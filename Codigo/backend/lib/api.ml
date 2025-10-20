(* REST API handlers for BusCar backend *)
open Lwt.Syntax
open Simple_types

(* CORS headers for frontend *)
let cors_headers = [
  ("Access-Control-Allow-Origin", "*");
  ("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  ("Access-Control-Allow-Headers", "Content-Type, Authorization");
]

(* JSON response helper *)
let json_response ?(status=`OK) ?(headers=[]) json =
  Dream.json ~status ~headers:(cors_headers @ headers) (Yojson.Safe.to_string json)

(* Error response helper *)
let error_response ?(status=`Bad_Request) message =
  let response_json = `Assoc [
    ("success", `Bool false);
    ("message", `String message);
    ("data", `Null);
  ] in
  json_response ~status response_json

(* Success response helper *)
let success_response ?(data=`Null) message =
  let response_json = `Assoc [
    ("success", `Bool true);
    ("message", `String message);
    ("data", data);
  ] in
  json_response response_json

(* Parse query parameters with defaults *)
let get_int_param request param default_val =
  match Dream.query request param with
  | Some s -> (try int_of_string s with _ -> default_val)
  | None -> default_val

let get_string_param request param =
  Dream.query request param

(* Parse vehicle filters from request *)
let parse_filters request =
  {
    brand = get_string_param request "brand";
    model = get_string_param request "model";
    year_min = (match get_string_param request "year_min" with Some s -> Some (int_of_string s) | None -> None);
    price_max = (match get_string_param request "price_max" with Some s -> Some (int_of_string s) | None -> None);
    fuel_type = get_string_param request "fuel_type";
    condition = get_string_param request "condition";
    source = get_string_param request "source";
    location_state = get_string_param request "location_state";
    page = get_int_param request "page" 1;
    limit = get_int_param request "limit" 10;
    sort_by = get_string_param request "sort";
  }

(* Filter and sort vehicles *)
let apply_filters_and_sort (vehicles : Simple_types.vehicle list) filters =
  (* Apply filters *)
  let filtered = 
    vehicles
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.brand with 
        | Some b when b <> "" -> String.equal v.brand b 
        | _ -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.model with 
        | Some m when m <> "" -> String.equal v.model m 
        | _ -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.year_min with 
        | Some min_year -> v.year >= min_year 
        | None -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.fuel_type with 
        | Some ft when ft <> "" -> String.equal v.fuel_type ft 
        | _ -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.condition with 
        | Some c when c <> "" -> String.equal v.condition c
        | _ -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.source with 
        | Some s when s <> "" -> String.equal v.source s
        | _ -> true)
    |> List.filter (fun (v : Simple_types.vehicle) -> 
        match filters.location_state with 
        | Some state when state <> "" -> String.equal v.location_state state 
        | _ -> true)
  in
  
  (* Apply sorting *)
  let sorted = match filters.sort_by with
    | Some "price_asc" -> List.sort (fun (a : Simple_types.vehicle) (b : Simple_types.vehicle) -> 
        let parse_price s = s |> String.split_on_char '.' |> String.concat "" |> int_of_string in
        compare (parse_price a.price) (parse_price b.price)) filtered
    | Some "price_desc" -> List.sort (fun a b -> 
        let parse_price s = s |> String.split_on_char '.' |> String.concat "" |> int_of_string in
        compare (parse_price b.price) (parse_price a.price)) filtered
    | Some "year_desc" -> List.sort (fun a b -> compare b.year a.year) filtered
    | Some "mileage_asc" -> List.sort (fun a b ->
        let parse_mileage s = s |> String.split_on_char '.' |> String.concat "" |> int_of_string in
        compare (parse_mileage a.mileage) (parse_mileage b.mileage)) filtered
    | _ -> filtered (* relevance - keep original order *)
  in
  sorted

(* Paginate vehicles *)
let paginate vehicles page limit =
  let total_count = List.length vehicles in
  let total_pages = max 1 ((total_count + limit - 1) / limit) in
  let safe_page = max 1 (min page total_pages) in
  let start_index = (safe_page - 1) * limit in
  
  let rec take n lst =
    match n, lst with
    | 0, _ | _, [] -> []
    | n, h :: t -> h :: take (n - 1) t
  in
  
  let rec drop n lst =
    match n, lst with
    | 0, _ -> lst
    | _, [] -> []
    | n, _ :: t -> drop (n - 1) t
  in
  
  let paginated = vehicles |> drop start_index |> take limit in
  (paginated, total_count, safe_page, total_pages)

(* API Handlers *)

(* GET /api/vehicles - List vehicles with filtering and pagination *)
let vehicles_list_handler request =
  let* vehicles_result = Mock_data.get_all_vehicles () in
  match vehicles_result with
  | Error err -> error_response ~status:`Internal_Server_Error err
  | Ok vehicles ->
    let filters = parse_filters request in
    let filtered_and_sorted = apply_filters_and_sort vehicles filters in
    let (paginated_vehicles, total_count, page, total_pages) = 
      paginate filtered_and_sorted filters.page filters.limit in
    
    
    let vehicle_to_json (v : Simple_types.vehicle) = `Assoc [
      ("id", `Int v.id);
      ("slug", `String v.slug);
      ("brand", `String v.brand);
      ("model", `String v.model);
      ("year", `Int v.year);
      ("price", `String v.price);
      ("mileage", `String v.mileage);
      ("fuel_type", `String v.fuel_type);
      ("color", `String v.color);
      ("transmission", `String v.transmission);
      ("description", `String v.description);
      ("image", `String v.image);
      ("seller_name", `String v.seller_name);
      ("seller_phone", `String v.seller_phone);
      ("seller_email", `String v.seller_email);
      ("condition", `String v.condition);
      ("source", `String v.source);
      ("engine", `String v.engine);
      ("doors", `Int v.doors);
      ("body_style", `String v.body_style);
      ("location_city", `String v.location_city);
      ("location_state", `String v.location_state);
      ("detailed_description_md", `String v.detailed_description_md);
      ("financing_available", `Bool v.financing_available);
      ("trade_accepted", `Bool v.trade_accepted);
      ("test_drive_available", `Bool v.test_drive_available);
    ] in
    let response_json = `Assoc [
      ("vehicles", `List (List.map vehicle_to_json paginated_vehicles));
      ("total_count", `Int total_count);
      ("page", `Int page);
      ("total_pages", `Int total_pages);
    ] in
    json_response response_json

(* GET /api/vehicles/:slug - Get single vehicle *)
let vehicle_detail_handler request =
  let slug = Dream.param request "slug" in
  let* vehicle_result = Mock_data.get_vehicle_by_slug slug in
  match vehicle_result with
  | Error err -> error_response ~status:`Internal_Server_Error err
  | Ok (Some vehicle) -> json_response (`Assoc [
      ("id", `Int vehicle.id);
      ("slug", `String vehicle.slug);
      ("brand", `String vehicle.brand);
      ("model", `String vehicle.model);
      ("year", `Int vehicle.year);
      ("price", `String vehicle.price);
      ("mileage", `String vehicle.mileage);
      ("fuel_type", `String vehicle.fuel_type);
      ("color", `String vehicle.color);
      ("transmission", `String vehicle.transmission);
      ("description", `String vehicle.description);
      ("image", `String vehicle.image);
      ("seller_name", `String vehicle.seller_name);
      ("seller_phone", `String vehicle.seller_phone);
      ("seller_email", `String vehicle.seller_email);
      ("condition", `String vehicle.condition);
      ("source", `String vehicle.source);
      ("engine", `String vehicle.engine);
      ("doors", `Int vehicle.doors);
      ("body_style", `String vehicle.body_style);
      ("location_city", `String vehicle.location_city);
      ("location_state", `String vehicle.location_state);
      ("detailed_description_md", `String vehicle.detailed_description_md);
      ("financing_available", `Bool vehicle.financing_available);
      ("trade_accepted", `Bool vehicle.trade_accepted);
      ("test_drive_available", `Bool vehicle.test_drive_available);
    ])
  | Ok None -> error_response ~status:`Not_Found "Vehicle not found"

(* GET /api/health - Health check *)
let health_handler _request =
  let response_json = `Assoc [
    ("success", `Bool true);
    ("message", `String "BusCar API is healthy");
    ("data", `Null);
  ] in
  json_response response_json

(* OPTIONS handler for CORS *)
let options_handler _request =
  Lwt.return (Dream.response ~headers:cors_headers "")

(* API Routes *)
let api_routes = [
  Dream.get "/api/health" health_handler;
  Dream.get "/api/vehicles" vehicles_list_handler;
  Dream.get "/api/vehicles/:slug" vehicle_detail_handler;
  Dream.options "/**" options_handler;
]
