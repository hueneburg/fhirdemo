CREATE SCHEMA IF NOT EXISTS fhir;

CREATE TYPE fhir.GENDER AS ENUM ('FEMALE', 'MALE', 'OTHER', 'UNKNOWN');

CREATE TABLE IF NOT EXISTS fhir.patient (
    id         UUID PRIMARY KEY NOT NULL,
    data       JSONB,
    birthdate  TEXT,
    gender     fhir.GENDER,
    created_at TEXT             NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT::TEXT
);

CREATE TABLE IF NOT EXISTS fhir.patient_name (
    patient      UUID NOT NULL REFERENCES fhir.patient (id),
    patient_name TEXT NOT NULL,
    period_start TIMESTAMPTZ,
    period_end   TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS fhir.id_list (
    id UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid()
);

CREATE INDEX idx_patient_birthdate ON fhir.patient (birthdate);
CREATE INDEX idx_patient_gender ON fhir.patient (gender);
CREATE INDEX idx_patient_pagination ON fhir.patient (created_at, id);
CREATE INDEX idx_patient_name_patient ON fhir.patient_name (patient);
CREATE INDEX idx_patient_name_patient_name ON fhir.patient_name (patient_name);
CREATE INDEX idx_patient_name_period_start ON fhir.patient_name (period_start);
CREATE INDEX idx_patient_name_period_end ON fhir.patient_name (period_end);
