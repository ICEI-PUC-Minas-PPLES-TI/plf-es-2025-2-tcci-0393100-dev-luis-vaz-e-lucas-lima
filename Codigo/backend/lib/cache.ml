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
  get_conn () >>= fun conn ->
  Redis_lwt.Client.keys conn "vehicles:list:*" >>= fun keys ->
  if List.length keys > 0 then
    Redis_lwt.Client.del conn keys >>= fun _ ->
    Lwt.return_unit
  else
    Lwt.return_unit

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

(* Increment view count in cache (for rate limiting database updates) *)
let increment_view_count slug =
  let key = Printf.sprintf "views:%s" slug in
  get_conn () >>= fun conn ->
  Redis_lwt.Client.incr conn key >>= fun count ->
  (* Set expiry of 1 hour for view counter *)
  Redis_lwt.Client.expire conn key 3600 >>= fun _ ->
  Lwt.return (Int64.of_int count)

