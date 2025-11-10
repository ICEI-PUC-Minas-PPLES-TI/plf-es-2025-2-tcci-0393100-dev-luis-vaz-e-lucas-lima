# Multi-stage build for BusCars Backend
FROM ocaml/opam:debian-11-ocaml-4.14 AS builder

# Install system dependencies  
USER root
RUN apt-get update && apt-get install -y \
    libpq-dev \
    pkg-config \
    m4 \
    libgmp-dev \
    libssl-dev \
    libev-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Switch back to opam user
USER opam
WORKDIR /home/opam/app

# Copy opam files first for better caching
COPY --chown=opam:opam buscar_backend.opam dune-project ./

# Install OCaml dependencies
RUN opam install . --deps-only -y

# Copy source code
COPY --chown=opam:opam . .

# Build the project
RUN eval $(opam env) && dune build --release

# Runtime stage
FROM debian:11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    libgmp10 \
    libssl1.1 \
    libev4 \
    zlib1g \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash buscar

# Copy binary from builder
COPY --from=builder /home/opam/app/_build/default/bin/main.exe /usr/local/bin/buscar_backend

# Switch to app user
USER buscar
WORKDIR /home/buscar

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD [ "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health" ]

# Run the application
CMD ["/usr/local/bin/buscar_backend"]

