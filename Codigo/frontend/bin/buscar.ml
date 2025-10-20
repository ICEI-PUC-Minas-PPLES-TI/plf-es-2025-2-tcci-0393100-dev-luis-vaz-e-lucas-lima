open Dream
open Lwt.Infix
module Templates = Buscar_lib.Templates
open Buscar_lib.Types

(* Initialize random seed *)
let () = Random.self_init ()

(* Theme helper function - not used in current implementation but kept for future server-side theme features *)
let _get_theme_from_request request =
  match Dream.cookie request "theme" with
  | Some theme when theme = "dark" || theme = "light" -> theme
  | _ -> "light" (* default to light theme *)

(* Sample data - in a real app this would come from a database *)
let sample_vehicles = [
  {
    id = 1;
    slug = "porsche-911-2022-1";
    brand = "Porsche";
    model = "911";
    year = 2022;
    price = "850.000";
    mileage = "15.000";
    fuel_type = "Gasolina";
    color = "Prata Metálico";
    transmission = "PDK 8 velocidades";
    description = "Porsche 911 Carrera em estado impecável.";
    image = "https://placehold.co/900x600/1a202c/10b981?text=2022+Porsche+911+Carrera";
    images = [
      "https://placehold.co/1200x800/1a202c/10b981?text=Porsche+911+3-4+Front";
      "https://placehold.co/1200x800/374151/ffffff?text=Interior+Couro+Preto";
      "https://placehold.co/1200x800/059669/ffffff?text=Motor+3.0L+Flat-Six+Turbo";
      "https://placehold.co/1200x800/dc2626/ffffff?text=Rodas+20pol+Originais";
      "https://placehold.co/1200x800/10b981/ffffff?text=Dashboard+PCM+5.0";
      "https://placehold.co/1200x800/764ba2/ffffff?text=Acabamento+Interno";
      "https://placehold.co/1200x800/1a202c/ffffff?text=Motor+Bay+Detalhes";
      "https://placehold.co/1200x800/374151/10b981?text=Compartimento+Traseiro";
    ];
    seller_name = "Carlos Silva";
    seller_phone = "(11) 99999-9999";
    seller_email = "carlos.silva@email.com";
    condition = "used";
    source = "buscar";
    engine = "3.0L Flat-Six Turbo (385cv)";
    doors = 2;
    body_style = "Coupé Esportivo";
    features = [
      "Porsche Communication Management (PCM) 5.0";
      "Teto solar panorâmico elétrico";
      "Bancos esportivos em couro com aquecimento";
      "Sistema de som Bose Premium";
      "Cruise control adaptativo com Stop & Go";
      "Rodas 20 polegadas originais Porsche";
      "Faróis LED Matrix com PDLS+";
      "Sistema de escape esportivo";
      "Suspensão ativa PASM";
      "Freios cerâmicos PCCB";
    ];
    detailed_description_md = "# Porsche 911 Carrera 2022 - Perfeição Alemã\n\n## História do Veículo\n\nEste **magnífico Porsche 911 Carrera 2022** representa o ápice da engenharia alemã moderna. Adquirido **zero quilômetro** pelo atual proprietário em março de 2022, este exemplar foi meticulosamente mantido com todas as revisões realizadas exclusivamente na **rede autorizada Porsche**.\n\n## Performance e Tecnologia\n\nO coração deste 911 é o **motor flat-six 3.0L biturbo** que produz impressionantes **385 cv de potência** e **450 Nm de torque**. Acoplado à transmissão **PDK de 8 velocidades**, proporciona uma experiência de condução inesquecível:\n\n- **0-100 km/h**: 4,2 segundos\n- **Velocidade máxima**: 293 km/h\n- **Consumo médio**: 11,8 km/l (cidade)\n\n## Interior e Conforto\n\nO interior em **couro preto Premium** contrasta perfeitamente com a pintura **Prata GT Metálico**, criando um ambiente sofisticado e esportivo. Todos os sistemas funcionam perfeitamente, incluindo:\n\n- **PCM 5.0** com navegação em tempo real\n- **Apple CarPlay** e **Android Auto**\n- **Sistema de som Bose** com 12 alto-falantes\n- **Climatização automática** de duas zonas\n\n## Documentação Completa\n\n✅ **Manual do proprietário** completo\n✅ **Chaves reservas** (2 unidades)\n✅ **Kit de ferramentas** original Porsche\n✅ **Certificado de garantia** estendida até 2027\n✅ **Histórico de revisões** completo\n✅ **IPVA 2024** quitado\n\n*Veículo para conhecedores que buscam o melhor da engenharia esportiva alemã.*";
    
    (* Additional detailed fields *)
    vin = Some "WP0AA2A99NS123456";
    license_plate = Some "ABC1D23";
    previous_owners = 1;
    service_history = [
      "2025 - Revisão de 10.000km (Porsche Ibirapuera)";
      "2023 - Revisão de 5.000km (Porsche Ibirapuera)";
      "2022 - Entrega PDI (Porsche Ibirapuera)";
    ];
    modifications = [];
    included_items = [
      "Manual do proprietário";
      "2 chaves originais";
      "Kit de ferramentas Porsche";
      "Carregador portátil";
      "Capa protetora original";
    ];
    exterior_condition = "Excelente";
    interior_condition = "Excelente"; 
    mechanical_condition = "Perfeito";
    inspection_notes = "Veículo inspecionado por nossa equipe técnica especializada. Todos os sistemas funcionando perfeitamente. Pneus com 90% de vida útil. Sem sinais de colisão ou reparo.";
    location_city = "São Paulo";
    location_state = "SP";
    financing_available = true;
    trade_accepted = true;
    test_drive_available = true;
  };
  {
    id = 2;
    slug = "toyota-corolla-2021-2";
    brand = "Toyota";
    model = "Corolla";
    year = 2021;
    price = "95.000";
    mileage = "25.000";
    fuel_type = "Flex";
    color = "Branco Perolado";
    transmission = "CVT Automática";
    description = "Toyota Corolla XEi 2021, modelo mais vendido do Brasil.";
    image = "https://placehold.co/900x600/10b981/ffffff?text=2021+Toyota+Corolla+XEi";
    images = [
      "https://placehold.co/1200x800/10b981/ffffff?text=Corolla+Front+3-4";
      "https://placehold.co/1200x800/059669/ffffff?text=Interior+Bege+Completo";
      "https://placehold.co/1200x800/1a202c/ffffff?text=Dashboard+Digital";
      "https://placehold.co/1200x800/374151/10b981?text=Motor+2.0+Flex";
      "https://placehold.co/1200x800/dc2626/ffffff?text=Bagageiro+Amplo";
      "https://placehold.co/1200x800/764ba2/ffffff?text=Banco+Traseiro";
    ];
    seller_name = "Maria Santos";
    seller_phone = "(11) 88888-8888";
    seller_email = "maria.santos@gmail.com";
    condition = "used";
    source = "buscar";
    engine = "2.0L Flex 16V Dynamic Force (177cv)";
    doors = 4;
    body_style = "Sedan Familiar";
    features = [
      "Central multimídia de 8 polegadas";
      "Ar-condicionado automático dual-zone";
      "Toyota Safety Sense 2.0";
      "Freios ABS com EBD e Brake Assist";
      "6 airbags (frontais, laterais e cortina)";
      "Direção elétrica progressiva";
      "Piloto automático";
      "Sensor de chuva";
      "Faróis automáticos";
      "Chave presencial";
    ];
    detailed_description_md = "# Toyota Corolla XEi 2021 - Confiabilidade Comprovada\n\n## O Sedan Mais Vendido do Brasil\n\nEste **Toyota Corolla XEi 2021** representa a **décima segunda geração** do sedan mais vendido e confiável do mercado brasileiro. Adquirido novo em **abril de 2021** pela atual proprietária, este exemplar foi **sempre mantido em garagem** e possui histórico completo de manutenção na rede autorizada Toyota.\n\n## Motor Dynamic Force\n\nEquipado com o revolucionário **motor 2.0L Dynamic Force**, que combina:\n\n- **Eficiência excepcional**: 14,7 km/l na cidade (etanol)\n- **Performance adequada**: 177 cv e 20,4 kgfm de torque\n- **Tecnologia Dual VVT-iE**: variação inteligente das válvulas\n- **Transmissão CVT Direct Shift**: suavidade e economia\n\n## Segurança Toyota Safety Sense 2.0\n\nSistema completo de segurança ativa inclui:\n\n- **Frenagem automática de emergência** com detecção de pedestres\n- **Alerta de mudança de faixa** com correção ativa\n- **Cruise control adaptativo** com Stop & Go\n- **Farol alto automático** inteligente\n\n## Único Dono - Histórico Limpo\n\n✅ **IPVA 2024** quitado  \n✅ **Licenciamento** em dia  \n✅ **Manual do proprietário** e documentos  \n✅ **Duas chaves** originais  \n✅ **Sem sinais de colisão** ou reparo  \n✅ **Pneus novos** Bridgestone  \n\n*Ideal para famílias que buscam economia, segurança e tecnologia em um sedan confiável.*";
    
    vin = Some "9BR53ZEC1M5123456";
    license_plate = Some "XYZ9A87";
    previous_owners = 1;
    service_history = [
      "2025 - Revisão de 20.000km + troca de óleo (Toyota Lapa)";
      "2023 - Revisão de 10.000km (Toyota Lapa)";
      "2022 - Primeira revisão 5.000km (Toyota Lapa)";
      "2021 - Entrega PDI (Toyota Lapa)";
    ];
    modifications = [];
    included_items = [
      "Manual do proprietário completo";
      "2 chaves originais Toyota";
      "Kit de primeiros socorros";
      "Triângulo de segurança";
      "Chave de roda";
      "Macaco hidráulico";
    ];
    exterior_condition = "Muito Bom";
    interior_condition = "Excelente";
    mechanical_condition = "Perfeito";
    inspection_notes = "Veículo de único dono sempre em garagem. Pintura original sem retoques. Interior em tecido bege sem desgastes. Motor com funcionamento perfeito, sem vazamentos. Transmissão CVT suave. Ar-condicionado gelando. Todos os equipamentos eletrônicos funcionando. Pneus novos com 95% vida útil.";
    location_city = "São Paulo";
    location_state = "SP"; 
    financing_available = true;
    trade_accepted = true;
    test_drive_available = true;
  };
  (* External vehicles - will redirect to their platforms *)
  {
    id = 3; slug = "bmw-x5-2023-3"; brand = "BMW"; model = "X5"; year = 2023; price = "320.000"; mileage = "8.000"; fuel_type = "Gasolina"; color = "Preto"; transmission = "Automática"; description = "BMW X5 xDrive 2023, SUV premium"; image = "https://placehold.co/600x400/1a202c/10b981?text=BMW+X5"; images = []; seller_name = "João Oliveira"; seller_phone = "(11) 77777-7777"; seller_email = ""; condition = "new"; source = "localiza"; engine = "3.0L I6 Turbo"; doors = 4; body_style = "SUV"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 1; service_history = []; modifications = []; included_items = []; exterior_condition = "Excelente"; interior_condition = "Excelente"; mechanical_condition = "Excelente"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 4; slug = "porsche-cayenne-2020-4"; brand = "Porsche"; model = "Cayenne"; year = 2020; price = "450.000"; mileage = "35.000"; fuel_type = "Gasolina"; color = "Azul"; transmission = "Automática"; description = "Porsche Cayenne 2020, SUV esportivo"; image = "https://placehold.co/600x400/764ba2/ffffff?text=Porsche+Cayenne"; images = []; seller_name = "Ana Costa"; seller_phone = "(11) 66666-6666"; seller_email = ""; condition = "used"; source = "webmotors"; engine = "3.6L V6"; doors = 4; body_style = "SUV"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 2; service_history = []; modifications = []; included_items = []; exterior_condition = "Bom"; interior_condition = "Bom"; mechanical_condition = "Bom"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  (* External platform vehicles - simplified since they redirect *)
  {
    id = 5; slug = "bmw-serie-3-2019-5"; brand = "BMW"; model = "Série 3"; year = 2019; price = "180.000"; mileage = "45.000"; fuel_type = "Gasolina"; color = "Branco"; transmission = "Automática"; description = "BMW Série 3 executivo"; image = "https://placehold.co/600x400/334155/10b981?text=BMW+Serie+3"; images = []; seller_name = "Pedro Santos"; seller_phone = "(11) 55555-5555"; seller_email = ""; condition = "used"; source = "webmotors"; engine = "2.0L Turbo"; doors = 4; body_style = "Sedan"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 2; service_history = []; modifications = []; included_items = []; exterior_condition = "Bom"; interior_condition = "Bom"; mechanical_condition = "Bom"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 6; slug = "toyota-rav4-2022-6"; brand = "Toyota"; model = "RAV4"; year = 2022; price = "220.000"; mileage = "18.000"; fuel_type = "Híbrido"; color = "Cinza"; transmission = "Automática"; description = "Toyota RAV4 Híbrido"; image = "https://placehold.co/600x400/059669/ffffff?text=Toyota+RAV4+Hybrid"; images = []; seller_name = "Laura Costa"; seller_phone = "(11) 44444-4444"; seller_email = ""; condition = "new"; source = "icarros"; engine = "2.5L Hybrid"; doors = 4; body_style = "SUV"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 1; service_history = []; modifications = []; included_items = []; exterior_condition = "Excelente"; interior_condition = "Excelente"; mechanical_condition = "Excelente"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 7; slug = "volkswagen-golf-2020-7"; brand = "Volkswagen"; model = "Golf"; year = 2020; price = "89.900"; mileage = "32.000"; fuel_type = "Flex"; color = "Azul"; transmission = "Manual"; description = "VW Golf Highline"; image = "https://placehold.co/600x400/1e293b/10b981?text=VW+Golf"; images = []; seller_name = "Concessionária VW Santos"; seller_phone = "(13) 3333-3333"; seller_email = ""; condition = "used"; source = "webmotors"; engine = "1.4L TSI"; doors = 4; body_style = "Hatch"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 2; service_history = []; modifications = []; included_items = []; exterior_condition = "Bom"; interior_condition = "Bom"; mechanical_condition = "Bom"; inspection_notes = ""; location_city = "Santos"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 8; slug = "ford-ka-2019-8"; brand = "Ford"; model = "Ka"; year = 2019; price = "52.000"; mileage = "41.000"; fuel_type = "Flex"; color = "Vermelho"; transmission = "Manual"; description = "Ford Ka SE econômico"; image = "https://placehold.co/600x400/dc2626/ffffff?text=Ford+Ka"; images = []; seller_name = "Roberto Silva"; seller_phone = "(11) 91234-5678"; seller_email = ""; condition = "used"; source = "localiza"; engine = "1.0L Flex"; doors = 4; body_style = "Hatch"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 3; service_history = []; modifications = []; included_items = []; exterior_condition = "Regular"; interior_condition = "Bom"; mechanical_condition = "Bom"; inspection_notes = ""; location_city = "São Paulo"; location_state = "SP"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 13; slug = "porsche-356a-1957-13"; brand = "Porsche"; model = "356A"; year = 1957; price = "1.825.000"; mileage = "93.000"; fuel_type = "Gasolina"; color = "Marfim"; transmission = "Manual"; description = "Porsche 356A Speedster 1957 - Família única"; image = "https://placehold.co/800x600/f8fafc/1a202c?text=1957+Porsche+356A+Speedster"; images = []; seller_name = "Walter Murfit"; seller_phone = "Via BaT"; seller_email = ""; condition = "used"; source = "bringatrailer"; engine = "1.6L Flat-Four 1600S (88hp)"; doors = 2; body_style = "Speedster"; features = []; detailed_description_md = ""; vin = None; license_plate = None; previous_owners = 1; service_history = []; modifications = []; included_items = []; exterior_condition = "Muito Bom"; interior_condition = "Bom"; mechanical_condition = "Excelente"; inspection_notes = ""; location_city = "Califórnia"; location_state = "EUA"; financing_available = false; trade_accepted = false; test_drive_available = false;
  };
]

let sample_user = {
  user_id = 1;
  name = "João Silva";
  email = "joao@email.com";
}

(* Helper functions *)
let find_vehicle_by_id id =
  let vehicles = sample_vehicles in
  List.find_opt (fun vehicle -> vehicle.id = id) vehicles

let find_vehicle_by_slug slug =
  let vehicles = sample_vehicles in
  List.find_opt (fun vehicle -> vehicle.slug = slug) vehicles

let filter_vehicles ?brand ?model ?year_min ?price_max ?fuel_type ?condition ?source () =
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
  ) sample_vehicles

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
  
  let filtered_vehicles = filter_vehicles ?brand ?model ?year_min ?price_max ?fuel_type ?condition ?source () in
  
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
    | _ -> filtered_vehicles (* relevance - keep original order *)
  in
  
  (* Pagination logic *)
  let items_per_page = 5 in (* Reduced for easier testing *)
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



(* Unified vehicle detail handler - handles both slugs and IDs *)
let vehicle_slug_handler request =
  match param request "slug" with
  | slug ->
    let vehicle = 
      (* Try to find by slug first, then by ID for backward compatibility *)
      match find_vehicle_by_slug slug with
      | Some v -> Some v
      | None -> 
        (try Some (find_vehicle_by_id (int_of_string slug))
         with _ -> None) |> function
        | Some (Some v) -> Some v
        | _ -> None
    in
    
    (match vehicle with
     | Some vehicle -> 
       (* Only show detailed pages for BusCars listings, redirect external ones *)
       if vehicle.source = "buscar" then
         let return_url = 
           match query request "return" with
           | Some url -> url
           | None -> "/vehicles"
         in
         let content = Templates.vehicle_detail_template ~vehicle ~return_url () in
         html content
       else
         (* Redirect external listings to their platforms via ad *)
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
    
    (* Show advertisement occasionally (30% chance) *)
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
      (* Show ad overlay that redirects to external Brazilian car sites *)
      let external_urls = [
        ("webmotors", "https://www.webmotors.com.br/carros/estoque/?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&modelo=" ^ (match model with Some m -> m | None -> "") ^ "&aff=buscar&utm_source=buscars");
        ("localiza", "https://www.localizaseminovos.com.br/comprar/carros?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&aff=buscar&utm_source=buscars");
        ("icarros", "https://www.icarros.com.br/carros/?marca=" ^ (match brand with Some b -> b | None -> "") ^ "&aff=buscar&utm_source=buscars");
      ] in
      
      (* Pick a random Brazilian platform *)
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
     | Some "admin@buscar.com", Some "123456" ->
       Dream.set_session_field request "user_id" "1" >>= fun () ->
       redirect request "/dashboard"
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
    let user_vehicles = List.filter (fun v -> v.id <= 2) sample_vehicles in
    let content = Templates.dashboard_template ~user:sample_user ~vehicles:user_vehicles () in
    html content
  | None -> redirect request "/login"

let logout_handler request =
  Dream.invalidate_session request >>= fun () ->
  redirect request "/"

(* External redirect handler for different car sites *)
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
       (* In a real app, we would save to database here *)
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

(* Simple logo handler *)
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
