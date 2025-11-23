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
  
  let find_user_by_email_opt =
    (string ->? t3 int string string)
    "SELECT user_id, name, email FROM users WHERE email = $1 AND is_active = TRUE"
  
  let find_user_by_id =
    (int ->! t3 int string string)
    "SELECT user_id, name, email FROM users WHERE user_id = $1 AND is_active = TRUE"
  
  (* Get seller info (name, phone, email) by user_id for vehicles *)
  let get_seller_info_by_id =
    (int ->? t3 string string string)
    "SELECT name, COALESCE(phone, ''), email FROM users WHERE user_id = $1 AND is_active = TRUE"
  
  let get_user_password_hash =
    (string ->! string)
    "SELECT password_hash FROM users WHERE email = $1 AND is_active = TRUE"
  
  let get_full_user_by_id =
    (int ->* string)
    {|SELECT row_to_json(u)::text FROM (
      SELECT user_id, name, email, ''::text as password_hash, phone, document_number, 
             address_street, address_number, address_complement,
             address_neighborhood, address_city, address_state, address_zipcode,
             is_admin, referred_by_code_id,
             created_at::text, updated_at::text, is_active, is_verified, subscription_tier
      FROM users WHERE user_id = $1
    ) u|}
  
  let create_user =
    (t12 string string string string string string string string string string string string ->. unit)
    {|INSERT INTO users (name, email, password_hash, phone, document_number,
                        address_street, address_number, address_complement,
                        address_neighborhood, address_city, address_state, address_zipcode)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)|}
  
  let update_user =
    (t11 int string string string string string string string string string string ->. unit)
    {|UPDATE users SET name = $2, phone = $3, document_number = $4,
                      address_street = $5, address_number = $6, address_complement = $7,
                      address_neighborhood = $8, address_city = $9, address_state = $10,
                      address_zipcode = $11, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1|}
  
  let update_user_password =
    (t2 int string ->. unit)
    "UPDATE users SET password_hash = $2, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1"
  
  let update_user_with_email =
    (t12 int string string string string string string string string string string string ->. unit)
    {|UPDATE users SET name = $2, email = $3, phone = $4, document_number = $5,
                      address_street = $6, address_number = $7, address_complement = $8,
                      address_neighborhood = $9, address_city = $10, address_state = $11,
                      address_zipcode = $12, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1|}
  
  let check_email_exists =
    (string ->! bool)
    "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)"
  
  let list_all_users =
    (unit ->* string)
    {|SELECT row_to_json(u)::text FROM (
      SELECT user_id, name, email, ''::text as password_hash, phone, document_number,
             address_street, address_number, address_complement,
             address_neighborhood, address_city, address_state, address_zipcode,
             is_admin, referred_by_code_id,
             created_at::text, updated_at::text, is_active, is_verified, subscription_tier
      FROM users ORDER BY created_at DESC
    ) u|}
  
  let count_users_filtered =
    (t2 string string ->! int)
    {|SELECT COUNT(*)::int FROM users
      WHERE ($1 = '' OR name ILIKE '%' || $1 || '%' OR email ILIKE '%' || $1 || '%')
        AND ($2 = 'all' OR ($2 = 'admin' AND is_admin = TRUE) OR ($2 = 'user' AND is_admin = FALSE))|}
  
  let list_users_filtered =
    (t5 int int string string string ->* string)
    {|SELECT row_to_json(u)::text FROM (
      SELECT user_id, name, email, ''::text as password_hash, phone, document_number,
             address_street, address_number, address_complement,
             address_neighborhood, address_city, address_state, address_zipcode,
             is_admin, referred_by_code_id,
             created_at::text, updated_at::text, is_active, is_verified, subscription_tier
      FROM users
      WHERE ($3 = '' OR name ILIKE '%' || $3 || '%' OR email ILIKE '%' || $3 || '%')
        AND ($4 = 'all' OR ($4 = 'admin' AND is_admin = TRUE) OR ($4 = 'user' AND is_admin = FALSE))
      ORDER BY 
        CASE WHEN $5 = 'name_asc' THEN name END ASC,
        CASE WHEN $5 = 'name_desc' THEN name END DESC,
        CASE WHEN $5 = 'email_asc' THEN email END ASC,
        CASE WHEN $5 = 'email_desc' THEN email END DESC,
        CASE WHEN $5 = 'created_desc' OR $5 = '' THEN created_at END DESC,
        CASE WHEN $5 = 'created_asc' THEN created_at END ASC
      LIMIT $1 OFFSET $2
    ) u|}
  
  (* Referral code queries *)
  let find_referral_code_by_code =
    (string ->? t4 int int string bool)
    "SELECT referral_code_id, created_by_user_id, code, is_active FROM referral_codes WHERE code = $1"
  
  let check_referral_code_used =
    (int ->! bool)
    "SELECT EXISTS(SELECT 1 FROM user_referrals WHERE referral_code_id = $1)"
  
  let create_referral_code =
    (t3 string int bool ->. unit)
    "INSERT INTO referral_codes (code, created_by_user_id, is_active) VALUES ($1, $2, $3)"
  
  let use_referral_code =
    (t2 int int ->. unit)
    "INSERT INTO user_referrals (referral_code_id, used_by_user_id) VALUES ($1, $2)"
  
  let update_user_referred_by =
    (t2 int int ->. unit)
    "UPDATE users SET referred_by_code_id = $2 WHERE user_id = $1"
  
  let list_referral_codes_by_user =
    (int ->* string)
    {|SELECT row_to_json(rc)::text FROM (
      SELECT rc.referral_code_id, rc.code, rc.created_by_user_id, 
             rc.created_at::text, rc.is_active,
             ur.used_by_user_id, u.name as used_by_user_name, ur.used_at::text
      FROM referral_codes rc
      LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
      LEFT JOIN users u ON ur.used_by_user_id = u.user_id
      WHERE rc.created_by_user_id = $1
      ORDER BY rc.created_at DESC
    ) rc|}
  
  let list_all_referral_codes =
    (unit ->* string)
    {|SELECT row_to_json(rc)::text FROM (
      SELECT rc.referral_code_id, rc.code, rc.created_by_user_id, 
             rc.created_at::text, rc.is_active,
             ur.used_by_user_id, u2.name as used_by_user_name, ur.used_at::text
      FROM referral_codes rc
      LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
      LEFT JOIN users u2 ON ur.used_by_user_id = u2.user_id
      ORDER BY rc.created_at DESC
    ) rc|}
  
  (* List referral codes with pagination, filters and search *)
  let list_referral_codes_by_user_filtered =
    (t5 int int int string string ->* string)
    {|SELECT row_to_json(rc_filtered)::text FROM (
      SELECT rc.referral_code_id, rc.code, rc.created_by_user_id, 
             rc.created_at::text, rc.is_active,
             ur.used_by_user_id, u.name as used_by_user_name, ur.used_at::text
      FROM referral_codes rc
      LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
      LEFT JOIN users u ON ur.used_by_user_id = u.user_id
      WHERE rc.created_by_user_id = $1
        AND ($4 = '' OR rc.code ILIKE '%' || $4 || '%')
        AND (
          $5 = 'all' OR
          ($5 = 'available' AND rc.is_active = TRUE AND ur.used_by_user_id IS NULL) OR
          ($5 = 'used' AND rc.is_active = TRUE AND ur.used_by_user_id IS NOT NULL) OR
          ($5 = 'deactivated' AND rc.is_active = FALSE)
        )
      ORDER BY
        CASE
          WHEN rc.is_active = FALSE THEN 3
          WHEN ur.used_by_user_id IS NOT NULL THEN 2
          ELSE 1
        END ASC, rc.created_at DESC
      LIMIT $2 OFFSET $3
    ) rc_filtered|}
  
  let count_referral_codes_by_user_filtered =
    (t3 int string string ->! int)
    {|SELECT COUNT(*)::int
      FROM referral_codes rc
      LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
      WHERE rc.created_by_user_id = $1
        AND ($2 = '' OR rc.code ILIKE '%' || $2 || '%')
        AND (
          $3 = 'all' OR
          ($3 = 'available' AND rc.is_active = TRUE AND ur.used_by_user_id IS NULL) OR
          ($3 = 'used' AND rc.is_active = TRUE AND ur.used_by_user_id IS NOT NULL) OR
          ($3 = 'deactivated' AND rc.is_active = FALSE)
        )|}
  
  let list_all_referral_codes_filtered =
    (t4 int int string string ->* string)
    {|SELECT row_to_json(rc)::text FROM (
      SELECT rc.referral_code_id, rc.code, rc.created_by_user_id, 
             rc.created_at::text, rc.is_active,
             rc.used_by_user_id, rc.used_by_user_name, rc.used_at::text
      FROM (
        SELECT rc.referral_code_id, rc.code, rc.created_by_user_id, 
               rc.created_at, rc.is_active,
               ur.used_by_user_id, u2.name as used_by_user_name, ur.used_at,
               CASE 
                 WHEN rc.is_active = FALSE THEN 3
                 WHEN ur.used_by_user_id IS NOT NULL THEN 2
                 ELSE 1
               END as sort_order
        FROM referral_codes rc
        LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
        LEFT JOIN users u2 ON ur.used_by_user_id = u2.user_id
        WHERE ($3 = '' OR rc.code ILIKE '%' || $3 || '%')
          AND (
            $4 = 'all' OR
            ($4 = 'available' AND rc.is_active = TRUE AND ur.used_by_user_id IS NULL) OR
            ($4 = 'used' AND rc.is_active = TRUE AND ur.used_by_user_id IS NOT NULL) OR
            ($4 = 'deactivated' AND rc.is_active = FALSE)
          )
        ORDER BY sort_order ASC, rc.created_at DESC
        LIMIT $1 OFFSET $2
      ) rc
    ) rc|}
  
  let count_all_referral_codes_filtered =
    (t2 string string ->! int)
    {|SELECT COUNT(*)::int
      FROM referral_codes rc
      LEFT JOIN user_referrals ur ON rc.referral_code_id = ur.referral_code_id
      WHERE ($1 = '' OR rc.code ILIKE '%' || $1 || '%')
        AND (
          $2 = 'all' OR
          ($2 = 'available' AND rc.is_active = TRUE AND ur.used_by_user_id IS NULL) OR
          ($2 = 'used' AND rc.is_active = TRUE AND ur.used_by_user_id IS NOT NULL) OR
          ($2 = 'deactivated' AND rc.is_active = FALSE)
        )|}
  
  let deactivate_referral_code =
    (int ->. unit)
    "UPDATE referral_codes SET is_active = FALSE WHERE referral_code_id = $1"
  
  let deactivate_all_referral_codes =
    (unit ->. unit)
    "UPDATE referral_codes SET is_active = FALSE WHERE is_active = TRUE"
  
  (* Count queries *)
  let count_vehicles =
    (unit ->! int)
    "SELECT COUNT(*)::int FROM vehicles WHERE is_active = TRUE"
  
  let count_vehicles_by_source =
    (string ->! int)
    "SELECT COUNT(*)::int FROM vehicles WHERE is_active = TRUE AND source = $1"
  
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

  let list_active_brands =
    (unit ->* string)
    {| SELECT DISTINCT 
         CASE 
           WHEN LOWER(brand) LIKE '%gm%' AND LOWER(brand) LIKE '%chevrolet%' THEN 'Chevrolet'
           WHEN LOWER(brand) = 'gm' THEN 'Chevrolet'
           WHEN LOWER(brand) LIKE 'gm - %' OR LOWER(brand) LIKE 'gm-%' THEN 'Chevrolet'
           WHEN LOWER(brand) LIKE '%vw%' AND LOWER(brand) LIKE '%volkswagen%' THEN 'Volkswagen'
           WHEN LOWER(brand) = 'vw' THEN 'Volkswagen'
           WHEN LOWER(brand) LIKE 'vw - %' OR LOWER(brand) LIKE 'vw-%' THEN 'Volkswagen'
           WHEN LOWER(brand) = 'volkswagen' THEN 'Volkswagen'
           ELSE brand
         END AS brand
       FROM vehicles 
       WHERE is_active = TRUE AND brand IS NOT NULL AND brand <> ''
       ORDER BY brand |}

  let list_active_models_by_brand =
    (string ->* string)
    {| SELECT DISTINCT model FROM vehicles 
       WHERE is_active = TRUE
         AND brand IS NOT NULL AND brand <> ''
         AND model IS NOT NULL AND model <> ''
         AND LOWER(brand) = LOWER($1)
       ORDER BY model |}

  let list_active_cities_by_state =
    (string ->* string)
    {| SELECT DISTINCT location_city FROM vehicles 
       WHERE is_active = TRUE
         AND location_city IS NOT NULL AND location_city <> ''
         AND location_state IS NOT NULL AND location_state <> ''
         AND UPPER(location_state) = UPPER($1)
       ORDER BY location_city |}

  let count_vehicles_filtered =
    (string ->! int)
    {|
      WITH params AS (SELECT $1::json AS params_json)
      SELECT COUNT(*)::int
      FROM vehicles v, params p
      WHERE v.is_active = TRUE
        AND (COALESCE(p.params_json->>'brand', '') = '' OR LOWER(v.brand) = LOWER(p.params_json->>'brand'))
        AND (
              COALESCE(p.params_json->>'model', '') = ''
              OR LOWER(v.model) = LOWER(p.params_json->>'model')
              OR LOWER(v.model) LIKE LOWER(p.params_json->>'model') || '%'
            )
        AND (
              COALESCE(p.params_json->>'fuel_type', '') = ''
              OR CASE
                   -- Normalize fuel types for matching (case-insensitive)
                   WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'flex' THEN
                     -- Flex: matches Flex, GASOLINA/ETANOL, and any combination with gasolina and etanol (but not pure etanol)
                     (LOWER(TRIM(v.fuel_type)) = 'flex' 
                      OR LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%etanol%' 
                      OR LOWER(TRIM(v.fuel_type)) LIKE '%etanol%gasolina%'
                      OR LOWER(TRIM(v.fuel_type)) LIKE '%gasolina/etanol%'
                      OR LOWER(TRIM(v.fuel_type)) LIKE '%etanol/gasolina%')
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elét%' 
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elet%'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%híbrido%'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%hibrido%'
                     AND LOWER(TRIM(v.fuel_type)) != 'etanol'
                   WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'híbrido' OR LOWER(TRIM(p.params_json->>'fuel_type')) = 'hibrido' THEN
                     -- Híbrido: matches any combination with elétrico/eletrico and gasolina/etanol
                     (LOWER(TRIM(v.fuel_type)) LIKE '%híbrido%' 
                      OR LOWER(TRIM(v.fuel_type)) LIKE '%hibrido%' 
                      OR (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' AND LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%')
                      OR (LOWER(TRIM(v.fuel_type)) LIKE '%elet%' AND LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%'))
                  WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'elétrico' OR LOWER(TRIM(p.params_json->>'fuel_type')) = 'eletrico' THEN
                    -- Elétrico: includes pure electric and hybrid/electric vehicles (like "Híbrido / Elétrico")
                    ((LOWER(TRIM(v.fuel_type)) LIKE '%elétrico%' OR LOWER(TRIM(v.fuel_type)) LIKE '%eletrico%')
                     OR (LOWER(TRIM(v.fuel_type)) LIKE '%híbrido%' AND (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' OR LOWER(TRIM(v.fuel_type)) LIKE '%elet%'))
                     OR (LOWER(TRIM(v.fuel_type)) LIKE '%hibrido%' AND (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' OR LOWER(TRIM(v.fuel_type)) LIKE '%elet%')))
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%gasolina%' 
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%etanol%'
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%diesel%'
                   WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'gasolina' THEN
                     -- Gasolina: only pure gasoline, not flex or hybrid
                     LOWER(TRIM(v.fuel_type)) = 'gasolina' 
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%etanol%' 
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%flex%'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elét%'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elet%'
                   WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'etanol' THEN
                     -- Etanol: pure ethanol only
                     LOWER(TRIM(v.fuel_type)) = 'etanol'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%gasolina%'
                     AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%flex%'
                   WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'diesel' THEN
                     LOWER(TRIM(v.fuel_type)) LIKE '%diesel%'
                   ELSE
                     LOWER(TRIM(v.fuel_type)) = LOWER(TRIM(p.params_json->>'fuel_type'))
                 END
            )
        AND (COALESCE(p.params_json->>'condition', '') = '' OR LOWER(v.condition) = LOWER(p.params_json->>'condition'))
        AND (COALESCE(p.params_json->>'source', '') = '' OR LOWER(v.source) = LOWER(p.params_json->>'source'))
        AND (COALESCE(p.params_json->>'location_state', '') = '' OR LOWER(v.location_state) = LOWER(p.params_json->>'location_state'))
        AND (COALESCE(p.params_json->>'location_city', '') = '' OR LOWER(v.location_city) = LOWER(p.params_json->>'location_city'))
        AND (COALESCE(p.params_json->>'seller_id', '') = '' OR v.seller_id = (p.params_json->>'seller_id')::int)
        AND (
              COALESCE(p.params_json->>'year_min', '') = ''
              OR v.year >= (p.params_json->>'year_min')::int
            )
        AND (
              COALESCE(p.params_json->>'year_max', '') = ''
              OR v.year <= (p.params_json->>'year_max')::int
            )
              AND (
                    COALESCE(p.params_json->>'price_min', '') = ''
                    OR CASE
                         WHEN position(',' in v.price) > 0 THEN
                           -- Price has decimal separator (comma), divide by 100 to convert cents to reais
                           (COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint / 100)
                         ELSE
                           -- No decimal separator, use as is
                           COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint
                       END >= (p.params_json->>'price_min')::bigint
                  )
              AND (
                    COALESCE(p.params_json->>'price_max', '') = ''
                    OR CASE
                         WHEN position(',' in v.price) > 0 THEN
                           -- Price has decimal separator (comma), divide by 100 to convert cents to reais
                           (COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint / 100)
                         ELSE
                           -- No decimal separator, use as is
                           COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint
                       END <= (p.params_json->>'price_max')::bigint
                  )
    |}

  let list_vehicles_filtered =
    (t3 string int int ->* string)
    {|
      WITH params AS (SELECT $1::json AS params_json),
      filtered AS (
        SELECT v.*
        FROM vehicles v, params p
        WHERE v.is_active = TRUE
          AND (COALESCE(p.params_json->>'brand', '') = '' OR LOWER(v.brand) = LOWER(p.params_json->>'brand'))
          AND (
                COALESCE(p.params_json->>'model', '') = ''
                OR LOWER(v.model) = LOWER(p.params_json->>'model')
                OR LOWER(v.model) LIKE LOWER(p.params_json->>'model') || '%'
              )
          AND (
                COALESCE(p.params_json->>'fuel_type', '') = ''
                OR CASE
                     -- Normalize fuel types for matching (case-insensitive)
                     WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'flex' THEN
                       -- Flex: matches Flex, GASOLINA/ETANOL, and any combination with gasolina and etanol
                       (LOWER(TRIM(v.fuel_type)) = 'flex' 
                        OR LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%etanol%' 
                        OR LOWER(TRIM(v.fuel_type)) LIKE '%etanol%gasolina%'
                        OR LOWER(TRIM(v.fuel_type)) LIKE '%gasolina/etanol%'
                        OR LOWER(TRIM(v.fuel_type)) LIKE '%etanol/gasolina%')
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elét%' 
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elet%'
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%híbrido%'
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%hibrido%'
                     WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'híbrido' OR LOWER(TRIM(p.params_json->>'fuel_type')) = 'hibrido' THEN
                       -- Híbrido: matches any combination with elétrico/eletrico and gasolina/etanol
                       (LOWER(TRIM(v.fuel_type)) LIKE '%híbrido%' 
                        OR LOWER(TRIM(v.fuel_type)) LIKE '%hibrido%' 
                        OR (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' AND LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%')
                        OR (LOWER(TRIM(v.fuel_type)) LIKE '%elet%' AND LOWER(TRIM(v.fuel_type)) LIKE '%gasolina%'))
                  WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'elétrico' OR LOWER(TRIM(p.params_json->>'fuel_type')) = 'eletrico' THEN
                    -- Elétrico: includes pure electric and hybrid/electric vehicles (like "Híbrido / Elétrico")
                    ((LOWER(TRIM(v.fuel_type)) LIKE '%elétrico%' OR LOWER(TRIM(v.fuel_type)) LIKE '%eletrico%')
                     OR (LOWER(TRIM(v.fuel_type)) LIKE '%híbrido%' AND (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' OR LOWER(TRIM(v.fuel_type)) LIKE '%elet%'))
                     OR (LOWER(TRIM(v.fuel_type)) LIKE '%hibrido%' AND (LOWER(TRIM(v.fuel_type)) LIKE '%elét%' OR LOWER(TRIM(v.fuel_type)) LIKE '%elet%')))
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%gasolina%' 
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%etanol%'
                    AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%diesel%'
                     WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'gasolina' THEN
                       -- Gasolina: only pure gasoline, not flex or hybrid
                       LOWER(TRIM(v.fuel_type)) = 'gasolina' 
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%etanol%' 
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%flex%'
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elét%'
                       AND LOWER(TRIM(v.fuel_type)) NOT LIKE '%elet%'
                     WHEN LOWER(TRIM(p.params_json->>'fuel_type')) = 'diesel' THEN
                       LOWER(TRIM(v.fuel_type)) LIKE '%diesel%'
                     ELSE
                       LOWER(TRIM(v.fuel_type)) = LOWER(TRIM(p.params_json->>'fuel_type'))
                   END
              )
          AND (COALESCE(p.params_json->>'condition', '') = '' OR LOWER(v.condition) = LOWER(p.params_json->>'condition'))
          AND (COALESCE(p.params_json->>'source', '') = '' OR LOWER(v.source) = LOWER(p.params_json->>'source'))
          AND (COALESCE(p.params_json->>'location_state', '') = '' OR LOWER(v.location_state) = LOWER(p.params_json->>'location_state'))
          AND (COALESCE(p.params_json->>'location_city', '') = '' OR LOWER(v.location_city) = LOWER(p.params_json->>'location_city'))
          AND (COALESCE(p.params_json->>'seller_id', '') = '' OR v.seller_id IS NOT DISTINCT FROM (p.params_json->>'seller_id')::int)
          AND (
                COALESCE(p.params_json->>'year_min', '') = ''
                OR v.year >= (p.params_json->>'year_min')::int
              )
          AND (
                COALESCE(p.params_json->>'year_max', '') = ''
                OR v.year <= (p.params_json->>'year_max')::int
              )
          AND (
                COALESCE(p.params_json->>'price_min', '') = ''
                OR CASE
                     WHEN position(',' in v.price) > 0 THEN
                       -- Price has decimal separator (comma), divide by 100 to convert cents to reais
                       (COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint / 100)
                     ELSE
                       -- No decimal separator, use as is
                       COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint
                   END >= (p.params_json->>'price_min')::bigint
              )
          AND (
                COALESCE(p.params_json->>'price_max', '') = ''
                OR CASE
                     WHEN position(',' in v.price) > 0 THEN
                       -- Price has decimal separator (comma), divide by 100 to convert cents to reais
                       (COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint / 100)
                     ELSE
                       -- No decimal separator, use as is
                       COALESCE(NULLIF(regexp_replace(v.price, '[^0-9]', '', 'g'), ''), '0')::bigint
                   END <= (p.params_json->>'price_max')::bigint
              )
      )
      SELECT row_to_json(v)::text
      FROM (
        SELECT f.*
        FROM filtered f, params p
        ORDER BY
          CASE 
            WHEN COALESCE(p.params_json->>'sort', '') = '' 
                 AND COALESCE(p.params_json->>'brand', '') = ''
                 AND COALESCE(p.params_json->>'model', '') = ''
                 AND COALESCE(p.params_json->>'fuel_type', '') = ''
                 AND COALESCE(p.params_json->>'condition', '') = ''
                 AND COALESCE(p.params_json->>'source', '') = ''
                 AND COALESCE(p.params_json->>'location_state', '') = ''
                 AND COALESCE(p.params_json->>'location_city', '') = ''
                 AND COALESCE(p.params_json->>'year_min', '') = ''
                 AND COALESCE(p.params_json->>'year_max', '') = ''
                 AND COALESCE(p.params_json->>'price_min', '') = ''
                 AND COALESCE(p.params_json->>'price_max', '') = ''
            THEN CASE WHEN f.source = 'buscar' THEN 0 ELSE 1 END
            ELSE 0
          END,
          CASE 
            WHEN COALESCE(p.params_json->>'sort', '') = '' 
                 AND COALESCE(p.params_json->>'brand', '') = ''
                 AND COALESCE(p.params_json->>'model', '') = ''
                 AND COALESCE(p.params_json->>'fuel_type', '') = ''
                 AND COALESCE(p.params_json->>'condition', '') = ''
                 AND COALESCE(p.params_json->>'source', '') = ''
                 AND COALESCE(p.params_json->>'location_state', '') = ''
                 AND COALESCE(p.params_json->>'location_city', '') = ''
                 AND COALESCE(p.params_json->>'year_min', '') = ''
                 AND COALESCE(p.params_json->>'year_max', '') = ''
                 AND COALESCE(p.params_json->>'price_min', '') = ''
                 AND COALESCE(p.params_json->>'price_max', '') = ''
            THEN random()
            ELSE 0
          END,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'price_asc'
            THEN COALESCE(NULLIF(regexp_replace(f.price, '[^0-9]', '', 'g'), ''), '0')::bigint END ASC,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'price_desc'
            THEN COALESCE(NULLIF(regexp_replace(f.price, '[^0-9]', '', 'g'), ''), '0')::bigint END DESC,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'year_asc' THEN f.year END ASC,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'year_desc' THEN f.year END DESC,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'mileage_asc'
            THEN COALESCE(
              NULLIF(regexp_replace(f.mileage, '[^0-9]', '', 'g'), '')::bigint,
              999999999::bigint
            ) END ASC NULLS LAST,
          CASE WHEN COALESCE(p.params_json->>'sort', '') = 'mileage_desc'
            THEN COALESCE(
              NULLIF(regexp_replace(f.mileage, '[^0-9]', '', 'g'), '')::bigint,
              0::bigint
            ) END DESC NULLS FIRST,
          f.created_at DESC
        LIMIT $2
        OFFSET $3
      ) v
    |}

  (* Scraper job queries *)
  let list_scraper_jobs =
    (unit ->* string)
    {|SELECT row_to_json(sj)::text FROM (
      SELECT scraper_job_id, brand, model, source, is_active,
             last_run_at::text, next_run_at::text,
             run_count, success_count, error_count, last_error,
             created_at::text, updated_at::text, created_by_user_id
      FROM scraper_jobs
      ORDER BY created_at DESC
    ) sj|}

  let get_scraper_job_by_id =
    (int ->? string)
    {|SELECT row_to_json(sj)::text FROM (
      SELECT scraper_job_id, brand, model, source, is_active,
             last_run_at::text, next_run_at::text,
             run_count, success_count, error_count, last_error,
             created_at::text, updated_at::text, created_by_user_id
      FROM scraper_jobs
      WHERE scraper_job_id = $1
    ) sj|}

  let create_scraper_job =
    (t4 string string string (option int) ->! string)
    {|WITH inserted AS (
        INSERT INTO scraper_jobs (brand, model, source, created_by_user_id)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (brand, model, source) DO UPDATE
        SET updated_at = CURRENT_TIMESTAMP
        RETURNING scraper_job_id, brand, model, source, is_active,
                   last_run_at, next_run_at,
                   run_count, success_count, error_count, last_error,
                   created_at, updated_at, created_by_user_id
      )
      SELECT row_to_json(sj)::text FROM (
        SELECT scraper_job_id, brand, model, source, is_active,
               last_run_at::text, next_run_at::text,
               run_count, success_count, error_count, last_error,
               created_at::text, updated_at::text, created_by_user_id
        FROM inserted
      ) sj|}

  let update_scraper_job =
    (t5 int string string string bool ->! string)
    {|WITH updated AS (
        UPDATE scraper_jobs
        SET brand = $2, model = $3, source = $4, is_active = $5,
            updated_at = CURRENT_TIMESTAMP
        WHERE scraper_job_id = $1
        RETURNING scraper_job_id, brand, model, source, is_active,
                   last_run_at, next_run_at,
                   run_count, success_count, error_count, last_error,
                   created_at, updated_at, created_by_user_id
      )
      SELECT row_to_json(sj)::text FROM (
        SELECT scraper_job_id, brand, model, source, is_active,
               last_run_at::text, next_run_at::text,
               run_count, success_count, error_count, last_error,
               created_at::text, updated_at::text, created_by_user_id
        FROM updated
      ) sj|}

  let delete_scraper_job =
    (int ->. unit)
    "DELETE FROM scraper_jobs WHERE scraper_job_id = $1"

  (* Count scraper jobs with filters *)
  let count_scraper_jobs_filtered =
    (string ->! int)
    {|
      WITH params AS (SELECT $1::json AS params_json)
      SELECT COUNT(*)::int
      FROM scraper_jobs sj, params p
      WHERE (COALESCE(p.params_json->>'search', '') = '' 
             OR LOWER(sj.brand) LIKE '%' || LOWER(p.params_json->>'search') || '%'
             OR LOWER(sj.model) LIKE '%' || LOWER(p.params_json->>'search') || '%')
        AND (COALESCE(p.params_json->>'source', '') = '' 
             OR LOWER(sj.source) = LOWER(p.params_json->>'source'))
    |}

  (* List scraper jobs with filters and pagination *)
  let list_scraper_jobs_filtered =
    (t3 string int int ->* string)
    {|
      WITH params AS (SELECT $1::json AS params_json),
      filtered AS (
        SELECT sj.*
        FROM scraper_jobs sj, params p
        WHERE (COALESCE(p.params_json->>'search', '') = '' 
               OR LOWER(sj.brand) LIKE '%' || LOWER(p.params_json->>'search') || '%'
               OR LOWER(sj.model) LIKE '%' || LOWER(p.params_json->>'search') || '%')
          AND (COALESCE(p.params_json->>'source', '') = '' 
               OR LOWER(sj.source) = LOWER(p.params_json->>'source'))
      )
      SELECT row_to_json(sj)::text
      FROM (
        SELECT f.scraper_job_id, f.brand, f.model, f.source, f.is_active,
               f.last_run_at::text, f.next_run_at::text,
               f.run_count, f.success_count, f.error_count, f.last_error,
               f.created_at::text, f.updated_at::text, f.created_by_user_id
        FROM filtered f
        ORDER BY f.created_at DESC
        LIMIT $2
        OFFSET $3
      ) sj
    |}

  let list_active_scraper_jobs =
    (unit ->* string)
    {|SELECT row_to_json(sj)::text FROM (
      SELECT scraper_job_id, brand, model, source, is_active,
             last_run_at::text, next_run_at::text,
             run_count, success_count, error_count, last_error,
             created_at::text, updated_at::text, created_by_user_id
      FROM scraper_jobs
      WHERE is_active = TRUE
      ORDER BY COALESCE(next_run_at, created_at) ASC
    ) sj|}

  let update_scraper_job_run_stats =
    (t2 int bool ->. unit)
    {|UPDATE scraper_jobs
      SET last_run_at = CURRENT_TIMESTAMP,
          next_run_at = CURRENT_TIMESTAMP + INTERVAL '1 day' + (RANDOM() * INTERVAL '12 hours'),
          run_count = run_count + 1,
          success_count = success_count + CASE WHEN $2 THEN 1 ELSE 0 END,
          error_count = error_count + CASE WHEN $2 THEN 0 ELSE 1 END,
          updated_at = CURRENT_TIMESTAMP
      WHERE scraper_job_id = $1|}
end
