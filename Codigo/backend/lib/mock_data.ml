(* Mock data for testing the backend API *)
open Simple_types

(* Sample vehicles for testing *)
let sample_vehicles = [
  {
    id = 1; slug = "porsche-911-carrera-2024-1"; brand = "Porsche"; model = "911 Carrera"; year = 2024; 
    price = "850.000"; mileage = "2.500"; fuel_type = "Gasolina"; color = "Azul Metálico"; 
    transmission = "Automática"; description = "Porsche 911 Carrera 2024, esportivo premium com apenas 2.500km";
    image = "https://placehold.co/800x600/1a202c/10b981?text=Porsche+911";
    seller_name = "BusCar Premium"; seller_phone = "(11) 99999-9999"; seller_email = "premium@buscar.com.br";
    condition = "new"; source = "buscar"; engine = "3.0L H6 Biturbo"; doors = 2; body_style = "Coupe";
    location_city = "São Paulo"; location_state = "SP";
    detailed_description_md = "# Porsche 911 Carrera 2024\n\n## Especificações Técnicas\n- Motor 3.0L H6 Biturbo\n- 385 cv de potência\n- Transmissão automática PDK de 8 velocidades\n- Tração traseira\n\n## Equipamentos\n- Sistema de navegação PCM\n- Bancos esportivos em couro\n- Sistema de som Bose\n- Controle de cruzeiro adaptativo\n- Freios cerâmicos PCCB";
    financing_available = true; trade_accepted = true; test_drive_available = true;
  };
  {
    id = 2; slug = "toyota-corolla-2023-2"; brand = "Toyota"; model = "Corolla"; year = 2023; 
    price = "120.000"; mileage = "15.000"; fuel_type = "Híbrido"; color = "Branco Pérola"; 
    transmission = "Automática"; description = "Toyota Corolla Híbrido 2023, economia e tecnologia";
    image = "https://placehold.co/800x600/1a202c/10b981?text=Toyota+Corolla";
    seller_name = "Maria Santos"; seller_phone = "(21) 77777-7777"; seller_email = "maria@email.com";
    condition = "used"; source = "buscar"; engine = "1.8L Híbrido"; doors = 4; body_style = "Sedan";
    location_city = "Rio de Janeiro"; location_state = "RJ";
    detailed_description_md = "# Toyota Corolla Híbrido 2023\n\n## Motor Híbrido\nCombinação de motor 1.8L a gasolina com motor elétrico, proporcionando excelente economia de combustível.\n\n## Tecnologia\n- Central multimídia com Android Auto e Apple CarPlay\n- Câmera de ré\n- Sensores de estacionamento\n- Controle de cruzeiro\n\n## Segurança\n- 7 airbags\n- Sistema Toyota Safety Sense\n- Controle de estabilidade\n- Freios ABS com EBD";
    financing_available = true; trade_accepted = false; test_drive_available = true;
  };
  {
    id = 3; slug = "bmw-x5-2023-3"; brand = "BMW"; model = "X5"; year = 2023; 
    price = "320.000"; mileage = "8.000"; fuel_type = "Gasolina"; color = "Preto"; 
    transmission = "Automática"; description = "BMW X5 xDrive 2023, SUV premium alemão";
    image = "https://placehold.co/800x600/1a202c/10b981?text=BMW+X5";
    seller_name = "João Silva"; seller_phone = "(11) 88888-8888"; seller_email = "joao@email.com";
    condition = "used"; source = "buscar"; engine = "3.0L I6 Turbo"; doors = 4; body_style = "SUV";
    location_city = "São Paulo"; location_state = "SP";
    detailed_description_md = "# BMW X5 xDrive 2023\n\n## Performance\nMotor 3.0L I6 turbo com 340 cv, tração integral xDrive e suspensão adaptativa.\n\n## Luxury Features\n- Bancos em couro Dakota perfurado\n- Teto solar panorâmico\n- Sistema de som Harman Kardon\n- Ar condicionado de 4 zonas\n- Câmeras 360°\n\n## Tecnologia\n- iDrive 7 com tela de 12.3\"\n- BMW Live Cockpit Professional\n- Wireless CarPlay\n- Heads-up Display\n- Assistente de estacionamento automático";
    financing_available = false; trade_accepted = true; test_drive_available = true;
  };
  {
    id = 4; slug = "volkswagen-gol-2022-4"; brand = "Volkswagen"; model = "Gol"; year = 2022; 
    price = "65.000"; mileage = "25.000"; fuel_type = "Flex"; color = "Prata"; 
    transmission = "Manual"; description = "Volkswagen Gol 2022, econômico e confiável";
    image = "https://placehold.co/800x600/1a202c/10b981?text=VW+Gol";
    seller_name = "Localiza Seminovos"; seller_phone = "(11) 55555-5555"; seller_email = "vendas@localiza.com";
    condition = "used"; source = "localiza"; engine = "1.0L MPI"; doors = 4; body_style = "Hatchback";
    location_city = "São Paulo"; location_state = "SP";
    detailed_description_md = "# Volkswagen Gol 2022\n\n## Economia\nMotor 1.0 MPI flex, ideal para cidade com baixo consumo de combustível.\n\n## Equipamentos\n- Direção elétrica\n- Ar condicionado\n- Vidros elétricos dianteiros\n- Trava elétrica\n- Som com Bluetooth\n\n## Características\n- Porta-malas de 285 litros\n- Computador de bordo\n- Freios ABS\n- Airbag duplo";
    financing_available = true; trade_accepted = false; test_drive_available = false;
  };
  {
    id = 5; slug = "honda-civic-2023-5"; brand = "Honda"; model = "Civic"; year = 2023; 
    price = "165.000"; mileage = "12.000"; fuel_type = "Gasolina"; color = "Cinza"; 
    transmission = "Automática"; description = "Honda Civic Touring 2023, sedan premium japonês";
    image = "https://placehold.co/800x600/1a202c/10b981?text=Honda+Civic";
    seller_name = "Webmotors Premium"; seller_phone = "(21) 44444-4444"; seller_email = "premium@webmotors.com.br";
    condition = "used"; source = "webmotors"; engine = "2.0L i-VTEC"; doors = 4; body_style = "Sedan";
    location_city = "Rio de Janeiro"; location_state = "RJ";
    detailed_description_md = "# Honda Civic Touring 2023\n\n## Motor Aspirado\nMotor 2.0L i-VTEC naturalmente aspirado com 155 cv, conhecido pela durabilidade Honda.\n\n## Tecnologia\n- Honda SENSING (pacote de segurança)\n- Central multimídia de 9\" com GPS\n- Painel digital 10,2\"\n- Wireless CarPlay e Android Auto\n- Carregador por indução\n\n## Conforto\n- Bancos em couro perfurado\n- Ar condicionado automático dual zone\n- Teto solar elétrico\n- Controle de cruzeiro adaptativo\n- Sistema de som Premium Audio";
    financing_available = true; trade_accepted = true; test_drive_available = true;
  };
]

(* Sample users *)
let sample_users = [
  { id = 1; email = "admin@buscar.com.br"; name = "Admin BusCar"; };
  { id = 2; email = "joao@email.com"; name = "João Silva"; };
  { id = 3; email = "maria@email.com"; name = "Maria Santos"; };
]

(* Mock database functions *)
let get_all_vehicles () = 
  Lwt.return_ok sample_vehicles

let get_vehicle_by_slug slug =
  let vehicle = List.find_opt (fun v -> v.slug = slug) sample_vehicles in
  Lwt.return_ok vehicle

let get_user_by_email email =
  let user = List.find_opt (fun u -> u.email = email) sample_users in
  Lwt.return_ok user