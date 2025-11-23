(* API Client for Backend Communication using Cohttp *)

open Lwt.Infix
open Types

module StringSet = Set.Make (String)

(* Backend API URL *)
let backend_url = 
  try Sys.getenv "BACKEND_API_URL" 
  with Not_found -> "http://backend:3000"

let has_digit s =
  let rec loop i =
    if i >= String.length s then false
    else
      match s.[i] with
      | '0' .. '9' -> true
      | _ -> loop (i + 1)
  in
  loop 0

let lower = String.lowercase_ascii

let trim_markers =
  [
    "altis"; "xei"; "gli"; "gls"; "xrs"; "xri"; "xli"; "xl"; "xle"; "xlt";
    "premium"; "prem"; "prem."; "platinum"; "sport"; "hybrid"; "híbrido";
    "limited"; "turbo"; "flex"; "aut"; "auto"; "autom"; "automático";
    "automatico"; "manual"; "mt"; "cv"; "xls"; "xrx"; "xre"; "xrt"; "xrv";
    "xsd"; "xse"; "hpe"; "hpe-s"; "coupe"; "coupé"; "le"; "se"; "gli"; "gli";
    "ge"; "dx"; "dx/"; "wg"; "sw"; "s"; "x"; "xs"; "x-way"; "ready!"; "jipe";
    "picape"; "cd"; "cs"; "chassi"; "minibus"; "lx"; "limited"; "sdrive";
    "xdrive";
  ]

let preserve_second_tokens =
  [
    "cross"; "fielder"; "cruiser"; "t-100"; "gr"; "gr-sport"; "grsport"; "band";
    "supra"; "prelude"; "land"; "rav4"; "hilux"; "mr"; "yaris"; "sw4";
  ]

let normalize_whitespace s =
  s
  |> String.trim
  |> String.split_on_char ' '
  |> List.filter (fun part -> part <> "")
  |> String.concat " "

let purge_punctuation s =
  String.map
    (function
      | '.' | '-' | '/' | '!' | ',' | ';' -> ' '
      | c -> c)
    s

let remove_parentheses s =
  let buf = Buffer.create (String.length s) in
  let rec aux i depth =
    if i >= String.length s then ()
    else
      match s.[i] with
      | '(' -> aux (i + 1) (depth + 1)
      | ')' -> aux (i + 1) (max 0 (depth - 1))
      | c when depth = 0 ->
          Buffer.add_char buf c;
          aux (i + 1) depth
      | _ -> aux (i + 1) depth
  in
  aux 0 0;
  Buffer.contents buf

let canonical_model_name name =
  let cleaned =
    name
    |> remove_parentheses
    |> purge_punctuation
    |> normalize_whitespace
  in
  match String.split_on_char ' ' cleaned with
  | [] -> ""
  | [ single ] -> String.capitalize_ascii single
  | first :: second :: _ ->
      let second_lower = lower second in
      if List.mem second_lower preserve_second_tokens then
        String.capitalize_ascii first ^ " " ^ String.capitalize_ascii second_lower
      else if has_digit second || List.mem second_lower trim_markers then
        String.capitalize_ascii first
      else
        String.capitalize_ascii first ^ " " ^ String.capitalize_ascii second

let simplify_models (models : Types.fipe_model list) : Types.fipe_model list =
  let rec aux (seen : StringSet.t) (acc : Types.fipe_model list) (lst : Types.fipe_model list) : Types.fipe_model list =
    match lst with
    | [] -> List.rev acc
    | m :: rest ->
        let canonical = canonical_model_name m.name in
        if canonical = "" || StringSet.mem canonical seen then
          aux seen acc rest
        else
          let updated = { m with name = canonical } in
          aux (StringSet.add canonical seen) (updated :: acc) rest
  in
  aux StringSet.empty [] models
(* HTTP GET helper *)
let http_get ?session url =
  let uri = Uri.of_string url in
  let headers = match session with
    | Some session_id -> 
        Cohttp.Header.init_with "Authorization" ("Bearer " ^ session_id)
    | None -> Cohttp.Header.init ()
  in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.get ~headers uri >>= fun (_resp, body) ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Lwt.return_some body_str)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP GET failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

(* HTTP POST helper *)
let http_post ?session url ~body =
  let uri = Uri.of_string url in
  let headers = Cohttp.Header.init_with "Content-Type" "application/json" in
  let headers = match session with
    | Some session_id -> 
        Cohttp.Header.add headers "Authorization" ("Bearer " ^ session_id)
    | None -> headers
  in
  let body = Cohttp_lwt.Body.of_string body in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.post ~headers ~body uri >>= fun (_resp, body) ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Lwt.return_some body_str)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP POST failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

(* HTTP PUT helper *)
let http_put ?session url ~body =
  let uri = Uri.of_string url in
  let headers = Cohttp.Header.init_with "Content-Type" "application/json" in
  let headers = match session with
    | Some session_id -> 
        Cohttp.Header.add headers "Authorization" ("Bearer " ^ session_id)
    | None -> headers
  in
  let body = Cohttp_lwt.Body.of_string body in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.put ~headers ~body uri >>= fun (_resp, body) ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Lwt.return_some body_str)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP PUT failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

let http_delete ?session url =
  let uri = Uri.of_string url in
  let headers = Cohttp.Header.init () in
  let headers = match session with
    | Some session_id -> 
        Cohttp.Header.add headers "Authorization" ("Bearer " ^ session_id)
    | None -> headers
  in
  Lwt.catch
    (fun () ->
      Cohttp_lwt_unix.Client.delete ~headers uri >>= fun (resp, body) ->
      let status = Cohttp.Response.status resp in
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      match status with
      | `OK | `No_content | `Accepted ->
          Lwt.return_some body_str
      | _ ->
          Logs.warn (fun m -> m "HTTP DELETE %s returned status %s: %s" url (Cohttp.Code.string_of_status status) body_str);
          Lwt.return_some body_str) (* Still return body for error parsing *)
    (fun exn ->
      Logs.warn (fun m -> m "HTTP DELETE failed for %s: %s" url (Printexc.to_string exn));
      Lwt.return_none)

(* Fetch all vehicles from backend with pagination metadata *)
let fetch_vehicles
    ?brand ?model ?condition ?source ?fuel_type ?location_state ?location_city
    ?year_min ?year_max ?price_min ?price_max ?seller_id ?sort ?page ?per_page () =
  let encode = Uri.pct_encode in
  let add_string acc key value_opt =
    match value_opt with
    | Some v when v <> "" -> (key, encode v) :: acc
    | _ -> acc
  in
  let add_int acc key value_opt =
    match value_opt with
    | Some v -> (key, string_of_int v) :: acc
    | None -> acc
  in
  let params = [] in
  let params = add_string params "brand" brand in
  let params = add_string params "model" model in
  let params = add_string params "condition" condition in
  let params = add_string params "source" source in
  let params = add_string params "fuel_type" fuel_type in
  let params = add_int params "seller_id" seller_id in
  let params = add_string params "location_state" location_state in
  let params = add_string params "location_city" location_city in
  let params = add_int params "year_min" year_min in
  let params = add_int params "year_max" year_max in
  let params = add_int params "price_min" price_min in
  let params = add_int params "price_max" price_max in
  let params = add_string params "sort" sort in
  let params = add_int params "page" page in
  let params = add_int params "per_page" per_page in
  let query_string = 
    match params with
    | [] -> ""
    | _ ->
        "?"
        ^ (params
          |> List.rev
          |> List.map (fun (k, v) -> k ^ "=" ^ v)
          |> String.concat "&")
  in
  let url = backend_url ^ "/api/vehicles" ^ query_string in
  let empty_page =
    {
      vehicles = [];
      total_count = 0;
      page = Option.value ~default:1 page;
      total_pages = 0;
      has_next = false;
      has_prev = Option.value ~default:1 page > 1;
    }
  in
  http_get url >>= function
  | Some json_str -> (
      try
        let json = Yojson.Safe.from_string json_str in
        let vehicles_json = Yojson.Safe.Util.member "vehicles" json |> Yojson.Safe.Util.to_list in
        let vehicles =
          List.filter_map (fun v ->
          match vehicle_of_yojson v with
            | Ok vehicle -> Some vehicle
          | Error e -> 
                Logs.err (fun m -> m "❌ Vehicle parse error: %s" e);
                None
          ) vehicles_json
        in
        let int_member key default =
          try Yojson.Safe.Util.member key json |> Yojson.Safe.Util.to_int with _ -> default
        in
        let bool_member key default =
          try Yojson.Safe.Util.member key json |> Yojson.Safe.Util.to_bool with _ -> default
        in
        let page_record = {
          vehicles;
          total_count = int_member "total_count" (List.length vehicles);
          page = int_member "page" (Option.value ~default:1 page);
          total_pages = int_member "total_pages" 1;
          has_next = bool_member "has_next" false;
          has_prev = bool_member "has_prev" false;
        } in
        Lwt.return page_record
      with e ->
        Logs.err (fun m -> m "❌ Exception parsing vehicle list: %s" (Printexc.to_string e));
        Lwt.return empty_page)
  | None ->
      Logs.err (fun m -> m "❌ Failed to fetch from backend");
      Lwt.return empty_page

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

(* Register user *)
let register name email password phone document_number address_street address_number address_complement 
             address_neighborhood address_city address_state address_zipcode referral_code =
  let url = backend_url ^ "/api/auth/register" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("name", `String name);
    ("email", `String email);
    ("password", `String password);
    ("phone", `String phone);
    ("document_number", `String document_number);
    ("address_street", `String address_street);
    ("address_number", `String address_number);
    ("address_complement", match address_complement with Some c -> `String c | None -> `Null);
    ("address_neighborhood", `String address_neighborhood);
    ("address_city", `String address_city);
    ("address_state", `String address_state);
    ("address_zipcode", `String address_zipcode);
    ("referral_code", `String referral_code);
  ]) in
  
  http_post url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let session_id = Yojson.Safe.Util.member "session_id" json |> Yojson.Safe.Util.to_string_option in
          Logs.info (fun m -> m "✅ Registration successful for %s" email);
          Lwt.return_ok session_id
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Logs.warn (fun m -> m "Registration failed: %s" message);
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse registration response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for registration");
      Lwt.return_error "Backend connection failed"

(* Referral codes page type - now in Types module *)

(* Fetch referral codes with pagination and filters *)
let fetch_referral_codes ?session ?(page=1) ?(per_page=5) ?(search="") ?(status="all") () =
  let params = [
    ("page", string_of_int page);
    ("per_page", string_of_int per_page);
    ("search", search);
    ("status", status);
  ] in
  let query_string = String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode ~component:`Query v) params) in
  let url = backend_url ^ "/api/referral-codes?" ^ query_string in
  http_get ?session url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let data = Yojson.Safe.Util.member "data" json in
          let codes_json = try Yojson.Safe.Util.member "codes" data |> Yojson.Safe.Util.to_list with _ -> [] in
          let codes = List.filter_map (fun item ->
            match Types.referral_code_of_yojson item with
            | Ok code -> Some code
            | Error _ -> None
          ) codes_json in
          let safe_int member default_val =
            try
              match Yojson.Safe.Util.member member data with
              | `Null -> default_val
              | v -> Yojson.Safe.Util.to_int v
            with _ -> default_val
          in
          let safe_bool member default_val =
            try
              match Yojson.Safe.Util.member member data with
              | `Null -> default_val
              | v -> Yojson.Safe.Util.to_bool v
            with _ -> default_val
          in
          let total_count = safe_int "total_count" 0 in
          let page_num = safe_int "page" 1 in
          let per_page_num = safe_int "per_page" 5 in
          let total_pages = safe_int "total_pages" 0 in
          let has_next = safe_bool "has_next" false in
          let has_prev = safe_bool "has_prev" false in
          Lwt.return_some ({
            codes;
            total_count;
            page = page_num;
            per_page = per_page_num;
            total_pages;
            has_next;
            has_prev;
          } : Types.referral_codes_page)
        else
          Lwt.return_none
      with e ->
        Logs.err (fun m -> m "Failed to parse referral codes: %s. JSON: %s" (Printexc.to_string e) (String.sub json_str 0 (min (String.length json_str) 500)));
        Lwt.return_none)
  | None ->
      Logs.err (fun m -> m "Failed to fetch referral codes");
      Lwt.return_none

(* Fetch all users (admin only) *)
let fetch_all_users ?session ?page ?per_page ?search ?role ?sort () =
  let page = Option.value ~default:1 page in
  let per_page = Option.value ~default:12 per_page in
  let search = Option.value ~default:"" search in
  let role = Option.value ~default:"all" role in
  let sort = Option.value ~default:"created_desc" sort in
  let params = ref [] in
  params := ("page", string_of_int page) :: !params;
  params := ("per_page", string_of_int per_page) :: !params;
  if search <> "" then params := ("search", search) :: !params;
  if role <> "all" then params := ("role", role) :: !params;
  if sort <> "" then params := ("sort", sort) :: !params;
  let query_string = String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode ~component:`Query v) !params) in
  let url = backend_url ^ "/api/users" ^ (if query_string <> "" then "?" ^ query_string else "") in
  http_get ?session url >>= function
  | Some json_str ->
      (try
        Logs.info (fun m -> m "📥 Received users response: %s" (String.sub json_str 0 (min 500 (String.length json_str))));
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let data = Yojson.Safe.Util.member "data" json in
          let users_json = Yojson.Safe.Util.member "users" data
            |> Yojson.Safe.Util.to_list in
          Logs.info (fun m -> m "📊 Found %d users in response" (List.length users_json));
          let users = List.filter_map (fun item ->
            match user_of_yojson item with
            | Ok u -> Some u
            | Error e -> 
                Logs.err (fun m -> m "Failed to parse user: %s" e);
                None
          ) users_json in
          let int_member key default =
            try Yojson.Safe.Util.member key data |> Yojson.Safe.Util.to_int with _ -> default
          in
          let bool_member key default =
            try Yojson.Safe.Util.member key data |> Yojson.Safe.Util.to_bool with _ -> default
          in
          let users_page = {
            Types.users = users;
            total_count = int_member "total_count" (List.length users);
            page = int_member "page" page;
            total_pages = int_member "total_pages" 1;
            has_next = bool_member "has_next" false;
            has_prev = bool_member "has_prev" false;
          } in
          Logs.info (fun m -> m "✅ Successfully parsed %d users (page %d/%d)" (List.length users) users_page.page users_page.total_pages);
          Lwt.return (Ok users_page)
        else
          (Logs.warn (fun m -> m "⚠️ Backend returned success=false for users");
           let empty_page = {
             Types.users = [];
             total_count = 0;
             page = page;
             total_pages = 0;
             has_next = false;
             has_prev = false;
           } in
           Lwt.return (Ok empty_page))
      with e ->
        Logs.err (fun m -> m "Failed to parse users: %s" (Printexc.to_string e));
        let empty_page = {
          Types.users = [];
          total_count = 0;
          page = page;
          total_pages = 0;
          has_next = false;
          has_prev = false;
        } in
        Lwt.return (Ok empty_page))
  | None ->
      Logs.err (fun m -> m "Failed to fetch users - no response");
      let empty_page = {
        Types.users = [];
        total_count = 0;
        page = page;
        total_pages = 0;
        has_next = false;
        has_prev = false;
      } in
      Lwt.return (Ok empty_page)

(* Create referral code *)
let create_referral_code ?session ?code () =
  let url = backend_url ^ "/api/referral-codes" in
  let body = match code with
    | Some c -> Yojson.Safe.to_string (`Assoc [("code", `String c)])
    | None -> Yojson.Safe.to_string (`Assoc [])
  in
  http_post ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let code = Yojson.Safe.Util.member "data" json
            |> Yojson.Safe.Util.member "code"
            |> Yojson.Safe.Util.to_string in
          Lwt.return_ok code
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse create referral code response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for create referral code");
      Lwt.return_error "Backend connection failed"

(* Distribute referral codes *)
let distribute_referral_codes ?session ?email ~count () =
  let url = backend_url ^ "/api/referral-codes/distribute" in
  let body = match email with
    | Some e when String.trim e <> "" && String.lowercase_ascii (String.trim e) <> "all" ->
        Yojson.Safe.to_string (`Assoc [
          ("email", `String (String.trim e));
          ("count", `Int count);
        ])
    | _ ->
        Yojson.Safe.to_string (`Assoc [
          ("count", `Int count);
        ])
  in
  http_post ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          Lwt.return_ok json
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse distribute referral codes response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for distribute referral codes");
      Lwt.return_error "Backend connection failed"

(* Deactivate all referral codes *)
let deactivate_all_referral_codes ?session () =
  let url = backend_url ^ "/api/referral-codes/deactivate-all" in
  http_post ?session url ~body:"{}" >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let total_deactivated = try
            Yojson.Safe.Util.member "data" json
              |> Yojson.Safe.Util.member "total_deactivated"
              |> Yojson.Safe.Util.to_int
          with _ -> 0 in
          Lwt.return_ok total_deactivated
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse deactivate all referral codes response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for deactivate all referral codes");
      Lwt.return_error "Backend connection failed"

(* Deactivate referral code *)
let deactivate_referral_code ?session code_id =
  let url = backend_url ^ "/api/referral-codes/" ^ string_of_int code_id ^ "/deactivate" in
  http_post ?session url ~body:"{}" >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          Lwt.return_ok ()
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse deactivate referral code response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for deactivate referral code");
      Lwt.return_error "Backend connection failed"

(* Get current user *)
let get_current_user ?session () =
  let url = backend_url ^ "/api/auth/me" in
  http_get ?session url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let user_json = Yojson.Safe.Util.member "data" json in
          match user_of_yojson user_json with
          | Ok user -> Lwt.return_some user
          | Error _ -> Lwt.return_none
        else
          Lwt.return_none
      with e ->
        Logs.err (fun m -> m "Failed to parse user: %s" (Printexc.to_string e));
        Lwt.return_none)
  | None -> Lwt.return_none

(* Change password *)
let change_password ?session old_password new_password =
  let url = backend_url ^ "/api/auth/change-password" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("old_password", `String old_password);
    ("new_password", `String new_password);
  ]) in
  http_post ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          Lwt.return_ok ()
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse change password response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for change password");
      Lwt.return_error "Backend connection failed"

(* Update user profile *)
(* Admin update user *)
let admin_update_user ?session user_id name email phone document_number address_street address_number
    address_complement address_neighborhood address_city address_state address_zipcode =
  let url = backend_url ^ "/api/users/" ^ string_of_int user_id in
  let body = Yojson.Safe.to_string (`Assoc [
    ("name", `String name);
    ("email", `String email);
    ("phone", `String phone);
    ("document_number", `String document_number);
    ("address_street", `String address_street);
    ("address_number", `String address_number);
    ("address_complement", `String (match address_complement with Some c -> c | None -> ""));
    ("address_neighborhood", `String address_neighborhood);
    ("address_city", `String address_city);
    ("address_state", `String address_state);
    ("address_zipcode", `String address_zipcode);
  ]) in
  http_put ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let user_json = Yojson.Safe.Util.member "data" json in
          (match user_of_yojson user_json with
           | Ok user -> Lwt.return (Ok user)
           | Error e -> Lwt.return (Error ("Erro ao parsear resposta: " ^ e)))
        else
          let msg = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return (Error msg)
      with e ->
        Logs.err (fun m -> m "Failed to parse admin update user response: %s" (Printexc.to_string e));
        Lwt.return (Error ("Erro ao atualizar usuário: " ^ Printexc.to_string e)))
  | None ->
      Lwt.return (Error "Erro ao atualizar usuário: sem resposta do servidor")

(* Admin change user password *)
let admin_change_user_password ?session user_id new_password =
  let url = backend_url ^ "/api/users/" ^ string_of_int user_id ^ "/change-password" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("user_id", `Int user_id);
    ("new_password", `String new_password);
  ]) in
  http_post ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          Lwt.return (Ok ())
        else
          let msg = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return (Error msg)
      with e ->
        Logs.err (fun m -> m "Failed to parse admin change password response: %s" (Printexc.to_string e));
        Lwt.return (Error ("Erro ao alterar senha: " ^ Printexc.to_string e)))
  | None ->
      Lwt.return (Error "Erro ao alterar senha: sem resposta do servidor")

let update_user_profile ?session name phone document_number address_street address_number
    address_complement address_neighborhood address_city address_state address_zipcode =
  let url = backend_url ^ "/api/auth/me" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("name", `String name);
    ("phone", `String phone);
    ("document_number", `String document_number);
    ("address_street", `String address_street);
    ("address_number", `String address_number);
    ("address_complement", (match address_complement with Some c -> `String c | None -> `Null));
    ("address_neighborhood", `String address_neighborhood);
    ("address_city", `String address_city);
    ("address_state", `String address_state);
    ("address_zipcode", `String address_zipcode);
  ]) in
  http_put ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let user_json = Yojson.Safe.Util.member "data" json in
          match user_of_yojson user_json with
          | Ok user -> Lwt.return_ok user
          | Error _ -> Lwt.return_error "Erro ao parsear resposta"
        else
          let message = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return_error message
      with e ->
        Logs.err (fun m -> m "Failed to parse update user response: %s" (Printexc.to_string e));
        Lwt.return_error "Invalid response from server")
  | None ->
      Logs.err (fun m -> m "Failed to connect to backend for update user");
      Lwt.return_error "Backend connection failed"

(* Fetch FIPE brands *)
let fetch_fipe_brands ?(vehicle_type="cars") () =
  let url = backend_url ^ "/api/fipe/brands?vehicle_type=" ^ vehicle_type in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let brands_json =
          Yojson.Safe.Util.member "data" json
          |> Yojson.Safe.Util.member "brands"
          |> Yojson.Safe.Util.to_list
        in
        let brands = List.filter_map (fun item ->
          match Types.fipe_brand_of_yojson item with
          | Ok brand -> Some brand
          | Error err ->
              Logs.err (fun m -> m "Failed to parse FIPE brand: %s" err);
              None
        ) brands_json in
        Lwt.return brands
      with e ->
        Logs.err (fun m -> m "Failed to parse FIPE brands payload: %s" (Printexc.to_string e));
        Lwt.return [])
  | None ->
      Logs.err (fun m -> m "Failed to fetch FIPE brands from backend");
      Lwt.return []

(* Fetch models from database (with Redis cache) *)
let fetch_db_models brand =
  let encoded_brand = Uri.pct_encode brand in
  let url = backend_url ^ "/api/vehicles/models/" ^ encoded_brand in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let data = Yojson.Safe.Util.member "data" json in
        let models_json = Yojson.Safe.Util.member "models" data |> Yojson.Safe.Util.to_list in
        let models = List.filter_map (fun item ->
          match item with
          | `String model_name -> 
              let model : fipe_model = { code = ""; name = model_name } in
              Some model
          | _ -> None
        ) models_json in
        Lwt.return models
      with e ->
        Logs.err (fun m -> m "Failed to parse DB models payload: %s" (Printexc.to_string e));
        Lwt.return [])
  | None ->
      Logs.err (fun m -> m "Failed to fetch DB models for brand %s" brand);
      Lwt.return []

(* Fetch FIPE models for brand (kept for backward compatibility) *)
let fetch_fipe_models ?(vehicle_type="cars") ?reference brand_code =
  let params =
    ("vehicle_type", vehicle_type) ::
    (match reference with
     | Some r when r <> "" -> [("reference", r)]
     | _ -> [])
  in
  let query =
    params
    |> List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode v)
    |> String.concat "&"
  in
  let encoded_brand_code = Uri.pct_encode brand_code in
  let url = backend_url ^ "/api/fipe/brands/" ^ encoded_brand_code ^ "/models" ^
            (if query = "" then "" else "?" ^ query) in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let models_json =
          Yojson.Safe.Util.member "data" json
          |> Yojson.Safe.Util.member "models"
          |> Yojson.Safe.Util.to_list
        in
        let models : Types.fipe_model list = List.filter_map (fun item ->
          match Types.fipe_model_of_yojson item with
          | Ok model -> Some model
          | Error err ->
              Logs.err (fun m -> m "Failed to parse FIPE model: %s" err);
              None
        ) models_json |> simplify_models in
        Lwt.return models
      with e ->
        Logs.err (fun m -> m "Failed to parse FIPE models payload: %s" (Printexc.to_string e));
        Lwt.return [])
  | None ->
      Logs.err (fun m -> m "Failed to fetch FIPE models for brand %s" brand_code);
      Lwt.return []

(* Fetch FIPE references (available months) *)
let fetch_fipe_references () =
  let url = backend_url ^ "/api/fipe/references" in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let data = Yojson.Safe.Util.member "data" json in
        let references_json = Yojson.Safe.Util.member "references" data |> Yojson.Safe.Util.to_list in
        let references = List.filter_map (fun item ->
          match Types.fipe_reference_of_yojson item with
          | Ok ref -> Some ref
          | Error _ -> None
        ) references_json in
        Lwt.return references
      with e ->
        Logs.err (fun m -> m "Failed to parse FIPE references: %s" (Printexc.to_string e));
        Lwt.return [])
  | None -> Lwt.return []

(* Fetch FIPE years for a model *)
let fetch_fipe_years ?(vehicle_type="cars") ?reference brand_code model_code =
  let params = [
    ("vehicle_type", vehicle_type);
  ] @ (match reference with Some r -> [("reference", r)] | None -> []) in
  let query = String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode v) params) in
  let url = backend_url ^ "/api/fipe/brands/" ^ Uri.pct_encode brand_code ^ 
            "/models/" ^ Uri.pct_encode model_code ^ "/years" ^
            (if query <> "" then "?" ^ query else "") in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let data = Yojson.Safe.Util.member "data" json in
        let years_json = Yojson.Safe.Util.member "years" data |> Yojson.Safe.Util.to_list in
        let years = List.filter_map (fun item ->
          match Types.fipe_year_of_yojson item with
          | Ok year -> Some year
          | Error _ -> None
        ) years_json in
        Lwt.return years
      with e ->
        Logs.err (fun m -> m "Failed to parse FIPE years: %s" (Printexc.to_string e));
        Lwt.return [])
  | None -> Lwt.return []

(* Fetch FIPE price for a vehicle *)
let fetch_fipe_price ?(vehicle_type="cars") ?reference brand_code model_code year_id =
  let params = [
    ("vehicle_type", vehicle_type);
  ] @ (match reference with Some r -> [("reference", r)] | None -> []) in
  let query = String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode v) params) in
  let url = backend_url ^ "/api/fipe/brands/" ^ Uri.pct_encode brand_code ^ 
            "/models/" ^ Uri.pct_encode model_code ^ "/years/" ^ Uri.pct_encode year_id ^
            (if query <> "" then "?" ^ query else "") in
  http_get url >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let data = Yojson.Safe.Util.member "data" json in
        match Types.fipe_vehicle_detail_of_yojson data with
        | Ok detail -> Lwt.return_some detail
        | Error _ -> Lwt.return_none
      with e ->
        Logs.err (fun m -> m "Failed to parse FIPE price: %s" (Printexc.to_string e));
        Lwt.return_none)
  | None -> Lwt.return_none

(* Create vehicle *)
let create_vehicle ?session brand model year price mileage fuel_type color transmission 
    description image images seller_name seller_phone seller_email condition location_city location_state
    engine doors body_style financing_available trade_accepted test_drive_available
    exterior_condition interior_condition mechanical_condition previous_owners =
  let url = backend_url ^ "/api/vehicles" in
  let images_json = `List (List.map (fun img -> `String img) images) in
  let body = Yojson.Safe.to_string (`Assoc [
    ("brand", `String brand);
    ("model", `String model);
    ("year", `Int year);
    ("price", `String price);
    ("mileage", `String mileage);
    ("fuel_type", `String fuel_type);
    ("color", `String color);
    ("transmission", `String transmission);
    ("description", `String description);
    ("detailed_description_md", `String description);
    ("image", `String image);
    ("images", images_json);
    ("seller_name", `String seller_name);
    ("seller_phone", `String seller_phone);
    ("seller_email", `String seller_email);
    ("condition", `String condition);
    ("location_city", `String location_city);
    ("location_state", `String location_state);
    ("source", `String "buscar");
    ("engine", (match engine with Some e -> `String e | None -> `Null));
    ("doors", `Int doors);
    ("body_style", (match body_style with Some b -> `String b | None -> `Null));
    ("financing_available", `Bool financing_available);
    ("trade_accepted", `Bool trade_accepted);
    ("test_drive_available", `Bool test_drive_available);
    ("exterior_condition", (match exterior_condition with Some e -> `String e | None -> `Null));
    ("interior_condition", (match interior_condition with Some i -> `String i | None -> `Null));
    ("mechanical_condition", (match mechanical_condition with Some m -> `String m | None -> `Null));
    ("previous_owners", `Int previous_owners);
  ]) in
  http_post ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let data = Yojson.Safe.Util.member "data" json in
          let id = Yojson.Safe.Util.member "id" data |> Yojson.Safe.Util.to_int in
          let slug = Yojson.Safe.Util.member "slug" data |> Yojson.Safe.Util.to_string in
          Lwt.return (Ok (id, slug))
        else
          let msg = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return (Error msg)
      with e ->
        Logs.err (fun m -> m "Failed to parse create vehicle response: %s" (Printexc.to_string e));
        Lwt.return (Error ("Erro ao criar veículo: " ^ Printexc.to_string e)))
  | None ->
      Lwt.return (Error "Erro ao criar veículo: sem resposta do servidor")

(* Update vehicle *)
let update_vehicle ?session vehicle_id brand model year price mileage fuel_type color transmission 
    description image images seller_name seller_phone seller_email condition location_city location_state
    engine doors body_style financing_available trade_accepted test_drive_available
    exterior_condition interior_condition mechanical_condition previous_owners =
  let url = backend_url ^ "/api/vehicles/" ^ string_of_int vehicle_id in
  let images_json = `List (List.map (fun img -> `String img) images) in
  let body = Yojson.Safe.to_string (`Assoc [
    ("brand", `String brand);
    ("model", `String model);
    ("year", `Int year);
    ("price", `String price);
    ("mileage", `String mileage);
    ("fuel_type", `String fuel_type);
    ("color", `String color);
    ("transmission", `String transmission);
    ("description", `String description);
    ("detailed_description_md", `String description);
    ("image", `String image);
    ("images", images_json);
    ("seller_name", `String seller_name);
    ("seller_phone", `String seller_phone);
    ("seller_email", `String seller_email);
    ("condition", `String condition);
    ("location_city", `String location_city);
    ("location_state", `String location_state);
    ("source", `String "buscar");
    ("engine", (match engine with Some e -> `String e | None -> `Null));
    ("doors", `Int doors);
    ("body_style", (match body_style with Some b -> `String b | None -> `Null));
    ("financing_available", `Bool financing_available);
    ("trade_accepted", `Bool trade_accepted);
    ("test_drive_available", `Bool test_drive_available);
    ("exterior_condition", (match exterior_condition with Some e -> `String e | None -> `Null));
    ("interior_condition", (match interior_condition with Some i -> `String i | None -> `Null));
    ("mechanical_condition", (match mechanical_condition with Some m -> `String m | None -> `Null));
    ("previous_owners", `Int previous_owners);
  ]) in
  http_put ?session url ~body >>= function
  | Some json_str ->
      (try
        let json = Yojson.Safe.from_string json_str in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        if success then
          let data = Yojson.Safe.Util.member "data" json in
          let id = Yojson.Safe.Util.member "id" data |> Yojson.Safe.Util.to_int in
          let slug = Yojson.Safe.Util.member "slug" data |> Yojson.Safe.Util.to_string in
          Lwt.return (Ok (id, slug))
        else
          let msg = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
          Lwt.return (Error msg)
      with e ->
        Logs.err (fun m -> m "Failed to parse update vehicle response: %s" (Printexc.to_string e));
        Lwt.return (Error ("Erro ao atualizar veículo: " ^ Printexc.to_string e)))
  | None ->
      Lwt.return (Error "Erro ao atualizar veículo: sem resposta do servidor")

(* Delete vehicle (soft delete) *)
let delete_vehicle ?session vehicle_id =
  let url = backend_url ^ "/api/vehicles/" ^ string_of_int vehicle_id in
  http_delete ?session url >>= function
  | Some json_str ->
      (try
        (* Handle empty response *)
        if json_str = "" || String.trim json_str = "" then
          Lwt.return (Ok ())
        else
          let json = Yojson.Safe.from_string json_str in
          let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
          if success then
            Lwt.return (Ok ())
          else
            let msg = Yojson.Safe.Util.member "message" json |> Yojson.Safe.Util.to_string in
            Lwt.return (Error msg)
      with e ->
        (* If parsing fails but we got a response, assume success *)
        if json_str <> "" then
          (Logs.warn (fun m -> m "Delete response parse warning: %s, but assuming success" (Printexc.to_string e));
           Lwt.return (Ok ()))
        else
          (Logs.err (fun m -> m "Failed to parse delete vehicle response: %s" (Printexc.to_string e));
           Lwt.return (Error ("Erro ao deletar veículo: " ^ Printexc.to_string e))))
  | None ->
      Lwt.return (Error "Erro ao deletar veículo: sem resposta do servidor")

