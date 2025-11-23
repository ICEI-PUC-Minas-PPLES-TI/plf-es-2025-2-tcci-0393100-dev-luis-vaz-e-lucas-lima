(* Type definitions for scraper jobs and vehicles *)

type scraper_job = {
  scraper_job_id: int;
  brand: string;
  model: string;
  source: string;
  is_active: bool [@default true];
  last_run_at: string option [@default None];
  next_run_at: string option [@default None];
  run_count: int [@default 0];
  success_count: int [@default 0];
  error_count: int [@default 0];
  last_error: string option [@default None];
  created_at: string;
  updated_at: string;
  created_by_user_id: int option [@default None];
} [@@deriving yojson]

type scraper_jobs_response = {
  success: bool;
  message: string;
  data: scraper_job list [@default []];
} [@@deriving yojson]

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

