#!/bin/bash

# API Testing Script for BusCars Backend

echo "🧪 Testing BusCars Backend API"
echo "================================"
echo ""

BASE_URL="http://localhost:3000"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -n "Testing: $description... "
    
    if [ -z "$data" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$endpoint")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo -e "${GREEN}✅ PASS${NC} ($response)"
    else
        echo -e "${RED}❌ FAIL${NC} ($response)"
    fi
}

# Test health endpoint
test_endpoint "GET" "/health" "" "Health check"

# Test vehicles list
test_endpoint "GET" "/api/vehicles" "" "List vehicles"

# Test specific vehicle
test_endpoint "GET" "/api/vehicles/porsche-911-2022-1" "" "Get vehicle by slug"

# Test login
test_endpoint "POST" "/api/auth/login" '{"email":"admin@buscar.com","password":"123456"}' "User login"

echo ""
echo "================================"
echo "Detailed API Responses:"
echo "================================"
echo ""

echo "1. Health Check:"
curl -s "$BASE_URL/health" | jq . 2>/dev/null || curl -s "$BASE_URL/health"
echo ""

echo "2. Vehicle Count:"
curl -s "$BASE_URL/api/vehicles" | jq '.total_count' 2>/dev/null || echo "jq not installed"
echo ""

echo "3. Login Test:"
curl -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@buscar.com","password":"123456"}' | jq .success 2>/dev/null || echo "Login response received"
echo ""

echo "================================"
echo "🎉 Testing Complete!"
echo "================================"

