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
  external_id: string option [@default None];
  external_url: string option [@default None];
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
  created_by: int option [@default None];
  updated_by: int option [@default None];
  original_id: int option [@default None];
  version: int [@default 1];
} [@@deriving yojson]

type user = {
  user_id: int;
  name: string;
  email: string;
  phone: string option [@default None];
  document_number: string option [@default None];
  address_street: string option [@default None];
  address_number: string option [@default None];
  address_complement: string option [@default None];
  address_neighborhood: string option [@default None];
  address_city: string option [@default None];
  address_state: string option [@default None];
  address_zipcode: string option [@default None];
  is_admin: bool [@default false];
  referred_by_code_id: int option [@default None];
  created_at: string [@default ""];
  updated_at: string [@default ""];
  is_active: bool [@default true];
  is_verified: bool [@default false];
  subscription_tier: string [@default "individual"];
} [@@deriving yojson]

type referral_code = {
  referral_code_id: int;
  code: string;
  created_by_user_id: int;
  created_at: string;
  is_active: bool;
  used_by_user_id: int option [@default None];
  used_by_user_name: string option [@default None];
  used_at: string option [@default None];
} [@@deriving yojson]

type fipe_brand = {
  code: string;
  name: string;
} [@@deriving yojson]

type fipe_model = {
  code: string;
  name: string;
} [@@deriving yojson]

type fipe_reference = {
  code: string;
  month: string;
} [@@deriving yojson]

type fipe_year = {
  code: string;
  name: string;
} [@@deriving yojson]

type fipe_price_history = {
  month: string;
  price: string;
  reference: string;
} [@@deriving yojson]

type fipe_vehicle_detail = {
  brand: string;
  codeFipe: string;
  fuel: string;
  fuelAcronym: string;
  model: string;
  modelYear: int;
  price: string;
  priceHistory: fipe_price_history list option [@default None];
  referenceMonth: string;
  vehicleType: int;
} [@@deriving yojson]

type vehicle_page = {
  vehicles: vehicle list;
  total_count: int;
  page: int;
  total_pages: int;
  has_next: bool;
  has_prev: bool;
}

type referral_codes_page = {
  codes: referral_code list;
  total_count: int;
  page: int;
  per_page: int;
  total_pages: int;
  has_next: bool;
  has_prev: bool;
} [@@deriving yojson]

type users_page = {
  users: user list;
  total_count: int;
  page: int;
  total_pages: int;
  has_next: bool;
  has_prev: bool;
} [@@deriving yojson]
