(* Type definitions for scrapers - separate from main types to avoid circular dependency *)

type vehicle = {
  brand: string;
  model: string;
  year: int option [@default None];
  price: string;
  mileage: string;
  city: string option [@default None];
  state: string option [@default None];
  fuel_type: string option [@default None];
  transmission: string option [@default None];
  color: string option [@default None];
  image_url: string option [@default None];
  detail_url: string;
  source: string;
  external_id: string option [@default None];
  description: string option [@default None];
} [@@deriving yojson]
