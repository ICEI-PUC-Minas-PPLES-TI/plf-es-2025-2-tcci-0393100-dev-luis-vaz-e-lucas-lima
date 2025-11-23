(* Main entry point for the scraper orchestrator *)

open Lwt.Infix

let () =
  (* Initialize random seed *)
  Random.self_init ();
  
  (* Setup logging *)
  Logs.set_reporter (Logs.format_reporter ());
  Logs.set_level (Some App_scrappers_lib.Config.log_level);
  
  Logs.info (fun m -> m "Starting BusCars Scraper Orchestrator");
  Logs.info (fun m -> m "Backend URL: %s" App_scrappers_lib.Config.backend_url);
  Logs.info (fun m -> m "Delay range: %d-%d seconds" App_scrappers_lib.Config.min_delay_seconds App_scrappers_lib.Config.max_delay_seconds);
  
  (* Run main loop *)
  Lwt_main.run (App_scrappers_lib.Orchestrator.main_loop ())

