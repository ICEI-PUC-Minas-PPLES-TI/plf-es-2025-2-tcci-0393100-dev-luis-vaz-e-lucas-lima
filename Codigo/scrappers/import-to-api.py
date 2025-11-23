#!/usr/bin/env python3
"""Bulk importer that posts scraped listings into the BusCars backend API."""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import codecs
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

import requests

LOG = logging.getLogger("import-to-api")


# -----------------------------------------------------------------------------
# Utility helpers
# -----------------------------------------------------------------------------


def decode_unicode_escapes(value: Any) -> Any:
    """Recursively decode Unicode escape sequences in strings.
    
    Handles strings that contain literal Unicode escape sequences like \\u00e3.
    """
    if isinstance(value, str):
        # Check if string contains Unicode escape sequences (literal backslash-u)
        if '\\u' in value:
            try:
                # Decode Unicode escapes like \u00e3 to actual characters
                # Using encode('latin1').decode('unicode_escape') to handle properly
                decoded = value.encode('latin1').decode('unicode_escape')
                # If the decoded string is different and valid, use it
                if decoded != value:
                    return decoded
            except (UnicodeDecodeError, UnicodeError, UnicodeEncodeError, ValueError):
                # If decoding fails, return original value
                pass
        return value
    elif isinstance(value, dict):
        return {k: decode_unicode_escapes(v) for k, v in value.items()}
    elif isinstance(value, list):
        return [decode_unicode_escapes(item) for item in value]
    else:
        return value


def format_price(value: Any) -> str:
    """Return a display-friendly BRL string for either numeric or textual input."""
    if isinstance(value, (int, float)):
        formatted = f"R$ {value:,.2f}"
        return formatted.replace(",", "X").replace(".", ",").replace("X", ".")
    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return "Preço sob consulta"
        # Remove any existing "R$" (with or without spaces) to avoid duplication
        cleaned = re.sub(r'^R\$\s*', '', stripped, flags=re.IGNORECASE).strip()
        if not cleaned:
            return "Preço sob consulta"
        return f"{cleaned}"
    return "Preço sob consulta"


def format_mileage(value: Any) -> str:
    if value is None:
        return "0 km"
    try:
        # If it's already a number, use it directly
        if isinstance(value, (int, float)):
            number = int(value)
        else:
            # If it's a string, remove dots (thousands separator) and commas (decimal separator)
            # then convert to int
            cleaned = str(value).strip().replace(".", "").replace(",", "")
            number = int(float(cleaned)) if cleaned else 0
        # Format with dot as thousands separator
        formatted = f"{number:,}".replace(",", ".")
        return f"{formatted} km"
    except (ValueError, TypeError):
        if isinstance(value, str) and value.strip():
            # If it's already a formatted string like "65.000 km", return as is
            return value.strip()
        return "0 km"


def to_title(value: Optional[str]) -> str:
    if not value:
        return ""
    return " ".join(part.capitalize() for part in value.split())


def normalize_brand(value: Optional[str]) -> str:
    if not value:
        return ""
    return value.strip()


def extract_state(raw: Optional[str]) -> str:
    if not raw:
        return ""
    match = re.search(r"\(([A-Z]{2})\)", raw)
    if match:
        return match.group(1)
    raw = raw.strip()
    if len(raw) == 2 and raw.isalpha():
        return raw.upper()
    parts = raw.replace("/", " ").split()
    for part in reversed(parts):
        if len(part) == 2 and part.isalpha():
            return part.upper()
    return raw[-2:].upper()


def determine_condition(km_value: Optional[float]) -> str:
    if km_value is None:
        return "used"
    try:
        return "new" if float(km_value) <= 100 else "used"
    except (ValueError, TypeError):
        return "used"


# -----------------------------------------------------------------------------
# Payload builders per source
# -----------------------------------------------------------------------------


def build_payload_from_icarros(entry: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    brand = normalize_brand(entry.get("brand"))
    model = entry.get("model") or entry.get("title")
    year = entry.get("year_model")
    if not (brand and model and year):
        return None
    try:
        year_int = int(str(year).split(".")[0])
    except ValueError:
        return None

    condition = "new" if str(entry.get("is_zero_km", "")).lower() == "true" else "used"
    city = to_title(entry.get("city"))
    state = entry.get("state", "")

    price = format_price(entry.get("price") or "Preço sob consulta")
    description_parts = [entry.get("description", "").strip()]
    seller = entry.get("seller_name")
    if seller:
        description_parts.append(f"Anunciante: {seller}")
    #detail_url = entry.get("detail_url")
    #if detail_url:
    #    description_parts.append(f"Fonte: {detail_url}")

    detail_url = entry.get("detail_url", "")
    description = "\n".join(part for part in description_parts if part)
    external_id = f"icarros-{entry.get('id')}"
    km_val = entry.get("km")

    payload = {
        "brand": brand,
        "model": model.strip(),
        "year": year_int,
        "price": price,
        "mileage": format_mileage(km_val),
        "fuel_type": entry.get("fuel") or entry.get("fuel_type") or "Não informado",
        "color": to_title(entry.get("color")) or "Não informado",
        "transmission": to_title(entry.get("gearbox")) or "Não informado",
        "description": description or entry.get("title", ""),
        "image": entry.get("listing_image_url", ""),
        "images": [u for u in [entry.get("listing_image_url")] if u],
        "condition": condition,
        "location_city": city or "Não informado",
        "location_state": state or "",
        "source": entry.get("source", "icarros"),
        "external_id": external_id,
        "external_url": detail_url,
        "seller_name": entry.get("seller_name", "Parceiro iCarros"),
        "seller_phone": entry.get("seller_phone", ""),
        "seller_email": entry.get("seller_email", ""),
        "engine": None,
        "body_style": None,
        "features": [],
    }
    return payload


def build_payload_from_localiza(entry: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    brand = normalize_brand(entry.get("brand"))
    model_family = to_title(entry.get("model_family"))
    model_detail = to_title(entry.get("model"))
    year = entry.get("year_model")
    if not (brand and model_family and year):
        return None
    try:
        year_int = int(year)
    except ValueError:
        return None

    km_val = entry.get("km")
    description = (
        f"{model_family} {model_detail} {entry.get('year_model')}/{entry.get('year_fabrication')} "
        f"- {format_mileage(km_val)} - categoria {entry.get('category', 'N/D')}"
    )
    detail_url = entry.get("detail_url", "")
    external_id = f"localiza-{entry.get('id')}"

    payload = {
        "brand": brand,
        "model": f"{model_family} {model_detail}".strip(),
        "year": year_int,
        "price": format_price(entry.get("price")),
        "mileage": format_mileage(km_val),
        "fuel_type": entry.get("fuel", "Não informado"),
        "color": entry.get("color", "Não informado"),
        "transmission": entry.get("transmission", "Não informado"),
        "description": description,
        "image": entry.get("image_url", ""),
        "images": [u for u in [entry.get("image_url")] if u],
        "condition": determine_condition(km_val),
        "location_city": to_title(entry.get("city")),
        "location_state": entry.get("state", ""),
        "source": "localiza",
        "external_id": external_id,
        "external_url": detail_url,
        "seller_name": entry.get("seller_name", "Localiza Seminovos"),
        "seller_phone": entry.get("seller_phone", ""),
        "seller_email": entry.get("seller_email", ""),
        "engine": None,
        "body_style": entry.get("category"),
        "features": [],
    }
    return payload


def build_payload_from_webmotors(entry: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    brand = normalize_brand(entry.get("brand"))
    model = to_title(entry.get("model"))
    version = entry.get("version", "")
    if not (brand and model and entry.get("year_model")):
        return None
    try:
        year_int = int(float(entry.get("year_model")))
    except ValueError:
        return None

    km_val = entry.get("km")
    state = extract_state(entry.get("state"))
    city = to_title(entry.get("city"))
    price = entry.get("price")

    detail_url = entry.get("detail_url", "")
    description = f"{model} {version}".strip()
    if detail_url:
        description += f"\nAnúncio: {detail_url}"

    # Heuristic fuel/transmission detection
    version_upper = version.upper()
    if "HYBRID" in version_upper or "HIBR" in version_upper:
        fuel = "Híbrido"
    elif "FLEX" in version_upper:
        fuel = "Flex"
    else:
        fuel = "Não informado"

    if any(token in version_upper for token in ["AUT", "CVT", "DIRECT SHIFT"]):
        transmission = "Automático"
    else:
        transmission = "Manual/Outro"

    payload = {
        "brand": brand,
        "model": f"{model} {version}".strip(),
        "year": year_int,
        "price": format_price(price),
        "mileage": format_mileage(km_val),
        "fuel_type": fuel,
        "color": "Não informado",
        "transmission": transmission,
        "description": description,
        "image": entry.get("photo", ""),
        "images": [u for u in [entry.get("photo")] if u],
        "condition": determine_condition(km_val),
        "location_city": city or "Não informado",
        "location_state": state,
        "source": "webmotors",
        "external_id": f"webmotors-{entry.get('id')}",
        "external_url": detail_url,
        "seller_name": entry.get("seller_type", "Webmotors"),
        "seller_phone": "",
        "seller_email": "",
        "engine": None,
        "body_style": None,
        "features": [],
    }
    return payload


PARSERS = {
    "icarros": build_payload_from_icarros,
    "localiza": build_payload_from_localiza,
    "webmotors": build_payload_from_webmotors,
}


def detect_parser(sample: Dict[str, Any], fallback: str) -> str:
    if "source" in sample:
        src = str(sample["source"]).lower()
        if src in PARSERS:
            return src
    if "model_family" in sample:
        return "localiza"
    if "version" in sample and "seller_type" in sample:
        return "webmotors"
    return fallback


# -----------------------------------------------------------------------------
# Backend client
# -----------------------------------------------------------------------------


@dataclass
class BackendClient:
    base_url: str
    scraper_key: str
    session: requests.Session = requests.Session()

    def post_vehicle(self, vehicle: Dict[str, Any]) -> requests.Response:
        """Post vehicle using scraper endpoint with X-Scraper-Key authentication."""
        body = json.dumps(vehicle, ensure_ascii=False).encode("utf-8")
        headers = {
            "X-Scraper-Key": self.scraper_key,
            "Content-Type": "application/json; charset=utf-8",
        }

        response = self.session.post(
            f"{self.base_url}/api/vehicles/scraper",
            data=body,
            headers=headers,
            timeout=60,
        )
        return response

    def bulk_post_vehicles(self, vehicles: List[Dict[str, Any]]) -> requests.Response:
        """Post multiple vehicles using bulk scraper endpoint with X-Scraper-Key authentication."""
        body = json.dumps(vehicles, ensure_ascii=False).encode("utf-8")
        headers = {
            "X-Scraper-Key": self.scraper_key,
            "Content-Type": "application/json; charset=utf-8",
        }

        response = self.session.post(
            f"{self.base_url}/api/vehicles/scraper/bulk",
            data=body,
            headers=headers,
            timeout=120,
        )
        return response


# -----------------------------------------------------------------------------
# Main import flow
# -----------------------------------------------------------------------------


def iter_payloads(paths: Iterable[Path]) -> Iterable[Dict[str, Any]]:
    for path in paths:
        try:
            raw_text = path.read_text(encoding="utf-8")
            data = json.loads(raw_text)
            # Decode Unicode escapes in the loaded data
            data = decode_unicode_escapes(data)
        except OSError as exc:
            LOG.error("Failed to read %s: %s", path, exc)
            continue
        except json.JSONDecodeError as exc:
            LOG.error("Invalid JSON in %s: %s", path, exc)
            continue

        if not isinstance(data, list) or not data:
            LOG.warning("Skipping %s: empty or unsupported JSON structure", path)
            continue

        parser_key = detect_parser(data[0], fallback="icarros")
        parser = PARSERS.get(parser_key)
        if not parser:
            LOG.warning("No parser registered for %s (file %s)", parser_key, path)
            continue

        LOG.info("Processing %s entries from %s with parser '%s'", len(data), path, parser_key)
        for raw in data:
            payload = parser(raw)
            if payload is None:
                LOG.debug("Skipping record from %s due to missing critical data: %s", path, raw)
                continue
            yield payload


def run_import(files: List[Path], dry_run: bool = False) -> None:
    base_url = os.getenv("BACKEND_API_URL", "http://localhost:9004").rstrip("/")
    scraper_key = os.getenv("SCRAPER_KEY", os.getenv("CRON_JOB_KEY", "default-cron-key-change-me"))

    client = BackendClient(base_url=base_url, scraper_key=scraper_key)

    # Collect all payloads first
    all_payloads = list(iter_payloads(files))
    
    if not all_payloads:
        LOG.warning("No payloads to import")
        return

    if dry_run:
        LOG.info("[DRY-RUN] Prepared %d payloads", len(all_payloads))
        for payload in all_payloads:
            LOG.info("[DRY-RUN] Payload: %s", json.dumps(payload, ensure_ascii=False))
        return

    # Use bulk import with batches of 100
    batch_size = 100
    created, failed = 0, 0
    
    for i in range(0, len(all_payloads), batch_size):
        batch = all_payloads[i:i + batch_size]
        LOG.info("Importing batch of %d vehicles (batch %d/%d)", 
                 len(batch), (i // batch_size) + 1, (len(all_payloads) + batch_size - 1) // batch_size)
        
        try:
            resp = client.bulk_post_vehicles(batch)
        except Exception as exc:  # pylint: disable=broad-except
            LOG.error("Bulk import request failed: %s", exc)
            failed += len(batch)
            continue

        if resp.status_code >= 400:
            failed += len(batch)
            try:
                detail = resp.json()
            except ValueError:
                detail = resp.text
            LOG.error(
                "Backend rejected bulk import (%s): %s",
                resp.status_code,
                detail,
            )
        else:
            try:
                result = resp.json()
                # Try to extract imported_count from response
                if isinstance(result, dict):
                    data = result.get("data", {})
                    if isinstance(data, dict):
                        imported = data.get("imported_count", len(batch))
                    else:
                        imported = len(batch)
                else:
                    imported = len(batch)
                created += imported
                failed += (len(batch) - imported)
                LOG.info("Bulk import: %d/%d vehicles imported successfully", imported, len(batch))
            except (ValueError, KeyError, AttributeError):
                # If we can't parse the response, assume all succeeded
                created += len(batch)
                LOG.info("Bulk import completed (response: %s)", resp.text[:200])

    LOG.info("Import completed: %s created, %s failed", created, failed)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import scraped listings into BusCars.")
    parser.add_argument(
        "files",
        nargs="*",
        type=Path,
        default=[
            Path("last-out-icarros.json"),
            Path("last-out-localiza.json"),
            Path("last-out-webmotors.json"),
        ],
        help="JSON files exported by the scrapers.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Only print payloads, don't call the API.")
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Set logging verbosity.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    logging.basicConfig(level=getattr(logging, args.log_level), format="%(levelname)s - %(message)s")
    run_import(args.files, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
