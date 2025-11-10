# BusCars Makefile

.PHONY: help build up down logs clean restart backend frontend db redis test

help: ## Show this help message
	@echo "BusCars - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build all Docker containers
	docker-compose build

up: ## Start all services
	./start.sh

down: ## Stop all services
	docker-compose down

logs: ## View logs from all services
	docker-compose logs -f

clean: ## Stop services and remove volumes
	docker-compose down -v
	docker system prune -f

restart: down up ## Restart all services

backend: ## View backend logs
	docker-compose logs -f backend

frontend: ## View frontend logs
	docker-compose logs -f frontend

db: ## Access PostgreSQL database
	docker exec -it buscar-postgres psql -U buscar_user -d buscar

redis: ## Access Redis CLI
	docker exec -it buscar-redis redis-cli

test: ## Run basic health checks
	@echo "Testing Backend API..."
	@curl -sf http://localhost:3000/health && echo "✅ Backend OK" || echo "❌ Backend Failed"
	@echo "Testing Frontend..."
	@curl -sf http://localhost:8080/ > /dev/null && echo "✅ Frontend OK" || echo "❌ Frontend Failed"

dev-backend: ## Run backend in development mode
	cd backend && dune exec buscar_backend

dev-frontend: ## Run frontend in development mode
	cd frontend && dune exec buscar

install: ## Install OCaml dependencies
	cd backend && opam install . --deps-only -y
	cd frontend && opam install . --deps-only -y

status: ## Show status of all services
	docker-compose ps

