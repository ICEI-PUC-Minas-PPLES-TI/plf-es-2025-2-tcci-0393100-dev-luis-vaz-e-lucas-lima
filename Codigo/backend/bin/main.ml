(* BusCars Backend API Server *)

open Lwt.Infix
open Buscar_backend_lib

module StringSet = Set.Make (String)

module Fipe_client = Buscar_backend_lib.Fipe

let normalize_key s =
  let cleaned = String.lowercase_ascii (String.trim s) in
  (* Normalize GM - Chevrolet and variations to chevrolet *)
  if cleaned = "gm" || cleaned = "gm - chevrolet" || cleaned = "gm-chevrolet" ||
     cleaned = "chevrolet" ||
     (String.contains cleaned 'g' && String.contains cleaned 'm' && 
      String.contains cleaned 'c' && String.contains cleaned 'h' && 
      String.contains cleaned 'e' && String.contains cleaned 'v' && 
      String.contains cleaned 'r' && String.contains cleaned 'o' && 
      String.contains cleaned 'l' && String.contains cleaned 't') then
    "chevrolet"
  (* Normalize VW - VolksWagen and variations to volkswagen *)
  else if cleaned = "vw" || cleaned = "vw - volkswagen" || cleaned = "vw-volkswagen" ||
          cleaned = "volkswagen" ||
          (String.contains cleaned 'v' && String.contains cleaned 'w' && 
           String.contains cleaned 'o' && String.contains cleaned 'l' && 
           String.contains cleaned 'k' && String.contains cleaned 's' && 
           String.contains cleaned 'a' && String.contains cleaned 'g' && 
           String.contains cleaned 'e' && String.contains cleaned 'n') then
    "volkswagen"
  else
    cleaned

let has_digit s =
  let rec loop i =
    if i >= String.length s then false
    else
      match s.[i] with
      | '0' .. '9' -> true
      | _ -> loop (i + 1)
  in
  loop 0

let trim_markers = [
  "altis"; "xei"; "gli"; "gls"; "xrs"; "xri"; "xli"; "xl"; "xle"; "xlt";
  "premium"; "prem"; "platinum"; "sport"; "hybrid"; "híbrido"; "limited";
  "turbo"; "flex"; "aut"; "auto"; "autom"; "automatico"; "automático";
  "manual"; "mt"; "cv"; "xls"; "xrx"; "xre"; "xrt"; "xrv"; "xsd"; "xse";
  "hpe"; "hpe-s"; "le"; "se"; "dx"; "dx/"; "wg"; "sw"; "s"; "x"; "xs";
  "x-way"; "ready"; "ready!"; "jipe"; "picape"; "cd"; "cs"; "chassi";
  "minibus"; "lx"; "ls"; "lt"; "limited"; "gts"; "gl"; "glx"; "sr"; "srv";
  "sdrive"; "xdrive";
]

let preserve_second_tokens = [
  "cross"; "fielder"; "cruiser"; "t-100"; "gr"; "gr-sport"; "grsport";
  "band"; "supra"; "prelude"; "land"; "rav4"; "hilux"; "mr"; "yaris";
  "sw4"; "camry"; "avalon"; "paseo";
]

let purge_parentheses s =
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

let purge_punctuation s =
  String.map
    (function
      | '.' | '-' | '/' | '!' | ',' | ';' -> ' '
      | c -> c)
    s

let normalize_whitespace s =
  s
  |> String.trim
  |> String.split_on_char ' '
  |> List.filter (fun part -> part <> "")
  |> String.concat " "

let canonical_model_name name =
  let cleaned =
    name
    |> purge_parentheses
    |> purge_punctuation
    |> normalize_whitespace
  in
  let tokens =
    cleaned
    |> String.split_on_char ' '
    |> List.filter (fun part -> part <> "")
    |> List.map String.lowercase_ascii
  in
  match tokens with
  | [] -> ""
  | [single] -> single
  | first :: second :: _ ->
      if List.mem second preserve_second_tokens then
        first ^ " " ^ second
      else if has_digit second || List.mem second trim_markers then
        first
      else
        first ^ " " ^ second

(* CORS middleware *)
let cors_middleware inner_handler request =
  let origin = Dream.header request "Origin" |> Option.value ~default:"*" in
  let response = inner_handler request in
  response >>= fun resp ->
  Dream.add_header resp "Access-Control-Allow-Origin" origin;
  Dream.add_header resp "Access-Control-Allow-Methods" (String.concat ", " Config.cors_allowed_methods);
  Dream.add_header resp "Access-Control-Allow-Headers" (String.concat ", " Config.cors_allowed_headers);
  Dream.add_header resp "Access-Control-Allow-Credentials" "true";
  Lwt.return resp

(* OPTIONS handler for CORS preflight *)
let cors_preflight _request =
  Dream.respond ~status:`OK ""

(* JSON response helper - using pretty_to_string to avoid Unicode escaping *)
let json_response ?(status=`OK) json =
  let json_str = Yojson.Safe.pretty_to_string ~std:true json in
  Dream.json ~status json_str

(* Error response helper *)
let error_response ?(status=`Bad_Request) message =
  let response = Types.{
    success = false;
    message;
    data = None;
  } in
  json_response ~status (Types.api_response_to_yojson response)

(* Success response helper *)
let success_response ?(status=`OK) message data =
  let response = Types.{
    success = true;
    message;
    data = Some data;
  } in
  json_response ~status (Types.api_response_to_yojson response)

(* Extract session from request *)
let get_session request =
  Dream.header request "Authorization" |> function
  | Some auth when String.length auth > 7 && String.sub auth 0 7 = "Bearer " ->
      Some (String.sub auth 7 (String.length auth - 7))
  | _ -> Dream.cookie request "session_id"

(* Create user field *)
let user_field : Buscar_backend_lib.Types.user Dream.field = Dream.new_field ()

(* Authentication middleware *)
let require_auth handler request =
  match get_session request with
  | Some session_id ->
      Auth.get_user_from_session session_id >>= (function
      | Some user ->
          Dream.set_field request user_field user;
          handler request
      | None -> error_response ~status:`Unauthorized "Invalid or expired session")
  | None -> error_response ~status:`Unauthorized "Authentication required"

(* Health check endpoint *)
let health_handler _request =
  let response = `Assoc [
    ("status", `String "healthy");
    ("service", `String "buscar-backend");
    ("timestamp", `String (Ptime_clock.now () |> Ptime.to_rfc3339));
  ] in
  json_response response

(* Login endpoint *)
let login_handler request =
  Dream.body request >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let login_req = Types.login_request_of_yojson json in
    match login_req with
    | Ok { email; password } ->
        Auth.authenticate email password >>= (function
        | Ok (session_id, user) ->
            let response = Types.{
              success = true;
              message = "Login successful";
              session_id = Some session_id;
              user = Some user;
            } in
            json_response (Types.login_response_to_yojson response)
        | Error msg ->
            let response = Types.{
              success = false;
              message = msg;
              session_id = None;
              user = None;
            } in
            json_response ~status:`Unauthorized (Types.login_response_to_yojson response))
    | Error _ -> error_response "Invalid request format"
  with _ -> error_response "Invalid JSON"

(* Registration endpoint *)
let register_handler request =
  Dream.body request >>= fun body ->
  try
    let json = Yojson.Safe.from_string body in
    let register_req = Types.register_request_of_yojson json in
    match register_req with
    | Ok { name; email; password; phone; document_number; 
           address_street; address_number; address_complement;
           address_neighborhood; address_city; address_state; address_zipcode;
           referral_code } ->
        (* Check if email already exists *)
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find Database.Q.check_email_exists email
        ) >>= fun email_exists ->
        if email_exists then
          error_response "Email já está em uso"
        else
          (* Check if referral code exists and is available *)
          Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
            Db.find_opt Database.Q.find_referral_code_by_code referral_code
          ) >>= (function
          | Some (code_id, _created_by, _code, is_active) ->
              if not is_active then
                error_response "Código de acesso inválido ou inativo"
              else
                (* Check if code is already used *)
                Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                  Db.find Database.Q.check_referral_code_used code_id
                ) >>= fun code_used ->
                if code_used then
                  error_response "Código de acesso já foi utilizado"
                else
                  (* Create user *)
                  let password_hash = Auth.hash_password password in
                  let complement = match address_complement with Some c -> c | None -> "" in
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.exec Database.Q.create_user 
                      (name, email, password_hash, phone, document_number,
                       address_street, address_number, complement,
                       address_neighborhood, address_city, address_state, address_zipcode)
                  ) >>= fun () ->
                  (* Get the new user ID *)
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.find Database.Q.find_user_by_email email
                  ) >>= fun (user_id, _, _) ->
                  (* Update user with referral code *)
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.exec Database.Q.update_user_referred_by (user_id, code_id)
                  ) >>= fun () ->
                  (* Mark referral code as used *)
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.exec Database.Q.use_referral_code (code_id, user_id)
                  ) >>= fun () ->
                  (* Create session *)
                  Auth.create_session user_id >>= fun session_id ->
                  (* Get full user data *)
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.collect_list Database.Q.get_full_user_by_id user_id
                  ) >>= fun user_json_list ->
                  (match user_json_list with
                   | [user_json] ->
                       (match Types.user_of_yojson (Yojson.Safe.from_string user_json) with
                        | Ok user ->
                            let response = Types.{
                              success = true;
                              message = "Registro realizado com sucesso";
                              session_id = Some session_id;
                              user = Some user;
                            } in
                            json_response (Types.login_response_to_yojson response)
                        | Error _ -> error_response "Erro ao criar usuário")
                   | _ -> error_response "Erro ao recuperar dados do usuário")
          | None -> error_response "Código de acesso inválido")
    | Error msg -> error_response ("Formato de requisição inválido: " ^ msg)
  with exn -> error_response ("Erro no registro: " ^ Printexc.to_string exn)

(* Logout endpoint *)
let logout_handler request =
  match get_session request with
  | Some session_id ->
      Auth.delete_session session_id >>= fun () ->
      success_response "Logged out successfully" (`Assoc [])
  | None -> error_response "No active session"

(* Get current user endpoint *)
let me_handler request =
  match Dream.field request user_field with
  | Some user ->
      (* Remove password_hash before sending to frontend *)
      let user_json = Types.user_to_yojson user in
      let user_json = match user_json with
        | `Assoc fields ->
            `Assoc (List.filter (fun (k, _) -> k <> "password_hash") fields)
        | other -> other
      in
      success_response "User retrieved" user_json
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* List vehicles endpoint *)
let list_vehicles_handler request =
  let brand = Dream.query request "brand" in
  let model = Dream.query request "model" in
  let year_min = Dream.query request "year_min" |> Option.map int_of_string in
  let year_max = Dream.query request "year_max" |> Option.map int_of_string in
  let price_min = Dream.query request "price_min" |> Option.map int_of_string in
  let price_max = Dream.query request "price_max" |> Option.map int_of_string in
  let fuel_type = Dream.query request "fuel_type" in
  let condition = Dream.query request "condition" in
  let source = Dream.query request "source" in
  let location_state = Dream.query request "location_state" in
  let location_city = Dream.query request "location_city" in
  let seller_id = Dream.query request "seller_id" |> Option.map int_of_string in
  let page = Dream.query request "page" |> Option.map int_of_string |> Option.value ~default:1 in
  let per_page = Dream.query request "per_page" |> Option.map int_of_string |> Option.value ~default:Config.default_page_size in
  let sort_by = Dream.query request "sort" in
  
  let per_page = min per_page Config.max_page_size in
  
  let filters = Types.{
    brand; model; year_min; year_max; price_min; price_max;
    fuel_type; condition; source; location_state; location_city; seller_id;
    page; per_page; sort_by;
  } in
  
  Repository.Vehicle.list filters >>= fun response ->
  json_response (Types.vehicle_list_response_to_yojson response)

(* Get vehicle by slug endpoint *)
let get_vehicle_handler request =
  let slug = Dream.param request "slug" in
  Repository.Vehicle.get_by_slug slug >>= function
  | Some vehicle ->
      (* Increment view count asynchronously *)
      success_response "Vehicle retrieved" (Types.vehicle_to_yojson vehicle)
  | None -> error_response ~status:`Not_Found "Vehicle not found"

(* CREATE vehicle endpoint *)
let create_vehicle_handler request =
  match Dream.field request user_field with
  | Some user ->
      Dream.body request >>= fun body ->
      (try
        let json = Yojson.Safe.from_string body in
        Vehicle_commands.create json user.user_id >>= function
        | Ok (new_id, slug) ->
            Logs.info (fun m -> m "✅ Created vehicle ID: %d" new_id);
            success_response ~status:`Created "Vehicle created" (`Assoc [
              ("id", `Int new_id);
              ("slug", `String slug);
              ("version", `Int 1)
            ])
        | Error msg -> error_response msg
      with e -> error_response ("JSON error: " ^ Printexc.to_string e))
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* Public endpoint for scraper app to bulk import vehicles - no auth required *)
let bulk_create_vehicles_scraper_handler request =
  (* Check authentication via X-Scraper-Key header *)
  match Dream.header request "X-Scraper-Key" with
  | Some key -> 
      let expected_key = match Sys.getenv_opt "CRON_JOB_KEY" with Some k -> k | None -> "default-cron-key-change-me" in
      if key <> expected_key then
        error_response ~status:`Unauthorized "Invalid scraper key"
      else
        Dream.body request >>= fun body ->
        (try
          let json = Yojson.Safe.from_string body in
          (* Expect a JSON array of vehicles *)
          match json with
          | `List vehicles_json ->
              (* Validate all vehicles have valid source *)
              let valid_vehicles = List.filter_map (fun v ->
                try
                  let source = Yojson.Safe.Util.member "source" v |> Yojson.Safe.Util.to_string_option in
                  match source with
                  | Some s when s <> "buscar" && (s = "localiza" || s = "icarros" || s = "webmotors") -> Some v
                  | _ -> None
                with _ -> None
              ) vehicles_json in
              
              if List.length valid_vehicles = 0 then
                error_response ~status:`Bad_Request "No valid vehicles to import"
              else
                (Logs.info (fun m -> m "📥 Bulk scraper import request: %d vehicles" (List.length valid_vehicles));
                 (* Try to import directly first *)
                 Vehicle_commands.bulk_create valid_vehicles 0 >>= function
                | Ok imported_count ->
                    Logs.info (fun m -> m "✅ Bulk imported %d vehicles" imported_count);
                    success_response ~status:`Created "Vehicles imported" (`Assoc [
                      ("imported_count", `Int imported_count);
                      ("total_count", `Int (List.length vehicles_json))
                    ])
                | Error msg ->
                    (* If direct import fails, enqueue to Redis for retry *)
                    Logs.warn (fun m -> m "⚠️ Bulk import failed, enqueueing to Redis: %s" msg);
                    Cache.enqueue_bulk_import valid_vehicles >>= function
                    | Ok () ->
                        Logs.info (fun m -> m "📥 Enqueued %d vehicles to Redis queue for retry" (List.length valid_vehicles));
                        success_response ~status:`Accepted "Vehicles enqueued for import" (`Assoc [
                          ("enqueued_count", `Int (List.length valid_vehicles));
                          ("total_count", `Int (List.length vehicles_json));
                          ("message", `String "Vehicles enqueued due to import error, will be processed shortly")
                        ])
                    | Error queue_error ->
                        Logs.err (fun m -> m "❌ Failed to enqueue vehicles: %s" queue_error);
                        error_response ("Import failed and queue failed: " ^ msg))
          | _ ->
              error_response ~status:`Bad_Request "Expected JSON array of vehicles"
        with e -> error_response ("JSON error: " ^ Printexc.to_string e))
  | None -> 
      error_response ~status:`Unauthorized "X-Scraper-Key header required"

(* Public endpoint for scraper app to import vehicles - no auth required *)
let create_vehicle_scraper_handler request =
  (* Check authentication via X-Scraper-Key header *)
  match Dream.header request "X-Scraper-Key" with
  | Some key -> 
      let expected_key = match Sys.getenv_opt "CRON_JOB_KEY" with Some k -> k | None -> "default-cron-key-change-me" in
      if key <> expected_key then
        error_response ~status:`Unauthorized "Invalid scraper key"
      else
        Dream.body request >>= fun body ->
        (try
          let json = Yojson.Safe.from_string body in
          (* Validate that source is external (not "buscar") *)
          let source = try
            Yojson.Safe.Util.member "source" json |> Yojson.Safe.Util.to_string_option
          with _ -> None in
          
          match source with
          | Some s when s <> "buscar" && (s = "localiza" || s = "icarros" || s = "webmotors") ->
              (* Log incoming request *)
              let brand = try Yojson.Safe.Util.member "brand" json |> Yojson.Safe.Util.to_string_option with _ -> None in
              let model = try Yojson.Safe.Util.member "model" json |> Yojson.Safe.Util.to_string_option with _ -> None in
              (Logs.info (fun m -> m "📥 Scraper import request: %s %s from %s" 
                (Option.value ~default:"?" brand) (Option.value ~default:"?" model) s);
               (* Use system user ID (0) for scraper imports *)
               Vehicle_commands.create json 0 >>= function
               | Ok (new_id, slug) ->
                   (Logs.info (fun m -> m "✅ Scraper imported vehicle ID: %d from %s (slug: %s, is_active should be TRUE)" new_id s slug);
                    Cache.invalidate_vehicle_lists () >>= fun () ->
                    success_response ~status:`Created "Vehicle imported" (`Assoc [
                      ("id", `Int new_id);
                      ("slug", `String slug);
                      ("version", `Int 1)
                    ]))
               | Error msg ->
                   (Logs.err (fun m -> m "❌ Scraper import failed for %s: %s. JSON preview: %s" s msg 
                     (if String.length (Yojson.Safe.pretty_to_string json) > 500 then
                       String.sub (Yojson.Safe.pretty_to_string json) 0 500 ^ "..."
                     else
                       Yojson.Safe.pretty_to_string json));
                    error_response msg))
          | Some "buscar" ->
              error_response ~status:`Forbidden "This endpoint is only for external scrapers. Use /api/vehicles for BusCars vehicles."
          | _ ->
              error_response ~status:`Bad_Request "Invalid or missing source. Must be 'localiza', 'icarros', or 'webmotors'"
        with e -> error_response ("JSON error: " ^ Printexc.to_string e))
  | None -> 
      error_response ~status:`Unauthorized "X-Scraper-Key header required"

(* UPDATE vehicle endpoint - Creates NEW version (immutable) *)
let update_vehicle_handler request =
  match Dream.field request user_field with
  | Some user ->
      let vehicle_id = Dream.param request "id" |> int_of_string in
      Dream.body request >>= fun body ->
      (try
        let json = Yojson.Safe.from_string body in
        Vehicle_commands.update_direct vehicle_id json user.user_id >>= function
        | Ok (updated_id, slug) ->
            Logs.info (fun m -> m "✅ Directly updated vehicle %d" vehicle_id);
            success_response "Vehicle updated" (`Assoc [
              ("id", `Int updated_id);
              ("slug", `String slug)
            ])
        | Error msg -> error_response msg
      with e -> error_response ("JSON error: " ^ Printexc.to_string e))
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* DELETE vehicle endpoint (soft delete) - Protected *)
let delete_vehicle_handler request =
  match Dream.field request user_field with
  | Some user ->
      let vehicle_id = Dream.param request "id" |> int_of_string in
      let reason = Dream.query request "reason" |> Option.value ~default:"User requested deletion" in
      
      Vehicle_commands.soft_delete vehicle_id user.user_id reason >>= fun result ->
      (match result with
      | Ok () ->
          Logs.info (fun m -> m "Soft deleted vehicle %d by user %d" vehicle_id user.user_id);
          success_response "Vehicle deleted (soft delete)" (`Assoc [("vehicle_id", `Int vehicle_id)])
      | Error msg -> error_response msg)
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* RESTORE vehicle endpoint - Protected *)
let restore_vehicle_handler request =
  match Dream.field request user_field with
  | Some user ->
      let vehicle_id = Dream.param request "id" |> int_of_string in
      
      Vehicle_commands.restore vehicle_id user.user_id >>= fun result ->
      (match result with
      | Ok () ->
          Logs.info (fun m -> m "Restored vehicle %d by user %d" vehicle_id user.user_id);
          success_response "Vehicle restored" (`Assoc [("vehicle_id", `Int vehicle_id)])
      | Error msg -> error_response msg)
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* List deleted vehicles - Admin only *)
let list_deleted_vehicles_handler request =
  match Dream.field request user_field with
  | Some _user ->
      let page = Dream.query request "page" |> Option.map int_of_string |> Option.value ~default:1 in
      let per_page = Dream.query request "per_page" |> Option.map int_of_string |> Option.value ~default:20 in
      
      Vehicle_commands.list_deleted page per_page >>= fun vehicles ->
      let response = `Assoc [
        ("vehicles", `List (List.map Types.vehicle_to_yojson vehicles));
        ("count", `Int (List.length vehicles));
      ] in
      success_response "Deleted vehicles retrieved" response
  | None -> error_response ~status:`Unauthorized "Not authenticated"

(* Deactivate stale external vehicles handler *)
(* This endpoint can be called by cron jobs or admin users *)
let deactivate_stale_vehicles_handler request =
  (* Check if user is authenticated and is admin, or if it's a cron job (check for API key in header) *)
  let is_cron_job = 
    match Dream.header request "X-Cron-Job-Key" with
    | Some key -> key = (match Sys.getenv_opt "CRON_JOB_KEY" with Some k -> k | None -> "default-cron-key-change-me")
    | None -> false
  in
  
  (* Get days parameter from request body or use default *)
  Dream.body request >>= fun body ->
  let days = 
    try
      let json = Yojson.Safe.from_string body in
      match Yojson.Safe.Util.member "days" json with
      | `Int d -> max 1 d (* Garantir pelo menos 1 dia *)
      | `Float f -> max 1 (int_of_float f)
      | _ -> 3
    with _ -> 3 (* Default: 3 dias *)
  in
  
  (* If cron job, allow without authentication *)
  if is_cron_job then
    Vehicle_commands.deactivate_stale_external_vehicles ~days >>= fun result ->
    (match result with
    | Ok count ->
        Logs.info (fun m -> m "🧹 Maintenance (cron): Deactivated %d stale external vehicles (not updated in %d+ days)" count days);
        success_response "Veículos desativados com sucesso"
          (`Assoc [
            ("deactivated_count", `Int count);
            ("message", `String (Printf.sprintf "Foram desativados %d veículos de terceiros que não foram atualizados há mais de %d dia(s)" count days));
          ])
    | Error msg ->
        Logs.err (fun m -> m "❌ Error deactivating stale vehicles: %s" msg);
        error_response ~status:`Internal_Server_Error ("Erro ao desativar veículos: " ^ msg))
  else
    (* For non-cron requests, validate session manually *)
    match get_session request with
    | Some session_id ->
        Auth.get_user_from_session session_id >>= (function
        | Some user when user.is_admin ->
            Vehicle_commands.deactivate_stale_external_vehicles ~days >>= fun result ->
            (match result with
            | Ok count ->
                Logs.info (fun m -> m "🧹 Maintenance: Deactivated %d stale external vehicles (not updated in %d+ days)" count days);
                success_response "Veículos desativados com sucesso"
                  (`Assoc [
                    ("deactivated_count", `Int count);
                    ("message", `String (Printf.sprintf "Foram desativados %d veículos de terceiros que não foram atualizados há mais de %d dia(s)" count days));
                  ])
            | Error msg ->
                Logs.err (fun m -> m "❌ Error deactivating stale vehicles: %s" msg);
                error_response ~status:`Internal_Server_Error ("Erro ao desativar veículos: " ^ msg))
        | Some _ ->
            error_response ~status:`Forbidden "Apenas administradores ou cron jobs podem executar esta operação"
        | None ->
            error_response ~status:`Unauthorized "Sessão inválida ou expirada")
    | None ->
        error_response ~status:`Unauthorized "Não autenticado"

(* FIPE helpers *)
let fipe_brands_handler request =
  let vehicle_type = Dream.query request "vehicle_type" |> Option.value ~default:Config.fipe_default_vehicle_type in
  let reference = Dream.query request "reference" in
  Fipe_client.get_brands ~vehicle_type ?reference () >>= function
  | Ok brands ->
      Repository.Vehicle.list_active_brands () >>= fun db_brands ->
      let brand_set =
        List.fold_left
          (fun acc name ->
            if String.trim name = "" then acc else StringSet.add (normalize_key name) acc)
          StringSet.empty db_brands
      in
      let filtered =
        List.filter (fun (brand : Types.fipe_brand) ->
          let normalized_fipe = normalize_key brand.name in
          (* Check if normalized FIPE brand matches any DB brand *)
          StringSet.mem normalized_fipe brand_set ||
          (* Special case: if FIPE has "Chevrolet" (from "GM - Chevrolet"), check if DB has "Chevrolet" *)
          (normalized_fipe = "chevrolet" && 
           (* Check if any DB brand, when normalized, is "chevrolet" *)
           StringSet.exists (fun db_brand -> normalize_key db_brand = "chevrolet") brand_set) ||
          (* Special case: if FIPE has "Volkswagen" (from "VW - VolksWagen"), check if DB has "Volkswagen" *)
          (normalized_fipe = "volkswagen" && 
           (* Check if any DB brand, when normalized, is "volkswagen" *)
           StringSet.exists (fun db_brand -> normalize_key db_brand = "volkswagen") brand_set)
        ) brands
      in
      (* Normalize brand names before returning (e.g., "GM - Chevrolet" -> "Chevrolet", "VW - VolksWagen" -> "Volkswagen") *)
      let normalized_brands =
        List.map (fun (brand : Types.fipe_brand) ->
          let normalized_key = normalize_key brand.name in
          let normalized_name = 
            if normalized_key = "chevrolet" then "Chevrolet"
            else if normalized_key = "volkswagen" then "Volkswagen"
            else brand.name
          in
          { brand with name = normalized_name }
        ) filtered
      in
      let data = `Assoc [
        ("vehicle_type", `String vehicle_type);
        ("reference", match reference with Some r -> `String r | None -> `Null);
        ("brands", `List (List.map Types.fipe_brand_to_yojson normalized_brands));
      ] in
      success_response "FIPE brands retrieved" data
  | Error msg ->
      Logs.err (fun m -> m "Failed to get FIPE brands: %s" msg);
      error_response ~status:`Bad_Gateway "Unable to fetch FIPE brands"

(* Get models from database with Redis cache (10 minutes) *)
let db_models_handler request =
  let brand = Dream.param request "brand" in
  let cache_key = Printf.sprintf "db:models:%s" (String.lowercase_ascii brand) in
  let cache_ttl = 600 in (* 10 minutes *)
  
  (* Try to get from cache first *)
  Cache.get cache_key >>= function
  | Some cached_json ->
      Logs.info (fun m -> m "📦 Models cache hit for brand: %s" brand);
      (try
        let json = Yojson.Safe.from_string cached_json in
        success_response "Models retrieved from cache" json
      with e ->
        Logs.warn (fun m -> m "Failed to parse cached models, fetching from DB: %s" (Printexc.to_string e));
        (* If cache is corrupted, fetch from DB *)
        Repository.Vehicle.list_active_models brand >>= fun models ->
        let models_json = `List (List.map (fun m -> `String m) models) in
        let data = `Assoc [
          ("brand", `String brand);
          ("models", models_json);
        ] in
        let data_json = Yojson.Safe.to_string data in
        Cache.set cache_key data_json cache_ttl >>= fun () ->
        success_response "Models retrieved" data)
  | None ->
      Logs.info (fun m -> m "📥 Fetching models from DB for brand: %s" brand);
      Repository.Vehicle.list_active_models brand >>= fun models ->
      let models_json = `List (List.map (fun m -> `String m) models) in
      let data = `Assoc [
        ("brand", `String brand);
        ("models", models_json);
      ] in
      let data_json = Yojson.Safe.to_string data in
      Cache.set cache_key data_json cache_ttl >>= fun () ->
      Logs.info (fun m -> m "✅ Cached models for brand: %s (%d models)" brand (List.length models));
      success_response "Models retrieved" data

let db_cities_handler request =
  let state = Dream.param request "state" in
  (* New cache key with version to invalidate old cache *)
  let cache_key = Printf.sprintf "cities:v2:%s" (String.uppercase_ascii state) in
  let cache_ttl = 3600 in (* 1 hour - máximo 1 hora de cache *)
  
  (* Process cities: fix UTF-8, normalize, and ensure uniqueness *)
  (* Use the same fix_city_name function from Repository to ensure consistency *)
  let process_cities cities =
    (* Fix and normalize all cities using the same function used for vehicles *)
    let fixed = List.map Repository.Vehicle.fix_city_name cities in
    (* Use Hashtbl for deduplication with normalized (case-insensitive UTF-8) keys *)
    (* This ensures "Uberlândia", "UberlÂndia", "Uberl\u00e2ndia" all become the same *)
    let city_map = Hashtbl.create (List.length fixed) in
    List.iter (fun city ->
      (* Create normalized key using UTF-8 aware lowercase for comparison *)
      (* This catches duplicates: "Uberlândia", "UberlÂndia", "Uberl\u00e2ndia" -> all "uberlândia" *)
      let normalized_key = Repository.Vehicle.normalized_city_key city in
      (* Keep the first (best) normalized version if we have duplicates *)
      if not (Hashtbl.mem city_map normalized_key) then
        Hashtbl.add city_map normalized_key city
    ) fixed;
    (* Convert hashtable to sorted list *)
    let unique_cities = Hashtbl.fold (fun _ city acc -> city :: acc) city_map [] in
    List.sort String.compare unique_cities
  in
  
  (* Try to get from cache first *)
  Cache.get cache_key >>= function
  | Some cached_json ->
      Logs.info (fun m -> m "📦 Cities cache hit for state: %s" state);
      (try
        (* Cache stores the data object as JSON string, parse it and return *)
        let data = Yojson.Safe.from_string cached_json in
        success_response "Cities retrieved from cache" data
      with e ->
        Logs.warn (fun m -> m "Failed to parse cached cities, fetching from DB: %s" (Printexc.to_string e));
        (* If cache is corrupted, fetch from DB *)
        Repository.Vehicle.list_active_cities state >>= fun cities ->
        let processed_cities = process_cities cities in
        let cities_json = `List (List.map (fun c -> `String c) processed_cities) in
        let data = `Assoc [
          ("state", `String state);
          ("cities", cities_json);
        ] in
        let data_json = Yojson.Safe.to_string data in
        Cache.set cache_key data_json cache_ttl >>= fun () ->
        success_response "Cities retrieved" data)
  | None ->
      Logs.info (fun m -> m "📥 Fetching cities from DB for state: %s" state);
      Repository.Vehicle.list_active_cities state >>= fun cities ->
      let processed_cities = process_cities cities in
      let cities_json = `List (List.map (fun c -> `String c) processed_cities) in
      let data = `Assoc [
        ("state", `String state);
        ("cities", cities_json);
      ] in
      let data_json = Yojson.Safe.to_string data in
      Cache.set cache_key data_json cache_ttl >>= fun () ->
      Logs.info (fun m -> m "✅ Cached cities for state: %s (%d unique cities, TTL: %d seconds)" state (List.length processed_cities) cache_ttl);
      success_response "Cities retrieved" data

let fipe_models_handler request =
  let vehicle_type = Dream.query request "vehicle_type" |> Option.value ~default:Config.fipe_default_vehicle_type in
  let reference = Dream.query request "reference" in
  let brand_code = Dream.param request "brand_code" in
  Fipe_client.get_models ~vehicle_type ?reference ~brand_code () >>= function
  | Ok models ->
      Fipe_client.get_brand_by_code ~vehicle_type ?reference ~brand_code () >>= (function
      | Ok brand ->
      Repository.Vehicle.list_active_models brand.Types.name >>= fun db_models ->
          let model_set =
            List.fold_left
              (fun acc name ->
                let canonical = canonical_model_name name in
                if canonical = "" then acc else StringSet.add canonical acc)
              StringSet.empty db_models
          in
          let filtered =
            List.filter (fun (model : Types.fipe_model) ->
              let canonical = canonical_model_name model.name in
          canonical <> "" && StringSet.mem canonical model_set) models
          in
          let data = `Assoc [
            ("vehicle_type", `String vehicle_type);
            ("reference", match reference with Some r -> `String r | None -> `Null);
            ("brand_code", `String brand_code);
            ("models", `List (List.map Types.fipe_model_to_yojson filtered));
          ] in
          success_response "FIPE models retrieved" data
      | Error _ ->
          error_response ~status:`Not_Found "Brand not recognized")
  | Error msg ->
      Logs.err (fun m -> m "Failed to get FIPE models for brand %s: %s" brand_code msg);
      error_response ~status:`Bad_Gateway "Unable to fetch FIPE models"

(* FIPE references handler *)
let fipe_references_handler request =
  Fipe_client.get_references () >>= function
  | Ok references ->
      let data = `Assoc [
        ("references", `List (List.map Types.fipe_reference_to_yojson references));
      ] in
      success_response "FIPE references retrieved" data
  | Error msg ->
      Logs.err (fun m -> m "Failed to get FIPE references: %s" msg);
      error_response ~status:`Bad_Gateway "Unable to fetch FIPE references"

(* FIPE years handler *)
let fipe_years_handler request =
  let vehicle_type = Dream.query request "vehicle_type" |> Option.value ~default:Config.fipe_default_vehicle_type in
  let reference = Dream.query request "reference" in
  let brand_code = Dream.param request "brand_code" in
  let model_code = Dream.param request "model_code" in
  Fipe_client.get_years ~vehicle_type ?reference ~brand_code ~model_code () >>= function
  | Ok years ->
      let data = `Assoc [
        ("vehicle_type", `String vehicle_type);
        ("reference", match reference with Some r -> `String r | None -> `Null);
        ("brand_code", `String brand_code);
        ("model_code", `String model_code);
        ("years", `List (List.map Types.fipe_year_to_yojson years));
      ] in
      success_response "FIPE years retrieved" data
  | Error msg ->
      Logs.err (fun m -> m "Failed to get FIPE years: %s" msg);
      error_response ~status:`Bad_Gateway "Unable to fetch FIPE years"

(* FIPE price handler *)
let fipe_price_handler request =
  let vehicle_type = Dream.query request "vehicle_type" |> Option.value ~default:Config.fipe_default_vehicle_type in
  let reference = Dream.query request "reference" in
  let brand_code = Dream.param request "brand_code" in
  let model_code = Dream.param request "model_code" in
  let year_id = Dream.param request "year_id" in
  Fipe_client.get_vehicle_price ~vehicle_type ?reference ~brand_code ~model_code ~year_id () >>= function
  | Ok detail ->
      success_response "FIPE price retrieved" (Types.fipe_vehicle_detail_to_yojson detail)
  | Error msg ->
      Logs.err (fun m -> m "Failed to get FIPE price: %s" msg);
      error_response ~status:`Bad_Gateway ("Unable to fetch FIPE price: " ^ msg)

(* Generate random referral code *)
let generate_referral_code () =
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" in
  let len = String.length chars in
  let rec gen n acc =
    if n = 0 then acc
    else
      let idx = Random.int len in
      gen (n - 1) (String.make 1 chars.[idx] :: acc)
  in
  "REF" ^ String.concat "" (gen 8 [])

(* Generate unique referral code *)
let rec generate_unique_code () =
  let candidate = generate_referral_code () in
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt Database.Q.find_referral_code_by_code candidate
  ) >>= function
  | Some _ -> generate_unique_code () (* Code exists, try again *)
  | None -> Lwt.return candidate

(* Referral code management handlers *)
let create_referral_code_handler request =
  match Dream.field request user_field with
  | Some user ->
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let code_opt = try
            Some (Yojson.Safe.Util.member "code" json |> Yojson.Safe.Util.to_string)
          with _ -> None in
          (match code_opt with
           | Some c when String.trim c <> "" ->
               let code = String.trim c in
               Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                 Db.find_opt Database.Q.find_referral_code_by_code code
               ) >>= (function
               | Some _ -> error_response "Código já existe"
               | None ->
                   Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                     Db.exec Database.Q.create_referral_code (code, user.user_id, true)
                   ) >>= fun () ->
                   success_response "Código de acesso criado com sucesso" (`Assoc [("code", `String code)]))
           | _ ->
               (* Generate random code if not provided *)
               generate_unique_code () >>= fun code ->
               Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                 Db.exec Database.Q.create_referral_code (code, user.user_id, true)
               ) >>= fun () ->
               success_response "Código de acesso criado com sucesso" (`Assoc [("code", `String code)]))
        )
        (fun exn -> error_response ("Erro ao criar código de acesso: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

let list_referral_codes_handler request =
  match Dream.field request user_field with
  | Some user ->
      let page = Dream.query request "page" |> Option.map int_of_string |> Option.value ~default:1 in
      let per_page = Dream.query request "per_page" |> Option.map int_of_string |> Option.value ~default:5 in
      let search = Dream.query request "search" |> Option.value ~default:"" in
      let status_filter = Dream.query request "status" |> Option.value ~default:"all" in
      let offset = (page - 1) * per_page in
      (if user.is_admin then
         (* Admin: see all codes with filters *)
         Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
           Db.collect_list Database.Q.list_all_referral_codes_filtered (per_page, offset, search, status_filter)
         ) >>= fun codes_json ->
         Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
           Db.find Database.Q.count_all_referral_codes_filtered (search, status_filter)
         ) >>= fun total_count ->
         let codes = List.filter_map (fun json_str ->
           match Types.referral_code_of_yojson (Yojson.Safe.from_string json_str) with
           | Ok code -> Some code
           | Error _ -> None
         ) codes_json in
         let total_pages = (total_count + per_page - 1) / per_page in
         Logs.info (fun m -> m "📊 Admin: Retrieved %d codes (page %d/%d, showing %d)" total_count page total_pages (List.length codes));
         success_response "Códigos de acesso recuperados" 
           (`Assoc [
             ("codes", `List (List.map Types.referral_code_to_yojson codes));
             ("total_count", `Int total_count);
             ("page", `Int page);
             ("per_page", `Int per_page);
             ("total_pages", `Int total_pages);
             ("has_next", `Bool (page < total_pages));
             ("has_prev", `Bool (page > 1));
           ])
       else
         (* User: see only their codes with filters *)
         Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
           Db.collect_list Database.Q.list_referral_codes_by_user_filtered (user.user_id, per_page, offset, search, status_filter)
         ) >>= fun codes_json ->
         Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
           Db.find Database.Q.count_referral_codes_by_user_filtered (user.user_id, search, status_filter)
         ) >>= fun total_count ->
         let codes = List.filter_map (fun json_str ->
           match Types.referral_code_of_yojson (Yojson.Safe.from_string json_str) with
           | Ok code -> Some code
           | Error _ -> None
         ) codes_json in
         let total_pages = (total_count + per_page - 1) / per_page in
         Logs.info (fun m -> m "📊 User %d: Retrieved %d codes (page %d/%d, showing %d)" user.user_id total_count page total_pages (List.length codes));
         success_response "Códigos de acesso recuperados" 
           (`Assoc [
             ("codes", `List (List.map Types.referral_code_to_yojson codes));
             ("total_count", `Int total_count);
             ("page", `Int page);
             ("per_page", `Int per_page);
             ("total_pages", `Int total_pages);
             ("has_next", `Bool (page < total_pages));
             ("has_prev", `Bool (page > 1));
           ]))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

let deactivate_referral_code_handler request =
  match Dream.field request user_field with
  | Some user ->
      if not user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem desativar códigos"
      else
        let code_id = Dream.param request "code_id" |> int_of_string in
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec Database.Q.deactivate_referral_code code_id
        ) >>= fun () ->
        success_response "Código de acesso desativado" (`Assoc [])
  | None -> error_response ~status:`Unauthorized "Não autenticado"

let deactivate_all_referral_codes_handler request =
  match Dream.field request user_field with
  | Some user ->
      if not user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem desativar códigos"
      else
        (* Count active codes before deactivating *)
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find Database.Q.count_all_referral_codes_filtered ("", "available")
        ) >>= fun active_count ->
        (* Deactivate all active codes *)
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec Database.Q.deactivate_all_referral_codes ()
        ) >>= fun () ->
        success_response "Todos os códigos de acesso foram desativados" 
          (`Assoc [("total_deactivated", `Int active_count)])
  | None -> error_response ~status:`Unauthorized "Não autenticado"

(* User management handlers (admin only) *)
let list_users_handler request =
  match Dream.field request user_field with
  | Some user ->
      if not user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem listar usuários"
      else
        let page = 
          match Dream.query request "page" with
          | Some p -> (try int_of_string p with _ -> 1)
          | None -> 1
        in
        let per_page = 
          match Dream.query request "per_page" with
          | Some p -> (try int_of_string p with _ -> 12)
          | None -> 12
        in
        let search = 
          match Dream.query request "search" with
          | Some s -> String.trim s
          | None -> ""
        in
        let role_filter = 
          match Dream.query request "role" with
          | Some r -> String.trim r
          | None -> "all"
        in
        let sort = 
          match Dream.query request "sort" with
          | Some s -> String.trim s
          | None -> "created_desc"
        in
        let offset = (page - 1) * per_page in
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find Database.Q.count_users_filtered (search, role_filter)
        ) >>= fun total_count ->
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list Database.Q.list_users_filtered (per_page, offset, search, role_filter, sort)
        ) >>= fun users_json ->
        let users = List.filter_map (fun json_str ->
          match Types.user_of_yojson (Yojson.Safe.from_string json_str) with
          | Ok u -> Some u
          | Error e -> 
              Logs.err (fun m -> m "Failed to parse user from database: %s" e);
              None
        ) users_json in
        (* Remove password_hash from user JSON before sending to frontend *)
        let users_json_clean = List.map (fun u ->
          let user_json = Types.user_to_yojson u in
          match user_json with
          | `Assoc fields ->
              `Assoc (List.filter (fun (k, _) -> k <> "password_hash") fields)
          | _ -> user_json
        ) users in
        let total_pages = (total_count + per_page - 1) / per_page in
        success_response "Usuários recuperados" 
          (`Assoc [
            ("users", `List users_json_clean);
            ("total_count", `Int total_count);
            ("page", `Int page);
            ("per_page", `Int per_page);
            ("total_pages", `Int total_pages);
            ("has_next", `Bool (page < total_pages));
            ("has_prev", `Bool (page > 1));
          ])
  | None -> error_response ~status:`Unauthorized "Não autenticado"

(* Distribute referral codes to users (admin only) *)
let distribute_referral_codes_handler request =
  match Dream.field request user_field with
  | Some user ->
      if not user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem distribuir códigos"
      else
        Dream.body request >>= fun body ->
        Lwt.catch
          (fun () ->
            let json = Yojson.Safe.from_string body in
            match Types.distribute_referral_codes_request_of_yojson json with
            | Ok { email; count } ->
                (* Get target users *)
                (match email with
                 | Some e when String.trim e <> "" && String.lowercase_ascii (String.trim e) <> "all" ->
                     (* Find user by email *)
                     Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                       Db.find_opt Database.Q.find_user_by_email_opt (String.trim e)
                     ) >>= (function
                     | Some (target_user_id, _, _) ->
                         (* Create codes for this user - codes should be created BY the target user, not the admin *)
                         let rec create_codes_for_user n acc =
                           if n = 0 then Lwt.return acc
                           else
                             generate_unique_code () >>= fun code ->
                             Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                               Db.exec Database.Q.create_referral_code (code, target_user_id, true)
                             ) >>= fun () ->
                             create_codes_for_user (n - 1) (code :: acc)
                         in
                         create_codes_for_user count [] >>= fun codes ->
                         success_response "Códigos distribuídos com sucesso"
                           (`Assoc [
                             ("codes", `List (List.map (fun c -> `String c) codes));
                             ("user_id", `Int target_user_id);
                             ("count", `Int count);
                           ])
                     | None -> error_response "Usuário não encontrado")
                 | _ ->
                     (* Distribute to all users *)
                     Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                       Db.collect_list Database.Q.list_all_users ()
                     ) >>= fun users_json ->
                     let users = List.filter_map (fun json_str ->
                       match Types.user_of_yojson (Yojson.Safe.from_string json_str) with
                       | Ok u -> Some u
                       | Error _ -> None
                     ) users_json in
                     let rec create_codes_for_all_users (user_list: Types.user list) (acc: (int * string) list) : (int * string) list Lwt.t =
                       match user_list with
                       | [] -> Lwt.return acc
                       | u :: rest ->
                           let rec create_codes_for_user n (codes_acc: (int * string) list) =
                             if n = 0 then Lwt.return codes_acc
                             else
                               generate_unique_code () >>= fun code ->
                               (* Create codes BY the target user, not the admin *)
                               Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                                 Db.exec Database.Q.create_referral_code (code, u.user_id, true)
                               ) >>= fun () ->
                               create_codes_for_user (n - 1) ((u.user_id, code) :: codes_acc)
                           in
                           create_codes_for_user count [] >>= fun user_codes ->
                           create_codes_for_all_users rest (user_codes @ acc)
                     in
                     create_codes_for_all_users users [] >>= fun all_codes ->
                     let codes_by_user = List.fold_left (fun acc (uid, code) ->
                       match List.assoc_opt uid acc with
                       | Some codes -> (uid, code :: codes) :: List.remove_assoc uid acc
                       | None -> (uid, [code]) :: acc
                     ) [] all_codes in
                     success_response "Códigos distribuídos com sucesso"
                       (`Assoc [
                         ("codes_by_user", `List (List.map (fun (uid, codes) ->
                           `Assoc [
                             ("user_id", `Int uid);
                             ("codes", `List (List.map (fun c -> `String c) codes));
                           ]
                         ) codes_by_user));
                         ("total_users", `Int (List.length users));
                         ("codes_per_user", `Int count);
                         ("total_codes", `Int (List.length all_codes));
                       ]))
            | Error msg -> error_response ("Formato de requisição inválido: " ^ msg))
          (fun exn -> error_response ("Erro ao distribuir códigos: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

let update_user_info_handler request =
  match Dream.field request user_field with
  | Some user ->
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          (* For non-admin users, preserve original values for name, phone, document_number, and email *)
          let (name, phone, document_number, email) = 
            if user.is_admin then
              (Yojson.Safe.Util.member "name" json |> Yojson.Safe.Util.to_string,
               Yojson.Safe.Util.member "phone" json |> Yojson.Safe.Util.to_string,
               Yojson.Safe.Util.member "document_number" json |> Yojson.Safe.Util.to_string,
               Yojson.Safe.Util.member "email" json |> Yojson.Safe.Util.to_string_option)
            else
              (user.name,
               Option.value ~default:"" user.phone,
               Option.value ~default:"" user.document_number,
               Some user.email)
          in
          let address_street = Yojson.Safe.Util.member "address_street" json |> Yojson.Safe.Util.to_string in
          let address_number = Yojson.Safe.Util.member "address_number" json |> Yojson.Safe.Util.to_string in
          let address_complement = Yojson.Safe.Util.member "address_complement" json |> Yojson.Safe.Util.to_string_option in
          let address_neighborhood = Yojson.Safe.Util.member "address_neighborhood" json |> Yojson.Safe.Util.to_string in
          let address_city = Yojson.Safe.Util.member "address_city" json |> Yojson.Safe.Util.to_string in
          let address_state = Yojson.Safe.Util.member "address_state" json |> Yojson.Safe.Util.to_string in
          let address_zipcode = Yojson.Safe.Util.member "address_zipcode" json |> Yojson.Safe.Util.to_string in
          let complement_str = match address_complement with Some c -> c | None -> "" in
          let email_str = match email with Some e -> e | None -> user.email in
          (* Use update_user_with_email if email is being updated (admin only), otherwise use update_user *)
          (if user.is_admin && email <> None then
             Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
               Db.exec Database.Q.update_user_with_email 
                 (user.user_id, name, email_str, phone, document_number,
                  address_street, address_number, complement_str,
                  address_neighborhood, address_city, address_state, address_zipcode)
             )
           else
             Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
               Db.exec Database.Q.update_user 
                 (user.user_id, name, phone, document_number,
                  address_street, address_number, complement_str,
                  address_neighborhood, address_city, address_state, address_zipcode)
             )) >>= fun () ->
          (* Get updated user *)
          Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
            Db.collect_list Database.Q.get_full_user_by_id user.user_id
          ) >>= fun user_json_list ->
          (match user_json_list with
           | [user_json] ->
               (match Types.user_of_yojson (Yojson.Safe.from_string user_json) with
                | Ok updated_user ->
                    (* Remove password_hash before sending to frontend *)
                    let user_json = Types.user_to_yojson updated_user in
                    let user_json = match user_json with
                      | `Assoc fields ->
                          `Assoc (List.filter (fun (k, _) -> k <> "password_hash") fields)
                      | other -> other
                    in
                    success_response "Informações atualizadas" user_json
                | Error _ -> error_response "Erro ao recuperar dados atualizados")
           | _ -> error_response "Erro ao recuperar dados atualizados")
        )
        (fun exn -> error_response ("Erro ao atualizar informações: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

let change_password_handler request =
  match Dream.field request user_field with
  | Some user ->
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          match Types.change_password_request_of_yojson (Yojson.Safe.from_string body) with
          | Ok { old_password; new_password } ->
              (* Verify old password *)
              Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                Db.find_opt Database.Q.get_user_password_hash user.email
              ) >>= (function
              | Some password_hash ->
                  if Auth.verify_password old_password password_hash then
                    (* Hash new password and update *)
                    let new_password_hash = Auth.hash_password new_password in
                    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                      Db.exec Database.Q.update_user_password (user.user_id, new_password_hash)
                    ) >>= fun () ->
                    success_response "Senha alterada com sucesso" (`Assoc [])
                  else
                    error_response "Senha atual incorreta"
              | None -> error_response "Erro ao verificar senha")
          | Error msg -> error_response ("Formato de requisição inválido: " ^ msg))
        (fun exn -> error_response ("Erro ao alterar senha: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

(* Admin update user handler *)
let admin_update_user_handler request =
  match Dream.field request user_field with
  | Some admin_user ->
      if not admin_user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem atualizar usuários"
      else
        let target_user_id = Dream.param request "user_id" |> int_of_string in
        Dream.body request >>= fun body ->
        Lwt.catch
          (fun () ->
            match Types.admin_update_user_request_of_yojson (Yojson.Safe.from_string body) with
            | Ok { name; email; phone; document_number; address_street; address_number;
                   address_complement; address_neighborhood; address_city; address_state; address_zipcode } ->
                let complement_str = match address_complement with Some c -> c | None -> "" in
                Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                  Db.exec Database.Q.update_user_with_email 
                    (target_user_id, name, email, phone, document_number,
                     address_street, address_number, complement_str,
                     address_neighborhood, address_city, address_state, address_zipcode)
                ) >>= fun () ->
                (* Get updated user *)
                Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                  Db.collect_list Database.Q.get_full_user_by_id target_user_id
                ) >>= fun user_json_list ->
                (match user_json_list with
                 | [user_json] ->
                     (match Types.user_of_yojson (Yojson.Safe.from_string user_json) with
                      | Ok updated_user ->
                          (* Remove password_hash before sending to frontend *)
                          let user_json = Types.user_to_yojson updated_user in
                          let user_json = match user_json with
                            | `Assoc fields ->
                                `Assoc (List.filter (fun (k, _) -> k <> "password_hash") fields)
                            | other -> other
                          in
                          success_response "Usuário atualizado com sucesso" user_json
                      | Error _ -> error_response "Erro ao recuperar dados atualizados")
                 | _ -> error_response "Erro ao recuperar dados atualizados")
            | Error msg -> error_response ("Formato de requisição inválido: " ^ msg))
          (fun exn -> error_response ("Erro ao atualizar usuário: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

(* Admin change user password handler *)
let admin_change_user_password_handler request =
  match Dream.field request user_field with
  | Some admin_user ->
      if not admin_user.is_admin then
        error_response ~status:`Forbidden "Apenas administradores podem alterar senhas de usuários"
      else
        Dream.body request >>= fun body ->
        Lwt.catch
          (fun () ->
            match Types.admin_change_user_password_request_of_yojson (Yojson.Safe.from_string body) with
            | Ok { user_id; new_password } ->
                (* Hash new password and update *)
                let new_password_hash = Auth.hash_password new_password in
                Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                  Db.exec Database.Q.update_user_password (user_id, new_password_hash)
                ) >>= fun () ->
                success_response "Senha do usuário alterada com sucesso" (`Assoc [])
            | Error msg -> error_response ("Formato de requisição inválido: " ^ msg))
          (fun exn -> error_response ("Erro ao alterar senha: " ^ Printexc.to_string exn))
  | None -> error_response ~status:`Unauthorized "Não autenticado"

(* Scraper jobs handlers *)
let list_scraper_jobs_handler request =
  match Dream.field request user_field with
  | Some user when user.is_admin ->
      Lwt.catch
        (fun () ->
          let search = Dream.query request "search" in
          let source = Dream.query request "source" in
          let page = match Dream.query request "page" with
            | Some p -> (try int_of_string p with _ -> 1)
            | None -> 1
          in
          let per_page = match Dream.query request "per_page" with
            | Some p -> (try int_of_string p with _ -> 10)
            | None -> 10
          in
          
          (* Ensure valid values *)
          let page = max 1 page in
          let per_page = max 1 (min per_page 100) in (* Min 1, Max 100 per page *)
          
          let filter = Types.{
            search;
            source;
            page;
            per_page;
          } in
          
          Logs.info (fun m -> m "📋 Listing scraper jobs - page: %d, per_page: %d, search: %s, source: %s" 
            page per_page 
            (match search with Some s -> s | None -> "none")
            (match source with Some s -> s | None -> "none"));
          
          Repository.ScraperJob.list filter >>= fun response ->
          Logs.info (fun m -> m "✅ Found %d scraper jobs (page %d/%d)" 
            response.total_count response.page response.total_pages);
          success_response "Scraper jobs recuperados" (Types.scraper_job_list_response_to_yojson response))
        (fun e ->
          Logs.err (fun m -> m "❌ Error in list_scraper_jobs_handler: %s" (Printexc.to_string e));
          error_response ~status:`Internal_Server_Error ("Erro ao listar scraper jobs: " ^ Printexc.to_string e))
  | Some _ ->
      error_response ~status:`Forbidden "Apenas administradores podem listar scraper jobs"
  | None ->
      error_response ~status:`Unauthorized "Não autenticado"

let get_scraper_job_handler request =
  match Dream.field request user_field with
  | Some user when user.is_admin ->
      let job_id_str = Dream.param request "id" in
      let job_id = try int_of_string job_id_str with _ -> 0 in
      if job_id > 0 then
        Repository.ScraperJob.get_by_id job_id >>= function
        | Some job -> success_response "Scraper job recuperado" (Types.scraper_job_to_yojson job)
        | None -> error_response ~status:`Not_Found "Scraper job não encontrado"
      else
        error_response ~status:`Bad_Request "ID inválido"
  | Some _ ->
      error_response ~status:`Forbidden "Apenas administradores podem visualizar scraper jobs"
  | None ->
      error_response ~status:`Unauthorized "Não autenticado"

let create_scraper_job_handler request =
  match Dream.field request user_field with
  | Some user when user.is_admin ->
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let brand = Yojson.Safe.Util.member "brand" json |> Yojson.Safe.Util.to_string in
          let model = Yojson.Safe.Util.member "model" json |> Yojson.Safe.Util.to_string in
          let source = Yojson.Safe.Util.member "source" json |> Yojson.Safe.Util.to_string in
          
          if brand = "" || model = "" || source = "" then
            error_response ~status:`Bad_Request "Brand, model e source são obrigatórios"
          else if not (List.mem source ["localiza"; "icarros"; "webmotors"]) then
            error_response ~status:`Bad_Request "Source deve ser 'localiza', 'icarros' ou 'webmotors'"
          else
            Repository.ScraperJob.create brand model source (Some user.user_id) >>= function
            | Some job ->
                success_response "Scraper job criado com sucesso" (Types.scraper_job_to_yojson job)
            | None ->
                error_response ~status:`Internal_Server_Error "Erro ao criar scraper job")
        (fun exn -> error_response ("Erro ao criar scraper job: " ^ Printexc.to_string exn))
  | Some _ ->
      error_response ~status:`Forbidden "Apenas administradores podem criar scraper jobs"
  | None ->
      error_response ~status:`Unauthorized "Não autenticado"

let update_scraper_job_handler request =
  match Dream.field request user_field with
  | Some user when user.is_admin ->
      let job_id_str = Dream.param request "id" in
      let job_id = try int_of_string job_id_str with _ -> 0 in
      if job_id > 0 then
        Dream.body request >>= fun body ->
        Lwt.catch
          (fun () ->
            let json = Yojson.Safe.from_string body in
            let brand = Yojson.Safe.Util.member "brand" json |> Yojson.Safe.Util.to_string in
            let model = Yojson.Safe.Util.member "model" json |> Yojson.Safe.Util.to_string in
            let source = Yojson.Safe.Util.member "source" json |> Yojson.Safe.Util.to_string in
            let is_active = 
              match Yojson.Safe.Util.member "is_active" json with
              | `Bool b -> b
              | _ -> true
            in
            
            if brand = "" || model = "" || source = "" then
              error_response ~status:`Bad_Request "Brand, model e source são obrigatórios"
            else if not (List.mem source ["localiza"; "icarros"; "webmotors"]) then
              error_response ~status:`Bad_Request "Source deve ser 'localiza', 'icarros' ou 'webmotors'"
            else
              Repository.ScraperJob.update job_id brand model source is_active >>= function
              | Some job ->
                  success_response "Scraper job atualizado com sucesso" (Types.scraper_job_to_yojson job)
              | None ->
                  error_response ~status:`Internal_Server_Error "Erro ao atualizar scraper job")
          (fun exn -> error_response ("Erro ao atualizar scraper job: " ^ Printexc.to_string exn))
      else
        error_response ~status:`Bad_Request "ID inválido"
  | Some _ ->
      error_response ~status:`Forbidden "Apenas administradores podem atualizar scraper jobs"
  | None ->
      error_response ~status:`Unauthorized "Não autenticado"

let delete_scraper_job_handler request =
  match Dream.field request user_field with
  | Some user when user.is_admin ->
      let job_id_str = Dream.param request "id" in
      let job_id = try int_of_string job_id_str with _ -> 0 in
      if job_id > 0 then
        Repository.ScraperJob.delete job_id >>= fun () ->
        success_response "Scraper job deletado com sucesso" (`Assoc [])
      else
        error_response ~status:`Bad_Request "ID inválido"
  | Some _ ->
      error_response ~status:`Forbidden "Apenas administradores podem deletar scraper jobs"
  | None ->
      error_response ~status:`Unauthorized "Não autenticado"

(* Public endpoint for scraper app - auth via X-Scraper-Key header *)
let list_active_scraper_jobs_handler request =
  match Dream.header request "X-Scraper-Key" with
  | Some key -> 
      let expected_key = match Sys.getenv_opt "CRON_JOB_KEY" with Some k -> k | None -> "default-cron-key-change-me" in
      if key = expected_key then
  Repository.ScraperJob.list_active () >>= fun jobs ->
  json_response (`List (List.map Types.scraper_job_to_yojson jobs))
      else
        error_response ~status:`Unauthorized "Invalid scraper key"
  | None -> 
      error_response ~status:`Unauthorized "X-Scraper-Key header required"

(* Public endpoint for scraper app to update job stats - auth via X-Scraper-Key header *)
let update_scraper_job_stats_handler request =
  match Dream.header request "X-Scraper-Key" with
  | Some key -> 
      let expected_key = match Sys.getenv_opt "CRON_JOB_KEY" with Some k -> k | None -> "default-cron-key-change-me" in
      if key = expected_key then
  let job_id_str = Dream.param request "id" in
  let job_id = try int_of_string job_id_str with _ -> 0 in
  if job_id > 0 then
    Dream.body request >>= fun body ->
    Lwt.catch
      (fun () ->
        let json = Yojson.Safe.from_string body in
        let success = Yojson.Safe.Util.member "success" json |> Yojson.Safe.Util.to_bool in
        Repository.ScraperJob.update_run_stats job_id success >>= fun () ->
        success_response "Estatísticas atualizadas" (`Assoc []))
      (fun exn -> error_response ("Erro ao atualizar estatísticas: " ^ Printexc.to_string exn))
  else
    error_response ~status:`Bad_Request "ID inválido"
      else
        error_response ~status:`Unauthorized "Invalid scraper key"
  | None -> 
      error_response ~status:`Unauthorized "X-Scraper-Key header required"

(* Swagger/OpenAPI documentation endpoints *)
let swagger_json_handler _request =
  Dream.respond ~headers:[("Content-Type", "application/json")] Swagger.swagger_spec

let swagger_ui_handler _request =
  Dream.html Swagger.swagger_ui_html

(* Proxy handler to bypass iframe restrictions *)
let proxy_handler request =
  let url_param = Dream.query request "url" in
  match url_param with
  | Some url when url <> "" ->
      let uri = try Uri.of_string url with _ -> Uri.empty in
      let _scheme = Uri.scheme uri |> Option.value ~default:"https" in
      let host = Uri.host uri |> Option.value ~default:"" in
      
      if host = "" then
        error_response ~status:`Bad_Request "Invalid URL"
      else
        let ctx = Lazy.force Fipe_client.cohttp_ctx in
        let headers = Cohttp.Header.init () in
        let headers = Cohttp.Header.add headers "User-Agent" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" in
        let headers = Cohttp.Header.add headers "Accept" "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" in
        let headers = Cohttp.Header.add headers "Accept-Language" "pt-BR,pt;q=0.9,en;q=0.8" in
        let headers = Cohttp.Header.add headers "Referer" (Uri.to_string uri) in
        
        Lwt.catch
          (fun () ->
            Cohttp_lwt_unix.Client.get ~ctx ~headers uri >>= fun (resp, body) ->
            let status = Cohttp.Response.status resp in
            let status_code = Cohttp.Code.code_of_status status in
            
            if status_code >= 400 then
              error_response ~status:`Bad_Gateway "Failed to fetch URL"
            else
              Cohttp_lwt.Body.to_string body >>= fun html_content ->
              
              (* Remove headers that block iframes *)
              let response_headers = Cohttp.Response.headers resp in
              let response_headers = Cohttp.Header.remove response_headers "x-frame-options" in
              let response_headers = Cohttp.Header.remove response_headers "X-Frame-Options" in
              let response_headers = Cohttp.Header.remove response_headers "content-security-policy" in
              let response_headers = Cohttp.Header.remove response_headers "Content-Security-Policy" in
              let response_headers = Cohttp.Header.remove response_headers "frame-options" in
              
              (* Add CORS headers to allow iframe embedding *)
              let response_headers = Cohttp.Header.add response_headers "X-Frame-Options" "ALLOWALL" in
              let response_headers = Cohttp.Header.add response_headers "Access-Control-Allow-Origin" "*" in
              
              (* Process HTML: convert relative URLs to absolute URLs *)
              (* For now, return HTML as-is - most modern sites block iframes anyway *)
              (* The main improvement is removing blocking headers above *)
              let processed_html = html_content in
              
              (* Create Dream response with headers *)
              let header_list = Cohttp.Header.to_list response_headers in
              let headers = List.map (fun (name, value) -> (name, value)) header_list in
              (* Ensure Content-Type is set to HTML *)
              let headers = ("Content-Type", "text/html; charset=utf-8") :: headers in
              Dream.respond ~headers ~status:`OK processed_html)
          (fun exn ->
            Logs.err (fun m -> m "Proxy error: %s" (Printexc.to_string exn));
            error_response ~status:`Bad_Gateway "Failed to proxy URL")
  | _ -> error_response ~status:`Bad_Request "URL parameter required"

(* Main router *)
let router = Dream.router [
  Dream.options "/**" cors_preflight;
  
  (* Documentation *)
  Dream.get  "/api/docs" swagger_ui_handler;
  Dream.get  "/api/swagger.json" swagger_json_handler;
  
  (* Public endpoints *)
  Dream.get  "/health" health_handler;
  Dream.post "/api/auth/login" login_handler;
  Dream.post "/api/auth/register" register_handler;
  Dream.post "/api/auth/logout" logout_handler;
  Dream.get  "/api/vehicles" list_vehicles_handler;
  Dream.get  "/api/vehicles/:slug" get_vehicle_handler;
  Dream.get  "/api/vehicles/models/:brand" db_models_handler;
  Dream.get  "/api/vehicles/cities/:state" db_cities_handler;
  Dream.get  "/api/fipe/brands" fipe_brands_handler;
  Dream.get  "/api/fipe/brands/:brand_code/models" fipe_models_handler;
  Dream.get  "/api/fipe/references" fipe_references_handler;
  Dream.get  "/api/fipe/brands/:brand_code/models/:model_code/years" fipe_years_handler;
  Dream.get  "/api/fipe/brands/:brand_code/models/:model_code/years/:year_id" fipe_price_handler;
  
  (* Proxy endpoint for external URLs (bypass iframe restrictions) *)
  Dream.get  "/api/proxy" proxy_handler;
  
  (* Public endpoints for scraper app - no auth required - MUST come before parameterized routes *)
  Dream.get    "/api/scraper-jobs/active" list_active_scraper_jobs_handler;
  Dream.post   "/api/scraper-jobs/:id/stats" update_scraper_job_stats_handler;
  Dream.post   "/api/vehicles/scraper" create_vehicle_scraper_handler;
  Dream.post   "/api/vehicles/scraper/bulk" bulk_create_vehicles_scraper_handler;
  
  (* Protected endpoints - Authentication required *)
  Dream.get  "/api/auth/me" (require_auth me_handler);
  Dream.put  "/api/auth/me" (require_auth update_user_info_handler);
  Dream.post "/api/auth/change-password" (require_auth change_password_handler);
  
  (* Admin user management *)
  Dream.put  "/api/users/:user_id" (require_auth admin_update_user_handler);
  Dream.post "/api/users/:user_id/change-password" (require_auth admin_change_user_password_handler);
  
  (* Referral code management *)
  Dream.post "/api/referral-codes" (require_auth create_referral_code_handler);
  Dream.get  "/api/referral-codes" (require_auth list_referral_codes_handler);
  Dream.post "/api/referral-codes/distribute" (require_auth distribute_referral_codes_handler);
  Dream.post "/api/referral-codes/:code_id/deactivate" (require_auth deactivate_referral_code_handler);
  Dream.post "/api/referral-codes/deactivate-all" (require_auth deactivate_all_referral_codes_handler);
  
  (* User management (admin only) *)
  Dream.get  "/api/users" (require_auth list_users_handler);
  
  (* CRUD endpoints - Protected *)
  Dream.post   "/api/vehicles" (require_auth create_vehicle_handler);
  Dream.put    "/api/vehicles/:id" (require_auth update_vehicle_handler);
  Dream.delete "/api/vehicles/:id" (require_auth delete_vehicle_handler);
  Dream.post   "/api/vehicles/:id/restore" (require_auth restore_vehicle_handler);
  Dream.get    "/api/vehicles/deleted/list" (require_auth list_deleted_vehicles_handler);
  
  (* Maintenance endpoint - Deactivate stale external vehicles (admin only or cron job) *)
  Dream.post   "/api/maintenance/deactivate-stale-vehicles" deactivate_stale_vehicles_handler;
  
  (* Scraper jobs management (admin only) *)
  Dream.get    "/api/scraper-jobs" (require_auth list_scraper_jobs_handler);
  Dream.get    "/api/scraper-jobs/:id" (require_auth get_scraper_job_handler);
  Dream.post   "/api/scraper-jobs" (require_auth create_scraper_job_handler);
  Dream.put    "/api/scraper-jobs/:id" (require_auth update_scraper_job_handler);
  Dream.delete "/api/scraper-jobs/:id" (require_auth delete_scraper_job_handler);
]

(* Worker to process bulk import queue *)
let rec process_bulk_import_queue () =
  Lwt.catch
    (fun () ->
      Cache.dequeue_bulk_import_batch ~batch_size:50 () >>= function
      | Some vehicles ->
          (Vehicle_commands.bulk_create vehicles 0 >>= function
          | Ok count ->
              Logs.info (fun m -> m "✅ Processed %d vehicles from queue" count);
              Lwt_unix.sleep 0.5 >>= fun () ->
              process_bulk_import_queue ()
          | Error msg ->
              Logs.err (fun m -> m "❌ Failed to process queue batch: %s, re-enqueueing" msg);
              (* Re-enqueue on failure *)
              Cache.enqueue_bulk_import vehicles >>= fun _ ->
              Lwt_unix.sleep 5.0 >>= fun () ->
              process_bulk_import_queue ())
      | None ->
          (* No items in queue, wait and retry *)
          Lwt_unix.sleep 10.0 >>= fun () ->
          process_bulk_import_queue ())
    (fun exn ->
      Logs.err (fun m -> m "❌ Exception in queue worker: %s" (Printexc.to_string exn));
      Lwt_unix.sleep 10.0 >>= fun () ->
      process_bulk_import_queue ())

(* Start queue worker in background *)
let start_queue_worker () =
  Lwt.async (fun () -> process_bulk_import_queue ())

(* Initialize services *)
let initialize () =
  Logs.info (fun m -> m "Initializing BusCars Backend...");
  
  (* Initialize database *)
  Database.init () >>= fun () ->
  Logs.info (fun m -> m "Database connected");
  
  (* Initialize Redis cache *)
  Cache.init () >>= fun () ->
  Logs.info (fun m -> m "Redis cache connected");
  
  Logs.info (fun m -> m "Backend initialization complete");
  Lwt.return_unit

(* Main application *)
let () =
  (* Setup logging *)
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Info);
  
  (* Initialize services and start queue worker *)
  Lwt_main.run (
    initialize () >>= fun () ->
    (* Start queue worker after initialization *)
    start_queue_worker ();
    Lwt.return_unit
  );
  
  (* Start server *)
  Logs.info (fun m -> m "Starting BusCars Backend API on %s:%d" 
    Config.server_host Config.server_port);
  
  Dream.run
    ~interface:Config.server_host
    ~port:Config.server_port
  @@ Dream.logger
  @@ cors_middleware
  @@ router


