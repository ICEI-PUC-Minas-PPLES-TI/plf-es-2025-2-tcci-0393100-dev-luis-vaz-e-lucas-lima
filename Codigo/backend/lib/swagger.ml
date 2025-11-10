(* OpenAPI/Swagger Documentation for BusCars API *)

let swagger_spec = {|
{
  "openapi": "3.0.0",
  "info": {
    "title": "BusCars API",
    "version": "1.0.0",
    "description": "REST API for BusCars car marketplace - supporting both internal listings and external scraped vehicles",
    "contact": {
      "name": "BusCars Support",
      "email": "support@buscars.com"
    }
  },
  "servers": [
    {
      "url": "http://localhost:3000",
      "description": "Development server"
    }
  ],
  "tags": [
    {
      "name": "health",
      "description": "System health endpoints"
    },
    {
      "name": "vehicles",
      "description": "Vehicle management (internal + external scraped)"
    },
    {
      "name": "auth",
      "description": "Authentication endpoints"
    }
  ],
  "paths": {
    "/health": {
      "get": {
        "tags": ["health"],
        "summary": "Health check",
        "responses": {
          "200": {
            "description": "Service is healthy",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "status": { "type": "string", "example": "healthy" },
                    "service": { "type": "string", "example": "buscar-backend" },
                    "timestamp": { "type": "string", "format": "date-time" }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/api/vehicles": {
      "get": {
        "tags": ["vehicles"],
        "summary": "List all vehicles (internal + external)",
        "description": "Returns paginated list of vehicles from database. Includes both BusCars internal listings and externally scraped vehicles.",
        "parameters": [
          {
            "name": "brand",
            "in": "query",
            "schema": { "type": "string" },
            "description": "Filter by brand"
          },
          {
            "name": "model",
            "in": "query",
            "schema": { "type": "string" },
            "description": "Filter by model"
          },
          {
            "name": "year_min",
            "in": "query",
            "schema": { "type": "integer" },
            "description": "Minimum year"
          },
          {
            "name": "year_max",
            "in": "query",
            "schema": { "type": "integer" },
            "description": "Maximum year"
          },
          {
            "name": "price_min",
            "in": "query",
            "schema": { "type": "integer" },
            "description": "Minimum price"
          },
          {
            "name": "price_max",
            "in": "query",
            "schema": { "type": "integer" },
            "description": "Maximum price"
          },
          {
            "name": "fuel_type",
            "in": "query",
            "schema": { "type": "string", "enum": ["Gasolina", "Flex", "Diesel", "Elétrico", "Híbrido"] },
            "description": "Filter by fuel type"
          },
          {
            "name": "condition",
            "in": "query",
            "schema": { "type": "string", "enum": ["used", "new"] },
            "description": "Filter by condition"
          },
          {
            "name": "source",
            "in": "query",
            "schema": { "type": "string", "enum": ["buscar", "webmotors", "localiza", "icarros", "bringatrailer"] },
            "description": "Filter by source (buscar = internal, others = scraped)"
          },
          {
            "name": "location_state",
            "in": "query",
            "schema": { "type": "string" },
            "description": "Filter by state (SP, RJ, etc.)"
          },
          {
            "name": "page",
            "in": "query",
            "schema": { "type": "integer", "default": 1 },
            "description": "Page number"
          },
          {
            "name": "per_page",
            "in": "query",
            "schema": { "type": "integer", "default": 20, "maximum": 100 },
            "description": "Items per page"
          },
          {
            "name": "sort",
            "in": "query",
            "schema": { "type": "string", "enum": ["price_asc", "price_desc", "year_desc", "mileage_asc"] },
            "description": "Sort order"
          }
        ],
        "responses": {
          "200": {
            "description": "List of vehicles",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "vehicles": {
                      "type": "array",
                      "items": { "$ref": "#/components/schemas/Vehicle" }
                    },
                    "total_count": { "type": "integer" },
                    "page": { "type": "integer" },
                    "total_pages": { "type": "integer" },
                    "has_next": { "type": "boolean" },
                    "has_prev": { "type": "boolean" }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/api/vehicles/{slug}": {
      "get": {
        "tags": ["vehicles"],
        "summary": "Get vehicle by slug",
        "description": "Returns detailed information about a specific vehicle (internal or external)",
        "parameters": [
          {
            "name": "slug",
            "in": "path",
            "required": true,
            "schema": { "type": "string" },
            "description": "Vehicle slug (e.g., 'porsche-911-2022-1')"
          }
        ],
        "responses": {
          "200": {
            "description": "Vehicle details",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/ApiResponse"
                }
              }
            }
          },
          "404": {
            "description": "Vehicle not found"
          }
        }
      }
    },
    "/api/auth/login": {
      "post": {
        "tags": ["auth"],
        "summary": "User login",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["email", "password"],
                "properties": {
                  "email": { "type": "string", "format": "email" },
                  "password": { "type": "string" }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Login successful",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "message": { "type": "string" },
                    "session_id": { "type": "string", "format": "uuid" },
                    "user": { "$ref": "#/components/schemas/User" }
                  }
                }
              }
            }
          },
          "401": {
            "description": "Invalid credentials"
          }
        }
      }
    },
    "/api/auth/logout": {
      "post": {
        "tags": ["auth"],
        "summary": "User logout",
        "security": [{ "bearerAuth": [] }],
        "responses": {
          "200": {
            "description": "Logout successful"
          }
        }
      }
    },
    "/api/auth/me": {
      "get": {
        "tags": ["auth"],
        "summary": "Get current user",
        "security": [{ "bearerAuth": [] }],
        "responses": {
          "200": {
            "description": "Current user info",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/ApiResponse"
                }
              }
            }
          },
          "401": {
            "description": "Not authenticated"
          }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "bearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "UUID"
      }
    },
    "schemas": {
      "Vehicle": {
        "type": "object",
        "properties": {
          "id": { "type": "integer" },
          "slug": { "type": "string" },
          "brand": { "type": "string" },
          "model": { "type": "string" },
          "year": { "type": "integer" },
          "price": { "type": "string" },
          "mileage": { "type": "string" },
          "fuel_type": { "type": "string" },
          "color": { "type": "string" },
          "transmission": { "type": "string" },
          "description": { "type": "string" },
          "image": { "type": "string" },
          "images": { "type": "array", "items": { "type": "string" } },
          "seller_id": { "type": "integer" },
          "seller_name": { "type": "string" },
          "seller_phone": { "type": "string" },
          "seller_email": { "type": "string" },
          "condition": { "type": "string", "enum": ["used", "new"] },
          "source": { 
            "type": "string", 
            "enum": ["buscar", "webmotors", "localiza", "icarros", "bringatrailer"],
            "description": "buscar = internal listing, others = scraped from external platforms"
          },
          "engine": { "type": "string" },
          "doors": { "type": "integer" },
          "body_style": { "type": "string" },
          "features": { "type": "array", "items": { "type": "string" } },
          "detailed_description_md": { "type": "string" },
          "vin": { "type": "string", "nullable": true },
          "license_plate": { "type": "string", "nullable": true },
          "previous_owners": { "type": "integer" },
          "service_history": { "type": "array", "items": { "type": "string" } },
          "modifications": { "type": "array", "items": { "type": "string" } },
          "included_items": { "type": "array", "items": { "type": "string" } },
          "exterior_condition": { "type": "string" },
          "interior_condition": { "type": "string" },
          "mechanical_condition": { "type": "string" },
          "inspection_notes": { "type": "string" },
          "location_city": { "type": "string" },
          "location_state": { "type": "string" },
          "financing_available": { "type": "boolean" },
          "trade_accepted": { "type": "boolean" },
          "test_drive_available": { "type": "boolean" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" },
          "is_active": { "type": "boolean" },
          "views_count": { "type": "integer" },
          "favorites_count": { "type": "integer" }
        }
      },
      "User": {
        "type": "object",
        "properties": {
          "user_id": { "type": "integer" },
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "subscription_tier": { 
            "type": "string", 
            "enum": ["individual", "professional", "business"] 
          }
        }
      },
      "ApiResponse": {
        "type": "object",
        "properties": {
          "success": { "type": "boolean" },
          "message": { "type": "string" },
          "data": { "type": "object" }
        }
      }
    }
  }
}
|}

let swagger_ui_html = {|
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>BusCars API Documentation</title>
    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
    <style>
        body { margin: 0; padding: 0; }
        .topbar { display: none; }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
    <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
    <script>
        window.onload = function() {
            const ui = SwaggerUIBundle({
                spec: |} ^ swagger_spec ^ {|,
                dom_id: '#swagger-ui',
                deepLinking: true,
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIStandalonePreset
                ],
                plugins: [
                    SwaggerUIBundle.plugins.DownloadUrl
                ],
                layout: "StandaloneLayout"
            });
            window.ui = ui;
        };
    </script>
</body>
</html>
|}

