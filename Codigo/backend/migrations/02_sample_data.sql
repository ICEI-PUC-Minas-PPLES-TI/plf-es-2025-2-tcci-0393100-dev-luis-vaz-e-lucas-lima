-- Sample data for BusCar platform
-- This populates the database with initial test data

-- Insert sample users
INSERT INTO users (email, name, phone) VALUES 
    ('admin@buscar.com.br', 'Admin BusCar', '(11) 99999-9999'),
    ('joao@email.com', 'João Silva', '(11) 88888-8888'),
    ('maria@email.com', 'Maria Santos', '(21) 77777-7777')
ON CONFLICT (email) DO NOTHING;

-- Insert sample vehicles
INSERT INTO vehicles (
    slug, brand, model, year, price, mileage, fuel_type, color, transmission,
    description, image, seller_name, seller_phone, seller_email, condition,
    source, engine, doors, body_style, location_city, location_state,
    detailed_description_md, financing_available, trade_accepted, test_drive_available
) VALUES 
    (
        'porsche-911-carrera-2024-1',
        'Porsche', '911 Carrera', 2024, '850.000', '2.500',
        'Gasolina', 'Azul Metálico', 'Automática',
        'Porsche 911 Carrera 2024, esportivo premium com apenas 2.500km',
        'https://placehold.co/800x600/1a202c/10b981?text=Porsche+911',
        'BusCar Premium', '(11) 99999-9999', 'premium@buscar.com.br',
        'new', 'buscar', '3.0L H6 Biturbo', 2, 'Coupe',
        'São Paulo', 'SP',
        '# Porsche 911 Carrera 2024\n\n## Especificações Técnicas\n- Motor 3.0L H6 Biturbo\n- 385 cv de potência\n- Transmissão automática PDK de 8 velocidades\n- Tração traseira\n\n## Equipamentos\n- Sistema de navegação PCM\n- Bancos esportivos em couro\n- Sistema de som Bose\n- Controle de cruzeiro adaptativo\n- Freios cerâmicos PCCB',
        true, true, true
    ),
    (
        'toyota-corolla-2023-2',
        'Toyota', 'Corolla', 2023, '120.000', '15.000',
        'Híbrido', 'Branco Pérola', 'Automática',
        'Toyota Corolla Híbrido 2023, economia e tecnologia',
        'https://placehold.co/800x600/1a202c/10b981?text=Toyota+Corolla',
        'Maria Santos', '(21) 77777-7777', 'maria@email.com',
        'used', 'buscar', '1.8L Híbrido', 4, 'Sedan',
        'Rio de Janeiro', 'RJ',
        '# Toyota Corolla Híbrido 2023\n\n## Motor Híbrido\nCombinação de motor 1.8L a gasolina com motor elétrico, proporcionando excelente economia de combustível.\n\n## Tecnologia\n- Central multimídia com Android Auto e Apple CarPlay\n- Câmera de ré\n- Sensores de estacionamento\n- Controle de cruzeiro\n\n## Segurança\n- 7 airbags\n- Sistema Toyota Safety Sense\n- Controle de estabilidade\n- Freios ABS com EBD',
        true, false, true
    ),
    (
        'bmw-x5-2023-3',
        'BMW', 'X5', 2023, '320.000', '8.000',
        'Gasolina', 'Preto', 'Automática',
        'BMW X5 xDrive 2023, SUV premium alemão',
        'https://placehold.co/800x600/1a202c/10b981?text=BMW+X5',
        'João Silva', '(11) 88888-8888', 'joao@email.com',
        'used', 'buscar', '3.0L I6 Turbo', 4, 'SUV',
        'São Paulo', 'SP',
        '# BMW X5 xDrive 2023\n\n## Performance\nMotor 3.0L I6 turbo com 340 cv, tração integral xDrive e suspensão adaptativa.\n\n## Luxury Features\n- Bancos em couro Dakota perfurado\n- Teto solar panorâmico\n- Sistema de som Harman Kardon\n- Ar condicionado de 4 zonas\n- Câmeras 360°\n\n## Tecnologia\n- iDrive 7 com tela de 12.3"\n- BMW Live Cockpit Professional\n- Wireless CarPlay\n- Heads-up Display\n- Assistente de estacionamento automático',
        false, true, true
    ),
    (
        'volkswagen-gol-2022-4',
        'Volkswagen', 'Gol', 2022, '65.000', '25.000',
        'Flex', 'Prata', 'Manual',
        'Volkswagen Gol 2022, econômico e confiável',
        'https://placehold.co/800x600/1a202c/10b981?text=VW+Gol',
        'Localiza Seminovos', '(11) 55555-5555', 'vendas@localiza.com',
        'used', 'localiza', '1.0L MPI', 4, 'Hatchback',
        'São Paulo', 'SP',
        '# Volkswagen Gol 2022\n\n## Economia\nMotor 1.0 MPI flex, ideal para cidade com baixo consumo de combustível.\n\n## Equipamentos\n- Direção elétrica\n- Ar condicionado\n- Vidros elétricos dianteiros\n- Trava elétrica\n- Som com Bluetooth\n\n## Características\n- Porta-malas de 285 litros\n- Computador de bordo\n- Freios ABS\n- Airbag duplo',
        true, false, false
    ),
    (
        'honda-civic-2023-5',
        'Honda', 'Civic', 2023, '165.000', '12.000',
        'Gasolina', 'Cinza', 'Automática',
        'Honda Civic Touring 2023, sedan premium japonês',
        'https://placehold.co/800x600/1a202c/10b981?text=Honda+Civic',
        'Webmotors Premium', '(21) 44444-4444', 'premium@webmotors.com.br',
        'used', 'webmotors', '2.0L i-VTEC', 4, 'Sedan',
        'Rio de Janeiro', 'RJ',
        '# Honda Civic Touring 2023\n\n## Motor Aspirado\nMotor 2.0L i-VTEC naturalmente aspirado com 155 cv, conhecido pela durabilidade Honda.\n\n## Tecnologia\n- Honda SENSING (pacote de segurança)\n- Central multimídia de 9" com GPS\n- Painel digital 10,2"\n- Wireless CarPlay e Android Auto\n- Carregador por indução\n\n## Conforto\n- Bancos em couro perfurado\n- Ar condicionado automático dual zone\n- Teto solar elétrico\n- Controle de cruzeiro adaptativo\n- Sistema de som Premium Audio',
        true, true, true
    )
ON CONFLICT (slug) DO NOTHING;
-- Insert vehicle images
INSERT INTO vehicle_images (vehicle_id, image_url, alt_text, sort_order) VALUES
    (1, 'https://placehold.co/800x600/1a202c/10b981?text=Porsche+911+Front', 'Porsche 911 - Vista frontal', 0),
    (1, 'https://placehold.co/800x600/1a202c/10b981?text=Porsche+911+Side', 'Porsche 911 - Vista lateral', 1),
    (1, 'https://placehold.co/800x600/1a202c/10b981?text=Porsche+911+Interior', 'Porsche 911 - Interior', 2),
    (2, 'https://placehold.co/800x600/1a202c/10b981?text=Toyota+Corolla+Front', 'Toyota Corolla - Vista frontal', 0),
    (2, 'https://placehold.co/800x600/1a202c/10b981?text=Toyota+Corolla+Side', 'Toyota Corolla - Vista lateral', 1),
    (3, 'https://placehold.co/800x600/1a202c/10b981?text=BMW+X5+Front', 'BMW X5 - Vista frontal', 0),
    (3, 'https://placehold.co/800x600/1a202c/10b981?text=BMW+X5+Interior', 'BMW X5 - Interior', 1),
    (4, 'https://placehold.co/800x600/1a202c/10b981?text=VW+Gol+Front', 'VW Gol - Vista frontal', 0),
    (5, 'https://placehold.co/800x600/1a202c/10b981?text=Honda+Civic+Front', 'Honda Civic - Vista frontal', 0),
    (5, 'https://placehold.co/800x600/1a202c/10b981?text=Honda+Civic+Interior', 'Honda Civic - Interior', 1);

-- Insert vehicle features
INSERT INTO vehicle_features (vehicle_id, feature_name, feature_value) VALUES
    (1, 'Sistema de navegação', 'PCM com GPS'),
    (1, 'Freios', 'Cerâmicos PCCB'),
    (1, 'Suspensão', 'Esportiva PASM'),
    (1, 'Sistema de som', 'Bose Premium'),
    (2, 'Economia', '16.5 km/l na cidade'),
    (2, 'Garantia', 'Toyota até 2026'),
    (2, 'Conectividade', 'Android Auto e Apple CarPlay'),
    (3, 'Tração', 'Integral xDrive'),
    (3, 'Suspensão', 'Adaptativa'),
    (3, 'Teto', 'Solar panorâmico'),
    (4, 'Consumo urbano', '12.5 km/l'),
    (4, 'Capacidade', '5 ocupantes'),
    (5, 'Honda SENSING', 'Pacote completo de segurança'),
    (5, 'Garantia', '3 anos Honda'),
    (5, 'Teto solar', 'Elétrico com anti-esmagamento');

-- Insert sample service history
INSERT INTO service_history (vehicle_id, service_date, service_type, description, mileage_at_service, cost, service_provider) VALUES
    (1, '2024-01-15', 'Revisão', 'Primeira revisão dos 2.500km', '2.500', 'R$ 800', 'Porsche Center SP'),
    (2, '2023-12-10', 'Revisão', 'Revisão dos 15.000km', '15.000', 'R$ 450', 'Toyota Barra Funda'),
    (2, '2023-06-15', 'Revisão', 'Revisão dos 10.000km', '10.000', 'R$ 350', 'Toyota Barra Funda'),
    (3, '2023-11-20', 'Revisão', 'Revisão programada BMW', '8.000', 'R$ 1200', 'BMW Morumbi'),
    (4, '2023-08-30', 'Troca de óleo', 'Troca de óleo e filtros', '23.000', 'R$ 180', 'Oficina VW'),
    (5, '2023-10-05', 'Revisão', 'Revisão dos 10.000km Honda', '10.000', 'R$ 420', 'Honda Ibirapuera');

-- Update statistics
ANALYZE vehicles;
ANALYZE users;
ANALYZE vehicle_images;
ANALYZE vehicle_features;
ANALYZE service_history;

