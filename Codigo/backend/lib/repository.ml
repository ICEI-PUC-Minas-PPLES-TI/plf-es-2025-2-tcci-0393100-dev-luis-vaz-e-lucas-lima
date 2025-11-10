(* Repository layer - Pure database access via JSON *)

open Lwt.Infix
open Types

module Vehicle = struct
  
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
          Some v
      | Error e ->
          Logs.err (fun m -> m "❌ ppx_deriving_yojson error: %s" e);
          Logs.err (fun m -> m "Full JSON: %s" json_str);
          None
    with e ->
      Logs.err (fun m -> m "❌ Exception: %s" (Printexc.to_string e));
      Logs.err (fun m -> m "JSON: %s" json_str);
      None
  
  (* Get vehicle by slug *)
  let get_by_slug slug =
    Cache.get_vehicle slug >>= function
    | Some vehicle -> Lwt.return_some vehicle
    | None ->
        Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find Database.Q.get_vehicle_json slug
        ) >>= fun json_str ->
        match vehicle_of_json_string json_str with
        | Some vehicle ->
            Cache.cache_vehicle vehicle >>= fun () ->
            Lwt.return_some vehicle
        | None -> Lwt.return_none
  
  (* List vehicles *)
  let list (filters : vehicle_filter) =
    let offset = (filters.page - 1) * filters.per_page in
    
    Cache.get_vehicle_list filters.page filters >>= function
    | Some response -> Lwt.return response
    | None ->
        (match filters.source with
        | Some source when source <> "" ->
            Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
              Db.find Database.Q.count_vehicles_by_source source
            ) >>= fun total_count ->
            Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
              Db.collect_list Database.Q.list_vehicles_json_by_source (source, filters.per_page, offset)
            ) >>= fun json_rows ->
            Lwt.return (total_count, json_rows)
        | _ ->
            Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
              Db.find Database.Q.count_vehicles ()
            ) >>= fun total_count ->
            Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
              Db.collect_list Database.Q.list_vehicles_json (filters.per_page, offset)
            ) >>= fun json_rows ->
            Lwt.return (total_count, json_rows)
        ) >>= fun (total_count, json_rows) ->
        
        let vehicles = List.filter_map vehicle_of_json_string json_rows in
        
        let total_pages = (total_count + filters.per_page - 1) / filters.per_page in
        let response = {
          vehicles;
          total_count;
          page = filters.page;
          total_pages;
          has_next = filters.page < total_pages;
          has_prev = filters.page > 1;
        } in
        
        Cache.cache_vehicle_list filters.page filters vehicles total_count >>= fun () ->
        Lwt.return response
  
  (* Increment view count *)
  let increment_views slug =
    Cache.increment_view_count slug >>= fun count ->
    let count_int = Int64.to_int count in
    if count_int mod 10 = 0 then
      Database.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
        Db.exec Database.Q.increment_views slug
      )
    else
      Lwt.return_unit
end
