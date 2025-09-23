pub mod model {
    use crate::model::model::SearchOperator::And;
    use chrono::{DateTime, FixedOffset};
    use serde::{Deserialize, Serialize};
    use std::error::Error;
    use std::fmt::Debug;
    use tokio_postgres::types::{FromSql, Type};

    fn default_count() -> u32 { 30 }
    fn default_vec<T>() -> Vec<T> { Vec::new() }
    fn deserialize_vec<'de, D, T>(deserializer: D) -> Result<Vec<T>, D::Error>
    where
        D: serde::Deserializer<'de>,
        T: Deserialize<'de>,
    {
        let raw: Vec<Option<T>> = Vec::deserialize(deserializer)?;
        Ok(raw.into_iter().flatten().collect())
    }
    fn default_operator() -> SearchOperator { And }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct PatientStub {
        pub id: String,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub name: Vec<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub birthdate: Option<String>,
        pub iteration_key: String,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    #[postgres(name = "patient")]
    pub struct Patient {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub meta: Option<Meta>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub implicit_rules: Vec<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub language: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub text: Option<Narrative>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub contained: Vec<Resource>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub modifier_extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub identifier: Vec<Identifier>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub active: Option<bool>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub name: Vec<HumanName>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub telecom: Vec<ContactPoint>,
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
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub photo: Vec<Attachment>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub contact: Vec<Contact>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub communication: Vec<Communication>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub general_practitioner: Vec<Reference>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub managing_organization: Option<Reference>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub link: Vec<Link>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Meta {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub source: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub profile: Vec<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub security: Vec<Coding>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub tag: Vec<Coding>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Narrative {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        pub status: NarrativeStatus,
        pub div: String,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Resource {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub meta: Option<Meta>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub implicit_rules: Vec<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub language: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct HumanName {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "use")]
        pub human_name_use: Option<HumanNameUse>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub text: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub family: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub given: Vec<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub prefix: Vec<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub suffix: Vec<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub period: Option<Period>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct ContactPoint {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub system: Option<ContactPointSystem>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub value: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "use")]
        pub contact_point_use: Option<ContactPointUse>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub rank: Option<u32>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub period: Option<Period>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct Deceased {
        #[serde(rename = "deceasedBoolean")]
        pub deceased: Option<bool>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "deceasedDateTime")]
        pub date_time: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Address {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "use")]
        pub address_use: Option<AddressUse>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "type")]
        pub address_type: Option<AddressType>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub text: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub line: Vec<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub city: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub district: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub state: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub postal_code: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub country: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub period: Option<Period>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct MultipleBirth {
        #[serde(rename = "multipleBirthBoolean")]
        pub multiple_birth: Option<bool>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "multipleBirthInteger")]
        pub count: Option<u32>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Attachment {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub content_type: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub language: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub data: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub url: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub size: Option<u32>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub hash: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub title: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub creation: Option<DateTime<FixedOffset>>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Contact {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub modifier_extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub relationship: Vec<CodeableConcept>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub name: Vec<HumanName>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub telecom: Vec<ContactPoint>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub address: Option<Address>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub gender: Option<Gender>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub organization: Option<Reference>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub period: Option<Period>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Communication {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub modifier_extension: Vec<Extension>,
        pub language: String,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub preferred: Option<bool>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Extension {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
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

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    #[serde(rename_all = "camelCase")]
    pub struct Coding {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
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

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct CodeableConcept {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub coding: Vec<Coding>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub text: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct Identifier {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
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

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct Period {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub start: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub end: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct Reference {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub id: Option<String>,
        #[serde(default = "default_vec", deserialize_with = "deserialize_vec")]
        pub extension: Vec<Extension>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub reference: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none", rename = "type")]
        pub ref_type: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub identifier: Option<Identifier>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub display: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub struct Link {
        pub other: Reference,
        #[serde(rename = "type")]
        pub link_type: LinkType,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum IdentifierUse {
        #[serde(rename = "USUAL")]
        Usual,
        #[serde(rename = "OFFICIAL")]
        Official,
        #[serde(rename = "TEMP")]
        Temp,
        #[serde(rename = "SECONDARY")]
        Secondary,
        #[serde(rename = "OLD")]
        Old,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum LinkType {
        #[serde(rename = "REPLACED-BY")]
        ReplacedBy,
        #[serde(rename = "REPLACES")]
        Replaces,
        #[serde(rename = "REFER")]
        Refer,
        #[serde(rename = "SEEALSO")]
        Seealso,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum NarrativeStatus {
        #[serde(rename = "GENERATED")]
        Generated,
        #[serde(rename = "EXTENSIONS")]
        Extensions,
        #[serde(rename = "ADDITIONAL")]
        Additional,
        #[serde(rename = "EMPTY")]
        Empty,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum HumanNameUse {
        #[serde(rename = "USUAL")]
        Usual,
        #[serde(rename = "OFFICIAL")]
        Official,
        #[serde(rename = "TEMP")]
        Temp,
        #[serde(rename = "NICKCNAME")]
        Nickname,
        #[serde(rename = "ANONYMOUS")]
        Anonymous,
        #[serde(rename = "OLD")]
        Old,
        #[serde(rename = "MAIDEN")]
        Maiden,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum ContactPointUse {
        #[serde(rename = "HOME")]
        Home,
        #[serde(rename = "WORK")]
        Work,
        #[serde(rename = "TEMP")]
        Temp,
        #[serde(rename = "OLD")]
        Old,
        #[serde(rename = "MOBILE")]
        Mobile,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum ContactPointSystem {
        #[serde(rename = "PHONE")]
        Phone,
        #[serde(rename = "FAX")]
        Fax,
        #[serde(rename = "EMAIL")]
        Email,
        #[serde(rename = "PAGER")]
        Pager,
        #[serde(rename = "URL")]
        Url,
        #[serde(rename = "SMS")]
        Sms,
        #[serde(rename = "OTHER")]
        Other,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum Gender {
        #[serde(rename = "MALE")]
        #[postgres(name = "MALE")]
        Male,
        #[serde(rename = "FEMALE")]
        #[postgres(name = "FEMALE")]
        Female,
        #[serde(rename = "OTHER")]
        #[postgres(name = "OTHER")]
        Other,
        #[serde(rename = "UNKNOWN")]
        #[postgres(name = "UNKNOWN")]
        Unknown,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum AddressUse {
        #[serde(rename = "HOME")]
        Home,
        #[serde(rename = "WORK")]
        Work,
        #[serde(rename = "TEMP")]
        Temp,
        #[serde(rename = "OLD")]
        Old,
        #[serde(rename = "BILLING")]
        Billing,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug, PartialEq, Eq, Clone)]
    pub enum AddressType {
        #[serde(rename = "POSTAL")]
        Postal,
        #[serde(rename = "PHYSICAL")]
        Physical,
        #[serde(rename = "BOTH")]
        Both,
    }

    #[derive(Serialize, Deserialize, Debug)]
    #[serde(rename_all = "camelCase")]
    pub struct PatientSearch {
        #[serde(skip_serializing_if = "Option::is_none")]
        pub name: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub birthdate_from: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub birthdate_until: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub gender: Option<Gender>,
        #[serde(default = "default_operator")]
        pub operator: SearchOperator,
        #[serde(default = "default_count")]
        pub count: u32,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub iteration_key: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        pub last_id: Option<String>,
    }

    #[derive(Serialize, Deserialize, FromSql, Debug)]
    pub enum SearchOperator {
        #[serde(rename = "AND")]
        #[postgres(name = "AND")]
        And,
        #[serde(rename = "OR")]
        #[postgres(name = "OR")]
        Or,
    }

    /// FromSql is not implemented for Box types, so we need to do it manually.
    /// All this one does is wrap the derived implementation of [Reference] into a Box.
    impl<'a> FromSql<'a> for Box<Reference> {
        fn from_sql(ty: &Type, raw: &'a [u8]) -> Result<Self, Box<dyn Error + Sync + Send>> {
            return Ok(Box::new(Reference::from_sql(ty, raw)?));
        }

        fn accepts(ty: &Type) -> bool {
            return <Reference as FromSql>::accepts(ty);
        }
    }
}
