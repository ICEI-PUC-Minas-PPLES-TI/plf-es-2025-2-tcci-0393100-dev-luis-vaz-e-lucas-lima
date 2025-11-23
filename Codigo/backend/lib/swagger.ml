(* OpenAPI/Swagger Documentation for BusCars API *)

let swagger_spec = {|
{
  "openapi": "3.0.0",
  "info": {
    "title": "BusCars API",
    "version": "2.0.0",
    "description": "Complete REST API for BusCars car marketplace - supporting internal listings, external scraped vehicles, FIPE integration, user management, and scraper orchestration",
    "contact": {
      "name": "BusCars Support",
      "email": "support@buscars.com"
    }
  },
  "servers": [
    {
      "url": "https://buscar-demo.rastrian.dev/",
      "description": "Development server"
    }
  ],
  "tags": [
    { "name": "health", "description": "System health endpoints" },
    { "name": "vehicles", "description": "Vehicle management (CRUD, listing, filtering)" },
    { "name": "auth", "description": "Authentication and user management" },
    { "name": "fipe", "description": "FIPE API integration (prices, brands, models)" },
    { "name": "referral-codes", "description": "Referral code management" },
    { "name": "users", "description": "User management (admin only)" },
    { "name": "scrapers", "description": "Scraper job management and bulk imports" },
    { "name": "maintenance", "description": "Maintenance and system operations" },
    { "name": "database", "description": "Database-backed lookups (models, cities)" }
  ],
  "paths": {
    "/health": {
      "get": {
        "tags": ["health"],
        "summary": "Health check",
        "description": "Returns service health status",
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
        "summary": "List vehicles",
        "description": "Returns paginated list of vehicles with advanced filtering. Includes both BusCars internal listings and externally scraped vehicles.",
        "parameters": [
          { "name": "brand", "in": "query", "schema": { "type": "string" }, "description": "Filter by brand" },
          { "name": "model", "in": "query", "schema": { "type": "string" }, "description": "Filter by model" },
          { "name": "year_min", "in": "query", "schema": { "type": "integer" }, "description": "Minimum year" },
          { "name": "year_max", "in": "query", "schema": { "type": "integer" }, "description": "Maximum year" },
          { "name": "price_min", "in": "query", "schema": { "type": "integer" }, "description": "Minimum price" },
          { "name": "price_max", "in": "query", "schema": { "type": "integer" }, "description": "Maximum price" },
          { "name": "fuel_type", "in": "query", "schema": { "type": "string", "enum": ["Gasolina", "Flex", "Diesel", "Elétrico", "Híbrido"] }, "description": "Filter by fuel type" },
          { "name": "condition", "in": "query", "schema": { "type": "string", "enum": ["used", "new"] }, "description": "Filter by condition" },
          { "name": "source", "in": "query", "schema": { "type": "string", "enum": ["buscar", "webmotors", "localiza", "icarros"] }, "description": "Filter by source" },
          { "name": "location_state", "in": "query", "schema": { "type": "string" }, "description": "Filter by state (SP, RJ, etc.)" },
          { "name": "location_city", "in": "query", "schema": { "type": "string" }, "description": "Filter by city" },
          { "name": "seller_id", "in": "query", "schema": { "type": "integer" }, "description": "Filter by seller ID" },
          { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 }, "description": "Page number" },
          { "name": "per_page", "in": "query", "schema": { "type": "integer", "default": 20, "maximum": 100 }, "description": "Items per page" },
          { "name": "sort", "in": "query", "schema": { "type": "string", "enum": ["price_asc", "price_desc", "year_desc", "mileage_asc"] }, "description": "Sort order" }
        ],
        "responses": {
          "200": {
            "description": "List of vehicles",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/VehicleListResponse" }
              }
            }
          }
        }
      },
      "post": {
        "tags": ["vehicles"],
        "summary": "Create vehicle",
        "description": "Create a new vehicle listing (requires authentication)",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/Vehicle" }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Vehicle created",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "401": { "description": "Not authenticated" },
          "400": { "description": "Invalid request" }
        }
      }
    },
    "/api/vehicles/{slug}": {
      "get": {
        "tags": ["vehicles"],
        "summary": "Get vehicle by slug",
        "description": "Returns detailed information about a specific vehicle",
        "parameters": [
          { "name": "slug", "in": "path", "required": true, "schema": { "type": "string" }, "description": "Vehicle slug" }
        ],
        "responses": {
          "200": {
            "description": "Vehicle details",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "404": { "description": "Vehicle not found" }
        }
      }
    },
    "/api/vehicles/{id}": {
      "put": {
        "tags": ["vehicles"],
        "summary": "Update vehicle",
        "description": "Update a vehicle (creates new version, immutable pattern). Requires authentication and ownership/admin.",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" }, "description": "Vehicle ID" }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/Vehicle" }
            }
          }
        },
        "responses": {
          "200": { "description": "Vehicle updated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Not authorized" },
          "404": { "description": "Vehicle not found" }
        }
      },
      "delete": {
        "tags": ["vehicles"],
        "summary": "Delete vehicle (soft delete)",
        "description": "Soft delete a vehicle (requires authentication and ownership/admin)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "reason": { "type": "string", "description": "Reason for deletion" }
                }
              }
            }
          }
        },
        "responses": {
          "200": { "description": "Vehicle deleted", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Not authorized" }
        }
      }
    },
    "/api/vehicles/{id}/restore": {
      "post": {
        "tags": ["vehicles"],
        "summary": "Restore deleted vehicle",
        "description": "Restore a soft-deleted vehicle (requires authentication and ownership/admin)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "responses": {
          "200": { "description": "Vehicle restored", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Not authorized" }
        }
      }
    },
    "/api/vehicles/deleted/list": {
      "get": {
        "tags": ["vehicles"],
        "summary": "List deleted vehicles",
        "description": "List soft-deleted vehicles (requires authentication)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
          { "name": "per_page", "in": "query", "schema": { "type": "integer", "default": 20 } }
        ],
        "responses": {
          "200": {
            "description": "List of deleted vehicles",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/VehicleListResponse" }
              }
            }
          },
          "401": { "description": "Not authenticated" }
        }
      }
    },
    "/api/vehicles/models/{brand}": {
      "get": {
        "tags": ["database"],
        "summary": "Get models by brand",
        "description": "Returns list of models for a given brand from database (cached)",
        "parameters": [
          { "name": "brand", "in": "path", "required": true, "schema": { "type": "string" }, "description": "Brand name" }
        ],
        "responses": {
          "200": {
            "description": "List of models",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "brand": { "type": "string" },
                        "models": { "type": "array", "items": { "type": "string" } }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/api/vehicles/cities/{state}": {
      "get": {
        "tags": ["database"],
        "summary": "Get cities by state",
        "description": "Returns list of cities for a given state from database (cached)",
        "parameters": [
          { "name": "state", "in": "path", "required": true, "schema": { "type": "string" }, "description": "State code (SP, RJ, etc.)" }
        ],
        "responses": {
          "200": {
            "description": "List of cities",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "state": { "type": "string" },
                        "cities": { "type": "array", "items": { "type": "string" } }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/api/fipe/brands": {
      "get": {
        "tags": ["fipe"],
        "summary": "List FIPE brands",
        "description": "Fetches and caches FIPE brands (cars by default, cache: 7 days)",
        "parameters": [
          { "name": "vehicle_type", "in": "query", "schema": { "type": "string", "default": "cars", "enum": ["cars", "motorcycles", "trucks"] }, "description": "Vehicle type" },
          { "name": "reference", "in": "query", "schema": { "type": "string" }, "description": "Reference month code" }
        ],
        "responses": {
          "200": {
            "description": "List of FIPE brands",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "502": { "description": "FIPE API unavailable" }
        }
      }
    },
    "/api/fipe/references": {
      "get": {
        "tags": ["fipe"],
        "summary": "List FIPE references",
        "description": "Get available reference months for FIPE data (cache: 7 days)",
        "responses": {
          "200": {
            "description": "List of references",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "references": {
                          "type": "array",
                          "items": { "$ref": "#/components/schemas/FipeReference" }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/api/fipe/brands/{brand_code}/models": {
      "get": {
        "tags": ["fipe"],
        "summary": "List FIPE models for brand",
        "description": "Get models for a FIPE brand (cache: 7 days)",
        "parameters": [
          { "name": "brand_code", "in": "path", "required": true, "schema": { "type": "string" }, "description": "FIPE brand code" },
          { "name": "vehicle_type", "in": "query", "schema": { "type": "string", "default": "cars" } },
          { "name": "reference", "in": "query", "schema": { "type": "string" } }
        ],
        "responses": {
          "200": {
            "description": "List of models",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "400": { "description": "Invalid brand code" },
          "502": { "description": "FIPE API unavailable" }
        }
      }
    },
    "/api/fipe/brands/{brand_code}/models/{model_code}/years": {
      "get": {
        "tags": ["fipe"],
        "summary": "List FIPE years for model",
        "description": "Get available years for a FIPE model (cache: 7 days)",
        "parameters": [
          { "name": "brand_code", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "model_code", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "vehicle_type", "in": "query", "schema": { "type": "string", "default": "cars" } },
          { "name": "reference", "in": "query", "schema": { "type": "string" } }
        ],
        "responses": {
          "200": {
            "description": "List of years",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "502": { "description": "FIPE API unavailable" }
        }
      }
    },
    "/api/fipe/brands/{brand_code}/models/{model_code}/years/{year_id}": {
      "get": {
        "tags": ["fipe"],
        "summary": "Get FIPE price",
        "description": "Get FIPE price for a specific vehicle (cache: 7 days)",
        "parameters": [
          { "name": "brand_code", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "model_code", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "year_id", "in": "path", "required": true, "schema": { "type": "string" } },
          { "name": "vehicle_type", "in": "query", "schema": { "type": "string", "default": "cars" } },
          { "name": "reference", "in": "query", "schema": { "type": "string" } }
        ],
        "responses": {
          "200": {
            "description": "FIPE vehicle detail with price",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "502": { "description": "FIPE API unavailable" }
        }
      }
    },
    "/api/auth/login": {
      "post": {
        "tags": ["auth"],
        "summary": "User login",
        "description": "Authenticate user and create session",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/LoginRequest" }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Login successful",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/LoginResponse" }
              }
            }
          },
          "401": { "description": "Invalid credentials" }
        }
      }
    },
    "/api/auth/register": {
      "post": {
        "tags": ["auth"],
        "summary": "User registration",
        "description": "Register a new user account",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/RegisterRequest" }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Registration successful",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "400": { "description": "Invalid request or email already exists" }
        }
      }
    },
    "/api/auth/logout": {
      "post": {
        "tags": ["auth"],
        "summary": "User logout",
        "description": "Invalidate current session",
        "security": [{ "bearerAuth": [] }],
        "responses": {
          "200": { "description": "Logout successful", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" }
        }
      }
    },
    "/api/auth/me": {
      "get": {
        "tags": ["auth"],
        "summary": "Get current user",
        "description": "Get authenticated user information",
        "security": [{ "bearerAuth": [] }],
        "responses": {
          "200": {
            "description": "Current user info",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "401": { "description": "Not authenticated" }
        }
      },
      "put": {
        "tags": ["auth"],
        "summary": "Update user profile",
        "description": "Update current user's profile information",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/UpdateUserRequest" }
            }
          }
        },
        "responses": {
          "200": { "description": "Profile updated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" }
        }
      }
    },
    "/api/auth/change-password": {
      "post": {
        "tags": ["auth"],
        "summary": "Change password",
        "description": "Change current user's password",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/ChangePasswordRequest" }
            }
          }
        },
        "responses": {
          "200": { "description": "Password changed", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "400": { "description": "Invalid old password" }
        }
      }
    },
    "/api/users": {
      "get": {
        "tags": ["users"],
        "summary": "List all users",
        "description": "List all users (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
          { "name": "per_page", "in": "query", "schema": { "type": "integer", "default": 20 } }
        ],
        "responses": {
          "200": {
            "description": "List of users",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "users": { "type": "array", "items": { "$ref": "#/components/schemas/User" } },
                        "total_count": { "type": "integer" },
                        "page": { "type": "integer" },
                        "total_pages": { "type": "integer" }
                      }
                    }
                  }
                }
              }
            }
          },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/users/{user_id}": {
      "put": {
        "tags": ["users"],
        "summary": "Update user (admin)",
        "description": "Update any user's information (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "user_id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/AdminUpdateUserRequest" }
            }
          }
        },
        "responses": {
          "200": { "description": "User updated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/users/{user_id}/change-password": {
      "post": {
        "tags": ["users"],
        "summary": "Change user password (admin)",
        "description": "Change any user's password (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "user_id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/AdminChangePasswordRequest" }
            }
          }
        },
        "responses": {
          "200": { "description": "Password changed", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/referral-codes": {
      "get": {
        "tags": ["referral-codes"],
        "summary": "List referral codes",
        "description": "List referral codes. Regular users see only their own codes. Admins see all codes.",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
          { "name": "per_page", "in": "query", "schema": { "type": "integer", "default": 20 } },
          { "name": "search", "in": "query", "schema": { "type": "string" }, "description": "Search by code" },
          { "name": "status", "in": "query", "schema": { "type": "string", "enum": ["all", "active", "inactive"] }, "description": "Filter by status", "default": "all" }
        ],
        "responses": {
          "200": {
            "description": "List of referral codes",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "401": { "description": "Not authenticated" }
        }
      },
      "post": {
        "tags": ["referral-codes"],
        "summary": "Create referral code",
        "description": "Create a new referral code (admin only). If code is not provided, a random unique code will be generated.",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/CreateReferralCodeRequest" }
            }
          }
        },
        "responses": {
          "201": { "description": "Referral code created", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" },
          "400": { "description": "Code already exists" }
        }
      }
    },
    "/api/referral-codes/distribute": {
      "post": {
        "tags": ["referral-codes"],
        "summary": "Distribute referral codes",
        "description": "Distribute referral codes to users (admin only). Creates new codes and assigns them to specified users.",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/DistributeReferralCodesRequest" }
            }
          }
        },
        "responses": {
          "200": { "description": "Codes distributed", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/referral-codes/{code_id}/deactivate": {
      "post": {
        "tags": ["referral-codes"],
        "summary": "Deactivate referral code",
        "description": "Deactivate a specific referral code (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "code_id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "responses": {
          "200": { "description": "Code deactivated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/referral-codes/deactivate-all": {
      "post": {
        "tags": ["referral-codes"],
        "summary": "Deactivate all referral codes",
        "description": "Deactivate all referral codes (admin only)",
        "security": [{ "bearerAuth": [] }],
        "responses": {
          "200": { "description": "All codes deactivated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/scraper-jobs": {
      "get": {
        "tags": ["scrapers"],
        "summary": "List scraper jobs",
        "description": "List all scraper jobs (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "page", "in": "query", "schema": { "type": "integer", "default": 1 } },
          { "name": "per_page", "in": "query", "schema": { "type": "integer", "default": 20 } },
          { "name": "search", "in": "query", "schema": { "type": "string" } },
          { "name": "source", "in": "query", "schema": { "type": "string" } }
        ],
        "responses": {
          "200": {
            "description": "List of scraper jobs",
            "content": {
              "application/json": {
                "schema": { "$ref": "#/components/schemas/ApiResponse" }
              }
            }
          },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      },
      "post": {
        "tags": ["scrapers"],
        "summary": "Create scraper job",
        "description": "Create a new scraper job (admin only)",
        "security": [{ "bearerAuth": [] }],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/ScraperJob" }
            }
          }
        },
        "responses": {
          "201": { "description": "Scraper job created", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/scraper-jobs/active": {
      "get": {
        "tags": ["scrapers"],
        "summary": "List active scraper jobs",
        "description": "Get active scraper jobs (public endpoint for scraper app)",
        "responses": {
          "200": {
            "description": "List of active jobs",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": { "$ref": "#/components/schemas/ScraperJob" }
                }
              }
            }
          }
        }
      }
    },
    "/api/scraper-jobs/{id}": {
      "get": {
        "tags": ["scrapers"],
        "summary": "Get scraper job",
        "description": "Get scraper job details (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "responses": {
          "200": { "description": "Scraper job details", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" },
          "404": { "description": "Job not found" }
        }
      },
      "put": {
        "tags": ["scrapers"],
        "summary": "Update scraper job",
        "description": "Update scraper job (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/ScraperJob" }
            }
          }
        },
        "responses": {
          "200": { "description": "Job updated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      },
      "delete": {
        "tags": ["scrapers"],
        "summary": "Delete scraper job",
        "description": "Delete scraper job (admin only)",
        "security": [{ "bearerAuth": [] }],
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "responses": {
          "200": { "description": "Job deleted", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Not authenticated" },
          "403": { "description": "Admin only" }
        }
      }
    },
    "/api/scraper-jobs/{id}/stats": {
      "post": {
        "tags": ["scrapers"],
        "summary": "Update scraper job stats",
        "description": "Update scraper job statistics (public endpoint for scraper app)",
        "parameters": [
          { "name": "id", "in": "path", "required": true, "schema": { "type": "integer" } }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "success_count": { "type": "integer" },
                  "error_count": { "type": "integer" },
                  "last_error": { "type": "string", "nullable": true },
                  "last_run_at": { "type": "string", "format": "date-time" }
                }
              }
            }
          }
        },
        "responses": {
          "200": { "description": "Stats updated", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } }
        }
      }
    },
    "/api/vehicles/scraper": {
      "post": {
        "tags": ["scrapers"],
        "summary": "Import single vehicle (scraper)",
        "description": "Import a single vehicle from scraper (public endpoint, requires X-Scraper-Key header)",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": { "$ref": "#/components/schemas/Vehicle" }
            }
          }
        },
        "responses": {
          "201": { "description": "Vehicle imported", "content": { "application/json": { "schema": { "$ref": "#/components/schemas/ApiResponse" } } } },
          "401": { "description": "Invalid scraper key" }
        }
      }
    },
    "/api/vehicles/scraper/bulk": {
      "post": {
        "tags": ["scrapers"],
        "summary": "Bulk import vehicles (scraper)",
        "description": "Bulk import vehicles from scraper (public endpoint, requires X-Scraper-Key header). Uses Redis queue if direct import fails.",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "array",
                "items": { "$ref": "#/components/schemas/Vehicle" }
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Vehicles imported",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "message": { "type": "string" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "imported_count": { "type": "integer" },
                        "total_count": { "type": "integer" },
                        "queued": { "type": "boolean", "description": "Whether vehicles were queued" }
                      }
                    }
                  }
                }
              }
            }
          },
          "401": { "description": "Invalid scraper key" },
          "400": { "description": "No valid vehicles to import" }
        }
      }
    },
    "/api/maintenance/deactivate-stale-vehicles": {
      "post": {
        "tags": ["maintenance"],
        "summary": "Deactivate stale vehicles",
        "description": "Deactivate external vehicles not updated in X days (admin or cron job)",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "days": { "type": "integer", "default": 3, "description": "Days threshold" }
                }
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Stale vehicles deactivated",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "message": { "type": "string" },
                    "data": {
                      "type": "object",
                      "properties": {
                        "deactivated_count": { "type": "integer" }
                      }
                    }
                  }
                }
              }
            }
          },
          "401": { "description": "Not authenticated or invalid key" }
        }
      }
    },
    "/api/proxy": {
      "get": {
        "tags": ["maintenance"],
        "summary": "Proxy external URL",
        "description": "Proxy external URLs to bypass iframe restrictions",
        "parameters": [
          { "name": "url", "in": "query", "required": true, "schema": { "type": "string", "format": "uri" } }
        ],
        "responses": {
          "200": { "description": "Proxied content", "content": { "text/html": { "schema": { "type": "string" } } } },
          "400": { "description": "URL parameter required" },
          "502": { "description": "Failed to fetch URL" }
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "bearerAuth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "UUID",
        "description": "Use session UUID as bearer token. Get from login response."
      },
      "scraperKey": {
        "type": "apiKey",
        "in": "header",
        "name": "X-Scraper-Key",
        "description": "API key for scraper authentication"
      }
    },
    "schemas": {
      "Vehicle": {
        "type": "object",
        "required": ["brand", "model", "year", "price", "seller_name"],
        "properties": {
          "id": { "type": "integer", "readOnly": true },
          "slug": { "type": "string", "readOnly": true },
          "brand": { "type": "string", "example": "Honda" },
          "model": { "type": "string", "example": "Civic" },
          "year": { "type": "integer", "example": 2022 },
          "price": { "type": "string", "example": "85000.00" },
          "mileage": { "type": "string", "example": "50000 km" },
          "fuel_type": { "type": "string", "enum": ["Gasolina", "Flex", "Diesel", "Elétrico", "Híbrido"] },
          "color": { "type": "string", "example": "Branco" },
          "transmission": { "type": "string", "example": "Automática" },
          "description": { "type": "string" },
          "detailed_description_md": { "type": "string", "description": "Markdown description" },
          "image": { "type": "string", "format": "uri" },
          "images": { "type": "array", "items": { "type": "string", "format": "uri" } },
          "seller_id": { "type": "integer", "nullable": true },
          "seller_name": { "type": "string" },
          "seller_phone": { "type": "string" },
          "seller_email": { "type": "string" },
          "condition": { "type": "string", "enum": ["used", "new"], "default": "used" },
          "source": { "type": "string", "enum": ["buscar", "webmotors", "localiza", "icarros"], "default": "buscar" },
          "external_id": { "type": "string", "nullable": true },
          "external_url": { "type": "string", "format": "uri", "nullable": true },
          "engine": { "type": "string", "nullable": true },
          "doors": { "type": "integer", "default": 4 },
          "body_style": { "type": "string", "nullable": true },
          "features": { "type": "array", "items": { "type": "string" } },
          "vin": { "type": "string", "nullable": true },
          "license_plate": { "type": "string", "nullable": true },
          "previous_owners": { "type": "integer", "default": 1 },
          "service_history": { "type": "array", "items": { "type": "string" } },
          "modifications": { "type": "array", "items": { "type": "string" } },
          "included_items": { "type": "array", "items": { "type": "string" } },
          "exterior_condition": { "type": "string", "nullable": true },
          "interior_condition": { "type": "string", "nullable": true },
          "mechanical_condition": { "type": "string", "nullable": true },
          "inspection_notes": { "type": "string", "nullable": true },
          "location_city": { "type": "string", "example": "São Paulo" },
          "location_state": { "type": "string", "example": "SP" },
          "financing_available": { "type": "boolean", "default": false },
          "trade_accepted": { "type": "boolean", "default": false },
          "test_drive_available": { "type": "boolean", "default": false },
          "created_at": { "type": "string", "format": "date-time", "readOnly": true },
          "updated_at": { "type": "string", "format": "date-time", "readOnly": true },
          "is_active": { "type": "boolean", "readOnly": true },
          "deleted_at": { "type": "string", "format": "date-time", "nullable": true, "readOnly": true },
          "created_by": { "type": "integer", "nullable": true, "readOnly": true },
          "updated_by": { "type": "integer", "nullable": true, "readOnly": true },
          "original_id": { "type": "integer", "nullable": true, "readOnly": true },
          "version": { "type": "integer", "readOnly": true }
        }
      },
      "VehicleListResponse": {
        "type": "object",
        "properties": {
          "vehicles": { "type": "array", "items": { "$ref": "#/components/schemas/Vehicle" } },
          "total_count": { "type": "integer" },
          "page": { "type": "integer" },
          "total_pages": { "type": "integer" },
          "has_next": { "type": "boolean" },
          "has_prev": { "type": "boolean" }
        }
      },
      "User": {
        "type": "object",
        "properties": {
          "user_id": { "type": "integer" },
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "phone": { "type": "string", "nullable": true },
          "document_number": { "type": "string", "nullable": true },
          "address_street": { "type": "string", "nullable": true },
          "address_number": { "type": "string", "nullable": true },
          "address_complement": { "type": "string", "nullable": true },
          "address_neighborhood": { "type": "string", "nullable": true },
          "address_city": { "type": "string", "nullable": true },
          "address_state": { "type": "string", "nullable": true },
          "address_zipcode": { "type": "string", "nullable": true },
          "is_admin": { "type": "boolean" },
          "subscription_tier": { "type": "string", "enum": ["individual", "professional", "business"] },
          "is_active": { "type": "boolean" },
          "is_verified": { "type": "boolean" },
          "created_at": { "type": "string", "format": "date-time" },
          "updated_at": { "type": "string", "format": "date-time" }
        }
      },
      "LoginRequest": {
        "type": "object",
        "required": ["email", "password"],
        "properties": {
          "email": { "type": "string", "format": "email" },
          "password": { "type": "string" }
        }
      },
      "LoginResponse": {
        "type": "object",
        "properties": {
          "success": { "type": "boolean" },
          "message": { "type": "string" },
          "session_id": { "type": "string", "format": "uuid" },
          "user": { "$ref": "#/components/schemas/User" }
        }
      },
      "RegisterRequest": {
        "type": "object",
        "required": ["name", "email", "password", "phone", "document_number", "address_street", "address_number", "address_neighborhood", "address_city", "address_state", "address_zipcode", "referral_code"],
        "properties": {
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "password": { "type": "string", "minLength": 6 },
          "phone": { "type": "string" },
          "document_number": { "type": "string" },
          "address_street": { "type": "string" },
          "address_number": { "type": "string" },
          "address_complement": { "type": "string", "nullable": true },
          "address_neighborhood": { "type": "string" },
          "address_city": { "type": "string" },
          "address_state": { "type": "string" },
          "address_zipcode": { "type": "string" },
          "referral_code": { "type": "string" }
        }
      },
      "UpdateUserRequest": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "phone": { "type": "string", "nullable": true },
          "document_number": { "type": "string", "nullable": true },
          "address_street": { "type": "string", "nullable": true },
          "address_number": { "type": "string", "nullable": true },
          "address_complement": { "type": "string", "nullable": true },
          "address_neighborhood": { "type": "string", "nullable": true },
          "address_city": { "type": "string", "nullable": true },
          "address_state": { "type": "string", "nullable": true },
          "address_zipcode": { "type": "string", "nullable": true }
        }
      },
      "ChangePasswordRequest": {
        "type": "object",
        "required": ["old_password", "new_password"],
        "properties": {
          "old_password": { "type": "string" },
          "new_password": { "type": "string", "minLength": 6 }
        }
      },
      "AdminUpdateUserRequest": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "phone": { "type": "string", "nullable": true },
          "document_number": { "type": "string", "nullable": true },
          "address_street": { "type": "string", "nullable": true },
          "address_number": { "type": "string", "nullable": true },
          "address_complement": { "type": "string", "nullable": true },
          "address_neighborhood": { "type": "string", "nullable": true },
          "address_city": { "type": "string", "nullable": true },
          "address_state": { "type": "string", "nullable": true },
          "address_zipcode": { "type": "string", "nullable": true }
        }
      },
      "AdminChangePasswordRequest": {
        "type": "object",
        "required": ["user_id", "new_password"],
        "properties": {
          "user_id": { "type": "integer", "description": "ID of user to change password" },
          "new_password": { "type": "string", "minLength": 6, "description": "New password for the user" }
        }
      },
      "ReferralCode": {
        "type": "object",
        "properties": {
          "referral_code_id": { "type": "integer" },
          "code": { "type": "string" },
          "created_by_user_id": { "type": "integer" },
          "created_at": { "type": "string", "format": "date-time" },
          "is_active": { "type": "boolean" },
          "used_by_user_id": { "type": "integer", "nullable": true },
          "used_by_user_name": { "type": "string", "nullable": true },
          "used_at": { "type": "string", "format": "date-time", "nullable": true }
        }
      },
      "CreateReferralCodeRequest": {
        "type": "object",
        "properties": {
          "code": { "type": "string", "nullable": true, "description": "Custom code (optional, auto-generated if not provided)" }
        }
      },
      "DistributeReferralCodesRequest": {
        "type": "object",
        "properties": {
          "email": { "type": "string", "nullable": true, "description": "Email of user to distribute codes to. If null or 'all', distributes to all users." },
          "count": { "type": "integer", "default": 1, "description": "Number of codes to create per user" }
        }
      },
      "ScraperJob": {
        "type": "object",
        "required": ["brand", "model", "source"],
        "properties": {
          "scraper_job_id": { "type": "integer", "readOnly": true },
          "brand": { "type": "string", "example": "Honda" },
          "model": { "type": "string", "example": "Civic" },
          "source": { "type": "string", "enum": ["localiza", "icarros", "webmotors"] },
          "is_active": { "type": "boolean", "default": true },
          "last_run_at": { "type": "string", "format": "date-time", "nullable": true },
          "next_run_at": { "type": "string", "format": "date-time", "nullable": true },
          "run_count": { "type": "integer", "default": 0 },
          "success_count": { "type": "integer", "default": 0 },
          "error_count": { "type": "integer", "default": 0 },
          "last_error": { "type": "string", "nullable": true },
          "created_at": { "type": "string", "format": "date-time", "readOnly": true },
          "updated_at": { "type": "string", "format": "date-time", "readOnly": true },
          "created_by_user_id": { "type": "integer", "nullable": true }
        }
      },
      "FipeReference": {
        "type": "object",
        "properties": {
          "code": { "type": "string", "example": "278" },
          "month": { "type": "string", "example": "abril de 2024" }
        }
      },
      "FipeBrand": {
        "type": "object",
        "properties": {
          "code": { "type": "string", "example": "59" },
          "name": { "type": "string", "example": "VW - VolksWagen" }
        }
      },
      "FipeModel": {
        "type": "object",
        "properties": {
          "code": { "type": "string", "example": "5940" },
          "name": { "type": "string", "example": "Golf 1.6 16V Flex 4p" }
        }
      },
      "FipeYear": {
        "type": "object",
        "properties": {
          "code": { "type": "string", "example": "2020-1" },
          "name": { "type": "string", "example": "2020 Gasolina" }
        }
      },
      "FipeVehicleDetail": {
        "type": "object",
        "properties": {
          "brand": { "type": "string" },
          "codeFipe": { "type": "string" },
          "fuel": { "type": "string" },
          "fuelAcronym": { "type": "string" },
          "model": { "type": "string" },
          "modelYear": { "type": "integer" },
          "price": { "type": "string", "example": "85000.00" },
          "priceHistory": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "month": { "type": "string" },
                "price": { "type": "string" },
                "reference": { "type": "string" }
              }
            },
            "nullable": true
          },
          "referenceMonth": { "type": "string" },
          "vehicleType": { "type": "integer" }
        }
      },
      "ApiResponse": {
        "type": "object",
        "properties": {
          "success": { "type": "boolean" },
          "message": { "type": "string" },
          "data": { "type": "object", "nullable": true }
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
