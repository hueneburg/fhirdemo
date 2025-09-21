FROM postgres:17.6-alpine3.22

COPY 01-schema.sql /docker-entrypoint-initdb.d/
COPY 03-extension.sql /docker-entrypoint-initdb.d/

COPY patient-extension/patient--1.0.sql /usr/local/share/postgresql/extension/

COPY patient-extension/patient.control /usr/local/share/postgresql/extension/
