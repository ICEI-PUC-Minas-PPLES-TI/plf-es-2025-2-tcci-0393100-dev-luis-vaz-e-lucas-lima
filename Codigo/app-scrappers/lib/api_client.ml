(* API client for communicating with the backend *)

open Lwt.Infix
open Types
open Scrapers_types

let backend_url = Config.backend_url

(* Use curl_lwt - OCaml binding for libcurl with Lwt support - much more reliable than calling curl via process *)
let http_get url =
  let curl = ref None in
  Lwt.catch
    (fun () ->
      let c = Curl.init () in
      curl := Some c;
      Curl.set_url c url;
      Curl.set_timeout c 30;
      Curl.set_connecttimeout c 10;
      Curl.set_followlocation c true;
      Curl.set_maxredirs c 5;
      let buffer = Buffer.create 1024 in
      Curl.set_writefunction c (fun s -> Buffer.add_string buffer s; String.length s);
      Curl_lwt.perform c >>= fun code ->
      (match code with
       | Curl.CURLE_OK -> ()
       | _ -> 
           (try Curl.cleanup c with _ -> ());
           raise (Failure (Printf.sprintf "curl error: %s" (Curl.strerror code))));
      let http_code = Curl.get_responsecode c in
      let body = Buffer.contents buffer in
      Curl.cleanup c;
      curl := None;
      if http_code >= 200 && http_code < 300 then
        Lwt.return_ok body
      else
        Lwt.return_error (Printf.sprintf "HTTP %d: %s" http_code body))
    (fun exn ->
      (match !curl with Some c -> (try Curl.cleanup c with _ -> ()) | None -> ());
      Logs.err (fun m -> m "Exception in http_get for %s: %s" url (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "HTTP request failed: %s" (Printexc.to_string exn)))

let http_get_with_header url header_name header_value =
  let curl = ref None in
  Lwt.catch
    (fun () ->
      let c = Curl.init () in
      curl := Some c;
      Curl.set_url c url;
      Curl.set_timeout c 30;
      Curl.set_connecttimeout c 10;
      Curl.set_followlocation c true;
      Curl.set_maxredirs c 5;
      Curl.set_httpheader c [Printf.sprintf "%s: %s" header_name header_value];
      let buffer = Buffer.create 1024 in
      Curl.set_writefunction c (fun s -> Buffer.add_string buffer s; String.length s);
      Curl_lwt.perform c >>= fun code ->
      (match code with
       | Curl.CURLE_OK -> ()
       | _ -> 
           (try Curl.cleanup c with _ -> ());
           raise (Failure (Printf.sprintf "curl error: %s" (Curl.strerror code))));
      let http_code = Curl.get_responsecode c in
      let body = Buffer.contents buffer in
      Curl.cleanup c;
      curl := None;
      if http_code >= 200 && http_code < 300 then
        Lwt.return_ok body
      else
        Lwt.return_error (Printf.sprintf "HTTP %d: %s" http_code body))
    (fun exn ->
      (match !curl with Some c -> (try Curl.cleanup c with _ -> ()) | None -> ());
      Logs.err (fun m -> m "Exception in http_get_with_header for %s: %s" url (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "HTTP request failed: %s" (Printexc.to_string exn)))

let http_post url body headers =
  let curl = ref None in
  Lwt.catch
    (fun () ->
      let c = Curl.init () in
      curl := Some c;
      Curl.set_url c url;
      Curl.set_timeout c 30;
      Curl.set_connecttimeout c 10;
      Curl.set_post c true;
      Curl.set_postfields c body;
      Curl.set_postfieldsize c (String.length body);
      Curl.set_httpheader c headers;
      let buffer = Buffer.create 1024 in
      Curl.set_writefunction c (fun s -> Buffer.add_string buffer s; String.length s);
      Curl_lwt.perform c >>= fun code ->
      (match code with
       | Curl.CURLE_OK -> ()
       | _ -> 
           (try Curl.cleanup c with _ -> ());
           raise (Failure (Printf.sprintf "curl error: %s" (Curl.strerror code))));
      let http_code = Curl.get_responsecode c in
      let response_body = Buffer.contents buffer in
      Curl.cleanup c;
      curl := None;
      if http_code >= 200 && http_code < 300 || http_code = 409 then
        Lwt.return_ok response_body
      else
        (* Include response body in error for debugging *)
        let error_msg = if String.length response_body > 0 then
          Printf.sprintf "HTTP %d: %s" http_code response_body
        else
          Printf.sprintf "HTTP %d" http_code
        in
        Lwt.return_error error_msg)
    (fun exn ->
      (match !curl with Some c -> (try Curl.cleanup c with _ -> ()) | None -> ());
      Logs.err (fun m -> m "Exception in http_post for %s: %s" url (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "HTTP request failed: %s" (Printexc.to_string exn)))

let fetch_active_jobs () =
  let url = backend_url ^ "/api/scraper-jobs/active" in
  Logs.info (fun m -> m "Fetching active scraper jobs from %s" url);
  http_get_with_header url "X-Scraper-Key" Config.scraper_key >>= function
  | Error msg -> 
      Logs.err (fun m -> m "curl_get error: %s" msg);
      Lwt.return_error msg
  | Ok body_str ->
      Logs.debug (fun m -> m "Response body (first 200 chars): %s" (if String.length body_str > 200 then String.sub body_str 0 200 ^ "..." else body_str));
      if String.trim body_str = "" then
        (Logs.err (fun m -> m "Empty response from backend");
         Lwt.return_error "Empty response from backend")
      else
      (try
         let json = Yojson.Safe.from_string body_str in
         (* The endpoint returns a list directly, not wrapped in success/data *)
         match json with
         | `List jobs_json ->
             let jobs = List.fold_left (fun acc job_json ->
               match scraper_job_of_yojson job_json with
               | Ok job -> job :: acc
               | Error msg ->
                   Logs.warn (fun m -> m "Failed to parse job: %s. JSON: %s" msg (Yojson.Safe.to_string job_json));
                   acc
             ) [] jobs_json in
             Logs.info (fun m -> m "Found %d active scraper jobs" (List.length jobs));
             Lwt.return_ok (List.rev jobs)
         | _ ->
             Logs.err (fun m -> m "Unexpected response format");
             Lwt.return_error "Unexpected response format"
       with
       | exn ->
           Logs.err (fun m -> m "Exception parsing response: %s" (Printexc.to_string exn));
           Lwt.return_error ("Exception: " ^ Printexc.to_string exn))

let update_job_stats job_id success =
  let url = backend_url ^ "/api/scraper-jobs/" ^ string_of_int job_id ^ "/stats" in
  let body = Yojson.Safe.to_string (`Assoc [
    ("success", `Bool success)
  ]) in
  let headers = [
    "Content-Type: application/json";
    Printf.sprintf "X-Scraper-Key: %s" Config.scraper_key
  ] in
  Logs.debug (fun m -> m "Updating job %d stats (success: %b)" job_id success);
  http_post url body headers >>= function
  | Error msg ->
      Logs.warn (fun m -> m "Failed to update job stats: %s" msg);
      Lwt.return_ok () (* Don't fail the whole process if stats update fails *)
  | Ok _ -> Lwt.return_ok ()

let bulk_import_vehicles (vehicles : Scrapers_types.vehicle list) =
  Lwt.catch
    (fun () ->
      (* Convert all vehicles to API JSON format *)
      let vehicles_json = List.map (fun vehicle ->
        match vehicle.source with
        | "localiza" -> Vehicle_converter.convert_from_localiza vehicle
        | "icarros" -> Vehicle_converter.convert_from_icarros vehicle
        | _ -> failwith (Printf.sprintf "Unknown source: %s" vehicle.source)
      ) vehicles in
      
      let vehicles_array = `List vehicles_json in
      let body = Yojson.Safe.to_string vehicles_array in
      
      Logs.info (fun m -> m "Bulk importing %d vehicles" (List.length vehicles));
      
      let url = backend_url ^ "/api/vehicles/scraper/bulk" in
      let headers = [
        "Content-Type: application/json";
        Printf.sprintf "X-Scraper-Key: %s" Config.scraper_key
      ] in
      http_post url body headers >>= function
      | Error msg ->
          Logs.err (fun m -> m "Failed to bulk import vehicles: %s" msg);
          Lwt.return_error msg
      | Ok response_body ->
          (try
            let json = Yojson.Safe.from_string response_body in
            let imported_count = Yojson.Safe.Util.member "data" json
              |> Yojson.Safe.Util.member "imported_count"
              |> Yojson.Safe.Util.to_int_option
              |> Option.value ~default:(List.length vehicles) in
            Logs.info (fun m -> m "✅ Successfully bulk imported %d/%d vehicles" imported_count (List.length vehicles));
            Lwt.return_ok imported_count
          with _ ->
            Logs.info (fun m -> m "✅ Successfully bulk imported vehicles (response: %s)" 
              (if String.length response_body > 200 then String.sub response_body 0 200 ^ "..." else response_body));
            Lwt.return_ok (List.length vehicles)))
    (fun exn ->
      Logs.err (fun m -> m "Exception bulk importing vehicles: %s" (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "Exception: %s" (Printexc.to_string exn)))

let import_vehicle (scraper_vehicle : Scrapers_types.vehicle) =
  Lwt.catch
    (fun () ->
  (* Convert scraper vehicle format to API JSON format *)
  let vehicle_json = match scraper_vehicle.source with
    | "localiza" -> Vehicle_converter.convert_from_localiza scraper_vehicle
    | "icarros" -> Vehicle_converter.convert_from_icarros scraper_vehicle
    | _ -> failwith (Printf.sprintf "Unknown source: %s" scraper_vehicle.source)
  in
  
  let body = Yojson.Safe.to_string vehicle_json in
  
      (* Log first 500 chars of body for debugging *)
      let body_preview = if String.length body > 500 then
        String.sub body 0 500 ^ "..."
      else
        body
      in
      Logs.debug (fun m -> m "Importing vehicle: %s %s (year: %s). JSON preview: %s" 
        scraper_vehicle.brand scraper_vehicle.model
        (match scraper_vehicle.year with Some y -> string_of_int y | None -> "N/A")
        body_preview);
  
  let url = backend_url ^ "/api/vehicles/scraper" in
      let headers = [
        "Content-Type: application/json";
        Printf.sprintf "X-Scraper-Key: %s" Config.scraper_key
      ] in
      http_post url body headers >>= function
      | Error msg ->
          (* Check if it's a 409 (already exists) - look for "409" in the message *)
          if (try 
                let idx = String.index msg '4' in
                String.length msg >= idx + 3 && String.sub msg idx 3 = "409"
              with _ -> false) then
            (Logs.debug (fun m -> m "Vehicle already exists (409): %s" scraper_vehicle.detail_url);
             Lwt.return_ok ())
          else
            (Logs.warn (fun m -> m "Failed to import vehicle: %s. URL: %s" msg scraper_vehicle.detail_url);
             Lwt.return_error msg)
      | Ok _ ->
          Logs.info (fun m -> m "Successfully imported vehicle: %s" scraper_vehicle.detail_url);
          Lwt.return_ok ())
    (fun exn ->
      Logs.err (fun m -> m "Exception importing vehicle %s %s: %s" 
        scraper_vehicle.brand scraper_vehicle.model (Printexc.to_string exn));
      Lwt.return_error (Printf.sprintf "Exception: %s" (Printexc.to_string exn)))

(* Call maintenance endpoint to deactivate stale vehicles *)
let deactivate_stale_vehicles days =
  let url = Printf.sprintf "%s/api/maintenance/deactivate-stale-vehicles" backend_url in
  let body = Printf.sprintf "{\"days\": %d}" days in
  let headers = [
    "Content-Type: application/json";
    Printf.sprintf "X-Cron-Job-Key: %s" Config.scraper_key
  ] in
  Logs.info (fun m -> m "🧹 Maintenance: Calling deactivate-stale-vehicles with %d days" days);
  http_post url body headers >>= function
  | Ok response_body ->
      Logs.info (fun m -> m "✅ Maintenance: Successfully deactivated stale vehicles. Response: %s" 
        (if String.length response_body > 200 then String.sub response_body 0 200 ^ "..." else response_body));
      Lwt.return_ok ()
  | Error msg ->
      Logs.err (fun m -> m "❌ Maintenance: Failed to deactivate stale vehicles: %s" msg);
      Lwt.return_error msg

