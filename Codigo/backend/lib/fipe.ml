open Lwt.Infix

module T = Types

module Net = Cohttp_lwt_unix.Net

let cohttp_ctx =
  lazy
    (let service_override scheme =
       match String.lowercase_ascii scheme with
       | "https" ->
           let svc = Resolver.{ name = "https"; port = 443; tls = true } in
           Lwt.return_some svc
       | _ -> Resolver_lwt_unix.system_service scheme
     in
     let resolver =
       Resolver_lwt.init ~service:service_override
         ~rewrites:[ ("", Resolver_lwt_unix.system_resolver) ] ()
     in
     Net.init ~resolver ())

let headers =
  let base =
    Cohttp.Header.of_list [
      ("accept", "application/json");
    ]
  in
  match Config.fipe_api_token with
  | "" -> base
  | token -> Cohttp.Header.add base "X-Subscription-Token" token

let build_uri path params =
  let base = Config.fipe_api_base_url ^ path in
  Uri.of_string base |> fun uri ->
  match params with
  | [] -> uri
  | _ -> Uri.add_query_params' uri params

let http_get path params =
  let uri = build_uri path params in
  Logs.debug (fun m -> m "FIPE GET %s" (Uri.to_string uri));
  let ctx = Lazy.force cohttp_ctx in
  Lwt.catch
    (fun () ->
       Cohttp_lwt_unix.Client.get ~ctx ~headers uri >>= fun (resp, body) ->
       let status = Cohttp.Response.status resp |> Cohttp.Code.code_of_status in
       Cohttp_lwt.Body.to_string body >>= fun body_str ->
       if status >= 400 then (
         Logs.err (fun m -> m "FIPE request failed (%d): %s" status body_str);
         Lwt.return (Error (Printf.sprintf "FIPE request failed with status %d" status))
       ) else
         Lwt.return (Ok body_str))
    (fun exn ->
       Logs.err (fun m -> m "FIPE request exception: %s" (Printexc.to_string exn));
       Lwt.return (Error "Failed to reach FIPE API"))

let brands_cache_key vehicle_type reference =
  match reference with
  | Some ref -> Printf.sprintf "fipe:brands:%s:%s" vehicle_type ref
  | None -> Printf.sprintf "fipe:brands:%s" vehicle_type

let models_cache_key vehicle_type brand_code reference =
  match reference with
  | Some ref -> Printf.sprintf "fipe:models:%s:%s:%s" vehicle_type brand_code ref
  | None -> Printf.sprintf "fipe:models:%s:%s" vehicle_type brand_code

let decode_list raw decoder =
  try
    match Yojson.Safe.from_string raw with
    | `List items ->
        let rec loop acc = function
          | [] -> Ok (List.rev acc)
          | item :: rest ->
              (match decoder item with
               | Ok v -> loop (v :: acc) rest
               | Error msg -> Error msg)
        in
        loop [] items
    | _ -> Error "Unexpected FIPE payload"
  with exn ->
    Error (Printf.sprintf "Failed to parse FIPE response: %s" (Printexc.to_string exn))

let with_cache key fetch parse =
  Cache.get key >>= function
  | Some cached ->
      (match parse cached with
       | Ok data -> Lwt.return (Ok data)
       | Error msg ->
           Logs.warn (fun m -> m "Failed to parse cached FIPE data (%s), refetching" msg);
           fetch () >>= fun result ->
           Lwt.return result)
  | None ->
      fetch () >>= fun result ->
      Lwt.return result

let cache_and_parse key raw parse =
  match parse raw with
  | Ok data ->
      Cache.set key raw Config.cache_ttl_fipe >>= fun () ->
      Lwt.return (Ok data)
  | Error msg ->
      Logs.err (fun m -> m "Failed to parse FIPE response: %s" msg);
      Lwt.return (Error msg)

let get_brands ?(vehicle_type = Config.fipe_default_vehicle_type) ?reference () =
  let cache_key = brands_cache_key vehicle_type reference in
  let fetch () =
    let params = match reference with Some ref -> ["reference", ref] | None -> [] in
    http_get (Printf.sprintf "/%s/brands" vehicle_type) params >>= function
    | Ok body -> cache_and_parse cache_key body (fun raw -> decode_list raw T.fipe_brand_of_yojson)
    | Error _ as e -> Lwt.return e
  in
  with_cache cache_key fetch (fun raw -> decode_list raw T.fipe_brand_of_yojson)

let get_models ?(vehicle_type = Config.fipe_default_vehicle_type) ?reference ~brand_code () =
  let cache_key = models_cache_key vehicle_type brand_code reference in
  let fetch () =
    let params = match reference with Some ref -> ["reference", ref] | None -> [] in
    http_get (Printf.sprintf "/%s/brands/%s/models" vehicle_type brand_code) params >>= function
    | Ok body -> cache_and_parse cache_key body (fun raw -> decode_list raw T.fipe_model_of_yojson)
    | Error _ as e -> Lwt.return e
  in
  with_cache cache_key fetch (fun raw -> decode_list raw T.fipe_model_of_yojson)

let get_brand_by_code ?(vehicle_type = Config.fipe_default_vehicle_type) ?reference ~brand_code () =
  get_brands ~vehicle_type ?reference () >>= function
  | Ok brands -> (
      match List.find_opt (fun (b : T.fipe_brand) -> String.equal b.code brand_code) brands with
      | Some brand -> Lwt.return (Ok brand)
      | None -> Lwt.return (Error "Brand not found"))
  | Error _ as e -> Lwt.return e

(* Get years for a model *)
let years_cache_key vehicle_type brand_code model_code reference =
  match reference with
  | Some ref -> Printf.sprintf "fipe:years:%s:%s:%s:%s" vehicle_type brand_code model_code ref
  | None -> Printf.sprintf "fipe:years:%s:%s:%s" vehicle_type brand_code model_code

let get_years ?(vehicle_type = Config.fipe_default_vehicle_type) ?reference ~brand_code ~model_code () =
  let cache_key = years_cache_key vehicle_type brand_code model_code reference in
  let fetch () =
    let params = match reference with Some ref -> ["reference", ref] | None -> [] in
    http_get (Printf.sprintf "/%s/brands/%s/models/%s/years" vehicle_type brand_code model_code) params >>= function
    | Ok body -> cache_and_parse cache_key body (fun raw -> decode_list raw T.fipe_year_of_yojson)
    | Error _ as e -> Lwt.return e
  in
  with_cache cache_key fetch (fun raw -> decode_list raw T.fipe_year_of_yojson)

(* Get vehicle price/detail from FIPE *)
let price_cache_key vehicle_type brand_code model_code year_id reference =
  match reference with
  | Some ref -> Printf.sprintf "fipe:price:%s:%s:%s:%s:%s" vehicle_type brand_code model_code year_id ref
  | None -> Printf.sprintf "fipe:price:%s:%s:%s:%s" vehicle_type brand_code model_code year_id

let get_vehicle_price ?(vehicle_type = Config.fipe_default_vehicle_type) ?reference ~brand_code ~model_code ~year_id () =
  let cache_key = price_cache_key vehicle_type brand_code model_code year_id reference in
  let fetch () =
    let params = match reference with Some ref -> ["reference", ref] | None -> [] in
    http_get (Printf.sprintf "/%s/brands/%s/models/%s/years/%s" vehicle_type brand_code model_code year_id) params >>= function
    | Ok body ->
        (match T.fipe_vehicle_detail_of_yojson (Yojson.Safe.from_string body) with
         | Ok detail ->
             Cache.set cache_key body Config.cache_ttl_fipe >>= fun () ->
             Lwt.return (Ok detail)
         | Error msg ->
             Logs.err (fun m -> m "Failed to parse FIPE vehicle detail: %s" msg);
             Lwt.return (Error msg))
    | Error _ as e -> Lwt.return e
  in
  with_cache cache_key fetch (fun raw ->
    match T.fipe_vehicle_detail_of_yojson (Yojson.Safe.from_string raw) with
    | Ok detail -> Ok detail
    | Error msg -> Error msg)

(* Get references (available months) *)
let get_references () =
  let cache_key = "fipe:references" in
  let fetch () =
    http_get "/references" [] >>= function
    | Ok body -> cache_and_parse cache_key body (fun raw -> decode_list raw T.fipe_reference_of_yojson)
    | Error _ as e -> Lwt.return e
  in
  with_cache cache_key fetch (fun raw -> decode_list raw T.fipe_reference_of_yojson)


