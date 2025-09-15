CREATE SCHEMA IF NOT EXISTS fhir_internal;

CREATE OR REPLACE FUNCTION fhir_internal.update_extension(extension_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_data         JSONB;
    v_uri          TEXT;
    v_extension    JSONB[];
    v_internal_ext UUID[];
    it_elem        JSONB;
BEGIN
    v_internal_ext := ARRAY []::UUID[];

    SELECT (extension_data ->> 'id')::UUID,
           extension_data ->> 'url',
           extension_data -> 'value',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(extension_data -> 'extension')), ARRAY []::JSONB[])
    INTO v_id, v_uri, v_data, v_extension;
    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;

        INSERT INTO extension (id, uri, value) VALUES (v_id, v_uri, v_data);
    ELSE
        UPDATE extension
        SET uri   = v_uri,
            value = v_data
        WHERE id = v_id;
    END IF;

    FOREACH it_elem IN ARRAY v_extension
        LOOP
            v_internal_ext := v_internal_ext || fhir_internal.update_extension(it_elem);
        END LOOP;
    INSERT INTO element_extension(element, extension)
    SELECT v_id, UNNEST(v_internal_ext)
    -- combination already exists, skipping
    ON CONFLICT (element, extension) DO NOTHING;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_coding(coding JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id            UUID;
    v_extension     JSONB[];
    v_system        TEXT;
    v_version       TEXT;
    v_code          TEXT;
    v_display       TEXT;
    v_user_selected BOOLEAN;
    it_elem         JSONB;
    v_internal_ext  UUID[];
BEGIN
    SELECT coding ->> 'id',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(coding -> 'extension')), '[]'),
           coding ->> 'system',
           coding ->> 'version',
           coding ->> 'code',
           coding ->> 'display',
           (coding ->> 'userSelected')::BOOLEAN
    INTO v_id, v_extension, v_system, v_version,v_code, v_display, v_user_selected;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;

        INSERT INTO coding (id, system, code, display, user_selected)
        VALUES (v_id, v_system, v_code, v_display, v_user_selected);
    ELSE
        UPDATE coding
        SET system        = v_system,
            code          = v_code,
            display       = v_display,
            user_selected = v_user_selected
        WHERE id = v_id;
    END IF;

    FOREACH it_elem IN ARRAY v_extension
        LOOP
            v_internal_ext := v_internal_ext || fhir_internal.update_extension(it_elem);
        END LOOP;
    INSERT INTO element_extension(element, extension)
    SELECT v_id, UNNEST(v_internal_ext)
    -- combination already exists, skipping
    ON CONFLICT (element, extension) DO NOTHING;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_meta(meta_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id        UUID;
    v_version   TEXT;
    v_source    TEXT;
    v_profile   TEXT[];
    v_extension JSONB[];
    v_profile   TEXT[];
    v_security  JSONB[];
    v_tag       JSONB[];
    ext_it_elem JSONB;
    ext_ids     UUID[];
BEGIN
    ext_ids := ARRAY []::UUID[];

    SELECT (meta_data ->> 'id')::UUID,
           meta_data ->> 'versionId',
           meta_data ->> 'source',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS_TEXT(meta_data -> 'profile')), ARRAY []::TEXT[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(meta_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(meta_data -> 'security')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(meta_data -> 'tag')), ARRAY []::JSONB[])
    INTO v_id, v_version, v_source, v_profile, v_extension, v_security, v_tag;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;

        INSERT INTO meta (id, version, last_updated, source, profile)
        VALUES (v_id, v_version, NOW(), v_source, v_profile);
    ELSE
        UPDATE meta
        SET version      = v_version,
            last_updated = NOW(),
            source       = v_source,
            profile      = v_profile
        WHERE id = v_id
          AND (version IS DISTINCT FROM v_version OR
               source IS DISTINCT FROM v_source OR
               profile IS DISTINCT FROM v_profile);
    END IF;

    ext_ids := ARRAY []::UUID[];

    FOREACH ext_it_elem IN ARRAY v_extension
        LOOP
            ext_ids := ext_ids || fhir_internal.update_extension(ext_it_elem);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(ext_ids)
    -- ignore if the pairing already exists
    ON CONFLICT (element, extension) DO NOTHING;

    ext_ids := ARRAY []::UUID[];

    FOREACH ext_it_elem IN ARRAY v_security
        LOOP
            ext_ids := ext_ids || fhir_internal.update_coding(ext_it_elem);
        END LOOP;

    INSERT INTO meta_security (meta, security)
    SELECT v_id, UNNEST(ext_ids)
    ON CONFLICT (meta, security) DO NOTHING;

    ext_ids := ARRAY []::UUID[];

    FOREACH ext_it_elem IN ARRAY v_tag
        LOOP
            ext_ids := ext_ids || fhir_internal.update_coding(ext_it_elem);
        END LOOP;

    INSERT INTO meta_tag (meta, tag)
    SELECT v_id, UNNEST(ext_ids)
    ON CONFLICT (meta, tag) DO NOTHING;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_codeable_concept(cc_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_coding       JSONB[];
    v_text         TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT cc_data ->> 'id',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(cc_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(cc_data -> 'coding')), ARRAY []::JSONB[]),
           cc_data ->> 'text'
    INTO v_id, v_extension, v_coding, v_text;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO codeable_concept (id, text)
        VALUES (v_id, v_text);
    ELSE
        UPDATE codeable_concept
        SET text = v_text
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::JSONB[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    uuid_collector := ARRAY []::JSONB[];

    FOREACH jsonb_iterator IN ARRAY v_coding
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_coding(jsonb_iterator);
        END LOOP;

    INSERT INTO codeable_concept_coding (codeable_concept, coding)
    SELECT v_id, UNNEST(uuid_collector)
    ON CONFLICT DO NOTHING;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_reference(reference_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_reference    TEXT;
    v_type         TEXT;
    v_identifier   JSONB;
    v_display      TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
    identifier_id  UUID;
BEGIN
    SELECT reference_data ->> 'id',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(reference_data -> 'extension')), ARRAY []::JSONB[]),
           reference_data ->> 'reference',
           reference_data ->> 'type',
           reference_data -> 'identifier',
           reference_data ->> 'display'
    INTO v_id, v_extension, v_reference, v_type, v_identifier, v_display;

    IF v_identifier IS NULL THEN
        identifier_id := NULL;
    ELSE
        identifier_id := fhir_internal.update_identifier(v_identifier);
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO reference (id, reference, type, identifier, display)
        VALUES (v_id, v_reference, v_type, identifier_id, v_display);
    ELSE
        UPDATE reference
        SET reference  = v_reference,
            type       = v_type,
            identifier = identifier_id,
            display    = v_display
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_identifier(identifier_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_use          IDENTIFIER_USE;
    v_type         JSONB;
    v_system       TEXT;
    v_value        TEXT;
    v_period_start TEXT;
    v_period_end   TEXT;
    v_assigner     JSONB;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
    type_id        UUID;
    assigner_id    UUID;
BEGIN
    SELECT identifier_data ->> 'id',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(identifier_data -> 'extension')), ARRAY []::JSONB[]),
           identifier_data ->> 'use'::IDENTIFIER_USE,
           identifier_data -> 'type',
           identifier_data ->> 'system',
           identifier_data ->> 'value',
           (identifier_data #>> '{period,start}')::TIMESTAMPTZ,
           (identifier_data #>> '{period,end}')::TIMESTAMPTZ,
           identifier_data -> 'assigner'
    INTO v_id, v_use, v_type, v_extension, v_system, v_value, v_period_start, v_period_end, v_assigner;

    IF v_type IS NULL THEN
        type_id := NULL;
    ELSE
        type_id := fhir_internal.update_codeable_concept(v_type);
    END IF;

    IF v_assigner IS NULL THEN
        assigner_id := NULL;
    ELSE
        assigner_id := fhir_internal.update_reference(v_assigner);
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO identifier (id, use, type, system, value, period_start, period_end, assigner)
        VALUES (v_id,
                v_use,
                type_id,
                v_system,
                v_value,
                v_period_start,
                v_period_end,
                assigner_id);
    ELSE
        UPDATE identifier
        SET use          = v_use,
            type         = type_id,
            system       = v_system,
            value        = v_value,
            period_start = v_period_start,
            period_end   = v_period_end,
            assigner     = assigner_id
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_human_name(name_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_use          HUMAN_NAME_USE;
    v_text         TEXT;
    v_family       TEXT;
    v_given        TEXT[];
    v_prefix       TEXT[];
    v_suffix       TEXT[];
    v_period_start TEXT;
    v_period_end   TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT (name_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(name_data -> 'extension')), ARRAY []::JSONB[]),
           (name_data ->> 'use')::HUMAN_NAME_USE,
           name_data ->> 'text',
           name_data ->> 'family',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS_TEXT(name_data -> 'given')), ARRAY []::TEXT[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS_TEXT(name_data -> 'prefix')), ARRAY []::TEXT[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS_TEXT(name_data -> 'suffix')), ARRAY []::TEXT[]),
           (name_data #>> '{period,start}')::TIMESTAMPTZ,
           (name_data #>> '{period,end}')::TIMESTAMPTZ
    INTO v_id,
        v_extension,
        v_use,
        v_text,
        v_family,
        v_given,
        v_prefix,
        v_suffix,
        v_period_start,
        v_period_end;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO human_name (id, use, text, family, given, prefix, suffix, period_start, period_end)
        VALUES (v_id, v_use, v_text, v_family, v_given, v_prefix, v_suffix, v_period_start, v_period_end);
    ELSE
        UPDATE human_name
        SET use          = v_use,
            text         = v_text,
            family       = v_family,
            given        = v_given,
            prefix       = v_prefix,
            suffix       = v_suffix,
            period_start = v_period_start,
            period_end   = v_period_end
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_contact_point(cp_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_system       CONTACT_POINT_SYSTEM;
    v_value        TEXT;
    v_use          CONTACT_POINT_USE;
    v_rank         POSITIVE_INTEGER;
    v_period_start TEXT;
    v_period_end   TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT (cp_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(cp_data -> 'extension')), ARRAY []::JSONB[]),
           (cp_data ->> 'system')::CONTACT_POINT_SYSTEM,
           cp_data ->> 'value',
           (cp_data ->> 'use')::CONTACT_POINT_USE,
           (cp_data ->> 'rank')::POSITIVE_INTEGER,
           (cp_data #>> '{period,start}')::TIMESTAMPTZ,
           (cp_data #>> '{period,end}')::TIMESTAMPTZ
    INTO v_id, v_extension, v_system, v_value, v_use, v_rank, v_period_start, v_period_end;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO contact_point (id, system, value, use, rank, period_start, period_end)
        VALUES (v_id, v_system, v_value, v_use, v_rank, v_period_start, v_period_end);
    ELSE
        UPDATE contact_point
        SET system       = v_system,
            value        = v_value,
            use          = v_use,
            rank         = v_rank,
            period_start = v_period_start,
            period_end   = v_period_end
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_address(add_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_use          ADDRESS_USE;
    v_type         ADDRESS_TYPE;
    v_text         TEXT;
    v_line         TEXT[];
    v_city         TEXT;
    v_district     TEXT;
    v_state        TEXT;
    v_postal_code  TEXT;
    v_country      TEXT;
    v_period_start TEXT;
    v_period_end   TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT (add_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(add_data -> 'extension')), ARRAY []::JSONB[]),
           (add_data ->> 'use')::ADDRESS_USE,
           (add_data ->> 'type')::ADDRESS_TYPE,
           add_data ->> 'text',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS_TEXT(add_data -> 'line')), ARRAY []::TEXT[]),
           add_data ->> 'city',
           add_data ->> 'district',
           add_data ->> 'state',
           add_data ->> 'postalCode',
           add_data ->> 'country',
           (add_data #>> '{period,start}')::TIMESTAMPTZ,
           (add_data #>> '{period,end}')::TIMESTAMPTZ
    INTO v_id,
        v_extension,
        v_use,
        v_type,
        v_text,
        v_line,
        v_city,
        v_district,
        v_state,
        v_postal_code,
        v_country,
        v_period_start,
        v_period_end;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO address (id, use, type, text, line, city, district, state, postal_code, country, period_start,
                             period_end)
        VALUES (v_id, v_use, v_type, v_text, v_line, v_city, v_district, v_state, v_postal_code, v_country,
                v_period_start, v_period_end);
    ELSE
        UPDATE address
        SET use          = v_use,
            type         = v_type,
            text         = v_text,
            line         = v_line,
            city         = v_city,
            district     = v_district,
            state        = v_state,
            postal_code  = v_postal_code,
            country      = v_country,
            period_start = v_period_start,
            period_end   = v_period_end
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_attachment(att_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_content_type TEXT;
    v_language     TEXT;
    v_data         BYTEA;
    v_url          TEXT;
    v_size         UNSIGNED_INTEGER;
    v_hash         BYTEA;
    v_title        TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT (att_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(att_data -> 'extension')), ARRAY []::JSONB[]),
           att_data ->> 'contentType',
           att_data ->> 'language',
           DECODE(att_data ->> 'use', 'base64'),
           att_data ->> 'url',
           (att_data ->> 'size')::UNSIGNED_INTEGER,
           DECODE(att_data ->> 'hash', 'base64'),
           att_data ->> 'title',
           (att_data ->> 'size')::TIMESTAMPTZ
    INTO v_id,
        v_extension,
        v_content_type,
        v_language,
        v_data,
        v_url,
        v_size,
        v_hash,
        v_title;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO attachment (id, content_type, language, data, url, size, hash, title, creation)
        VALUES (v_id, v_content_type, v_language, v_data, v_url, v_size, v_hash, v_title, NOW());
    ELSE
        UPDATE attachment
        SET content_type = v_content_type,
            language     = v_language,
            data         = v_data,
            url          = v_url,
            size         = v_size,
            hash         = v_hash,
            title        = v_title
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_contact(con_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id                 UUID;
    v_extension          JSONB[];
    v_modifier_extension JSONB[];
    v_relationship       JSONB[];
    v_name               JSONB;
    v_telecom            JSONB[];
    v_address            JSONB;
    v_gender             GENDER;
    v_organization       JSONB;
    v_period_start       TIMESTAMPTZ;
    v_period_end         TIMESTAMPTZ;
    jsonb_iterator       JSONB;
    uuid_collector       UUID[];
    name_id              UUID;
    address_id           UUID;
    organization_id      UUID;
BEGIN
    SELECT (con_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(con_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(con_data -> 'modifierExtension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(con_data -> 'relationship')), ARRAY []::JSONB[]),
           con_data -> 'name',
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(con_data -> 'telecom')), ARRAY []::JSONB[]),
           con_data -> 'address',
           (con_data -> 'gender')::GENDER,
           con_data -> 'organization',
           (con_data #>> '{period,start}')::TIMESTAMPTZ,
           (con_data #>> '{period,end}')::TIMESTAMPTZ
    INTO v_id,
        v_extension,
        v_modifier_extension,
        v_modifier_extension,
        v_relationship,
        v_name,
        v_telecom,
        v_address,
        v_gender,
        v_organization,
        v_period_start,
        v_period_end;

    IF v_name IS NULL THEN
        name_id := NULL;
    ELSE
        name_id := fhir_internal.update_human_name(v_name);
    END IF;

    IF v_address IS NULL THEN
        address_id := NULL;
    ELSE
        address_id := fhir_internal.update_address(v_address);
    END IF;

    IF v_organization IS NULL THEN
        organization_id := NULL;
    ELSE
        organization_id := fhir_internal.update_reference(v_organization);
    END IF;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO backbone_element (id) VALUES (v_id);
        INSERT INTO contact (id, name, address, gender, organization, period_start, period_end)
        VALUES (v_id, name_id, address_id, v_gender,
                organization_id, v_period_start, v_period_end);
    ELSE
        UPDATE contact
        SET name         = name_id,
            address      = address_id,
            gender       = gender,
            organization = organization_id,
            period_start = v_period_start,
            period_end   = v_period_end
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO backbone_element_modifier_extension (backbone_element, modifier_extension)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_relationship
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_codeable_concept(jsonb_iterator);
        END LOOP;

    INSERT INTO contact_relationship (contact, relationship)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_telecom
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_contact_point(jsonb_iterator);
        END LOOP;

    INSERT INTO contact_contact_point (contact, contact_point)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_communication(com_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id                 UUID;
    v_extension          JSONB[];
    v_modifier_extension JSONB[];
    v_language           TEXT;
    v_preferred          BOOLEAN;
    jsonb_iterator       JSONB;
    uuid_collector       UUID[];
BEGIN
    SELECT (com_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(com_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(com_data -> 'modifierExtension')), ARRAY []::JSONB[]),
           com_data ->> 'language',
           (com_data ->> 'preferred')::BOOLEAN
    INTO v_id,
        v_extension,
        v_modifier_extension,
        v_language,
        v_preferred;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO backbone_element (id) VALUES (v_id);
        INSERT INTO communication (id, language, preferred)
        VALUES (v_id, v_language, v_preferred);
    ELSE
        UPDATE communication
        SET language  = v_language,
            preferred = v_preferred
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO backbone_element_modifier_extension (backbone_element, modifier_extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_link(link_data JSONB, patient_id UUID)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id                 UUID;
    v_extension          JSONB[];
    v_modifier_extension JSONB[];
    v_other              JSONB;
    v_type               LINK_TYPE;
    jsonb_iterator       JSONB;
    uuid_collector       UUID[];
BEGIN
    SELECT (link_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(link_data -> 'extension')), ARRAY []::JSONB[]),
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(link_data -> 'modifierExtension')), ARRAY []::JSONB[]),
           link_data -> 'other',
           (link_data ->> 'type')::LINK_TYPE
    INTO v_id,
        v_extension,
        v_modifier_extension,
        v_other,
        v_type;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO backbone_element (id) VALUES (v_id);
        INSERT INTO patient_link (id, patient, other, type)
        VALUES (v_id, patient_id, fhir_internal.update_reference(v_other), v_type);
    ELSE
        UPDATE patient_link
        -- Only allow updating the link type and nothing else
        SET type = v_type
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO backbone_element_modifier_extension (backbone_element, modifier_extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir_internal.update_narrative(nar_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id           UUID;
    v_extension    JSONB[];
    v_status       NARRATIVE_STATUS;
    v_div          TEXT;
    jsonb_iterator JSONB;
    uuid_collector UUID[];
BEGIN
    SELECT (nar_data ->> 'id')::UUID,
           COALESCE(ARRAY(SELECT JSONB_ARRAY_ELEMENTS(nar_data -> 'extension')), ARRAY []::JSONB[]),
           (nar_data ->> 'status')::NARRATIVE_STATUS,
           nar_data ->> 'div'
    INTO v_id,
        v_extension,
        v_status,
        v_div;

    IF v_id IS NULL THEN
        INSERT INTO element DEFAULT VALUES RETURNING id INTO v_id;
        INSERT INTO narrative (id, status, div)
        VALUES (v_id, v_status, v_div);
    ELSE
        UPDATE narrative
        SET status = v_status,
            div    = v_div
        WHERE id = v_id;
    END IF;

    uuid_collector := ARRAY []::UUID[];

    FOREACH jsonb_iterator IN ARRAY v_extension
        LOOP
            uuid_collector := uuid_collector || fhir_internal.update_extension(jsonb_iterator);
        END LOOP;

    INSERT INTO element_extension (element, extension)
    SELECT v_id, UNNEST(uuid_collector);

    RETURN v_id;
END;
$$;
