FROM ocaml/opam:alpine-ocaml-4.14

# Install system dependencies
RUN sudo apk add --no-cache \
    sqlite sqlite-dev \
    libev-dev \
    openssl-dev \
    gmp-dev \
    postgresql-dev \
    pkgconfig

WORKDIR /app

# Update opam and install OCaml dependencies
RUN opam update && opam upgrade -y

# Install OCaml packages
RUN opam install \
    "ocamlfind>=1.9.8" \
    dune \
    lwt \
    dream \
    caqti \
    caqti-lwt \
    caqti-driver-postgresql \
    redis-lwt \
    ppx_deriving_yojson \
    yojson \
    logs \
    fmt \
    -y

# Copy source code
COPY --chown=opam:opam . .

# Build the application
RUN eval $(opam env) && dune build

# Expose port
EXPOSE 3000

# Run the application
CMD eval $(opam env) && dune exec bin/main.exe
