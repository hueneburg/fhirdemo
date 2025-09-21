pub mod db {
    use crate::model::model::{Patient, PatientSearch, PatientStub};
    use axum::Json;
    use deadpool::managed::{Object, Pool};
    use deadpool_postgres::Manager;
    use tokio_postgres::NoTls;
    use uuid::Uuid;

    pub struct Db {
        pool: Pool<Manager, Object<Manager>>,
    }

    impl Db {
        pub fn create_connection(dbname: &str,
                                 host: &str,
                                 password: &str,
                                 username: &str,
                                 port: u16,
        ) -> Self {
            // Setup config
            let mut config = tokio_postgres::Config::new();
            config.dbname(dbname.to_string())
                  .host(host.to_string())
                  .password(password.to_string())
                  .user(username.to_string())
                  .port(port);
            let manager_config = deadpool_postgres::ManagerConfig {
                recycling_method: deadpool_postgres::RecyclingMethod::Fast,
            };
            let mgr = Manager::from_config(config, NoTls, manager_config);

            // Setup connection pool
            let pool = Pool::builder(mgr)
                .max_size(16)
                .build()
                .unwrap();
            Self { pool }
        }

        /// Updates or inserts the patient into the DB.
        /// Assumption: Nested documents have IDs assigned where appropriate.
        /// Sets the id of patient if it isn't set already.
        /// Returns patient.id.
        pub async fn upsert_patient(&self,
                                    patient: &mut Patient,
        ) -> Result<Uuid, String> {
            let client = self.pool.get().await.unwrap();
            let json = serde_json::to_value(patient).unwrap();
            let row = client.query_one("SELECT fhir.upsert_patient($1);", &[&json]).await.unwrap();
            return Ok(row.get(0));
        }

        /// Returns the patient with the ID.
        pub async fn get_patient(&self, patient_id: Uuid) -> Result<Patient, String> {
            let client = self.pool.get().await.unwrap();
            let row = client.query_one("SELECT fhir.get_patient($1)", &[&patient_id]).await.unwrap();

            return Ok(serde_json::from_value(row.get(0)).unwrap());
        }

        /// Creates a unique identifier across the DB that can be used for any kind of object.
        pub async fn get_id(&self) -> String {
            let client = self.pool.get().await.unwrap();
            return client.query_one("SELECT fhir.get_uuid();", &[]).await.unwrap().get::<_, Uuid>(0).to_string();
        }

        /// Allows for searching patients.
        pub async fn search_patient(&self,
                                    params: PatientSearch) -> Result<Json<Vec<PatientStub>>, String> {
            let client = self.pool.get().await.unwrap();
            let row = client.query_one(
                "SELECT fhir.search_patients($1);",
                &[&serde_json::to_value(params).unwrap()]).await.unwrap();
            return Ok(Json(serde_json::from_value(row.get(0)).unwrap()));
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;
        use crate::model::model::Gender::{Female, Male, Unknown};
        use crate::model::model::HumanNameUse::Official;
        use crate::model::model::SearchOperator::{And, Or};
        use crate::model::model::*;
        use chrono::DateTime;
        use deadpool_postgres::GenericClient;
        use speculoos::assert_that;
        use speculoos::prelude::ContainingIntoIterAssertions;
        use testcontainers::core::{IntoContainerPort, WaitFor};
        use testcontainers::runners::AsyncRunner;
        use testcontainers::{ContainerAsync, GenericImage, ImageExt};
        use tokio::fs::read_to_string;
        use tokio_postgres::SimpleQueryMessage;
        use crate::setid::SetId;

        struct TestDb {
            db: Db,
            _image: ContainerAsync<GenericImage>,
        }

        /// Set up the DB with testcontainers, using the schema from the DB in the same project.
        async fn setup() -> TestDb {
            let image = GenericImage::new("postgres", "17.6-alpine3.22")
                .with_exposed_port(5432.tcp())
                .with_wait_for(WaitFor::message_on_stdout("PostgreSQL init process complete; ready for start up."))
                .with_wait_for(WaitFor::message_on_stdout("database system is ready to accept connections"))
                // Wait 5 seconds for it to start because for some reason,
                // it cannot connect otherwise.
                .with_wait_for(WaitFor::seconds(5))
                .with_env_var("POSTGRES_DB", "fhir")
                .with_env_var("POSTGRES_USER", "myuser")
                .with_env_var("POSTGRES_PASSWORD", "mypassword")
                .start()
                .await
                .expect("Failed to start postgresql");

            let db = Db::create_connection("fhir",
                                           image.get_host().await.unwrap().to_string().as_str(),
                                           "mypassword",
                                           "myuser",
                                           image.get_host_port_ipv4(5432).await.unwrap());

            let client = db.pool.get().await.unwrap();

            // Path to schema and extension
            let ext = read_to_string("../db/patient-extension/patient--1.0.sql")
                .await
                .unwrap();
            // Does not load extension as an actual extension but as a normal schema
            let schema = read_to_string("../db/01-schema.sql")
                .await
                .unwrap();

            client.batch_execute(schema.as_str()).await.unwrap();
            client.batch_execute(ext.as_str()).await.unwrap();

            return TestDb { _image: image, db };
        }

        #[tokio::test]
        async fn test_empty_patient() {
            let test_db = setup().await;
            let db = test_db.db;

            db.upsert_patient(&mut get_empty_patient()).await.unwrap();

            let client = db.pool.get().await.unwrap();
            let patient_count: i64 = client.query_one("SELECT count(1) FROM fhir.patient;",
                                                      &[])
                                           .await
                                           .unwrap()
                                           .get(0);

            assert_that(&patient_count).is_equal_to(1);
        }

        #[tokio::test]
        async fn test_full_patient() {
            let test_db = setup().await;
            let db = test_db.db;

            let patient = &mut get_full_patient(&db).await;
            let id = db.upsert_patient(&mut patient.clone()).await.unwrap();

            patient.id = Some(id.to_string());

            let res = db.get_patient(id).await.unwrap();

            assert_that(&res).is_equal_to(patient);
        }

        #[tokio::test]
        async fn test_update_patient() {
            let test_db = setup().await;
            let db = test_db.db;

            let client = db.pool.get().await.unwrap();

            let orig = get_empty_patient();
            let new = &mut get_full_patient(&db).await;

            let id = db.upsert_patient(&mut orig.clone()).await.unwrap();
            let orig_count: i64 = client.query_one("SELECT count(1) FROM fhir.patient;",
                                                   &[])
                                        .await
                                        .unwrap()
                                        .get(0);

            new.id = Some(id.to_string());

            db.upsert_patient(new).await.unwrap();

            let res = db.get_patient(id).await.unwrap();
            let new_count: i64 = client.query_one("SELECT count(1) FROM fhir.patient;",
                                                  &[])
                                       .await
                                       .unwrap()
                                       .get(0);

            assert_that(&orig_count).is_equal_to(new_count);
            assert_that(&res).is_equal_to(new);
        }

        #[tokio::test]
        async fn test_search_patient_and() {
            let test_db = setup().await;
            let db = test_db.db;

            let a = &mut get_empty_patient();
            let b = &mut get_empty_patient();
            let c = &mut get_empty_patient();
            let d = &mut get_empty_patient();
            let e = &mut get_empty_patient();
            let f = &mut get_empty_patient();
            let g = &mut get_empty_patient();

            a.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["A".to_string()]),
                text: Some("A Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            a.birth_date = Some("1992".to_string());
            a.gender = Some(Female);

            b.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["B".to_string()]),
                text: Some("B Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            b.birth_date = Some("1992-09".to_string());
            b.gender = Some(Male);

            c.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["C".to_string()]),
                text: Some("C Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            c.birth_date = Some("1993-09-02".to_string());
            c.gender = Some(Female);

            d.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["D".to_string()]),
                text: Some("D Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            d.birth_date = Some("1992-09-02".to_string());
            d.gender = Some(Male);

            e.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["E".to_string()]),
                text: Some("E Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            e.birth_date = Some("1994".to_string());
            e.gender = Some(Female);

            f.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["F".to_string()]),
                text: Some("F Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            f.birth_date = Some("1992-08".to_string());
            f.gender = Some(Male);

            g.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["G".to_string()]),
                text: Some("G Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            g.birth_date = Some("1993-10".to_string());
            g.gender = Some(Female);

            db.upsert_patient(a).await.unwrap();
            db.upsert_patient(b).await.unwrap();
            db.upsert_patient(c).await.unwrap();
            db.upsert_patient(d).await.unwrap();
            db.upsert_patient(e).await.unwrap();
            db.upsert_patient(f).await.unwrap();
            db.upsert_patient(g).await.unwrap();

            let page1_name = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: None,
                    operator: And,
                    count: 3,
                    last_id: None,
                }
            ).await.unwrap();
            let page2_name = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: None,
                    operator: And,
                    count: 3,
                    last_id: page1_name.last().unwrap().id.clone(),
                }
            ).await.unwrap();
            assert_that(&(page1_name.len())).is_equal_to(3);
            assert_that(&(page2_name.len())).is_equal_to(1);

            let page_bday = db.search_patient(
                PatientSearch {
                    name: None,
                    birthdate_from: Some("1992-09-02".to_string()),
                    birthdate_until: Some("1993-09-02".to_string()),
                    gender: None,
                    operator: And,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_bday.len())).is_equal_to(4);

            let page_gender = db.search_patient(
                PatientSearch {
                    name: None,
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: Some(Female),
                    operator: And,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_gender.len())).is_equal_to(4);

            let page_and = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: Some(Female),
                    operator: And,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_and.len())).is_equal_to(2);
        }

        #[tokio::test]
        async fn test_search_patient_or() {
            let test_db = setup().await;
            let db = test_db.db;

            let a = &mut get_empty_patient();
            let b = &mut get_empty_patient();
            let c = &mut get_empty_patient();
            let d = &mut get_empty_patient();
            let e = &mut get_empty_patient();
            let f = &mut get_empty_patient();
            let g = &mut get_empty_patient();

            a.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["A".to_string()]),
                text: Some("A Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            a.birth_date = Some("1992".to_string());
            a.gender = Some(Female);

            b.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["B".to_string()]),
                text: Some("B Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            b.birth_date = Some("1992-09".to_string());
            b.gender = Some(Male);

            c.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["C".to_string()]),
                text: Some("C Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            c.birth_date = Some("1993-09-02".to_string());
            c.gender = Some(Female);

            d.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meier".to_string()),
                given: Vec::from(["D".to_string()]),
                text: Some("D Meier".to_string()),
                human_name_use: Some(Official),
            }]);
            d.birth_date = Some("1992-09-02".to_string());
            d.gender = Some(Male);

            e.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["E".to_string()]),
                text: Some("E Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            e.birth_date = Some("1994".to_string());
            e.gender = Some(Female);

            f.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["F".to_string()]),
                text: Some("F Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            f.birth_date = Some("1992-08".to_string());
            f.gender = Some(Male);

            g.name = Vec::from([HumanName {
                id: Some(db.get_id().await),
                extension: Vec::new(),
                period: None,
                prefix: Vec::new(),
                suffix: Vec::new(),
                family: Some("Meyer".to_string()),
                given: Vec::from(["G".to_string()]),
                text: Some("G Meyer".to_string()),
                human_name_use: Some(Official),
            }]);
            g.birth_date = Some("1993-10".to_string());
            g.gender = Some(Female);

            db.upsert_patient(a).await.unwrap();
            db.upsert_patient(b).await.unwrap();
            db.upsert_patient(c).await.unwrap();
            db.upsert_patient(d).await.unwrap();
            db.upsert_patient(e).await.unwrap();
            db.upsert_patient(f).await.unwrap();
            db.upsert_patient(g).await.unwrap();

            let page1_name = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: None,
                    operator: Or,
                    count: 3,
                    last_id: None,
                }
            ).await.unwrap();
            let page2_name = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: None,
                    operator: Or,
                    count: 3,
                    last_id: page1_name.last().unwrap().id.clone(),
                }
            ).await.unwrap();
            assert_that(&(page1_name.len())).is_equal_to(3);
            assert_that(&(page2_name.len())).is_equal_to(1);

            let page_bday = db.search_patient(
                PatientSearch {
                    name: None,
                    birthdate_from: Some("1992-09-02".to_string()),
                    birthdate_until: Some("1993-09-02".to_string()),
                    gender: None,
                    operator: Or,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_bday.len())).is_equal_to(4);

            let page_gender = db.search_patient(
                PatientSearch {
                    name: None,
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: Some(Female),
                    operator: Or,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_gender.len())).is_equal_to(4);

            let page_or = db.search_patient(
                PatientSearch {
                    name: Some("Meier".to_string()),
                    birthdate_from: None,
                    birthdate_until: None,
                    gender: Some(Female),
                    operator: Or,
                    count: 100,
                    last_id: None,
                }
            ).await.unwrap();
            assert_that(&(page_or.len())).is_equal_to(6);
        }

        #[tokio::test]
        async fn test_get_id() {
            let test_db = setup().await;
            let db = test_db.db;

            let client = db.pool.get().await.unwrap();

            let as_is_res = client.simple_query("SELECT id FROM fhir.id_list;").await.unwrap();
            let mut uuids: Vec<String> = Vec::new();

            for _ in 1..10 {
                uuids.push(db.get_id().await);
            }

            let to_be_res = client.simple_query("SELECT id FROM fhir.id_list;").await.unwrap();
            let mut db_ids: Vec<String> = Vec::new();

            for message in &to_be_res {
                if let SimpleQueryMessage::Row(row) = message {
                    db_ids.push(row.get(0).unwrap().to_string());
                }
            }

            assert_that(&(to_be_res.len() - as_is_res.len())).is_equal_to(uuids.len());
            assert_that(&(db_ids)).contains_all_of(&(uuids.iter().collect::<Vec<_>>()));
        }

        #[tokio::test]
        async fn test_set_id_trait() {
            let test_db = setup().await;
            let db = test_db.db;
            let client = db.pool.get().await.unwrap();

            let id_count: i64 = client.query_one("SELECT COUNT(1) FROM fhir.id_list", &[]).await.unwrap().get(0);

            let mut patient = get_empty_patient();

            patient.meta = Some(Meta {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                profile: vec!["".to_string()],
                security: vec![Coding {
                    id: None,
                    version: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    display: None,
                    system: None,
                    user_selected: None,
                    code: None,
                }],
                source: None,
                tag: vec![Coding {
                    id: None,
                    user_selected: None,
                    display: None,
                    code: None,
                    version: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    system: None,
                }],
            });

            patient.text = Some(Narrative {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                div: "div".to_string(),
                status: NarrativeStatus::Additional,
            });

            patient.contained = vec![Resource {
                id: None,
                implicit_rules: Vec::new(),
                meta: Some(Meta {
                    id: None,
                    tag: Vec::new(),
                    extension: Vec::new(),
                    source: None,
                    security: Vec::new(),
                    profile: Vec::new(),
                }),
                language: None,
            }, Resource {
                id: None,
                implicit_rules: Vec::new(),
                meta: Some(Meta {
                    id: None,
                    tag: Vec::new(),
                    extension: Vec::new(),
                    source: None,
                    security: Vec::new(),
                    profile: Vec::new(),
                }),
                language: None,
            }];

            patient.extension = vec![Extension {
                id: None,
                url: "some url".to_string(),
                value_integer: None,
                extension: Vec::new(),
                value_string: None,
                value_base_64_binary: None,
                value_boolean: None,
            }];

            patient.modifier_extension = vec![Extension {
                id: None,
                url: "some url".to_string(),
                value_integer: None,
                extension: Vec::new(),
                value_string: None,
                value_base_64_binary: None,
                value_boolean: None,
            }];

            patient.identifier = vec![Identifier {
                id: None,
                system: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                period: None,
                identifier_type: Some(CodeableConcept {
                    id: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    text: None,
                    coding: vec![Coding {
                        id: None,
                        user_selected: None,
                        display: None,
                        code: None,
                        version: None,
                        extension: vec![Extension {
                            id: None,
                            url: "some url".to_string(),
                            value_integer: None,
                            extension: Vec::new(),
                            value_string: None,
                            value_base_64_binary: None,
                            value_boolean: None,
                        }],
                        system: None,
                    }]
                }),
                value: None,
                assigner: Some(Box::new(Reference {
                    id: None,
                    identifier: Some(Identifier {
                        id: None,
                        assigner: None,
                        value: None,
                        extension: Vec::new(),
                        identifier_type: None,
                        period: None,
                        system: None,
                        identifier_use: None
                    }),
                    display: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    ref_type: None,
                    reference: None,
                })),
                identifier_use: None,
            }, Identifier {
                id: None,
                system: None,
                extension: Vec::new(),
                period: None,
                identifier_type: None,
                value: None,
                assigner: None,
                identifier_use: None,
            }];

            patient.name = vec![HumanName {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                period: None,
                text: None,
                given: Vec::new(),
                human_name_use: None,
                family: None,
                suffix: Vec::new(),
                prefix: Vec::new(),
            }, HumanName {
                id: None,
                extension: Vec::new(),
                period: None,
                text: None,
                given: Vec::new(),
                human_name_use: None,
                family: None,
                suffix: Vec::new(),
                prefix: Vec::new(),
            }];

            patient.telecom = vec![ContactPoint {
                id: None,
                period: None,
                system: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }, Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                value: None,
                contact_point_use: None,
                rank: None,
            }, ContactPoint {
                id: None,
                period: None,
                system: None,
                extension: Vec::new(),
                value: None,
                contact_point_use: None,
                rank: None,
            }];

            patient.address = Some(Address {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }, Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                period: None,
                text: None,
                country: None,
                postal_code: None,
                district: None,
                address_type: None,
                address_use: None,
                city: None,
                line: Vec::new(),
                state: None,
            });

            patient.marital_status = Some(CodeableConcept {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                text: None,
                coding: vec![Coding {
                    id: None,
                    user_selected: None,
                    display: None,
                    code: None,
                    version: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    system: None,
                }, Coding {
                    id: None,
                    user_selected: None,
                    display: None,
                    code: None,
                    version: None,
                    extension: vec![Extension {
                        id: None,
                        url: "some url".to_string(),
                        value_integer: None,
                        extension: Vec::new(),
                        value_string: None,
                        value_base_64_binary: None,
                        value_boolean: None,
                    }],
                    system: None,
                }],
            });

            patient.photo = vec![Attachment {
                id: None,
                language: None,
                url: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }, Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                creation: None,
                content_type: None,
                data: None,
                hash: None,
                size: None,
                title: None,
            }, Attachment {
                id: None,
                language: None,
                url: None,
                extension: Vec::new(),
                creation: None,
                content_type: None,
                data: None,
                hash: None,
                size: None,
                title: None,
            }];

            patient.contact = vec![Contact {
                id: None,
                extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }, Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                modifier_extension: vec![Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }, Extension {
                    id: None,
                    url: "some url".to_string(),
                    value_integer: None,
                    extension: Vec::new(),
                    value_string: None,
                    value_base_64_binary: None,
                    value_boolean: None,
                }],
                period: None,
                address: None,
                telecom: vec![ContactPoint {
                    id: None,
                    period: None,
                    system: None,
                    extension: Vec::new(),
                    value: None,
                    contact_point_use: None,
                    rank: None,
                }, ContactPoint {
                    id: None,
                    period: None,
                    system: None,
                    extension: Vec::new(),
                    value: None,
                    contact_point_use: None,
                    rank: None,
                }],
                name: vec![HumanName {
                    id: None,
                    extension: Vec::new(),
                    period: None,
                    text: None,
                    given: Vec::new(),
                    human_name_use: None,
                    family: None,
                    suffix: Vec::new(),
                    prefix: Vec::new(),
                }, HumanName {
                    id: None,
                    extension: Vec::new(),
                    period: None,
                    text: None,
                    given: Vec::new(),
                    human_name_use: None,
                    family: None,
                    suffix: Vec::new(),
                    prefix: Vec::new(),
                }],
                gender: None,
                organization: Some(Reference {
                    id: None,
                    identifier: None,
                    display: None,
                    extension: Vec::new(),
                    ref_type: None,
                    reference: None,
                }),
                relationship: vec![CodeableConcept {
                    id: None,
                    extension: Vec::new(),
                    text: None,
                    coding: Vec::new(),
                }, CodeableConcept {
                    id: None,
                    extension: Vec::new(),
                    text: None,
                    coding: Vec::new(),
                }]
            }];

            patient.communication = vec![Communication {
                id: None,
                language: "de-DE".to_string(),
                modifier_extension: Vec::new(),
                extension: Vec::new(),
                preferred: None,
            }, Communication {
                id: None,
                language: "de-DE".to_string(),
                modifier_extension: Vec::new(),
                extension: Vec::new(),
                preferred: None,
            }];

            patient.general_practitioner = vec![Reference {
                id: None,
                identifier: None,
                display: None,
                extension: Vec::new(),
                ref_type: None,
                reference: None,
            }, Reference {
                id: None,
                identifier: None,
                display: None,
                extension: Vec::new(),
                ref_type: None,
                reference: None,
            }];

            patient.managing_organization = Some(Reference {
                id: None,
                identifier: None,
                display: None,
                extension: Vec::new(),
                ref_type: None,
                reference: None,
            });

            patient.set_id(&db).await;

            let new_count = client.query_one("SELECT COUNT(1) FROM fhir.id_list;", &[]).await.unwrap().get::<usize, i64>(0);

            assert_that(&new_count).is_equal_to(id_count + 63);
        }

        /// Returns a patient with no fields set.
        fn get_empty_patient() -> Patient {
            return Patient {
                id: None,
                meta: None,
                implicit_rules: Vec::new(),
                language: None,
                text: None,
                contained: Vec::new(),
                extension: Vec::new(),
                modifier_extension: Vec::new(),
                identifier: Vec::new(),
                active: None,
                name: Vec::new(),
                telecom: Vec::new(),
                gender: None,
                birth_date: None,
                deceased: None,
                address: None,
                marital_status: None,
                multiple_birth: None,
                photo: Vec::new(),
                contact: Vec::new(),
                communication: Vec::new(),
                general_practitioner: Vec::new(),
                managing_organization: None,
                link: Vec::new(),
            };
        }

        /// Returns a patient with most fields set.
        async fn get_full_patient(db: &Db) -> Patient {
            return Patient {
                id: None,
                meta: Some(Meta {
                    id: Some(db.get_id().await),
                    extension: Vec::from([Extension {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        url: String::from("http://example.com/meta/extension/1"),
                        value_base_64_binary: None,
                        value_boolean: Some(true),
                        value_string: None,
                        value_integer: None,
                    }, Extension {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        url: String::from("http://example.com/meta/extension/2"),
                        value_base_64_binary: None,
                        value_boolean: None,
                        value_string: None,
                        value_integer: Some(42),
                    }]),
                    source: Some("http://example.com/meta/source".to_string()),
                    profile: Vec::from(["http://example.com/meta/profile/1".to_string(),
                        "http://example.com/meta/profile/2".to_string()]),
                    security: Vec::from([Coding {
                        id: Some(db.get_id().await),
                        extension: Vec::from([Extension {
                            id: Some(db.get_id().await),
                            extension: Vec::new(),
                            url: String::from("http://example.com/meta/security/1/extension/1"),
                            value_base_64_binary: None,
                            value_boolean: None,
                            value_string: Some("Some value".to_string()),
                            value_integer: None,
                        }]),
                        system: Some("http://example.com/meta/security/1/system".to_string()),
                        version: Some("1.0.0".to_string()),
                        code: Some("some code".to_string()),
                        display: Some("some display".to_string()),
                        user_selected: Some(false),
                    }]),
                    tag: Vec::from([Coding {
                        id: Some(db.get_id().await),
                        extension: Vec::from([Extension {
                            id: Some(db.get_id().await),
                            extension: Vec::new(),
                            url: String::from("http://example.com/meta/security/2/extension/1"),
                            value_base_64_binary: Some("abc".to_string()),
                            value_boolean: None,
                            value_string: None,
                            value_integer: None,
                        }]),
                        system: Some("http://example.com/meta/security/2/system".to_string()),
                        version: Some("1.0.1".to_string()),
                        code: Some("some code2".to_string()),
                        display: Some("some display2".to_string()),
                        user_selected: Some(true),
                    }]),
                }),
                implicit_rules: Vec::from(["some implicit rule".to_string()]),
                language: Some("en_US".to_string()),
                text: Some(Narrative {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    status: NarrativeStatus::Generated,
                    div: "<p>Some div</p>".to_string(),
                }),
                contained: Vec::from([Resource {
                    id: Some(db.get_id().await),
                    meta: Some(Meta {
                        id: Some(db.get_id().await),
                        extension: Vec::from([Extension {
                            id: Some(db.get_id().await),
                            extension: Vec::new(),
                            url: String::from("http://example.com/meta/extension/1"),
                            value_base_64_binary: None,
                            value_boolean: Some(true),
                            value_string: None,
                            value_integer: None,
                        }, Extension {
                            id: Some(db.get_id().await),
                            extension: Vec::new(),
                            url: String::from("http://example.com/meta/extension/2"),
                            value_base_64_binary: None,
                            value_boolean: None,
                            value_string: None,
                            value_integer: Some(42),
                        }]),
                        source: Some("http://example.com/meta/source".to_string()),
                        profile: Vec::from(["http://example.com/contained/1/meta/profile/1".to_string(),
                            "http://example.com/contained/1/meta/profile/2".to_string()]),
                        security: Vec::from([Coding {
                            id: Some(db.get_id().await),
                            extension: Vec::from([Extension {
                                id: Some(db.get_id().await),
                                extension: Vec::new(),
                                url: String::from("http://example.com/contained/1/meta/security/1/extension/1"),
                                value_base_64_binary: None,
                                value_boolean: None,
                                value_string: Some("Some value".to_string()),
                                value_integer: None,
                            }]),
                            system: Some("http://example.com/contained/1/meta/security/1/system".to_string()),
                            version: Some("1.0.0".to_string()),
                            code: Some("some code".to_string()),
                            display: Some("some display".to_string()),
                            user_selected: Some(false),
                        }]),
                        tag: Vec::from([Coding {
                            id: Some(db.get_id().await),
                            extension: Vec::from([Extension {
                                id: Some(db.get_id().await),
                                extension: Vec::new(),
                                url: String::from("http://example.com/contained/1/meta/security/2/extension/1"),
                                value_base_64_binary: Some("abc".to_string()),
                                value_boolean: None,
                                value_string: None,
                                value_integer: None,
                            }]),
                            system: Some("http://example.com/meta/security/2/system".to_string()),
                            version: Some("1.0.1".to_string()),
                            code: Some("some code2".to_string()),
                            display: Some("some display2".to_string()),
                            user_selected: Some(true),
                        }]),
                    }),
                    implicit_rules: Vec::from(["contained implicit rule".to_string()]),
                    language: Some("de_DE".to_string()),
                }]),
                extension: Vec::from([Extension {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    url: String::from("http://example.com/patient/extension/1"),
                    value_base_64_binary: Some("abcd".to_string()),
                    value_boolean: None,
                    value_string: None,
                    value_integer: None,
                }]),
                modifier_extension: Vec::from([Extension {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    url: String::from("http://example.com/patient/modifier_extension/1"),
                    value_base_64_binary: Some("abcde".to_string()),
                    value_boolean: None,
                    value_string: None,
                    value_integer: None,
                }]),
                identifier: Vec::from([Identifier {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    identifier_use: Some(IdentifierUse::Official),
                    identifier_type: Some(CodeableConcept {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        text: Some("Some text for identifier".to_string()),
                        coding: Vec::from([Coding {
                            id: Some(db.get_id().await),
                            extension: Vec::from([Extension {
                                id: Some(db.get_id().await),
                                extension: Vec::new(),
                                url: String::from("http://example.com/identifier/1/type"),
                                value_base_64_binary: Some("zabc".to_string()),
                                value_boolean: None,
                                value_string: None,
                                value_integer: None,
                            }]),
                            system: Some("http://example.com/identifier/1/system".to_string()),
                            version: Some("1.0.1".to_string()),
                            code: Some("some code3".to_string()),
                            display: Some("some display3".to_string()),
                            user_selected: Some(true),
                        }]),
                    }),
                    assigner: Some(Box::new(Reference {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        reference: Some("some reference".to_string()),
                        ref_type: Some("organization".to_string()),
                        identifier: None,
                        display: Some("some assigner display".to_string()),
                    })),
                    system: Some("identifier system".to_string()),
                    value: Some("identifier value".to_string()),
                    period: Some(Period {
                        start: Some("2024-11-17T13:00:00+09:00".to_string()),
                        end: Some("2025-11-17T13:00:00+09:00".to_string()),
                    }),
                }]),
                active: Some(true),
                name: Vec::from([HumanName {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    human_name_use: Some(HumanNameUse::Official),
                    text: Some("Sir Hand Willi Peterson der Weltenbummler".to_string()),
                    family: Some("Peterson".to_string()),
                    given: Vec::from(["Hans".to_string(), "Willi".to_string()]),
                    prefix: Vec::from(["Sir".to_string()]),
                    suffix: Vec::from(["der Weltenbummler".to_string()]),
                    period: Some(Period {
                        start: Some("2011-07-08T00:00:00+02:00".to_string()),
                        end: Some("2015-07-08T00:00:00+02:00".to_string()),
                    }),
                }, HumanName {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    human_name_use: Some(HumanNameUse::Official),
                    text: Some("Sir Hand Willi Peterson".to_string()),
                    family: Some("Peterson".to_string()),
                    given: Vec::from(["Hans".to_string(), "Willi".to_string()]),
                    prefix: Vec::from(["Sir".to_string()]),
                    suffix: Vec::new(),
                    period: Some(Period {
                        start: Some("2015-07-08T00:00:00+02:00".to_string()),
                        end: None,
                    }),
                }]),
                telecom: Vec::from([ContactPoint {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    system: Some(ContactPointSystem::Email),
                    value: Some("my@email.com".to_string()),
                    contact_point_use: Some(ContactPointUse::Home),
                    rank: Some(1),
                    period: None,
                }]),
                gender: Some(Unknown),
                birth_date: Some("1993-09-02".to_string()),
                deceased: Some(Deceased {
                    deceased: Some(false),
                    date_time: None,
                }),
                address: Some(Address {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    address_use: Some(AddressUse::Home),
                    address_type: Some(AddressType::Both),
                    text: Some("Musterstr. 1\n12345 Musterstadt\nGERMANY".to_string()),
                    line: Vec::from(["Musterstr. 1".to_string(), "12345 Musterstadt".to_string(), "GERMANY".to_string()]),
                    city: Some("Musterstadt".to_string()),
                    district: None,
                    state: None,
                    postal_code: Some("12345".to_string()),
                    country: Some("DE".to_string()),
                    period: None,
                }),
                marital_status: Some(CodeableConcept {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    coding: Vec::from([Coding {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        system: Some("coding system".to_string()),
                        version: Some("1.1.0".to_string()),
                        code: Some("some code".to_string()),
                        display: Some("marital status code".to_string()),
                        user_selected: Some(true),
                    }]),
                    text: Some("some marital status".to_string()),
                }),
                multiple_birth: Some(MultipleBirth {
                    multiple_birth: Some(true),
                    count: Some(3),
                }),
                photo: Vec::from([Attachment {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    content_type: Some("image/jpeg".to_string()),
                    language: Some("de-DE".to_string()),
                    data: Some("data in base64".to_string()),
                    url: None,
                    size: Some(128 * 1024),
                    hash: Some("hash in base 64".to_string()),
                    title: Some("My Picture.jpg".to_string()),
                    creation: DateTime::from_timestamp(1000, 0).map(|x| x.fixed_offset()),
                }]),
                contact: Vec::from([Contact {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    modifier_extension: Vec::new(),
                    relationship: Vec::new(),
                    name: Vec::from([HumanName {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        human_name_use: Some(Official),
                        text: Some("Hans Meier".to_string()),
                        given: Vec::from(["Hans".to_string()]),
                        family: Some("Meier".to_string()),
                        suffix: Vec::new(),
                        prefix: Vec::new(),
                        period: None,
                    }]),
                    telecom: Vec::new(),
                    address: None,
                    gender: Some(Male),
                    organization: None,
                    period: None,
                }]),
                communication: Vec::from([Communication {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    modifier_extension: Vec::new(),
                    language: "de-DE".to_string(),
                    preferred: Some(true),
                }]),
                general_practitioner: Vec::from([Reference {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    reference: Some("gp".to_string()),
                    ref_type: Some("gp ref type".to_string()),
                    identifier: None,
                    display: Some("Their GP".to_string()),
                }]),
                managing_organization: Some(Reference {
                    id: Some(db.get_id().await),
                    extension: Vec::new(),
                    reference: Some("managing_organization".to_string()),
                    ref_type: Some("managing_organization ref type".to_string()),
                    identifier: None,
                    display: Some("Their managing_organization".to_string()),
                }),
                link: Vec::from([Link {
                    other: Reference {
                        id: Some(db.get_id().await),
                        extension: Vec::new(),
                        reference: Some("link".to_string()),
                        ref_type: Some("link ref type".to_string()),
                        identifier: None,
                        display: Some("Their link".to_string()),
                    },
                    link_type: LinkType::Seealso,
                }]),
            };
        }
    }
}
