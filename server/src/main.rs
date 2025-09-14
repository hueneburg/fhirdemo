mod patient;

use crate::patient::{Patient, PatientSearch, PatientUpdate};
use axum::{extract::{Path, Query}, routing::{get, post, put}, Json, Router};
use deadpool::Runtime;
use tokio_postgres::{Error, NoTls};
use uuid::Uuid;

#[tokio::main]
async fn main() {
    db_setup().await.unwrap();
    setup_cache().await.unwrap();
    let app = Router::new().route("/fhir/Patient/{patient_id}", get(get_patient))
                           .route("/fhir/Patient", post(create_patient))
                           .route("/fhir/Patient", get(search_patients))
                           .route("/fhir/Patient/{patient_id}", put(update_patient));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn db_setup() -> Result<(), Error> {
    let mut cfg = tokio_postgres::Config::new();
    cfg.dbname("fhir".to_string())
       .host("127.0.0.1".to_string())
       .password("mypassword".to_string())
       .user("myuser".to_string());
    let mgrCfg = deadpool_postgres::ManagerConfig {
        recycling_method: deadpool_postgres::RecyclingMethod::Fast,
    };

    let mgr = deadpool_postgres::Manager::from_config(cfg, NoTls, mgrCfg);
    let pool = deadpool_postgres::Pool::builder(mgr).max_size(16).build().unwrap();

    let client = pool.get().await.unwrap();

    let rows = client.query("SELECT * FROM element;", &[]).await?;

    let value: String = rows.into_iter()
                            .map(|row| row.get::<usize, Uuid>(0).to_string())
                            .collect::<Vec<_>>()
                            .join(", ");
    println!("PostgreSQL DB connection set up");
    println!("{}", value);

    return Ok(());
}

async fn setup_cache() -> Result<(), Error> {
    let mut cfg = deadpool_redis::Config::from_url("redis://default:mysecretpassword@127.0.0.1:6379");
    let pool = cfg.create_pool(Some(Runtime::Tokio1)).unwrap();
    let mut conn = pool.get().await.unwrap();
    deadpool_redis::redis::cmd("SET").arg(&["testkey", "42", "ex", "300"]).query_async::<()>(&mut conn).await.unwrap();
    return Ok(());
}

async fn get_patient(Path(patient_id): Path<String>) -> String {
    return patient_id;
}
async fn search_patients(Query(params): Query<PatientSearch>) -> Json<Vec<String>> {
    return Json(Vec::new());
}
async fn create_patient(Json(params): Json<Patient>) -> Json<bool> {
    return Json(true);
}
async fn update_patient(Path(patient_id): Path<String>,
                        Json(new_data): Json<PatientUpdate>) -> Json<bool> {
    return Json(true);
}
