-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_000
-- ENGINE NAME: Education System Admission Ledger
-- ENGINE FUNCTION:
--   Constitutionally admits Omnex_System_Education as a sovereign
--   authority system under Omnex_System_Core. Declares existence,
--   scope, criticality, and readiness — no domain behavior.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_education IS
'Omnex System Education — sovereign education authority schema (ENGINE 000 admission only)';

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — admission uses Core record types only

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education System Admission Ledger
CREATE TABLE IF NOT EXISTS omnex_system_education.education_system_admission (
    admission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    system_code        text NOT NULL,
    system_name        text NOT NULL,
    category_code      text NOT NULL,
    schema_name        text NOT NULL,

    ownership_domain   text NOT NULL,
    criticality_level  text NOT NULL,
    operational_scope  text NOT NULL,

    status             text NOT NULL,
    admitted_at        timestamptz NOT NULL DEFAULT now(),

    payload            jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum           text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at         timestamptz NOT NULL DEFAULT now(),
    created_by         text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_education.education_system_admission IS
'ENGINE 000 — Immutable admission record declaring Omnex_System_Education as a lawful authority system';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_education_admission_identity'
    ) THEN
        ALTER TABLE omnex_system_education.education_system_admission
            ADD CONSTRAINT chk_education_admission_identity
            CHECK (
                system_code = 'OS_ED'
                AND category_code = 'OS_AUTH'
                AND schema_name = 'omnex_system_education'
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_education_admission_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.education_system_admission
            ADD CONSTRAINT chk_education_admission_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — admission is sovereign and non-dependent

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

CREATE OR REPLACE FUNCTION omnex_system_education.compute_and_validate_admission_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.system_code, '') ||
            coalesce(NEW.system_name, '') ||
            coalesce(NEW.category_code, '') ||
            coalesce(NEW.schema_name, '') ||
            coalesce(NEW.ownership_domain, '') ||
            coalesce(NEW.criticality_level, '') ||
            coalesce(NEW.operational_scope, '') ||
            coalesce(NEW.payload::text, '') ||
            coalesce(NEW.payload_schema_version::text, ''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.checksum <> computed THEN
        RAISE EXCEPTION
            'EDUCATION ADMISSION CHECKSUM VIOLATION: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_education_admission_checksum
ON omnex_system_education.education_system_admission;

CREATE TRIGGER trg_validate_education_admission_checksum
BEFORE INSERT
ON omnex_system_education.education_system_admission
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.compute_and_validate_admission_checksum();

CREATE OR REPLACE FUNCTION omnex_system_education.prevent_admission_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION SYSTEM ADMISSION IS IMMUTABLE — updates or deletes are forbidden';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_education_admission_mutation
ON omnex_system_education.education_system_admission;

CREATE TRIGGER trg_prevent_education_admission_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.education_system_admission
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_admission_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.education_system_admission
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_education_admission
ON omnex_system_education.education_system_admission;

CREATE POLICY deny_all_education_admission
ON omnex_system_education.education_system_admission
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_education_admission
ON omnex_system_education.education_system_admission IS
'Education system admission is governed exclusively by Omnex_System_Core';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_education_admission_system_code
ON omnex_system_education.education_system_admission (system_code);

CREATE INDEX IF NOT EXISTS idx_education_admission_status
ON omnex_system_education.education_system_admission (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_001
-- ENGINE NAME: Education Legal Instruments Registry
-- ENGINE FUNCTION:
--   Registers constitutions, acts, regulations, and statutory
--   instruments governing the education sector.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_education IS
'Omnex System Education — sovereign education authority schema';

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — legal instruments are data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Legal Instruments
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_legal_instrument (
    legal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_code text NOT NULL,
    legal_type text NOT NULL,           -- Constitution, Act, Regulation, Statutory Instrument
    title text NOT NULL,
    jurisdiction text NOT NULL,

    enacted_at date,
    effective_from date NOT NULL,
    effective_to date,

    status text NOT NULL,                -- Draft | Active | Repealed | Superseded

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_001'
);

COMMENT ON TABLE omnex_system_education.edu_legal_instrument IS
'Canonical registry of all legal instruments governing education';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_legal_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_legal_instrument
            ADD CONSTRAINT uq_edu_legal_code
            UNIQUE (legal_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_legal_effective_range'
    ) THEN
        ALTER TABLE omnex_system_education.edu_legal_instrument
            ADD CONSTRAINT chk_edu_legal_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_legal_status_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_legal_instrument
            ADD CONSTRAINT chk_edu_legal_status_nonempty
            CHECK (length(status) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — this is the root legal authority table for education

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of legal instruments (append-only law)
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_legal_instrument_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION LEGAL INSTRUMENT VIOLATION: records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_legal_instrument_mutation
ON omnex_system_education.edu_legal_instrument;

CREATE TRIGGER trg_prevent_legal_instrument_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_legal_instrument
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_legal_instrument_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_legal_instrument
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_legal_instrument
ON omnex_system_education.edu_legal_instrument;

CREATE POLICY deny_all_edu_legal_instrument
ON omnex_system_education.edu_legal_instrument
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_legal_instrument
ON omnex_system_education.edu_legal_instrument IS
'All access to education legal instruments is centrally governed';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_legal_code
ON omnex_system_education.edu_legal_instrument (legal_code);

CREATE INDEX IF NOT EXISTS idx_edu_legal_type
ON omnex_system_education.edu_legal_instrument (legal_type);

CREATE INDEX IF NOT EXISTS idx_edu_legal_status
ON omnex_system_education.edu_legal_instrument (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_002
-- ENGINE NAME: National Education Mandates Registry
-- ENGINE FUNCTION:
--   Captures executive and constitutional mandates directing
--   education obligations under established legal instruments.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — mandates are sovereign legal facts, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 National Education Mandates
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_mandate (
    mandate_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_id uuid NOT NULL,                     -- FK → edu_legal_instrument
    mandate_code text NOT NULL,
    mandate_description text NOT NULL,
    issuing_authority text NOT NULL,

    effective_from date NOT NULL,
    effective_to date,

    status text NOT NULL CHECK (
        status IN ('Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_002'
);

COMMENT ON TABLE omnex_system_education.edu_mandate IS
'Canonical registry of national education mandates derived from constitutional and statutory legal instruments';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_mandate_legal'
    ) THEN
        ALTER TABLE omnex_system_education.edu_mandate
            ADD CONSTRAINT fk_edu_mandate_legal
            FOREIGN KEY (legal_id)
            REFERENCES omnex_system_education.edu_legal_instrument (legal_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_mandate_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_mandate
            ADD CONSTRAINT uq_edu_mandate_code
            UNIQUE (mandate_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_mandate_effective_range'
    ) THEN
        ALTER TABLE omnex_system_education.edu_mandate
            ADD CONSTRAINT chk_edu_mandate_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Mandates are legally derived from Education Legal Instruments (ENGINE 001)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only sovereign mandate records
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_mandate_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION MANDATE VIOLATION: mandate records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_mandate_mutation
ON omnex_system_education.edu_mandate;

CREATE TRIGGER trg_prevent_edu_mandate_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_mandate
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_mandate_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_mandate
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_mandate
ON omnex_system_education.edu_mandate;

CREATE POLICY deny_all_edu_mandate
ON omnex_system_education.edu_mandate
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_mandate
ON omnex_system_education.edu_mandate IS
'Education mandates are governed centrally; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_mandate_code
ON omnex_system_education.edu_mandate (mandate_code);

CREATE INDEX IF NOT EXISTS idx_edu_mandate_legal
ON omnex_system_education.edu_mandate (legal_id);

CREATE INDEX IF NOT EXISTS idx_edu_mandate_status
ON omnex_system_education.edu_mandate (status);

CREATE INDEX IF NOT EXISTS idx_edu_mandate_effective
ON omnex_system_education.edu_mandate
USING btree (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 003
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_003
-- ENGINE NAME: Education Policies Registry
-- ENGINE FUNCTION:
--   Defines binding national and sector-wide education policies
--   derived from legal instruments and national mandates.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — policies are sovereign legal constructs

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Policies
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_policy (
    policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_id uuid NOT NULL,        -- FK → edu_legal_instrument
    mandate_id uuid NOT NULL,      -- FK → edu_mandate

    policy_code text NOT NULL,
    policy_name text NOT NULL,
    policy_scope text NOT NULL,    -- NATIONAL, BASIC, TVET, HIGHER, SPECIAL, etc.

    effective_from date NOT NULL,
    effective_to date,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_003'
);

COMMENT ON TABLE omnex_system_education.edu_policy IS
'Canonical registry of binding education policies derived from legal instruments and national mandates';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_policy_legal'
    ) THEN
        ALTER TABLE omnex_system_education.edu_policy
            ADD CONSTRAINT fk_edu_policy_legal
            FOREIGN KEY (legal_id)
            REFERENCES omnex_system_education.edu_legal_instrument (legal_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_policy_mandate'
    ) THEN
        ALTER TABLE omnex_system_education.edu_policy
            ADD CONSTRAINT fk_edu_policy_mandate
            FOREIGN KEY (mandate_id)
            REFERENCES omnex_system_education.edu_mandate (mandate_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_policy_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_policy
            ADD CONSTRAINT uq_edu_policy_code
            UNIQUE (policy_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_policy_effective_range'
    ) THEN
        ALTER TABLE omnex_system_education.edu_policy
            ADD CONSTRAINT chk_edu_policy_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Policies are legally derived from:
--  • Education Legal Instruments (ENGINE 001)
--  • National Education Mandates (ENGINE 002)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only policy records
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_policy_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION POLICY VIOLATION: policy records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_policy_mutation
ON omnex_system_education.edu_policy;

CREATE TRIGGER trg_prevent_edu_policy_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_policy
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_policy_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_policy
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_policy
ON omnex_system_education.edu_policy;

CREATE POLICY deny_all_edu_policy
ON omnex_system_education.edu_policy
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_policy
ON omnex_system_education.edu_policy IS
'Education policies are governed centrally; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_policy_code
ON omnex_system_education.edu_policy (policy_code);

CREATE INDEX IF NOT EXISTS idx_edu_policy_legal
ON omnex_system_education.edu_policy (legal_id);

CREATE INDEX IF NOT EXISTS idx_edu_policy_mandate
ON omnex_system_education.edu_policy (mandate_id);

CREATE INDEX IF NOT EXISTS idx_edu_policy_status
ON omnex_system_education.edu_policy (status);

CREATE INDEX IF NOT EXISTS idx_edu_policy_effective
ON omnex_system_education.edu_policy
USING btree (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 004
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_004
-- ENGINE NAME: Sectoral & Strategic Education Plans
-- ENGINE FUNCTION:
--   Stores medium- and long-term education sector plans
--   derived strictly from approved education policies.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — plans are governed legal constructs

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Sectoral & Strategic Education Plans
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_sector_plan (
    plan_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,   -- FK → edu_policy

    plan_code text NOT NULL,
    plan_name text NOT NULL,

    plan_horizon text NOT NULL,  -- SHORT, MEDIUM, LONG
    start_year integer NOT NULL,
    end_year integer NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Expired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_004'
);

COMMENT ON TABLE omnex_system_education.edu_sector_plan IS
'Canonical registry of education sector and strategic plans derived from approved education policies';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_sector_plan_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_sector_plan
            ADD CONSTRAINT fk_edu_sector_plan_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_sector_plan_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_sector_plan
            ADD CONSTRAINT uq_edu_sector_plan_code
            UNIQUE (plan_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_sector_plan_years'
    ) THEN
        ALTER TABLE omnex_system_education.edu_sector_plan
            ADD CONSTRAINT chk_edu_sector_plan_years
            CHECK (
                end_year > start_year
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Plans are strictly derived from:
--  • Education Policies (ENGINE 003)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only plan records
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_sector_plan_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION PLAN VIOLATION: sector plan records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_sector_plan_mutation
ON omnex_system_education.edu_sector_plan;

CREATE TRIGGER trg_prevent_edu_sector_plan_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_sector_plan
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_sector_plan_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_sector_plan
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_sector_plan
ON omnex_system_education.edu_sector_plan;

CREATE POLICY deny_all_edu_sector_plan
ON omnex_system_education.edu_sector_plan
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_sector_plan
ON omnex_system_education.edu_sector_plan IS
'Education sector plans are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_sector_plan_code
ON omnex_system_education.edu_sector_plan (plan_code);

CREATE INDEX IF NOT EXISTS idx_edu_sector_plan_policy
ON omnex_system_education.edu_sector_plan (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_sector_plan_status
ON omnex_system_education.edu_sector_plan (status);

CREATE INDEX IF NOT EXISTS idx_edu_sector_plan_years
ON omnex_system_education.edu_sector_plan
USING btree (start_year, end_year);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 005
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_005
-- ENGINE NAME: Education Programs (Legal Constructs)
-- ENGINE FUNCTION:
--   Declares education programs constituted by law or policy (non-operational),
--   derived from approved policies and sector plans.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — programs are sovereign legal constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Programs (Legal Constructs)
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_program (
    program_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,     -- FK → edu_policy (ENGINE 003)
    plan_id   uuid NOT NULL,     -- FK → edu_sector_plan (ENGINE 004)

    program_code text NOT NULL,
    program_name text NOT NULL,

    legal_basis text NOT NULL,   -- human-citable legal reference (act/section/policy clause)

    effective_from date NOT NULL,
    effective_to   date,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_005'
);

COMMENT ON TABLE omnex_system_education.edu_program IS
'Canonical registry of education programs as legal constructs (non-operational), derived from approved education policies and sector plans';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_program_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_program
            ADD CONSTRAINT fk_edu_program_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_program_plan'
    ) THEN
        ALTER TABLE omnex_system_education.edu_program
            ADD CONSTRAINT fk_edu_program_plan
            FOREIGN KEY (plan_id)
            REFERENCES omnex_system_education.edu_sector_plan (plan_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_program_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_program
            ADD CONSTRAINT uq_edu_program_code
            UNIQUE (program_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_program_effective_range'
    ) THEN
        ALTER TABLE omnex_system_education.edu_program
            ADD CONSTRAINT chk_edu_program_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_program_legal_basis_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_program
            ADD CONSTRAINT chk_edu_program_legal_basis_nonempty
            CHECK (length(btrim(legal_basis)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Programs are derived from:
--  • Education Policies (ENGINE 003)
--  • Sectoral & Strategic Plans (ENGINE 004)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only program records
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_program_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION PROGRAM VIOLATION: program records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_program_mutation
ON omnex_system_education.edu_program;

CREATE TRIGGER trg_prevent_edu_program_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_program
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_program_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_program
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_program
ON omnex_system_education.edu_program;

CREATE POLICY deny_all_edu_program
ON omnex_system_education.edu_program
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_program
ON omnex_system_education.edu_program IS
'Education programs (legal constructs) are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_program_code
ON omnex_system_education.edu_program (program_code);

CREATE INDEX IF NOT EXISTS idx_edu_program_policy
ON omnex_system_education.edu_program (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_program_plan
ON omnex_system_education.edu_program (plan_id);

CREATE INDEX IF NOT EXISTS idx_edu_program_status
ON omnex_system_education.edu_program (status);

CREATE INDEX IF NOT EXISTS idx_edu_program_effective
ON omnex_system_education.edu_program
USING btree (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 006
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_006
-- ENGINE NAME: Education Standards Registry
-- ENGINE FUNCTION:
--   Defines binding education standards and quality benchmarks issued
--   under approved education policies (non-operational, normative layer).

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — standards are sovereign legal constructs, not enumerations

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Standards Registry
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_standard (
    standard_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,       -- FK → edu_policy (ENGINE 003)

    standard_code text NOT NULL,
    standard_type text NOT NULL,   -- e.g. CURRICULUM, INFRASTRUCTURE, ASSESSMENT, TEACHER, INSTITUTIONAL
    standard_description text NOT NULL,

    issuing_body text NOT NULL,    -- e.g. Ministry, Authority, Council, Board

    effective_from date NOT NULL,
    effective_to   date,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_006'
);

COMMENT ON TABLE omnex_system_education.edu_standard IS
'Canonical registry of education standards and quality benchmarks issued under approved education policies';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_standard_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_standard
            ADD CONSTRAINT fk_edu_standard_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_standard_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_standard
            ADD CONSTRAINT uq_edu_standard_code
            UNIQUE (standard_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_standard_effective_range'
    ) THEN
        ALTER TABLE omnex_system_education.edu_standard
            ADD CONSTRAINT chk_edu_standard_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_standard_description_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_standard
            ADD CONSTRAINT chk_edu_standard_description_nonempty
            CHECK (length(btrim(standard_description)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Standards derive authority from:
--  • Education Policies (ENGINE 003)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only standard records
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_standard_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION STANDARD VIOLATION: standard records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_standard_mutation
ON omnex_system_education.edu_standard;

CREATE TRIGGER trg_prevent_edu_standard_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_standard
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_standard_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_standard
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_standard
ON omnex_system_education.edu_standard;

CREATE POLICY deny_all_edu_standard
ON omnex_system_education.edu_standard
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_standard
ON omnex_system_education.edu_standard IS
'Education standards are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_standard_code
ON omnex_system_education.edu_standard (standard_code);

CREATE INDEX IF NOT EXISTS idx_edu_standard_policy
ON omnex_system_education.edu_standard (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_standard_type
ON omnex_system_education.edu_standard (standard_type);

CREATE INDEX IF NOT EXISTS idx_edu_standard_status
ON omnex_system_education.edu_standard (status);

CREATE INDEX IF NOT EXISTS idx_edu_standard_effective
ON omnex_system_education.edu_standard
USING btree (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 007
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_007
-- ENGINE NAME: Education Quality Assurance Framework
-- ENGINE FUNCTION:
--   Defines quality assurance rules, inspection criteria,
--   accreditation dimensions, and compliance thresholds
--   derived from approved education standards.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — QA frameworks are legal constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Quality Assurance Framework
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_quality_assurance_framework (
    qa_framework_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    standard_id uuid NOT NULL,      -- FK → edu_standard (ENGINE 006)

    framework_code text NOT NULL,

    quality_dimensions text NOT NULL,
    assessment_method text NOT NULL,

    compliance_threshold numeric(5,2) NOT NULL
        CHECK (compliance_threshold >= 0 AND compliance_threshold <= 100),

    effective_from date NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_007'
);

COMMENT ON TABLE omnex_system_education.edu_quality_assurance_framework IS
'Canonical registry defining education quality assurance rules, inspection dimensions, and accreditation thresholds';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_qa_standard'
    ) THEN
        ALTER TABLE omnex_system_education.edu_quality_assurance_framework
            ADD CONSTRAINT fk_edu_qa_standard
            FOREIGN KEY (standard_id)
            REFERENCES omnex_system_education.edu_standard (standard_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_edu_qa_framework_code'
    ) THEN
        ALTER TABLE omnex_system_education.edu_quality_assurance_framework
            ADD CONSTRAINT uq_edu_qa_framework_code
            UNIQUE (framework_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_qa_dimensions_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_quality_assurance_framework
            ADD CONSTRAINT chk_edu_qa_dimensions_nonempty
            CHECK (length(btrim(quality_dimensions)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_qa_method_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_quality_assurance_framework
            ADD CONSTRAINT chk_edu_qa_method_nonempty
            CHECK (length(btrim(assessment_method)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Quality Assurance derives authority from:
--  • Education Standards (ENGINE 006)
-- Ultimately grounded in Policy → Standard → QA chain

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only QA frameworks
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_qa_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION QA VIOLATION: quality assurance frameworks are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_qa_mutation
ON omnex_system_education.edu_quality_assurance_framework;

CREATE TRIGGER trg_prevent_edu_qa_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_quality_assurance_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_qa_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_quality_assurance_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_qa_framework
ON omnex_system_education.edu_quality_assurance_framework;

CREATE POLICY deny_all_edu_qa_framework
ON omnex_system_education.edu_quality_assurance_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_qa_framework
ON omnex_system_education.edu_quality_assurance_framework IS
'Quality assurance frameworks are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_qa_framework_code
ON omnex_system_education.edu_quality_assurance_framework (framework_code);

CREATE INDEX IF NOT EXISTS idx_edu_qa_standard
ON omnex_system_education.edu_quality_assurance_framework (standard_id);

CREATE INDEX IF NOT EXISTS idx_edu_qa_status
ON omnex_system_education.edu_quality_assurance_framework (status);

CREATE INDEX IF NOT EXISTS idx_edu_qa_effective
ON omnex_system_education.edu_quality_assurance_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 008
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_008
-- ENGINE NAME: Institutional Governance Frameworks
-- ENGINE FUNCTION:
--   Defines lawful governance models, oversight structures,
--   and institutional control frameworks for education bodies
--   and agencies derived from approved education policies.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — governance frameworks are legal constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Institutional Governance Framework
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_institution_governance_framework (
    governance_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,          -- FK → edu_policy (ENGINE 003)

    institution_type text NOT NULL,   -- e.g. SCHOOL, UNIVERSITY, AGENCY, REGULATOR
    governance_model text NOT NULL,   -- e.g. BOARD_LED, EXECUTIVE, HYBRID
    oversight_body text NOT NULL,     -- e.g. Ministry, Council, Authority

    effective_from date NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_008'
);

COMMENT ON TABLE omnex_system_education.edu_institution_governance_framework IS
'Canonical registry defining lawful governance and oversight models for education institutions and agencies';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_gov_framework_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_institution_governance_framework
            ADD CONSTRAINT fk_edu_gov_framework_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_gov_institution_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_institution_governance_framework
            ADD CONSTRAINT chk_edu_gov_institution_type_nonempty
            CHECK (length(btrim(institution_type)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_gov_model_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_institution_governance_framework
            ADD CONSTRAINT chk_edu_gov_model_nonempty
            CHECK (length(btrim(governance_model)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_gov_oversight_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_institution_governance_framework
            ADD CONSTRAINT chk_edu_gov_oversight_nonempty
            CHECK (length(btrim(oversight_body)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Institutional governance authority derives from:
--   Policy → Governance Framework
-- This engine does not manage institutions themselves.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only governance frameworks
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_gov_framework_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION GOVERNANCE VIOLATION: institutional governance frameworks are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_gov_framework_mutation
ON omnex_system_education.edu_institution_governance_framework;

CREATE TRIGGER trg_prevent_edu_gov_framework_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_institution_governance_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_gov_framework_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_institution_governance_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_gov_framework
ON omnex_system_education.edu_institution_governance_framework;

CREATE POLICY deny_all_edu_gov_framework
ON omnex_system_education.edu_institution_governance_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_gov_framework
ON omnex_system_education.edu_institution_governance_framework IS
'Institutional governance frameworks are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_gov_framework_policy
ON omnex_system_education.edu_institution_governance_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_gov_framework_institution_type
ON omnex_system_education.edu_institution_governance_framework (institution_type);

CREATE INDEX IF NOT EXISTS idx_edu_gov_framework_status
ON omnex_system_education.edu_institution_governance_framework (status);

CREATE INDEX IF NOT EXISTS idx_edu_gov_framework_effective
ON omnex_system_education.edu_institution_governance_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 009
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_009
-- ENGINE NAME: Education Financing Policy Frameworks
-- ENGINE FUNCTION:
--   Governs lawful education financing constructs, including
--   funding eligibility, allocation logic, fiscal constraints,
--   and compliance boundaries derived from approved education policy.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — financing frameworks are legal-policy constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Financing Policy Framework
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_financing_policy_framework (
    financing_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,           -- FK → edu_policy (ENGINE 003)

    funding_type text NOT NULL,        -- e.g. CAPEX, OPEX, GRANT, SUBSIDY
    allocation_logic text NOT NULL,    -- narrative or reference logic (non-operational)
    constraints text,                  -- fiscal, legal, or eligibility constraints

    effective_from date NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_009'
);

COMMENT ON TABLE omnex_system_education.edu_financing_policy_framework IS
'Canonical registry defining lawful education financing policy frameworks and fiscal constraints';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_financing_policy_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_financing_policy_framework
            ADD CONSTRAINT fk_edu_financing_policy_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_financing_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_financing_policy_framework
            ADD CONSTRAINT chk_edu_financing_type_nonempty
            CHECK (length(btrim(funding_type)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_financing_allocation_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_financing_policy_framework
            ADD CONSTRAINT chk_edu_financing_allocation_nonempty
            CHECK (length(btrim(allocation_logic)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Financing authority chain:
--   Policy → Financing Policy Framework
-- No execution, budgeting, or disbursement occurs here.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only financing frameworks
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_financing_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION FINANCING VIOLATION: financing policy frameworks are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_financing_mutation
ON omnex_system_education.edu_financing_policy_framework;

CREATE TRIGGER trg_prevent_edu_financing_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_financing_policy_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_financing_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_financing_policy_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_financing_policy
ON omnex_system_education.edu_financing_policy_framework;

CREATE POLICY deny_all_edu_financing_policy
ON omnex_system_education.edu_financing_policy_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_financing_policy
ON omnex_system_education.edu_financing_policy_framework IS
'Education financing policy frameworks are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_financing_policy_policy
ON omnex_system_education.edu_financing_policy_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_financing_policy_type
ON omnex_system_education.edu_financing_policy_framework (funding_type);

CREATE INDEX IF NOT EXISTS idx_edu_financing_policy_status
ON omnex_system_education.edu_financing_policy_framework (status);

CREATE INDEX IF NOT EXISTS idx_edu_financing_policy_effective
ON omnex_system_education.edu_financing_policy_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 010
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_010
-- ENGINE NAME: Education Data Governance Rules
-- ENGINE FUNCTION:
--   Defines lawful handling, classification, sharing, retention,
--   and protection rules for education data, derived strictly
--   from approved education policy and statutory obligations.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — data governance rules are legal constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Data Governance Framework
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_data_governance_framework (
    data_gov_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,                 -- FK → edu_policy (ENGINE 003)

    data_domain text NOT NULL,               -- e.g. STUDENT, INSTITUTION, EXAMINATION
    access_classification text NOT NULL,     -- e.g. PUBLIC, RESTRICTED, CONFIDENTIAL
    retention_policy text NOT NULL,          -- narrative or reference (non-operational)
    compliance_standard text,                -- e.g. DATA_PROTECTION_ACT, GDPR_EQUIV

    effective_from date NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_010'
);

COMMENT ON TABLE omnex_system_education.edu_data_governance_framework IS
'Canonical registry defining lawful education data governance, classification, and protection rules';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_data_gov_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_data_governance_framework
            ADD CONSTRAINT fk_edu_data_gov_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_data_domain_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_data_governance_framework
            ADD CONSTRAINT chk_edu_data_domain_nonempty
            CHECK (length(btrim(data_domain)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_data_access_class_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_data_governance_framework
            ADD CONSTRAINT chk_edu_data_access_class_nonempty
            CHECK (length(btrim(access_classification)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_data_retention_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_data_governance_framework
            ADD CONSTRAINT chk_edu_data_retention_nonempty
            CHECK (length(btrim(retention_policy)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Governance chain:
--   Policy → Data Governance Framework
-- Enforcement, logging, and access control occur in other systems.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only data governance rules
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_data_gov_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION DATA GOVERNANCE VIOLATION: data governance frameworks are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_data_gov_mutation
ON omnex_system_education.edu_data_governance_framework;

CREATE TRIGGER trg_prevent_edu_data_gov_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_data_governance_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_data_gov_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_data_governance_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_data_gov
ON omnex_system_education.edu_data_governance_framework;

CREATE POLICY deny_all_edu_data_gov
ON omnex_system_education.edu_data_governance_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_data_gov
ON omnex_system_education.edu_data_governance_framework IS
'Education data governance frameworks are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_data_gov_policy
ON omnex_system_education.edu_data_governance_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_data_gov_domain
ON omnex_system_education.edu_data_governance_framework (data_domain);

CREATE INDEX IF NOT EXISTS idx_edu_data_gov_access
ON omnex_system_education.edu_data_governance_framework (access_classification);

CREATE INDEX IF NOT EXISTS idx_edu_data_gov_status
ON omnex_system_education.edu_data_governance_framework (status);

CREATE INDEX IF NOT EXISTS idx_edu_data_gov_effective
ON omnex_system_education.edu_data_governance_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — OMNEX SYSTEM EDUCATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM EDUCATION — ENGINE 011
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_014
-- SYSTEM ID: 2026014
-- SYSTEM CODE: OS_ED
-- SYSTEM NAME: Omnex_System_Education

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_education

-- ENGINE NO: engine_011
-- ENGINE NAME: Oversight, Inspection & Accountability
-- ENGINE FUNCTION:
--   Defines lawful oversight regimes, inspection models,
--   accountability mechanisms, sanctions, and corrective
--   measures applicable to the education sector.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026014_omnex_system_education.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_education;
REVOKE ALL ON SCHEMA omnex_system_education FROM PUBLIC;

SET search_path = omnex_system_education, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — oversight regimes are legal constructs, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Education Oversight Framework
CREATE TABLE IF NOT EXISTS omnex_system_education.edu_oversight_framework (
    oversight_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,                  -- FK → edu_policy (ENGINE 003)

    oversight_type text NOT NULL,             -- e.g. INSPECTION, AUDIT, ACCREDITATION
    inspection_frequency text NOT NULL,       -- e.g. ANNUAL, BIENNIAL, EVENT_DRIVEN
    enforcement_action text NOT NULL,         -- sanctions or corrective measures
    authority_body text NOT NULL,             -- e.g. Ministry, Regulator, Commission

    effective_from date NOT NULL,

    status text NOT NULL CHECK (
        status IN ('Draft', 'Active', 'Superseded', 'Retired')
    ),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_011'
);

COMMENT ON TABLE omnex_system_education.edu_oversight_framework IS
'Canonical registry defining education oversight, inspection, enforcement, and accountability regimes';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_edu_oversight_policy'
    ) THEN
        ALTER TABLE omnex_system_education.edu_oversight_framework
            ADD CONSTRAINT fk_edu_oversight_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_education.edu_policy (policy_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_oversight_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_oversight_framework
            ADD CONSTRAINT chk_edu_oversight_type_nonempty
            CHECK (length(btrim(oversight_type)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_inspection_frequency_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_oversight_framework
            ADD CONSTRAINT chk_edu_inspection_frequency_nonempty
            CHECK (length(btrim(inspection_frequency)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_enforcement_action_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_oversight_framework
            ADD CONSTRAINT chk_edu_enforcement_action_nonempty
            CHECK (length(btrim(enforcement_action)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_edu_authority_body_nonempty'
    ) THEN
        ALTER TABLE omnex_system_education.edu_oversight_framework
            ADD CONSTRAINT chk_edu_authority_body_nonempty
            CHECK (length(btrim(authority_body)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Governance chain:
--   Policy → Oversight Framework
-- Execution, inspections, sanctions, and audits occur in
-- operational and audit systems, not here.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only oversight regimes
CREATE OR REPLACE FUNCTION omnex_system_education.prevent_edu_oversight_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'EDUCATION OVERSIGHT VIOLATION: oversight frameworks are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_edu_oversight_mutation
ON omnex_system_education.edu_oversight_framework;

CREATE TRIGGER trg_prevent_edu_oversight_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_education.edu_oversight_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_education.prevent_edu_oversight_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_education.edu_oversight_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_edu_oversight
ON omnex_system_education.edu_oversight_framework;

CREATE POLICY deny_all_edu_oversight
ON omnex_system_education.edu_oversight_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_edu_oversight
ON omnex_system_education.edu_oversight_framework IS
'Education oversight frameworks are centrally governed; no direct access permitted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_edu_oversight_policy
ON omnex_system_education.edu_oversight_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_edu_oversight_type
ON omnex_system_education.edu_oversight_framework (oversight_type);

CREATE INDEX IF NOT EXISTS idx_edu_oversight_authority
ON omnex_system_education.edu_oversight_framework (authority_body);

CREATE INDEX IF NOT EXISTS idx_edu_oversight_status
ON omnex_system_education.edu_oversight_framework (status);

CREATE INDEX IF NOT EXISTS idx_edu_oversight_effective
ON omnex_system_education.edu_oversight_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — OMNEX SYSTEM EDUCATION
-- ============================================================
