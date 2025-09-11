CREATE TYPE human_name_use AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'NICKNAME', 'ANONYMOUS', 'OLD', 'MAIDEN');
CREATE TYPE contact_point_system AS ENUM ('PHONE', 'FAX', 'EMAIL', 'PAGER', 'URL', 'SMS', 'OTHER');
CREATE TYPE contact_point_use AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'MOBILE');
CREATE TYPE gender AS ENUM ('FEMALE', 'MALE', 'OTHER', 'UNKNOWN');
CREATE TYPE address_use AS ENUM ('HOME', 'WORK', 'TEMP', 'OLD', 'BILLING');
CREATE TYPE address_type AS ENUM ('POSTAL', 'PHYSICAL', 'BOTH');
CREATE TYPE link_type AS ENUM ('REPLACED-BY', 'REPLACES', 'REFER', 'SEEALSO');
CREATE TYPE extension_type AS ENUM (
    'BASE64BINARY',
    'BOOLEAN',
    'CANONICAL',
    'CODE',
    'DATE',
    'DATETIME',
    'DECIMAL',
    'ID',
    'INSTANT',
    'INTEGER',
    'MARKDOWN',
    'OID',
    'POSITIVE_INT',
    'STRING',
    'TIME',
    'UNSIGNED_INT',
    'URI',
    'URL',
    'UUID',
    'ADDRESS',
    'AGE',
    'ANNOTATION',
    'ATTACHMENT',
    'CODEABLE_CONCEPT',
    'CODEABLE_REFERENCE',
    'CODING',
    'CONTACT_POINT',
    'COUNT',
    'DISTANCE',
    'DURATION',
    'HUMAN_NAME',
    'IDENTIFIER',
    'MONEY',
    'PERIOD',
    'QUANTITY',
    'RANGE',
    'RATIO',
    'RATIO_RANGE',
    'REFERENCE',
    'SAMPLED_DATA',
    'SIGNATURE',
    'TIMING',
    'CONTACT_DETAIL',
    'CONTRIBUTOR',
    'DATA_REQUIREMENT',
    'EXPRESSION',
    'PARAMETER_DEFINITION',
    'RELATED_ARTIFACT',
    'TRIGGER_DEFINITION',
    'USAGE_CONTEXT',
    'DOSAGE'
    );
CREATE TYPE author_reference_type AS ENUM ('STRING', 'PRACTITIONER', 'PATIENT', 'RELATED_PERSON', 'ORGANIZATION');
CREATE TYPE identifier_use AS ENUM ('USUAL', 'OFFICIAL', 'TEMP', 'OLD');
CREATE TYPE narrative_status AS ENUM ('GENERATED', 'EXTENSIONS', 'ADDITIONAL', 'EMPTY');
CREATE TYPE day_of_week AS ENUM ('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN');
CREATE TYPE practitioner_status AS ENUM ('ACTIVE', 'SUSPENDED', 'ERROR', 'OFF', 'ENTERED-IN-ERROR', 'TEST');
CREATE TYPE endpoint_status AS ENUM ('ACTIVE', 'SUSPENDED', 'ERROR', 'OFF', 'ENTERED-IN-ERROR', 'TEST');
CREATE TYPE location_status AS ENUM ('ACTIVE', 'SUSPENDED', 'INACTIVE');
CREATE TYPE location_mode AS ENUM ('INSTANCE', 'KIND');

CREATE DOMAIN uri AS TEXT;
CREATE DOMAIN positive_integer AS INTEGER CHECK (value > 0);
CREATE DOMAIN unsigned_integer AS INTEGER CHECK (value >= 0);
CREATE DOMAIN fhir_date AS TEXT CHECK (value ~*
                                       '^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?$');
CREATE DOMAIN fhir_datetime AS TEXT CHECK (value ~*
                                           '^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?(Z|(\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?)?)?$');
CREATE DOMAIN fhir_time AS TEXT CHECK (value ~* '^([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\.[0-9]+)?$');

CREATE TABLE IF NOT EXISTS element (
    id uuid PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS meta (
    id           uuid PRIMARY KEY NOT NULL,
    version      TEXT,
    last_updated fhir_datetime,
    source       uri,
    profile      uri[]
);

CREATE TABLE IF NOT EXISTS resource (
    id             uuid PRIMARY KEY,
    meta           uuid,
    implicit_rules uri,
    language       TEXT
);

CREATE TABLE IF NOT EXISTS extension (
    id             uuid PRIMARY KEY,
    element        uuid,
    uri            uri            NOT NULL,
    extension_type extension_type NOT NULL,
    bin_value      bytea,
    bool_value     bool,
    uri_value      uri,
    text_value     TEXT,
    decimal_value  NUMERIC,
    int_value      INTEGER,
    uuid_value     uuid
);

CREATE TABLE IF NOT EXISTS backbone_element (
    id uuid PRIMARY KEY NOT NULL
);

CREATE TABLE IF NOT EXISTS author (
    id             uuid PRIMARY KEY,
    reference_type author_reference_type NOT NULL,
    text_value     TEXT
);

CREATE TABLE IF NOT EXISTS annotation (
    id     uuid PRIMARY KEY NOT NULL,
    time   fhir_datetime,
    text   TEXT NOT NULL,
    author uuid
);

CREATE TABLE IF NOT EXISTS attachment (
    id           uuid PRIMARY KEY NOT NULL,
    content_type TEXT,
    language     TEXT,
    data         bytea,
    url          TEXT,
    size         INTEGER,
    hash         bytea,
    title        TEXT,
    creation     fhir_datetime
);

CREATE TABLE IF NOT EXISTS coding (
    id            uuid PRIMARY KEY NOT NULL,
    system        TEXT,
    version       TEXT,
    code          TEXT,
    display       TEXT,
    user_selected BOOLEAN
);

CREATE TABLE IF NOT EXISTS codeable_concept (
    id   uuid PRIMARY KEY NOT NULL,
    text TEXT
);

CREATE TABLE IF NOT EXISTS identifier (
    id           uuid PRIMARY KEY NOT NULL,
    use          identifier_use,
    type         uuid,
    system       TEXT,
    value        TEXT,
    period_start fhir_datetime,
    period_end   fhir_datetime,
    assigner     uuid
);

CREATE TABLE IF NOT EXISTS reference (
    id         uuid PRIMARY KEY NOT NULL,
    reference  TEXT,
    type       TEXT,
    identifier uuid,
    display    TEXT
);

CREATE TABLE IF NOT EXISTS codeable_reference (
    id        uuid PRIMARY KEY NOT NULL,
    concept   uuid,
    reference uuid
);

CREATE TABLE IF NOT EXISTS contact_point (
    id           uuid PRIMARY KEY NOT NULL,
    system       contact_point_system,
    value        TEXT,
    use          contact_point_use,
    rank         positive_integer,
    period_start fhir_datetime,
    period_end   fhir_datetime
);

CREATE TABLE IF NOT EXISTS contact_detail (
    id   uuid PRIMARY KEY NOT NULL,
    name TEXT
);

CREATE TABLE IF NOT EXISTS contact_detail_contact_point (
    contact_detail uuid,
    contact_point  uuid
);

CREATE TABLE IF NOT EXISTS human_name (
    id           uuid PRIMARY KEY NOT NULL,
    use          human_name_use,
    text         TEXT,
    family       TEXT,
    given        TEXT[],
    prefix       TEXT[],
    suffix       TEXT[],
    period_start fhir_datetime,
    period_end   fhir_datetime
);

CREATE TABLE IF NOT EXISTS coding_codeable_concept (
    codeable_concept uuid,
    coding           uuid
);

CREATE TABLE IF NOT EXISTS meta_security (
    meta     uuid,
    security uuid
);

CREATE TABLE IF NOT EXISTS meta_tag (
    meta uuid,
    tag  uuid
);

CREATE TABLE IF NOT EXISTS narrative (
    id     uuid PRIMARY KEY NOT NULL,
    status narrative_status NOT NULL,
    div    TEXT             NOT NULL
);

CREATE TABLE IF NOT EXISTS domain_resource (
    id   uuid PRIMARY KEY NOT NULL,
    text uuid
);

CREATE TABLE IF NOT EXISTS domain_resource_contained (
    domain_resource uuid,
    contained       uuid
);

CREATE TABLE IF NOT EXISTS domain_resource_extension (
    domain_resource uuid,
    extension       uuid
);

CREATE TABLE IF NOT EXISTS domain_resource_modifier_extension (
    domain_resource    uuid,
    modifier_extension uuid
);

CREATE TABLE IF NOT EXISTS organization (
    id      uuid PRIMARY KEY NOT NULL,
    active  boolean,
    name    TEXT,
    alias   TEXT[],
    part_of uuid
);

CREATE TABLE IF NOT EXISTS patient (
    id                    uuid PRIMARY KEY NOT NULL,
    active                BOOLEAN,
    gender                gender,
    birthdate             fhir_date,
    deceased              BOOLEAN,
    deceased_time         fhir_datetime,
    marital_status        uuid,
    multiple_birth        BOOLEAN,
    multiple_birth_count  INTEGER,
    managing_organization uuid
);

CREATE TABLE IF NOT EXISTS patient_attachment (
    patient    uuid,
    attachment uuid
);

CREATE TABLE IF NOT EXISTS patient_address (
    patient uuid,
    address uuid
);

CREATE TABLE IF NOT EXISTS patient_identifier (
    patient    uuid,
    identifier uuid
);

CREATE TABLE IF NOT EXISTS patient_name (
    patient uuid,
    name    uuid
);

CREATE TABLE IF NOT EXISTS patient_contact_point (
    patient       uuid,
    contact_point uuid
);

CREATE TABLE IF NOT EXISTS contact (
    id      uuid PRIMARY KEY NOT NULL,
    purpose uuid,
    name    uuid,
    address uuid
);

CREATE TABLE IF NOT EXISTS organization_contact (
    organization uuid,
    contact      uuid
);

CREATE TABLE IF NOT EXISTS organization_address (
    organization uuid,
    address      uuid
);

CREATE TABLE IF NOT EXISTS organization_contact_point (
    organization  uuid,
    contact_point uuid
);

CREATE TABLE IF NOT EXISTS organization_type (
    organization uuid,
    type         uuid
);

CREATE TABLE IF NOT EXISTS organization_identifier (
    organization uuid,
    identifier   uuid
);

CREATE TABLE IF NOT EXISTS practitioner (
    id                    uuid PRIMARY KEY NOT NULL,
    status                practitioner_status NOT NULL,
    connection_type       uuid,
    name                  TEXT,
    managing_organization uuid,
    period_start          fhir_datetime,
    period_end            fhir_datetime,
    payload_mimetype      TEXT[],
    address               uri                 NOT NULL,
    header                TEXT[]
);

CREATE TABLE IF NOT EXISTS practitioner_payload_type (
    practitioner     uuid,
    codeable_concept uuid
);

CREATE TABLE IF NOT EXISTS practitioner_contact_point (
    practitioner  uuid,
    contact_point uuid
);

CREATE TABLE IF NOT EXISTS practitioner_identifier (
    practitioner uuid,
    identifier   uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role (
    id                      uuid PRIMARY KEY NOT NULL,
    active                  boolean,
    period_start            fhir_datetime,
    period_end              fhir_datetime,
    practitioner            uuid,
    organization            uuid,
    availability_exceptions TEXT
);

CREATE TABLE IF NOT EXISTS practitioner_role_endpoint (
    practitioner_role uuid,
    endpoint          uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_contact_point (
    practitioner_role uuid,
    contact_point     uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_health_care_service (
    practitioner_role   uuid,
    health_care_service uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_location (
    practitioner_role uuid,
    location          uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_specialty (
    practitioner_role uuid,
    codeable_concept  uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_code (
    practitioner_role uuid,
    codeable_concept  uuid
);

CREATE TABLE IF NOT EXISTS practitioner_role_identifier (
    practitioner_role uuid,
    identifier        uuid
);

CREATE TABLE IF NOT EXISTS endpoint (
    id                    uuid PRIMARY KEY NOT NULL,
    status                endpoint_status NOT NULL,
    connection_type       uuid,
    name                  TEXT,
    managing_organization uuid,
    period_start          fhir_datetime,
    period_end            fhir_datetime,
    payload_mimetype      TEXT[],
    address               uri             NOT NULL,
    header                TEXT[]
);

CREATE TABLE IF NOT EXISTS endpoint_payload_type (
    endpoint         uuid,
    codeable_concept uuid
);

CREATE TABLE IF NOT EXISTS endpoint_contact_point (
    endpoint      uuid,
    contact_point uuid
);

CREATE TABLE IF NOT EXISTS endpoint_identifier (
    endpoint   uuid,
    identifier uuid
);

CREATE TABLE IF NOT EXISTS not_available (
    id           uuid PRIMARY KEY NOT NULL,
    description  TEXT NOT NULL,
    during_start TEXT,
    during_end   TEXT
);

CREATE TABLE IF NOT EXISTS available_time (
    id                   uuid PRIMARY KEY NOT NULL,
    day_of_week          day_of_week[],
    all_day              boolean,
    available_start_time fhir_time,
    available_end_time   fhir_time
);

CREATE TABLE IF NOT EXISTS health_care_service (
    id                      uuid PRIMARY KEY NOT NULL,
    active                  boolean,
    provided_by             uuid,
    name                    TEXT,
    comment                 TEXT,
    extra_details           TEXT,
    photo                   uuid,
    appointment_required    boolean,
    availability_exceptions TEXT
);

CREATE TABLE IF NOT EXISTS health_care_service_endpoint (
    health_care_service uuid,
    endpoint            uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_not_available (
    health_care_service uuid,
    not_available       uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_available_time (
    health_care_service uuid,
    available_time      uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_coverage_area (
    health_care_service uuid,
    location            uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_contact_point (
    health_care_service uuid,
    contact_point       uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_location (
    health_care_service uuid,
    location            uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_referral_method (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_communication (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_characteristic (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_program (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_service_provision_code (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_specialty (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_type (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_category (
    health_care_service uuid,
    codeable_concept    uuid
);

CREATE TABLE IF NOT EXISTS health_care_service_identifier (
    health_care_service uuid,
    identifier          uuid
);

CREATE TABLE IF NOT EXISTS eligibility (
    id      uuid PRIMARY KEY NOT NULL,
    comment TEXT
);

CREATE TABLE IF NOT EXISTS eligibility_codeable_concept (
    eligibility      uuid,
    codeable_concept uuid
);

CREATE TABLE IF NOT EXISTS location (
    id                     uuid PRIMARY KEY NOT NULL,
    status                 location_status,
    operational_status     uuid,
    name                   TEXT,
    alias                  TEXT[],
    description            TEXT,
    mode                   location_mode,
    address                uuid,
    physical_type          uuid,
    managing_organization  uuid,
    part_of                uuid,
    availability_exception TEXT
);

CREATE TABLE IF NOT EXISTS location_endpoint (
    location uuid,
    endpoint uuid
);

CREATE TABLE IF NOT EXISTS location_type (
    location         uuid,
    codeable_concept uuid
);

CREATE TABLE IF NOT EXISTS location_identifier (
    location   uuid,
    identifier uuid
);

CREATE TABLE IF NOT EXISTS hours_of_operation (
    id           uuid PRIMARY KEY NOT NULL,
    days_of_week day_of_week[],
    all_day      boolean,
    opening_time fhir_time,
    closing_time fhir_time
);

CREATE TABLE IF NOT EXISTS position (
    id        uuid PRIMARY KEY NOT NULL,
    longitude DECIMAL NOT NULL,
    latitude  DECIMAL NOT NULL,
    altitude  DECIMAL
);

CREATE TABLE IF NOT EXISTS communication (
    id        uuid PRIMARY KEY NOT NULL,
    language  uuid,
    preferred boolean
);

CREATE TABLE IF NOT EXISTS contact_contact_point (
    contact       uuid,
    contact_point uuid
);

CREATE TABLE IF NOT EXISTS address (
    id           uuid PRIMARY KEY NOT NULL,
    use          address_use,
    type         address_type,
    text         TEXT,
    line         TEXT[],
    city         TEXT,
    district     TEXT,
    state        TEXT,
    postal_code  TEXT,
    country      TEXT,
    period_start fhir_datetime,
    period_end   fhir_datetime
);

CREATE TABLE IF NOT EXISTS related_person (
    id           uuid PRIMARY KEY NOT NULL,
    active       boolean,
    patient      uuid,
    gender       gender,
    birthdate    fhir_date,
    period_start fhir_datetime,
    period_end   fhir_datetime
);

CREATE TABLE IF NOT EXISTS related_person_communication (
    related_person uuid,
    communication  uuid
);

CREATE TABLE IF NOT EXISTS related_person_photo (
    related_person uuid,
    attachment     uuid
);

CREATE TABLE IF NOT EXISTS related_person_address (
    related_person uuid,
    address        uuid
);

CREATE TABLE IF NOT EXISTS related_person_human_name (
    related_person uuid,
    human_name     uuid
);

CREATE TABLE IF NOT EXISTS related_person_relationship (
    related_person   uuid,
    codeable_concept uuid
);

CREATE TABLE IF NOT EXISTS related_person_identifier (
    related_person uuid,
    identifier     uuid
);

CREATE TABLE IF NOT EXISTS related_person_contact_point (
    related_person uuid,
    contact_point  uuid
);

CREATE TABLE IF NOT EXISTS backbone_element_modifier_extension (
    backbone_element uuid,
    extension        uuid
);

CREATE TABLE IF NOT EXISTS patient_link (
    id                   uuid PRIMARY KEY NOT NULL,
    patient              uuid,
    other_patient        uuid,
    other_related_person uuid,
    type                 link_type NOT NULL
);

ALTER TABLE resource
    ADD FOREIGN KEY (meta) REFERENCES meta (id),
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE extension
    ADD FOREIGN KEY (element) REFERENCES element (id);
ALTER TABLE annotation
    ADD FOREIGN KEY (author) REFERENCES author (id),
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE identifier
    ADD FOREIGN KEY (type) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE reference
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id),
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE codeable_reference
    ADD FOREIGN KEY (concept) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (reference) REFERENCES reference (id),
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE contact_detail_contact_point
    ADD FOREIGN KEY (contact_detail) REFERENCES contact_detail (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE coding_codeable_concept
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (coding) REFERENCES coding (id);
ALTER TABLE meta_security
    ADD FOREIGN KEY (meta) REFERENCES meta (id),
    ADD FOREIGN KEY (security) REFERENCES coding (id);
ALTER TABLE meta_tag
    ADD FOREIGN KEY (meta) REFERENCES meta (id),
    ADD FOREIGN KEY (tag) REFERENCES coding (id);
ALTER TABLE domain_resource
    ADD FOREIGN KEY (text) REFERENCES narrative (id),
    ADD FOREIGN KEY (id) REFERENCES resource (id);
ALTER TABLE domain_resource_contained
    ADD FOREIGN KEY (domain_resource) REFERENCES domain_resource (id),
    ADD FOREIGN KEY (contained) REFERENCES resource (id);
ALTER TABLE domain_resource_extension
    ADD FOREIGN KEY (domain_resource) REFERENCES domain_resource (id),
    ADD FOREIGN KEY (extension) REFERENCES extension (id);
ALTER TABLE domain_resource_modifier_extension
    ADD FOREIGN KEY (domain_resource) REFERENCES domain_resource (id),
    ADD FOREIGN KEY (modifier_extension) REFERENCES extension (id);
ALTER TABLE organization
    ADD FOREIGN KEY (part_of) REFERENCES organization (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE patient
    ADD FOREIGN KEY (marital_status) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (managing_organization) REFERENCES organization (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE patient_attachment
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (attachment) REFERENCES attachment (id);
ALTER TABLE patient_address
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (address) REFERENCES address (id);
ALTER TABLE patient_identifier
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE patient_name
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (name) REFERENCES human_name (id);
ALTER TABLE patient_contact_point
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE contact
    ADD FOREIGN KEY (purpose) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (name) REFERENCES human_name (id),
    ADD FOREIGN KEY (address) REFERENCES address (id),
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE organization_contact
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (contact) REFERENCES contact (id);
ALTER TABLE organization_address
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (address) REFERENCES address (id);
ALTER TABLE organization_contact_point
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE organization_type
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (type) REFERENCES codeable_concept (id);
ALTER TABLE organization_identifier
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE practitioner
    ADD FOREIGN KEY (connection_type) REFERENCES coding (id),
    ADD FOREIGN KEY (managing_organization) REFERENCES organization (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE practitioner_payload_type
    ADD FOREIGN KEY (practitioner) REFERENCES practitioner (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE practitioner_contact_point
    ADD FOREIGN KEY (practitioner) REFERENCES practitioner (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE practitioner_identifier
    ADD FOREIGN KEY (practitioner) REFERENCES practitioner (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE practitioner_role
    ADD FOREIGN KEY (practitioner) REFERENCES practitioner (id),
    ADD FOREIGN KEY (organization) REFERENCES organization (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE practitioner_role_endpoint
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id);
ALTER TABLE practitioner_role_contact_point
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE practitioner_role_health_care_service
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id);
ALTER TABLE practitioner_role_location
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (location) REFERENCES location (id);
ALTER TABLE practitioner_role_specialty
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE practitioner_role_code
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE practitioner_role_identifier
    ADD FOREIGN KEY (practitioner_role) REFERENCES practitioner_role (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE endpoint
    ADD FOREIGN KEY (connection_type) REFERENCES coding (id),
    ADD FOREIGN KEY (managing_organization) REFERENCES organization (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE endpoint_payload_type
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE endpoint_contact_point
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE endpoint_identifier
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE health_care_service
    ADD FOREIGN KEY (provided_by) REFERENCES organization (id),
    ADD FOREIGN KEY (photo) REFERENCES attachment (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE health_care_service_endpoint
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id);
ALTER TABLE health_care_service_not_available
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (not_available) REFERENCES not_available (id);
ALTER TABLE health_care_service_available_time
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (available_time) REFERENCES available_time (id);
ALTER TABLE health_care_service_coverage_area
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (location) REFERENCES location (id);
ALTER TABLE health_care_service_contact_point
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE health_care_service_location
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (location) REFERENCES location (id);
ALTER TABLE health_care_service_referral_method
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_communication
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_characteristic
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_program
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_service_provision_code
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_specialty
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_type
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_category
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE health_care_service_identifier
    ADD FOREIGN KEY (health_care_service) REFERENCES health_care_service (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE eligibility_codeable_concept
    ADD FOREIGN KEY (eligibility) REFERENCES eligibility (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE location
    ADD FOREIGN KEY (operational_status) REFERENCES coding (id),
    ADD FOREIGN KEY (address) REFERENCES address (id),
    ADD FOREIGN KEY (physical_type) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (managing_organization) REFERENCES organization (id),
    ADD FOREIGN KEY (part_of) REFERENCES location (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE location_endpoint
    ADD FOREIGN KEY (location) REFERENCES location (id),
    ADD FOREIGN KEY (endpoint) REFERENCES endpoint (id);
ALTER TABLE location_type
    ADD FOREIGN KEY (location) REFERENCES location (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE location_identifier
    ADD FOREIGN KEY (location) REFERENCES location (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE communication
    ADD FOREIGN KEY (language) REFERENCES codeable_concept (id),
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE contact_contact_point
    ADD FOREIGN KEY (contact) REFERENCES contact (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE related_person
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (id) REFERENCES domain_resource (id);
ALTER TABLE related_person_communication
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (communication) REFERENCES communication (id);
ALTER TABLE related_person_photo
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (attachment) REFERENCES attachment (id);
ALTER TABLE related_person_address
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (address) REFERENCES address (id);
ALTER TABLE related_person_human_name
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (human_name) REFERENCES human_name (id);
ALTER TABLE related_person_relationship
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (codeable_concept) REFERENCES codeable_concept (id);
ALTER TABLE related_person_identifier
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (identifier) REFERENCES identifier (id);
ALTER TABLE related_person_contact_point
    ADD FOREIGN KEY (related_person) REFERENCES related_person (id),
    ADD FOREIGN KEY (contact_point) REFERENCES contact_point (id);
ALTER TABLE backbone_element_modifier_extension
    ADD FOREIGN KEY (backbone_element) REFERENCES backbone_element (id),
    ADD FOREIGN KEY (extension) REFERENCES extension (id);
ALTER TABLE patient_link
    ADD FOREIGN KEY (patient) REFERENCES patient (id),
    ADD FOREIGN KEY (other_patient) REFERENCES patient (id),
    ADD FOREIGN KEY (other_related_person) REFERENCES related_person (id);
ALTER TABLE identifier
    ADD FOREIGN KEY (assigner) REFERENCES organization (id);
ALTER TABLE backbone_element
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE attachment
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE coding
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE codeable_concept
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE contact_point
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE contact_detail
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE human_name
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE narrative
    ADD FOREIGN KEY (id) REFERENCES element (id);
ALTER TABLE not_available
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE available_time
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE eligibility
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE hours_of_operation
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE position
    ADD FOREIGN KEY (id) REFERENCES backbone_element (id);
ALTER TABLE address
    ADD FOREIGN KEY (id) REFERENCES element (id);
CREATE INDEX idx_contact_detail_contact_point_contact_detail ON contact_detail_contact_point (contact_detail);
CREATE INDEX idx_contact_detail_contact_point_contact_point ON contact_detail_contact_point (contact_point);
CREATE INDEX idx_coding_codeable_concept_codeable_concept ON coding_codeable_concept (codeable_concept);
CREATE INDEX idx_coding_codeable_concept_coding ON coding_codeable_concept (coding);
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
CREATE INDEX idx_patient_attachment_patient ON patient_attachment (patient);
CREATE INDEX idx_patient_attachment_attachment ON patient_attachment (attachment);
CREATE INDEX idx_patient_address_patient ON patient_address (patient);
CREATE INDEX idx_patient_address_address ON patient_address (address);
CREATE INDEX idx_patient_identifier_patient ON patient_identifier (patient);
CREATE INDEX idx_patient_identifier_identifier ON patient_identifier (identifier);
CREATE INDEX idx_patient_name_patient ON patient_name (patient);
CREATE INDEX idx_patient_name_name ON patient_name (name);
CREATE INDEX idx_patient_contact_point_patient ON patient_contact_point (patient);
CREATE INDEX idx_patient_contact_point_contact_point ON patient_contact_point (contact_point);
CREATE INDEX idx_organization_contact_organization ON organization_contact (organization);
CREATE INDEX idx_organization_contact_contact ON organization_contact (contact);
CREATE INDEX idx_organization_address_organization ON organization_address (organization);
CREATE INDEX idx_organization_address_address ON organization_address (address);
CREATE INDEX idx_organization_contact_point_organization ON organization_contact_point (organization);
CREATE INDEX idx_organization_contact_point_contact_point ON organization_contact_point (contact_point);
CREATE INDEX idx_organization_type_organization ON organization_type (organization);
CREATE INDEX idx_organization_type_type ON organization_type (type);
CREATE INDEX idx_organization_identifier_organization ON organization_identifier (organization);
CREATE INDEX idx_organization_identifier_identifier ON organization_identifier (identifier);
CREATE INDEX idx_practitioner_payload_type_practitioner ON practitioner_payload_type (practitioner);
CREATE INDEX idx_practitioner_payload_type_codeable_concept ON practitioner_payload_type (codeable_concept);
CREATE INDEX idx_practitioner_contact_point_practitioner ON practitioner_contact_point (practitioner);
CREATE INDEX idx_practitioner_contact_point_contact_point ON practitioner_contact_point (contact_point);
CREATE INDEX idx_practitioner_identifier_practitioner ON practitioner_identifier (practitioner);
CREATE INDEX idx_practitioner_identifier_identifier ON practitioner_identifier (identifier);
CREATE INDEX idx_practitioner_role_endpoint_practitioner_role ON practitioner_role_endpoint (practitioner_role);
CREATE INDEX idx_practitioner_role_endpoint_endpoint ON practitioner_role_endpoint (endpoint);
CREATE INDEX idx_practitioner_role_contact_point_practitioner_role ON practitioner_role_contact_point (practitioner_role);
CREATE INDEX idx_practitioner_role_contact_point_contact_point ON practitioner_role_contact_point (contact_point);
CREATE INDEX idx_practitioner_role_health_care_service_practitioner_role ON practitioner_role_health_care_service (practitioner_role);
CREATE INDEX idx_practitioner_role_health_care_service_health_care_service ON practitioner_role_health_care_service (health_care_service);
CREATE INDEX idx_practitioner_role_location_practitioner_role ON practitioner_role_location (practitioner_role);
CREATE INDEX idx_practitioner_role_location_location ON practitioner_role_location (location);
CREATE INDEX idx_practitioner_role_specialty_practitioner_role ON practitioner_role_specialty (practitioner_role);
CREATE INDEX idx_practitioner_role_specialty_codeable_concept ON practitioner_role_specialty (codeable_concept);
CREATE INDEX idx_practitioner_role_code_practitioner_role ON practitioner_role_code (practitioner_role);
CREATE INDEX idx_practitioner_role_code_codeable_concept ON practitioner_role_code (codeable_concept);
CREATE INDEX idx_practitioner_role_identifier_practitioner_role ON practitioner_role_identifier (practitioner_role);
CREATE INDEX idx_practitioner_role_identifier_identifier ON practitioner_role_identifier (identifier);
CREATE INDEX idx_endpoint_payload_type_endpoint ON endpoint_payload_type (endpoint);
CREATE INDEX idx_endpoint_payload_type_codeable_concept ON endpoint_payload_type (codeable_concept);
CREATE INDEX idx_endpoint_contact_point_endpoint ON endpoint_contact_point (endpoint);
CREATE INDEX idx_endpoint_contact_point_contact_point ON endpoint_contact_point (contact_point);
CREATE INDEX idx_endpoint_identifier_endpoint ON endpoint_identifier (endpoint);
CREATE INDEX idx_endpoint_identifier_identifier ON endpoint_identifier (identifier);
CREATE INDEX idx_health_care_service_endpoint_health_care_service ON health_care_service_endpoint (health_care_service);
CREATE INDEX idx_health_care_service_endpoint_endpoint ON health_care_service_endpoint (endpoint);
CREATE INDEX idx_health_care_service_not_available_health_care_service ON health_care_service_not_available (health_care_service);
CREATE INDEX idx_health_care_service_not_available_not_available ON health_care_service_not_available (not_available);
CREATE INDEX idx_health_care_service_available_time_health_care_service ON health_care_service_available_time (health_care_service);
CREATE INDEX idx_health_care_service_available_time_available_time ON health_care_service_available_time (available_time);
CREATE INDEX idx_health_care_service_coverage_area_health_care_service ON health_care_service_coverage_area (health_care_service);
CREATE INDEX idx_health_care_service_coverage_area_location ON health_care_service_coverage_area (location);
CREATE INDEX idx_health_care_service_contact_point_health_care_service ON health_care_service_contact_point (health_care_service);
CREATE INDEX idx_health_care_service_contact_point_contact_point ON health_care_service_contact_point (contact_point);
CREATE INDEX idx_health_care_service_location_health_care_service ON health_care_service_location (health_care_service);
CREATE INDEX idx_health_care_service_location_location ON health_care_service_location (location);
CREATE INDEX idx_health_care_service_referral_method_health_care_service ON health_care_service_referral_method (health_care_service);
CREATE INDEX idx_health_care_service_referral_method_codeable_concept ON health_care_service_referral_method (codeable_concept);
CREATE INDEX idx_health_care_service_communication_health_care_service ON health_care_service_communication (health_care_service);
CREATE INDEX idx_health_care_service_communication_codeable_concept ON health_care_service_communication (codeable_concept);
CREATE INDEX idx_health_care_service_characteristic_health_care_service ON health_care_service_characteristic (health_care_service);
CREATE INDEX idx_health_care_service_characteristic_codeable_concept ON health_care_service_characteristic (codeable_concept);
CREATE INDEX idx_health_care_service_program_health_care_service ON health_care_service_program (health_care_service);
CREATE INDEX idx_health_care_service_program_codeable_concept ON health_care_service_program (codeable_concept);
CREATE INDEX idx_health_care_service_service_provision_code_health_care_serv ON health_care_service_service_provision_code (health_care_service);
CREATE INDEX idx_health_care_service_service_provision_code_codeable_concept ON health_care_service_service_provision_code (codeable_concept);
CREATE INDEX idx_health_care_service_specialty_health_care_service ON health_care_service_specialty (health_care_service);
CREATE INDEX idx_health_care_service_specialty_codeable_concept ON health_care_service_specialty (codeable_concept);
CREATE INDEX idx_health_care_service_type_health_care_service ON health_care_service_type (health_care_service);
CREATE INDEX idx_health_care_service_type_codeable_concept ON health_care_service_type (codeable_concept);
CREATE INDEX idx_health_care_service_category_health_care_service ON health_care_service_category (health_care_service);
CREATE INDEX idx_health_care_service_category_codeable_concept ON health_care_service_category (codeable_concept);
CREATE INDEX idx_health_care_service_identifier_health_care_service ON health_care_service_identifier (health_care_service);
CREATE INDEX idx_health_care_service_identifier_identifier ON health_care_service_identifier (identifier);
CREATE INDEX idx_eligibility_codeable_concept_eligibility ON eligibility_codeable_concept (eligibility);
CREATE INDEX idx_eligibility_codeable_concept_codeable_concept ON eligibility_codeable_concept (codeable_concept);
CREATE INDEX idx_location_endpoint_location ON location_endpoint (location);
CREATE INDEX idx_location_endpoint_endpoint ON location_endpoint (endpoint);
CREATE INDEX idx_location_type_location ON location_type (location);
CREATE INDEX idx_location_type_codeable_concept ON location_type (codeable_concept);
CREATE INDEX idx_location_identifier_location ON location_identifier (location);
CREATE INDEX idx_location_identifier_identifier ON location_identifier (identifier);
CREATE INDEX idx_contact_contact_point_contact ON contact_contact_point (contact);
CREATE INDEX idx_contact_contact_point_contact_point ON contact_contact_point (contact_point);
CREATE INDEX idx_related_person_communication_related_person ON related_person_communication (related_person);
CREATE INDEX idx_related_person_communication_communication ON related_person_communication (communication);
CREATE INDEX idx_related_person_photo_related_person ON related_person_photo (related_person);
CREATE INDEX idx_related_person_photo_attachment ON related_person_photo (attachment);
CREATE INDEX idx_related_person_address_related_person ON related_person_address (related_person);
CREATE INDEX idx_related_person_address_address ON related_person_address (address);
CREATE INDEX idx_related_person_human_name_related_person ON related_person_human_name (related_person);
CREATE INDEX idx_related_person_human_name_human_name ON related_person_human_name (human_name);
CREATE INDEX idx_related_person_relationship_related_person ON related_person_relationship (related_person);
CREATE INDEX idx_related_person_relationship_codeable_concept ON related_person_relationship (codeable_concept);
CREATE INDEX idx_related_person_identifier_related_person ON related_person_identifier (related_person);
CREATE INDEX idx_related_person_identifier_identifier ON related_person_identifier (identifier);
CREATE INDEX idx_related_person_contact_point_related_person ON related_person_contact_point (related_person);
CREATE INDEX idx_related_person_contact_point_contact_point ON related_person_contact_point (contact_point);
CREATE INDEX idx_backbone_element_modifier_extension_backbone_element ON backbone_element_modifier_extension (backbone_element);
CREATE INDEX idx_backbone_element_modifier_extension_extension ON backbone_element_modifier_extension (extension);
