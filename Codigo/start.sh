#!/bin/bash

# BusCars - Complete Stack Startup Script

set -e

echo "🚗 Starting BusCars - Full Stack Application"
echo "=============================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true
echo ""

# Clean up old volumes (optional - uncomment if needed)
# echo "🧹 Cleaning up old volumes..."
# docker-compose down -v
# echo ""

# Build and start all services
echo "🏗️  Building and starting services..."
echo "   - PostgreSQL Database"
echo "   - Redis Cache"
echo "   - Backend API (OCaml + Dream)"
echo "   - Frontend (OCaml + Dream)"
echo "   - Nginx Reverse Proxy"
echo ""

docker-compose up --build -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check service health
echo ""
echo "🔍 Checking service status..."

check_service() {
    local service=$1
    local url=$2
    
    if curl -sf "$url" > /dev/null 2>&1; then
        echo "   ✅ $service is healthy"
        return 0
    else
        echo "   ⚠️  $service is starting..."
        return 1
    fi
}

# Wait for services
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    all_healthy=true
    
    if ! check_service "Backend API" "http://localhost:3000/health"; then
        all_healthy=false
    fi
    
    if ! check_service "Frontend" "http://localhost:8080"; then
        all_healthy=false
    fi
    
    if [ "$all_healthy" = true ]; then
        break
    fi
    
    attempt=$((attempt + 1))
    sleep 2
done

echo ""
echo "=============================================="
echo "🎉 BusCars is now running!"
echo "=============================================="
echo ""
echo "📱 Application URLs:"
echo "   Frontend:  http://localhost:8080"
echo "   Backend API: http://localhost:3000"
echo "   Nginx Proxy: http://localhost:80"
echo ""
echo "🗄️  Database:"
echo "   PostgreSQL: localhost:5432"
echo "   Redis: localhost:6379"
echo ""
echo "🔑 Test Credentials:"
echo "   Email: admin@buscar.com"
echo "   Password: 123456"
echo ""
echo "📊 View logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose down"
echo ""
echo "=============================================="

