extern crate core;

use std::io;
use tracing_subscriber::Layer;

mod model;
mod api;
mod db;
mod cache;
mod setid;

use crate::api::api::Api;
use crate::cache::cache::Cache;
use crate::db::db::Db;
use deadpool::Runtime;
use rand::Rng;
use std::sync::Arc;
use tracing::{error, Level};
use tracing_appender::rolling;
use tracing_subscriber::filter::{filter_fn, LevelFilter};
use tracing_subscriber::fmt;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

#[tokio::main]
async fn main() {
    setup_tracing();
    let cache = setup_cache().await;
    let db = Db::create_connection("fhir", "127.0.0.1", "mypassword", "myuser", 5432);
    let api = Api::new(Arc::new(db), cache);

    let listener = match tokio::net::TcpListener::bind("0.0.0.0:8080").await {
        Ok(listener) => listener,
        Err(e) => {
            error!(?e, "Could not start listening on port 8080");
            panic!("Application start impossible");
        }
    };
    match axum::serve(listener, api.app).await {
        Ok(_) => (),
        Err(e) => {
            error!(?e, "Could not start application server");
            panic!("Application server failed to start");
        }
    };
}

async fn setup_cache() -> Cache {
    let cache = Cache::new("redis://default:mysecretpassword@127.0.0.1:6379").await;
    return cache;
}

fn setup_tracing() {
    let file_appender = rolling::daily("/opt/fhir/logs/", "server.log");
    let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

    let sampling_filter = filter_fn(|metadata| {
        let level = *metadata.level();
        match level {
            Level::TRACE | Level::DEBUG | Level::INFO => {
                // Keep ~1% of lower-level logs
                let mut rng = rand::rng();
                rng.random_range(0..100) == 0
            }
            Level::WARN | Level::ERROR => true,
        }
    });

    let file_layer = fmt::layer()
        .with_writer(non_blocking)
        .with_ansi(false)
        .with_filter(sampling_filter);

    let console_layer = fmt::layer()
        .with_writer(std::io::stdout)
        .with_ansi(true)
        .with_filter(LevelFilter::TRACE);

    tracing_subscriber::registry()
        .with(file_layer)
        .with(console_layer)
        .init();
}
