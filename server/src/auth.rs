pub mod auth {
    use axum::extract::State;
    use axum::middleware::Next;
    use axum_core::body::Body;
    use axum_core::extract::Request;
    use axum_core::response::Response;
    use http::{HeaderValue, StatusCode};
    use std::env;

    #[derive(Clone)]
    pub struct Auth {
        read_token: String,
        write_token: String,
    }

    impl Auth {
        pub fn new() -> Self {
            let read_token = match env::var_os("FHIR_READ_TOKEN") {
                Some(val) => val.into_string().unwrap(),
                None => "read".to_string(),
            };
            let write_token = match env::var_os("FHIR_WRITE_TOKEN") {
                None => "write".to_string(),
                Some(val) => val.into_string().unwrap(),
            };
            return Self { read_token, write_token };
        }

        pub async fn auth_middleware(
            State(auth): State<Auth>,
            req: Request<Body>,
            next: Next,
        ) -> Response<Body> {
            return if let Some(Ok(token)) = req.headers()
                                               .get("Authorization")
                                               .map(HeaderValue::to_str) {
                if req.method() == http::Method::POST || req.method() == http::Method::PUT {
                    if token == auth.write_token {
                        next.run(req).await
                    } else {
                        Response::builder().status(StatusCode::UNAUTHORIZED)
                                           .body(Body::empty())
                                           .unwrap()
                    }
                } else {
                    // read API
                    if token == auth.read_token || token == auth.write_token {
                        next.run(req).await
                    } else {
                        Response::builder().status(StatusCode::UNAUTHORIZED)
                                           .body(Body::empty())
                                           .unwrap()
                    }
                }
            } else {
                Response::builder().status(StatusCode::UNAUTHORIZED)
                                   .body(Body::empty())
                                   .unwrap()
            };
        }
    }
}
