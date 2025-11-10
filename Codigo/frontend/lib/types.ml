(* Type definitions for the BusCar application *)

type vehicle = {
  id: int;
  slug: string [@default ""];
  brand: string [@default ""];
  model: string [@default ""];
  year: int [@default 2020];
  price: string [@default "0"];
  mileage: string [@default "0"];
  fuel_type: string [@default "Gasolina"];
  color: string [@default ""];
  transmission: string [@default ""];
  description: string [@default ""];
  image: string [@default ""];
  images: string list [@default []];
  seller_id: int [@default 0];
  seller_name: string [@default ""];
  seller_phone: string [@default ""];
  seller_email: string [@default ""];
  condition: string [@default "used"];
  source: string [@default "buscar"];
  engine: string option [@default None];
  doors: int [@default 4];
  body_style: string option [@default None];
  features: string list [@default []];
  detailed_description_md: string option [@default None];
  vin: string option [@default None];
  license_plate: string option [@default None];
  previous_owners: int [@default 1];
  service_history: string list [@default []];
  modifications: string list [@default []];
  included_items: string list [@default []];
  exterior_condition: string option [@default None];
  interior_condition: string option [@default None];
  mechanical_condition: string option [@default None];
  inspection_notes: string option [@default None];
  location_city: string [@default ""];
  location_state: string [@default ""];
  financing_available: bool [@default false];
  trade_accepted: bool [@default false];
  test_drive_available: bool [@default false];
  created_at: string [@default ""];
  updated_at: string [@default ""];
  is_active: bool [@default true];
  deleted_at: string option [@default None];
  views_count: int [@default 0];
  favorites_count: int [@default 0];
  created_by: int option [@default None];
  updated_by: int option [@default None];
  original_id: int option [@default None];
  version: int [@default 1];
} [@@deriving yojson]

type user = {
  user_id: int;
  name: string;
  email: string;
} [@@deriving yojson]
