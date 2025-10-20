#!/bin/bash

echo "🚗 Starting BusCar (optimized build)..."

mkdir -p data static

echo "Building... (much faster now - Alpine + minimal deps)"
docker-compose up --build

echo "✅ App running at http://localhost:8080"
echo "Login: admin@buscar.com / 123456"