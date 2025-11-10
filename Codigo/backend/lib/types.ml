(* Core type definitions for BusCars Backend *)

(* Vehicle type matching frontend structure *)
type vehicle = {
  id: int;
  slug: string;
  brand: string;
  model: string;
  year: int;
  price: string;
  mileage: string;
  fuel_type: string;
  color: string;
  transmission: string;
  description: string;
  image: string;
  images: string list;
  seller_id: int;
  seller_name: string;
  seller_phone: string;
  seller_email: string;
  condition: string; (* "used" or "new" *)
  source: string; (* "buscar" for our own, "webmotors", etc. *)
  engine: string option [@default None];
  doors: int [@default 4];
  body_style: string option [@default None];
  features: string list [@default []];
  detailed_description_md: string option [@default None];
  
  (* Additional detailed fields *)
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
  location_city: string;
  location_state: string;
  financing_available: bool;
  trade_accepted: bool;
  test_drive_available: bool;
  
  (* Metadata *)
  created_at: string [@default ""];
  updated_at: string [@default ""];
  is_active: bool [@default true];
  deleted_at: string option [@default None];
  views_count: int [@default 0];
  favorites_count: int [@default 0];
  
  (* Audit/Immutability fields *)
  created_by: int option [@default None];
  updated_by: int option [@default None];
  original_id: int option [@default None];
  version: int [@default 1];
} [@@deriving yojson]

(* User type *)
type user = {
  user_id: int;
  name: string;
  email: string;
  password_hash: string;
  phone: string option;
  created_at: string;
  updated_at: string;
  is_active: bool;
  is_verified: bool;
  subscription_tier: string; (* "individual", "professional", "business" *)
} [@@deriving yojson]

(* Session type *)
type session = {
  session_id: string;
  user_id: int;
  created_at: string;
  expires_at: string;
  last_activity: string;
} [@@deriving yojson]

(* API request/response types *)
type login_request = {
  email: string;
  password: string;
} [@@deriving yojson]

type login_response = {
  success: bool;
  message: string;
  session_id: string option;
  user: user option;
} [@@deriving yojson]

type vehicle_filter = {
  brand: string option;
  model: string option;
  year_min: int option;
  year_max: int option;
  price_min: int option;
  price_max: int option;
  fuel_type: string option;
  condition: string option;
  source: string option;
  location_state: string option;
  page: int;
  per_page: int;
  sort_by: string option; (* "price_asc", "price_desc", "year_desc", etc *)
} [@@deriving yojson]

type vehicle_list_response = {
  vehicles: vehicle list;
  total_count: int;
  page: int;
  total_pages: int;
  has_next: bool;
  has_prev: bool;
} [@@deriving yojson]

type api_response = {
  success: bool;
  message: string;
  data: Yojson.Safe.t option;
} [@@deriving yojson]

(* Create vehicle request *)
type create_vehicle_request = {
  brand: string;
  model: string;
  year: int;
  price: string;
  mileage: string;
  fuel_type: string;
  color: string;
  transmission: string;
  description: string;
  image: string;
  images: string list [@default []];
  condition: string;
  engine: string option [@default None];
  doors: int [@default 4];
  body_style: string option [@default None];
  features: string list [@default []];
  location_city: string;
  location_state: string;
} [@@deriving yojson]

