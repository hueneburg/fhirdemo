extern crate core;

mod model;
mod api;
mod db;
mod middleware;
mod setid;

use crate::api::api::Api;
use crate::db::db::Db;
use deadpool::Runtime;
use std::sync::Arc;
use tokio_postgres::Error;
use tracing::Level;
use tracing_appender::rolling;
use tracing_subscriber::filter::LevelFilter;
use tracing_subscriber::fmt;
use tracing_subscriber::fmt::writer::MakeWriterExt;
use tracing_subscriber::layer::SubscriberExt;

#[tokio::main]
async fn main() {
    setup_cache().await.unwrap();
    let db = Db::create_connection("fhir", "127.0.0.1", "mypassword", "myuser", 5432);
    let api = Api::new(Arc::new(db));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, api.app).await.unwrap();
}

async fn setup_cache() -> Result<(), Error> {
    let cfg = deadpool_redis::Config::from_url("redis://default:mysecretpassword@127.0.0.1:6379");
    let pool = cfg.create_pool(Some(Runtime::Tokio1)).unwrap();
    let mut conn = pool.get().await.unwrap();
    deadpool_redis::redis::cmd("SET").arg(&["testkey", "42", "ex", "300"]).query_async::<()>(&mut conn).await.unwrap();
    return Ok(());
}

fn setup_tracing() {
    let file_appender = rolling::daily("/opt/fhir/logs/", "server.log");
    let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

    let file_layer = fmt::layer()
        .with_writer(non_blocking)
        .with_ansi(false)
        .with_filter(LevelFilter::DEBUG);

    let console_layer = fmt::layer()
        .with_writer(std::io::stdout)
        .with_ansi(true);

    tracing_subscriber::registry()
        .with(file_layer)
        .with(console_layer)
        .with(fmt::layer().with_max_level(Level::INFO))
        .init();
}
