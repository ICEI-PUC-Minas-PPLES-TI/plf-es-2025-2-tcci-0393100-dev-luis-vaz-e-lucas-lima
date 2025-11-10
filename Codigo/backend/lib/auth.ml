(* Authentication module with password hashing using Cryptokit *)

open Lwt.Infix

(* Simple password hashing using SHA-256 with salt *)
let hash_password password =
  let salt = "buscar_salt_change_in_production" in  (* In production, use unique salts *)
  let hash = Cryptokit.Hash.sha256 () in
  Cryptokit.hash_string hash (salt ^ password)
  |> Cryptokit.transform_string (Cryptokit.Hexa.encode ())

(* Verify a password against a hash *)
let verify_password password hash_str =
  let computed_hash = hash_password password in
  String.equal computed_hash hash_str

(* Generate session ID *)
let generate_session_id () =
  Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string

(* Calculate session expiration date *)
let session_expires_at () =
  let now = Ptime_clock.now () in
  let days = Ptime.Span.of_int_s (Config.session_duration_days * 86400) in
  match Ptime.add_span now days with
  | Some time -> Ptime.to_rfc3339 time
  | None -> 
      (* Fallback to 30 days from now *)
      let now_seconds = Ptime.to_float_s now in
      let future_seconds = now_seconds +. (float_of_int Config.session_duration_days *. 86400.0) in
      match Ptime.of_float_s future_seconds with
      | Some t -> Ptime.to_rfc3339 t
      | None -> failwith "Failed to calculate expiration time"

(* Create a new session *)
let create_session user_id =
  let session_id = generate_session_id () in
  let expires_at = session_expires_at () in
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec Database.Q.create_session (session_id, user_id, expires_at)
  ) >>= fun () ->
  Lwt.return session_id

(* Validate session and return user_id *)
let validate_session session_id =
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt Database.Q.find_session session_id
  ) >>= function
  | Some (_session_id, user_id) ->
      (* Update last activity *)
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.exec Database.Q.update_session_activity session_id
      ) >>= fun () ->
      Lwt.return_some user_id
  | None -> Lwt.return_none

(* Delete session (logout) *)
let delete_session session_id =
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec Database.Q.delete_session session_id
  )

(* Authenticate user with email and password *)
let authenticate email password =
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt Database.Q.get_user_password_hash email
  ) >>= function
  | Some hash_str ->
      if verify_password password hash_str then
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt Database.Q.find_user_by_email email
        ) >>= (function
        | Some (user_id, name, email) ->
            create_session user_id >>= fun session_id ->
            let user = Types.{
              user_id;
              name;
              email;
              password_hash = "";
              phone = None;
              created_at = "";
              updated_at = "";
              is_active = true;
              is_verified = true;
              subscription_tier = "individual";
            } in
            Lwt.return_ok (session_id, user)
        | None -> Lwt.return_error "User not found")
      else
        Lwt.return_error "Invalid password"
  | None -> Lwt.return_error "User not found"

(* Get user from session *)
let get_user_from_session session_id =
  validate_session session_id >>= function
  | Some user_id ->
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.find_opt Database.Q.find_user_by_id user_id
      ) >>= (function
      | Some (user_id, name, email) ->
          let user = Types.{
            user_id;
            name;
            email;
            password_hash = "";
            phone = None;
            created_at = "";
            updated_at = "";
            is_active = true;
            is_verified = true;
            subscription_tier = "individual";
          } in
          Lwt.return_some user
      | None -> Lwt.return_none)
  | None -> Lwt.return_none
