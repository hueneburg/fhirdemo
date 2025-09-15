use serde::{Deserialize, Serialize};

fn default_count() -> u32 { 30 }
fn default_offset() -> u32 { 0 }

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Patient {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meta: Option<Meta>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub implicit_rules: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub language: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text: Option<Narrative>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub contained: Option<Vec<Resource>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub modifier_extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub identifier: Option<Vec<Identifier>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub active: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<Vec<HumanName>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub telecom: Option<Vec<ContactPoint>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gender: Option<Gender>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub birth_date: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deceased: Option<Deceased>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub address: Option<Address>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub marital_status: Option<CodeableConcept>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub multiple_birth: Option<MultipleBirth>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub photo: Option<Vec<Attachment>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub contact: Option<Vec<Contact>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub communication: Option<Vec<Communication>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub general_practitioner: Option<Vec<Reference>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub managing_organization: Option<Reference>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub link: Option<Vec<Link>>,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Extension {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value_base_64_binary: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value_boolean: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value_string: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value_integer: Option<i32>,
    // Skipping the rest, many are not implemented in the DB, and the pattern
    // would continue like this.
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Coding {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub version: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user_selected: Option<bool>,
}

#[derive(Serialize, Deserialize)]
pub struct CodeableConcept {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub coding: Option<Vec<Coding>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Identifier {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none", rename = "use")]
    pub identifier_use: Option<IdentifierUse>,
    #[serde(skip_serializing_if = "Option::is_none", rename = "type")]
    pub identifier_type: Option<CodeableConcept>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub period: Option<Period>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub assigner: Option<Box<Reference>>,
}

#[derive(Serialize, Deserialize)]
pub struct Period {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub start: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub end: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Reference {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub extension: Option<Vec<Extension>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reference: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none", rename = "type")]
    pub ref_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub identifier: Option<Identifier>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct Link {
    pub other: Reference,
    #[serde(rename = "type")]
    pub link_type: LinkType,
}

#[derive(Serialize, Deserialize)]
enum IdentifierUse {

}

#[derive(Serialize, Deserialize)]
enum LinkType {
    #[serde(rename = "REPLACED-BY")]
    ReplacedBy,
    #[serde(rename = "REPLACES")]
    Replaces,
    #[serde(rename = "REFER")]
    Refer,
    #[serde(rename = "SEEALSO")]
    Seealso,
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
