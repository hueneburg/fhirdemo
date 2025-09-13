mod patient;

use crate::patient::{Patient, PatientSearch, PatientUpdate};
use axum::{extract::{Path, Query}, routing::{get, post, put}, Json, Router};
use tokio_postgres::{Error, NoTls};

#[tokio::main]
async fn main() {
    db_setup().await.unwrap();
    let app = Router::new().route("/fhir/Patient/{patient_id}", get(get_patient))
                           .route("/fhir/Patient", post(create_patient))
                           .route("/fhir/Patient", get(search_patients))
                           .route("/fhir/Patient/{patient_id}", put(update_patient));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn db_setup() -> Result<(), Error> {
    let (client, connection) = tokio_postgres::connect("host=192.168.10.109 user=myuser dbname=fhir password=mypassword", NoTls).await?;
    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("connection error: {}", e);
        }
    });
    let rows = client.query("SELECT * FROM element;", &[]).await?;

    let value: &str = rows[0].get(0);
    print!("DB connection set up");
    print!("{}", value);

    return Result::Ok(());
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
