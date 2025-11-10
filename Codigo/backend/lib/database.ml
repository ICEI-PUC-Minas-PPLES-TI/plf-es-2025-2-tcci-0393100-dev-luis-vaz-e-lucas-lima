(* Database connection module - Pure DB access *)

open Lwt.Infix

let db_uri = lazy (Uri.of_string Config.database_url)

let with_connection f =
  Caqti_lwt_unix.connect (Lazy.force db_uri) >>= function
  | Ok conn ->
      f conn >>= (function
      | Ok result -> Lwt.return result
      | Error err ->
          Logs.err (fun m -> m "Database error: %s" (Caqti_error.show err));
          Lwt.fail_with ("Database error: " ^ Caqti_error.show err))
  | Error err ->
      Logs.err (fun m -> m "Connection error: %s" (Caqti_error.show err));
      Lwt.fail_with ("Connection failed: " ^ Caqti_error.show err)

let init () =
  Logs.info (fun m -> m "Initializing database");
  with_connection (fun _conn -> Lwt.return_ok ()) >>= fun () ->
  Logs.info (fun m -> m "Database connected");
  Lwt.return_unit

(* Query module *)
module Q = struct
  open Caqti_request.Infix
  open Caqti_type.Std
  
  (* Parse PostgreSQL array to list *)
  let parse_array str =
    if str = "{}" || str = "" then []
    else
      let cleaned = String.sub str 1 (String.length str - 2) in
      if cleaned = "" then []
      else String.split_on_char ',' cleaned
  
  (* User queries *)
  let find_user_by_email =
    (string ->! t3 int string string)
    "SELECT user_id, name, email FROM users WHERE email = $1 AND is_active = TRUE"
  
  let find_user_by_id =
    (int ->! t3 int string string)
    "SELECT user_id, name, email FROM users WHERE user_id = $1 AND is_active = TRUE"
  
  let get_user_password_hash =
    (string ->! string)
    "SELECT password_hash FROM users WHERE email = $1 AND is_active = TRUE"
  
  (* Count queries *)
  let count_vehicles =
    (unit ->! int)
    "SELECT COUNT(*)::int FROM vehicles WHERE is_active = TRUE"
  
  let count_vehicles_by_source =
    (string ->! int)
    "SELECT COUNT(*)::int FROM vehicles WHERE is_active = TRUE AND source = $1"
  
  let increment_views =
    (string ->. unit)
    "UPDATE vehicles SET views_count = views_count + 1 WHERE slug = $1"
  
  (* Session queries *)
  let create_session =
    (t3 string int string ->. unit)
    "INSERT INTO sessions (session_id, user_id, expires_at) VALUES ($1, $2, $3)"
  
  let find_session =
    (string ->? t2 string int)
    "SELECT session_id, user_id FROM sessions WHERE session_id = $1 AND expires_at > CURRENT_TIMESTAMP"
  
  let delete_session =
    (string ->. unit)
    "DELETE FROM sessions WHERE session_id = $1"
  
  let update_session_activity =
    (string ->. unit)
    "UPDATE sessions SET last_activity = CURRENT_TIMESTAMP WHERE session_id = $1"
  
  (* Get full vehicle as JSON - then parse in OCaml *)
  let get_vehicle_json =
    (string ->! string)
    {| SELECT row_to_json(v)::text FROM (
         SELECT * FROM vehicles WHERE slug = $1 AND is_active = TRUE
       ) v |}
  
  let list_vehicles_json =
    (t2 int int ->* string)
    {| SELECT row_to_json(v)::text FROM (
         SELECT * FROM vehicles 
         WHERE is_active = TRUE
         ORDER BY created_at DESC
         LIMIT $1 OFFSET $2
       ) v |}
  
  let list_vehicles_json_by_source =
    (t3 string int int ->* string)
    {| SELECT row_to_json(v)::text FROM (
         SELECT * FROM vehicles 
         WHERE is_active = TRUE AND source = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3
       ) v |}
end
