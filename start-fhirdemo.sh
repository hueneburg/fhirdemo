#! /usr/bin/env bash

docker compose down
# Clean the directory in case the tests failed in the previous run
cargo clean -v --manifest-path server/Cargo.toml
cargo test --manifest-path server/Cargo.toml || exit 1
# Clean the directory so that the target directory of the tests is removed
cargo clean -v --manifest-path server/Cargo.toml
# Start the app in daemon mode
docker compose up -d app
