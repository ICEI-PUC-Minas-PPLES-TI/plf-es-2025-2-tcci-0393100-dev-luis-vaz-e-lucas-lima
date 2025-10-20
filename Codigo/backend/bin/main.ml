(* BusCar Backend Main Server *)
open Buscar_backend

(* Configuration from environment *)
let port = 
  match Sys.getenv_opt "PORT" with
  | Some p -> int_of_string p
  | None -> 3000

(* Initialize logging *)
let setup_logging () =
  Logs.set_level (Some Logs.Info);
  Printf.printf "BusCar Backend starting...\n%!"

(* Entry point *)
let () = 
  setup_logging ();
  Printf.printf "Starting BusCar API server on port %d\n%!" port;
  Printf.printf "Using mock data for development\n%!";
  
  Dream.run ~port ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router Api.api_routes
