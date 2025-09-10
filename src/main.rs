mod patient;

use crate::patient::{Patient, PatientSearch, PatientUpdate};
use axum::{extract::{Path, Query}, routing::{get, post, put}, Json, Router};

#[tokio::main]
async fn main() {
    let app = Router::new().route("/fhir/Patient/{patient_id}", get(get_patient))
                           .route("/fhir/Patient", post(create_patient))
                           .route("/fhir/Patient", get(search_patients))
                           .route("/fhir/Patient/{patient_id}", put(update_patient));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
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
