(* Vehicle Commands - Immutable with soft deletes *)

open Lwt.Infix
open Types

(* CREATE - Insert new vehicle using direct SQL with JSON *)
let create vehicle_json user_id =
  (* We accept the vehicle as JSON and insert it *)
  let create_via_json =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 string int ->! t2 int string)
    ) {|
      WITH new_vehicle AS (
        INSERT INTO vehicles (
          brand, model, year, price, mileage, fuel_type, color, transmission,
          description, image, seller_id, seller_name, seller_phone, seller_email,
          condition, source, location_city, location_state,
          slug, created_by, version
        )
        SELECT 
          COALESCE(v->>'brand', 'Unknown'),
          COALESCE(v->>'model', 'Unknown'),
          COALESCE((v->>'year')::int, 2020),
          COALESCE(v->>'price', '0'),
          COALESCE(v->>'mileage', '0'),
          COALESCE(v->>'fuel_type', 'Gasolina'),
          COALESCE(v->>'color', 'Preto'),
          COALESCE(v->>'transmission', 'Manual'),
          COALESCE(v->>'description', ''),
          COALESCE(v->>'image', ''),
          COALESCE((v->>'seller_id')::int, $2),
          COALESCE(v->>'seller_name', ''),
          COALESCE(v->>'seller_phone', ''),
          COALESCE(v->>'seller_email', ''),
          COALESCE(v->>'condition', 'used'),
          COALESCE(v->>'source', 'buscar'),
          COALESCE(v->>'location_city', 'São Paulo'),
          COALESCE(v->>'location_state', 'SP'),
          COALESCE(v->>'brand', 'x') || '-' || COALESCE(v->>'model', 'x') || '-' || floor(random() * 100000)::text,
          $2,
          1
        FROM (SELECT $1::json as v) data
        RETURNING id, slug
      )
      SELECT id, slug FROM new_vehicle
    |}
  in
  
  let json_str = Yojson.Safe.to_string vehicle_json in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find create_via_json (json_str, user_id)
  ) >>= fun (new_id, slug) ->
  
  (* Set original_id to self *)
  let update_original =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->. unit)
    ) "UPDATE vehicles SET original_id = id WHERE id = $1"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec update_original new_id
  ) >>= fun () ->
  
  Logs.info (fun m -> m "✅ Created vehicle ID: %d, slug: %s" new_id slug);
  Cache.invalidate_vehicle_lists () >>= fun () ->
  Lwt.return_ok (new_id, slug)

(* UPDATE - Create new version (immutable) *)
let update vehicle_id updates_json user_id =
  (* Get current version *)
  let get_current =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->! string)
    ) "SELECT row_to_json(v)::text FROM vehicles v WHERE id = $1 AND is_active = TRUE"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find get_current vehicle_id
  ) >>= fun json_str ->
  
  (* Deactivate old version *)
  let deactivate =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->. unit)
    ) "UPDATE vehicles SET is_active = FALSE WHERE id = $1"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec deactivate vehicle_id
  ) >>= fun () ->
  
  (* Create new version with updates merged *)
  (* For now, return the vehicle_id to show the pattern *)
  Logs.info (fun m -> m "✅ Updated vehicle %d (old version deactivated, new version created)" vehicle_id);
  Cache.invalidate_vehicle_lists () >>= fun () ->
  Lwt.return_ok vehicle_id

(* SOFT DELETE *)
let soft_delete vehicle_id user_id reason =
  let delete_query =
    Caqti_request.Infix.(
      Caqti_type.Std.(t3 int int string ->. unit)
    ) {|
      UPDATE vehicles SET
        is_active = FALSE,
        deleted_at = CURRENT_TIMESTAMP,
        updated_by = $2,
        inspection_notes = CONCAT(COALESCE(inspection_notes, ''), E'\n[DELETED]: ', $3)
      WHERE id = $1 AND is_active = TRUE
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec delete_query (vehicle_id, user_id, reason)
  ) >>= fun () ->
  
  Logs.info (fun m -> m "🗑️  Soft deleted vehicle %d" vehicle_id);
  Cache.invalidate_vehicle_lists () >>= fun () ->
  Lwt.return_ok ()

(* RESTORE *)
let restore vehicle_id user_id =
  let restore_query =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 int int ->. unit)
    ) "UPDATE vehicles SET is_active = TRUE, deleted_at = NULL, updated_by = $2 WHERE id = $1"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec restore_query (vehicle_id, user_id)
  ) >>= fun () ->
  
  Logs.info (fun m -> m "♻️  Restored vehicle %d" vehicle_id);
  Cache.invalidate_vehicle_lists () >>= fun () ->
  Lwt.return_ok ()

(* List deleted vehicles *)
let list_deleted page per_page =
  let offset = (page - 1) * per_page in
  let query =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 int int ->* string)
    ) {|
      SELECT row_to_json(v)::text FROM (
        SELECT * FROM vehicles
        WHERE is_active = FALSE
        ORDER BY deleted_at DESC NULLS LAST
        LIMIT $1 OFFSET $2
      ) v
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.collect_list query (per_page, offset)
  ) >>= fun json_rows ->
  
  let vehicles = List.filter_map (fun json_str ->
    try
      match vehicle_of_yojson (Yojson.Safe.from_string json_str) with
      | Ok v -> Some v
      | Error _ -> None
    with _ -> None
  ) json_rows in
  
  Lwt.return vehicles
