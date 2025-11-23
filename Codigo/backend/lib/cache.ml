(* Redis cache module *)

open Lwt.Infix

(* Redis connection *)
let redis_connection = ref None

(* Initialize Redis connection *)
let init () =
  let open Redis_lwt.Client in
  try
    let spec = {
      host = Config.redis_host;
      port = Config.redis_port;
    } in
    connect spec >>= fun conn ->
    redis_connection := Some conn;
    select conn Config.redis_db >>= fun _ ->
    Logs.info (fun m -> m "Redis connected successfully");
    Lwt.return_unit
  with e ->
    Logs.err (fun m -> m "Failed to connect to Redis: %s" (Printexc.to_string e));
    Lwt.fail e

(* Get Redis connection *)
let get_conn () =
  match !redis_connection with
  | None -> Lwt.fail_with "Redis not initialized"
  | Some conn -> Lwt.return conn

(* Cache key generators *)
let vehicle_key slug = Printf.sprintf "vehicle:%s" slug
let vehicle_list_key page filters = 
  Printf.sprintf "vehicles:list:%d:%s" page (Yojson.Safe.to_string (Types.vehicle_filter_to_yojson filters))
let user_key user_id = Printf.sprintf "user:%d" user_id
let stats_key name = Printf.sprintf "stats:%s" name
let stats_key_with_param name param = Printf.sprintf "stats:%s:%s" name param

(* Get cached value *)
let get key =
  get_conn () >>= fun conn ->
  Redis_lwt.Client.get conn key >>= function
  | Some value -> Lwt.return_some value
  | None -> Lwt.return_none

(* Set cached value with TTL *)
let set key value ttl =
  get_conn () >>= fun conn ->
  Redis_lwt.Client.setex conn key ttl value >>= fun _ ->
  Lwt.return_unit

(* Delete cached value *)
let delete key =
  get_conn () >>= fun conn ->
  Redis_lwt.Client.del conn [key] >>= fun _ ->
  Lwt.return_unit

(* Invalidate all vehicle list caches *)
let invalidate_vehicle_lists () =
  Lwt.catch
    (fun () ->
  get_conn () >>= fun conn ->
  Redis_lwt.Client.keys conn "vehicles:list:*" >>= fun keys ->
  if List.length keys > 0 then
        (Logs.debug (fun m -> m "Invalidating %d vehicle list cache keys" (List.length keys));
    Redis_lwt.Client.del conn keys >>= fun _ ->
         Lwt.return_unit)
  else
        Lwt.return_unit)
    (fun exn ->
      (* If Redis fails, log but don't fail the operation *)
      Logs.warn (fun m -> m "Failed to invalidate vehicle list cache: %s" (Printexc.to_string exn));
      Lwt.return_unit)

(* Invalidate vehicle lists granularly based on vehicle attributes *)
(* This invalidates list caches that could be affected by a vehicle change *)
let invalidate_vehicle_lists_granular ?brand ?model ?location_state ?location_city ?source ?condition () =
  Lwt.catch
    (fun () ->
      get_conn () >>= fun conn ->
      Redis_lwt.Client.keys conn "vehicles:list:*" >>= fun all_keys ->
      if List.length all_keys = 0 then
        Lwt.return_unit
      else
        (* Build search patterns for each attribute *)
        let patterns = ref [] in
        (match brand with
         | Some b -> patterns := (Printf.sprintf "\"brand\":\"%s\"" b) :: !patterns
         | None -> ());
        (match model with
         | Some m -> patterns := (Printf.sprintf "\"model\":\"%s\"" m) :: !patterns
         | None -> ());
        (match location_state with
         | Some ls -> patterns := (Printf.sprintf "\"location_state\":\"%s\"" ls) :: !patterns
         | None -> ());
        (match location_city with
         | Some lc -> patterns := (Printf.sprintf "\"location_city\":\"%s\"" lc) :: !patterns
         | None -> ());
        (match source with
         | Some s -> patterns := (Printf.sprintf "\"source\":\"%s\"" s) :: !patterns
         | None -> ());
        (match condition with
         | Some c -> patterns := (Printf.sprintf "\"condition\":\"%s\"" c) :: !patterns
         | None -> ());
        
        (* If no patterns, invalidate all (safe fallback) *)
        if List.length !patterns = 0 then
          invalidate_vehicle_lists ()
        else
          (* Helper to check if string contains substring *)
          let string_contains str substr =
            try
              let len = String.length substr in
              let str_len = String.length str in
              let rec check i =
                if i + len > str_len then false
                else if String.sub str i len = substr then true
                else check (i + 1)
              in
              check 0
            with _ -> false
          in
          (* Find keys that contain any of the patterns OR are general listings (no filters) *)
          let matching_keys = List.filter (fun key ->
            List.exists (fun pattern -> string_contains key pattern) !patterns ||
            (* Also invalidate keys without filters (general listings) *)
            (not (string_contains key "\"brand\"") &&
             not (string_contains key "\"model\"") &&
             not (string_contains key "\"location_state\""))
          ) all_keys in
          
          if List.length matching_keys > 0 then
            (Logs.debug (fun m -> m "Invalidating %d/%d vehicle list cache keys (granular)" (List.length matching_keys) (List.length all_keys));
             Redis_lwt.Client.del conn matching_keys >>= fun _ ->
             Lwt.return_unit)
          else
            Lwt.return_unit)
    (fun exn ->
      Logs.warn (fun m -> m "Failed to invalidate vehicle list cache granularly: %s" (Printexc.to_string exn));
      (* Fallback to full invalidation on error *)
      invalidate_vehicle_lists ())

(* Cache vehicle *)
let cache_vehicle vehicle =
  let key = vehicle_key vehicle.Types.slug in
  let json = Types.vehicle_to_yojson vehicle |> Yojson.Safe.to_string in
  set key json Config.cache_ttl_vehicle_detail

(* Get cached vehicle *)
let get_vehicle slug =
  get (vehicle_key slug) >>= function
  | Some json ->
      (try
        let vehicle = Yojson.Safe.from_string json |> Types.vehicle_of_yojson in
        match vehicle with
        | Ok v -> Lwt.return_some v
        | Error _ -> Lwt.return_none
      with _ -> Lwt.return_none)
  | None -> Lwt.return_none

(* Cache vehicle list *)
let cache_vehicle_list page filters vehicles total_count =
  let key = vehicle_list_key page filters in
  let response = Types.{
    vehicles;
    total_count;
    page;
    total_pages = (total_count + filters.per_page - 1) / filters.per_page;
    has_next = page * filters.per_page < total_count;
    has_prev = page > 1;
  } in
  let json = Types.vehicle_list_response_to_yojson response |> Yojson.Safe.to_string in
  set key json Config.cache_ttl_vehicle_list

(* Get cached vehicle list *)
let get_vehicle_list page filters =
  get (vehicle_list_key page filters) >>= function
  | Some json ->
      (try
        let response = Yojson.Safe.from_string json |> Types.vehicle_list_response_of_yojson in
        match response with
        | Ok r -> Lwt.return_some r
        | Error _ -> Lwt.return_none
      with _ -> Lwt.return_none)
  | None -> Lwt.return_none

(* Redis queue for bulk vehicle imports *)
let bulk_import_queue_key = "vehicles:bulk:import:queue"

(* Add vehicles to bulk import queue *)
let enqueue_bulk_import vehicles_json =
  Lwt.catch
    (fun () ->
      get_conn () >>= fun conn ->
      let json_str = Yojson.Safe.to_string (`List vehicles_json) in
      Redis_lwt.Client.rpush conn bulk_import_queue_key [json_str] >>= fun _ ->
      Logs.info (fun m -> m "📥 Enqueued %d vehicles for bulk import" (List.length vehicles_json));
      Lwt.return_ok ())
    (fun exn ->
      Logs.warn (fun m -> m "⚠️ Failed to enqueue bulk import: %s" (Printexc.to_string exn));
      Lwt.return_error (Printexc.to_string exn))

(* Get vehicles from bulk import queue (batch) *)
let dequeue_bulk_import_batch ?(batch_size=50) () =
  Lwt.catch
    (fun () ->
      get_conn () >>= fun conn ->
      Redis_lwt.Client.lrange conn bulk_import_queue_key 0 (batch_size - 1) >>= fun items ->
      if List.length items > 0 then
        (Redis_lwt.Client.ltrim conn bulk_import_queue_key (List.length items) (-1) >>= fun _ ->
         let vehicles = List.filter_map (fun json_str ->
           try
             let json = Yojson.Safe.from_string json_str in
             match json with
             | `List vehicles -> Some vehicles
             | _ -> None
           with _ -> None
         ) items in
         let all_vehicles = List.flatten vehicles in
         Logs.info (fun m -> m "📤 Dequeued %d vehicles from bulk import queue" (List.length all_vehicles));
         Lwt.return_some all_vehicles)
      else
        Lwt.return_none)
    (fun exn ->
      Logs.warn (fun m -> m "⚠️ Failed to dequeue bulk import: %s" (Printexc.to_string exn));
      Lwt.return_none)

(* Get queue length *)
let bulk_import_queue_length () =
  Lwt.catch
    (fun () ->
      get_conn () >>= fun conn ->
      Redis_lwt.Client.llen conn bulk_import_queue_key >>= fun len ->
      Lwt.return len)
    (fun _ -> Lwt.return 0)

(* Cache statistics *)
let cache_stats name value =
  let key = stats_key name in
  set key value Config.cache_ttl_stats

let cache_stats_with_param name param value =
  let key = stats_key_with_param name param in
  set key value Config.cache_ttl_stats

let get_stats name =
  get (stats_key name)

let get_stats_with_param name param =
  get (stats_key_with_param name param)

(* Invalidate statistics cache *)
let invalidate_stats () =
  Lwt.catch
    (fun () ->
      get_conn () >>= fun conn ->
      Redis_lwt.Client.keys conn "stats:*" >>= fun keys ->
      if List.length keys > 0 then
        (Logs.debug (fun m -> m "Invalidating %d stats cache keys" (List.length keys));
         Redis_lwt.Client.del conn keys >>= fun _ ->
         Lwt.return_unit)
      else
        Lwt.return_unit)
    (fun exn ->
      Logs.warn (fun m -> m "Failed to invalidate stats cache: %s" (Printexc.to_string exn));
      Lwt.return_unit)
