(* API client for communicating with the backend *)
open Lwt.Syntax

let backend_url = 
  match Sys.getenv_opt "BACKEND_URL" with
  | Some url -> url
  | None -> "http://backend:3000"

(* HTTP client helper using Cohttp *)
let make_request ?(method_="GET") ?(headers=[]) ?body url =
  let uri = Uri.of_string (backend_url ^ url) in
  let headers = Cohttp.Header.of_list (("Content-Type", "application/json") :: headers) in
  
  match method_ with
  | "GET" -> 
    (try 
      let* (response, body) = Cohttp_lwt_unix.Client.get ~headers uri in
      let status_code = Cohttp.Response.status response |> Cohttp.Code.code_of_status in
      let* body_string = Cohttp_lwt.Body.to_string body in
      Lwt.return_ok (status_code, body_string)
    with
    | exn -> 
      Lwt.return_error ("Request failed: " ^ (Printexc.to_string exn))
    )
  | "POST" ->
    let body_cohttp = match body with
      | Some b -> `String b
      | None -> `Empty in
    (try 
      let* (response, body) = Cohttp_lwt_unix.Client.post ~headers ~body:body_cohttp uri in
      let status_code = Cohttp.Response.status response |> Cohttp.Code.code_of_status in
      let* body_string = Cohttp_lwt.Body.to_string body in
      Lwt.return_ok (status_code, body_string)
    with
    | exn -> 
      Lwt.return_error ("Request failed: " ^ (Printexc.to_string exn))
    )
  | _ -> Lwt.return_error "Unsupported HTTP method"

(* Parse JSON response helper *)
let parse_json_response json_string =
  try
    let json = Yojson.Basic.from_string json_string in
    Ok json
  with
  | exn -> Error ("JSON parsing failed: " ^ (Printexc.to_string exn))

(* API Functions *)

(* Get vehicles list with optional filters *)
let get_vehicles ?brand ?model ?year_min ?price_max ?fuel_type ?condition ?source ?location_state ?page ?limit ?sort_by () =
  let params = [] in
  let params = match brand with Some b -> ("brand", b) :: params | None -> params in
  let params = match model with Some m -> ("model", m) :: params | None -> params in
  let params = match year_min with Some y -> ("year_min", string_of_int y) :: params | None -> params in
  let params = match price_max with Some p -> ("price_max", string_of_int p) :: params | None -> params in
  let params = match fuel_type with Some f -> ("fuel_type", f) :: params | None -> params in
  let params = match condition with Some c -> ("condition", c) :: params | None -> params in
  let params = match source with Some s -> ("source", s) :: params | None -> params in
  let params = match location_state with Some ls -> ("location_state", ls) :: params | None -> params in
  let params = match page with Some p -> ("page", string_of_int p) :: params | None -> params in
  let params = match limit with Some l -> ("limit", string_of_int l) :: params | None -> params in
  let params = match sort_by with Some sb -> ("sort_by", sb) :: params | None -> params in
  
  let query_string = 
    if params = [] then ""
    else "?" ^ (String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ v) params)) in
  
  let* result = make_request ("/api/vehicles" ^ query_string) in
  match result with
  | Error err -> Lwt.return_error err
  | Ok (status_code, body) ->
    if status_code = 200 then
      match parse_json_response body with
      | Ok json -> Lwt.return_ok json
      | Error err -> Lwt.return_error err
    else
      Lwt.return_error ("HTTP error: " ^ (string_of_int status_code))

(* Get single vehicle by slug *)
let get_vehicle_by_slug slug =
  let* result = make_request ("/api/vehicles/" ^ slug) in
  match result with
  | Error err -> Lwt.return_error err
  | Ok (status_code, body) ->
    if status_code = 200 then
      match parse_json_response body with
      | Ok json -> Lwt.return_ok json
      | Error err -> Lwt.return_error err
    else if status_code = 404 then
      Lwt.return_error "Vehicle not found"
    else
      Lwt.return_error ("HTTP error: " ^ (string_of_int status_code))

(* Health check *)
let health_check () =
  let* result = make_request "/api/health" in
  match result with
  | Error err -> Lwt.return_error err
  | Ok (status_code, body) ->
    if status_code = 200 then
      match parse_json_response body with
      | Ok json -> Lwt.return_ok json
      | Error err -> Lwt.return_error err
    else
      Lwt.return_error ("HTTP error: " ^ (string_of_int status_code))
