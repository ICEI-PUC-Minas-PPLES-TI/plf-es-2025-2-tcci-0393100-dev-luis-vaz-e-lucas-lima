#!/usr/bin/env python3
import argparse
import time
import sys
import json
import re
import os
from datetime import datetime

import requests


BASE_URL = "https://www.icarros.com.br/comprar/{brand}/{model}"


def slugify(text: str) -> str:
    """
    Normaliza brand/model:
    - lowercase
    - strip
    - múltiplos espaços -> '-'
    """
    return "-".join(text.strip().lower().split())


def parse_anuncios_items(html: str) -> list[dict]:
    """
    Extrai a estrutura `anuncios = { items: [...] }` do HTML
    e converte em uma lista de dicts Python.

    Obs:
      - Existem blocos de template (dealInformation...) que vamos IGNORAR
        filtrando apenas itens cujo item_id seja numérico.
    """
    m = re.search(
        r"anuncios\s*=\s*\{\s*items\s*:\s*\[(.*?)]\s*\};",
        html,
        re.DOTALL,
    )
    if not m:
        print(
            "[iCarros] Não encontrei 'anuncios = { items: [...] }' no HTML.",
            file=sys.stderr,
        )
        return []

    items_block = m.group(1)
    objects = re.findall(r"\{(.*?)\}", items_block, re.DOTALL)
    results: list[dict] = []

    for obj_body in objects:
        item: dict = {}
        for raw_line in obj_body.splitlines():
            line = raw_line.strip().rstrip(",")
            if not line or ":" not in line:
                continue
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()

            if value.startswith("`") and value.endswith("`"):
                value = value[1:-1]
            elif value == "true":
                value = True
            elif value == "false":
                value = False
            elif value in ("null", "undefined"):
                value = None

            item[key] = value

        raw_id = item.get("item_id")
        if isinstance(raw_id, str) and raw_id.isdigit():
            results.append(item)

    print(f"[iCarros] parse_anuncios_items: {len(results)} itens válidos.", file=sys.stderr)
    return results


def find_listing_image(html: str, rel_link: str | None, item_id: str | None) -> str | None:
    """
    Tenta descobrir a URL da imagem de listagem a partir do HTML.
    """
    if rel_link:
        try:
            pattern = (
                r'<a[^>]+href="' + re.escape(rel_link) +
                r'".*?<img[^>]+src="([^"]+)"'
            )
            m = re.search(pattern, html, re.DOTALL | re.IGNORECASE)
            if m:
                return m.group(1)
        except re.error:
            pass

    if item_id:
        try:
            pattern = (
                r'(?:' + re.escape(item_id) + r').{0,800}?<img[^>]+src="([^"]+)"'
            )
            m = re.search(pattern, html, re.DOTALL | re.IGNORECASE)
            if m:
                return m.group(1)
        except re.error:
            pass

    return None


def parse_price_from_detail(html: str) -> str | None:
    """
    Extrai o preço da página de detalhes:
    <h2 class="preco">R$ ...</h2>
    """
    m = re.search(
        r'<h2[^>]*class="[^"]*\bpreco\b[^"]*"[^>]*>\s*([^<]+)\s*</h2>',
        html,
        re.IGNORECASE,
    )
    return m.group(1).strip() if m else None


def parse_km_from_detail(html: str) -> str | None:
    """
    Extrai a KM da página de detalhes, no bloco:

    <li>
      <h6>Km</h6>
      <span class="destaque">31.996 </span>
    </li>
    """
    m = re.search(
        r'<li[^>]*>\s*<h6>\s*Km\s*</h6>.*?<span[^>]*class="[^"]*\bdestaque\b[^"]*"[^>]*>\s*([^<]+)\s*</span>',
        html,
        re.IGNORECASE | re.DOTALL,
    )
    return m.group(1).strip() if m else None


def parse_fuel_from_detail(html: str) -> str | None:
    """
    Extrai o tipo de combustível da página de detalhes.

    Padrão observado:

    <ul class="listavertical">
      <li>
        <span class="icones icones_opcionais icone-carro-info"></span>
        <p>
            Gasolina,
            Final da placa 5
        </p>
      </li>
      ...
    </ul>

    Pegamos o texto do <p> desse <li> e usamos a parte
    antes da primeira vírgula como combustível.
    """
    m = re.search(
        r'<li[^>]*>\s*'
        r'<span[^>]*class="[^"]*\bicone-carro-info\b[^"]*"[^>]*>\s*</span>\s*'
        r'<p[^>]*>\s*([^<]+?)\s*</p>',
        html,
        re.IGNORECASE | re.DOTALL,
    )
    if not m:
        return None
    text = " ".join(m.group(1).split())
    return text.split(",", 1)[0].strip()


def fetch_detail_info(detail_url: str, headers: dict) -> dict:
    """
    Busca detalhes do anúncio.
    Agora também detecta se o anúncio é 'anúncio sem fotos'.
    """
    try:
        print(f"[iCarros] Fetching detail page: {detail_url}", file=sys.stderr)
        resp = requests.get(detail_url, headers=headers, timeout=20)
        resp.raise_for_status()
    except Exception as e:
        print(f"[iCarros] Erro ao buscar detalhes em detail_url={detail_url}: {e}", file=sys.stderr)
        return {"price": None, "km": None, "fuel": None, "no_photos": False}

    html = resp.text

    if re.search(r'anúncio sem fotos', html, re.IGNORECASE):
        print(f"[iCarros] Ignorando anúncio {detail_url} — anúncio sem fotos!", file=sys.stderr)
        return {"price": None, "km": None, "fuel": None, "no_photos": True}

    price = parse_price_from_detail(html)
    km = parse_km_from_detail(html)
    fuel = parse_fuel_from_detail(html)

    print(
        f"[iCarros] Detalhes carregados de {detail_url}: price={price} km={km} fuel={fuel}",
        file=sys.stderr,
    )

    return {"price": price, "km": km, "fuel": fuel, "no_photos": False}


def is_zero_km_value(km_value) -> bool:
    """
    Heurística simples pra saber se o valor vindo da listagem representa "zero KM"
    (ou valor inválido / vazio) e merece ser checado na página de detalhes.
    """
    if km_value is None:
        return True
    if isinstance(km_value, (int, float)):
        return km_value == 0
    if isinstance(km_value, str):
        return km_value.strip().lower() in ("", "0", "0 km", "0km", "0 km/h", "0km/h")
    return False


def scrape_icarros(
    brand: str,
    model: str,
    max_pages: int | None = None,
    delay: float = 1.0,
) -> list[dict]:
    print(f"[iCarros] Iniciando scrape para {brand} {model}", file=sys.stderr)

    brand_slug = slugify(brand)
    model_slug = slugify(model)
    headers = {"User-Agent": "Mozilla/5.0 (MVP-Scraper; +https://example.com)"}

    all_cars: list[dict] = []
    seen_ids: set[str] = set()
    page = 1
    pages_processed = 0
    zero_page_streak = 0
    stop_pagination = False

    while True:
        if max_pages is not None and page > max_pages:
            print("[iCarros] Atingiu max_pages, encerrando.", file=sys.stderr)
            break

        success_with_ads = False
        attempt = 1

        while True:
            url = BASE_URL.format(brand=brand_slug, model=model_slug)
            params = {"pagina": page} if page > 1 else {}

            if attempt == 1:
                print(f"[iCarros] Fetching page {page}: {url}", file=sys.stderr)
            else:
                print(
                    f"[iCarros] Re-tentando página {page} (tentativa {attempt})...",
                    file=sys.stderr,
                )

            resp = requests.get(url, params=params, headers=headers, timeout=20)

            if resp.status_code == 404:
                print("[iCarros] 404 recebido, encerrando paginação.", file=sys.stderr)
                stop_pagination = True
                break

            resp.raise_for_status()
            html = resp.text
            anuncios_items = parse_anuncios_items(html)

            if not anuncios_items:
                if attempt == 1:
                    print(
                        "[iCarros] Não encontrei 'anuncios = { items: [...] }' nessa página. "
                        "Aguardando 5s e tentando novamente na mesma página...",
                        file=sys.stderr,
                    )
                    time.sleep(5)
                    attempt = 2
                    continue
                elif attempt == 2:
                    print(
                        "[iCarros] Ainda não encontrei 'anuncios = { items: [...] }' "
                        "após nova tentativa. Aguardando 10s e tentando última vez "
                        "na mesma página...",
                        file=sys.stderr,
                    )
                    time.sleep(10)
                    attempt = 3
                    continue
                else:
                    print(
                        "[iCarros] Não encontrei 'anuncios = { items: [...] }' após 3 tentativas. "
                        "Encerrando paginação.",
                        file=sys.stderr,
                    )
                    stop_pagination = True
                    break

            count_page = 0
            page_cars: list[dict] = []

            for item in anuncios_items:
                item_id = item.get("item_id")
                if not item_id or item_id in seen_ids:
                    continue

                rel_link = item.get("link") or ""
                if rel_link and rel_link.startswith("/"):
                    detail_url = "https://www.icarros.com.br" + rel_link
                else:
                    detail_url = rel_link or None

                listing_image_url = find_listing_image(html, rel_link, item_id)

                km_raw = item.get("km") or item.get("item_km") or item.get("kilometragem")
                price = item.get("price")
                fuel_raw = item.get("combustivel") or item.get("item_combustivel")

                km = km_raw
                fuel = fuel_raw

                price_empty = price is None or price == ""
                need_detail = price_empty or is_zero_km_value(km)

                detail_info = {"price": None, "km": None, "fuel": None, "no_photos": False}

                if detail_url:
                    detail_info = fetch_detail_info(detail_url, headers=headers)

                    if detail_info.get("no_photos"):
                        print(
                            f"[iCarros] Anúncio {item_id} ignorado (sem fotos)",
                            file=sys.stderr,
                        )
                        continue

                if need_detail and price_empty and detail_info.get("price"):
                    print(
                        f"[iCarros] Completando preço do item {item_id} a partir da página de detalhes.",
                        file=sys.stderr,
                    )
                    price = detail_info["price"]

                if need_detail and is_zero_km_value(km) and detail_info.get("km"):
                    print(
                        f"[iCarros] Completando KM do item {item_id} a partir da página de detalhes.",
                        file=sys.stderr,
                    )
                    km = detail_info["km"]

                if not fuel and detail_info.get("fuel"):
                    print(
                        f"[iCarros] Completando combustível do item {item_id} a partir da página de detalhes.",
                        file=sys.stderr,
                    )
                    fuel = detail_info["fuel"]

                car = {
                    "source": "icarros",
                    "id": item_id,
                    "brand": item.get("item_brand"),
                    "model": item.get("item_name"),
                    "title": item.get("titulo"),
                    "year_model": item.get("item_variant"),
                    "is_zero_km": item.get("isZeroKm"),
                    "gearbox": item.get("cambio"),
                    "color": item.get("cor"),
                    "description": item.get("description"),
                    "price": price,
                    "km": km,
                    "fuel": fuel,
                    "seller_name": item.get("nomeVendedor"),
                    "city": item.get("item_category4"),
                    "state": item.get("item_category3"),
                    "detail_url": detail_url,
                    "listing_image_url": listing_image_url,
                    "has_whatsapp": item.get("hasWhatsApp"),
                    "whatsapp_type": item.get("whatsappType"),
                    "super_offer": item.get("superOffer"),
                }

                seen_ids.add(item_id)
                all_cars.append(car)
                page_cars.append(car)
                count_page += 1

            if count_page > 0:
                summary = ", ".join(
                    f"{c['id']}:{(c['brand'] or '').strip()} {(c['model'] or '').strip()}"
                    for c in page_cars[:10]
                )
                print(
                    f"[iCarros] Página {page}: {count_page} anúncios novos. Exemplos: {summary}",
                    file=sys.stderr,
                )
                success_with_ads = True
                zero_page_streak = 0
                pages_processed += 1
                break

            # count_page == 0
            if attempt == 1:
                print(
                    f"[iCarros] Página {page}: 0 anúncios novos. "
                    "Aguardando 3s e tentando novamente na mesma página...",
                    file=sys.stderr,
                )
                time.sleep(3)
                attempt = 2
                continue
            else:
                print(
                    f"[iCarros] Página {page}: 0 anúncios novos mesmo após nova tentativa.",
                    file=sys.stderr,
                )
                zero_page_streak += 1
                break

        if stop_pagination:
            print("[iCarros] stop_pagination=True, encerrando loop principal.", file=sys.stderr)
            break

        if success_with_ads:
            page += 1
            if delay > 0 and pages_processed % 3 == 0:
                print(
                    f"[iCarros] Delay de {delay}s após {pages_processed} páginas processadas.",
                    file=sys.stderr,
                )
                time.sleep(delay)
            continue

        if zero_page_streak >= 2:
            print(
                "[iCarros] Duas páginas consecutivas sem novos anúncios. Encerrando pesquisa.",
                file=sys.stderr,
            )
            break

        print(
            f"[iCarros] Página {page} segue sem novos anúncios. "
            "Aguardando 1.5s e avançando para a próxima página...",
            file=sys.stderr,
        )
        time.sleep(1.5)
        page += 1

    print(f"[iCarros] Total de anúncios coletados: {len(all_cars)}", file=sys.stderr)
    return all_cars


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scraper simples de anúncios do iCarros usando anuncios.items."
    )
    parser.add_argument("--brand", required=True, help='Marca, ex: "Toyota"')
    parser.add_argument("--model", required=True, help='Modelo, ex: "Corolla Cross"')
    parser.add_argument("--max-pages", type=int, default=None)
    parser.add_argument("--delay", type=float, default=1.0)

    args = parser.parse_args()

    cars = scrape_icarros(
        brand=args.brand,
        model=args.model,
        max_pages=args.max_pages,
        delay=args.delay,
    )

    output_dir = "output-icarros"
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    brand_slug = slugify(args.brand)
    model_slug = slugify(args.model)

    dated_path = os.path.join(output_dir, f"{timestamp}-{brand_slug}-{model_slug}.json")
    with open(dated_path, "w", encoding="utf-8") as f:
        json.dump(cars, f, ensure_ascii=False, indent=2)

    with open("last-out-icarros.json", "w", encoding="utf-8") as f:
        json.dump(cars, f, ensure_ascii=False, indent=2)

    print(len(cars), "carros encontrados")
    print(json.dumps(cars[:3], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
