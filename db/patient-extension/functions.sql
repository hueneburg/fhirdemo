CREATE OR REPLACE FUNCTION get_patient(patient_id uuid)
    RETURNS jsonb
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_patient jsonb;
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

CREATE OR REPLACE FUNCTION update_patient(patient_data jsonb)
    RETURNS uuid
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN '33333333-3333-3333-3333-333333333333';
END;
$$;

CREATE TYPE search_operator AS ENUM ('AND', 'OR');

CREATE OR REPLACE FUNCTION search_patients(search_data jsonb)
    RETURNS uuid[]
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_name      text;
    v_birthdate text;
    v_operator  search_operator;
    uuids       uuid[];
BEGIN
    SELECT search_data ->> 'name',
           search_data ->> 'birthdate',
           COALESCE((search_data ->> 'operator')::search_operator, 'AND'::search_operator)
    INTO v_name, v_birthdate, v_operator;

    IF v_birthdate IS NULL AND v_name IS NULL
    THEN
        RAISE EXCEPTION 'At least one of name or birthdate has to be set when searching';
    ELSIF v_birthdate IS NULL THEN
        SELECT ARRAY_AGG(pn.patient)
        INTO uuids
        FROM human_name hn
                 LEFT JOIN patient_name pn ON pn.name = hn.id
        WHERE hn.text LIKE '%' || v_name || '%';
    ELSIF v_name IS NULL THEN
        SELECT ARRAY_AGG(id)
        INTO uuids
        FROM patient
        WHERE birthdate LIKE v_birthdate || '%';
    ELSE
        IF v_operator = 'OR' THEN
            SELECT ARRAY_AGG(p.id)
            INTO uuids
            FROM patient p
                     LEFT JOIN patient_name pn ON pn.patient = p.id
                     LEFT JOIN human_name hn ON hn.id = pn.name
            WHERE p.birthdate LIKE v_birthdate || '%'
               OR hn.text LIKE '%' || v_name || '%';
        ELSIF v_operator = 'AND' THEN
            SELECT ARRAY_AGG(p.id)
            INTO uuids
            FROM patient p
                     LEFT JOIN patient_name pn ON pn.patient = p.id
                     LEFT JOIN human_name hn ON hn.id = pn.name
            WHERE p.birthdate LIKE v_birthdate || '%'
              AND hn.text LIKE '%' || v_name || '%';
        END IF;
    END IF;
    RETURN COALESCE(uuids, ARRAY []::uuid[]);
END;
$$;

CREATE OR REPLACE FUNCTION get_all_patients()
    RETURNS uuid[]
    LANGUAGE sql
AS
$$
SELECT COALESCE(ARRAY_AGG(id), ARRAY [] ::uuid[])
FROM patient;
$$;
