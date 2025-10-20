#!/bin/bash

# BusCar VPS Deployment Script with Network Resilience
set -e

echo "🚀 BusCar VPS Deployment Script"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Clean up Docker resources to free space
print_status "Cleaning up Docker resources..."
docker system prune -f --volumes 2>/dev/null || true

# Test network connectivity
print_status "Testing network connectivity..."
if ! curl -I --connect-timeout 10 https://opam.ocaml.org/ &>/dev/null; then
    print_warning "Network connectivity to opam.ocaml.org seems slow or unavailable"
    print_warning "This may cause build timeouts. Consider:"
    print_warning "1. Trying during off-peak hours"
    print_warning "2. Checking VPS network configuration"
    print_warning "3. Using a different DNS server"
fi

# Build with retries
MAX_ATTEMPTS=3
attempt=1

while [ $attempt -le $MAX_ATTEMPTS ]; do
    print_status "Build attempt $attempt/$MAX_ATTEMPTS..."
    
    if timeout 3600 docker-compose up --build -d; then
        print_success "Build and deployment successful!"
        
        # Wait for service to be ready
        print_status "Waiting for service to be ready..."
        sleep 10
        
        # Test if service is responding
        if curl -f http://localhost:8080/ &>/dev/null; then
            print_success "BusCar is running and responding!"
            print_success "Access your application at: http://localhost:8080"
            
            # Show container status
            echo ""
            print_status "Container status:"
            docker-compose ps
            
            exit 0
        else
            print_warning "Service built but not responding. Check logs:"
            echo "  docker-compose logs buscar-web"
        fi
        
        exit 0
    else
        print_error "Build attempt $attempt failed"
        
        if [ $attempt -lt $MAX_ATTEMPTS ]; then
            print_status "Cleaning up and retrying in 60 seconds..."
            docker-compose down 2>/dev/null || true
            docker system prune -f --volumes 2>/dev/null || true
            sleep 60
        fi
        
        attempt=$((attempt + 1))
    fi
done

print_error "All build attempts failed!"
print_status "Troubleshooting steps:"
echo "1. Check network connectivity: ping opam.ocaml.org"
echo "2. Check Docker logs: docker-compose logs"
echo "3. Try building during off-peak hours"
echo "4. Check available disk space: df -h"
echo "5. Check VPS memory: free -h"

exit 1

