FROM rust:1.89.0-bullseye

WORKDIR /usr/src/fhirdemo
COPY . .

RUN cargo install --path .

CMD ["target/release/FhirDemo"]

