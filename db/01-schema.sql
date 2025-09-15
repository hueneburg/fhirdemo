CREATE TYPE GENDER AS ENUM ('FEMALE', 'MALE', 'OTHER', 'UNKNOWN');
CREATE TYPE LINK_TYPE AS ENUM ('REPLACED-BY', 'REPLACES', 'REFER', 'SEEALSO');
CREATE TYPE NARRATIVE_STATUS AS ENUM ('GENERATED', 'EXTENSIONS', 'ADDITIONAL', 'EMPTY');
CREATE TYPE IDENTIFIER_USE AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'OLD');
CREATE TYPE HUMAN_NAME_USE AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'NICKNAME', 'ANONYMOUS', 'OLD', 'MAIDEN');
CREATE TYPE ADDRESS_USE AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'BILLING');
CREATE TYPE ADDRESS_TYPE AS ENUM ('POSTAL', 'PHYSICAL', 'BOTH');
CREATE TYPE CONTACT_POINT_SYSTEM AS ENUM ('PHONE', 'FAX', 'EMAIL', 'PAGER', 'URL', 'SMS', 'OTHER');
CREATE TYPE CONTACT_POINT_USE AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'MOBILE');

CREATE DOMAIN unsigned_integer AS INTEGER CHECK (value >= 0);
CREATE DOMAIN positive_integer AS INTEGER CHECK (value > 0);
CREATE DOMAIN fhir_date AS TEXT CHECK (value ~*
                                       '^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?$');
CREATE DOMAIN fhir_datetime AS TEXT CHECK (value ~*
                                           '^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?)?)?$');

CREATE TABLE IF NOT EXISTS element (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

CREATE TABLE IF NOT EXISTS coding (
    id            UUID PRIMARY KEY REFERENCES element (id),
    system        TEXT,
    code          TEXT,
    display       TEXT,
    user_selected BOOLEAN
);

CREATE TABLE IF NOT EXISTS meta (
    id           UUID PRIMARY KEY NOT NULL,
    version      TEXT,
    last_updated TIMESTAMPTZ,
    source       TEXT,
    profile      TEXT[]           NOT NULL
);

CREATE TABLE IF NOT EXISTS meta_security (
    meta     UUID NOT NULL REFERENCES meta (id),
    security UUID NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS meta_tag (
    meta UUID NOT NULL REFERENCES meta (id),
    tag  UUID NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS resource (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meta           UUID REFERENCES meta (id),
    implicit_rules TEXT,
    language       TEXT
);

CREATE TABLE IF NOT EXISTS extension (
    id    UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    uri   TEXT             NOT NULL,
    value JSONB
);

CREATE TABLE IF NOT EXISTS narrative (
    id     UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    status NARRATIVE_STATUS NOT NULL,
    div    TEXT             NOT NULL
);

CREATE TABLE IF NOT EXISTS domain_resource (
    id   UUID PRIMARY KEY NOT NULL REFERENCES resource (id),
    text UUID REFERENCES narrative (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_contained (
    domain_resource UUID NOT NULL REFERENCES domain_resource (id),
    contained       UUID NOT NULL REFERENCES resource (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_extension (
    domain_resource UUID NOT NULL REFERENCES domain_resource (id),
    extension       UUID NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS domain_resource_modifier_extension (
    domain_resource    UUID NOT NULL REFERENCES domain_resource (id),
    modifier_extension UUID NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS codeable_concept (
    id   UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    text TEXT
);

CREATE TABLE IF NOT EXISTS codeable_concept_coding (
    codeable_concept UUID NOT NULL REFERENCES codeable_concept (id),
    coding           UUID NOT NULL REFERENCES coding (id)
);

CREATE TABLE IF NOT EXISTS patient (
    id                     UUID PRIMARY KEY NOT NULL REFERENCES domain_resource (id),
    active                 BOOL,
    gender                 GENDER,
    birthdate              FHIR_DATE,
    deceased               BOOL,
    deceased_date_time     FHIR_DATETIME,
    marital_status         UUID REFERENCES codeable_concept (id),
    multiple_birth         BOOL,
    multiple_birth_integer INTEGER,
    managing_organization  UUID -- would reference organization but left out for this demo
);

CREATE TABLE IF NOT EXISTS identifier (
    id           UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    use          IDENTIFIER_USE,
    type         UUID REFERENCES codeable_concept (id),
    system       TEXT,
    value        TEXT,
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ,
    assigner     UUID
);

CREATE TABLE IF NOT EXISTS reference (
    id         UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    reference  TEXT,
    type       TEXT,
    identifier UUID REFERENCES identifier (id),
    display    TEXT
);

CREATE TABLE IF NOT EXISTS backbone_element (
    id UUID PRIMARY KEY NOT NULL REFERENCES element (id)
);

CREATE TABLE IF NOT EXISTS element_extension (
    element   UUID NOT NULL REFERENCES element (id),
    extension UUID NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS backbone_element_modifier_extension (
    backbone_element   UUID NOT NULL REFERENCES backbone_element (id),
    modifier_extension UUID NOT NULL REFERENCES extension (id)
);

CREATE TABLE IF NOT EXISTS patient_link (
    id      UUID PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    patient UUID             NOT NULL REFERENCES patient (id),
    other   UUID REFERENCES reference (id),
    type    LINK_TYPE        NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_general_practitioner (
    patient              UUID NOT NULL REFERENCES patient (id),
    general_practitioner UUID NOT NULL REFERENCES reference (id)
);

CREATE TABLE IF NOT EXISTS communication (
    id        UUID PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    language  UUID             NOT NULL REFERENCES codeable_concept (id),
    preferred BOOLEAN
);

CREATE TABLE IF NOT EXISTS patient_communication (
    patient       UUID NOT NULL REFERENCES patient (id),
    communication UUID NOT NULL REFERENCES communication (id)
);

CREATE TABLE IF NOT EXISTS human_name (
    id           UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    use          HUMAN_NAME_USE,
    text         TEXT,
    family       TEXT,
    given        TEXT[]           NOT NULL,
    prefix       TEXT[]           NOT NULL,
    suffix       TEXT[]           NOT NULL,
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS address (
    id           UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    use          ADDRESS_USE,
    type         ADDRESS_TYPE,
    text         TEXT,
    line         TEXT[]           NOT NULL,
    city         TEXT,
    district     TEXT,
    state        TEXT,
    postal_code  TEXT,
    country      TEXT,
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS contact (
    id           UUID PRIMARY KEY NOT NULL REFERENCES backbone_element (id),
    name         UUID REFERENCES human_name (id),
    address      UUID REFERENCES address (id),
    gender       GENDER,
    organization UUID REFERENCES reference (id),
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS contact_relationship (
    contact      UUID NOT NULL REFERENCES contact (id),
    relationship UUID NOT NULL REFERENCES codeable_concept (id)
);

CREATE TABLE IF NOT EXISTS patient_contact (
    patient UUID NOT NULL REFERENCES patient (id),
    contact UUID NOT NULL REFERENCES contact (id)
);

CREATE TABLE IF NOT EXISTS patient_address (
    patient UUID NOT NULL REFERENCES patient (id),
    address UUID NOT NULL REFERENCES address (id)
);

CREATE TABLE IF NOT EXISTS patient_name (
    patient UUID NOT NULL REFERENCES patient (id),
    name    UUID NOT NULL REFERENCES human_name (id)
);

CREATE TABLE IF NOT EXISTS contact_point (
    id           UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    system       CONTACT_POINT_SYSTEM,
    value        TEXT,
    use          CONTACT_POINT_USE,
    rank         POSITIVE_INTEGER,
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS contact_contact_point (
    contact       UUID NOT NULL REFERENCES contact (id),
    contact_point UUID NOT NULL REFERENCES contact_point (id)
);

CREATE TABLE IF NOT EXISTS patient_telecom (
    patient UUID NOT NULL REFERENCES patient (id),
    telecom UUID NOT NULL REFERENCES contact_point (id)
);

CREATE TABLE IF NOT EXISTS patient_identifier (
    patient    UUID NOT NULL REFERENCES patient (id),
    identifier UUID NOT NULL REFERENCES identifier (id)
);

CREATE TABLE IF NOT EXISTS attachment (
    id           UUID PRIMARY KEY NOT NULL REFERENCES element (id),
    content_type TEXT,
    language     TEXT,
    data         BYTEA,
    url          TEXT,
    size         UNSIGNED_INTEGER,
    hash         BYTEA,
    title        TEXT,
    creation     TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS patient_photo (
    patient UUID NOT NULL REFERENCES patient (id),
    photo   UUID NOT NULL REFERENCES attachment (id)
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
CREATE UNIQUE INDEX uniq_idx_element_extension ON element_extension (element, extension);

ALTER TABLE identifier
    ADD CONSTRAINT fk_identifier_reference FOREIGN KEY (assigner) REFERENCES reference (id);
