pub mod api {
    use crate::db::db::Db;
    use crate::model::model::{Patient, PatientSearch, PatientStub};
    use crate::setid::SetId;
    use axum::extract::{Path, Query};
    use axum::http::StatusCode;
    use axum::routing::{get, put};
    use axum::{Extension, Json, Router};
    use std::str::FromStr;
    use std::sync::Arc;
    use uuid::Uuid;

    const UPSERT_PATIENT_PATH: &'static str = "/fhir/patient";
    const SEARCH_PATIENTS_PATH: &'static str = "/fhir/patient";
    const GET_PATIENT_PATH: &'static str = "/fhir/patient/{patient_id}";

    pub struct Api {
        pub app: Router<()>,
    }

    impl Api {
        pub fn new(db: Arc<Db>) -> Self {
            let app = Router::new()
                .route(UPSERT_PATIENT_PATH, put(Api::upsert_patient))
                .route(SEARCH_PATIENTS_PATH, get(Api::search_patient))
                .route(GET_PATIENT_PATH, get(Api::get_patient))
                .layer(Extension(db));
            Self { app }
        }

        async fn upsert_patient(Extension(db): Extension<Arc<Db>>,
                                Json(patient): Json<Patient>,
        ) -> Result<String, (StatusCode, String)> {
            let mut pc = patient.clone();
            pc.set_id(db.as_ref()).await;
            return db.upsert_patient(&mut pc)
                     .await
                     .map(|uuid| uuid.to_string())
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e));
        }

        async fn search_patient(Extension(db): Extension<Arc<Db>>,
                                Query(params): Query<PatientSearch>,
        ) -> Result<Json<Vec<PatientStub>>, (StatusCode, String)> {
            return db.search_patient(params)
                     .await
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e));
        }

        async fn get_patient(Extension(db): Extension<Arc<Db>>,
                             Path(patient_id): Path<String>,
        ) -> Result<Json<Patient>, (StatusCode, String)> {
            let uuid = Uuid::from_str(&patient_id).unwrap();
            return db.get_patient(uuid)
                     .await
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))
                     .map(Json);
        }
    }
}
