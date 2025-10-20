# BusCar - Find Your Ideal Car in Brazil

BusCar is a car search platform for the Brazilian market, inspired by Auto Tempest but designed specifically for Brazil. It combines the functionality of Webmotors with the detailed presentation style of Bring a Trailer.

## Features

- **Home Screen**: Search cars by brand (Porsche, Toyota, BMW) and model
- **Vehicle Listing**: Browse and filter available vehicles
- **Vehicle Details**: Detailed vehicle pages with comprehensive information
- **Advertisement System**: 15-second delay ads with third-party redirects
- **User Dashboard**: Manage vehicle announcements
- **Login System**: User authentication

## Technology Stack

- **Backend**: OCaml with Dream framework
- **Frontend**: HTML, CSS, JavaScript (embedded in OCaml)
- **Database**: SQLite with Caqti
- **Containerization**: Docker and Docker Compose

## Quick Start

### Option 1: Using the Run Script (Easiest)
```bash
./run.sh
```

### Option 2: Using Docker Compose
```bash
# Build and run
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### Option 3: Manual Setup (Requires OCaml)
```bash
# Install OCaml and dependencies (if not already installed)
opam init
opam install . --deps-only

# Build the project
dune build

# Run the application
dune exec ./bin/buscar.exe
```

### Access the Application
- Open your browser and go to `http://localhost:8080`
- The application will start with sample vehicle data

## Demo Credentials

For testing the dashboard functionality:
- Email: `admin@buscar.com`
- Password: `123456`

## Project Structure

```
buscar-mockup/
├── bin/                 # Main application
│   ├── buscar.ml       # Main server file
│   └── dune            # Build configuration
├── lib/                 # Library modules
│   ├── templates.ml    # HTML templates
│   └── dune            # Library build config
├── data/               # SQLite database
├── static/             # Static assets
├── docker-compose.yml  # Docker composition
├── Dockerfile         # Container definition
└── dune-project       # Project configuration
```

## Available Routes

- `/` - Home page with search functionality
- `/vehicles` - Vehicle listing with filters
- `/vehicle/:id` - Individual vehicle details
- `/login` - User authentication
- `/dashboard` - User dashboard (requires login)
- `/ad` - Advertisement page with redirect

## Development

The application uses string-based HTML templates defined in `lib/templates.ml`. All styling is embedded within the OCaml code for easy maintenance and deployment.

## Sample Data

The application includes sample vehicles from Porsche, Toyota, and BMW for demonstration purposes. In a production environment, this would be replaced with a proper database integration.
