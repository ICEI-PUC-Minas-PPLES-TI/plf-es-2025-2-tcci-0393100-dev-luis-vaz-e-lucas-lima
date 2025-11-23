(* Configuration module *)

let backend_url =
  let normalize_url url =
    let url = String.trim url in
    (* Remove quotes if present *)
    let url = if String.length url > 0 && url.[0] = '"' then
      String.sub url 1 (String.length url - 1)
    else
      url in
    let url = if String.length url > 0 && url.[String.length url - 1] = '"' then
      String.sub url 0 (String.length url - 1)
    else
      url in
    let url = String.trim url in
    (* Ensure URL has a scheme (http:// or https://) *)
    if String.length url >= 7 && (String.sub url 0 7 = "http://" || String.sub url 0 8 = "https://") then
      url
    else if String.length url >= 8 && String.sub url 0 8 = "https://" then
      url
    else
      "http://" ^ url
  in
  try 
    normalize_url (Sys.getenv "BACKEND_URL")
  with Not_found -> "http://backend:3000"

let log_level =
  try
    match Sys.getenv "LOG_LEVEL" with
    | "debug" -> Logs.Debug
    | "info" -> Logs.Info
    | "warn" -> Logs.Warning
    | "error" -> Logs.Error
    | _ -> Logs.Info
  with Not_found -> Logs.Info

let min_delay_seconds =
  try int_of_string (Sys.getenv "MIN_DELAY_SECONDS")
  with Not_found -> 300 (* 5 minutes *)

let max_delay_seconds =
  try int_of_string (Sys.getenv "MAX_DELAY_SECONDS")
  with Not_found -> 3600 (* 1 hour *)

let scraper_key =
  try Sys.getenv "CRON_JOB_KEY"
  with Not_found -> "default-cron-key-change-me"

let stale_vehicles_days =
  try int_of_string (Sys.getenv "STALE_VEHICLES_DAYS")
  with Not_found -> 3 (* Default: 3 days *)

(* Enabled scrapers: comma-separated list or "both" for all *)
(* Default: "localiza" *)
let enabled_scrapers =
  try
    let env_value = Sys.getenv "ENABLED_SCRAPERS" in
    let env_value = String.lowercase_ascii (String.trim env_value) in
    match env_value with
    | "both" | "all" -> ["localiza"; "icarros"]
    | "localiza" -> ["localiza"]
    | "icarros" -> ["icarros"]
    | s ->
        (* Parse comma-separated list *)
        String.split_on_char ',' s
        |> List.map String.trim
        |> List.map String.lowercase_ascii
        |> List.filter (fun x -> x = "localiza" || x = "icarros")
  with Not_found -> ["localiza"] (* Default: only localiza *)
