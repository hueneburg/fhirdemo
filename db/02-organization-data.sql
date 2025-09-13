BEGIN TRANSACTION;

INSERT INTO element (id)
VALUES -- organizations
       ('00000000-0000-0000-0000-000000000000'),
       ('00000000-0000-0000-0000-000000000001'),
       ('00000000-0000-0000-0000-000000000002'),
       -- narratives
       ('00000000-0000-0000-0001-000000000000'),
       -- extensions
       ('00000000-0000-0000-0002-000000000000'),
       -- meta
       ('00000000-0000-0000-0003-000000000000');

INSERT INTO meta (id, version, last_updated, source, profile)
VALUES ('00000000-0000-0000-0003-000000000000', '1.0.9A', '2025-09-12T12:00:00+02:00', '/some/source/definition',
        ARRAY ['https://example.com/meta-profile']);

INSERT INTO resource (id, meta, implicit_rules, language)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0003-000000000000', NULL, 'en-US'),
       ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-000000000000', NULL, 'en-US'),
       ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0003-000000000000', NULL, 'en-US');

INSERT INTO narrative (id, status, div)
VALUES ('00000000-0000-0000-0001-000000000000', 'GENERATED', '<div>Sample narrative</div>');

INSERT INTO domain_resource (id, text)
-- organizations
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0001-000000000000'),
       ('00000000-0000-0000-0000-000000000001', NULL),
       ('00000000-0000-0000-0000-000000000002', NULL);

INSERT INTO extension (id, uri, value)
VALUES ('00000000-0000-0000-0002-000000000000', 'https://github.com/hueneburg/fhirdemo/extension0', '{
  "valueContributor": {
    "id": "00000000-0001-0000-0000-000000000000",
    "type": "AUTHOR",
    "name": "Hans-Peter Karloff"
  }
}'),
       ('00000000-0000-0000-0002-000000000001', 'https://github.com/hueneburg/fhirdemo/extension1', '{
         "valueId": "00000000-0001-0000-0000-000000000001"
       }');

INSERT INTO domain_resource_extension (domain_resource, extension)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0002-000000000000');

INSERT INTO domain_resource_modifier_extension (domain_resource, modifier_extension)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0002-000000000001');

INSERT INTO domain_resource_contained (domain_resource, contained)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001');

INSERT INTO organization (id, active, name, alias, part_of)
VALUES ('00000000-0000-0000-0000-000000000000', TRUE, 'Uni Klinik Essen', ARRAY ['Uni Klinikum Essen'], NULL),
       ('00000000-0000-0000-0000-000000000001', TRUE, 'Caritas-Krankenhaus Bad Mergentheim', ARRAY []::TEXT[], NULL),
       ('00000000-0000-0000-0000-000000000002', FALSE, 'Ein geschlossenes Krankenhaus', ARRAY []::TEXT[], NULL);

COMMIT;