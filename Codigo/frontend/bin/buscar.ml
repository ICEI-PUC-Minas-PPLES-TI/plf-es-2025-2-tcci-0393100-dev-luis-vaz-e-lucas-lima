open Dream
open Lwt.Infix
module Types = Buscar_lib.Types
open Types
module Templates = Buscar_lib.Templates
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

(* NO MORE LOCAL VEHICLES - ALL data comes from backend database now *)
(* Backend stores both internal (source='buscar') and external (source='webmotors', etc.) vehicles *)
(* External vehicles will be populated by future scraper agent *)

(* Helper to get user from session *)
let get_user_from_session request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      (Api.get_current_user ~session:session_id () >>= function
       | Some user -> Lwt.return_some user
       | None -> Lwt.return_none)
  | None -> Lwt.return_none

(* Route handlers *)
let home_handler request =
  get_user_from_session request >>= fun user_opt ->
  Api.fetch_fipe_brands () >>= fun fipe_brands ->
  let home_content = Templates.home_template ~brands:fipe_brands () in
  html (Templates.base_template ~user:user_opt ~title:"BusCars - Encontre seu carro ideal" ~content:home_content)

let vehicles_handler request =
  let parse_int name =
    match query request name with
    | Some value when value <> "" -> (try Some (int_of_string value) with _ -> None)
    | _ -> None
  in
  let brand = query request "brand" in
  let model = query request "model" in
  let condition = query request "condition" in
  let source = query request "source" in
  let fuel_type = query request "fuel_type" in
  let location_state = query request "location_state" in
  let location_city = query request "location_city" in
  let year_min = parse_int "year_min" in
  let year_max = parse_int "year_max" in
  let price_min = parse_int "price_min" in
  let price_max = parse_int "price_max" in
  let sort_by = query request "sort" in
  let page = 
    match parse_int "page" with
    | Some p when p > 0 -> p
    | _ -> 1
  in
  let per_page =
    match parse_int "per_page" with
    | Some p when p > 0 -> min p 24
    | _ -> 12
  in

  Api.fetch_vehicles
    ?brand ?model ?condition ?source ?fuel_type ?location_state ?location_city
    ?year_min ?year_max ?price_min ?price_max ?sort:sort_by
    ~page ~per_page ()
  >>= fun page_data ->
  Api.fetch_fipe_brands () >>= fun fipe_brands ->
  let normalized_brand =
    match brand with
    | Some b when b <> "" -> Some b
    | _ -> None
  in
  let normalized_model =
    match model with
    | Some m when m <> "" -> Some m
    | _ -> None
  in
  (* Use brand name directly for DB models (not FIPE code) *)
  let selected_brand_name = normalized_brand in
  (match selected_brand_name with
   | Some brand_name -> Api.fetch_db_models brand_name
   | None -> Lwt.return []) >>= fun fipe_models ->
  let start_index =
    if page_data.total_count = 0 then 0 else (page_data.page - 1) * per_page
  in
  let end_index = min (start_index + List.length page_data.vehicles) page_data.total_count in
  get_user_from_session request >>= fun user_opt ->
  let listing_content = Templates.vehicle_listing_template
      ~vehicles:page_data.vehicles
      ~page:page_data.page
      ~total_pages:page_data.total_pages
      ~total_count:page_data.total_count
      ~start_index
      ~end_index
      ~per_page
      ~brands:fipe_brands
      ~models:fipe_models
      ~selected_brand:normalized_brand
      ~selected_model:normalized_model
      () in
  html (Templates.base_template ~user:user_opt ~title:"BusCars - Catálogo de Veículos" ~content:listing_content)



(* Vehicle detail handler - fetch from backend *)
let vehicle_slug_handler request =
  let slug = param request "slug" in
  (* Fetch from backend API - handles both internal and external vehicles *)
  Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
  
  match vehicle_opt with
  | Some vehicle -> 
    if vehicle.source = "buscar" then
      let return_url = 
        match query request "return" with
        | Some url -> url
        | None -> "/vehicles"
      in
      get_user_from_session request >>= fun user_opt ->
      let detail_content = Templates.vehicle_detail_template ~vehicle ~return_url () in
      html (Templates.base_template ~user:user_opt 
            ~title:("BusCars Premium - " ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year)
            ~content:detail_content)
    else
      (* All external sources show countdown page first *)
      get_user_from_session request >>= fun user_opt ->
      let redirect_content = Templates.advertisement_redirect_page ~slug:vehicle.slug ~source:vehicle.source () in
      html (Templates.base_template ~user:user_opt ~title:"BusCars - Redirecionando..." ~content:redirect_content)
  | None -> 
    respond ~status:`Not_Found "Veículo não encontrado"

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
      let platform_sources = ["webmotors"; "localiza"; "icarros"] in
      let random_source = List.nth platform_sources (Random.int (List.length platform_sources)) in
      (* For random redirects, we don't have a specific vehicle slug, so use a generic slug *)
      (* This is a fallback case - normally we'd have a vehicle slug *)
      let fallback_slug = "redirect-" ^ random_source in
      
      get_user_from_session request >>= fun user_opt ->
      let redirect_content = Templates.advertisement_redirect_page ~slug:fallback_slug ~source:random_source () in
      html (Templates.base_template ~user:user_opt ~title:"BusCars - Redirecionando..." ~content:redirect_content)
    else
      redirect request target_url
  | _ -> redirect request "/vehicles"

let login_handler request =
  Dream.body request >>= fun body ->
  (* Parse form data manually to avoid CSRF issues *)
  let form_data = Dream.from_form_urlencoded body in
  let email = List.assoc_opt "email" form_data in
  let password = List.assoc_opt "password" form_data in
  (match email, password with
   | Some email_val, Some pass_val ->
     (* Use backend API authentication *)
     Api.login email_val pass_val >>= (function
     | Ok (Some session_id) ->
         (* Get user info to store user_id *)
         Api.get_current_user ~session:session_id () >>= (function
         | Some user ->
             Dream.set_session_field request "user_id" (string_of_int user.user_id) >>= fun () ->
             Dream.set_session_field request "backend_session" session_id >>= fun () ->
             Logs.info (fun m -> m "✅ User logged in via backend API");
             redirect request "/dashboard"
         | None ->
             Logs.warn (fun m -> m "❌ Failed to get user info after login");
             let login_content = Templates.login_template ~error:"Erro ao recuperar informações do usuário" () in
             html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Login" ~content:login_content))
     | Ok None ->
         Logs.warn (fun m -> m "❌ Login returned no session");
         let login_content = Templates.login_template ~error:"Erro no login" () in
         html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Login" ~content:login_content)
     | Error msg ->
         Logs.warn (fun m -> m "❌ Login failed: %s" msg);
         let login_content = Templates.login_template ~error:msg () in
         html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Login" ~content:login_content))
   | _ ->
     let login_content = Templates.login_template ~error:"E-mail ou senha incorretos" () in
     html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Login" ~content:login_content))

let login_get_handler request =
  get_user_from_session request >>= fun user_opt ->
  (match user_opt with
   | Some _ -> redirect request "/dashboard"
   | None ->
       let content = Templates.login_template () in
       html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Login" ~content))

let register_get_handler request =
  get_user_from_session request >>= fun user_opt ->
  (match user_opt with
   | Some _ -> redirect request "/dashboard"
   | None ->
       let content = Templates.register_template () in
       html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Cadastro" ~content))

let register_handler request =
  Dream.body request >>= fun body ->
  (* Parse form data manually to avoid CSRF issues *)
  let form_data = Dream.from_form_urlencoded body in
  let name = List.assoc_opt "name" form_data |> Option.value ~default:"" in
  let email = List.assoc_opt "email" form_data |> Option.value ~default:"" in
  let password = List.assoc_opt "password" form_data |> Option.value ~default:"" in
  let phone = List.assoc_opt "phone" form_data |> Option.value ~default:"" in
  let document_number = List.assoc_opt "document_number" form_data |> Option.value ~default:"" in
  let address_street = List.assoc_opt "address_street" form_data |> Option.value ~default:"" in
  let address_number = List.assoc_opt "address_number" form_data |> Option.value ~default:"" in
  let address_complement = List.assoc_opt "address_complement" form_data in
  let address_neighborhood = List.assoc_opt "address_neighborhood" form_data |> Option.value ~default:"" in
  let address_city = List.assoc_opt "address_city" form_data |> Option.value ~default:"" in
  let address_state = List.assoc_opt "address_state" form_data |> Option.value ~default:"" in
  let address_zipcode = List.assoc_opt "address_zipcode" form_data |> Option.value ~default:"" in
  let referral_code = List.assoc_opt "referral_code" form_data |> Option.value ~default:"" in
  
  if name = "" || email = "" || password = "" || phone = "" || document_number = "" ||
     address_street = "" || address_number = "" || address_neighborhood = "" ||
     address_city = "" || address_state = "" || address_zipcode = "" || referral_code = "" then
    let content = Templates.register_template ~error:"Todos os campos obrigatórios devem ser preenchidos" () in
    html content
  else
    Api.register name email password phone document_number address_street address_number 
                 address_complement address_neighborhood address_city address_state 
                 address_zipcode referral_code >>= (function
    | Ok (Some session_id) ->
        (* Get user info to store user_id *)
        Api.get_current_user ~session:session_id () >>= (function
        | Some user ->
            Dream.set_session_field request "user_id" (string_of_int user.user_id) >>= fun () ->
            Dream.set_session_field request "backend_session" session_id >>= fun () ->
            Logs.info (fun m -> m "✅ User registered via backend API");
            redirect request "/dashboard"
        | None ->
            Logs.warn (fun m -> m "❌ Failed to get user info after registration");
            let register_content = Templates.register_template ~error:"Erro ao recuperar informações do usuário" () in
            html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Cadastro" ~content:register_content))
    | Ok None ->
        Logs.warn (fun m -> m "❌ Registration returned no session");
        let register_content = Templates.register_template ~error:"Erro no registro" () in
        html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Cadastro" ~content:register_content)
    | Error msg ->
        Logs.warn (fun m -> m "❌ Registration failed: %s" msg);
        let register_content = Templates.register_template ~error:msg () in
        html (Templates.base_template ~user:(None : Types.user option) ~title:"BusCars - Cadastro" ~content:register_content))

let dashboard_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    let backend_session = Dream.session_field request "backend_session" in
    (* Get current user from backend *)
    Api.get_current_user ?session:backend_session () >>= (function
    | Some user ->
        (* Parse query parameters for pagination and filters *)
        let parse_int name =
          match Dream.query request name with
          | Some value when value <> "" -> (try Some (int_of_string value) with _ -> None)
          | _ -> None
        in
        let page = match parse_int "page" with Some p when p > 0 -> p | _ -> 1 in
        let per_page = 12 in
        let brand = Dream.query request "brand" in
        let model = Dream.query request "model" in
        let year_min = parse_int "year_min" in
        let year_max = parse_int "year_max" in
        let price_min = parse_int "price_min" in
        let price_max = parse_int "price_max" in
        let fuel_type = Dream.query request "fuel_type" in
        let condition = Dream.query request "condition" in
        let sort_by = Dream.query request "sort" in
        let source = Dream.query request "source" in
        let user_email = Dream.query request "user_email" in
        
        (* If admin and user_email is provided, find user_id by email *)
        (if user.is_admin && user_email <> None then
           (match user_email with
            | Some email when email <> "" ->
                (* Fetch all users and find by email *)
                Api.fetch_all_users ?session:backend_session ~page:1 ~per_page:1000 () >>= (function
                | Ok users_page ->
                    (match List.find_opt (fun (u: Types.user) -> u.email = email) users_page.users with
                     | Some found_user ->
                         Lwt.return (Some found_user.user_id)
                     | None ->
                         Logs.warn (fun m -> m "User not found with email: %s" email);
                         Lwt.return None)
                | Error _ -> Lwt.return None)
            | _ -> Lwt.return None)
         else
           Lwt.return None) >>= fun seller_id_by_email ->
        
        (* Use seller_id from email filter if provided, otherwise use current user's id for non-admin *)
        let final_seller_id = 
          if user.is_admin then
            seller_id_by_email
          else
            Some user.user_id
        in
        
        (* Fetch vehicles - all if admin, own if user *)
        Api.fetch_vehicles ?brand ?model ?condition ?source ?fuel_type
          ?year_min ?year_max ?price_min ?price_max ?seller_id:final_seller_id ?sort:sort_by
          ~page ~per_page () >>= fun page_data ->
        
        (* Fetch referral codes (initial load - will be loaded via JS with pagination) *)
        Api.fetch_referral_codes ?session:backend_session ~page:1 ~per_page:5 ~search:"" ~status:"all" () >>= (function
        | Some codes_page ->
            (* Fetch all users if admin (with pagination) *)
            (if user.is_admin then
               Api.fetch_all_users ?session:backend_session ~page:1 ~per_page:12 () >>= (function
               | Ok users_page ->
                   Logs.info (fun m -> m "📊 Fetched %d users for admin dashboard (page %d/%d)" 
                     (List.length users_page.users) users_page.page users_page.total_pages);
                   Lwt.return (Some users_page)
               | Error _ -> Lwt.return None)
             else
               Lwt.return None) >>= fun all_users_page ->
            
            Logs.info (fun m -> m "📊 Dashboard loaded: %d vehicles (page %d/%d), %d codes (page 1)" 
              (List.length page_data.vehicles) page_data.page page_data.total_pages codes_page.total_count);
            (* Fetch brands for filter dropdown *)
            Api.fetch_fipe_brands () >>= fun brands ->
            (* Use brand name directly for DB models (not FIPE code) *)
            (match brand with
             | Some brand_name -> Api.fetch_db_models brand_name
             | None -> Lwt.return []) >>= fun models ->
            let dashboard_content = Templates.dashboard_template ~user ~vehicles_page:page_data
                          ~brands ~models ?selected_brand:brand ?selected_model:model
                          ?selected_source:source ?selected_user_email:user_email
                          ~referral_codes_page:(Some codes_page) ?all_users_page () in
            html (Templates.base_template ~user:(Some user) ~title:"BusCars - Dashboard" ~content:dashboard_content)
        | None ->
            (* Fallback if fetch fails *)
            (if user.is_admin then
               Api.fetch_all_users ?session:backend_session ~page:1 ~per_page:12 () >>= (function
               | Ok users_page -> Lwt.return (Some users_page)
               | Error _ -> Lwt.return None)
             else
               Lwt.return None) >>= fun all_users_page ->
            let empty_page: Types.referral_codes_page = {
              codes = [];
              total_count = 0;
              page = 1;
              per_page = 5;
              total_pages = 0;
              has_next = false;
              has_prev = false;
            } in
            let empty_vehicles_page: Types.vehicle_page = {
              vehicles = [];
              total_count = 0;
              page = 1;
              total_pages = 0;
              has_next = false;
              has_prev = false;
            } in
            Api.fetch_fipe_brands () >>= fun brands ->
            let dashboard_content = Templates.dashboard_template ~user ~vehicles_page:empty_vehicles_page
                          ~brands ~models:[] ~referral_codes_page:(Some empty_page) ?all_users_page () in
            html (Templates.base_template ~user:(Some user) ~title:"BusCars - Dashboard" ~content:dashboard_content))
    | None ->
        redirect request "/login")
  | None -> redirect request "/login"

let logout_handler request =
  Dream.invalidate_session request >>= fun () ->
  redirect request "/"

let external_redirect_handler request =
  let source = param request "source" in
  
  (* For generic redirects without a specific vehicle, use a fallback slug *)
  let fallback_slug = "redirect-" ^ source in
  
  get_user_from_session request >>= fun user_opt ->
  let redirect_content = Templates.advertisement_redirect_page ~slug:fallback_slug ~source () in
    html (Templates.base_template ~user:user_opt ~title:"BusCars - Redirecionando..." ~content:redirect_content)

(* Handler for external frame page (second page with iframe) *)
let external_frame_handler request =
  let slug_param = Dream.param request "slug" in
  
  (* Fetch vehicle by slug to get the URL and source *)
  Api.fetch_vehicle_by_slug slug_param >>= function
  | Some vehicle ->
      let redirect_url = match vehicle.external_url with
        | Some url when url <> "" -> url
        | _ -> 
            (* Fallback based on source *)
            match String.lowercase_ascii vehicle.source with
            | "webmotors" -> "https://www.webmotors.com.br/?aff=buscar&utm_source=buscars"
            | "localiza" -> "https://www.localizaseminovos.com.br/?aff=buscar&utm_source=buscars"
            | "icarros" -> "https://www.icarros.com.br/carros/?aff=buscar&utm_source=buscars"
            | _ -> "https://www.buscar.com.br/"
      in
      (* Check source: iCarros redirects directly, Localiza uses iframe *)
      let source_lower = String.lowercase_ascii vehicle.source in
      if source_lower = "icarros" then
        (* iCarros: redirect directly without iframe *)
        Dream.redirect request redirect_url
      else if source_lower = "localiza" then
        (* Localiza: show iframe page *)
        let frame_content = Templates.advertisement_frame_page ~redirect_url ~source:vehicle.source () in
        html frame_content
      else
        (* Default: show iframe page *)
        let frame_content = Templates.advertisement_frame_page ~redirect_url ~source:vehicle.source () in
        html frame_content
  | None ->
      (* Vehicle not found, redirect to vehicles page *)
      redirect request "/vehicles"

let add_vehicle_get_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    get_user_from_session request >>= fun user_opt ->
    (match user_opt with
     | Some user ->
         let add_content = Templates.add_vehicle_template ~user () in
         html (Templates.base_template ~user:(Some user) ~title:"BusCars - Adicionar Veículo" ~content:add_content)
     | None -> redirect request "/login")
  | None -> redirect request "/login"

let add_vehicle_post_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    (match Dream.session_field request "backend_session" with
     | Some session_id ->
         Dream.body request >>= fun body ->
         (try
           let form_data = Dream.from_form_urlencoded body in
           let brand = List.assoc_opt "brand" form_data |> Option.value ~default:"" in
           let model = List.assoc_opt "model" form_data |> Option.value ~default:"" in
           let year = List.assoc_opt "year" form_data |> Option.map int_of_string |> Option.value ~default:2020 in
           let price = List.assoc_opt "price" form_data |> Option.value ~default:"" in
           let mileage = List.assoc_opt "mileage" form_data |> Option.value ~default:"" in
           let fuel_type = List.assoc_opt "fuel_type" form_data |> Option.value ~default:"" in
           let color = List.assoc_opt "color" form_data |> Option.value ~default:"" in
           let transmission = List.assoc_opt "transmission" form_data |> Option.value ~default:"" in
           let description = List.assoc_opt "description" form_data |> Option.value ~default:"" in
           let image = List.assoc_opt "image" form_data |> Option.value ~default:"" in
           let images_str = List.assoc_opt "images" form_data |> Option.value ~default:"" in
           let images = if images_str <> "" then String.split_on_char ',' images_str |> List.filter (fun s -> s <> "") else [] in
           let seller_name = List.assoc_opt "seller_name" form_data |> Option.value ~default:"" in
           let seller_phone = List.assoc_opt "seller_phone" form_data |> Option.value ~default:"" in
           let seller_email = List.assoc_opt "seller_email" form_data |> Option.value ~default:"" in
           let engine = List.assoc_opt "engine" form_data in
           let doors = List.assoc_opt "doors" form_data |> Option.map int_of_string |> Option.value ~default:4 in
           let body_style = List.assoc_opt "body_style" form_data in
           let location_city = List.assoc_opt "location_city" form_data |> Option.value ~default:"São Paulo" in
           let location_state = List.assoc_opt "location_state" form_data |> Option.value ~default:"SP" in
           let financing_available = List.mem_assoc "financing_available" form_data in
           let trade_accepted = List.mem_assoc "trade_accepted" form_data in
           let test_drive_available = List.mem_assoc "test_drive_available" form_data in
           let exterior_condition = List.assoc_opt "exterior_condition" form_data in
           let interior_condition = List.assoc_opt "interior_condition" form_data in
           let mechanical_condition = List.assoc_opt "mechanical_condition" form_data in
           let previous_owners = List.assoc_opt "previous_owners" form_data |> Option.map int_of_string |> Option.value ~default:1 in
           
           if brand <> "" && model <> "" && price <> "" && image <> "" && description <> "" then
             (get_user_from_session request >>= fun user_opt ->
              match user_opt with
              | Some user ->
                  let seller_email = if seller_email = "" then user.email else seller_email in
                  Api.create_vehicle ~session:session_id brand model year price mileage fuel_type color transmission
                    description image images seller_name seller_phone seller_email "used" location_city location_state
                    engine doors body_style financing_available trade_accepted test_drive_available
                    exterior_condition interior_condition mechanical_condition previous_owners >>= (function
                  | Ok (vehicle_id, slug) ->
                      Logs.info (fun m -> m "✅ Created vehicle ID: %d, slug: %s" vehicle_id slug);
                      redirect request ("/vehicle/" ^ slug)
                  | Error msg ->
                      let add_content = Templates.add_vehicle_template ~error:msg ~user () in
                      html (Templates.base_template ~user:(Some user) ~title:"BusCars - Adicionar Veículo" ~content:add_content))
              | None -> redirect request "/login")
           else
             get_user_from_session request >>= fun user_opt ->
             (match user_opt with
              | Some user ->
                  let add_content = Templates.add_vehicle_template ~error:"Todos os campos são obrigatórios" ~user () in
                  html (Templates.base_template ~user:(Some user) ~title:"BusCars - Adicionar Veículo" ~content:add_content)
              | None -> redirect request "/login")
         with e ->
           get_user_from_session request >>= fun user_opt ->
           (match user_opt with
            | Some user ->
                let add_content = Templates.add_vehicle_template ~error:("Erro no formulário: " ^ Printexc.to_string e) ~user () in
                html (Templates.base_template ~user:(Some user) ~title:"BusCars - Adicionar Veículo" ~content:add_content)
            | None -> redirect request "/login"))
     | None -> redirect request "/login")
  | None -> redirect request "/login"

let edit_vehicle_get_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
      let slug = Dream.param request "slug" in
      get_user_from_session request >>= fun user_opt ->
      (match user_opt with
       | Some user ->
           Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
           (match vehicle_opt with
            | Some vehicle ->
                (* Verify user owns the vehicle or is admin *)
                if vehicle.seller_id = user.user_id || user.is_admin then
                  let edit_content = Templates.edit_vehicle_template ~user ~vehicle () in
                  html (Templates.base_template ~user:(Some user) ~title:"BusCars - Editar Anúncio" ~content:edit_content)
                else
                  redirect request "/dashboard"
            | None ->
                redirect request "/dashboard")
       | None -> redirect request "/login")
  | None -> redirect request "/login"

let edit_vehicle_post_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    (match Dream.session_field request "backend_session" with
     | Some session_id ->
         let slug = Dream.param request "slug" in
         Dream.body request >>= fun body ->
         (try
           let form_data = Dream.from_form_urlencoded body in
           let vehicle_id_str = List.assoc_opt "vehicle_id" form_data |> Option.value ~default:"" in
           let vehicle_id = try int_of_string vehicle_id_str with _ -> 0 in
           let brand = List.assoc_opt "brand" form_data |> Option.value ~default:"" in
           let model = List.assoc_opt "model" form_data |> Option.value ~default:"" in
           let year = List.assoc_opt "year" form_data |> Option.map int_of_string |> Option.value ~default:2020 in
           let price = List.assoc_opt "price" form_data |> Option.value ~default:"" in
           let mileage = List.assoc_opt "mileage" form_data |> Option.value ~default:"" in
           let fuel_type = List.assoc_opt "fuel_type" form_data |> Option.value ~default:"" in
           let color = List.assoc_opt "color" form_data |> Option.value ~default:"" in
           let transmission = List.assoc_opt "transmission" form_data |> Option.value ~default:"" in
           let description = List.assoc_opt "description" form_data |> Option.value ~default:"" in
           let image = List.assoc_opt "image" form_data |> Option.value ~default:"" in
           let images_str = List.assoc_opt "images" form_data |> Option.value ~default:"" in
           let images = if images_str <> "" then String.split_on_char ',' images_str |> List.filter (fun s -> s <> "") else [] in
           let seller_name = List.assoc_opt "seller_name" form_data |> Option.value ~default:"" in
           let seller_phone = List.assoc_opt "seller_phone" form_data |> Option.value ~default:"" in
           let seller_email = List.assoc_opt "seller_email" form_data |> Option.value ~default:"" in
           let engine = List.assoc_opt "engine" form_data in
           let doors = List.assoc_opt "doors" form_data |> Option.map int_of_string |> Option.value ~default:4 in
           let body_style = List.assoc_opt "body_style" form_data in
           let location_city = List.assoc_opt "location_city" form_data |> Option.value ~default:"São Paulo" in
           let location_state = List.assoc_opt "location_state" form_data |> Option.value ~default:"SP" in
           let financing_available = List.mem_assoc "financing_available" form_data in
           let trade_accepted = List.mem_assoc "trade_accepted" form_data in
           let test_drive_available = List.mem_assoc "test_drive_available" form_data in
           let exterior_condition = List.assoc_opt "exterior_condition" form_data in
           let interior_condition = List.assoc_opt "interior_condition" form_data in
           let mechanical_condition = List.assoc_opt "mechanical_condition" form_data in
           let previous_owners = List.assoc_opt "previous_owners" form_data |> Option.map int_of_string |> Option.value ~default:1 in
           
           if vehicle_id > 0 && brand <> "" && model <> "" && price <> "" && image <> "" && description <> "" then
             (get_user_from_session request >>= fun user_opt ->
              match user_opt with
              | Some user ->
                  let seller_email = if seller_email = "" then user.email else seller_email in
                  Api.update_vehicle ~session:session_id vehicle_id brand model year price mileage fuel_type color transmission
                    description image images seller_name seller_phone seller_email "used" location_city location_state
                    engine doors body_style financing_available trade_accepted test_drive_available
                    exterior_condition interior_condition mechanical_condition previous_owners >>= (function
                  | Ok (new_version_id, new_slug) ->
                      Logs.info (fun m -> m "✅ Updated vehicle ID: %d" new_version_id);
                      redirect request ("/vehicle/" ^ new_slug)
                  | Error msg ->
                      Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
                      (match vehicle_opt with
                       | Some vehicle ->
                           let edit_content = Templates.edit_vehicle_template ~error:msg ~user ~vehicle () in
                           html (Templates.base_template ~user:(Some user) ~title:"BusCars - Editar Anúncio" ~content:edit_content)
                       | None ->
                           redirect request "/dashboard"))
              | None -> redirect request "/login")
           else
             (get_user_from_session request >>= fun user_opt ->
              match user_opt with
              | Some user ->
                  Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
                  (match vehicle_opt with
                   | Some vehicle ->
                       let edit_content = Templates.edit_vehicle_template ~error:"Por favor, preencha todos os campos obrigatórios." ~user ~vehicle () in
                       html (Templates.base_template ~user:(Some user) ~title:"BusCars - Editar Anúncio" ~content:edit_content)
                   | None ->
                       redirect request "/dashboard")
              | None -> redirect request "/login")
         with e ->
           get_user_from_session request >>= fun user_opt ->
           (match user_opt with
            | Some user ->
                Api.fetch_vehicle_by_slug slug >>= fun vehicle_opt ->
                (match vehicle_opt with
                 | Some vehicle ->
                     let error_msg = "Erro interno ao processar o formulário: " ^ (Printexc.to_string e) in
                     let edit_content = Templates.edit_vehicle_template ~error:error_msg ~user ~vehicle () in
                     html (Templates.base_template ~user:(Some user) ~title:"BusCars - Editar Anúncio" ~content:edit_content)
                 | None ->
                     redirect request "/dashboard")
            | None -> redirect request "/login"))
     | None -> redirect request "/login")
  | None -> redirect request "/login"

let delete_vehicle_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
    (match Dream.session_field request "backend_session" with
     | Some session_id ->
         let vehicle_id_str = Dream.param request "id" in
         let vehicle_id = try int_of_string vehicle_id_str with _ -> 0 in
         if vehicle_id > 0 then
           (Api.delete_vehicle ~session:session_id vehicle_id >>= (function
            | Ok () ->
                Logs.info (fun m -> m "✅ Deleted vehicle ID: %d" vehicle_id);
                redirect request "/dashboard"
            | Error msg ->
                Logs.warn (fun m -> m "❌ Failed to delete vehicle: %s" msg);
                redirect request "/dashboard"))
         else
           redirect request "/dashboard"
     | None -> redirect request "/login")
  | None -> redirect request "/login"

let fipe_brands_proxy_handler request =
  let vehicle_type = match Dream.query request "vehicle_type" with Some v -> v | None -> "cars" in
  Api.fetch_fipe_brands ~vehicle_type () >>= fun brands ->
  let json = `Assoc [
    ("success", `Bool true);
    ("message", `String "FIPE brands retrieved");
    ("data", `Assoc [
      ("vehicle_type", `String vehicle_type);
      ("brands", `List (List.map Types.fipe_brand_to_yojson brands));
    ]);
  ] in
  Dream.json (Yojson.Safe.to_string json)

(* Proxy handler for external URLs to bypass iframe restrictions *)
let proxy_handler request =
  let url_param = Dream.query request "url" in
  Logs.info (fun m -> m "🔗 Proxy request - url param: %s" (match url_param with Some u -> u | None -> "None"));
  match url_param with
  | Some url when url <> "" ->
      let backend_url = "http://backend:3000/api/proxy?url=" ^ (Uri.pct_encode ~component:`Query url) in
      Logs.info (fun m -> m "🔗 Proxying to backend: %s" backend_url);
      let uri = Uri.of_string backend_url in
      Lwt.catch
        (fun () ->
          Cohttp_lwt_unix.Client.get uri >>= fun (resp, body) ->
          let status = Cohttp.Response.status resp |> Cohttp.Code.code_of_status in
          Logs.info (fun m -> m "🔗 Backend proxy response status: %d" status);
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          Dream.respond ~headers:[("Content-Type", "text/html; charset=utf-8")] body_str)
        (fun exn ->
          Logs.err (fun m -> m "Proxy error: %s" (Printexc.to_string exn));
          Dream.respond ~status:`Bad_Gateway ("Failed to proxy URL: " ^ Printexc.to_string exn))
  | _ -> 
      Logs.warn (fun m -> m "❌ Proxy request missing URL parameter");
      Dream.respond ~status:`Bad_Request "URL parameter required"

let fipe_models_proxy_handler request =
  let brand_code = param request "brand_code" in
  let vehicle_type = match Dream.query request "vehicle_type" with Some v -> v | None -> "cars" in
  let reference = Dream.query request "reference" in
  (* Fetch models from FIPE API *)
  Api.fetch_fipe_models ~vehicle_type ?reference brand_code >>= fun models ->
  let json = `Assoc [
    ("success", `Bool true);
    ("message", `String "FIPE models retrieved");
    ("data", `Assoc [
      ("vehicle_type", `String vehicle_type);
      ("reference", (match reference with Some r -> `String r | None -> `Null));
      ("brand_code", `String brand_code);
      ("models", `List (List.map Types.fipe_model_to_yojson models));
    ]);
  ] in
  Dream.json (Yojson.Safe.to_string json)

(* FIPE consult page handler - requires authentication *)
let fipe_consult_handler request =
  match Dream.session_field request "user_id" with
  | Some _ ->
      get_user_from_session request >>= fun user_opt ->
      (match user_opt with
       | Some user ->
           let consult_content = Templates.fipe_consult_template ~user () in
           html (Templates.base_template ~user:(Some user) ~title:"BusCars - Consulta FIPE" ~content:consult_content)
       | None -> redirect request "/login")
  | None -> redirect request "/login"

(* FIPE references proxy handler *)
let fipe_references_proxy_handler _request =
  Api.fetch_fipe_references () >>= fun references ->
  let json = `Assoc [
    ("success", `Bool true);
    ("message", `String "FIPE references retrieved");
    ("data", `Assoc [
      ("references", `List (List.map Types.fipe_reference_to_yojson references));
    ]);
  ] in
  Dream.json (Yojson.Safe.to_string json)

(* FIPE years proxy handler *)
let fipe_years_proxy_handler request =
  let brand_code = param request "brand_code" in
  let model_code = param request "model_code" in
  let vehicle_type = match Dream.query request "vehicle_type" with Some v -> v | None -> "cars" in
  let reference = Dream.query request "reference" in
  Api.fetch_fipe_years ~vehicle_type ?reference brand_code model_code >>= fun years ->
  let json = `Assoc [
    ("success", `Bool true);
    ("message", `String "FIPE years retrieved");
    ("data", `Assoc [
      ("vehicle_type", `String vehicle_type);
      ("reference", (match reference with Some r -> `String r | None -> `Null));
      ("brand_code", `String brand_code);
      ("model_code", `String model_code);
      ("years", `List (List.map Types.fipe_year_to_yojson years));
    ]);
  ] in
  Dream.json (Yojson.Safe.to_string json)

(* FIPE price proxy handler *)
let fipe_price_proxy_handler request =
  let brand_code = param request "brand_code" in
  let model_code = param request "model_code" in
  let year_id = param request "year_id" in
  let vehicle_type = match Dream.query request "vehicle_type" with Some v -> v | None -> "cars" in
  let reference = Dream.query request "reference" in
  Api.fetch_fipe_price ~vehicle_type ?reference brand_code model_code year_id >>= fun price_opt ->
  (match price_opt with
   | Some detail ->
       let json = `Assoc [
         ("success", `Bool true);
         ("message", `String "FIPE price retrieved");
         ("data", Types.fipe_vehicle_detail_to_yojson detail);
       ] in
       Dream.json (Yojson.Safe.to_string json)
   | None ->
       let json = `Assoc [
         ("success", `Bool false);
         ("message", `String "Unable to fetch FIPE price");
       ] in
       Dream.json ~status:`Bad_Gateway (Yojson.Safe.to_string json))

let logo_handler _request =
  let ic = open_in_bin "./static/logo-buscar.png" in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  respond ~headers:[("Content-Type", "image/png")] content

(* API proxy handlers for authenticated endpoints *)
let list_referral_codes_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let page = match Dream.query request "page" with
        | Some p -> (try int_of_string p with _ -> 1)
        | None -> 1
      in
      let per_page = match Dream.query request "per_page" with
        | Some p -> (try int_of_string p with _ -> 5)
        | None -> 5
      in
      let search = Dream.query request "search" |> Option.value ~default:"" in
      let status = Dream.query request "status" |> Option.value ~default:"all" in
      Lwt.catch
        (fun () ->
          Api.fetch_referral_codes ~session:session_id ~page ~per_page ~search ~status () >>= (function
          | Some codes_page ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Códigos de acesso recuperados");
                ("data", `Assoc [
                  ("codes", `List (List.map Types.referral_code_to_yojson codes_page.codes));
                  ("total_count", `Int codes_page.total_count);
                  ("page", `Int codes_page.page);
                  ("per_page", `Int codes_page.per_page);
                  ("total_pages", `Int codes_page.total_pages);
                  ("has_next", `Bool codes_page.has_next);
                  ("has_prev", `Bool codes_page.has_prev);
                ]);
              ]))
          | None ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String "Erro ao recuperar códigos de acesso");
              ]))))
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let create_referral_code_proxy_handler request =
  let session_opt = Dream.session_field request "backend_session" in
  Logs.info (fun m -> m "🔐 Create referral code - session: %s" (match session_opt with Some s -> s | None -> "NONE"));
  match session_opt with
  | Some session_id ->
      Dream.body request >>= fun body ->
      let code_opt = try
        let json = Yojson.Safe.from_string body in
        try 
          let code = Yojson.Safe.Util.member "code" json |> Yojson.Safe.Util.to_string in
          if String.trim code = "" then None else Some code
        with _ -> None
      with _ -> None in
      Lwt.catch
        (fun () ->
          Api.create_referral_code ~session:session_id ?code:code_opt () >>= (function
          | Ok code ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Código criado com sucesso");
                ("data", `Assoc [("code", `String code)]);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ]))))
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let distribute_referral_codes_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      Dream.body request >>= fun body ->
      let email_opt, count = try
        let json = Yojson.Safe.from_string body in
        let email = try
          let e = Yojson.Safe.Util.member "email" json |> Yojson.Safe.Util.to_string in
          if String.trim e = "" || String.lowercase_ascii (String.trim e) = "all" then None else Some e
        with _ -> None in
        let c = try
          Yojson.Safe.Util.member "count" json |> Yojson.Safe.Util.to_int
        with _ -> 1 in
        (email, c)
      with _ -> (None, 1) in
      Lwt.catch
        (fun () ->
          Api.distribute_referral_codes ~session:session_id ?email:email_opt ~count () >>= (function
          | Ok result_json ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Convites distribuídos com sucesso");
                ("data", result_json);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ]))))
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let list_users_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let page = 
        match Dream.query request "page" with
        | Some p -> (try int_of_string p with _ -> 1)
        | None -> 1
      in
      let per_page = 
        match Dream.query request "per_page" with
        | Some p -> (try int_of_string p with _ -> 12)
        | None -> 12
      in
      let search = 
        match Dream.query request "search" with
        | Some s -> Some (String.trim s)
        | None -> None
      in
      let role = 
        match Dream.query request "role" with
        | Some r -> Some (String.trim r)
        | None -> None
      in
      let sort = 
        match Dream.query request "sort" with
        | Some s -> Some (String.trim s)
        | None -> None
      in
      Lwt.catch
        (fun () ->
          Api.fetch_all_users ~session:session_id ?page:(Some page) ?per_page:(Some per_page) ?search ?role ?sort () >>= (function
          | Ok users_page ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Usuários recuperados");
                ("data", Types.users_page_to_yojson users_page);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ])))
        )
        (fun e ->
          Logs.err (fun m -> m "Error in list_users_proxy_handler: %s" (Printexc.to_string e));
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let deactivate_all_referral_codes_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      Lwt.catch
        (fun () ->
          Api.deactivate_all_referral_codes ~session:session_id () >>= (function
          | Ok total_deactivated ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Todos os códigos foram desativados");
                ("data", `Assoc [("total_deactivated", `Int total_deactivated)]);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ]))))
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let deactivate_referral_code_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let code_id = try int_of_string (param request "code_id") with _ -> 0 in
      Api.deactivate_referral_code ~session:session_id code_id >>= (function
      | Ok () ->
          Dream.json (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool true);
            ("message", `String "Código desativado com sucesso");
          ]))
      | Error msg ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String msg);
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

(* Scraper jobs proxy handlers *)
let list_scraper_jobs_proxy_handler request =
  let session_opt = Dream.session_field request "backend_session" in
  Logs.info (fun m -> m "🔐 list_scraper_jobs_proxy_handler - session: %s" (match session_opt with Some s -> s | None -> "NONE"));
  match session_opt with
  | Some session_id ->
      Lwt.catch
        (fun () ->
          (* Get query parameters *)
          let search = Dream.query request "search" in
          let source = Dream.query request "source" in
          let page = match Dream.query request "page" with
            | Some p -> (try int_of_string p with _ -> 1)
            | None -> 1
          in
          let per_page = match Dream.query request "per_page" with
            | Some p -> (try int_of_string p with _ -> 10)
            | None -> 10
          in
          
          (* Build query string *)
          let query_params = ref [] in
          query_params := ("page", string_of_int page) :: !query_params;
          query_params := ("per_page", string_of_int per_page) :: !query_params;
          (match search with Some s when s <> "" -> query_params := ("search", s) :: !query_params | _ -> ());
          (match source with Some s when s <> "" -> query_params := ("source", s) :: !query_params | _ -> ());
          
          let query_string = String.concat "&" (List.map (fun (k, v) -> k ^ "=" ^ Uri.pct_encode ~component:`Query_key v) !query_params) in
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/scraper-jobs" ^ (if query_string <> "" then "?" ^ query_string else "") in
          Logs.info (fun m -> m "🔗 Proxying scraper jobs request to: %s" api_url);
          let headers = Cohttp.Header.of_list [
            ("Authorization", "Bearer " ^ session_id);
          ] in
          Cohttp_lwt_unix.Client.get ~headers (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          Logs.info (fun m -> m "🔗 Backend response status: %d" (Cohttp.Code.code_of_status status_code));
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 -> `OK
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Logs.err (fun m -> m "❌ Error in list_scraper_jobs_proxy_handler: %s" (Printexc.to_string e));
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao listar scraper jobs: " ^ Printexc.to_string e));
          ])))
  | None ->
      Logs.warn (fun m -> m "❌ list_scraper_jobs_proxy_handler: No session found");
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let get_scraper_job_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let job_id = Dream.param request "id" in
      Lwt.catch
        (fun () ->
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/scraper-jobs/" ^ job_id in
          let headers = Cohttp.Header.of_list [
            ("Authorization", "Bearer " ^ session_id);
          ] in
          Cohttp_lwt_unix.Client.get ~headers (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 -> `OK
            | 404 -> `Not_Found
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao buscar scraper job: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let create_scraper_job_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      Dream.body request >>= fun request_body ->
      Lwt.catch
        (fun () ->
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/scraper-jobs" in
          let headers = Cohttp.Header.of_list [
            ("Content-Type", "application/json");
            ("Authorization", "Bearer " ^ session_id);
          ] in
          let body = Cohttp_lwt.Body.of_string request_body in
          Cohttp_lwt_unix.Client.post ~headers ~body (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 | 201 -> `OK
            | 400 -> `Bad_Request
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao criar scraper job: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let update_scraper_job_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let job_id = Dream.param request "id" in
      Dream.body request >>= fun request_body ->
      Lwt.catch
        (fun () ->
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/scraper-jobs/" ^ job_id in
          let headers = Cohttp.Header.of_list [
            ("Content-Type", "application/json");
            ("Authorization", "Bearer " ^ session_id);
          ] in
          let body = Cohttp_lwt.Body.of_string request_body in
          Cohttp_lwt_unix.Client.put ~headers ~body (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 -> `OK
            | 400 -> `Bad_Request
            | 404 -> `Not_Found
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao atualizar scraper job: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let delete_scraper_job_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let job_id = Dream.param request "id" in
      Lwt.catch
        (fun () ->
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/scraper-jobs/" ^ job_id in
          let headers = Cohttp.Header.of_list [
            ("Authorization", "Bearer " ^ session_id);
          ] in
          Cohttp_lwt_unix.Client.delete ~headers (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 | 204 -> `OK
            | 404 -> `Not_Found
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao deletar scraper job: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let deactivate_stale_vehicles_proxy_handler request =
  (* Try to get session from Dream session field first, then from cookie *)
  let session_id_opt = match Dream.session_field request "backend_session" with
    | Some sid -> Some sid
    | None -> 
        (* Fallback: try to get from cookie *)
        (match Dream.cookie request "session_id" with
         | Some sid -> Some sid
         | None -> None)
  in
  match session_id_opt with
  | Some session_id ->
      Dream.body request >>= fun request_body ->
      Lwt.catch
        (fun () ->
          let api_url = (try Sys.getenv "BACKEND_API_URL" with Not_found -> "http://backend:3000") ^ "/api/maintenance/deactivate-stale-vehicles" in
          let headers = Cohttp.Header.of_list [
            ("Content-Type", "application/json");
            ("Authorization", "Bearer " ^ session_id);
          ] in
          let body = Cohttp_lwt.Body.of_string request_body in
          Cohttp_lwt_unix.Client.post ~headers ~body (Uri.of_string api_url) >>= fun (response, body) ->
          Cohttp_lwt.Body.to_string body >>= fun body_str ->
          let status_code = Cohttp.Response.status response in
          let status = match Cohttp.Code.code_of_status status_code with
            | 200 -> `OK
            | 201 -> `Created
            | 400 -> `Bad_Request
            | 401 -> `Unauthorized
            | 403 -> `Forbidden
            | 404 -> `Not_Found
            | 500 -> `Internal_Server_Error
            | _ -> `Internal_Server_Error
          in
          Dream.json ~status body_str)
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao executar sanitização: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Não autenticado");
      ]))

let change_password_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let old_password = Yojson.Safe.Util.member "old_password" json |> Yojson.Safe.Util.to_string in
          let new_password = Yojson.Safe.Util.member "new_password" json |> Yojson.Safe.Util.to_string in
          Api.change_password ~session:session_id old_password new_password >>= (function
          | Ok () ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Senha alterada com sucesso");
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ])))
        )
        (fun e ->
          Dream.json ~status:`Internal_Server_Error (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let update_user_profile_proxy_handler request =
  let session_opt = Dream.session_field request "backend_session" in
  Logs.info (fun m -> m "🔐 Update user profile - session: %s" (match session_opt with Some s -> s | None -> "NONE"));
  match session_opt with
  | Some session_id ->
      Dream.body request >>= fun body ->
      (Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let name = Yojson.Safe.Util.member "name" json |> Yojson.Safe.Util.to_string in
          let phone = Yojson.Safe.Util.member "phone" json |> Yojson.Safe.Util.to_string in
          let document_number = Yojson.Safe.Util.member "document_number" json |> Yojson.Safe.Util.to_string in
          let address_street = Yojson.Safe.Util.member "address_street" json |> Yojson.Safe.Util.to_string in
          let address_number = Yojson.Safe.Util.member "address_number" json |> Yojson.Safe.Util.to_string in
          let address_complement = try Some (Yojson.Safe.Util.member "address_complement" json |> Yojson.Safe.Util.to_string) with _ -> None in
          let address_neighborhood = Yojson.Safe.Util.member "address_neighborhood" json |> Yojson.Safe.Util.to_string in
          let address_city = Yojson.Safe.Util.member "address_city" json |> Yojson.Safe.Util.to_string in
          let address_state = Yojson.Safe.Util.member "address_state" json |> Yojson.Safe.Util.to_string in
          let address_zipcode = Yojson.Safe.Util.member "address_zipcode" json |> Yojson.Safe.Util.to_string in
          Api.update_user_profile ~session:session_id name phone document_number address_street address_number
            address_complement address_neighborhood address_city address_state address_zipcode >>= (function
          | Ok user ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Informações atualizadas");
                ("data", Types.user_to_yojson user);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ])))
        )
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao processar requisição: " ^ Printexc.to_string e));
          ]))))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let admin_update_user_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let user_id = Dream.param request "user_id" in
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let name = Yojson.Safe.Util.member "name" json |> Yojson.Safe.Util.to_string in
          let email = Yojson.Safe.Util.member "email" json |> Yojson.Safe.Util.to_string in
          let phone = Yojson.Safe.Util.member "phone" json |> Yojson.Safe.Util.to_string in
          let document_number = Yojson.Safe.Util.member "document_number" json |> Yojson.Safe.Util.to_string in
          let address_street = Yojson.Safe.Util.member "address_street" json |> Yojson.Safe.Util.to_string in
          let address_number = Yojson.Safe.Util.member "address_number" json |> Yojson.Safe.Util.to_string in
          let address_complement = try Some (Yojson.Safe.Util.member "address_complement" json |> Yojson.Safe.Util.to_string) with _ -> None in
          let address_neighborhood = Yojson.Safe.Util.member "address_neighborhood" json |> Yojson.Safe.Util.to_string in
          let address_city = Yojson.Safe.Util.member "address_city" json |> Yojson.Safe.Util.to_string in
          let address_state = Yojson.Safe.Util.member "address_state" json |> Yojson.Safe.Util.to_string in
          let address_zipcode = Yojson.Safe.Util.member "address_zipcode" json |> Yojson.Safe.Util.to_string in
          Api.admin_update_user ~session:session_id (int_of_string user_id) name email phone document_number address_street address_number
            address_complement address_neighborhood address_city address_state address_zipcode >>= (function
          | Ok user ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Usuário atualizado com sucesso");
                ("data", Types.user_to_yojson user);
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ])))
        )
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao processar requisição: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

let admin_change_user_password_proxy_handler request =
  match Dream.session_field request "backend_session" with
  | Some session_id ->
      let user_id = Dream.param request "user_id" in
      Dream.body request >>= fun body ->
      Lwt.catch
        (fun () ->
          let json = Yojson.Safe.from_string body in
          let new_password = Yojson.Safe.Util.member "new_password" json |> Yojson.Safe.Util.to_string in
          Api.admin_change_user_password ~session:session_id (int_of_string user_id) new_password >>= (function
          | Ok () ->
              Dream.json (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool true);
                ("message", `String "Senha alterada com sucesso");
              ]))
          | Error msg ->
              Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
                ("success", `Bool false);
                ("message", `String msg);
              ])))
        )
        (fun e ->
          Dream.json ~status:`Bad_Request (Yojson.Safe.to_string (`Assoc [
            ("success", `Bool false);
            ("message", `String ("Erro ao processar requisição: " ^ Printexc.to_string e));
          ])))
  | None ->
      Dream.json ~status:`Unauthorized (Yojson.Safe.to_string (`Assoc [
        ("success", `Bool false);
        ("message", `String "Authentication required");
      ]))

(* Main application *)
let () =
  run ~interface:"0.0.0.0" ~port:8080
  @@ logger
  @@ Dream.memory_sessions
  @@ router [
    get "/" home_handler;
    get "/fipe/brands" fipe_brands_proxy_handler;
    get "/fipe/brands/:brand_code/models" fipe_models_proxy_handler;
    get "/fipe/references" fipe_references_proxy_handler;
    get "/fipe/brands/:brand_code/models/:model_code/years" fipe_years_proxy_handler;
    get "/fipe/brands/:brand_code/models/:model_code/years/:year_id" fipe_price_proxy_handler;
    get "/fipe-consult" fipe_consult_handler;
    get "/vehicles" vehicles_handler;
    get "/vehicle/:slug" vehicle_slug_handler;
    post "/search" search_handler;
    get "/login" login_get_handler;
    post "/login" login_handler;
    get "/register" register_get_handler;
    post "/register" register_handler;
    get "/logout" logout_handler;
    get "/dashboard" dashboard_handler;
    get "/dashboard/add-vehicle" add_vehicle_get_handler;
    post "/dashboard/add-vehicle" add_vehicle_post_handler;
    get "/dashboard/edit-vehicle/:slug" edit_vehicle_get_handler;
    post "/dashboard/edit-vehicle/:slug" edit_vehicle_post_handler;
    post "/dashboard/delete/:id" delete_vehicle_handler;
    (* API proxy endpoints *)
    get "/api/referral-codes" list_referral_codes_proxy_handler;
    post "/api/referral-codes" create_referral_code_proxy_handler;
    post "/api/referral-codes/distribute" distribute_referral_codes_proxy_handler;
    post "/api/referral-codes/deactivate-all" deactivate_all_referral_codes_proxy_handler;
    post "/api/referral-codes/:code_id/deactivate" deactivate_referral_code_proxy_handler;
    get "/api/proxy" proxy_handler;
    get "/api/users" list_users_proxy_handler;
    put "/api/users/:user_id" admin_update_user_proxy_handler;
    post "/api/users/:user_id/change-password" admin_change_user_password_proxy_handler;
    put "/api/auth/me" update_user_profile_proxy_handler;
    post "/api/auth/change-password" change_password_proxy_handler;
    post "/api/maintenance/deactivate-stale-vehicles" deactivate_stale_vehicles_proxy_handler;
    (* Scraper jobs proxy handlers *)
    get "/api/scraper-jobs" list_scraper_jobs_proxy_handler;
    get "/api/scraper-jobs/:id" get_scraper_job_proxy_handler;
    post "/api/scraper-jobs" create_scraper_job_proxy_handler;
    put "/api/scraper-jobs/:id" update_scraper_job_proxy_handler;
    delete "/api/scraper-jobs/:id" delete_scraper_job_proxy_handler;
    get "/redirect/:source" external_redirect_handler;
    get "/external-frame/:slug" external_frame_handler;
    get "/logo-buscar.png" logo_handler;
    get "/favicon.ico" logo_handler;
  ]

