(* Simplified types for backend *)

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
  seller_name: string;
  seller_phone: string;
  seller_email: string;
  condition: string;
  source: string;
  engine: string;
  doors: int;
  body_style: string;
  location_city: string;
  location_state: string;
  detailed_description_md: string;
  financing_available: bool;
  trade_accepted: bool;
  test_drive_available: bool;
}

type vehicle_image = {
  id: int;
  vehicle_id: int;
  image_url: string;
  alt_text: string;
  sort_order: int;
}

type vehicle_feature = {
  id: int;
  vehicle_id: int;
  feature_name: string;
  feature_value: string;
}

type service_record = {
  id: int;
  vehicle_id: int;
  service_date: string;
  service_type: string;
  description: string;
  mileage_at_service: string;
  cost: string;
  service_provider: string;
}

type user = {
  id: int;
  email: string;
  name: string;
}

type vehicle_filters = {
  brand: string option;
  model: string option;
  year_min: int option;
  price_max: int option;
  fuel_type: string option;
  condition: string option;
  source: string option;
  location_state: string option;
  page: int;
  limit: int;
  sort_by: string option;
}
