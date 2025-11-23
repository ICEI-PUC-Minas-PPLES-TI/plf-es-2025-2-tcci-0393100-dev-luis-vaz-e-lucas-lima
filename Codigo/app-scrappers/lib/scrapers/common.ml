(* Common utilities for scrapers *)

open Lwt.Infix
open Re
open Logs
open Lwt_mutex

let normalize_text text =
  let text = String.lowercase_ascii (String.trim text) in
  (* Remove accents - simplified version *)
  let text = Str.global_replace (Str.regexp "á\\|à\\|ã\\|â\\|ä") "a" text in
  let text = Str.global_replace (Str.regexp "é\\|è\\|ê\\|ë") "e" text in
  let text = Str.global_replace (Str.regexp "í\\|ì\\|î\\|ï") "i" text in
  let text = Str.global_replace (Str.regexp "ó\\|ò\\|õ\\|ô\\|ö") "o" text in
  let text = Str.global_replace (Str.regexp "ú\\|ù\\|û\\|ü") "u" text in
  let text = Str.global_replace (Str.regexp "ç") "c" text in
  Str.global_replace (Str.regexp " +") "-" text

let slugify text =
  let text = String.lowercase_ascii (String.trim text) in
  String.split_on_char ' ' text
  |> List.filter (fun s -> s <> "")
  |> String.concat "-"

let parse_int_opt s =
  try Some (int_of_string s)
  with _ -> None

let parse_float_opt s =
  try Some (float_of_string s)
  with _ -> None

let format_price price =
  (* Format price as Brazilian currency string - matches Python format_price *)
  try
    (* Try to parse as float first *)
    let price_float = float_of_string price in
    let formatted = Printf.sprintf "%.2f" price_float in
    (* Replace comma with X, dot with comma, then X with dot *)
    formatted
    |> Str.global_replace (Str.regexp ",") "X"
    |> Str.global_replace (Str.regexp "\\.") ","
    |> Str.global_replace (Str.regexp "X") "."
    |> (fun s -> "R$ " ^ s)
  with _ ->
    (* If it's already a string, check if it has R$ prefix *)
    let cleaned = Str.global_replace (Str.regexp "^R\\$[ \t]*") "" price in
    if String.trim cleaned = "" then
      "Preço sob consulta"
    else
      cleaned

let format_mileage mileage =
  (* Format mileage with dots as thousands separator - matches Python format_mileage *)
  try
    (* Remove dots and commas, then convert to int *)
    let cleaned = Str.global_replace (Str.regexp "[^0-9]") "" mileage in
    if cleaned = "" then
      "0 km"
    else
      let number = int_of_string cleaned in
      (* Format with dot as thousands separator *)
      let formatted = Printf.sprintf "%d" number in
      (* Add dots as thousands separator *)
      let rec add_dots s =
        if String.length s <= 3 then s
        else
          let len = String.length s in
          let last_three = String.sub s (len - 3) 3 in
          let rest = String.sub s 0 (len - 3) in
          (add_dots rest) ^ "." ^ last_three
      in
      (add_dots formatted) ^ " km"
  with _ ->
    (* If it's already formatted like "65.000 km", return as is *)
    if String.contains mileage 'k' || String.contains mileage 'K' then
      String.trim mileage
    else
      "0 km"

(* Rate limiting per provider - track last request time per domain *)
let provider_last_request = Hashtbl.create 10
let provider_lock = Lwt_mutex.create ()

(* Get domain from URL for rate limiting *)
let get_domain url =
  try
    let uri = Uri.of_string url in
    match Uri.host uri with
    | Some host -> host
    | None -> "unknown"
  with _ -> "unknown"

(* HTTP helper with rate limiting per provider *)
let http_get ?(delay_seconds=0.1) url =
  let domain = get_domain url in
  Lwt_mutex.with_lock provider_lock (fun () ->
    (* Check last request time for this domain *)
    let last_request = try Hashtbl.find provider_last_request domain with Not_found -> 0.0 in
    let now = Unix.gettimeofday () in
    let time_since_last = now -. last_request in
    
    (* Wait if needed to respect rate limit *)
    let%lwt () = if time_since_last < delay_seconds then (
      let wait_time = delay_seconds -. time_since_last in
      Logs.debug (fun m -> m "Rate limiting: waiting %.2fs before request to %s" wait_time domain);
      Lwt_unix.sleep wait_time
    ) else
      Lwt.return_unit in
    
    (* Update last request time *)
    Hashtbl.replace provider_last_request domain (Unix.gettimeofday ());
    
    (* Make the HTTP request *)
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
        Curl.set_useragent c "Mozilla/5.0 (MVP-Scraper)";
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
          Lwt.return_ok (http_code, body)
        else
          Lwt.return_error (Printf.sprintf "HTTP %d" http_code))
      (fun exn ->
        (match !curl with Some c -> (try Curl.cleanup c with _ -> ()) | None -> ());
        Logs.err (fun m -> m "Exception in http_get for URL %s: %s" url (Printexc.to_string exn));
        Lwt.return_error (Printf.sprintf "HTTP request exception: %s" (Printexc.to_string exn)))
  )

