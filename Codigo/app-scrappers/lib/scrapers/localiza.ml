(* Localiza scraper *)

open Lwt.Infix
open Scrapers_types
open Common

let base_url = "https://seminovos.localiza.com"

let normalize text =
  let text = String.lowercase_ascii (String.trim text) in
  (* Remove accents and replace spaces with hyphens *)
  let text = Str.global_replace (Str.regexp "á\\|à\\|ã\\|â\\|ä") "a" text in
  let text = Str.global_replace (Str.regexp "é\\|è\\|ê\\|ë") "e" text in
  let text = Str.global_replace (Str.regexp "í\\|ì\\|î\\|ï") "i" text in
  let text = Str.global_replace (Str.regexp "ó\\|ò\\|õ\\|ô\\|ö") "o" text in
  let text = Str.global_replace (Str.regexp "ú\\|ù\\|û\\|ü") "u" text in
  let text = Str.global_replace (Str.regexp "ç") "c" text in
  Str.global_replace (Str.regexp " +") "-" text

let extract_products_from_html html =
  try
    (* Find __NEXT_DATA__ script tag - handle multiline content *)
    let next_data_start_regex = Str.regexp {|<script id="__NEXT_DATA__"[^>]*>|} in
    let next_data_end_regex = Str.regexp {|</script>|} in
    let start_pos = try
      ignore (Str.search_forward next_data_start_regex html 0);
      Str.match_end ()
    with Not_found -> -1 in
    
    if start_pos >= 0 then (
      let end_pos = try
        ignore (Str.search_forward next_data_end_regex html start_pos);
        Str.match_beginning ()
      with Not_found -> -1 in
      
      if end_pos > start_pos then (
        let json_str = String.sub html start_pos (end_pos - start_pos) in
        let json = Yojson.Safe.from_string json_str in
        
        (* Navigate to props.pageProps.products *)
        let products = Yojson.Safe.Util.(
          json
          |> member "props"
          |> member "pageProps"
          |> member "products"
          |> to_list
        ) in
        
        (* Get total pages from _metadados *)
        let total_pages = try
          Yojson.Safe.Util.(
            json
            |> member "props"
            |> member "pageProps"
            |> member "_metadados"
            |> member "_totalPaginas"
            |> to_int_option
          ) |> Option.value ~default:1
        with _ -> 1 in
        
        Ok (products, total_pages)
      ) else (
        Logs.err (fun m -> m "Could not find end of __NEXT_DATA__ script tag");
        Error "Could not find end of __NEXT_DATA__"
      )
    ) else (
      Logs.err (fun m -> m "Could not find __NEXT_DATA__ in HTML");
      Error "Could not find __NEXT_DATA__"
    )
  with
  | exn ->
      Logs.err (fun m -> m "Exception extracting products: %s" (Printexc.to_string exn));
      Error (Printexc.to_string exn)

(* Helper to convert JSON value to string (handles both string and int) *)
let json_to_string json =
  match json with
  | `String s -> s
  | `Int i -> string_of_int i
  | `Float f -> string_of_float f
  | _ -> Yojson.Safe.Util.to_string json

let normalize_product json =
  let open Yojson.Safe.Util in
  try
    let id = json |> member "id" |> json_to_string in
    let brand = json |> member "marcaDescricao" |> json_to_string in
    let model_family = json |> member "modeloFamiliaDescricao" |> json_to_string in
    let model = json |> member "modeloDescricaoReduzida" |> json_to_string in
    let year_model = json |> member "anoModelo" |> to_int_option in
    let year_fabrication = json |> member "anoFabricacao" |> to_int_option in
    let km = json |> member "odometro" |> json_to_string in
    let price = json |> member "preco" |> json_to_string in
    let city = json |> member "cidadeDescricao" |> to_string_option in
    let state = json |> member "siglaEstado" |> to_string_option in
    let category = json |> member "categoriaDescricao" |> to_string_option in
    let transmission = json |> member "tipoTransmissaoDescricao" |> to_string_option in
    let fuel = json |> member "tipoCombustivelDescricao" |> to_string_option in
    let image_url = json |> member "fotoUrl" |> to_string_option in
    let detail_url = json |> member "pdpUrl" |> json_to_string in
    
    (* Try to get color from various fields *)
    let color = try
      Some (json |> member "corDescricao" |> to_string)
    with _ -> try
      Some (json |> member "corExternaDescricao" |> to_string)
    with _ -> try
      Some (json |> member "corExternaDescricaoReduzida" |> to_string)
    with _ -> try
      Some (json |> member "cor" |> to_string)
    with _ -> None in
    
    (* Build detail URL if relative *)
    let detail_url = if String.length detail_url > 0 && detail_url.[0] = '/' then
      base_url ^ detail_url
    else
      detail_url in
    
    (* Combine model_family and model like in Python *)
    let full_model = Printf.sprintf "%s %s" model_family model |> String.trim in
    
    (* Build description like in Python import-to-api.py *)
    let description = Printf.sprintf "%s %s %s/%s - %s - categoria %s"
      model_family model
      (match year_model with Some y -> string_of_int y | None -> "N/A")
      (match year_fabrication with Some y -> string_of_int y | None -> "N/A")
      (format_mileage km)
      (Option.value ~default:"N/D" category)
    in
    
    Ok {
      brand;
      model = full_model;
      year = year_model;
      price = format_price price;
      mileage = format_mileage km;
      city;
      state;
      fuel_type = fuel;
      transmission;
      color;
      image_url;
      detail_url;
      source = "localiza";
      external_id = Some id;
      description = Some description;
    }
  with
  | exn ->
      Logs.err (fun m -> m "Exception normalizing product: %s" (Printexc.to_string exn));
      Error (Printexc.to_string exn)

let fetch_page brand_slug model_slug page =
  let url = if page = 1 then
    Printf.sprintf "%s/carros/%s/%s" base_url brand_slug model_slug
  else
    Printf.sprintf "%s/carros/%s/%s?page=%d" base_url brand_slug model_slug page
  in
  
  Logs.info (fun m -> m "Fetching Localiza page: %s" url);
  
  Common.http_get url >>= function
  | Error msg -> Lwt.return_error msg
  | Ok (200, html) ->
      (match extract_products_from_html html with
      | Ok (products_json, total_pages) ->
          let vehicles = List.fold_left (fun acc product_json ->
            match normalize_product product_json with
            | Ok vehicle -> vehicle :: acc
            | Error _ -> acc
          ) [] products_json in
          Lwt.return_ok (vehicles, total_pages)
      | Error msg -> Lwt.return_error msg)
  | Ok (404, _) ->
      Logs.info (fun m -> m "Page not found (404), stopping pagination");
      Lwt.return_ok ([], 0)
  | Ok (code, _) ->
      Logs.err (fun m -> m "HTTP error %d" code);
      Lwt.return_error (Printf.sprintf "HTTP %d" code)

(* Helper functions for list batching *)
let rec take n = function
  | [] -> []
  | x :: xs when n > 0 -> x :: take (n - 1) xs
  | _ -> []

let rec drop n = function
  | [] -> []
  | xs when n <= 0 -> xs
  | _ :: xs -> drop (n - 1) xs

let scrape brand model =
  Logs.info (fun m -> m "Starting Localiza scrape for %s %s" brand model);
  
  let brand_slug = normalize brand in
  let model_slug = normalize model in
  
  (* Fetch first page *)
  let%lwt first_page_result = fetch_page brand_slug model_slug 1 in
  
  match first_page_result with
  | Error msg -> Lwt.return_error msg
  | Ok (vehicles, total_pages) ->
      let all_vehicles = ref vehicles in
      
      (* Fetch remaining pages in parallel batches for better performance *)
      let%lwt () = if total_pages <= 1 then
        Lwt.return_unit
      else (
        (* Create list of page numbers to fetch *)
        let pages_to_fetch = List.init (total_pages - 1) (fun i -> i + 2) in
        
        (* Process pages in parallel batches of 5 *)
        let rec process_batch remaining =
          match remaining with
          | [] -> Lwt.return_unit
          | batch ->
              let batch_list = if List.length remaining > 5 then
                take 5 remaining
              else
                remaining
              in
              let rest = if List.length remaining > 5 then
                drop 5 remaining
              else
                []
              in
              (* Fetch all pages in this batch in parallel *)
              let%lwt results = Lwt_list.map_p (fun page ->
                Lwt.catch
                  (fun () -> fetch_page brand_slug model_slug page)
                  (fun exn ->
                    Logs.err (fun m -> m "Error fetching Localiza page %d: %s" page (Printexc.to_string exn));
                    Lwt.return_ok ([], 0))
              ) batch_list in
              
              (* Collect vehicles from successful fetches *)
              List.iter (function
                | Ok (page_vehicles, _) -> all_vehicles := page_vehicles @ !all_vehicles
                | Error _ -> ()
              ) results;
              
              (* Small delay between batches *)
              let%lwt () = if List.length rest > 0 then Lwt_unix.sleep 0.1 else Lwt.return_unit in
              process_batch rest
        in
        process_batch pages_to_fetch
      ) in
      
      Logs.info (fun m -> m "Scraped %d vehicles from Localiza" (List.length !all_vehicles));
      Lwt.return_ok (List.rev !all_vehicles)

