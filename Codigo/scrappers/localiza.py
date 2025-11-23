#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
import argparse
import unicodedata
import os
from datetime import datetime

BASE_URL = "https://seminovos.localiza.com"


def normalize(text: str) -> str:
    """
    Normaliza texto para URL da Localiza:
    - remove acentos
    - troca espaços por hífen
    - lowercase
    """
    text = text.strip().lower()

    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")

    return text.replace(" ", "-")


def _extract_products_from_html(html: str):
    soup = BeautifulSoup(html, "html.parser")
    script_tag = soup.find("script", id="__NEXT_DATA__")
    if not script_tag or not script_tag.string:
        raise RuntimeError("❌ Não encontrei o __NEXT_DATA__")

    data = json.loads(script_tag.string)
    page_props = data["props"]["pageProps"]

    products = page_props["products"]
    meta = page_props.get("_metadados") or {}
    total_pages = meta.get("_totalPaginas", 1)

    return products, total_pages


def _normalize_product(p: dict) -> dict:
    # Tentativas de pegar a cor da estrutura do produto.
    # Usamos .get() pra não quebrar caso algum campo não exista.
    color_description = (
        p.get("corDescricao")
        or p.get("corExternaDescricao")
        or p.get("corExternaDescricaoReduzida")
        or p.get("cor")
    )

    color_code = (
        p.get("corCodigo")
        or p.get("corExternaCodigo")
        or p.get("codigoCor")
    )

    return {
        "id": p["id"],
        "brand": p["marcaDescricao"],
        "model_family": p["modeloFamiliaDescricao"],
        "model": p["modeloDescricaoReduzida"],
        "year_model": p["anoModelo"],
        "year_fabrication": p["anoFabricacao"],
        "km": p["odometro"],
        "price": p["preco"],
        "city": p["cidadeDescricao"],
        "state": p["siglaEstado"],
        "category": p["categoriaDescricao"],
        "transmission": p["tipoTransmissaoDescricao"],
        "fuel": p["tipoCombustivelDescricao"],
        "image_url": p["fotoUrl"],
        "detail_url": p["pdpUrl"],
        # Novos campos de cor
        "color": color_description,
        "color_code": color_code,
    }


def scrape_localiza(brand: str, model: str, max_pages: int | None = None):
    session = requests.Session()
    headers = {"User-Agent": "Mozilla/5.0 (MVP-Scraper)"}

    cars: list[dict] = []

    brand_slug = normalize(brand)
    model_slug = normalize(model)

    # Página inicial
    url = f"{BASE_URL}/carros/{brand_slug}/{model_slug}"
    resp = session.get(url, headers=headers, timeout=20)
    resp.raise_for_status()

    products, total_pages = _extract_products_from_html(resp.text)
    cars.extend(_normalize_product(p) for p in products)

    if max_pages is not None:
        total_pages = min(total_pages, max_pages)

    # Paginação
    for page in range(2, total_pages + 1):
        page_url = f"{BASE_URL}/carros/{brand_slug}/{model_slug}?page={page}"

        resp = session.get(page_url, headers=headers, timeout=20)
        if resp.status_code == 404:
            break

        resp.raise_for_status()

        products, _ = _extract_products_from_html(resp.text)
        cars.extend(_normalize_product(p) for p in products)

    return cars


def main():
    parser = argparse.ArgumentParser(description="Scraper Localiza Seminovos (multi-page)")
    parser.add_argument("--brand", required=True, help="Brand name (ex: Toyota)")
    parser.add_argument("--model", required=True, help="Model name (ex: Corolla Cross)")
    parser.add_argument("--max-pages", type=int, default=None, help="Optional: limit number of pages")

    args = parser.parse_args()

    results = scrape_localiza(args.brand, args.model, args.max_pages)

    # ===============================
    # Persistência dos resultados
    # ===============================

    output_dir = "output-localiza"
    os.makedirs(output_dir, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    brand_slug = normalize(args.brand)
    model_slug = normalize(args.model)

    dated_filename = f"{timestamp}-{brand_slug}-{model_slug}.json"
    dated_path = os.path.join(output_dir, dated_filename)

    # Snapshot com timestamp
    with open(dated_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    # Última saída sobrescrita no root
    last_out_path = "last-out-localiza.json"
    with open(last_out_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    # Print básico pro usuário
    print(f"\nFound {len(results)} cars for {args.brand} {args.model}.\n")
    for car in results:
        print(car)


if __name__ == "__main__":
    main()
