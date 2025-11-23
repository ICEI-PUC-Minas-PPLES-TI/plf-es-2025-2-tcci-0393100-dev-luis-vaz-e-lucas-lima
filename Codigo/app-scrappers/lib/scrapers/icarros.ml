(* iCarros scraper - versão alinhada ao Python *)

open Lwt.Infix
open Scrapers_types
open Common
open Re

(* ============================================ *)
(* HTTP helper específico do iCarros (Curl)     *)
(* ============================================ *)

(* Converte bytes ISO-8859-1/latin1 em UTF-8 válido *)
let latin1_to_utf8 (s : string) : string =
  let b = Buffer.create (String.length s * 2) in
  String.iter
    (fun ch ->
      let code = Char.code ch in
      if code < 0x80 then
        (* ASCII fica igual *)
        Buffer.add_char b ch
      else (
        (* latin1 -> sequência UTF-8 de 2 bytes *)
        Buffer.add_char b (Char.chr (0xC0 lor (code lsr 6)));
        Buffer.add_char b (Char.chr (0x80 lor (code land 0x3F)))
      ))
    s;
  Buffer.contents b

(* Verifica se uma string é UTF-8 válida. *)
let is_valid_utf8 (s : string) : bool =
  let len = String.length s in
  let rec aux i =
    if i >= len then
      true
    else
      let byte = Char.code s.[i] in
      if byte land 0x80 = 0 then
        (* 0xxxxxxx *)
        aux (i + 1)
      else if byte land 0xE0 = 0xC0 then
        (* 110xxxxx 10xxxxxx *)
        if i + 1 >= len then false
        else
          let b1 = Char.code s.[i + 1] in
          if b1 land 0xC0 <> 0x80 then false
          else aux (i + 2)
      else if byte land 0xF0 = 0xE0 then
        (* 1110xxxx 10xxxxxx 10xxxxxx *)
        if i + 2 >= len then false
        else
          let b1 = Char.code s.[i + 1] in
          let b2 = Char.code s.[i + 2] in
          if b1 land 0xC0 <> 0x80 || b2 land 0xC0 <> 0x80 then false
          else aux (i + 3)
      else if byte land 0xF8 = 0xF0 then
        (* 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx *)
        if i + 3 >= len then false
        else
          let b1 = Char.code s.[i + 1] in
          let b2 = Char.code s.[i + 2] in
          let b3 = Char.code s.[i + 3] in
          if b1 land 0xC0 <> 0x80
             || b2 land 0xC0 <> 0x80
             || b3 land 0xC0 <> 0x80
          then false
          else aux (i + 4)
      else
        false
  in
  aux 0

(* Rate limiting local só para o iCarros *)
let icarros_last_request : (string, float) Hashtbl.t = Hashtbl.create 1
let icarros_lock = Lwt_mutex.create ()

let get_domain url =
  try
    let uri = Uri.of_string url in
    match Uri.host uri with
    | Some host -> host
    | None -> "unknown"
  with _ -> "unknown"

let http_get_icarros ?(delay_seconds = 0.1) (url : string)
  : ((int * string), string) result Lwt.t =
  let domain = get_domain url in
  Lwt_mutex.with_lock icarros_lock (fun () ->
      let last_request =
        try Hashtbl.find icarros_last_request domain with Not_found -> 0.0
      in
      let now = Unix.gettimeofday () in
      let time_since_last = now -. last_request in

      let%lwt () =
        if time_since_last < delay_seconds then
          let wait_time = delay_seconds -. time_since_last in
          Logs.debug (fun m ->
              m "[iCarros] Rate limiting: esperando %.2fs antes de %s"
                wait_time domain);
          Lwt_unix.sleep wait_time
        else
          Lwt.return_unit
      in

      Hashtbl.replace icarros_last_request domain (Unix.gettimeofday ());

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

          (* User-Agent mais “realista” que o do Common.http_get *)
          Curl.set_useragent c
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) \
             AppleWebKit/537.36 (KHTML, like Gecko) \
             Chrome/123.0.0.0 Safari/537.36";

          let buffer = Buffer.create 16384 in
          Curl.set_writefunction c (fun s ->
              Buffer.add_string buffer s;
              String.length s);

          Curl_lwt.perform c >>= fun code ->
          (match code with
          | Curl.CURLE_OK -> ()
          | _ ->
              (try Curl.cleanup c with _ -> ());
              raise
                (Failure
                   (Printf.sprintf "curl error: %s"
                      (Curl.strerror code))));
          let http_code = Curl.get_responsecode c in
          let raw_body = Buffer.contents buffer in

          (* Se já for UTF-8 válido, não mexe; senão converte de latin1. *)
          let body =
            if is_valid_utf8 raw_body then
              raw_body
            else
              latin1_to_utf8 raw_body
          in

          Curl.cleanup c;
          curl := None;
          Logs.debug (fun m ->
              m "[iCarros] http_get_icarros %s -> %d" url http_code);
          Lwt.return_ok (http_code, body))
        (fun exn ->
          (match !curl with
          | Some c -> (try Curl.cleanup c with _ -> ())
          | None -> ());
          Logs.err (fun m ->
              m "[iCarros] Exception em http_get_icarros para %s: %s"
                url (Printexc.to_string exn));
          Lwt.return_error
            (Printf.sprintf "HTTP request exception: %s"
               (Printexc.to_string exn))))

(* ============================================ *)
(* Helpers comuns                               *)
(* ============================================ *)

(* Helper: take first n elements from list *)
let rec take n = function
  | [] -> []
  | x :: xs when n > 0 -> x :: take (n - 1) xs
  | _ -> []

let base_url = "https://www.icarros.com.br"

let slugify text =
  let text = String.lowercase_ascii (String.trim text) in
  text
  |> String.split_on_char ' '
  |> List.filter (fun s -> s <> "")
  |> String.concat "-"

(*
  Parse anuncios = { items: [ ... ] };

  Python:
  m = re.search(r"anuncios\s*=\s*\{\s*items\s*:\s*\[(.*?)]\s*\};", html, re.DOTALL)
  objects = re.findall(r"\{(.*?)\}", items_block, re.DOTALL)
*)
let parse_anuncios_items (html : string)
  : ((string * string) list list, string) result =
  try
    let re_anuncios =
      Re.Pcre.regexp
        ~flags:[ `DOTALL ]
        "anuncios\\s*=\\s*\\{\\s*items\\s*:\\s*\\[(.*?)]\\s*\\};"
    in
    match Re.exec_opt re_anuncios html with
    | None ->
        Logs.warn (fun m ->
            m
              "[iCarros] Não achei 'anuncios = { items: [...] }' no \
               HTML.");
        (* Alinhado com o Python: tratamos isso como caso especial *)
        Error "NO_ANUNCIOS"
    | Some groups ->
        let items_block = Re.Group.get groups 1 in

        (* Regex para todos os { ... } dentro de items_block *)
        let re_obj = Re.Pcre.regexp ~flags:[ `DOTALL ] "\\{(.*?)\\}" in

        let rec loop pos acc =
          match Re.exec_opt ~pos re_obj items_block with
          | None -> List.rev acc
          | Some g ->
              let obj_body = Re.Group.get g 1 in
              let next_pos =
                let (_start_pos, end_pos) = Re.Group.offset g 0 in
                end_pos
              in

              (* Parse linha a linha: key: value *)
              let item = ref [] in
              obj_body
              |> String.split_on_char '\n'
              |> List.iter (fun raw_line ->
                     (* trim + rstrip(",") igual ao Python *)
                     let line = String.trim raw_line in
                     let line =
                       let len = String.length line in
                       if len > 0 && line.[len - 1] = ',' then
                         String.sub line 0 (len - 1)
                       else
                         line
                     in
                     if line <> "" && String.contains line ':' then
                       match String.index_opt line ':' with
                       | None -> ()
                       | Some idx ->
                           let key =
                             String.sub line 0 idx |> String.trim
                           in
                           let value =
                             String.sub line (idx + 1)
                               (String.length line - idx - 1)
                             |> String.trim
                           in
                           (* remover crase `...` como no Python *)
                           let value =
                             let len = String.length value in
                             if len >= 2
                                && value.[0] = '`'
                                && value.[len - 1] = '`'
                             then
                               String.sub value 1 (len - 2)
                             else
                               value
                           in
                           item := (key, value) :: !item);

              (* Filtrar apenas itens com item_id numérico (como no Python) *)
              let raw_id =
                match List.assoc_opt "item_id" !item with
                | Some v -> v
                | None -> ""
              in
              let is_numeric =
                raw_id <> ""
                && String.for_all
                     (fun c -> c >= '0' && c <= '9')
                     raw_id
              in
              let acc = if is_numeric then !item :: acc else acc in
              loop next_pos acc
        in

        let items = loop 0 [] in
        Logs.info (fun m ->
            m "[iCarros] parse_anuncios_items: %d itens válidos."
              (List.length items));
        Ok items
  with exn ->
    let msg = Printexc.to_string exn in
    Logs.err (fun m ->
        m "[iCarros] Exception em parse_anuncios_items: %s" msg);
    Error msg

(* Igual ao Python: tenta primeiro pelo rel_link; se não achar, tenta pelo item_id *)
let find_listing_image (html : string) (rel_link : string) (item_id : string) :
    string option =
  try
    (* 1ª tentativa: achar <a href="rel_link"> ... <img src="..."> *)
    let from_link =
      if rel_link <> "" then (
        let escaped = Re.Pcre.quote rel_link in
        let pattern =
          Printf.sprintf
            "<a[^>]+href=\"%s\".*?<img[^>]+src=\"([^\"]+)\"" escaped
        in
        let re =
          Re.Pcre.regexp ~flags:[ `DOTALL; `CASELESS ] pattern
        in
        match Re.exec_opt re html with
        | Some g -> Some (Re.Group.get g 1)
        | None -> None
      ) else
        None
    in
    match from_link with
    | Some _ as img -> img
    | None ->
        (* 2ª tentativa: fallback por item_id – procura item_id e depois <img> perto *)
        if item_id <> "" then (
          let escaped_id = Re.Pcre.quote item_id in
          let pattern =
            Printf.sprintf
              "%s.{0,800}?<img[^>]+src=\"([^\"]+)\"" escaped_id
          in
          let re =
            Re.Pcre.regexp ~flags:[ `DOTALL; `CASELESS ] pattern
          in
          match Re.exec_opt re html with
          | Some g -> Some (Re.Group.get g 1)
          | None -> None
        ) else
          None
  with _ -> None

let parse_price_from_detail html =
  try
    let re =
      Re.Pcre.regexp
        ~flags:[ `DOTALL; `CASELESS ]
        "<h2[^>]*class=\"[^\"]*preco[^\"]*\"[^>]*>\\s*([^<]+)\\s*</h2>"
    in
    match Re.exec_opt re html with
    | Some g ->
        let price = Re.Group.get g 1 |> String.trim in
        if price <> "" then Some price else None
    | None -> None
  with _ -> None

let parse_km_from_detail html =
  try
    let re =
      Re.Pcre.regexp
        ~flags:[ `DOTALL; `CASELESS ]
        "<li[^>]*>\\s*<h6>\\s*Km\\s*</h6>.*?<span[^>]*class=\"[^\"]*destaque[^\"]*\"[^>]*>\\s*([^<]+)\\s*</span>"
    in
    match Re.exec_opt re html with
    | Some g ->
        let km = Re.Group.get g 1 |> String.trim in
        if km <> "" then Some km else None
    | None -> None
  with _ -> None

let parse_fuel_from_detail html =
  try
    let re =
      Re.Pcre.regexp
        ~flags:[ `DOTALL; `CASELESS ]
        "<li[^>]*>\\s*<span[^>]*class=\"[^\"]*icone-carro-info[^\"]*\"[^>]*>\\s*</span>\\s*<p[^>]*>\\s*([^<]+?)\\s*</p>"
    in
    match Re.exec_opt re html with
    | Some g ->
        let text =
          Re.Group.get g 1
          |> Str.global_replace (Str.regexp "\\s+") " "
        in
        let fuel =
          match String.index_opt text ',' with
          | Some i -> String.sub text 0 i
          | None -> text
        in
        let fuel = String.trim fuel in
        if fuel <> "" then Some fuel else None
    | None -> None
  with _ -> None

(* Mesma heurística do Python: km “zerado”/inválido *)
let is_zero_km_value = function
  | None -> true
  | Some s ->
      let s = String.lowercase_ascii (String.trim s) in
      s = ""
      || s = "0"
      || s = "0 km"
      || s = "0km"
      || s = "0 km/h"
      || s = "0km/h"

(* Busca detalhes do anúncio.
   Igual ao Python: só é chamado quando necessário (need_detail) *)
let fetch_detail_info detail_url =
  http_get_icarros detail_url >>= function
  | Error msg -> Lwt.return_error msg
  | Ok (200, html) ->
      let no_photos =
        let re =
          Re.Pcre.regexp ~flags:[ `CASELESS ] "anúncio sem fotos"
        in
        Re.execp re html
      in
      if no_photos then (
        Logs.info (fun m ->
            m "[iCarros] Ignorando anúncio sem fotos: %s" detail_url);
        Lwt.return_ok (None, None, None, true))
      else
        let price = parse_price_from_detail html in
        let km = parse_km_from_detail html in
        let fuel = parse_fuel_from_detail html in
        Lwt.return_ok (price, km, fuel, false)
  | Ok (code, _) ->
      Logs.warn (fun m ->
          m "[iCarros] Falha ao buscar detalhes (%d): %s" code
            detail_url);
      Lwt.return_ok (None, None, None, false)

let normalize_item (item_dict : (string * string) list) (html : string) :
    vehicle option Lwt.t =
  try
    let get_field key = List.assoc_opt key item_dict in
    let get_field_default key default =
      match get_field key with Some v when v <> "" -> v | _ -> default
    in

    let item_id = get_field_default "item_id" "" in
    if item_id = "" then Lwt.return_none
    else
      let rel_link = get_field_default "link" "" in
      let detail_url =
        if rel_link <> "" && rel_link.[0] = '/' then
          base_url ^ rel_link
        else if rel_link <> "" then
          rel_link
        else
          ""
      in

      let listing_image = find_listing_image html rel_link item_id in

      (* KM da listagem *)
      let km_raw =
        match get_field "km" with
        | Some v -> Some v
        | None -> (
            match get_field "item_km" with
            | Some v -> Some v
            | None -> get_field "kilometragem")
      in

      let price = get_field "price" in
      let fuel_raw =
        match get_field "combustivel" with
        | Some v -> Some v
        | None -> get_field "item_combustivel"
      in

      (* Igual ao Python: só PRECISAMOS dos detalhes pra preço/km quando: *)
      let need_detail =
        let price_empty =
          match price with
          | None -> true
          | Some p -> String.trim p = ""
        in
        price_empty || is_zero_km_value km_raw
      in

      (* DIFERENÇA PRO PYTHON:
         - aqui a gente SEMPRE chama fetch_detail_info se tiver detail_url,
           pra poder detectar "anúncio sem fotos" em todos os casos. *)
      let%lwt detail_result =
        if detail_url <> "" then (
          Logs.debug (fun m ->
              m "[iCarros] Fetching detail page para item_id=%s: %s"
                item_id detail_url);
          fetch_detail_info detail_url
        ) else
          Lwt.return_ok (None, None, None, false)
      in

      let (detail_price, detail_km, detail_fuel, no_photos) =
        match detail_result with
        | Ok t -> t
        | Error _ -> (None, None, None, false)
      in

      if no_photos then
        (* sempre ignora anúncio “sem fotos”, mesmo se price/km já estiverem ok *)
        Lwt.return_none
      else (
        (* Completa preço / km / combustível SOMENTE se precisar *)
        let final_price =
          if need_detail then
            match price, detail_price with
            | Some p, _ when String.trim p <> "" -> p
            | _, Some p -> p
            | _ -> ""
          else
            (* não preciso mexer, uso o que já veio da listagem *)
            match price with Some p -> p | None -> ""
        in

        let final_km =
          if need_detail && is_zero_km_value km_raw then
            match detail_km with
            | Some k -> k
            | None -> "0"
          else
            match km_raw with
            | Some k -> k
            | None -> "0"
        in

        let final_fuel =
          match fuel_raw, detail_fuel with
          | Some f, _ when String.trim f <> "" -> Some f
          | _, Some f -> Some f
          | _ -> None
        in

        Logs.debug (fun m ->
            m "[iCarros] Detalhes item %s: price=%s km=%s fuel=%s"
              item_id
              (match detail_price with
              | Some p -> p
              | None -> "None")
              (match detail_km with
              | Some k -> k
              | None -> "None")
              (match detail_fuel with
              | Some f -> f
              | None -> "None"));

        let brand = get_field_default "item_brand" "" in
        let model =
          match get_field "item_name" with
          | Some m -> m
          | None -> get_field_default "titulo" ""
        in
        let year_str = get_field_default "item_variant" "" in
        let year =
          try
            Some
              (year_str
              |> String.split_on_char '.'
              |> List.hd |> int_of_string)
          with _ -> None
        in

        let description_raw = get_field_default "description" "" in
        let seller_name = get_field "nomeVendedor" in

        let description_parts = ref [] in
        if description_raw <> "" then
          description_parts := description_raw :: !description_parts;
        (match seller_name with
        | Some s when s <> "" ->
            description_parts :=
              Printf.sprintf "Anunciante: %s" s :: !description_parts
        | _ -> ());
        let description = String.concat "\n" (List.rev !description_parts) in

        let color = get_field "cor" in
        let transmission = get_field "cambio" in
        let city = get_field "item_category4" in
        let state = get_field "item_category3" in

        Lwt.return_some
          {
            brand;
            model;
            year;
            price = format_price final_price;
            mileage = format_mileage final_km;
            city;
            state;
            fuel_type = final_fuel;
            transmission;
            color;
            image_url = listing_image;
            detail_url;
            source = "icarros";
            external_id = Some (Printf.sprintf "icarros-%s" item_id);
            description =
              (if description <> "" then Some description else None);
          })
  with exn ->
    Logs.err (fun m ->
        m "[iCarros] Exception em normalize_item: %s"
          (Printexc.to_string exn));
    Lwt.return_none

(* Busca e normaliza uma página de resultados.
   Se não encontrar o bloco anuncios = { items: [...] }, retorna Error "NO_ANUNCIOS" *)
let fetch_page brand_slug model_slug page =
  let url =
    Printf.sprintf "%s/comprar/%s/%s" base_url brand_slug model_slug
  in
  let params =
    if page > 1 then [ ("pagina", string_of_int page) ] else []
  in
  let uri = Uri.add_query_params' (Uri.of_string url) params in
  let url_str = Uri.to_string uri in

  Logs.info (fun m -> m "[iCarros] Fetching page %d: %s" page url_str);

  http_get_icarros url_str >>= function
  | Error msg -> Lwt.return_error msg
  | Ok (404, _) ->
      Logs.info (fun m ->
          m "[iCarros] 404 na página %d, parando." page);
      Lwt.return_ok []
  | Ok (200, html) -> (
      match parse_anuncios_items html with
      | Error msg -> Lwt.return_error msg
      | Ok items ->
          let%lwt vehicles =
            Lwt_list.filter_map_p
              (fun item_dict -> normalize_item item_dict html)
              items
          in
          Lwt.return_ok vehicles)
  | Ok (code, _) ->
      Lwt.return_error (Printf.sprintf "HTTP %d" code)

let scrape brand model =
  Logs.info (fun m ->
      m "Starting iCarros scrape for %s %s" brand model);

  let brand_slug = slugify brand in
  let model_slug = slugify model in
  let seen_ids = ref [] in
  let all_vehicles = ref [] in
  let page = ref 1 in
  let pages_processed = ref 0 in

  (* zero_page_streak = n páginas consecutivas com 0 anúncios novos *)
  let rec fetch_pages zero_page_streak =
    (* Tentativa da MESMA página, com re-tentativas conforme:
       - NO_ANUNCIOS: 3 tentativas (5s, 10s)
       - 0 anúncios novos: 2 tentativas (3s e depois segue regra de streak) *)
    let rec handle_page attempt zero_page_streak =
      let%lwt result = fetch_page brand_slug model_slug !page in
      match result with
      | Error msg when msg = "NO_ANUNCIOS" ->
          (* Análoga ao Python: 3 tentativas na mesma página *)
          if attempt = 1 then (
            Logs.warn (fun m ->
                m
                  "[iCarros] Não encontrei bloco 'anuncios' na página \
                   %d. Aguardando 5s e tentando novamente..."
                  !page);
            let%lwt () = Lwt_unix.sleep 5.0 in
            handle_page 2 zero_page_streak)
          else if attempt = 2 then (
            Logs.warn (fun m ->
                m
                  "[iCarros] Ainda sem bloco 'anuncios' na página %d \
                   após nova tentativa. Aguardando 10s e tentando \
                   última vez..."
                  !page);
            let%lwt () = Lwt_unix.sleep 10.0 in
            handle_page 3 zero_page_streak)
          else (
            Logs.err (fun m ->
                m
                  "[iCarros] Não encontrei bloco 'anuncios' na página \
                   %d após 3 tentativas. Encerrando paginação."
                  !page);
            Lwt.return_unit)
      | Error msg ->
          Logs.err (fun m ->
              m "[iCarros] Erro buscando página %d: %s" !page msg);
          Lwt.return_unit
      | Ok vehicles ->
          (* Dedup e contagem de anúncios novos *)
          let count_page = ref 0 in
          let page_cars = ref [] in

          let new_vehicles =
            List.filter
              (fun v ->
                match v.external_id with
                | Some id when not (List.mem id !seen_ids) ->
                    seen_ids := id :: !seen_ids;
                    incr count_page;
                    page_cars := v :: !page_cars;
                    true
                | _ -> false)
              vehicles
          in

          all_vehicles := new_vehicles @ !all_vehicles;

          if !count_page > 0 then (
            (* Log igual ao Python: printa alguns exemplos *)
            let summary =
              !page_cars
              |> List.rev
              |> take (min 10 (List.length !page_cars))
              |> List.map (fun v ->
                     Printf.sprintf "%s:%s %s"
                       (Option.value ~default:"" v.external_id)
                       (String.trim v.brand)
                       (String.trim v.model))
              |> String.concat ", "
            in
            Logs.info (fun m ->
                m
                  "[iCarros] Página %d: %d anúncios novos. Exemplos: \
                   %s"
                  !page !count_page summary);

            (* Reseta streak de páginas zeradas *)
            let zero_page_streak = 0 in

            incr pages_processed;
            incr page;

            (* Delay a cada 3 páginas processadas (similar ao Python) *)
            let%lwt () =
              if !pages_processed mod 3 = 0 then
                Lwt_unix.sleep 1.0
              else
                Lwt.return_unit
            in
            fetch_pages zero_page_streak)
          else
            (* count_page = 0: comportamento alinhado ao Python:
               - 1ª vez: espera 3s e tenta mesma página
               - 2ª vez: incrementa streak; se streak >= 2, encerra;
                         senão espera 1.5s e vai para próxima página *)
            if attempt = 1 then (
              Logs.info (fun m ->
                  m
                    "[iCarros] Página %d: 0 anúncios novos. \
                     Aguardando 3s e tentando novamente na mesma \
                     página..."
                    !page);
              let%lwt () = Lwt_unix.sleep 3.0 in
              handle_page 2 zero_page_streak)
            else
              let zero_page_streak = zero_page_streak + 1 in
              if zero_page_streak >= 2 then (
                Logs.info (fun m ->
                    m
                      "[iCarros] Duas páginas consecutivas sem novos \
                       anúncios. Encerrando pesquisa.");
                Lwt.return_unit)
              else (
                Logs.info (fun m ->
                    m
                      "[iCarros] Página %d segue sem novos anúncios. \
                       Aguardando 1.5s e avançando para a próxima \
                       página..."
                      !page);
                let%lwt () = Lwt_unix.sleep 1.5 in
                incr page;
                fetch_pages zero_page_streak)
    in

    handle_page 1 zero_page_streak
  in

  let%lwt () = fetch_pages 0 in

  Logs.info (fun m ->
      m "[iCarros] Total de veículos coletados: %d"
        (List.length !all_vehicles));
  Lwt.return_ok (List.rev !all_vehicles)
