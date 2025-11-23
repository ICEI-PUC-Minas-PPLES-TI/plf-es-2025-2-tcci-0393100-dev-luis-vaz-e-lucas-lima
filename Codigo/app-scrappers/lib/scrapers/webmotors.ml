(* Webmotors scraper - placeholder for now *)

open Lwt.Infix
open Scrapers_types
open Common

let scrape brand model =
  Logs.warn (fun m -> m "Webmotors scraper not yet implemented");
  Lwt.return_error "Webmotors scraper not yet implemented"

