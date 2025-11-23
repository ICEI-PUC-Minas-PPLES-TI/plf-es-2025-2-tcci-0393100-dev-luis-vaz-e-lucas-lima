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
  seller_id: int option [@default None];
  seller_name: string;
  seller_phone: string;
  seller_email: string;
  condition: string; (* "used" or "new" *)
  source: string; (* "buscar" for our own, "webmotors", etc. *)
  external_id: string option [@default None];
  external_url: string option [@default None];
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

(* Scraper job type *)
type scraper_job = {
  scraper_job_id: int;
  brand: string;
  model: string;
  source: string; (* "localiza", "icarros", "webmotors" *)
  is_active: bool;
  last_run_at: string option [@default None];
  next_run_at: string option [@default None];
  run_count: int;
  success_count: int;
  error_count: int;
  last_error: string option [@default None];
  created_at: string;
  updated_at: string;
  created_by_user_id: int option [@default None];
} [@@deriving yojson]

(* Scraper job filter type *)
type scraper_job_filter = {
  search: string option; (* Search by brand or model (name) *)
  source: string option; (* Filter by source/platform *)
  page: int;
  per_page: int;
} [@@deriving yojson]

(* Scraper job list response type *)
type scraper_job_list_response = {
  jobs: scraper_job list;
  total_count: int;
  page: int;
  total_pages: int;
  has_next: bool;
  has_prev: bool;
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
  location_city: string option;
  seller_id: int option [@default None];
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

(* FIPE API auxiliary types *)
type fipe_reference = {
  code: string;
  month: string;
} [@@deriving yojson]

type fipe_brand = {
  code: string;
  name: string;
} [@@deriving yojson]

type fipe_model = {
  code: string;
  name: string;
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

type api_response = {
  success: bool;
  message: string;
  data: Yojson.Safe.t option;
} [@@deriving yojson]

(* Registration request *)
type register_request = {
  name: string;
  email: string;
  password: string;
  phone: string;
  document_number: string;
  address_street: string;
  address_number: string;
  address_complement: string option [@default None];
  address_neighborhood: string;
  address_city: string;
  address_state: string;
  address_zipcode: string;
  referral_code: string;
} [@@deriving yojson]

(* Referral code type *)
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

type create_referral_code_request = {
  code: string option [@default None];
} [@@deriving yojson]

type distribute_referral_codes_request = {
  email: string option [@default None]; (* If None or "all", distribute to all users *)
  count: int [@default 1]; (* Number of codes to create per user *)
} [@@deriving yojson]

type change_password_request = {
  old_password: string;
  new_password: string;
} [@@deriving yojson]

type admin_update_user_request = {
  name: string;
  email: string;
  phone: string;
  document_number: string;
  address_street: string;
  address_number: string;
  address_complement: string option [@default None];
  address_neighborhood: string;
  address_city: string;
  address_state: string;
  address_zipcode: string;
} [@@deriving yojson]

type admin_change_user_password_request = {
  user_id: int;
  new_password: string;
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
  seller_name: string [@default ""];
  seller_phone: string [@default ""];
  seller_email: string [@default ""];
  source: string [@default "buscar"];
  external_id: string option [@default None];
  external_url: string option [@default None];
} [@@deriving yojson]

