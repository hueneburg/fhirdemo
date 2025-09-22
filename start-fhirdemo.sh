#! /usr/bin/env bash

cargo test --manifest-path server/Cargo.toml || exit 1
docker compose up app
