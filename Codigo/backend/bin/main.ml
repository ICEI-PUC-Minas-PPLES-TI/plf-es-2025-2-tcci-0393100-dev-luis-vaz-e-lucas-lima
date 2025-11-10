(* BusCars Backend API Server *)

open Lwt.Infix
open Buscar_backend_lib

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

(* JSON response helper *)
let json_response ?(status=`OK) json =
  Dream.json ~status (Yojson.Safe.to_string json)

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
      success_response "User retrieved" (Types.user_to_yojson user)
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
  let page = Dream.query request "page" |> Option.map int_of_string |> Option.value ~default:1 in
  let per_page = Dream.query request "per_page" |> Option.map int_of_string |> Option.value ~default:Config.default_page_size in
  let sort_by = Dream.query request "sort" in
  
  let per_page = min per_page Config.max_page_size in
  
  let filters = Types.{
    brand; model; year_min; year_max; price_min; price_max;
    fuel_type; condition; source; location_state;
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
      Lwt.async (fun () -> Repository.Vehicle.increment_views slug);
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

(* UPDATE vehicle endpoint - Creates NEW version (immutable) *)
let update_vehicle_handler request =
  match Dream.field request user_field with
  | Some user ->
      let vehicle_id = Dream.param request "id" |> int_of_string in
      Dream.body request >>= fun body ->
      (try
        let json = Yojson.Safe.from_string body in
        Vehicle_commands.update vehicle_id json user.user_id >>= function
        | Ok new_version_id ->
            Logs.info (fun m -> m "✅ Created new version for vehicle %d" vehicle_id);
            success_response "Vehicle updated (new version created)" (`Assoc [
              ("original_id", `Int vehicle_id);
              ("new_version_id", `Int new_version_id);
              ("immutable", `Bool true)
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

(* Swagger/OpenAPI documentation endpoints *)
let swagger_json_handler _request =
  Dream.respond ~headers:[("Content-Type", "application/json")] Swagger.swagger_spec

let swagger_ui_handler _request =
  Dream.html Swagger.swagger_ui_html

(* Main router *)
let router = Dream.router [
  Dream.options "/**" cors_preflight;
  
  (* Documentation *)
  Dream.get  "/api/docs" swagger_ui_handler;
  Dream.get  "/api/swagger.json" swagger_json_handler;
  
  (* Public endpoints *)
  Dream.get  "/health" health_handler;
  Dream.post "/api/auth/login" login_handler;
  Dream.post "/api/auth/logout" logout_handler;
  Dream.get  "/api/vehicles" list_vehicles_handler;
  Dream.get  "/api/vehicles/:slug" get_vehicle_handler;
  
  (* Protected endpoints - Authentication required *)
  Dream.get  "/api/auth/me" (require_auth me_handler);
  
  (* CRUD endpoints - Protected *)
  Dream.post   "/api/vehicles" (require_auth create_vehicle_handler);
  Dream.put    "/api/vehicles/:id" (require_auth update_vehicle_handler);
  Dream.delete "/api/vehicles/:id" (require_auth delete_vehicle_handler);
  Dream.post   "/api/vehicles/:id/restore" (require_auth restore_vehicle_handler);
  Dream.get    "/api/vehicles/deleted/list" (require_auth list_deleted_vehicles_handler);
]

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
  
  (* Initialize services *)
  Lwt_main.run (initialize ());
  
  (* Start server *)
  Logs.info (fun m -> m "Starting BusCars Backend API on %s:%d" 
    Config.server_host Config.server_port);
  
  Dream.run
    ~interface:Config.server_host
    ~port:Config.server_port
  @@ Dream.logger
  @@ cors_middleware
  @@ router

