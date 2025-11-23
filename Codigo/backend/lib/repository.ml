(* Repository layer - Pure database access via JSON *)

open Lwt.Infix
open Types
open Str

module StringSet = Set.Make (String)

(* Utility functions for UTF-8 correction *)
module Utf8Fix = struct
  (* Decode Unicode escape sequences like \u00ed to actual UTF-8 characters *)
  let decode_unicode_escapes str =
    (* Only decode if string contains Unicode escape sequences *)
    if not (String.contains str '\\' && String.contains str 'u') then str
    else
      let len = String.length str in
      let buf = Buffer.create len in
      let rec process i =
        if i >= len then Buffer.contents buf
        else if i < len - 5 && str.[i] = '\\' && str.[i+1] = 'u' then
        (* Found \u, try to parse hex code *)
        try
          let hex_code = String.sub str (i+2) 4 in
          let code_point = int_of_string ("0x" ^ hex_code) in
          if code_point >= 0 && code_point <= 0x10FFFF then
            begin
              (* Convert code point to UTF-8 *)
              if code_point < 0x80 then
                Buffer.add_char buf (Char.chr code_point)
              else if code_point < 0x800 then
                begin
                  Buffer.add_char buf (Char.chr (0xC0 lor (code_point lsr 6)));
                  Buffer.add_char buf (Char.chr (0x80 lor (code_point land 0x3F)))
                end
              else if code_point < 0x10000 then
                begin
                  Buffer.add_char buf (Char.chr (0xE0 lor (code_point lsr 12)));
                  Buffer.add_char buf (Char.chr (0x80 lor ((code_point lsr 6) land 0x3F)));
                  Buffer.add_char buf (Char.chr (0x80 lor (code_point land 0x3F)))
                end
              else
                begin
                  Buffer.add_char buf (Char.chr (0xF0 lor (code_point lsr 18)));
                  Buffer.add_char buf (Char.chr (0x80 lor ((code_point lsr 12) land 0x3F)));
                  Buffer.add_char buf (Char.chr (0x80 lor ((code_point lsr 6) land 0x3F)));
                  Buffer.add_char buf (Char.chr (0x80 lor (code_point land 0x3F)))
                end;
              process (i + 6)
            end
          else
            begin
              Buffer.add_char buf str.[i];
              process (i + 1)
            end
        with _ ->
          (* Invalid hex code, keep original *)
          Buffer.add_char buf str.[i];
          process (i + 1)
      else
        begin
          Buffer.add_char buf str.[i];
          process (i + 1)
        end
      in
      process 0
  
  (* Check if string contains double-encoding patterns that need fixing *)
  let needs_fixing str =
    (* Check for double-encoding pattern "Ã" (multi-byte UTF-8 character) *)
    let has_double_encoding = 
      try
        let idx = String.index_from str 0 (Char.chr 0xC3) in
        (* Check if next byte is one of the problematic patterns *)
        if idx < String.length str - 1 then
          let next_byte = Char.code str.[idx + 1] in
          (* Common patterns: Ã¡ (0xC3 0xA1), Ã© (0xC3 0xA9), etc. *)
          next_byte = 0xA1 || next_byte = 0xA9 || next_byte = 0xAD || 
          next_byte = 0xB3 || next_byte = 0xBA || next_byte = 0xA3 ||
          next_byte = 0xB5 || next_byte = 0xA7 || next_byte = 0x83 ||
          next_byte = 0x89 || next_byte = 0x8D || next_byte = 0x93 ||
          next_byte = 0x9A || next_byte = 0x9F || next_byte = 0x95 ||
          next_byte = 0x87
        else false
      with Not_found -> false
    in
    let has_unicode_escape = String.contains str '\\' && String.contains str 'u' in
    has_double_encoding || has_unicode_escape
  
  (* Fix double-encoding UTF-8 issues (e.g., SÃo -> São, JosÃ© -> José) *)
  let fix_double_encoding str =
    (* Only fix if string contains problematic patterns *)
    if not (needs_fixing str) then str
    else
      (* Fix common Portuguese double-encoding patterns *)
      let fixed = global_replace (regexp_string "Ã¡") "á" str in
      let fixed = global_replace (regexp_string "Ã©") "é" fixed in
      let fixed = global_replace (regexp_string "Ã­") "í" fixed in
      let fixed = global_replace (regexp_string "Ã³") "ó" fixed in
      let fixed = global_replace (regexp_string "Ãº") "ú" fixed in
      let fixed = global_replace (regexp_string "Ã£") "ã" fixed in
      let fixed = global_replace (regexp_string "Ãµ") "õ" fixed in
      let fixed = global_replace (regexp_string "Ã§") "ç" fixed in
      let fixed = global_replace (regexp_string "Ã ") "à" fixed in
      let fixed = global_replace (regexp_string "Ã¢") "â" fixed in
      let fixed = global_replace (regexp_string "Ãª") "ê" fixed in
      let fixed = global_replace (regexp_string "Ã´") "ô" fixed in
      (* Fix common typos and encoding issues *)
      let fixed = global_replace (regexp_string "ío") "ão" fixed in  (* Sío -> São *)
      let fixed = global_replace (regexp_string "Ío") "ão" fixed in  (* SÍo -> São *)
      let fixed = global_replace (regexp_string "ÍO") "ÃO" fixed in  (* SÍO -> SÃO *)
      (* Uppercase versions *)
      let fixed = global_replace (regexp_string "Ã¡") "Á" fixed in
      let fixed = global_replace (regexp_string "Ã‰") "É" fixed in
      let fixed = global_replace (regexp_string "Ã") "Í" fixed in
      let fixed = global_replace (regexp_string "Ã\"") "Ó" fixed in
      let fixed = global_replace (regexp_string "Ãš") "Ú" fixed in
      let fixed = global_replace (regexp_string "Ãƒ") "Ã" fixed in
      let fixed = global_replace (regexp_string "Ã•") "Õ" fixed in
      let fixed = global_replace (regexp_string "Ã‡") "Ç" fixed in
      fixed
  
  (* Convert to lowercase handling UTF-8 properly - for comparison/deduplication *)
  let lowercase_utf8 str =
    let fixed = global_replace (regexp_string "Á") "á" str in
    let fixed = global_replace (regexp_string "É") "é" fixed in
    let fixed = global_replace (regexp_string "Í") "í" fixed in
    let fixed = global_replace (regexp_string "Ó") "ó" fixed in
    let fixed = global_replace (regexp_string "Ú") "ú" fixed in
    let fixed = global_replace (regexp_string "Ã") "ã" fixed in
    let fixed = global_replace (regexp_string "Õ") "õ" fixed in
    let fixed = global_replace (regexp_string "Ç") "ç" fixed in
    let fixed = global_replace (regexp_string "À") "à" fixed in
    let fixed = global_replace (regexp_string "Â") "â" fixed in
    let fixed = global_replace (regexp_string "Ê") "ê" fixed in
    let fixed = global_replace (regexp_string "Ô") "ô" fixed in
    String.lowercase_ascii fixed
  
  (* Normalize city name to Title Case - handles UTF-8 characters properly *)
  let normalize_city_name city =
    let words = String.split_on_char ' ' city in
    let capitalize_word word =
      if String.length word = 0 then word
      else
        (* Get first character and convert to uppercase *)
        let first_char = String.sub word 0 1 in
        let first_upper = 
          (* Handle common Portuguese uppercase conversions *)
          match first_char with
          | "á" -> "Á" | "é" -> "É" | "í" -> "Í" | "ó" -> "Ó" | "ú" -> "Ú"
          | "ã" -> "Ã" | "õ" -> "Õ" | "ç" -> "Ç" | "à" -> "À" | "â" -> "Â"
          | "ê" -> "Ê" | "ô" -> "Ô"
          | c -> String.uppercase_ascii c
        in
        (* Get rest and convert to lowercase, handling UTF-8 *)
        let rest = String.sub word 1 (String.length word - 1) in
        let rest_lower = lowercase_utf8 rest in
        first_upper ^ rest_lower
    in
    String.concat " " (List.map capitalize_word words)
  
  (* Fix common typos in city names (e.g., "Sío" -> "São") *)
  let fix_typos str =
    let fixed = global_replace (regexp_string "ío") "ão" str in  (* Sío -> São *)
    let fixed = global_replace (regexp_string "Ío") "ão" fixed in  (* SÍo -> São *)
    let fixed = global_replace (regexp_string "ÍO") "ÃO" fixed in  (* SÍO -> SÃO *)
    fixed
  
  (* Fix and normalize city name - only if needed *)
  let fix_city_name city =
    (* First fix common typos, then check if it needs UTF-8 fixing *)
    let fixed_typos = fix_typos city in
    if needs_fixing fixed_typos then
      (* Needs fixing - apply all corrections *)
      fixed_typos
      |> decode_unicode_escapes
      |> fix_double_encoding
      |> normalize_city_name
    else
      (* Already has correct UTF-8, just normalize case *)
      normalize_city_name fixed_typos
  
  (* Get normalized key for comparison (lowercase UTF-8) *)
  let normalized_key_for_comparison city =
    fix_city_name city |> lowercase_utf8
  end

module Vehicle = struct
  
  (* Fix location_city in vehicle *)
  let fix_vehicle_city (vehicle : Types.vehicle) : Types.vehicle =
    { vehicle with location_city = Utf8Fix.fix_city_name vehicle.location_city }
  
  (* Parse vehicle from JSON *)
  let vehicle_of_json_string json_str =
    try
      let json = Yojson.Safe.from_string json_str in
      (* Log the actual JSON we're trying to parse *)
      let json_preview = String.sub json_str 0 (min 500 (String.length json_str)) in
      Logs.info (fun m -> m "Parsing JSON: %s..." json_preview);
      
      match vehicle_of_yojson json with
      | Ok v -> 
          Logs.info (fun m -> m "✅ Parsed: %s %s (source: %s)" v.brand v.model v.source);
          Some (fix_vehicle_city v)
      | Error e ->
          Logs.err (fun m -> m "❌ ppx_deriving_yojson error: %s" e);
          Logs.err (fun m -> m "Full JSON: %s" json_str);
          None
    with e ->
      Logs.err (fun m -> m "❌ Exception: %s" (Printexc.to_string e));
      Logs.err (fun m -> m "JSON: %s" json_str);
      None
  
  (* Enrich vehicle with seller info from users table if seller_id is present *)
  let enrich_with_seller_info (vehicle : Types.vehicle) =
    match vehicle.seller_id with
    | Some seller_id ->
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt Database.Q.get_seller_info_by_id seller_id
        ) >>= (function
        | Some (seller_name, seller_phone, seller_email) ->
            (* Update vehicle with fresh seller info from users table *)
            Lwt.return { vehicle with
              seller_name;
              seller_phone;
              seller_email;
            }
        | None ->
            (* Seller not found, keep original values from vehicle table *)
            Lwt.return vehicle)
    | None ->
        (* No seller_id (external vehicle), keep original values *)
        Lwt.return vehicle
  
  (* Get vehicle by slug *)
  let get_by_slug slug =
    Cache.get_vehicle slug >>= function
    | Some vehicle ->
        let fixed_vehicle = fix_vehicle_city vehicle in
        enrich_with_seller_info fixed_vehicle >>= fun enriched_vehicle ->
        Lwt.return_some enriched_vehicle
    | None ->
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find Database.Q.get_vehicle_json slug
        ) >>= fun json_str ->
        match vehicle_of_json_string json_str with
        | Some vehicle ->
            let fixed_vehicle = fix_vehicle_city vehicle in
            enrich_with_seller_info fixed_vehicle >>= fun enriched_vehicle ->
            Cache.cache_vehicle enriched_vehicle >>= fun () ->
            Lwt.return_some enriched_vehicle
        | None -> Lwt.return_none
  
  let filters_to_json (filters : vehicle_filter) offset =
    let string_field = function
      | Some value when String.trim value <> "" -> `String value
      | _ -> `Null
    in
    let int_field = function
      | Some value -> `Int value
      | None -> `Null
    in
    `Assoc [
      ("brand", string_field filters.brand);
      ("model", string_field filters.model);
      ("fuel_type", string_field filters.fuel_type);
      ("condition", string_field filters.condition);
      ("source", string_field filters.source);
      ("location_state", string_field filters.location_state);
      ("location_city", string_field filters.location_city);
      ("seller_id", int_field filters.seller_id);
      ("year_min", int_field filters.year_min);
      ("year_max", int_field filters.year_max);
      ("price_min", int_field filters.price_min);
      ("price_max", int_field filters.price_max);
      ("sort", string_field filters.sort_by);
      ("per_page", `Int filters.per_page);
      ("offset", `Int offset);
    ] |> Yojson.Safe.to_string

  (* List vehicles *)
  let list (filters : vehicle_filter) =
    let offset = (filters.page - 1) * filters.per_page in
    let filters_json = filters_to_json filters offset in
    Cache.get_vehicle_list filters.page filters >>= function
    | Some response -> 
        (* Fix cities in cached vehicles as well (safety check) *)
        let fixed_vehicles = List.map fix_vehicle_city response.vehicles in
        (* Enrich cached vehicles with seller info from users table *)
        let enriched_vehicles = Lwt_list.map_s enrich_with_seller_info fixed_vehicles in
        enriched_vehicles >>= fun enriched_vehicles_list ->
        Lwt.return { response with vehicles = enriched_vehicles_list }
    | None ->
            (* Try to get total_count from cache first *)
            Cache.get_stats_with_param "count" (Yojson.Safe.to_string (Types.vehicle_filter_to_yojson filters)) >>= function
            | Some cached_count_str ->
                (try
                  let total_count = int_of_string cached_count_str in
                  Logs.debug (fun m -> m "📦 Using cached total_count: %d" total_count);
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.collect_list Database.Q.list_vehicles_filtered (filters_json, filters.per_page, offset)
                  ) >>= fun json_rows ->
                  let vehicles = List.filter_map vehicle_of_json_string json_rows in
                  let fixed_vehicles = List.map fix_vehicle_city vehicles in
                  let enriched_vehicles = Lwt_list.map_s enrich_with_seller_info fixed_vehicles in
                  enriched_vehicles >>= fun enriched_vehicles_list ->
                  let total_pages = (total_count + filters.per_page - 1) / filters.per_page in
                  let response = {
                    vehicles = enriched_vehicles_list;
                    total_count;
                    page = filters.page;
                    total_pages;
                    has_next = filters.page < total_pages;
                    has_prev = filters.page > 1;
                  } in
                  Cache.cache_vehicle_list filters.page filters enriched_vehicles_list total_count >>= fun () ->
                  Lwt.return response
                with _ ->
                  (* If cache is corrupted, fetch from DB *)
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.find Database.Q.count_vehicles_filtered filters_json
                  ) >>= fun total_count ->
                  Cache.cache_stats_with_param "count" (Yojson.Safe.to_string (Types.vehicle_filter_to_yojson filters)) (string_of_int total_count) >>= fun () ->
                  Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                    Db.collect_list Database.Q.list_vehicles_filtered (filters_json, filters.per_page, offset)
                  ) >>= fun json_rows ->
                  let vehicles = List.filter_map vehicle_of_json_string json_rows in
                  let fixed_vehicles = List.map fix_vehicle_city vehicles in
                  let enriched_vehicles = Lwt_list.map_s enrich_with_seller_info fixed_vehicles in
                  enriched_vehicles >>= fun enriched_vehicles_list ->
                  let total_pages = (total_count + filters.per_page - 1) / filters.per_page in
                  let response = {
                    vehicles = enriched_vehicles_list;
                    total_count;
                    page = filters.page;
                    total_pages;
                    has_next = filters.page < total_pages;
                    has_prev = filters.page > 1;
                  } in
                  Cache.cache_vehicle_list filters.page filters enriched_vehicles_list total_count >>= fun () ->
                  Lwt.return response)
            | None ->
                Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
                  Db.find Database.Q.count_vehicles_filtered filters_json
                ) >>= fun total_count ->
                (* Cache the count *)
                Cache.cache_stats_with_param "count" (Yojson.Safe.to_string (Types.vehicle_filter_to_yojson filters)) (string_of_int total_count) >>= fun () ->
            Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list Database.Q.list_vehicles_filtered (filters_json, filters.per_page, offset)
            ) >>= fun json_rows ->
        
        let vehicles = List.filter_map vehicle_of_json_string json_rows in
        
        (* Fix cities in all vehicles *)
        let fixed_vehicles = List.map fix_vehicle_city vehicles in
        
        (* Enrich all vehicles with seller info from users table *)
        let enriched_vehicles = Lwt_list.map_s enrich_with_seller_info fixed_vehicles in
        enriched_vehicles >>= fun enriched_vehicles_list ->
        
        let total_pages = (total_count + filters.per_page - 1) / filters.per_page in
        let response = {
          vehicles = enriched_vehicles_list;
          total_count;
          page = filters.page;
          total_pages;
          has_next = filters.page < total_pages;
          has_prev = filters.page > 1;
        } in
        
        Cache.cache_vehicle_list filters.page filters enriched_vehicles_list total_count >>= fun () ->
        Lwt.return response
  
  let list_active_brands () =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list Database.Q.list_active_brands ()
    )

  let list_active_models brand =
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list Database.Q.list_active_models_by_brand brand
      )
  
  let list_active_cities state =
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list Database.Q.list_active_cities_by_state state
      )
  
  (* Public function to fix and normalize city name *)
  let fix_city_name = Utf8Fix.fix_city_name
  
  (* Public function to get normalized key for comparison *)
  let normalized_city_key = Utf8Fix.normalized_key_for_comparison
end

module ScraperJob = struct
  open Types
  
  (* Parse scraper job from JSON string *)
  let scraper_job_of_json_string json_str =
    try
      let json = Yojson.Safe.from_string json_str in
      match scraper_job_of_yojson json with
      | Ok job -> Some job
      | Error e ->
          Logs.err (fun m -> m "❌ Error parsing scraper_job: %s" e);
          None
    with e ->
      Logs.err (fun m -> m "❌ Exception parsing scraper_job: %s" (Printexc.to_string e));
      None
  
  (* Convert filter to JSON for SQL query *)
  let filter_to_json (filter : scraper_job_filter) =
    let string_field = function
      | Some value when value <> "" -> `String value
      | _ -> `String ""  (* Use empty string instead of null for SQL compatibility *)
    in
    `Assoc [
      ("search", string_field filter.search);
      ("source", string_field filter.source);
    ]
  
  (* List scraper jobs with filters and pagination *)
  let list (filter : scraper_job_filter) =
    let offset = (filter.page - 1) * filter.per_page in
    let filter_json = filter_to_json filter in
    let filter_json_str = Yojson.Safe.to_string filter_json in
    
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find Database.Q.count_scraper_jobs_filtered filter_json_str
    ) >>= fun total_count ->
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list Database.Q.list_scraper_jobs_filtered (filter_json_str, filter.per_page, offset)
    ) >>= fun json_rows ->
    
    let jobs = List.filter_map scraper_job_of_json_string json_rows in
    let total_pages = (total_count + filter.per_page - 1) / filter.per_page in
    Lwt.return {
      jobs;
      total_count;
      page = filter.page;
      total_pages;
      has_next = filter.page < total_pages;
      has_prev = filter.page > 1;
    }

  let get_by_id job_id =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find_opt Database.Q.get_scraper_job_by_id job_id
    ) >>= function
    | Some json_str -> Lwt.return (scraper_job_of_json_string json_str)
    | None -> Lwt.return_none

  let create brand model source user_id =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find Database.Q.create_scraper_job (brand, model, source, user_id)
    ) >>= fun json_str ->
    Lwt.return (scraper_job_of_json_string json_str)

  let update job_id brand model source is_active =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find Database.Q.update_scraper_job (job_id, brand, model, source, is_active)
    ) >>= fun json_str ->
    Lwt.return (scraper_job_of_json_string json_str)

  let delete job_id =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.exec Database.Q.delete_scraper_job job_id
    ) >>= fun () ->
    Lwt.return_unit

  let list_active () =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list Database.Q.list_active_scraper_jobs ()
    ) >>= fun json_rows ->
    Lwt.return (List.filter_map scraper_job_of_json_string json_rows)

  let update_run_stats job_id success =
    Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.exec Database.Q.update_scraper_job_run_stats (job_id, success)
    ) >>= fun () ->
    Lwt.return_unit
end
