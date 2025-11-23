(* Vehicle Commands - Immutable with soft deletes *)

open Lwt.Infix
open Types

(* Helper function to invalidate cache granularly based on vehicle data *)
let invalidate_cache_for_vehicle vehicle_json =
  let brand = Yojson.Safe.Util.member "brand" vehicle_json |> Yojson.Safe.Util.to_string_option in
  let model = Yojson.Safe.Util.member "model" vehicle_json |> Yojson.Safe.Util.to_string_option in
  let location_state = Yojson.Safe.Util.member "location_state" vehicle_json |> Yojson.Safe.Util.to_string_option in
  let location_city = Yojson.Safe.Util.member "location_city" vehicle_json |> Yojson.Safe.Util.to_string_option in
  let source = Yojson.Safe.Util.member "source" vehicle_json |> Yojson.Safe.Util.to_string_option in
  let condition = Yojson.Safe.Util.member "condition" vehicle_json |> Yojson.Safe.Util.to_string_option in
  Cache.invalidate_vehicle_lists_granular ?brand ?model ?location_state ?location_city ?source ?condition () >>= fun () ->
  Cache.invalidate_stats () >>= fun () ->
  Lwt.return_unit

(* Helper function to get vehicle attributes and invalidate cache granularly *)
let invalidate_cache_for_vehicle_id vehicle_id =
  let get_vehicle_attrs =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->! t6 (option string) (option string) (option string) (option string) (option string) (option string))
    ) "SELECT brand, model, location_state, location_city, source, condition FROM vehicles WHERE id = $1"
  in
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find get_vehicle_attrs vehicle_id
  ) >>= fun (brand, model, location_state, location_city, source, condition) ->
  Cache.invalidate_vehicle_lists_granular ?brand ?model ?location_state ?location_city ?source ?condition () >>= fun () ->
  Cache.invalidate_stats () >>= fun () ->
  Lwt.return_unit

(* BULK CREATE - Insert multiple vehicles in a single transaction *)
let bulk_create vehicles_json user_id =
  (* Use PostgreSQL's unnest with arrays for efficient bulk insert *)
  (* We do the INSERT/UPDATE first, then count separately to avoid CTE issues *)
  let bulk_insert_via_json =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 string int ->. unit)
    ) {|
      WITH vehicles_data AS (
        SELECT json_array_elements($1::json) AS v
      ),
      deduplicated_data AS (
        SELECT DISTINCT ON (
          COALESCE(v->>'source', 'buscar'),
          NULLIF(v->>'external_id', '')
        )
        v
        FROM vehicles_data
        WHERE NULLIF(v->>'external_id', '') IS NOT NULL
        ORDER BY 
          COALESCE(v->>'source', 'buscar'),
          NULLIF(v->>'external_id', ''),
          v::text  -- Convert JSON to text for ordering
      )
      INSERT INTO vehicles (
        brand, model, year, price, mileage, fuel_type, color, transmission,
        description, image, images, seller_id, seller_name, seller_phone, seller_email,
        condition, source, location_city, location_state,
        slug, created_by, version, external_id, external_url,
        engine, doors, body_style, financing_available, trade_accepted, test_drive_available,
        exterior_condition, interior_condition, mechanical_condition, previous_owners,
        detailed_description_md
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
        COALESCE(
          (SELECT ARRAY(SELECT json_array_elements_text(v->'images'))),
          ARRAY[]::text[]
        ),
        CASE WHEN $2 = 0 THEN NULL ELSE COALESCE((v->>'seller_id')::int, $2) END,
        COALESCE(NULLIF(v->>'seller_name', ''), 'Parceiro'),
        COALESCE(NULLIF(v->>'seller_phone', ''), 'Não informado'),
        COALESCE(NULLIF(v->>'seller_email', ''), 'nao-disponivel@buscar.com'),
        COALESCE(v->>'condition', 'used'),
        COALESCE(v->>'source', 'buscar'),
        COALESCE(v->>'location_city', 'São Paulo'),
        COALESCE(v->>'location_state', 'SP'),
        COALESCE(
          NULLIF(v->>'slug', ''),
          COALESCE(v->>'brand', 'x') || '-' || COALESCE(v->>'model', 'x') || '-' || COALESCE(v->>'external_id', '') || '-' || extract(epoch from now())::bigint::text || '-' || floor(random() * 1000000)::text
        ),
        CASE WHEN $2 = 0 THEN NULL ELSE $2 END,
        1,
        NULLIF(v->>'external_id', ''),
        NULLIF(v->>'external_url', ''),
        NULLIF(v->>'engine', ''),
        COALESCE((v->>'doors')::int, 4),
        NULLIF(v->>'body_style', ''),
        COALESCE((v->>'financing_available')::bool, false),
        COALESCE((v->>'trade_accepted')::bool, false),
        COALESCE((v->>'test_drive_available')::bool, false),
        NULLIF(v->>'exterior_condition', ''),
        NULLIF(v->>'interior_condition', ''),
        NULLIF(v->>'mechanical_condition', ''),
        COALESCE((v->>'previous_owners')::int, 1),
        COALESCE(v->>'description', '')
      FROM deduplicated_data
      ON CONFLICT (source, external_id)
      DO UPDATE SET
        brand = EXCLUDED.brand,
        model = EXCLUDED.model,
        year = EXCLUDED.year,
        price = EXCLUDED.price,
        mileage = CASE
                   WHEN EXCLUDED.mileage IS NOT NULL 
                        AND EXCLUDED.mileage != '' 
                        AND EXCLUDED.mileage != '0 km'
                        AND EXCLUDED.mileage != '0'
                   THEN EXCLUDED.mileage
                   ELSE vehicles.mileage
                 END,
        fuel_type = EXCLUDED.fuel_type,
        color = EXCLUDED.color,
        transmission = EXCLUDED.transmission,
        description = EXCLUDED.description,
        image = EXCLUDED.image,
        images = CASE
                   WHEN array_length(EXCLUDED.images, 1) IS NOT NULL
                        AND array_length(EXCLUDED.images, 1) > 0
                   THEN EXCLUDED.images
                   ELSE vehicles.images
                 END,
        condition = EXCLUDED.condition,
        location_city = EXCLUDED.location_city,
        location_state = EXCLUDED.location_state,
        seller_name = EXCLUDED.seller_name,
        seller_phone = EXCLUDED.seller_phone,
        seller_email = EXCLUDED.seller_email,
        external_url = COALESCE(EXCLUDED.external_url, vehicles.external_url),
        created_by = CASE WHEN $2 = 0 THEN NULL ELSE EXCLUDED.created_by END,
        is_active = TRUE,
        deleted_at = NULL,
        updated_at = CURRENT_TIMESTAMP
    |}
  in
  
  let vehicles_array = `List vehicles_json in
  let json_str = Yojson.Safe.to_string vehicles_array in
  
  Lwt.catch
    (fun () ->
      (* First, do the INSERT/UPDATE *)
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.exec bulk_insert_via_json (json_str, user_id)
      ) >>= fun () ->
      (* Return the count of vehicles processed (we can't easily count inserted vs updated) *)
      let imported_count = List.length vehicles_json in
      Logs.info (fun m -> m "Imported/updated %d vehicles" imported_count);
      (* Update original_id for newly created vehicles (only if user_id > 0) *)
      (if user_id > 0 then
        let update_original =
          Caqti_request.Infix.(
            Caqti_type.Std.(int ->. unit)
          ) "UPDATE vehicles SET original_id = id WHERE original_id IS NULL AND created_by = $1"
        in
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec update_original user_id
        )
      else
        Lwt.return_unit) >>= fun () ->
      Logs.info (fun m -> m "✅ Bulk created %d vehicles" imported_count);
      (* For bulk operations, invalidate all lists (too many combinations to track) *)
      Cache.invalidate_vehicle_lists () >>= fun () ->
      Cache.invalidate_stats () >>= fun () ->
      Lwt.return_ok imported_count)
    (fun exn ->
      Logs.err (fun m -> m "❌ Exception bulk creating vehicles: %s" (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "Database error: %s" (Printexc.to_string exn)))

(* CREATE - Insert new vehicle using direct SQL with JSON *)
let create vehicle_json user_id =
  (* We accept the vehicle as JSON and insert it *)
  let create_via_json =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 string int ->! t2 int string)
    ) {|
      WITH payload AS (SELECT $1::json AS v),
      new_vehicle AS (
        INSERT INTO vehicles (
          brand, model, year, price, mileage, fuel_type, color, transmission,
          description, image, images, seller_id, seller_name, seller_phone, seller_email,
          condition, source, location_city, location_state,
          slug, created_by, version, external_id, external_url,
          engine, doors, body_style, financing_available, trade_accepted, test_drive_available,
          exterior_condition, interior_condition, mechanical_condition, previous_owners,
          detailed_description_md
        )
        SELECT 
          COALESCE(p.v->>'brand', 'Unknown'),
          COALESCE(p.v->>'model', 'Unknown'),
          COALESCE((p.v->>'year')::int, 2020),
          COALESCE(p.v->>'price', '0'),
          COALESCE(p.v->>'mileage', '0'),
          COALESCE(p.v->>'fuel_type', 'Gasolina'),
          COALESCE(p.v->>'color', 'Preto'),
          COALESCE(p.v->>'transmission', 'Manual'),
          COALESCE(p.v->>'description', ''),
          COALESCE(p.v->>'image', ''),
          COALESCE(
            (SELECT ARRAY(SELECT json_array_elements_text(p.v->'images'))),
            ARRAY[]::text[]
          ),
          CASE WHEN $2 = 0 THEN NULL ELSE COALESCE((p.v->>'seller_id')::int, $2) END,
          COALESCE(NULLIF(p.v->>'seller_name', ''), 'Parceiro'),
          COALESCE(NULLIF(p.v->>'seller_phone', ''), 'Não informado'),
          COALESCE(NULLIF(p.v->>'seller_email', ''), 'nao-disponivel@buscar.com'),
          COALESCE(p.v->>'condition', 'used'),
          COALESCE(p.v->>'source', 'buscar'),
          COALESCE(p.v->>'location_city', 'São Paulo'),
          COALESCE(p.v->>'location_state', 'SP'),
          COALESCE(
            NULLIF(p.v->>'slug', ''),
            COALESCE(p.v->>'brand', 'x') || '-' || COALESCE(p.v->>'model', 'x') || '-' || COALESCE(p.v->>'external_id', '') || '-' || extract(epoch from now())::bigint::text || '-' || floor(random() * 1000000)::text
          ),
          CASE WHEN $2 = 0 THEN NULL ELSE $2 END,
          1,
          NULLIF(p.v->>'external_id', ''),
          NULLIF(p.v->>'external_url', ''),
          NULLIF(p.v->>'engine', ''),
          COALESCE((p.v->>'doors')::int, 4),
          NULLIF(p.v->>'body_style', ''),
          COALESCE((p.v->>'financing_available')::bool, false),
          COALESCE((p.v->>'trade_accepted')::bool, false),
          COALESCE((p.v->>'test_drive_available')::bool, false),
          NULLIF(p.v->>'exterior_condition', ''),
          NULLIF(p.v->>'interior_condition', ''),
          NULLIF(p.v->>'mechanical_condition', ''),
          COALESCE((p.v->>'previous_owners')::int, 1),
          COALESCE(p.v->>'description', '')
        FROM payload p
        ON CONFLICT (source, external_id)
        DO UPDATE SET
          brand = EXCLUDED.brand,
          model = EXCLUDED.model,
          year = EXCLUDED.year,
          price = EXCLUDED.price,
          mileage = CASE
                     WHEN EXCLUDED.mileage IS NOT NULL 
                          AND EXCLUDED.mileage != '' 
                          AND EXCLUDED.mileage != '0 km'
                          AND EXCLUDED.mileage != '0'
                     THEN EXCLUDED.mileage
                     ELSE vehicles.mileage
                   END,
          fuel_type = EXCLUDED.fuel_type,
          color = EXCLUDED.color,
          transmission = EXCLUDED.transmission,
          description = EXCLUDED.description,
          image = EXCLUDED.image,
          images = CASE
                     WHEN array_length(EXCLUDED.images, 1) IS NOT NULL
                          AND array_length(EXCLUDED.images, 1) > 0
                     THEN EXCLUDED.images
                     ELSE vehicles.images
                   END,
          condition = EXCLUDED.condition,
          location_city = EXCLUDED.location_city,
          location_state = EXCLUDED.location_state,
          seller_name = EXCLUDED.seller_name,
          seller_phone = EXCLUDED.seller_phone,
          seller_email = EXCLUDED.seller_email,
          external_url = COALESCE(EXCLUDED.external_url, vehicles.external_url),
          is_active = TRUE,
          deleted_at = NULL,
          updated_at = CURRENT_TIMESTAMP
        RETURNING id, slug
      )
      SELECT id, slug FROM new_vehicle
    |}
  in
  
  let json_str = Yojson.Safe.to_string vehicle_json in
  
  Lwt.catch
    (fun () ->
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
  
      Logs.info (fun m -> m "✅ Created vehicle ID: %d, slug: %s, is_active should be TRUE" new_id slug);
  invalidate_cache_for_vehicle vehicle_json >>= fun () ->
      Lwt.return_ok (new_id, slug))
    (fun exn ->
      Logs.err (fun m -> m "❌ Exception creating vehicle: %s. JSON: %s" (Printexc.to_string exn) json_str);
      Lwt.return_error (Printf.sprintf "Database error: %s" (Printexc.to_string exn)))

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
  ) >>= fun current_json_str ->
  
  (* Parse current vehicle and updates *)
  let current_json = Yojson.Safe.from_string current_json_str in
  let updates_json_obj = updates_json in
  
  (* Merge updates into current data *)
  let merged_json = match current_json, updates_json_obj with
    | `Assoc current_fields, `Assoc update_fields ->
        let merged_fields = List.map (fun (k, v) ->
          if List.mem_assoc k update_fields then
            (k, List.assoc k update_fields)
          else
            (k, v)
        ) current_fields in
        (* Add any new fields from updates *)
        let new_fields = List.filter (fun (k, _) -> not (List.mem_assoc k current_fields)) update_fields in
        `Assoc (merged_fields @ new_fields)
    | _ -> updates_json_obj
  in
  
  (* Deactivate old version *)
  let deactivate =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->. unit)
    ) "UPDATE vehicles SET is_active = FALSE WHERE id = $1"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec deactivate vehicle_id
  ) >>= fun () ->
  
  (* Create new version with merged data *)
  let create_new_version =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 string int ->! t2 int string)
    ) {|
      WITH payload AS (SELECT $1::json AS v),
      current_vehicle AS (
        SELECT * FROM vehicles WHERE id = $2
      ),
      new_vehicle AS (
        INSERT INTO vehicles (
          brand, model, year, price, mileage, fuel_type, color, transmission,
          description, image, images, seller_id, seller_name, seller_phone, seller_email,
          condition, source, location_city, location_state,
          slug, created_by, version, external_id, external_url,
          engine, doors, body_style, financing_available, trade_accepted, test_drive_available,
          exterior_condition, interior_condition, mechanical_condition, previous_owners,
          detailed_description_md, original_id
        )
        SELECT 
          COALESCE(p.v->>'brand', cv.brand),
          COALESCE(p.v->>'model', cv.model),
          COALESCE((p.v->>'year')::int, cv.year),
          COALESCE(p.v->>'price', cv.price),
          COALESCE(p.v->>'mileage', cv.mileage),
          COALESCE(p.v->>'fuel_type', cv.fuel_type),
          COALESCE(p.v->>'color', cv.color),
          COALESCE(p.v->>'transmission', cv.transmission),
          COALESCE(p.v->>'description', cv.description),
          COALESCE(p.v->>'image', cv.image),
          COALESCE(
            CASE WHEN p.v->'images' IS NOT NULL THEN
              (SELECT ARRAY(SELECT json_array_elements_text(p.v->'images')))
            ELSE cv.images END,
            ARRAY[]::text[]
          ),
          COALESCE((p.v->>'seller_id')::int, cv.seller_id),
          COALESCE(NULLIF(p.v->>'seller_name', ''), cv.seller_name),
          COALESCE(NULLIF(p.v->>'seller_phone', ''), cv.seller_phone),
          COALESCE(NULLIF(p.v->>'seller_email', ''), cv.seller_email),
          COALESCE(p.v->>'condition', cv.condition),
          COALESCE(p.v->>'source', cv.source),
          COALESCE(p.v->>'location_city', cv.location_city),
          COALESCE(p.v->>'location_state', cv.location_state),
          COALESCE(
            NULLIF(p.v->>'slug', ''),
            COALESCE(p.v->>'brand', cv.brand) || '-' || COALESCE(p.v->>'model', cv.model) || '-' || COALESCE(p.v->>'external_id', '') || '-' || extract(epoch from now())::bigint::text || '-' || floor(random() * 1000000)::text
          ),
          $2,
          cv.version + 1,
          cv.external_id,
          cv.external_url,
          COALESCE(NULLIF(p.v->>'engine', ''), cv.engine),
          COALESCE((p.v->>'doors')::int, cv.doors),
          COALESCE(NULLIF(p.v->>'body_style', ''), cv.body_style),
          COALESCE((p.v->>'financing_available')::bool, cv.financing_available),
          COALESCE((p.v->>'trade_accepted')::bool, cv.trade_accepted),
          COALESCE((p.v->>'test_drive_available')::bool, cv.test_drive_available),
          COALESCE(NULLIF(p.v->>'exterior_condition', ''), cv.exterior_condition),
          COALESCE(NULLIF(p.v->>'interior_condition', ''), cv.interior_condition),
          COALESCE(NULLIF(p.v->>'mechanical_condition', ''), cv.mechanical_condition),
          COALESCE((p.v->>'previous_owners')::int, cv.previous_owners),
          COALESCE(p.v->>'detailed_description_md', p.v->>'description', cv.detailed_description_md, cv.description),
          COALESCE(cv.original_id, cv.id)
        FROM payload p, current_vehicle cv
        RETURNING id, slug
      )
      SELECT id, slug FROM new_vehicle
    |}
  in
  
  let merged_json_str = Yojson.Safe.to_string merged_json in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find create_new_version (merged_json_str, vehicle_id)
  ) >>= fun (new_version_id, new_slug) ->
  
  (* Set original_id if it's the first version *)
  let update_original =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 int int ->. unit)
    ) "UPDATE vehicles SET original_id = $2 WHERE id = $1 AND original_id IS NULL"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec update_original (new_version_id, vehicle_id)
  ) >>= fun () ->
  
  Logs.info (fun m -> m "✅ Updated vehicle %d (old version deactivated, new version %d created)" vehicle_id new_version_id);
  invalidate_cache_for_vehicle merged_json >>= fun () ->
  Lwt.return_ok (new_version_id, new_slug)

(* UPDATE DIRECT - Update existing vehicle without creating new version *)
(* Only admin or owner can update *)
let update_direct vehicle_id updates_json user_id =
  (* First check if user is admin or owner *)
  let check_permission =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 int int ->! bool)
    ) {|
      SELECT EXISTS(
        SELECT 1 FROM vehicles v
        JOIN users u ON u.user_id = $2
        WHERE v.id = $1 
          AND v.is_active = TRUE
          AND (v.seller_id = $2 OR u.is_admin = TRUE)
      )
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find check_permission (vehicle_id, user_id)
  ) >>= fun has_permission ->
  
  if not has_permission then
    Lwt.return_error "Você não tem permissão para editar este anúncio. Apenas o dono ou um administrador pode editar."
  else
    let update_query =
      Caqti_request.Infix.(
      Caqti_type.Std.(t3 int string int ->. unit)
    ) {|
      WITH payload AS (SELECT $2::json AS v)
      UPDATE vehicles SET
        brand = COALESCE((payload.v->>'brand'), vehicles.brand),
        model = COALESCE((payload.v->>'model'), vehicles.model),
        year = COALESCE((payload.v->>'year')::int, vehicles.year),
        price = COALESCE((payload.v->>'price'), vehicles.price),
        mileage = COALESCE((payload.v->>'mileage'), vehicles.mileage),
        fuel_type = COALESCE((payload.v->>'fuel_type'), vehicles.fuel_type),
        color = COALESCE((payload.v->>'color'), vehicles.color),
        transmission = COALESCE((payload.v->>'transmission'), vehicles.transmission),
        description = COALESCE(NULLIF(payload.v->>'description', ''), vehicles.description),
        image = COALESCE(NULLIF(payload.v->>'image', ''), vehicles.image),
        images = COALESCE(
          CASE WHEN payload.v->'images' IS NOT NULL THEN
            (SELECT ARRAY(SELECT json_array_elements_text(payload.v->'images')))
          ELSE vehicles.images END,
          ARRAY[]::text[]
        ),
        seller_name = COALESCE(NULLIF(payload.v->>'seller_name', ''), vehicles.seller_name),
        seller_phone = COALESCE(NULLIF(payload.v->>'seller_phone', ''), vehicles.seller_phone),
        seller_email = COALESCE(NULLIF(payload.v->>'seller_email', ''), vehicles.seller_email),
        condition = COALESCE(NULLIF(payload.v->>'condition', ''), vehicles.condition),
        location_city = COALESCE(NULLIF(payload.v->>'location_city', ''), vehicles.location_city),
        location_state = COALESCE(NULLIF(payload.v->>'location_state', ''), vehicles.location_state),
        engine = COALESCE(NULLIF(payload.v->>'engine', ''), vehicles.engine),
        doors = COALESCE((payload.v->>'doors')::int, vehicles.doors),
        body_style = COALESCE(NULLIF(payload.v->>'body_style', ''), vehicles.body_style),
        detailed_description_md = CASE
          WHEN payload.v->>'detailed_description_md' IS NOT NULL AND payload.v->>'detailed_description_md' != '' THEN
            payload.v->>'detailed_description_md'
          WHEN payload.v->>'description' IS NOT NULL AND payload.v->>'description' != '' THEN
            payload.v->>'description'
          ELSE
            vehicles.detailed_description_md
        END,
        previous_owners = COALESCE((payload.v->>'previous_owners')::int, vehicles.previous_owners),
        exterior_condition = COALESCE(NULLIF(payload.v->>'exterior_condition', ''), vehicles.exterior_condition),
        interior_condition = COALESCE(NULLIF(payload.v->>'interior_condition', ''), vehicles.interior_condition),
        mechanical_condition = COALESCE(NULLIF(payload.v->>'mechanical_condition', ''), vehicles.mechanical_condition),
        financing_available = COALESCE((payload.v->>'financing_available')::bool, vehicles.financing_available),
        trade_accepted = COALESCE((payload.v->>'trade_accepted')::bool, vehicles.trade_accepted),
        test_drive_available = COALESCE((payload.v->>'test_drive_available')::bool, vehicles.test_drive_available),
        updated_by = $3,
        updated_at = CURRENT_TIMESTAMP
      FROM payload
      WHERE vehicles.id = $1
    |}
  in
  
  let json_str = Yojson.Safe.to_string updates_json in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec update_query (vehicle_id, json_str, user_id)
  ) >>= fun () ->
  
  (* Get the updated vehicle's slug *)
  let get_slug =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->! string)
    ) "SELECT slug FROM vehicles WHERE id = $1"
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find get_slug vehicle_id
  ) >>= fun slug ->
  
    (* Invalidate cache for this specific vehicle *)
    Cache.delete (Cache.vehicle_key slug) >>= fun () ->
    Logs.info (fun m -> m "✅ Directly updated vehicle ID: %d, slug: %s" vehicle_id slug);
  invalidate_cache_for_vehicle_id vehicle_id >>= fun () ->
  Lwt.return_ok (vehicle_id, slug)

(* SOFT DELETE - Only admin or owner can delete *)
let soft_delete vehicle_id user_id reason =
  (* First check if user is admin or owner *)
  let check_permission =
    Caqti_request.Infix.(
      Caqti_type.Std.(t2 int int ->! bool)
    ) {|
      SELECT EXISTS(
        SELECT 1 FROM vehicles v
        JOIN users u ON u.user_id = $2
        WHERE v.id = $1 
          AND v.is_active = TRUE
          AND (v.seller_id = $2 OR u.is_admin = TRUE)
      )
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find check_permission (vehicle_id, user_id)
  ) >>= fun has_permission ->
  
  if not has_permission then
    Lwt.return_error "Você não tem permissão para deletar este anúncio. Apenas o dono ou um administrador pode deletar."
  else
    let delete_query =
      Caqti_request.Infix.(
      Caqti_type.Std.(t3 int int string ->. unit)
    ) {|
      UPDATE vehicles SET
        is_active = FALSE,
        deleted_at = CURRENT_TIMESTAMP,
        updated_by = $2,
          inspection_notes = CONCAT(COALESCE(inspection_notes, ''), E'\n[DELETED]: ', $3::text)
      WHERE id = $1 AND is_active = TRUE
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec delete_query (vehicle_id, user_id, reason)
  ) >>= fun () ->
  
    (* Invalidate cache *)
    let get_slug =
      Caqti_request.Infix.(
        Caqti_type.Std.(int ->! string)
      ) "SELECT slug FROM vehicles WHERE id = $1"
    in
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find get_slug vehicle_id
    ) >>= fun slug ->
    Cache.delete (Cache.vehicle_key slug) >>= fun () ->
    
    Logs.info (fun m -> m "🗑️  Soft deleted vehicle %d by user %d" vehicle_id user_id);
  invalidate_cache_for_vehicle_id vehicle_id >>= fun () ->
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
  invalidate_cache_for_vehicle_id vehicle_id >>= fun () ->
  Lwt.return_ok ()

(* DEACTIVATE STALE EXTERNAL VEHICLES *)
(* Desativa veículos de terceiros (source != 'buscar') que não foram atualizados há mais de X dias *)
let deactivate_stale_external_vehicles ~days =
  let days_int = max 1 days in (* Garantir pelo menos 1 dia *)
  let deactivate_query =
    Caqti_request.Infix.(
      Caqti_type.Std.(int ->! int)
    ) {|
      WITH deactivated AS (
        UPDATE vehicles SET
          is_active = FALSE,
          deleted_at = CURRENT_TIMESTAMP,
          inspection_notes = CONCAT(
            COALESCE(inspection_notes, ''),
            E'\n[DEACTIVATED]: Desativado automaticamente por não ter sido atualizado há mais de ' || $1::text || ' dia(s) (', 
            to_char(updated_at, 'DD/MM/YYYY HH24:MI:SS'), 
            ')'
          )
        WHERE source != 'buscar'
          AND is_active = TRUE
          AND updated_at < NOW() - (($1::text || ' days')::interval)
        RETURNING id, slug
      )
      SELECT COUNT(*) FROM deactivated
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find deactivate_query days_int
  ) >>= fun count ->
  
  (* Invalidate cache for all deactivated vehicles *)
  let get_deactivated_slugs =
    Caqti_request.Infix.(
      Caqti_type.Std.(unit ->* string)
    ) {|
      SELECT slug FROM vehicles 
      WHERE source != 'buscar'
        AND is_active = FALSE
        AND deleted_at >= NOW() - INTERVAL '1 minute'
    |}
  in
  
  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.collect_list get_deactivated_slugs ()
  ) >>= fun slugs ->
  
  Lwt_list.iter_s (fun slug ->
    Cache.delete (Cache.vehicle_key slug) >>= fun () ->
    Lwt.return_unit
  ) slugs >>= fun () ->
  
  (* Invalidate vehicle lists cache *)
  Cache.invalidate_vehicle_lists () >>= fun () ->
  
  Logs.info (fun m -> m "🧹 Deactivated %d stale external vehicles (not updated in %d+ days)" count days_int);
  Lwt.return_ok count

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
