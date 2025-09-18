CREATE OR REPLACE FUNCTION public.get_patient(patient_id UUID)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_patient JSONB;
BEGIN
    BEGIN
        SELECT JSONB_BUILD_OBJECT(
                   -- resource
                       'id', p.id,
                       'meta', m.meta,
                       'implicitRules', r.implicit_rules,
                       'language', r.language,
                   -- domain_resource
                       'text', n.narrative,
                       'contained', drc.contained,
                       'extension', ce.extension,
                       'modifierExtension', rmen.modifier_extension,
                   -- patient,
                       'identifier', i.identifier,
                       'active', p.active,
                       'name', name.human_name,
                       'telecom', tel.contact_point,
                       'birthDate', p.birthdate,
                       'deceased', JSONB_BUILD_OBJECT(
                               'deceasedBoolean', p.deceased,
                               'deceasedDateTime', p.deceased_date_time
                                   ),
                       'address', add.address,
                       'marital_status', JSONB_BUILD_OBJECT(
                               'id', p.marital_status,
                               'extension', mse.extension,
                               'coding', msc.coding,
                               'text', ms.text
                                         ),
                       'multipleBirth', JSONB_BUILD_OBJECT(
                               'multipleBirthBoolean', p.multiple_birth,
                               'multipleBirthInteger', p.multiple_birth_integer
                                        ),
                       'photo', photo.photo,
                       'contact', contact.contact,
                       'communication', com.communication,
                       'generalPractitioner', '',
                       'managingOrganization', org.ref,
                       'link', link.link
               )
        INTO v_patient
        FROM patient p
                 LEFT JOIN resource r ON r.id = p.id
                 LEFT JOIN meta_view m ON m.id = r.meta
                 LEFT JOIN domain_resource dr ON dr.id = p.id
                 LEFT JOIN clean_resource_extension ce ON ce.resource = p.id
                 LEFT JOIN clean_domain_resource_modifier_extension rmen ON rmen.domain_resource = p.id
                 LEFT JOIN domain_resource_contained_view drc ON drc.domain_resource = p.id
                 LEFT JOIN narrative_view n ON dr.text = n.id
                 LEFT JOIN patient_identifier_view i ON i.patient = p.id
                 LEFT JOIN patient_name_view name ON name.patient = p.id
                 LEFT JOIN patient_contact_point_view tel ON tel.patient = p.id
                 LEFT JOIN patient_address_view add ON add.patient = p.id
                 LEFT JOIN clean_codeable_concept_coding msc
                           ON msc.codeable_concept = p.marital_status
                 LEFT JOIN codeable_concept ms ON ms.id = p.marital_status
                 LEFT JOIN clean_extension mse ON mse.element = p.marital_status
                 LEFT JOIN patient_photo_view photo ON photo.patient = p.id
                 LEFT JOIN patient_contact_view contact ON contact.patient = p.id
                 LEFT JOIN patient_communication_view com ON com.patient = p.id
                 LEFT JOIN reference_view org ON org.id = p.managing_organization
                 LEFT JOIN patient_link_view link ON link.patient = p.id
                 LEFT JOIN patient_general_practitioner_view pgp ON pgp.patient = p.id
        WHERE p.id = patient_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'Could not find patient %', patient_id;
    END;
    RETURN v_patient;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_patient(patient_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id                     UUID;
    v_meta                   JSONB;
    v_implicit_rules         TEXT;
    v_language               TEXT;
    v_text                   JSONB;
    v_extension              JSONB[];
    v_modifier_extension     JSONB[];
    v_identifier             JSONB[];
    v_active                 BOOLEAN;
    v_name                   JSONB[];
    v_telecom                JSONB[];
    v_gender                 GENDER;
    v_birthdate              FHIR_DATE;
    v_deceased_boolean       BOOLEAN;
    v_deceased_datetime      FHIR_DATETIME;
    v_address                JSONB[];
    v_marital_status         JSONB;
    v_multiple_birth_boolean BOOLEAN;
    v_multiple_birth_integer INTEGER;
    v_photo                  JSONB[];
    v_contact                JSONB[];
    v_communication          JSONB[];
    v_gp                     JSONB[];
    v_managing_organization  JSONB;
    v_link                   JSONB[];
    jsonb_iterator           JSONB;
    uuid_collector           UUID[];
    narrative_id             UUID;
    meta_id                  UUID;
    marital_status_id        UUID;
    managing_organization_id UUID;
BEGIN
    SELECT patient_data ->> 'id',
           patient_data -> 'meta',
           patient_data ->> 'implicitRules',
           patient_data ->> 'language',
           patient_data -> 'text',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'modifierExtension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'identifier')), ARRAY []::JSONB[]),
           (patient_data ->> 'active')::BOOLEAN,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'name')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'telecom')), ARRAY []::JSONB[]),
           (patient_data ->> 'gender')::GENDER,
           patient_data ->> 'birthDate',
           (patient_data #>> '{deceased,deceasedBoolean}')::BOOLEAN,
           patient_data #>> '{deceased,deceasedDateTime}',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'address')), ARRAY []::JSONB[]),
           patient_data -> 'maritalStatus',
           (patient_data #>> '{multipleBirth,multipleBirthBoolean}')::BOOLEAN,
           (patient_data #>> '{multipleBirth,multipleBirthInteger}')::INTEGER,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'photo')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'contact')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'communication')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'generalPractitioner')), ARRAY []::JSONB[]),
           patient_data -> 'managingOrganization',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(patient_data -> 'link')), ARRAY []::JSONB[])
    INTO v_id, v_meta, v_implicit_rules, v_language, v_extension, v_modifier_extension, v_identifier,
        v_active,
        v_name,
        v_telecom,
        v_gender,
        v_birthdate,
        v_deceased_boolean,
        v_deceased_datetime,
        v_address,
        v_marital_status,
        v_multiple_birth_boolean,
        v_multiple_birth_integer,
        v_photo,
        v_contact,
        v_communication,
        v_gp,
        v_managing_organization,
        v_link;

    IF v_meta IS NULL THEN
        meta_id := NULL;
    ELSE
        meta_id = fhir_internal.update_meta(v_meta);
    END IF;

    IF v_text IS NULL THEN
        narrative_id := NULL;
    ELSE
        narrative_id = fhir_internal.update_narrative(v_text);
    END IF;

    IF v_marital_status IS NULL THEN
        marital_status_id := NULL;
    ELSE
        marital_status_id = fhir_internal.update_codeable_concept(v_marital_status);
    END IF;

    IF v_managing_organization IS NULL THEN
        managing_organization_id := NULL;
    ELSE
        managing_organization_id = fhir_internal.update_reference(v_managing_organization);
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO resource (meta, implicit_rules, language)
        VALUES (meta_id, v_implicit_rules, v_language)
        RETURNING id INTO v_id;
        INSERT INTO domain_resource (id, text)
        VALUES (v_id, narrative_id);
        INSERT INTO patient (id, active, gender, birthdate, deceased, deceased_date_time, marital_status,
                             multiple_birth, multiple_birth_integer, managing_organization)
        VALUES (v_id, v_active, v_gender, v_birthdate, v_deceased_boolean, v_deceased_datetime,
                marital_status_id,
                v_multiple_birth_boolean, v_multiple_birth_integer,
                managing_organization_id);
    ELSE
        UPDATE resource
        SET meta           = meta_id,
            implicit_rules = v_implicit_rules,
            language       = v_language
        WHERE id = v_id;
        SELECT 2;
        UPDATE domain_resource
        SET text = narrative_id
        WHERE id = v_id;
        UPDATE patient
        SET active                 = v_active,
            gender                 = v_gender,
            birthdate              = v_birthdate,
            deceased               = v_deceased_boolean,
            deceased_date_time     = v_deceased_datetime,
            marital_status         = marital_status_id,
            multiple_birth         = v_multiple_birth_boolean,
            multiple_birth_integer = v_multiple_birth_integer,
            managing_organization  = managing_organization_id
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;
    INSERT INTO domain_resource_extension (domain_resource, extension)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_modifier_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;
    INSERT INTO domain_resource_modifier_extension (domain_resource, modifier_extension)
    SELECT v_id, UNNEST(uuid_collector);

    -- Skipping contained because it does not make much sense for a patient to contain another patient,
    -- and we have no other resources for now

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_identifier
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_identifier(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_identifier (patient, identifier)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_name
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_human_name(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_name (patient, name)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_telecom
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_contact_point(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_telecom (patient, telecom)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_address
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_address(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_address (patient, address)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_photo
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_attachment(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_photo (patient, photo)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_contact
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_contact(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_contact (patient, contact)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_communication
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_communication(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_communication (patient, communication)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];
    FOREACH jsonb_iterator IN ARRAY v_gp
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_reference(jsonb_iterator);
        END LOOP;
    INSERT INTO patient_general_practitioner (patient, general_practitioner)
    SELECT v_id, UNNEST(uuid_collector);

    FOREACH jsonb_iterator IN ARRAY v_link
        LOOP
            fhir_internal.update_link(jsonb_iterator, v_id);
        END LOOP;

    RETURN '00000000-0000-0000-0000-000000000000';
END;
$$;

CREATE TYPE SEARCH_OPERATOR AS ENUM ('AND', 'OR');

CREATE OR REPLACE FUNCTION public.search_patients(search_data JSONB)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_name      TEXT;
    v_birthdate TEXT;
    v_operator  SEARCH_OPERATOR;
    v_last_id   UUID;
    v_count     INTEGER;
    result      JSONB;
BEGIN
    SELECT search_data ->> 'name',
           search_data ->> 'birthdate',
           (search_data ->> 'lastId')::UUID,
           COALESCE((search_data ->> 'count')::INTEGER, 30),
           COALESCE((search_data ->> 'operator')::SEARCH_OPERATOR, 'AND'::SEARCH_OPERATOR)
    INTO v_name, v_birthdate, v_last_id, v_count, v_operator;

    IF v_count > 100 THEN
        v_count = 100;
    END IF;

    WITH res AS (SELECT p.id, hn.text AS name, p.birthdate, hn.period_start, hn.period_end
                 FROM patient p
                          LEFT JOIN patient_name pn ON p.id = pn.patient
                          LEFT JOIN human_name hn ON pn.name = hn.id
                 WHERE (
                     -- Neither birthdate nor name is set -> return all
                     (v_birthdate IS NULL AND v_name IS NULL)
                         OR
                         -- case: only name
                     (v_birthdate IS NULL AND v_name IS NOT NULL
                         AND hn.text LIKE '%' || v_name || '%')
                         OR
                         -- case: only birthdate
                     (v_name IS NULL AND v_birthdate IS NOT NULL
                         AND p.birthdate LIKE v_birthdate || '%')
                         OR
                         -- case: both given, operator = OR
                     (v_name IS NOT NULL AND v_birthdate IS NOT NULL AND v_operator = 'OR'
                         AND (p.birthdate LIKE v_birthdate || '%' OR hn.text LIKE '%' || v_name || '%'))
                         OR
                         -- case: both given, operator = AND
                     (v_name IS NOT NULL AND v_birthdate IS NOT NULL AND v_operator = 'AND'
                         AND (p.birthdate LIKE v_birthdate || '%' AND hn.text LIKE '%' || v_name || '%'))
                     )
                   AND (hn.period_start IS NULL OR hn.period_start <= NOW())
                   AND (hn.period_end IS NULL OR hn.period_end > NOW())
                   AND (v_last_id IS NULL OR v_last_id < p.id)
                 LIMIT v_count)
    SELECT JSONB_AGG(JSONB_BUILD_OBJECT(
            'id', id,
            'name', name,
            'birthdate', birthdate
                     ))
    INTO result
    FROM res;
    RETURN result;
END;
$$;
