FROM rust:1.89.0-bullseye

WORKDIR /usr/src/fhir
COPY . .

RUN cargo install --path .

CMD ["cargo", "run", "--release"]