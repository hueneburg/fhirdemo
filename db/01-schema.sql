CREATE TYPE gender AS ENUM ('FEMALE', 'MALE', 'OTHER', 'UNKNOWN');
CREATE TYPE link_type AS ENUM ('REPLACED-BY', 'REPLACES', 'REFER', 'SEEALSO');
CREATE TYPE narrative_status AS ENUM ('GENERATED', 'EXTENSIONS', 'ADDITIONAL', 'EMPTY');
CREATE TYPE identifier_use AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'OLD');
CREATE TYPE human_name_use AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'NICKNAME', 'ANONYMOUS', 'OLD', 'MAIDEN');
CREATE TYPE address_use AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'BILLING');
CREATE TYPE address_type AS ENUM ('POSTAL', 'PHYSICAL', 'BOTH');
CREATE TYPE contact_point_system AS ENUM ('PHONE', 'FAX', 'EMAIL', 'PAGER', 'URL', 'SMS', 'OTHER');
CREATE TYPE contact_point_use AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'MOBILE');

CREATE DOMAIN unsigned_integer AS INTEGER CHECK (value >= 0);
CREATE DOMAIN positive_integer AS INTEGER CHECK (value > 0);
CREATE DOMAIN fhir_date AS TEXT CHECK (value ~*
                                       '^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?$');
CREATE DOMAIN fhir_time AS TEXT CHECK (value ~* '^([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?$');

CREATE TABLE IF NOT EXISTS element (
    id uuid PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS coding (
    id            uuid PRIMARY KEY REFERENCES element (id),
    system        TEXT,
    uri           TEXT,
    code          TEXT,
    display       TEXT,
    user_selected BOOLEAN
);

CREATE TABLE IF NOT EXISTS meta (
    id           uuid PRIMARY KEY NOT NULL,
    version      TEXT,
    last_updated TIMESTAMP,
    source       TEXT,
    profile      TEXT[]           NOT NULL
);

CREATE TABLE IF NOT EXISTS meta_security (
    meta     uuid NOT NULL REFERENCES meta (id),
    security uuid NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS meta_tag (
    meta uuid NOT NULL REFERENCES meta (id),
    tag  uuid NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS resource (
    id             uuid PRIMARY KEY,
    meta           uuid REFERENCES meta (id),
    implicit_rules TEXT,
    language       TEXT
);

CREATE TABLE IF NOT EXISTS extension (
    id    uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    uri   TEXT             NOT NULL,
    value jsonb
);

CREATE TABLE IF NOT EXISTS narrative (
    id     uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    status narrative_status NOT NULL,
    div    TEXT             NOT NULL
);

CREATE TABLE IF NOT EXISTS domain_resource (
    id   uuid PRIMARY KEY NOT NULL REFERENCES resource (id),
    text uuid REFERENCES narrative (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_contained (
    domain_resource uuid NOT NULL REFERENCES domain_resource (id),
    contained       uuid NOT NULL REFERENCES resource (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_extension (
    domain_resource uuid NOT NULL REFERENCES domain_resource (id),
    extension       uuid NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_modifier_extension (
    domain_resource    uuid NOT NULL REFERENCES domain_resource (id),
    modifier_extension uuid NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS codeable_concept (
    id   uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    text TEXT
);

CREATE TABLE IF NOT EXISTS codeable_concept_coding (
    codeable_concept uuid NOT NULL REFERENCES codeable_concept (id),
    coding           uuid NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS patient (
    id                     uuid PRIMARY KEY NOT NULL REFERENCES domain_resource (id),
    active                 bool,
    gender                 gender,
    birthdate              fhir_date,
    deceased               bool,
    deceased_date_time     TIMESTAMP,
    marital_status         uuid REFERENCES codeable_concept (id),
    multiple_birth         bool,
    multiple_birth_integer INTEGER,
    managing_organization  uuid -- would reference organization but left out for this demo
);

CREATE TABLE IF NOT EXISTS identifier (
    id           uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    use          identifier_use,
    type         uuid REFERENCES codeable_concept (id),
    system       text,
    value        text,
    period_start TIMESTAMP,
    period_end   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reference (
    id         uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    reference  TEXT,
    type       TEXT,
    identifier uuid REFERENCES identifier (id),
    display    TEXT
);

CREATE TABLE IF NOT EXISTS backbone_element (
    id uuid PRIMARY KEY NOT NULL REFERENCES element (id)
);

CREATE TABLE IF NOT EXISTS element_extension (
    element   uuid NOT NULL REFERENCES element (id),
    extension uuid NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS backbone_element_modifier_extension (
    backbone_element   uuid NOT NULL REFERENCES backbone_element (id),
    modifier_extension uuid NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS patient_link (
    id      uuid PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    patient uuid             NOT NULL REFERENCES patient (id),
    other   uuid REFERENCES reference (id),
    type    link_type        NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_general_practitioner (
    patient              uuid NOT NULL REFERENCES patient (id),
    general_practitioner uuid NOT NULL REFERENCES reference (id)
);

CREATE TABLE IF NOT EXISTS communication (
    id        uuid PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    language  uuid             NOT NULL REFERENCES codeable_concept (id),
    preferred boolean
);

CREATE TABLE IF NOT EXISTS patient_communication (
    patient       uuid NOT NULL REFERENCES patient (id),
    communication uuid NOT NULL REFERENCES communication (id)
);

CREATE TABLE IF NOT EXISTS human_name (
    id           uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    use          human_name_use,
    text         text,
    family       text,
    given        TEXT[]           NOT NULL,
    prefix       text[]           NOT NULL,
    suffix       text[]           NOT NULL,
    period_start TIMESTAMP,
    period_end   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS address (
    id           uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    use          address_use,
    type         address_type,
    text         text,
    line         text[]           NOT NULL,
    city         text,
    district     text,
    state        text,
    postal_code  text,
    country      text,
    period_start TIMESTAMP,
    period_end   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact (
    id           uuid PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    name         uuid REFERENCES human_name (id),
    address      uuid REFERENCES address (id),
    gender       gender,
    organization uuid REFERENCES reference (id),
    period_start TIMESTAMP,
    period_end   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact_relationship (
    contact      uuid NOT NULL REFERENCES contact (id),
    relationship uuid NOT NULL REFERENCES codeable_concept (id)
);

CREATE TABLE IF NOT EXISTS patient_contact (
    patient uuid NOT NULL REFERENCES patient (id),
    contact uuid NOT NULL REFERENCES contact (id)
);

CREATE TABLE IF NOT EXISTS patient_address (
    patient uuid NOT NULL REFERENCES patient (id),
    address uuid NOT NULL REFERENCES address (id)
);

CREATE TABLE IF NOT EXISTS patient_name (
    patient uuid NOT NULL REFERENCES patient (id),
    name    uuid NOT NULL REFERENCES human_name (id)
);

CREATE TABLE IF NOT EXISTS contact_point (
    id           uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    system       contact_point_system,
    value        text,
    use          contact_point_use,
    rank         positive_integer,
    period_start TIMESTAMP,
    period_end   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact_contact_point (
    contact       uuid NOT NULL REFERENCES contact (id),
    contact_point uuid NOT NULL REFERENCES contact_point (id)
);

CREATE TABLE IF NOT EXISTS patient_telecom (
    patient uuid NOT NULL REFERENCES patient (id),
    telecom uuid NOT NULL REFERENCES contact_point (id)
);

CREATE TABLE IF NOT EXISTS patient_identifier (
    patient    uuid NOT NULL REFERENCES patient (id),
    identifier uuid NOT NULL REFERENCES identifier (id)
);

CREATE TABLE IF NOT EXISTS attachment (
    id           uuid PRIMARY KEY NOT NULL REFERENCES element (id),
    content_type text,
    language     text,
    data         bytea,
    url          text,
    size         unsigned_integer,
    hash         bytea,
    title        text,
    creation     TIMESTAMP
);

CREATE TABLE IF NOT EXISTS patient_photo (
    patient uuid NOT NULL REFERENCES patient (id),
    photo   uuid NOT NULL REFERENCES attachment (id)
);

CREATE INDEX idx_patient_photo_patient ON patient_photo (patient);
CREATE INDEX idx_patient_photo_photo ON patient_photo (photo);
CREATE INDEX idx_patient_identifier_patient ON patient_identifier (patient);
CREATE INDEX idx_patient_identifier_identifier ON patient_identifier (identifier);
CREATE INDEX idx_patient_telecom_patient ON patient_telecom (patient);
CREATE INDEX idx_patient_telecom_telecom ON patient_telecom (telecom);
CREATE INDEX idx_contact_contact_point_contact ON contact_contact_point (contact);
CREATE INDEX idx_contact_contact_point_contact_point ON contact_contact_point (contact_point);
CREATE INDEX idx_patient_name_patient ON patient_name (patient);
CREATE INDEX idx_patient_name_name ON patient_name (name);
CREATE INDEX idx_patient_address_patient ON patient_address (patient);
CREATE INDEX idx_patient_address_address ON patient_address (address);
CREATE INDEX idx_patient_contact_patient ON patient_contact (patient);
CREATE INDEX idx_patient_contact_contact ON patient_contact (contact);
CREATE INDEX idx_contact_relationship_contact ON contact_relationship (contact);
CREATE INDEX idx_contact_relationship_relationship ON contact_relationship (relationship);
CREATE INDEX idx_patient_communication_patient ON patient_communication (patient);
CREATE INDEX idx_patient_communication_communication ON patient_communication (communication);
CREATE INDEX idx_patient_general_practitioner_patient ON patient_general_practitioner (patient);
CREATE INDEX idx_patient_general_practitioner_general_practitioner ON patient_general_practitioner (general_practitioner);
CREATE INDEX idx_element_extension_backbone_element ON element_extension (element);
CREATE INDEX idx_extension_extension ON element_extension (extension);
CREATE INDEX idx_backbone_element_extension_backbone_element ON backbone_element_modifier_extension (backbone_element);
CREATE INDEX idx_backbone_extension_extension ON backbone_element_modifier_extension (modifier_extension);
CREATE INDEX idx_meta_security_meta ON meta_security (meta);
CREATE INDEX idx_meta_security_security ON meta_security (security);
CREATE INDEX idx_meta_tag_meta ON meta_tag (meta);
CREATE INDEX idx_meta_tag_tag ON meta_tag (tag);
CREATE INDEX idx_domain_resource_contained_domain_resource ON domain_resource_contained (domain_resource);
CREATE INDEX idx_domain_resource_contained_contained ON domain_resource_contained (contained);
CREATE INDEX idx_domain_resource_extension_domain_resource ON domain_resource_extension (domain_resource);
CREATE INDEX idx_domain_resource_extension_extension ON domain_resource_extension (extension);
CREATE INDEX idx_domain_resource_modifier_extension_domain_resource ON domain_resource_modifier_extension (domain_resource);
CREATE INDEX idx_domain_resource_modifier_extension_modifier_extension ON domain_resource_modifier_extension (modifier_extension);

CREATE INDEX idx_human_name_text ON human_name (text);
CREATE INDEX idx_patient_birthdate ON patient (birthdate);
