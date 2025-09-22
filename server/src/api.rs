pub mod api {
    use crate::auth::auth::Auth;
    use crate::cache::cache::Cache;
    use crate::db::db::Db;
    use crate::model::model::{Patient, PatientSearch, PatientStub};
    use crate::setid::SetId;
    use axum::extract::{ConnectInfo, Path, Query, State};
    use axum::http::StatusCode;
    use axum::middleware::{from_fn, from_fn_with_state, Next};
    use axum::routing::{get, put};
    use axum::{Extension, Json, Router};
    use axum_core::body::Body;
    use axum_core::extract::Request;
    use axum_core::response::Response;
    use std::net::SocketAddr;
    use std::str::FromStr;
    use std::sync::Arc;
    use tracing::{error, info_span, Instrument};
    use uuid::Uuid;

    const UPSERT_PATIENT_PATH: &'static str = "/fhir/patient";
    const SEARCH_PATIENTS_PATH: &'static str = "/fhir/patient";
    const GET_PATIENT_PATH: &'static str = "/fhir/patient/{patient_id}";

    pub struct Api {
        pub app: Router<()>,
    }

    impl Api {
        pub fn new(db: Arc<Db>, cache: Cache) -> Self {
            let auth = Auth::new();
            let app = Router::new()
                .route(UPSERT_PATIENT_PATH, put(Api::upsert_patient))
                .route(SEARCH_PATIENTS_PATH, get(Api::search_patient))
                .route_layer(from_fn_with_state(cache, Api::get_patient_cache_layer))
                .route(GET_PATIENT_PATH, get(Api::get_patient))
                .layer(from_fn(tracing_middleware))
                .layer(from_fn_with_state(auth, Auth::auth_middleware))
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

    async fn tracing_middleware(ConnectInfo(remote): ConnectInfo<SocketAddr>,
                                req: Request<Body>,
                                next: Next) -> Response {
        let request_id = Uuid::new_v4();
        let method = req.method().clone();
        let uri = req.uri().clone();

        let ip = match remote {
            SocketAddr::V4(v4) => {
                let octets = v4.ip().octets();
                // zero the last octet
                format!("{}.{}.{}.0", octets[0], octets[1], octets[2])
            }
            SocketAddr::V6(v6) => {
                let segments = v6.ip().segments();
                // zero the last segment
                format!(
                    "{:x}:{:x}:{:x}:{:x}:{:x}:{:x}:{:x}:0",
                    segments[0], segments[1], segments[2], segments[3],
                    segments[4], segments[5], segments[6]
                )
            }
        };

        let span = info_span!("request", %request_id, %method, %uri, %ip);
        return next.run(req).instrument(span).await;
    }
}
