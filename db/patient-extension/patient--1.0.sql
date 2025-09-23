CREATE OR REPLACE FUNCTION fhir.get_patient(patient_id UUID)
    RETURNS JSONB
    LANGUAGE sql
AS
$$
SELECT data
FROM fhir.patient
WHERE id = patient_id;
$$;

CREATE OR REPLACE FUNCTION fhir.upsert_patient(patient_data JSONB)
    RETURNS UUID
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_id        UUID;
    v_birthdate TEXT;
    v_name      JSONB;
    v_gender    fhir.GENDER;
    v_names     JSONB[];
    v_name_text TEXT;
    v_start     TIMESTAMPTZ;
    v_end       TIMESTAMPTZ;
BEGIN
    SELECT (patient_data ->> 'id')::UUID,
           patient_data ->> 'birthDate',
           patient_data -> 'name',
           CAST((patient_data ->> 'gender') AS fhir.GENDER)
    INTO v_id,
        v_birthdate,
        v_name,
        v_gender;

    IF v_id IS NULL THEN
        SELECT fhir.get_uuid()
        INTO v_id;

        SELECT JSONB_SET(patient_data, '{id}', TO_JSONB(v_id))
        INTO patient_data;
    END IF;

    INSERT INTO fhir.patient (id, data, birthdate, gender)
    VALUES (v_id, patient_data, v_birthdate, v_gender)
    ON CONFLICT (id) DO UPDATE SET data = patient_data, birthdate = v_birthdate, gender = v_gender;

    DELETE FROM fhir.patient_name WHERE patient = v_id;

    SELECT ARRAY_AGG(name)
    INTO v_names
    FROM JSONB_ARRAY_ELEMENTS(v_name) name;

    IF v_names IS NOT NULL THEN
        FOREACH v_name IN ARRAY v_names
            LOOP
                SELECT (v_name ->> 'text'),
                       (v_name #>> '{period,start}')::TIMESTAMPTZ,
                       (v_name #>> '{period,end}')::TIMESTAMPTZ
                INTO v_name_text, v_start, v_end;

                INSERT INTO fhir.patient_name (patient, patient_name, period_start, period_end)
                VALUES (v_id, v_name_text, v_start, v_end);
            END LOOP;
    END IF;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION fhir.get_uuid()
    RETURNS UUID
    LANGUAGE sql
AS
$$
INSERT INTO fhir.id_list DEFAULT
VALUES
RETURNING (id);
$$;

CREATE TYPE fhir.SEARCH_OPERATOR AS ENUM ('AND', 'OR');

CREATE OR REPLACE FUNCTION fhir.search_patients(search_data JSONB)
    RETURNS JSONB
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_name            TEXT;
    v_birthdate_from  TEXT;
    v_birthdate_until TEXT;
    v_operator        fhir.SEARCH_OPERATOR;
    v_iteration_key TEXT;
    v_last_id         UUID;
    v_count           INTEGER;
    v_gender          fhir.GENDER;
    result            JSONB;
BEGIN
    SELECT search_data ->> 'name',
           search_data ->> 'birthdateFrom',
           search_data ->> 'birthdateUntil',
           CAST((search_data ->> 'gender') AS fhir.GENDER),
           search_data ->> 'iterationKey',
           (search_data ->> 'lastId')::UUID,
           COALESCE((search_data ->> 'count')::INTEGER, 30),
           COALESCE((search_data ->> 'operator')::fhir.SEARCH_OPERATOR, 'AND'::fhir.SEARCH_OPERATOR)
    INTO v_name, v_birthdate_from, v_birthdate_until, v_gender, v_iteration_key, v_last_id, v_count, v_operator;

    IF v_count > 100 THEN
        v_count = 100;
    END IF;

    IF v_operator = 'OR'::fhir.SEARCH_OPERATOR THEN
        WITH d AS (SELECT JSONB_BUILD_OBJECT('id', p.id, 'birthdate', p.birthdate, 'name',
                                             JSONB_AGG(pn.patient_name), 'iterationKey',
                                             p.created_at, 'gender', p.gender::fhir.GENDER) data
                   FROM fhir.patient p
                            LEFT JOIN fhir.patient_name pn ON p.id = pn.patient
                   -- No search parameters at all
                   WHERE (v_name IS NULL
                       AND v_birthdate_from IS NULL
                       AND v_birthdate_until IS NULL
                       AND v_gender IS NULL
                       AND (pn.period_start IS NULL OR pn.period_start <= NOW())
                       AND (pn.period_end IS NULL OR pn.period_end > NOW()))
                      OR (((v_birthdate_from IS NOT NULL AND (
                       -- check if year is the same if only year is provided for the patient
                       (((LENGTH(p.birthdate) = 4 OR LENGTH(v_birthdate_from) = 4)
                           AND (SUBSTRING(v_birthdate_from FOR 4) <= SUBSTRING(p.birthdate FOR 4))) OR
                           -- check if year-month fits into the timeframe if only those are provided for the patient
                        ((LENGTH(p.birthdate) = 7 OR LENGTH(v_birthdate_from) = 7)
                            AND (SUBSTRING(v_birthdate_from FOR 7) <= SUBSTRING(p.birthdate FOR 7))) OR
                           -- check complete year-month-date
                        ((LENGTH(p.birthdate) = 10 OR LENGTH(v_birthdate_from) = 10)
                            AND (SUBSTRING(v_birthdate_from FOR 10) <= SUBSTRING(p.birthdate FOR 10))))))
                       AND (v_birthdate_until IS NOT NULL AND (
                           -- check if year is the same if only year is provided for the patient
                           (((LENGTH(p.birthdate) = 4 OR LENGTH(v_birthdate_until) = 4)
                               AND (SUBSTRING(v_birthdate_until FOR 4) >= SUBSTRING(p.birthdate FOR 4))) OR
                               -- check if year-month fits into the timeframe if only those are provided for the patient
                            ((LENGTH(p.birthdate) = 7 OR LENGTH(v_birthdate_until) = 7)
                                AND (SUBSTRING(v_birthdate_until FOR 7) >= SUBSTRING(p.birthdate FOR 7))) OR
                               -- check complete year-month-date
                            ((LENGTH(p.birthdate) = 10 OR LENGTH(v_birthdate_until) = 10)
                                AND (SUBSTRING(v_birthdate_until FOR 10) >= SUBSTRING(p.birthdate FOR 10)))))))
                       OR (v_gender IS NOT NULL AND p.gender = v_gender)
                       OR (v_name IS NOT NULL AND
                           (pn.patient_name IS NOT NULL AND (pn.patient_name LIKE '%' || COALESCE(v_name, '') || '%'))))
                       -- ignore names that are not in use right now
                       AND (pn.period_start IS NULL OR pn.period_start <= NOW())
                       AND (pn.period_end IS NULL OR pn.period_end > NOW())
                     -- pagination
                       AND (v_iteration_key IS NULL
                           OR v_iteration_key < p.created_at
                           OR (v_iteration_key = p.created_at
                               AND (v_last_id IS NULL
                                   OR v_last_id < p.id)))
                   GROUP BY p.id, p.created_at
                   ORDER BY p.created_at, p.id
                   LIMIT v_count)
        SELECT COALESCE(JSONB_AGG(d.data), '[]'::JSONB)
        INTO result
        FROM d;
    ELSIF v_operator = 'AND'::fhir.SEARCH_OPERATOR THEN
        WITH d AS (SELECT JSONB_BUILD_OBJECT('id', p.id, 'birthdate', p.birthdate, 'name',
                                             JSONB_AGG(pn.patient_name), 'iterationKey',
                                             p.created_at, 'gender', p.gender::fhir.GENDER) data
                   FROM fhir.patient p
                            LEFT JOIN fhir.patient_name pn ON p.id = pn.patient
                   WHERE (v_birthdate_from IS NULL OR (
                       -- check if year is the same if only year is provided for the patient
                       (((LENGTH(p.birthdate) = 4 OR LENGTH(v_birthdate_from) = 4)
                           AND (SUBSTRING(v_birthdate_from FOR 4) <= SUBSTRING(p.birthdate FOR 4))) OR
                           -- check if year-month fits into the timeframe if only those are provided for the patient
                        ((LENGTH(p.birthdate) = 7 OR LENGTH(v_birthdate_from) = 7)
                            AND (SUBSTRING(v_birthdate_from FOR 7) <= SUBSTRING(p.birthdate FOR 7))) OR
                           -- check complete year-month-date
                        ((LENGTH(p.birthdate) = 10 OR LENGTH(v_birthdate_from) = 10)
                            AND (SUBSTRING(v_birthdate_from FOR 10) <= SUBSTRING(p.birthdate FOR 10))))))
                     AND (v_birthdate_until IS NULL OR (
                       -- check if year is the same if only year is provided for the patient
                       (((LENGTH(p.birthdate) = 4 OR LENGTH(v_birthdate_until) = 4))
                           AND (SUBSTRING(v_birthdate_until FOR 4) >= SUBSTRING(p.birthdate FOR 4))) OR
                           -- check if year-month fits into the timeframe if only those are provided for the patient
                       ((LENGTH(p.birthdate) = 7 OR LENGTH(v_birthdate_until) = 7))
                           AND (SUBSTRING(v_birthdate_until FOR 7) >= SUBSTRING(p.birthdate FOR 7)) OR
                           -- check complete year-month-date
                       ((LENGTH(p.birthdate) = 10 OR LENGTH(v_birthdate_until) = 10)
                           AND (SUBSTRING(v_birthdate_until FOR 10) >= SUBSTRING(p.birthdate FOR 10)))))
                     AND (v_gender IS NULL OR p.gender = v_gender)
                     AND (v_name IS NULL OR
                          (pn.patient_name IS NOT NULL AND (pn.patient_name LIKE '%' || v_name || '%')))
                     -- ignore names that are not in use right now
                     AND (pn.period_start IS NULL OR pn.period_start <= NOW())
                     AND (pn.period_end IS NULL OR pn.period_end > NOW())
                     -- pagination
                     AND (v_iteration_key IS NULL
                       OR v_iteration_key < p.created_at
                       OR (v_iteration_key = p.created_at
                           AND (v_last_id IS NULL
                               OR v_last_id < p.id)))
                   GROUP BY p.id, p.created_at
                   ORDER BY p.created_at, p.id
                   LIMIT v_count)
        SELECT COALESCE(JSONB_AGG(d.data), '[]'::JSONB)
        INTO result
        FROM d;
    END IF;

    RETURN result;
END;
$$;
