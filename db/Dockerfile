FROM postgres:17.6-alpine3.22

COPY 01-schema.sql /docker-entrypoint-initdb.d/
COPY 03-patient-data.sql /docker-entrypoint-initdb.d/
