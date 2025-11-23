(* Orchestrator for running scrapers randomly throughout the day *)

open Lwt.Infix
open Types
open Localiza
open Icarros

(* Helper functions for list batching *)
let rec take n = function
  | [] -> []
  | x :: xs when n > 0 -> x :: take (n - 1) xs
  | _ -> []

let rec drop n = function
  | [] -> []
  | xs when n <= 0 -> xs
  | _ :: xs -> drop (n - 1) xs

let random_delay () =
  let min_delay = Config.min_delay_seconds in
  let max_delay = Config.max_delay_seconds in
  let delay = min_delay + Random.int (max_delay - min_delay + 1) in
  Logs.info (fun m -> m "Next scraper run in %d seconds (~%.1f minutes)" delay (float_of_int delay /. 60.0));
  Lwt_unix.sleep (float_of_int delay)

let run_scraper_job (job : scraper_job) =
  Logs.info (fun m -> m "Running scraper job: %s %s from %s" job.brand job.model job.source);
  
  (* Call the appropriate scraper based on source *)
  let%lwt result = match job.source with
    | "localiza" -> Localiza.scrape job.brand job.model
    | "icarros" -> Icarros.scrape job.brand job.model
    | "webmotors" ->
        Logs.warn (fun m -> m "Scraper %s not yet implemented" job.source);
        Lwt.return_error ("Scraper not yet implemented: " ^ job.source)
    | _ ->
        Logs.err (fun m -> m "Unknown source: %s" job.source);
        Lwt.return_error ("Unknown source: " ^ job.source)
  in
  
  match result with
  | Ok vehicles ->
      Logs.info (fun m -> m "Scraped %d vehicles for %s %s" (List.length vehicles) job.brand job.model);
      
      (* Import vehicles in batches to avoid overwhelming the database *)
      let batch_size = 100 in
      let rec import_batch remaining =
        match remaining with
        | [] -> Lwt.return_ok 0
        | batch ->
            let batch_list = if List.length remaining > batch_size then
              take batch_size remaining
            else
              remaining
            in
            let rest = if List.length remaining > batch_size then
              drop batch_size remaining
            else
              []
            in
            Logs.info (fun m -> m "Importing batch of %d vehicles (remaining: %d)" 
              (List.length batch_list) (List.length rest));
            Api_client.bulk_import_vehicles batch_list >>= function
            | Ok imported_count ->
                (* Small delay between batches to avoid overwhelming the database *)
                let%lwt () = if List.length rest > 0 then Lwt_unix.sleep 0.1 else Lwt.return_unit in
                import_batch rest >>= function
                | Ok rest_count -> Lwt.return_ok (imported_count + rest_count)
                | Error _ -> Lwt.return_ok imported_count
            | Error msg ->
                Logs.warn (fun m -> m "Batch import failed: %s, trying individual imports" msg);
                (* Fallback to individual imports for this batch *)
                let%lwt individual_results = Lwt_list.map_p (fun vehicle ->
                  Lwt.catch
                    (fun () -> Api_client.import_vehicle vehicle)
                    (fun exn ->
                      Logs.err (fun m -> m "Exception importing vehicle: %s" (Printexc.to_string exn));
                      Lwt.return_error (Printexc.to_string exn))
                ) batch_list in
                let batch_success = List.fold_left (fun acc -> function
                  | Ok () -> acc + 1
                  | Error _ -> acc
                ) 0 individual_results in
                import_batch rest >>= function
                | Ok rest_count -> Lwt.return_ok (batch_success + rest_count)
                | Error _ -> Lwt.return_ok batch_success
      in
      
      let%lwt import_result = import_batch vehicles in
      match import_result with
      | Ok success_count ->
          let error_count = List.length vehicles - success_count in
          Logs.info (fun m -> m "Imported %d/%d vehicles successfully" success_count (List.length vehicles));
          (* Update job stats *)
          let%lwt _ = Api_client.update_job_stats job.scraper_job_id (error_count = 0) in
          Lwt.return_ok ()
      | Error msg ->
          Logs.err (fun m -> m "Failed to import vehicles: %s" msg);
          let%lwt _ = Api_client.update_job_stats job.scraper_job_id false in
          Lwt.return_error msg
  | Error msg ->
      Logs.err (fun m -> m "Scraper failed: %s" msg);
      let%lwt _ = Api_client.update_job_stats job.scraper_job_id false in
      Lwt.return_error msg

(* Group jobs by provider (source) to process them sequentially per provider *)
let group_jobs_by_provider (jobs : Types.scraper_job list) : (string * Types.scraper_job list) list =
  let groups : (string, Types.scraper_job list) Hashtbl.t = Hashtbl.create 10 in
  List.iter (fun (job : Types.scraper_job) ->
    let provider = job.source in
    let existing = try Hashtbl.find groups provider with Not_found -> [] in
    Hashtbl.replace groups provider (job :: existing)
  ) jobs;
  Hashtbl.fold (fun provider job_list acc -> (provider, List.rev job_list) :: acc) groups []

(* Split list into chunks of size n *)
let rec chunks n = function
  | [] -> []
  | xs when List.length xs <= n -> [xs]
  | xs -> take n xs :: chunks n (drop n xs)

(* Create chunks ensuring no duplicate (brand, model) in the same chunk *)
let chunks_no_duplicates n (jobs : Types.scraper_job list) : Types.scraper_job list list =
  let seen_in_chunk = Hashtbl.create 10 in
  let current_chunk = ref [] in
  let chunks = ref [] in
  
  let rec process_jobs (remaining : Types.scraper_job list) =
    match remaining with
    | [] -> 
        if List.length !current_chunk > 0 then
          chunks := !current_chunk :: !chunks;
        List.rev !chunks
    | job :: rest ->
        let key = Printf.sprintf "%s|%s" (String.lowercase_ascii job.brand) (String.lowercase_ascii job.model) in
        if Hashtbl.mem seen_in_chunk key then (
          (* This brand+model already in current chunk, skip to next chunk *)
          if List.length !current_chunk > 0 then (
            chunks := !current_chunk :: !chunks;
            current_chunk := [];
            Hashtbl.clear seen_in_chunk
          );
          process_jobs (job :: rest)
        ) else if List.length !current_chunk >= n then (
          (* Current chunk is full, start new chunk *)
          chunks := !current_chunk :: !chunks;
          current_chunk := [];
          Hashtbl.clear seen_in_chunk;
          process_jobs (job :: rest)
        ) else (
          (* Add to current chunk *)
          Hashtbl.add seen_in_chunk key true;
          current_chunk := job :: !current_chunk;
          process_jobs rest
        )
  in
  process_jobs jobs

(* Process jobs: different providers in parallel, but jobs from same provider sequentially *)
(* Special case: iCarros can run up to 5 jobs in parallel *)
let run_all_jobs jobs =
  Logs.info (fun m -> m "Running %d scraper jobs" (List.length jobs));
  
  (* Group jobs by provider *)
  let provider_groups = group_jobs_by_provider jobs in
  Logs.info (fun m -> m "Grouped into %d provider groups" (List.length provider_groups));
  
  (* Process each provider group in parallel (different providers can run simultaneously) *)
  Lwt_list.iter_p (fun (provider, provider_jobs) ->
    Logs.info (fun m -> m "Processing %d jobs for provider: %s" (List.length provider_jobs) provider);
    
    (* For iCarros, allow up to 10 jobs to run in parallel *)
    if provider = "icarros" then (
      (* Split iCarros jobs into chunks of 10, ensuring no duplicate (brand, model) in same chunk *)
      let job_chunks = chunks_no_duplicates 10 provider_jobs in
      Logs.info (fun m -> m "iCarros: Processing %d unique jobs in %d parallel batches (max 10 per batch, no duplicate brand+model in same batch)" 
        (List.length provider_jobs) (List.length job_chunks));
      
      (* Process each chunk sequentially, but jobs within a chunk run in parallel *)
      Lwt_list.iter_s (fun chunk ->
        Logs.info (fun m -> m "iCarros: Starting parallel batch of %d jobs" (List.length chunk));
        (* Process all jobs in this chunk in parallel *)
        Lwt_list.iter_p (fun job ->
          Lwt.catch
            (fun () -> 
              let%lwt result = run_scraper_job job in
              match result with
              | Ok () -> Lwt.return_unit
              | Error _ -> Lwt.return_unit)
            (fun exn ->
              Logs.err (fun m -> m "Exception running job %d: %s" job.scraper_job_id (Printexc.to_string exn));
              let%lwt _ = Api_client.update_job_stats job.scraper_job_id false in
              Lwt.return_unit)
        ) chunk >>= fun () ->
        (* Small delay between batches to avoid overwhelming the provider *)
        if List.length job_chunks > 1 then
          Lwt_unix.sleep 0.5
        else
          Lwt.return_unit
      ) job_chunks >>= fun () ->
      Logs.info (fun m -> m "Finished processing provider: %s" provider);
      Lwt.return_unit
    ) else (
      (* For other providers, allow up to 5 jobs to run in parallel *)
      let job_chunks = chunks 5 provider_jobs in
      Logs.info (fun m -> m "%s: Processing %d jobs in %d parallel batches (max 5 per batch)" 
        provider (List.length provider_jobs) (List.length job_chunks));
      
      (* Process each chunk sequentially, but jobs within a chunk run in parallel *)
      Lwt_list.iter_s (fun chunk ->
        Logs.info (fun m -> m "%s: Starting parallel batch of %d jobs" provider (List.length chunk));
        (* Process all jobs in this chunk in parallel *)
        Lwt_list.iter_p (fun job ->
          Lwt.catch
            (fun () -> 
              let%lwt result = run_scraper_job job in
              match result with
              | Ok () -> Lwt.return_unit
              | Error _ -> Lwt.return_unit)
            (fun exn ->
              Logs.err (fun m -> m "Exception running job %d: %s" job.scraper_job_id (Printexc.to_string exn));
              let%lwt _ = Api_client.update_job_stats job.scraper_job_id false in
              Lwt.return_unit)
        ) chunk >>= fun () ->
        (* Small delay between batches *)
        if List.length job_chunks > 1 then
          Lwt_unix.sleep 0.2
        else
          Lwt.return_unit
      ) job_chunks >>= fun () ->
      
      Logs.info (fun m -> m "Finished processing provider: %s" provider);
      Lwt.return_unit
    )
  ) provider_groups

(* Get current hour in São Paulo timezone *)
let get_sao_paulo_hour () =
  (* Set timezone to America/Sao_Paulo *)
  Unix.putenv "TZ" "America/Sao_Paulo";
  let tm = Unix.localtime (Unix.time ()) in
  tm.Unix.tm_hour

(* Check if it's 6 AM in São Paulo timezone *)
let is_maintenance_time () =
  get_sao_paulo_hour () = 6

(* Track if maintenance was already run today to avoid multiple runs *)
let last_maintenance_date = ref None

(* Check if maintenance should run (6 AM São Paulo, once per day) *)
let should_run_maintenance () =
  let current_hour = get_sao_paulo_hour () in
  let current_date = Unix.localtime (Unix.time ()) in
  let today = (current_date.Unix.tm_year, current_date.Unix.tm_mon, current_date.Unix.tm_mday) in
  
  if current_hour = 6 then (
    match !last_maintenance_date with
    | Some last_date when last_date = today -> false (* Already ran today *)
    | _ -> 
        last_maintenance_date := Some today;
        true
  ) else
    false

let main_loop () =
  Logs.info (fun m -> m "Starting scraper orchestrator");
  Logs.info (fun m -> m "Enabled scrapers: %s" (String.concat ", " Config.enabled_scrapers));
  Logs.info (fun m -> m "Maintenance configured: Daily at 6 AM (São Paulo timezone), deactivating vehicles older than %d days" Config.stale_vehicles_days);
  
  let rec loop () =
    (* Check if it's time for maintenance (6 AM São Paulo) *)
    if should_run_maintenance () then (
      Logs.info (fun m -> m "🧹 Maintenance time: Deactivating stale vehicles (not updated in %d+ days)" Config.stale_vehicles_days);
      let%lwt maintenance_result = Api_client.deactivate_stale_vehicles Config.stale_vehicles_days in
      (match maintenance_result with
      | Ok () -> Logs.info (fun m -> m "✅ Maintenance completed successfully")
      | Error msg -> Logs.err (fun m -> m "❌ Maintenance failed: %s" msg));
      (* Wait 1 hour after maintenance before checking again *)
      let%lwt () = Lwt_unix.sleep 3600.0 in
      loop ()
    ) else (
      (* Fetch active jobs *)
      let%lwt jobs_result = Api_client.fetch_active_jobs () in
      
      match jobs_result with
      | Ok jobs when List.length jobs > 0 ->
          (* Filter jobs by enabled scrapers *)
          let enabled = Config.enabled_scrapers in
          let filtered_jobs = List.filter (fun (job : Types.scraper_job) ->
            List.mem job.source enabled
          ) jobs in
          
          if List.length filtered_jobs = 0 then (
            Logs.info (fun m -> m "No jobs match enabled scrapers: %s" (String.concat ", " enabled));
            let%lwt () = random_delay () in
            loop ()
          ) else (
            if List.length jobs <> List.length filtered_jobs then (
              Logs.info (fun m -> m "Filtered %d jobs to %d based on enabled scrapers: %s" 
                (List.length jobs) (List.length filtered_jobs) (String.concat ", " enabled))
            );
            (* Run filtered jobs *)
            let%lwt () = run_all_jobs filtered_jobs in
            
            (* Wait before next cycle *)
            let%lwt () = random_delay () in
            loop ()
          )
      | Ok [] ->
          Logs.info (fun m -> m "No active scraper jobs found, waiting...");
          let%lwt () = random_delay () in
          loop ()
      | Error msg ->
          Logs.err (fun m -> m "Failed to fetch jobs: %s, retrying in 60 seconds" msg);
          let%lwt () = Lwt_unix.sleep 60.0 in
          loop ()
    )
  in
  
  loop ()

