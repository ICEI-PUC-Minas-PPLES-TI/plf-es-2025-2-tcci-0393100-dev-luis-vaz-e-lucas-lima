#!/bin/bash

# BusCars - Stop Script

echo "🛑 Stopping BusCars services..."
docker-compose down

echo ""
echo "✅ All services stopped"
echo ""
echo "To remove volumes as well, run:"
echo "   docker-compose down -v"

