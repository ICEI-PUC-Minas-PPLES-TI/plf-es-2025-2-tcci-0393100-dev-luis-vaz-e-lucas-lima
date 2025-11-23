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
    libcurl4-gnutls-dev \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Switch back to opam user
USER opam
WORKDIR /home/opam/app

# Copy dependency files
COPY app_scrappers.opam dune-project ./

# Install dependencies
RUN opam install . --deps-only -y

# Copy source code
COPY . .

# Clean any existing build artifacts and ensure proper permissions
RUN rm -rf _build || true

# Build the application
RUN opam exec -- dune build --release

# Runtime stage
FROM debian:11-slim

WORKDIR /app

# Install runtime dependencies and timezone data
RUN apt-get update && \
    apt-get install -y \
      libssl1.1 \
      libpq5 \
      libcurl4-gnutls-dev \
      ca-certificates \
      curl \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# Set timezone to São Paulo
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Copy the binary
COPY --from=builder /home/opam/app/_build/install/default/bin/app_scrappers /usr/local/bin/app_scrappers

# Run the application
CMD ["/usr/local/bin/app_scrappers"]
