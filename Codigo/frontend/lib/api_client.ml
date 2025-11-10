(* API Client for Backend Communication using Cohttp *)

open Lwt.Infix
open Types

(* Backend API URL *)
let backend_url = 
  try Sys.getenv "BACKEND_API_URL" 
  with Not_found -> "http://backend:3000"

(* HTTP GET helper *)
let http_get url =
  let uri = Uri.of_string url in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.get uri >>= fun (_resp, body) ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Lwt.return_some body_str)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP GET failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

(* HTTP POST helper *)
let http_post url ~body =
  let uri = Uri.of_string url in
  let headers = Cohttp.Header.init_with "Content-Type" "application/json" in
  let body = Cohttp_lwt.Body.of_string body in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.post ~headers ~body uri >>= fun (_resp, body) ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Lwt.return_some body_str)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP POST failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

(* Fetch all vehicles from backend *)
let fetch_vehicles ?brand ?model ?condition ?source ?page () =
  let params = [] in
  let params = match brand with Some b when b <> "" -> ("brand", b) :: params | _ -> params in
  let params = match model with Some m when m <> "" -> ("model", m) :: params | _ -> params in
  let params = match condition with Some c when c <> "" -> ("condition", c) :: params | _ -> params in
  let params = match source with Some s when s <> "" -> ("source", s) :: params | _ -> params in
  let params = match page with Some p -> ("page", string_of_int p) :: params | _ -> params in
  
  let query_string = 
    if List.length params > 0 then
      "?" ^ String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ v) params)
    else ""
  in
  
  let url = backend_url ^ "/api/vehicles" ^ query_string in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let vehicles_json = Yojson.Safe.Util.member "vehicles" json in
        let vehicles_list = Yojson.Safe.Util.to_list vehicles_json in
        Logs.info (fun m -> m "Got %d vehicles from API response" (List.length vehicles_list));
        let vehicles = List.filter_map (fun v ->
          match vehicle_of_yojson v with
          | Ok vehicle -> 
              Logs.info (fun m -> m "✅ Parsed: %s %s" vehicle.brand vehicle.model);
              Some vehicle
          | Error e -> 
              let json_preview = Yojson.Safe.to_string v |> fun s -> String.sub s 0 (min 300 (String.length s)) in
              Logs.err (fun m -> m "❌ Parse error: %s" e);
              Logs.err (fun m -> m "JSON: %s..." json_preview);
              None
        ) vehicles_list in
        Logs.info (fun m -> m "✅ Fetched %d vehicles from backend API" (List.length vehicles));
        Lwt.return vehicles
      with e ->
        Logs.err (fun m -> m "❌ Exception parsing response: %s" (Printexc.to_string e));
        Lwt.return [])
  | None ->
      Logs.err (fun m -> m "❌ Failed to fetch from backend");
      Lwt.return []

(* Fetch single vehicle by slug *)
let fetch_vehicle_by_slug slug =
  let url = backend_url ^ "/api/vehicles/" ^ slug in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let data = Yojson.Safe.Util.member "data" json in
          match vehicle_of_yojson data with
          | Ok vehicle -> 
              Logs.info (fun m -> m "✅ Fetched vehicle %s from backend API" slug);
              Lwt.return_some vehicle
          | Error err -> 
              Logs.warn (fun m -> m "Failed to parse vehicle: %s" err);
              Lwt.return_none
        else
          Lwt.return_none
      with e ->
          Logs.err (fun m -> m "Exception parsing vehicle: %s" (Printexc.to_string e));
          Lwt.return_none)
  | None -> 
      Logs.warn (fun m -> m "Failed to fetch vehicle %s from backend" slug);
      Lwt.return_none

(* Login user *)
let login email password =
  let url = backend_url ^ "/api/auth/login" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("email", `String email);
    ("password", `String password);
  ]) in
  
  http_post url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let session_id = Yojson.Safe.Util.member "session_id" json |> Yojson.Safe.Util.to_string_option in
          Logs.info (fun m -> m "✅ Login successful for %s" email);
          Lwt.return_ok session_id
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Logs.warn (fun m -> m "Login failed: %s" message);
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse login response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response format")
  | None -> 
      Logs.err (fun m -> m "Failed to connect to backend for login");
      Lwt.return_error "Backend connection failed"

