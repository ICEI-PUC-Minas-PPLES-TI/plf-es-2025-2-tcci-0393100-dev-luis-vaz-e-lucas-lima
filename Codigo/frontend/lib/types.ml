(* Type definitions for the BusCar application *)

type vehicle = {
  id: int;
  slug: string; (* URL-friendly slug *)
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
  images: string list; (* Multiple images for slideshow *)
  seller_name: string;
  seller_phone: string;
  seller_email: string;
  condition: string; (* "used" or "new" *)
  source: string; (* "buscar" for our own, "webmotors", etc. *)
  engine: string;
  doors: int;
  body_style: string;
  features: string list;
  detailed_description_md: string; (* Markdown supported *)
  
  (* Additional detailed fields for BusCars listings *)
  vin: string option;
  license_plate: string option;
  previous_owners: int;
  service_history: string list;
  modifications: string list;
  included_items: string list;
  exterior_condition: string; (* "Excellent", "Good", "Fair", etc. *)
  interior_condition: string;
  mechanical_condition: string;
  inspection_notes: string;
  location_city: string;
  location_state: string;
  financing_available: bool;
  trade_accepted: bool;
  test_drive_available: bool;
}

type user = {
  user_id: int;
  name: string;
  email: string;
}
