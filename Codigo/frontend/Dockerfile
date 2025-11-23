FROM ocaml/opam:alpine-ocaml-4.14

WORKDIR /app

# Install system dependencies and timezone data
USER root
RUN apk add --no-cache sqlite sqlite-dev libev-dev openssl-dev gmp-dev tzdata

# Set timezone to São Paulo
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

USER opam

# Upgrade opam to latest version and update repositories
RUN opam update && opam upgrade -y

# Install dependencies with specific ocamlfind version
RUN opam install "ocamlfind>=1.9.8" dune lwt dream yojson ppx_deriving_yojson logs fmt cohttp-lwt-unix -y

# Copy project files
COPY --chown=opam:opam . .

# Build the project
RUN eval $(opam env) && dune build

EXPOSE 8080

CMD eval $(opam env) && dune exec ./bin/buscar.exe