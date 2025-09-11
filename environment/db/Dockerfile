FROM postgres:17.6-alpine3.22

ENV POSTGRES_USER=myuser
ENV POSTGRES_PASSWORD=mypassword
ENV POSTGRES_DB=fhir

COPY schema.sql /docker-entrypoint-initdb.d/
