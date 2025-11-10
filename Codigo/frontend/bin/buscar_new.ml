open Dream
open Lwt.Infix
module Templates = Buscar_lib.Templates
open Buscar_lib.Types
module Api = Buscar_lib.Api_client

(* Initialize random seed *)
let () = Random.self_init ()

(* Setup logging *)
let () =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Info);
  Logs.info (fun m -> m "🚗 BusCars Frontend starting - Backend API: %s" 
    (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000"))

(* Theme helper function *)
let _get_theme_from_request request =
  match Dream.cookie request "theme" with
  | Some theme when theme = "dark" || theme = "light" -> theme
  | _ -> "light"

(* External platform vehicles - for redirects only *)
let external_vehicles = [
  {
    id = 100; slug = "bmw-x5-external"; brand = "BMW"; model = "X5"; year = 2023; price = "320.000"; mileage = "8.000"; fuel_type = "Gasolina"; color = "Preto"; transmission = "Automática"; description = "BMW X5 xDrive 2023"; image = "https://placehold.co/600x400/1a202c/10b981?text=BMW+X5"; images = []; seller_id = 0; seller_name = "João Oliveira"; seller_phone = "(11) 77777-7777"; seller_email = ""; condition = "new"; source = "localiza"; engine = "3.0L I6 Turbo"; doors = 4; body_style = "SUV"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 1; service_history = []; modifications = []; included_items = []; exterior_condition = "Excelente"; interior_condition = "Excelente"; mechanical_condition = "Excelente"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false; created_at = ""; updated_at = ""; is_active = true; views_count = 0; favorites_count = 0;
  };
]

let sample_user = {
  user_id = 1;
  name = "João Silva";
  email = "joao@email.com";
}

(* Helper functions *)
let find_vehicle_by_id id vehicles =
  List.find_opt (fun vehicle -> vehicle.id = id) vehicles

let find_vehicle_by_slug slug vehicles =
  List.find_opt (fun vehicle -> vehicle.slug = slug) vehicles

let filter_vehicles ?brand ?model ?year_min ?price_max ?fuel_type ?condition ?source () vehicles =
  List.filter (fun v ->
    let brand_match = match brand with
      | Some b when b <> "" -> String.equal v.brand b
      | _ -> true
    in
    let model_match = match model with
      | Some m when m <> "" -> String.equal v.model m
      | _ -> true
    in
    let year_match = match year_min with
      | Some y -> v.year >= y
      | None -> true
    in
    let price_match = match price_max with
      | Some p -> 
        (try
          let vehicle_price = int_of_string (String.map (fun c -> if c = '.' then ' ' else c) v.price |> 
                                            String.split_on_char ' ' |> String.concat "") in
          vehicle_price <= p
        with _ -> true)
      | None -> true
    in
    let fuel_match = match fuel_type with
      | Some f when f <> "" -> String.equal v.fuel_type f
      | _ -> true
    in
    let condition_match = match condition with
      | Some c when c <> "" -> String.equal v.condition c
      | _ -> true
    in
    let source_match = match source with
      | Some s when s <> "" -> String.equal v.source s
      | _ -> true
    in
    brand_match && model_match && year_match && price_match && fuel_match && condition_match && source_match
  ) vehicles

(* Route handlers *)
let home_handler _request =
  let content = Templates.home_template () in
  html content

let vehicles_handler request =
  let brand = query request "brand" in
  let model = query request "model" in
  let condition = query request "condition" in
  let source = query request "source" in
  let page = 
    match query request "page" with
    | Some p when p <> "" -> int_of_string p
    | _ -> 1
  in
  let year_min = 
    match query request "year_min" with
    | Some y when y <> "" -> Some (int_of_string y)
    | _ -> None
  in
  let price_max = 
    match query request "price_max" with
    | Some p when p <> "" -> Some (int_of_string p)
    | _ -> None
  in
  let fuel_type = query request "fuel_type" in
  let sort_by = query request "sort" in
  
  (* Fetch from backend API *)
  Api.fetch_vehicles ?brand ?model ?condition ?source ~page () >>= fun backend_vehicles ->
  
  (* Combine with external vehicles *)
  let all_vehicles = backend_vehicles @ external_vehicles in
  let filtered_vehicles = filter_vehicles ?brand ?model ?year_min ?price_max ?fuel_type ?condition ?source () all_vehicles in
  
  (* Apply sorting *)
  let sorted_vehicles = match sort_by with
    | Some "price_asc" -> List.sort (fun a b -> 
        let parse_price s = 
          s |> String.split_on_char '.' |> String.concat "" |> int_of_string
        in
        compare (parse_price a.price) (parse_price b.price)) filtered_vehicles
    | Some "price_desc" -> List.sort (fun a b -> 
        let parse_price s = 
          s |> String.split_on_char '.' |> String.concat "" |> int_of_string
        in
        compare (parse_price b.price) (parse_price a.price)) filtered_vehicles
    | Some "year_desc" -> List.sort (fun a b -> compare b.year a.year) filtered_vehicles
    | Some "mileage_asc" -> List.sort (fun a b ->
        let parse_mileage s = 
          s |> String.split_on_char '.' |> String.concat "" |> int_of_string
        in
        compare (parse_mileage a.mileage) (parse_mileage b.mileage)) filtered_vehicles
    | _ -> filtered_vehicles
  in
  
  (* Pagination logic *)
  let items_per_page = 5 in
  let total_count = List.length sorted_vehicles in
  let total_pages = max 1 ((total_count + items_per_page - 1) / items_per_page) in
  let safe_page = max 1 (min page total_pages) in
  let start_index = (safe_page - 1) * items_per_page in
  let end_index = min (start_index + items_per_page) total_count in
  
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
  
  let paginated_vehicles = sorted_vehicles |> drop start_index |> take items_per_page in
  
  let content = Templates.vehicle_listing_template ~vehicles:paginated_vehicles ~page:safe_page ~total_pages ~total_count ~start_index ~end_index () in
  html content

(* Vehicle detail handler - fetch from backend *)
let vehicle_slug_handler request =
  match param request "slug" with
  | slug ->
    (* Fetch from backend API *)
    Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
    
    let vehicle = match vehicle_opt with
      | Some v -> Some v
      | None -> find_vehicle_by_slug slug external_vehicles
    in
    
    (match vehicle with
     | Some vehicle -> 
       if vehicle.source = "buscar" then
         let return_url = 
           match query request "return" with
           | Some url -> url
           | None -> "/vehicles"
         in
         let content = Templates.vehicle_detail_template ~vehicle ~return_url () in
         html content
       else
         (* Redirect external listings *)
         let external_redirect_urls = [
           ("webmotors", "https://www.webmotors.com.br/carros/estoque/?aff=buscar&utm_source=buscars");
           ("localiza", "https://www.localizaseminovos.com.br/veiculos/?aff=buscar&utm_source=buscars");  
           ("icarros", "https://www.icarros.com.br/carros/?aff=buscar&utm_source=buscars");
           ("bringatrailer", "https://bringatrailer.com/listing/1957-porsche-356a-speedster-43/?aff=buscar&utm_source=buscars");
         ] in
         let redirect_url = try List.assoc vehicle.source external_redirect_urls 
                           with Not_found -> "https://www.webmotors.com.br/?aff=buscar&utm_source=buscars" in
         let content = Templates.advertisement_with_redirect ~redirect_url ~source:vehicle.source () in
         html content
     | None -> 
       respond ~status:`Not_Found "Veículo não encontrado")

let search_handler request =
  form request >>= fun form_result ->
  match form_result with
  | `Ok form_data ->
    let brand = List.assoc_opt "brand" form_data in
    let model = List.assoc_opt "model" form_data in
    let condition = List.assoc_opt "condition" form_data in
    
    let should_show_ad = Random.int 100 < 30 in
    
    let query_params = 
      let params = [] in
      let params = match brand with
        | Some b when b <> "" -> ("brand", b) :: params
        | _ -> params
      in
      let params = match model with
        | Some m when m <> "" -> ("model", m) :: params
        | _ -> params
      in
      let params = match condition with
        | Some c when c <> "" -> ("condition", c) :: params
        | _ -> params
      in
      params
    in
    let query_string = 
      String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ v) query_params)
    in
    let target_url = "/vehicles" ^ (if query_string <> "" then "?" ^ query_string else "") in
    
    if should_show_ad then
      let external_urls = [
        ("webmotors", "https://www.webmotors.com.br/carros/estoque/?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&modelo=" ^ (match model with Some m -> m | None -> "") ^ "&aff=buscar&utm_source=buscars");
        ("localiza", "https://www.localizaseminovos.com.br/comprar/carros?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&aff=buscar&utm_source=buscars");
        ("icarros", "https://www.icarros.com.br/carros/?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&aff=buscar&utm_source=buscars");
      ] in
      
      let platform_sources = ["webmotors"; "localiza"; "icarros"] in
      let random_source = List.nth platform_sources (Random.int (List.length platform_sources)) in
      let redirect_url = List.assoc random_source external_urls in
      
      let content = Templates.advertisement_with_redirect ~redirect_url ~source:random_source () in
      html content
    else
      redirect request target_url
  | _ -> redirect request "/vehicles"

let login_handler request =
  form request >>= fun form_result ->
  match form_result with
  | `Ok form_data ->
    let email = List.assoc_opt "email" form_data in
    let password = List.assoc_opt "password" form_data in
    (match email, password with
     | Some email_val, Some pass_val ->
       (* Use backend API authentication *)
       Api.login email_val pass_val >>= (function
       | Ok (Some session_id) ->
           Dream.set_session_field request "user_id" "1" >>= fun () ->
           Dream.set_session_field request "backend_session" session_id >>= fun () ->
           Logs.info (fun m -> m "✅ User logged in via backend API");
           redirect request "/dashboard"
       | Ok None ->
           Dream.set_session_field request "user_id" "1" >>= fun () ->
           redirect request "/dashboard"
       | Error msg ->
           Logs.warn (fun m -> m "❌ Login failed: %s" msg);
           let content = Templates.login_template ~error:msg () in
           html content)
     | _ ->
       let content = Templates.login_template ~error:"E-mail ou senha incorretos" () in
       html content)
  | _ ->
    let content = Templates.login_template () in
    html content

let login_get_handler _request =
  let content = Templates.login_template () in
  html content

let dashboard_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    (* Fetch vehicles from backend *)
    Api.fetch_vehicles ~source:"buscar" () >>= fun user_vehicles ->
    Logs.info (fun m -> m "📊 Dashboard loaded with %d vehicles from backend" (List.length user_vehicles));
    let content = Templates.dashboard_template ~user:sample_user ~vehicles:user_vehicles () in
    html content
  | None -> redirect request "/login"

let logout_handler request =
  Dream.invalidate_session request >>= fun () ->
  redirect request "/"

let external_redirect_handler request =
  let source = param request "source" in
  
  let external_urls = [
    ("webmotors", "https://www.webmotors.com.br/carros/estoque/?estadocidade=&marca=&modelo=&anoate=&anomin=&preco=&tipoveiculo=carros&aff=buscar&utm_source=buscars");
    ("localiza", "https://www.localizaseminovos.com.br/veiculos/?aff=buscar&utm_source=buscars");
    ("icarros", "https://www.icarros.com.br/carros/index.jsp?aff=buscar&utm_source=buscars");
    ("bringatrailer", "https://bringatrailer.com/auctions/?aff=buscar&utm_source=buscars");
  ] in
  
  let redirect_url = 
    try 
      List.assoc source external_urls
    with Not_found -> 
      "https://www.webmotors.com.br/?aff=buscar&utm_source=buscars"
  in
  
  let content = Templates.advertisement_with_redirect ~redirect_url ~source () in
  html content

let add_vehicle_get_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    let content = Templates.add_vehicle_template () in
    html content
  | None -> redirect request "/login"

let add_vehicle_post_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    (form request >>= fun form_result ->
     match form_result with
     | `Ok form_data ->
       let brand = List.assoc_opt "brand" form_data |> Option.value ~default:"" in
       let model = List.assoc_opt "model" form_data |> Option.value ~default:"" in
       if brand <> "" && model <> "" then
         redirect request "/dashboard"
       else
         let content = Templates.add_vehicle_template ~error:"Todos os campos são obrigatórios" () in
         html content
     | _ ->
       let content = Templates.add_vehicle_template ~error:"Erro no formulário" () in
       html content)
  | None -> redirect request "/login"

let logo_handler _request =
  let ic = open_in_bin "./static/logo-buscar.png" in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  respond ~headers:[("Content-Type", "image/png")] content

(* Main application *)
let () =
  run ~interface:"0.0.0.0" ~port:8080
  @@ logger
  @@ Dream.memory_sessions
  @@ router [
    get "/" home_handler;
    get "/vehicles" vehicles_handler;
    get "/vehicle/:slug" vehicle_slug_handler;
    post "/search" search_handler;
    get "/login" login_get_handler;
    post "/login" login_handler;
    get "/logout" logout_handler;
    get "/dashboard" dashboard_handler;
    get "/dashboard/add-vehicle" add_vehicle_get_handler;
    post "/dashboard/add-vehicle" add_vehicle_post_handler;
    get "/redirect/:source" external_redirect_handler;
    get "/logo-buscar.png" logo_handler;
    get "/favicon.ico" (fun _request -> respond ~headers:[("Content-Type", "image/x-icon")] "");
  ]

