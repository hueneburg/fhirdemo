FROM postgres:17.6-alpine3.22

COPY 01-schema.sql /docker-entrypoint-initdb.d/
COPY 02-patient-data.sql /docker-entrypoint-initdb.d/
COPY 03-extension.sql /docker-entrypoint-initdb.d/

COPY patient-extension /tmp

COPY patient.control /usr/local/share/postgresql/extension/

RUN cat /tmp/views.sql \
    /tmp/internal-functions.sql \
    /tmp/public-functions.sql \
    /tmp/view-refresh.sql > /usr/local/share/postgresql/extension/patient--1.0.sql
