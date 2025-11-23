#!/bin/bash

# BusCars Database Seed Script
# Uses Backend API to populate data (tests CRUD operations)

set -e

BACKEND_URL="${BACKEND_API_URL:-http://localhost:3000}"

echo "🌱 Seeding BusCars Database via Backend API..."
echo "Backend: $BACKEND_URL"
echo ""

# Wait for backend to be ready
echo "⏳ Waiting for backend..."
for i in {1..30}; do
    if curl -sf "$BACKEND_URL/health" > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    sleep 1
done

# First, seed users directly (they don't go through API yet)
echo ""
echo "👥 Creating users..."
docker exec buscar-postgres psql -U buscar_user -d buscar << 'EOF'
INSERT INTO users (name, email, password_hash, phone, subscription_tier, is_verified) VALUES
    ('Admin User', 'admin@buscar.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 99999-0000', 'business', TRUE),
    ('Carlos Silva', 'carlos.silva@email.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 99999-9999', 'professional', TRUE),
    ('Maria Santos', 'maria.santos@gmail.com', '3a8d50293b3b56b15c8ca72e59d7c2efce869fe21542ca1f1162342c4a36328b', '(11) 88888-8888', 'individual', TRUE)
ON CONFLICT (email) DO NOTHING;
EOF

echo "✅ Users created"
echo ""

# Login to get session
echo "🔐 Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@buscar.com","password":"123456"}')

SESSION_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.session_id // empty')

if [ -z "$SESSION_ID" ]; then
    echo "❌ Login failed! Response:"
    echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Logged in! Session: $SESSION_ID"
echo ""

# Create vehicles via API
echo "🚗 Creating internal vehicles via API..."

# Vehicle 1: Porsche 911
echo "  Creating Porsche 911..."
curl -s -X POST "$BACKEND_URL/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SESSION_ID" \
  -d '{
    "brand": "Porsche",
    "model": "911",
    "year": 2022,
    "price": "850.000",
    "mileage": "15.000",
    "fuel_type": "Gasolina",
    "color": "Prata Metálico",
    "transmission": "PDK 8 velocidades",
    "description": "Porsche 911 Carrera em estado impecável.",
    "image": "https://placehold.co/900x600/1a202c/10b981?text=2022+Porsche+911+Carrera",
    "images": [],
    "seller_id": 2,
    "seller_name": "Carlos Silva",
    "seller_phone": "(11) 99999-9999",
    "seller_email": "carlos.silva@email.com",
    "condition": "used",
    "source": "buscar",
    "engine": "3.0L Flat-Six Turbo (385cv)",
    "doors": 2,
    "body_style": "Coupé Esportivo",
    "features": [],
    "detailed_description_md": "# Porsche 911 Carrera 2022",
    "vin": "WP0AA2A99NS123456",
    "license_plate": "ABC1D23",
    "previous_owners": 1,
    "service_history": [],
    "modifications": [],
    "included_items": [],
    "exterior_condition": "Excelente",
    "interior_condition": "Excelente",
    "mechanical_condition": "Perfeito",
    "inspection_notes": "Veículo inspecionado.",
    "location_city": "São Paulo",
    "location_state": "SP",
    "financing_available": true,
    "trade_accepted": true,
    "test_drive_available": true,
    "created_at": "",
    "updated_at": "",
    "is_active": true,
  }' | jq '.'

echo ""
echo "  Creating Toyota Corolla..."
curl -s -X POST "$BACKEND_URL/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SESSION_ID" \
  -d '{
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2021,
    "price": "95.000",
    "mileage": "25.000",
    "fuel_type": "Flex",
    "color": "Branco Perolado",
    "transmission": "CVT Automática",
    "description": "Toyota Corolla XEi 2021.",
    "image": "https://placehold.co/900x600/10b981/ffffff?text=2021+Toyota+Corolla+XEi",
    "images": [],
    "seller_id": 3,
    "seller_name": "Maria Santos",
    "seller_phone": "(11) 88888-8888",
    "seller_email": "maria.santos@gmail.com",
    "condition": "used",
    "source": "buscar",
    "engine": "2.0L Flex",
    "doors": 4,
    "body_style": "Sedan",
    "features": [],
    "detailed_description_md": "# Toyota Corolla",
    "vin": "9BR53ZEC1M5123456",
    "license_plate": "XYZ9A87",
    "previous_owners": 1,
    "service_history": [],
    "modifications": [],
    "included_items": [],
    "exterior_condition": "Muito Bom",
    "interior_condition": "Excelente",
    "mechanical_condition": "Perfeito",
    "inspection_notes": "",
    "location_city": "São Paulo",
    "location_state": "SP",
    "financing_available": true,
    "trade_accepted": true,
    "test_drive_available": true,
    "created_at": "",
    "updated_at": "",
    "is_active": true,
  }' | jq '.'

echo ""
echo "🌐 Creating external platform vehicles..."

# External vehicles (simulating scraper)
echo "  Creating BMW X5 (source: localiza)..."
curl -s -X POST "$BACKEND_URL/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SESSION_ID" \
  -d '{
    "brand": "BMW",
    "model": "X5",
    "year": 2023,
    "price": "320.000",
    "mileage": "8.000",
    "source": "localiza",
    "seller_id": 1,
    "seller_name": "João Oliveira",
    "condition": "new",
    "description": "BMW X5 xDrive 2023",
    "image": "https://placehold.co/600x400/1a202c/10b981?text=BMW+X5",
    "location_city": "São Paulo",
    "location_state": "SP"
  }' | jq -c '{success, id: .data.id}'

echo ""
echo "✅ Seed data created via Backend API!"
echo ""
echo "📊 Summary:"
docker exec buscar-postgres psql -U buscar_user -d buscar -c "SELECT source, COUNT(*), string_agg(DISTINCT brand, ', ') as brands FROM vehicles WHERE is_active = TRUE GROUP BY source ORDER BY source;"
echo ""
echo "🧪 Test CRUD operations:"
echo "  GET    $BACKEND_URL/api/vehicles"
echo "  POST   $BACKEND_URL/api/vehicles (with auth)"
echo "  PUT    $BACKEND_URL/api/vehicles/:id (with auth)"
echo "  DELETE $BACKEND_URL/api/vehicles/:id (with auth)"
