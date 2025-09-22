pub mod cache {
    use axum::body::Body;
    use axum::extract::Path;
    use axum::middleware::Next;
    use axum::response::Response;
    use axum_core::extract::Request;
    use deadpool::Runtime;
    use deadpool_redis::redis::AsyncTypedCommands;
    use http_body_util::BodyExt;
    use tracing::error;
    use uuid::Uuid;

    #[derive(Clone)]
    pub struct Cache {
        pool: deadpool_redis::Pool,
    }

    impl Cache {
        pub async fn new(url: &str) -> Self {
            let cfg = deadpool_redis::Config::from_url(url);
            let pool = match cfg.create_pool(Some(Runtime::Tokio1)) {
                Ok(pool) => pool,
                Err(e) => {
                    panic!("Failed to create Redis cache: {}", e);
                }
            };
            return Self { pool };
        }

        pub async fn get_patient_caching_layer(&self, req: Request<Body>, next: Next) -> Response<Body> {
            let id = match req.extensions().get::<Path<Uuid>>() {
                Some(Path(id)) => *id, // copy the UUID
                None => {
                    error!("Could not extract id path");
                    return Response::builder().status(500).body(Body::empty()).unwrap();
                }
            };
            let mut client = match self.pool.get().await {
                Ok(client) => client,
                Err(e) => {
                    error!(?e, "Could not open connection to cache");
                    return Response::builder().status(500).body(Body::empty()).unwrap();
                }
            };

            let cache_result = match client.get(id.to_string()).await {
                Ok(res) => res,
                Err(e) => {
                    error!(?e, "Error when querying cache");
                    return Response::builder().status(500).body(Body::empty()).unwrap();
                }
            };

            if let Some(json) = cache_result {
                return Response::builder().status(200).body(Body::from(json)).unwrap();
            }

            let res = next.run(req).await;

            return if res.status() == 200 {
                let (parts, body) = res.into_parts();

                match body.collect().await {
                    Ok(collected) => {
                        let body_bytes = collected.to_bytes();

                        let _ = client.set_ex::<>(
                            &id.to_string(),
                            String::from_utf8_lossy(&body_bytes.to_vec()),
                            300,
                        ).await;

                        Response::from_parts(parts, Body::from(body_bytes))
                    }
                    Err(e) => {
                        error!(?e, "Error reading body");
                        Response::from_parts(parts, Body::empty())
                    }
                }
            } else {
                res
            };
        }
    }
}
