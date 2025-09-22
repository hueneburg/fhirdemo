pub mod api {
    use crate::cache::cache::Cache;
    use crate::db::db::Db;
    use crate::model::model::{Patient, PatientSearch, PatientStub};
    use crate::setid::SetId;
    use axum::extract::{Path, Query, State};
    use axum::http::StatusCode;
    use axum::middleware::{from_fn, from_fn_with_state, Next};
    use axum::routing::{get, put};
    use axum::{Extension, Json, Router};
    use axum_core::body::Body;
    use axum_core::extract::Request;
    use axum_core::response::Response;
    use std::str::FromStr;
    use std::sync::Arc;
    use tracing::error;
    use uuid::Uuid;

    const UPSERT_PATIENT_PATH: &'static str = "/fhir/patient";
    const SEARCH_PATIENTS_PATH: &'static str = "/fhir/patient";
    const GET_PATIENT_PATH: &'static str = "/fhir/patient/{patient_id}";

    pub struct Api {
        pub app: Router<()>,
    }

    impl Api {
        pub fn new(db: Arc<Db>, cache: Cache) -> Self {
            let app = Router::new()
                .route(UPSERT_PATIENT_PATH, put(Api::upsert_patient))
                .route(SEARCH_PATIENTS_PATH, get(Api::search_patient))
                .route_layer(from_fn_with_state(cache, Api::get_patient_cache_layer))
                .route(GET_PATIENT_PATH, get(Api::get_patient))
                .layer(Extension(db));
            Self { app }
        }


        async fn get_patient_cache_layer(
            State(cache): State<Cache>,
            request: Request<Body>,
            next: Next,
        ) -> Response<Body> {
            return cache.get_patient_caching_layer(request, next).await;
        }

        async fn upsert_patient(Extension(db): Extension<Arc<Db>>,
                                Json(patient): Json<Patient>,
        ) -> Result<String, (StatusCode, String)> {
            let mut pc = patient.clone();
            pc.set_id(db.as_ref())
              .await
              .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
            return db.upsert_patient(&mut pc)
                     .await
                     .map(|uuid| uuid.to_string())
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()));
        }

        async fn search_patient(Extension(db): Extension<Arc<Db>>,
                                Query(params): Query<PatientSearch>,
        ) -> Result<Json<Vec<PatientStub>>, (StatusCode, String)> {
            return db.search_patient(params)
                     .await
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()));
        }

        async fn get_patient(Extension(db): Extension<Arc<Db>>,
                             Path(patient_id): Path<String>,
        ) -> Result<Json<Patient>, (StatusCode, String)> {
            let uuid = match Uuid::from_str(&patient_id) {
                Ok(uuid) => uuid,
                Err(error) => {
                    error!(?error, "Could not parse UUID");
                    return Err((StatusCode::BAD_REQUEST, "UUID format".to_string()));
                }
            };
            return db.get_patient(uuid)
                     .await
                     .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))
                     .map(Json);
        }
    }
}
