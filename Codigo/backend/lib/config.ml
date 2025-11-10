(* Configuration module for BusCars Backend *)

(* Database configuration *)
let postgres_host = 
  try Sys.getenv "POSTGRES_HOST" 
  with Not_found -> "localhost"

let postgres_port = 
  try Sys.getenv "POSTGRES_PORT" 
  with Not_found -> "5432"

let postgres_db = 
  try Sys.getenv "POSTGRES_DB" 
  with Not_found -> "buscar"

let postgres_user = 
  try Sys.getenv "POSTGRES_USER" 
  with Not_found -> "buscar_user"

let postgres_password = 
  try Sys.getenv "POSTGRES_PASSWORD" 
  with Not_found -> "buscar_password"

let database_url = 
  Printf.sprintf "postgresql://%s:%s@%s:%s/%s"
    postgres_user
    postgres_password
    postgres_host
    postgres_port
    postgres_db

(* Redis configuration *)
let redis_host = 
  try Sys.getenv "REDIS_HOST" 
  with Not_found -> "localhost"

let redis_port = 
  try int_of_string (Sys.getenv "REDIS_PORT")
  with Not_found -> 6379

let redis_db = 
  try int_of_string (Sys.getenv "REDIS_DB")
  with Not_found -> 0

(* Cache TTL (time to live) in seconds *)
let cache_ttl_vehicle_detail = 300  (* 5 minutes *)
let cache_ttl_vehicle_list = 60     (* 1 minute *)
let cache_ttl_user = 600            (* 10 minutes *)

(* Server configuration *)
let server_host = 
  try Sys.getenv "SERVER_HOST" 
  with Not_found -> "0.0.0.0"

let server_port = 
  try int_of_string (Sys.getenv "SERVER_PORT")
  with Not_found -> 3000

(* Session configuration *)
let session_duration_days = 30
let session_secret = 
  try Sys.getenv "SESSION_SECRET"
  with Not_found -> "change-me-in-production-please"

(* Pagination defaults *)
let default_page_size = 20
let max_page_size = 100

(* CORS configuration *)
let cors_allowed_origins = [
  "http://localhost:8080";
  "http://localhost:3000";
]

let cors_allowed_methods = ["GET"; "POST"; "PUT"; "DELETE"; "OPTIONS"]
let cors_allowed_headers = ["Content-Type"; "Authorization"; "X-Requested-With"]

