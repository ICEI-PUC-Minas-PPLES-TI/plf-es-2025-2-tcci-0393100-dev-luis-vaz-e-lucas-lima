# BusCars Backend API

Backend API service for BusCars car marketplace platform, built with OCaml, PostgreSQL, and Redis.

## Features

- **RESTful API** - Clean REST endpoints for vehicle and user management
- **PostgreSQL Database** - Robust data persistence with full schema
- **Redis Caching** - Fast response times with intelligent caching
- **Authentication** - Secure bcrypt password hashing and session management
- **CORS Support** - Cross-origin resource sharing for frontend integration

## Tech Stack

- **Language**: OCaml 4.14+
- **Web Framework**: Dream
- **Database**: PostgreSQL 14+ with Caqti
- **Cache**: Redis 7+ with redis-lwt
- **Authentication**: Bcrypt for password hashing
- **JSON**: Yojson with ppx_deriving_yojson

## API Endpoints

### Public Endpoints

- `GET /health` - Health check
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/vehicles` - List vehicles with filters
- `GET /api/vehicles/:slug` - Get vehicle details

### Protected Endpoints

- `GET /api/auth/me` - Get current user info

### Query Parameters for Vehicle Listing

- `brand` - Filter by brand
- `model` - Filter by model
- `year_min` - Minimum year
- `year_max` - Maximum year
- `price_min` - Minimum price
- `price_max` - Maximum price
- `fuel_type` - Filter by fuel type
- `condition` - Filter by condition (new/used)
- `source` - Filter by source
- `location_state` - Filter by state
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20, max: 100)
- `sort` - Sort order (price_asc, price_desc, year_desc, mileage_asc)

## Environment Variables

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=buscar
POSTGRES_USER=buscar_user
POSTGRES_PASSWORD=buscar_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=3000
SESSION_SECRET=your-secret-key

# Cache TTL (seconds)
CACHE_TTL_VEHICLE_DETAIL=300
CACHE_TTL_VEHICLE_LIST=60
CACHE_TTL_USER=600
```

## Database Schema

The database includes the following tables:

- `users` - User accounts with authentication
- `vehicles` - Vehicle listings with full details
- `sessions` - User sessions
- `favorites` - User favorites (prepared for future use)
- `contact_requests` - Contact inquiries (prepared for future use)

## Development

### Local Setup

```bash
# Install dependencies
opam install . --deps-only

# Build
dune build

# Run
dune exec buscar_backend
```

### Docker Setup

```bash
# Build
docker build -t buscar-backend .

# Run with PostgreSQL and Redis
docker-compose up
```

## Docker Deployment

The complete stack can be deployed using Docker Compose from the root directory:

```bash
cd ..
docker-compose up --build
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379
- Backend API on port 3000
- Frontend on port 8080
- Nginx on port 80

## Default Credentials

For testing:
- Email: `admin@buscar.com`
- Password: `123456`

**Note**: Change these in production!

## Caching Strategy

- Vehicle details cached for 5 minutes
- Vehicle listings cached for 1 minute
- User data cached for 10 minutes
- View counts batched (DB updated every 10 views)

## API Response Format

### Success Response

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description",
  "data": null
}
```

## License

MIT
