(* Vehicle converter - converts scraper vehicle format to API JSON format *)

open Scrapers_types
open Yojson.Safe
open Logs

let to_title value =
  match value with
  | None | Some "" -> ""
  | Some s ->
      String.split_on_char ' ' s
      |> List.map (fun part ->
          if String.length part > 0 then
            String.make 1 (Char.uppercase_ascii part.[0]) ^ String.sub part 1 (String.length part - 1)
          else
            part)
      |> String.concat " "

let normalize_brand value =
  match value with
  | None | Some "" -> ""
  | Some s -> String.trim s

let determine_condition km_value =
  match km_value with
  | None -> "used"
  | Some km_str ->
      try
        let km = int_of_string (Str.global_replace (Str.regexp "[^0-9]") "" km_str) in
        if km <= 100 then "new" else "used"
      with _ -> "used"

let convert_from_localiza vehicle =
  let brand = normalize_brand (Some vehicle.brand) in
  let model = String.trim vehicle.model in
  (* Use year_model, fallback to current year if not available *)
  let year = match vehicle.year with
    | Some y -> y
    | None -> 
        (* Default to current year if year is missing *)
        let current_year = 2024 in
        Logs.warn (fun m -> m "Year missing for vehicle %s %s, using default %d" brand model current_year);
        current_year
  in
  
  (* Use description from scraper or build one like in Python *)
  let description = match vehicle.description with
    | Some desc when desc <> "" -> desc
    | _ -> Printf.sprintf "%s %d - %s" model year vehicle.mileage
  in
  
  let images = match vehicle.image_url with
    | Some img when img <> "" -> [`String img]
    | _ -> []
  in
  
  (* Format external_id like Python: "localiza-{id}" *)
  let external_id = match vehicle.external_id with
    | Some id -> `String (Printf.sprintf "localiza-%s" id)
    | None -> `Null
  in
  
  (* Get body_style from category if available (Python uses entry.get("category")) *)
  (* Note: We don't have category in vehicle type, so we'll use Null for now *)
  let body_style = `Null in
  
  (* Apply to_title to location_city like Python *)
  let location_city = to_title vehicle.city in
  let location_city_str = if location_city = "" then "Não informado" else location_city in
  
  `Assoc [
    ("brand", `String brand);
    ("model", `String model);
    ("year", `Int year);
    ("price", `String vehicle.price);
    ("mileage", `String vehicle.mileage);
    ("fuel_type", `String (Option.value ~default:"Não informado" vehicle.fuel_type));
    ("color", `String (Option.value ~default:"Não informado" vehicle.color));
    ("transmission", `String (Option.value ~default:"Não informado" vehicle.transmission));
    ("description", `String description);
    ("image", `String (Option.value ~default:"" vehicle.image_url));
    ("images", `List images);
    ("seller_id", `Int 0);
    ("seller_name", `String "Localiza Seminovos");
    ("seller_phone", `String "");
    ("seller_email", `String "");
    ("condition", `String (determine_condition (Some vehicle.mileage)));
    ("source", `String "localiza");
    ("external_id", external_id);
    ("external_url", `String vehicle.detail_url);
    ("engine", `Null);
    ("doors", `Int 4);
    ("body_style", body_style);
    ("features", `List []);
    ("detailed_description_md", `Null);
    ("vin", `Null);
    ("license_plate", `Null);
    ("previous_owners", `Int 1);
    ("service_history", `List []);
    ("modifications", `List []);
    ("included_items", `List []);
    ("exterior_condition", `Null);
    ("interior_condition", `Null);
    ("mechanical_condition", `Null);
    ("inspection_notes", `Null);
    ("location_city", `String location_city_str);
    ("location_state", `String (Option.value ~default:"" vehicle.state));
    ("financing_available", `Bool false);
    ("trade_accepted", `Bool false);
    ("test_drive_available", `Bool false);
  ]

let convert_from_icarros vehicle =
  let brand = normalize_brand (Some vehicle.brand) in
  let model = String.trim vehicle.model in
  (* Use year_model, fallback to current year if not available *)
  let year = match vehicle.year with
    | Some y -> y
    | None -> 
        (* Default to current year if year is missing *)
        let current_year = 2024 in
        Logs.warn (fun m -> m "Year missing for vehicle %s %s, using default %d" brand model current_year);
        current_year
  in
  
  (* Use description from scraper (already includes seller info from iCarros scraper) *)
  let description = Option.value ~default:"" vehicle.description in
  
  let images = match vehicle.image_url with
    | Some img when img <> "" -> [`String img]
    | _ -> []
  in
  
  (* Format external_id like Python: "icarros-{id}" *)
  let external_id = match vehicle.external_id with
    | Some id -> `String (Printf.sprintf "icarros-%s" id)
    | None -> `Null
  in
  
  (* Apply to_title to location_city and color like Python *)
  let location_city = to_title vehicle.city in
  let location_city_str = if location_city = "" then "Não informado" else location_city in
  let color = to_title vehicle.color in
  let color_str = if color = "" then "Não informado" else color in
  
  `Assoc [
    ("brand", `String brand);
    ("model", `String model);
    ("year", `Int year);
    ("price", `String vehicle.price);
    ("mileage", `String vehicle.mileage);
    ("fuel_type", `String (Option.value ~default:"Não informado" vehicle.fuel_type));
    ("color", `String color_str);
    ("transmission", `String (Option.value ~default:"Não informado" vehicle.transmission));
    ("description", `String description);
    ("image", `String (Option.value ~default:"" vehicle.image_url));
    ("images", `List images);
    ("seller_id", `Int 0);
    ("seller_name", `String "Parceiro iCarros");
    ("seller_phone", `String "");
    ("seller_email", `String "");
    ("condition", `String (determine_condition (Some vehicle.mileage)));
    ("source", `String "icarros");
    ("external_id", external_id);
    ("external_url", `String vehicle.detail_url);
    ("engine", `Null);
    ("doors", `Int 4);
    ("body_style", `Null);
    ("features", `List []);
    ("detailed_description_md", `Null);
    ("vin", `Null);
    ("license_plate", `Null);
    ("previous_owners", `Int 1);
    ("service_history", `List []);
    ("modifications", `List []);
    ("included_items", `List []);
    ("exterior_condition", `Null);
    ("interior_condition", `Null);
    ("mechanical_condition", `Null);
    ("inspection_notes", `Null);
    ("location_city", `String location_city_str);
    ("location_state", `String (Option.value ~default:"" vehicle.state));
    ("financing_available", `Bool false);
    ("trade_accepted", `Bool false);
    ("test_drive_available", `Bool false);
  ]
