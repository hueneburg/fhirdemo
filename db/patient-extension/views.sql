CREATE MATERIALIZED VIEW extension_nested AS
WITH RECURSIVE
    extension_tree AS (
        -- Base case: all extensions start as roots
        SELECT e.id,
               e.uri,
               e.value,
               e.id AS root_id
        FROM extension e

        UNION ALL

        -- Recursive step: attach children
        SELECT c.id,
               c.uri,
               c.value,
               t.root_id
        FROM extension_tree t
                 JOIN element_extension ee ON ee.element = t.id
                 JOIN extension c ON c.id = ee.extension),
    nested_json AS (SELECT t.id,
                           JSONB_BUILD_OBJECT(
                                   'id', t.id,
                                   'uri', t.uri,
                                   'value', t.value,
                                   'extension', COALESCE(
                                           (SELECT JSONB_AGG(child_json)
                                            FROM (SELECT JSONB_BUILD_OBJECT(
                                                                 'id', c.id,
                                                                 'uri', c.uri,
                                                                 'value', c.value,
                                                                 'extension', '[]'::jsonb
                                                         ) AS child_json
                                                  FROM element_extension ee
                                                           JOIN extension c ON c.id = ee.extension
                                                  WHERE ee.element = t.id) sub
                                            WHERE child_json IS NOT NULL),
                                           '[]'::jsonb
                                                )
                           ) AS json
                    FROM extension t)
SELECT t.id,
       n.json AS extension
FROM extension t
         JOIN nested_json n ON n.id = t.id;

CREATE UNIQUE INDEX idx_extension_nested_id ON extension_nested (id);

CREATE MATERIALIZED VIEW clean_extension AS
SELECT e.id                element,
       JSONB_BUILD_ARRAY() extension
FROM element e
         LEFT JOIN element_extension ee ON ee.element = e.id
WHERE ee.extension IS NULL
UNION ALL
SELECT e.id                      element,
       JSONB_AGG(TO_JSONB(en.*)) extension
FROM element e
         LEFT JOIN element_extension ee ON ee.element = e.id
         LEFT JOIN extension_nested en
                   ON en.id = ee.extension
WHERE ee.extension IS NOT NULL
GROUP BY e.id;

CREATE UNIQUE INDEX idx_clean_extension_id ON clean_extension (element);

CREATE MATERIALIZED VIEW clean_resource_extension AS
SELECT r.id                resource,
       JSONB_BUILD_ARRAY() extension
FROM domain_resource r
         LEFT JOIN domain_resource_extension dre ON dre.domain_resource = r.id
WHERE dre.extension IS NULL
UNION ALL
SELECT r.id                      resource,
       JSONB_AGG(TO_JSONB(en.*)) extension
FROM domain_resource r
         LEFT JOIN domain_resource_extension dre ON dre.domain_resource = r.id
         LEFT JOIN extension_nested en
                   ON en.id = dre.extension
WHERE dre.extension IS NOT NULL
GROUP BY r.id;

CREATE UNIQUE INDEX idx_clean_resource_extension_id ON clean_resource_extension (resource);

CREATE MATERIALIZED VIEW clean_codeable_concept_coding AS
SELECT cc.id AS            codeable_concept,
       JSONB_BUILD_ARRAY() coding
FROM codeable_concept cc
         LEFT JOIN codeable_concept_coding ccc ON cc.id = ccc.codeable_concept
WHERE ccc.coding IS NULL
UNION ALL
SELECT cc.id                    AS codeable_concept,
       JSONB_AGG(TO_JSONB(c.*)) AS coding
FROM codeable_concept cc
         LEFT JOIN codeable_concept_coding ccc ON cc.id = ccc.codeable_concept
         LEFT JOIN coding c ON c.id = ccc.coding
WHERE ccc.codeable_concept IS NOT NULL
GROUP BY cc.id;

CREATE UNIQUE INDEX idx_clean_codeable_concept_coding_cc ON clean_codeable_concept_coding (codeable_concept);

CREATE MATERIALIZED VIEW identifier_view AS
SELECT i.id,
       JSONB_BUILD_OBJECT(
               'id', i.id,
               'extension', ex.extension,
               'use', i.use,
               'type', JSONB_BUILD_OBJECT(
                       'id', cc.id,
                       'extension', ccex.extension,
                       'coding', cccc.coding,
                       'text', cc.text
                       ),
               'system', i.system,
               'value', i.value,
               'period', JSONB_BUILD_OBJECT(
                       'start', i.period_start,
                       'end', i.period_end
                         )
       ) AS identifier
FROM identifier i
         LEFT JOIN codeable_concept cc ON i.type = cc.id
         LEFT JOIN clean_extension ex ON ex.element = i.id
         LEFT JOIN clean_extension ccex ON ccex.element = cc.id
         LEFT JOIN clean_codeable_concept_coding cccc ON cccc.codeable_concept = cc.id;

CREATE UNIQUE INDEX idx_identifier_view_id ON identifier_view (id);

CREATE MATERIALIZED VIEW human_name_view AS
SELECT hn.id AS id,
       JSONB_BUILD_OBJECT(
               'id', hn.id,
               'extension', ce.extension,
               'use', use,
               'text', text,
               'family', family,
               'given', given,
               'prefix', prefix,
               'suffix', suffix,
               'period', JSONB_BUILD_OBJECT(
                       'start', period_start,
                       'end', period_end
                         )
       )        human_name
FROM human_name hn
         LEFT JOIN clean_extension ce ON ce.element = hn.id;

CREATE UNIQUE INDEX idx_human_name_view_id ON human_name_view (id);

CREATE MATERIALIZED VIEW contact_point_view AS
SELECT cp.id AS id,
       JSONB_BUILD_OBJECT(
               'id', cp.id,
               'extension', ce.extension,
               'system', system,
               'value', value,
               'use', use,
               'rank', rank,
               'period', JSONB_BUILD_OBJECT(
                       'start', period_start,
                       'end', period_end
                         )
       )     AS contact_point
FROM contact_point cp
         LEFT JOIN clean_extension ce ON ce.element = cp.id;

CREATE UNIQUE INDEX idx_contact_point_view_id ON contact_point_view (id);

CREATE MATERIALIZED VIEW attachment_view AS
SELECT a.id AS id,
       JSONB_BUILD_OBJECT(
               'id', a.id,
               'extension', ce.extension,
               'contentType', content_type,
               'language', language,
               'data', ENCODE(data, 'base64'),
               'url', url,
               'size', size,
               'hash', ENCODE(hash, 'base64'),
               'title', title,
               'creation', creation
       )    AS attachment
FROM attachment a
         LEFT JOIN clean_extension ce ON ce.element = a.id;

CREATE UNIQUE INDEX idx_attachment_view_id ON attachment_view (id);

CREATE MATERIALIZED VIEW address_view AS
SELECT a.id AS id,
       JSONB_BUILD_OBJECT(
               'id', a.id,
               'extension', ce.extension,
               'use', use,
               'type', type,
               'text', text,
               'line', TO_JSONB(line),
               'city', city,
               'district', district,
               'state', state,
               'postalCode', postal_code,
               'country', country,
               'period', JSONB_BUILD_OBJECT(
                       'start', period_start,
                       'end', period_end
                         )
       )    AS address
FROM address a
         LEFT JOIN clean_extension ce ON ce.element = a.id;

CREATE UNIQUE INDEX idx_address_view_id ON address_view (id);

CREATE MATERIALIZED VIEW modifier_extension_nested AS
WITH RECURSIVE
    extension_tree AS (
        -- Base case: all extensions
        SELECT e.id,
               e.uri,
               e.value,
               e.id AS root_id
        FROM extension e

        UNION ALL

        -- Recursive step: attach children
        SELECT c.id,
               c.uri,
               c.value,
               t.root_id
        FROM extension_tree t
                 JOIN element_extension ee ON ee.element = t.id
                 JOIN extension c ON c.id = ee.extension),
    nested_extension AS (
        -- Build JSON object for each extension with immediate children
        SELECT t.id,
               JSONB_BUILD_OBJECT(
                       'id', t.id,
                       'uri', t.uri,
                       'value', t.value,
                       'extension', COALESCE(
                               (SELECT JSONB_AGG(child_json)
                                FROM (SELECT JSONB_BUILD_OBJECT(
                                                     'id', c.id,
                                                     'uri', c.uri,
                                                     'value', c.value,
                                                     'extension', '[]'::jsonb
                                             ) AS child_json
                                      FROM element_extension ee
                                               JOIN extension c ON c.id = ee.extension
                                      WHERE ee.element = t.id) sub
                                WHERE child_json IS NOT NULL),
                               '[]'::jsonb
                                    )
               ) AS json
        FROM extension t)
SELECT b.id AS id,
       COALESCE(
                       JSONB_AGG(n.json ORDER BY n.id) FILTER (WHERE n.json IS NOT NULL),
                       '[]'::jsonb
       )    AS modifier_extension
FROM backbone_element b
         LEFT JOIN backbone_element_modifier_extension bex
                   ON bex.backbone_element = b.id
         LEFT JOIN nested_extension n
                   ON n.id = bex.modifier_extension
GROUP BY b.id;

CREATE UNIQUE INDEX idx_modifier_extension_nested_id ON modifier_extension_nested (id);

CREATE MATERIALIZED VIEW relationship_view AS
SELECT c.id                AS contact,
       JSONB_BUILD_ARRAY() AS relationship
FROM contact c
         LEFT JOIN contact_relationship cr ON cr.contact = c.id
WHERE cr.relationship IS NULL
UNION ALL
SELECT c.id AS id,
       JSONB_AGG(TO_JSONB(r.*))
FROM contact c
         LEFT JOIN contact_relationship cr ON cr.contact = c.id
         LEFT JOIN codeable_concept r ON cr.relationship = r.id
WHERE cr.relationship IS NOT NULL
GROUP BY c.id;

CREATE UNIQUE INDEX idx_relationship_view_id ON relationship_view (contact);

CREATE MATERIALIZED VIEW reference_view AS
SELECT r.id AS id,
       JSONB_BUILD_OBJECT(
               'id', r.id,
               'extension', ce.extension,
               'reference', reference,
               'type', type,
               'identifier', i.identifier,
               'display', display
       )    AS ref
FROM reference r
         LEFT JOIN clean_extension ce ON ce.element = r.id
         LEFT JOIN identifier_view i ON r.identifier = i.id;

CREATE UNIQUE INDEX idx_reference_view_id ON reference_view (id);

CREATE MATERIALIZED VIEW contact_contact_point_view AS
SELECT c.id                AS contact,
       JSONB_BUILD_ARRAY() AS cotnact_point
FROM contact c
         LEFT JOIN contact_contact_point ccp ON ccp.contact = c.id
WHERE ccp.contact_point IS NULL
UNION ALL
SELECT c.id                        AS contact,
       JSONB_AGG(cp.contact_point) AS contact_point
FROM contact c
         LEFT JOIN contact_contact_point ccp ON ccp.contact = c.id
         LEFT JOIN contact_point_view cp ON ccp.contact_point = cp.id
WHERE ccp.contact_point IS NOT NULL
GROUP BY c.id;

CREATE UNIQUE INDEX idx_contact_contact_point_view_contact ON contact_contact_point_view (contact);

CREATE MATERIALIZED VIEW contact_view AS
SELECT c.id AS id,
       JSONB_BUILD_OBJECT(
               'id', c.id,
               'extension', ce.extension,
               'modifierExtension', me.modifier_extension,
               'relationship', r.relationship,
               'name', hn.human_name,
               'telecom', cp.cotnact_point,
               'address', a.address,
               'gender', gender,
               'organization', ref.ref,
               'period', JSONB_BUILD_OBJECT(
                       'start', c.period_start,
                       'end', c.period_end
                         )
       )    AS contact
FROM contact c
         LEFT JOIN clean_extension ce ON ce.element = c.id
         LEFT JOIN modifier_extension_nested me ON me.id = c.id
         LEFT JOIN relationship_view r ON r.contact = c.id
         LEFT JOIN human_name_view hn ON hn.id = c.name
         LEFT JOIN contact_contact_point_view cp ON cp.contact = c.id
         LEFT JOIN address_view a ON a.id = c.address
         LEFT JOIN reference_view ref ON ref.id = c.organization;

CREATE UNIQUE INDEX idx_contact_view_id ON contact_view (id);

CREATE MATERIALIZED VIEW communication_view AS
SELECT c.id AS id,
       JSONB_BUILD_OBJECT(
               'id', c.id,
               'extension', ce.extension,
               'modifierExtension', me.modifier_extension,
               'language', language,
               'preferred', preferred
       )    AS communication
FROM communication c
         LEFT JOIN clean_extension ce ON ce.element = c.id
         LEFT JOIN modifier_extension_nested me ON me.id = c.id;

CREATE UNIQUE INDEX idx_communication_view_id ON communication_view (id);

CREATE MATERIALIZED VIEW link_view AS
SELECT l.id,
       JSONB_BUILD_OBJECT(
               'id', l.id,
               'extension', ex.extension,
               'modifierExtension', me.modifier_extension,
               'other', r.ref,
               'type', type
       ) AS link
FROM patient_link l
         LEFT JOIN reference_view r ON r.id = l.other
         LEFT JOIN clean_extension ex ON ex.element = l.id
         LEFT JOIN modifier_extension_nested me ON me.id = l.id;

CREATE UNIQUE INDEX idx_link_view_id ON link_view (id);

CREATE MATERIALIZED VIEW meta_security_view AS
SELECT m.id                AS meta,
       JSONB_BUILD_ARRAY() AS security
FROM meta m
         LEFT JOIN meta_security ms ON ms.meta = m.id
WHERE ms.security IS NULL
UNION ALL
SELECT m.id                     AS meta,
       JSONB_AGG(TO_JSONB(c.*)) AS security
FROM meta m
         LEFT JOIN meta_security ms ON ms.meta = m.id
         LEFT JOIN coding c ON c.id = ms.security
WHERE ms.security IS NOT NULL
GROUP BY m.id;

CREATE UNIQUE INDEX idx_meta_security_view ON meta_security_view (meta);

CREATE MATERIALIZED VIEW meta_tag_view AS
SELECT m.id                AS meta,
       JSONB_BUILD_ARRAY() AS tag
FROM meta m
         LEFT JOIN meta_tag mt ON mt.meta = m.id
WHERE mt.tag IS NULL
UNION ALL
SELECT m.id                     AS meta,
       JSONB_AGG(TO_JSONB(c.*)) AS tag
FROM meta m
         LEFT JOIN meta_tag mt ON mt.meta = m.id
         LEFT JOIN coding c ON c.id = mt.tag
WHERE mt.tag IS NOT NULL
GROUP BY m.id;

CREATE UNIQUE INDEX idx_meta_tag_view ON meta_tag_view (meta);

CREATE MATERIALIZED VIEW meta_view AS
SELECT m.id AS id,
       JSONB_BUILD_OBJECT(
               'id', m.id,
               'extension', ex.extension,
               'versionId', m.version,
               'lastUpdated', m.last_updated,
               'source', m.source,
               'profile', m.profile,
               'security', sec.security,
               'tag', tag.tag
       )    AS meta
FROM meta m
         LEFT JOIN meta_security_view sec ON sec.meta = m.id
         LEFT JOIN meta_tag_view tag ON tag.meta = m.id
         LEFT JOIN clean_extension ex ON ex.element = m.id;

CREATE UNIQUE INDEX idx_meta_view_id ON meta_view (id);

CREATE MATERIALIZED VIEW domain_resource_contained_view AS
WITH RECURSIVE resource_tree AS (
    -- Base case: start with all domain_resources
    SELECT dr.id      AS root_id,
           dr.id      AS id,
           dr.text,
           NULL::uuid AS parent_id
    FROM domain_resource dr

    UNION ALL

    -- Recursive step: add contained resources
    SELECT t.root_id,
           c.contained       AS id,
           NULL::uuid        AS text,
           c.domain_resource AS parent_id
    FROM resource_tree t
             JOIN domain_resource_contained c
                  ON t.id = c.domain_resource)
   , json_tree AS (
    -- Build JSON objects for each resource
    SELECT t.root_id,
           t.id,
           JSONB_BUILD_OBJECT(
                   'id', t.id,
                   'text', t.text,
                   'contained', '[]'::jsonb
           ) AS json_obj,
           t.parent_id
    FROM resource_tree t)
   , aggregated AS (
    -- Aggregate contained JSONs under their parents
    SELECT p.root_id,
           p.id,
           CASE
               WHEN COUNT(c.json_obj) > 0
                   THEN JSONB_SET(
                       p.json_obj,
                       '{contained}',
                       JSONB_AGG(c.json_obj)
                        )
               ELSE p.json_obj
               END AS json_obj,
           p.parent_id
    FROM json_tree p
             LEFT JOIN json_tree c
                       ON p.id = c.parent_id
    GROUP BY p.root_id, p.id, p.json_obj, p.parent_id)
SELECT root_id AS domain_resource, json_obj AS contained
FROM aggregated
WHERE parent_id IS NULL;

CREATE UNIQUE INDEX idx_domain_resource_contained_view_id ON domain_resource_contained_view (domain_resource);

CREATE MATERIALIZED VIEW narrative_view AS
SELECT n.id,
       JSONB_BUILD_OBJECT(
               'id', n.id,
               'extension', ex.extension,
               'status', n.status,
               'div', n.div
       ) AS narrative
FROM narrative n
         LEFT JOIN clean_extension ex ON ex.element = n.id;

CREATE UNIQUE INDEX idx_narrative_view_id ON narrative_view (id);

CREATE MATERIALIZED VIEW domain_resource_modifier_extension_view AS
WITH RECURSIVE
    extension_tree AS (
        -- base case: take all extensions directly linked to a domain_resource
        SELECT e.id,
               e.uri,
               e.value,
               e.id AS root_id
        FROM domain_resource_extension dre
                 JOIN extension e ON dre.extension = e.id

        UNION ALL

        -- recursive case: get child extensions of the current extension
        SELECT c.id,
               c.uri,
               c.value,
               t.root_id
        FROM extension_tree t
                 JOIN element_extension ee ON ee.element = t.id
                 JOIN extension c ON c.id = ee.extension),
    json_tree AS (
        -- build JSON objects for each extension
        SELECT et.id,
               et.root_id,
               JSONB_BUILD_OBJECT(
                       'id', et.id,
                       'uri', et.uri,
                       'value', et.value,
                       'extensions', '[]'::jsonb
               ) AS node
        FROM extension_tree et),
    aggregated AS (
        -- attach children to their parents
        SELECT p.root_id,
               p.id,
               p.node || JSONB_BUILD_OBJECT(
                       'extensions',
                       COALESCE(JSONB_AGG(c.node) FILTER (WHERE c.id IS NOT NULL), '[]'::jsonb)
                         ) AS node
        FROM json_tree p
                 LEFT JOIN element_extension ee ON ee.element = p.id
                 LEFT JOIN json_tree c ON c.id = ee.extension
        GROUP BY p.root_id, p.id, p.node),
    root_nodes AS (
        -- only keep the top-level nodes (those directly attached to domain_resource)
        SELECT DISTINCT ON (a.id) a.root_id, a.node
        FROM aggregated a)
SELECT dr.id                                     AS domain_resource,
       COALESCE(JSONB_AGG(rn.node), '[]'::jsonb) AS modifier_extension
FROM domain_resource dr
         LEFT JOIN root_nodes rn
                   ON rn.root_id IN (SELECT extension FROM domain_resource_extension WHERE domain_resource = dr.id)
GROUP BY dr.id;

CREATE UNIQUE INDEX idx_domain_resource_modifier_extension_view_domain_resource ON domain_resource_modifier_extension_view (domain_resource);

CREATE MATERIALIZED VIEW clean_domain_resource_modifier_extension AS
SELECT dr.id               AS domain_resource,
       JSONB_BUILD_ARRAY() AS modifier_extension
FROM domain_resource dr
         LEFT JOIN domain_resource_modifier_extension drme ON dr.id = drme.domain_resource
WHERE drme.modifier_extension IS NULL
UNION ALL
SELECT dr.domain_resource    AS domain_resource,
       dr.modifier_extension AS modifier_extension
FROM domain_resource_modifier_extension_view dr
         LEFT JOIN domain_resource_modifier_extension drme ON drme.domain_resource = dr.domain_resource
WHERE drme.modifier_extension IS NOT NULL;

CREATE UNIQUE INDEX idx_clean_domain_resource_modifier_extension ON clean_domain_resource_modifier_extension (domain_resource);

CREATE MATERIALIZED VIEW patient_identifier_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS identifier
FROM patient p
         LEFT JOIN patient_identifier pi ON p.id = pi.patient
WHERE pi.identifier IS NULL
UNION ALL
SELECT p.id                    AS patient,
       JSONB_AGG(i.identifier) AS identifier
FROM patient p
         LEFT JOIN patient_identifier pi ON p.id = pi.patient
         LEFT JOIN identifier_view i ON i.id = pi.identifier
WHERE pi.identifier IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_identifier_view_patient ON patient_identifier_view (patient);

CREATE MATERIALIZED VIEW patient_name_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS human_name
FROM patient p
         LEFT JOIN patient_name pn ON p.id = pn.patient
WHERE pn.name IS NULL
UNION ALL
SELECT p.id                    AS patient,
       JSONB_AGG(n.human_name) AS humna_name
FROM patient p
         LEFT JOIN patient_name pn ON p.id = pn.patient
         LEFT JOIN human_name_view n ON n.id = pn.name
WHERE pn.name IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_name_view_patient ON patient_name_view (patient);

CREATE MATERIALIZED VIEW patient_contact_point_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS contact_point
FROM patient p
         LEFT JOIN patient_telecom pt ON p.id = pt.patient
WHERE pt.telecom IS NULL
UNION ALL
SELECT p.id                        AS patient,
       JSONB_AGG(cp.contact_point) AS contact_point
FROM patient p
         LEFT JOIN patient_telecom pt ON p.id = pt.patient
         LEFT JOIN contact_point_view cp ON cp.id = pt.telecom
WHERE pt.telecom IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_contact_point_view_patient ON patient_contact_point_view (patient);

CREATE MATERIALIZED VIEW patient_address_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS address
FROM patient p
         LEFT JOIN patient_address pa ON p.id = pa.patient
WHERE pa.address IS NULL
UNION ALL
SELECT p.id                 AS patient,
       JSONB_AGG(a.address) AS address
FROM patient p
         LEFT JOIN patient_address pa ON p.id = pa.patient
         LEFT JOIN address_view a ON a.id = pa.address
WHERE pa.address IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_address_view_patient ON patient_address_view (patient);

CREATE MATERIALIZED VIEW patient_photo_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS photo
FROM patient p
         LEFT JOIN patient_photo pp ON p.id = pp.patient
WHERE pp.photo IS NULL
UNION ALL
SELECT p.id                    AS patient,
       JSONB_AGG(a.attachment) AS photo
FROM patient p
         LEFT JOIN patient_photo pp ON p.id = pp.patient
         LEFT JOIN attachment_view a ON a.id = pp.photo
WHERE pp.photo IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_photo_view_patient ON patient_photo_view (patient);

CREATE MATERIALIZED VIEW patient_contact_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS contact
FROM patient p
         LEFT JOIN patient_contact pc ON p.id = pc.patient
WHERE pc.contact IS NULL
UNION ALL
SELECT p.id                 AS patient,
       JSONB_AGG(c.contact) AS contact
FROM patient p
         LEFT JOIN patient_contact pc ON p.id = pc.patient
         LEFT JOIN contact_view c ON c.id = pc.contact
WHERE pc.contact IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_contact_view_patient ON patient_contact_view (patient);

CREATE MATERIALIZED VIEW patient_communication_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS communication
FROM patient p
         LEFT JOIN patient_communication pc ON p.id = pc.patient
WHERE pc.communication IS NULL
UNION ALL
SELECT p.id                       AS patient,
       JSONB_AGG(c.communication) AS communication
FROM patient p
         LEFT JOIN patient_communication pc ON p.id = pc.patient
         LEFT JOIN communication_view c ON c.id = pc.communication
WHERE pc.communication IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_communication_view_patient ON patient_communication_view (patient);

CREATE MATERIALIZED VIEW patient_link_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS link
FROM patient p
         LEFT JOIN patient_link pl ON p.id = pl.patient
WHERE pl.id IS NULL
UNION ALL
SELECT p.id              AS patient,
       JSONB_AGG(l.link) AS communication
FROM patient p
         LEFT JOIN patient_link pl ON p.id = pl.patient
         LEFT JOIN link_view l ON l.id = pl.id
WHERE pl.id IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_link_view_patient ON patient_link_view (patient);

CREATE MATERIALIZED VIEW patient_general_practitioner_view AS
SELECT p.id                AS patient,
       JSONB_BUILD_ARRAY() AS general_practitioner
FROM patient p
         LEFT JOIN patient_general_practitioner pgp ON p.id = pgp.patient
WHERE pgp.general_practitioner IS NULL
UNION ALL
SELECT p.id              AS patient,
       JSONB_AGG(gp.ref) AS general_practitioner
FROM patient p
         LEFT JOIN patient_general_practitioner pgp ON p.id = pgp.patient
         LEFT JOIN reference_view gp ON gp.id = pgp.general_practitioner
WHERE pgp.general_practitioner IS NOT NULL
GROUP BY p.id;

CREATE UNIQUE INDEX idx_patient_general_practitioner_view_patient ON patient_general_practitioner_view (patient);