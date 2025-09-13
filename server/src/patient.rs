use serde::Deserialize;

fn default_count() -> u32 { 30 }
fn default_offset() -> u32 { 0 }

#[derive(Deserialize)]
pub struct Patient {
    pub id: Option<String>,
}

#[derive(Deserialize)]
pub struct PatientUpdate {}

#[derive(Deserialize)]
pub struct PatientSearch {
    name: Option<String>,
    birthdate: Option<String>,
    gender: Option<String>,
    #[serde(default = "default_count")]
    count: u32,
    #[serde(default = "default_offset")]
    offset: u32,
}
