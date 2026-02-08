-- ============================================================
-- THIS FILE IS A LAW-BOUND MIGRATION. IT MUST NEVER BE RENAMED,
-- MODIFIED, RESHUFFLED, OR MANIPULATED IN ANY WAY AFTER INSTALL.
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_000
-- ENGINE NAME: Infrastructure System Admission Ledger
-- ENGINE FUNCTION:
--   Constitutionally admits Omnex_System_Infrastructure as a
--   sovereign infrastructure authority system under
--   Omnex_System_Core. Declares existence, scope, authority,
--   and readiness — no operational behavior.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_infrastructure IS
'Omnex System Infrastructure — sovereign infrastructure authority schema (ENGINE 000 admission only)';

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — admission is governed by Omnex_System_Core record types

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure System Admission Ledger
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infrastructure_system_admission (
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

COMMENT ON TABLE omnex_system_infrastructure.infrastructure_system_admission IS
'ENGINE 000 — Immutable admission record declaring Omnex_System_Infrastructure as a lawful sovereign authority system';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infrastructure_admission_identity'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infrastructure_system_admission
            ADD CONSTRAINT chk_infrastructure_admission_identity
            CHECK (
                system_code   = 'OS_INFRA'
                AND category_code = 'OS_AUTH'
                AND schema_name   = 'omnex_system_infrastructure'
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infrastructure_admission_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infrastructure_system_admission
            ADD CONSTRAINT chk_infrastructure_admission_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — system admission is sovereign and non-dependent

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

CREATE OR REPLACE FUNCTION omnex_system_infrastructure.compute_and_validate_admission_checksum()
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
            'INFRASTRUCTURE ADMISSION CHECKSUM VIOLATION: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_infrastructure_admission_checksum
ON omnex_system_infrastructure.infrastructure_system_admission;

CREATE TRIGGER trg_validate_infrastructure_admission_checksum
BEFORE INSERT
ON omnex_system_infrastructure.infrastructure_system_admission
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.compute_and_validate_admission_checksum();

CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_admission_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE SYSTEM ADMISSION IS IMMUTABLE — updates or deletes are forbidden';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infrastructure_admission_mutation
ON omnex_system_infrastructure.infrastructure_system_admission;

CREATE TRIGGER trg_prevent_infrastructure_admission_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infrastructure_system_admission
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_admission_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infrastructure_system_admission
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infrastructure_admission
ON omnex_system_infrastructure.infrastructure_system_admission;

CREATE POLICY deny_all_infrastructure_admission
ON omnex_system_infrastructure.infrastructure_system_admission
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infrastructure_admission
ON omnex_system_infrastructure.infrastructure_system_admission IS
'Infrastructure system admission is governed exclusively by Omnex_System_Core';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infrastructure_admission_system_code
ON omnex_system_infrastructure.infrastructure_system_admission (system_code);

CREATE INDEX IF NOT EXISTS idx_infrastructure_admission_status
ON omnex_system_infrastructure.infrastructure_system_admission (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_001
-- ENGINE NAME: Infrastructure Legal Instruments
-- ENGINE FUNCTION:
--   Registers all legal instruments governing infrastructure,
--   including Acts, regulations, statutory instruments,
--   standards acts, and infrastructure-specific statutes.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — legal instrument types are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Legal Instrument Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_legal_instrument (
    instrument_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    instrument_code text NOT NULL UNIQUE,
    instrument_type text NOT NULL,       -- ACT / REGULATION / STATUTE / STANDARD_ACT
    title           text NOT NULL,

    issuing_authority text NOT NULL,
    jurisdiction      text NOT NULL,

    enacted_at     date NOT NULL,
    effective_from date NOT NULL,
    effective_to   date NULL,

    status          text NOT NULL,        -- DRAFT / ACTIVE / REPEALED / EXPIRED

    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      text NOT NULL DEFAULT 'ENGINE_001'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_legal_instrument IS
'Authoritative registry of infrastructure legal instruments and statutory foundations';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_legal_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_legal_instrument
            ADD CONSTRAINT chk_infra_legal_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Non-empty instrument code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_legal_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_legal_instrument
            ADD CONSTRAINT chk_infra_legal_code_nonempty
            CHECK (length(instrument_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — legal instruments are sovereign authority roots

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only legal truth)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_infra_legal_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE LEGAL VIOLATION: legal instruments are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_legal_mutation
ON omnex_system_infrastructure.infra_legal_instrument;

CREATE TRIGGER trg_prevent_infra_legal_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_legal_instrument
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_infra_legal_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_legal_instrument
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_legal
ON omnex_system_infrastructure.infra_legal_instrument;

CREATE POLICY deny_all_infra_legal
ON omnex_system_infrastructure.infra_legal_instrument
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_legal
ON omnex_system_infrastructure.infra_legal_instrument IS
'Infrastructure legal instruments are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_legal_instrument_code
ON omnex_system_infrastructure.infra_legal_instrument (instrument_code);

CREATE INDEX IF NOT EXISTS idx_infra_legal_status
ON omnex_system_infrastructure.infra_legal_instrument (status);

CREATE INDEX IF NOT EXISTS idx_infra_legal_effective
ON omnex_system_infrastructure.infra_legal_instrument (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_002
-- ENGINE NAME: National Infrastructure Mandates
-- ENGINE FUNCTION:
--   Captures executive and constitutional mandates directing
--   national infrastructure obligations and priorities.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — mandate semantics are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 National Infrastructure Mandate Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_mandate (
    mandate_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_id uuid NOT NULL,                 -- FK to infra_legal_instrument
    mandate_code text NOT NULL UNIQUE,
    mandate_description text NOT NULL,

    issuing_authority text NOT NULL,

    effective_from date NOT NULL,
    effective_to   date NULL,

    status text NOT NULL,                   -- DRAFT / ACTIVE / REVOKED / EXPIRED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_002'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_mandate IS
'Authoritative registry of executive and constitutional mandates governing infrastructure';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_mandate_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_mandate
            ADD CONSTRAINT chk_infra_mandate_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Non-empty mandate code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_mandate_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_mandate
            ADD CONSTRAINT chk_infra_mandate_code_nonempty
            CHECK (length(mandate_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Mandate must derive from a legal instrument
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_infra_mandate_legal'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_mandate
            ADD CONSTRAINT fk_infra_mandate_legal
            FOREIGN KEY (legal_id)
            REFERENCES omnex_system_infrastructure.infra_legal_instrument (instrument_id)
            DEFERRABLE INITIALLY DEFERRED;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only mandate truth)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_infra_mandate_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE MANDATE VIOLATION: mandates are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_mandate_mutation
ON omnex_system_infrastructure.infra_mandate;

CREATE TRIGGER trg_prevent_infra_mandate_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_mandate
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_infra_mandate_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_mandate
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_mandate
ON omnex_system_infrastructure.infra_mandate;

CREATE POLICY deny_all_infra_mandate
ON omnex_system_infrastructure.infra_mandate
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_mandate
ON omnex_system_infrastructure.infra_mandate IS
'Infrastructure mandates are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_mandate_code
ON omnex_system_infrastructure.infra_mandate (mandate_code);

CREATE INDEX IF NOT EXISTS idx_infra_mandate_status
ON omnex_system_infrastructure.infra_mandate (status);

CREATE INDEX IF NOT EXISTS idx_infra_mandate_effective
ON omnex_system_infrastructure.infra_mandate (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 003
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_003
-- ENGINE NAME: Infrastructure Policy Authority
-- ENGINE FUNCTION:
--   Defines binding national and sector-wide infrastructure
--   policies derived from legal instruments and mandates.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — policy state is authoritative data, not enum

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Policy Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_policy (
    policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    legal_id uuid NOT NULL,          -- FK to infra_legal_instrument
    mandate_id uuid NOT NULL,        -- FK to infra_mandate

    policy_code text NOT NULL UNIQUE,
    policy_name text NOT NULL,
    policy_scope text NOT NULL,      -- NATIONAL / SECTORAL / REGIONAL

    effective_from date NOT NULL,
    effective_to   date NULL,

    status text NOT NULL,            -- DRAFT / ACTIVE / RETIRED / REVOKED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_003'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_policy IS
'Authoritative registry of binding infrastructure policies derived from legal instruments and mandates';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_policy_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_policy
            ADD CONSTRAINT chk_infra_policy_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Non-empty policy code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_policy_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_policy
            ADD CONSTRAINT chk_infra_policy_code_nonempty
            CHECK (length(policy_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Policy must derive from a legal instrument
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_infra_policy_legal'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_policy
            ADD CONSTRAINT fk_infra_policy_legal
            FOREIGN KEY (legal_id)
            REFERENCES omnex_system_infrastructure.infra_legal_instrument (instrument_id)
            DEFERRABLE INITIALLY DEFERRED;
    END IF;
END $$;

-- Policy must derive from a mandate
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_infra_policy_mandate'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_policy
            ADD CONSTRAINT fk_infra_policy_mandate
            FOREIGN KEY (mandate_id)
            REFERENCES omnex_system_infrastructure.infra_mandate (mandate_id)
            DEFERRABLE INITIALLY DEFERRED;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only policy truth)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_infra_policy_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE POLICY VIOLATION: policies are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_policy_mutation
ON omnex_system_infrastructure.infra_policy;

CREATE TRIGGER trg_prevent_infra_policy_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_policy
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_infra_policy_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_policy
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_policy
ON omnex_system_infrastructure.infra_policy;

CREATE POLICY deny_all_infra_policy
ON omnex_system_infrastructure.infra_policy
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_policy
ON omnex_system_infrastructure.infra_policy IS
'Infrastructure policies are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_policy_code
ON omnex_system_infrastructure.infra_policy (policy_code);

CREATE INDEX IF NOT EXISTS idx_infra_policy_status
ON omnex_system_infrastructure.infra_policy (status);

CREATE INDEX IF NOT EXISTS idx_infra_policy_effective
ON omnex_system_infrastructure.infra_policy (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 004
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_004
-- ENGINE NAME: Master & Sector Infrastructure Plans
-- ENGINE FUNCTION:
--   Stores national master plans, corridor plans, and sector
--   infrastructure plans derived from approved infrastructure policy.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — plan type and status are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Master & Sector Plans
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_plan (
    plan_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,     -- FK to infra_policy

    plan_code text NOT NULL UNIQUE,
    plan_name text NOT NULL,

    plan_type text NOT NULL,     -- NATIONAL / SECTOR / CORRIDOR / REGIONAL

    start_year integer NOT NULL,
    end_year   integer NOT NULL,

    status text NOT NULL,        -- DRAFT / ACTIVE / SUPERSEDED / RETIRED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_004'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_plan IS
'Authoritative registry of national, corridor, and sector infrastructure plans derived from policy';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Plan horizon sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_plan_horizon'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_plan
            ADD CONSTRAINT chk_infra_plan_horizon
            CHECK (end_year >= start_year);
    END IF;
END $$;

-- Non-empty plan code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_plan_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_plan
            ADD CONSTRAINT chk_infra_plan_code_nonempty
            CHECK (length(plan_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Plans must derive from approved infrastructure policy
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_infra_plan_policy'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_plan
            ADD CONSTRAINT fk_infra_plan_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_infrastructure.infra_policy (policy_id)
            DEFERRABLE INITIALLY DEFERRED;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only plan truth)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_infra_plan_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE PLAN VIOLATION: plans are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_plan_mutation
ON omnex_system_infrastructure.infra_plan;

CREATE TRIGGER trg_prevent_infra_plan_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_plan
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_infra_plan_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_plan
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_plan
ON omnex_system_infrastructure.infra_plan;

CREATE POLICY deny_all_infra_plan
ON omnex_system_infrastructure.infra_plan
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_plan
ON omnex_system_infrastructure.infra_plan IS
'Infrastructure plans are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_plan_code
ON omnex_system_infrastructure.infra_plan (plan_code);

CREATE INDEX IF NOT EXISTS idx_infra_plan_type
ON omnex_system_infrastructure.infra_plan (plan_type);

CREATE INDEX IF NOT EXISTS idx_infra_plan_status
ON omnex_system_infrastructure.infra_plan (status);

CREATE INDEX IF NOT EXISTS idx_infra_plan_horizon
ON omnex_system_infrastructure.infra_plan (start_year, end_year);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 005
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_005
-- ENGINE NAME: Asset Classification Authority
-- ENGINE FUNCTION:
--   Defines the canonical taxonomy and hierarchical classification
--   of infrastructure assets used uniformly across planning,
--   financing, regulation, construction, and operations systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — asset classes are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Asset Classification Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_asset_classification (
    classification_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    class_code text NOT NULL UNIQUE,
    class_type text NOT NULL,              -- e.g. TRANSPORT / ENERGY / WATER / ICT
    description text NOT NULL,

    parent_class_id uuid NULL,

    status text NOT NULL,                  -- ACTIVE / RETIRED / SUPERSEDED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_005'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_asset_classification IS
'Authoritative hierarchical taxonomy defining infrastructure asset classes';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Non-empty class code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_asset_class_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_asset_classification
            ADD CONSTRAINT chk_infra_asset_class_code_nonempty
            CHECK (length(class_code) > 0);
    END IF;
END $$;

-- Prevent self-referencing parent
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_asset_no_self_parent'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_asset_classification
            ADD CONSTRAINT chk_infra_asset_no_self_parent
            CHECK (
                parent_class_id IS NULL
                OR parent_class_id <> classification_id
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Hierarchical self-referencing relationship (safe rerun)
ALTER TABLE omnex_system_infrastructure.infra_asset_classification
    DROP CONSTRAINT IF EXISTS fk_infra_asset_parent;

ALTER TABLE omnex_system_infrastructure.infra_asset_classification
    ADD CONSTRAINT fk_infra_asset_parent
    FOREIGN KEY (parent_class_id)
    REFERENCES omnex_system_infrastructure.infra_asset_classification (classification_id)
    DEFERRABLE INITIALLY DEFERRED;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only classification truth)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_asset_classification_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'ASSET CLASSIFICATION VIOLATION: asset classifications are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_asset_classification_mutation
ON omnex_system_infrastructure.infra_asset_classification;

CREATE TRIGGER trg_prevent_asset_classification_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_asset_classification
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_asset_classification_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_asset_classification
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_asset_classification
ON omnex_system_infrastructure.infra_asset_classification;

CREATE POLICY deny_all_infra_asset_classification
ON omnex_system_infrastructure.infra_asset_classification
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_asset_classification
ON omnex_system_infrastructure.infra_asset_classification IS
'Infrastructure asset classifications are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_asset_class_code
ON omnex_system_infrastructure.infra_asset_classification (class_code);

CREATE INDEX IF NOT EXISTS idx_infra_asset_class_type
ON omnex_system_infrastructure.infra_asset_classification (class_type);

CREATE INDEX IF NOT EXISTS idx_infra_asset_class_status
ON omnex_system_infrastructure.infra_asset_classification (status);

CREATE INDEX IF NOT EXISTS idx_infra_asset_class_parent
ON omnex_system_infrastructure.infra_asset_classification (parent_class_id);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 006
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_006
-- ENGINE NAME: Infrastructure Standards Authority
-- ENGINE FUNCTION:
--   Defines authoritative technical standards, codes, and specifications
--   governing infrastructure design, construction, safety, and operation.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — standards are authoritative records, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Standards Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_standard (
    standard_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,

    standard_code text NOT NULL UNIQUE,
    standard_type text NOT NULL,              -- DESIGN / SAFETY / ENVIRONMENTAL / OPERATIONS
    issuing_body text NOT NULL,

    effective_from date NOT NULL,
    effective_to   date NULL,

    status text NOT NULL,                     -- ACTIVE / RETIRED / SUPERSEDED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_006'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_standard IS
'Authoritative registry of technical infrastructure standards and codes';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_standard_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_standard
            ADD CONSTRAINT chk_infra_standard_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Non-empty standard code
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_standard_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_standard
            ADD CONSTRAINT chk_infra_standard_code_nonempty
            CHECK (length(standard_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Policy authority relationship (safe rerun)
ALTER TABLE omnex_system_infrastructure.infra_standard
    DROP CONSTRAINT IF EXISTS fk_infra_standard_policy;

ALTER TABLE omnex_system_infrastructure.infra_standard
    ADD CONSTRAINT fk_infra_standard_policy
    FOREIGN KEY (policy_id)
    REFERENCES omnex_system_infrastructure.infra_policy (policy_id)
    DEFERRABLE INITIALLY DEFERRED;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only standards authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_infra_standard_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE STANDARD VIOLATION: standards are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_standard_mutation
ON omnex_system_infrastructure.infra_standard;

CREATE TRIGGER trg_prevent_infra_standard_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_standard
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_infra_standard_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_standard
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_standard
ON omnex_system_infrastructure.infra_standard;

CREATE POLICY deny_all_infra_standard
ON omnex_system_infrastructure.infra_standard
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_standard
ON omnex_system_infrastructure.infra_standard IS
'Infrastructure standards are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_standard_code
ON omnex_system_infrastructure.infra_standard (standard_code);

CREATE INDEX IF NOT EXISTS idx_infra_standard_type
ON omnex_system_infrastructure.infra_standard (standard_type);

CREATE INDEX IF NOT EXISTS idx_infra_standard_status
ON omnex_system_infrastructure.infra_standard (status);

CREATE INDEX IF NOT EXISTS idx_infra_standard_effective
ON omnex_system_infrastructure.infra_standard (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 007
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_007
-- ENGINE NAME: Lifecycle Governance Authority
-- ENGINE FUNCTION:
--   Defines lawful lifecycle rules governing creation, upgrade,
--   suspension, rehabilitation, and decommissioning of
--   infrastructure assets by class.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — lifecycle stages are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Lifecycle Governance Rules
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_lifecycle_rule (
    rule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    asset_class_id uuid NOT NULL,

    lifecycle_stage text NOT NULL,        -- CREATE / UPGRADE / MAINTAIN / SUSPEND / DECOMMISSION
    rule_definition text NOT NULL,

    effective_from date NOT NULL,

    status text NOT NULL,                 -- ACTIVE / RETIRED / SUPERSEDED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_007'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_lifecycle_rule IS
'Authoritative lifecycle governance rules for infrastructure assets by classification';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Non-empty lifecycle stage
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_lifecycle_stage_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_lifecycle_rule
            ADD CONSTRAINT chk_lifecycle_stage_nonempty
            CHECK (length(lifecycle_stage) > 0);
    END IF;
END $$;

-- Non-empty rule definition
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_lifecycle_rule_definition_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_lifecycle_rule
            ADD CONSTRAINT chk_lifecycle_rule_definition_nonempty
            CHECK (length(rule_definition) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Asset classification authority linkage (safe rerun)
ALTER TABLE omnex_system_infrastructure.infra_lifecycle_rule
    DROP CONSTRAINT IF EXISTS fk_lifecycle_asset_class;

ALTER TABLE omnex_system_infrastructure.infra_lifecycle_rule
    ADD CONSTRAINT fk_lifecycle_asset_class
    FOREIGN KEY (asset_class_id)
    REFERENCES omnex_system_infrastructure.infra_asset_classification (classification_id)
    DEFERRABLE INITIALLY DEFERRED;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only lifecycle authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_lifecycle_rule_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE LIFECYCLE VIOLATION: lifecycle rules are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_lifecycle_rule_mutation
ON omnex_system_infrastructure.infra_lifecycle_rule;

CREATE TRIGGER trg_prevent_lifecycle_rule_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_lifecycle_rule
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_lifecycle_rule_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_lifecycle_rule
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_lifecycle_rule
ON omnex_system_infrastructure.infra_lifecycle_rule;

CREATE POLICY deny_all_infra_lifecycle_rule
ON omnex_system_infrastructure.infra_lifecycle_rule
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_lifecycle_rule
ON omnex_system_infrastructure.infra_lifecycle_rule IS
'Lifecycle governance rules are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_lifecycle_asset_class
ON omnex_system_infrastructure.infra_lifecycle_rule (asset_class_id);

CREATE INDEX IF NOT EXISTS idx_lifecycle_stage
ON omnex_system_infrastructure.infra_lifecycle_rule (lifecycle_stage);

CREATE INDEX IF NOT EXISTS idx_lifecycle_status
ON omnex_system_infrastructure.infra_lifecycle_rule (status);

CREATE INDEX IF NOT EXISTS idx_lifecycle_effective
ON omnex_system_infrastructure.infra_lifecycle_rule (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 008
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_008
-- ENGINE NAME: Custodianship & Ownership Authority
-- ENGINE FUNCTION:
--   Defines lawful custodianship, ownership responsibility,
--   and institutional accountability for infrastructure assets.
--   Establishes who is responsible — not who operates.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — custodian types and scopes are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Custodianship & Ownership Framework
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_custodian_framework (
    custodian_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    institution_type text NOT NULL,        -- Ministry / Authority / Agency / SOE / PPP Entity
    responsibility_scope text NOT NULL,    -- OWNERSHIP / CUSTODY / TRUSTEESHIP / STEWARDSHIP

    legal_basis text NOT NULL,              -- Act / Regulation / Cabinet Decision reference

    effective_from date NOT NULL,

    status text NOT NULL,                   -- ACTIVE / REVOKED / SUPERSEDED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_008'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_custodian_framework IS
'Authoritative registry defining custodianship and ownership responsibility for infrastructure assets';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Institution type must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_custodian_institution_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_custodian_framework
            ADD CONSTRAINT chk_infra_custodian_institution_nonempty
            CHECK (length(institution_type) > 0);
    END IF;
END $$;

-- Responsibility scope must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_custodian_scope_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_custodian_framework
            ADD CONSTRAINT chk_infra_custodian_scope_nonempty
            CHECK (length(responsibility_scope) > 0);
    END IF;
END $$;

-- Legal basis must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_custodian_legal_basis_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_custodian_framework
            ADD CONSTRAINT chk_infra_custodian_legal_basis_nonempty
            CHECK (length(legal_basis) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — custodianship is an authority declaration,
-- referenced by other engines but not dependent here.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_custodian_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE CUSTODIANSHIP VIOLATION: custodianship records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_custodian_mutation
ON omnex_system_infrastructure.infra_custodian_framework;

CREATE TRIGGER trg_prevent_custodian_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_custodian_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_custodian_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_custodian_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_custodian_framework
ON omnex_system_infrastructure.infra_custodian_framework;

CREATE POLICY deny_all_infra_custodian_framework
ON omnex_system_infrastructure.infra_custodian_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_custodian_framework
ON omnex_system_infrastructure.infra_custodian_framework IS
'Custodianship authority is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_custodian_institution
ON omnex_system_infrastructure.infra_custodian_framework (institution_type);

CREATE INDEX IF NOT EXISTS idx_infra_custodian_scope
ON omnex_system_infrastructure.infra_custodian_framework (responsibility_scope);

CREATE INDEX IF NOT EXISTS idx_infra_custodian_status
ON omnex_system_infrastructure.infra_custodian_framework (status);

CREATE INDEX IF NOT EXISTS idx_infra_custodian_effective
ON omnex_system_infrastructure.infra_custodian_framework (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 009
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_009
-- ENGINE NAME: Infrastructure Financing Policy Authority
-- ENGINE FUNCTION:
--   Defines lawful infrastructure financing policies, including
--   funding eligibility rules, constraints, and policy conditions.
--   Governs who may be funded and under what conditions — not execution.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — financing types and constraints are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Financing Policy Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_financing_policy (
    financing_policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,                -- Reference to Infrastructure Policy Authority
    funding_type text NOT NULL,             -- BUDGET / GRANT / LOAN / PPP / CONCESSION

    eligibility_rules text NOT NULL,        -- Human + machine interpretable rules
    constraints text NOT NULL,              -- Caps, ratios, exclusions, ceilings

    effective_from date NOT NULL,

    status text NOT NULL,                   -- DRAFT / ACTIVE / RETIRED / SUPERSEDED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_009'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_financing_policy IS
'Authoritative registry defining lawful infrastructure financing eligibility and constraints';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Funding type must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_financing_funding_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_financing_policy
            ADD CONSTRAINT chk_infra_financing_funding_type_nonempty
            CHECK (length(funding_type) > 0);
    END IF;
END $$;

-- Eligibility rules must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_financing_eligibility_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_financing_policy
            ADD CONSTRAINT chk_infra_financing_eligibility_nonempty
            CHECK (length(eligibility_rules) > 0);
    END IF;
END $$;

-- Constraints must be non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_financing_constraints_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_financing_policy
            ADD CONSTRAINT chk_infra_financing_constraints_nonempty
            CHECK (length(constraints) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- No FK enforced here by design.
-- policy_id is resolved by Governance/Core to avoid hard coupling.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only financing authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_financing_policy_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRASTRUCTURE FINANCING POLICY VIOLATION: records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_financing_policy_mutation
ON omnex_system_infrastructure.infra_financing_policy;

CREATE TRIGGER trg_prevent_financing_policy_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_financing_policy
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_financing_policy_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_financing_policy
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_financing_policy
ON omnex_system_infrastructure.infra_financing_policy;

CREATE POLICY deny_all_infra_financing_policy
ON omnex_system_infrastructure.infra_financing_policy
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_financing_policy
ON omnex_system_infrastructure.infra_financing_policy IS
'Infrastructure financing policy authority is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_financing_policy_policy
ON omnex_system_infrastructure.infra_financing_policy (policy_id);

CREATE INDEX IF NOT EXISTS idx_infra_financing_policy_type
ON omnex_system_infrastructure.infra_financing_policy (funding_type);

CREATE INDEX IF NOT EXISTS idx_infra_financing_policy_status
ON omnex_system_infrastructure.infra_financing_policy (status);

CREATE INDEX IF NOT EXISTS idx_infra_financing_policy_effective
ON omnex_system_infrastructure.infra_financing_policy (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 010
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_010
-- ENGINE NAME: Infrastructure Data Governance Authority
-- ENGINE FUNCTION:
--   Defines lawful ownership, access classification, sharing,
--   retention, and compliance rules for infrastructure data.
--   Governs data meaning and legality — not data storage or execution.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — access classes and standards are authority data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Data Governance Framework
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_data_governance_framework (
    data_gov_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,                     -- Reference to Infrastructure Policy Authority
    data_domain text NOT NULL,                   -- ASSET / PROJECT / GEO / FINANCIAL / SENSOR

    access_classification text NOT NULL,         -- PUBLIC / RESTRICTED / CONFIDENTIAL / SECRET
    retention_policy text NOT NULL,              -- Duration + disposal semantics
    compliance_standard text NOT NULL,           -- ISO / NIST / NATIONAL / SECTORAL

    effective_from date NOT NULL,
    effective_to   date NULL,

    status text NOT NULL,                        -- DRAFT / ACTIVE / RETIRED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_010'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_data_governance_framework IS
'Authoritative registry defining lawful infrastructure data ownership, access, retention, and compliance semantics';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_data_gov_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_data_governance_framework
            ADD CONSTRAINT chk_infra_data_gov_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Non-empty domain
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_data_domain_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_data_governance_framework
            ADD CONSTRAINT chk_infra_data_domain_nonempty
            CHECK (length(data_domain) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — authority references are enforced constitutionally, not by FK

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation (append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_data_gov_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA DATA GOVERNANCE VIOLATION: authority records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_data_gov_mutation
ON omnex_system_infrastructure.infra_data_governance_framework;

CREATE TRIGGER trg_prevent_data_gov_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_data_governance_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_data_gov_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_data_governance_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_data_gov
ON omnex_system_infrastructure.infra_data_governance_framework;

CREATE POLICY deny_all_infra_data_gov
ON omnex_system_infrastructure.infra_data_governance_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_data_gov
ON omnex_system_infrastructure.infra_data_governance_framework IS
'Infrastructure data governance is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_data_gov_policy
ON omnex_system_infrastructure.infra_data_governance_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_infra_data_gov_domain
ON omnex_system_infrastructure.infra_data_governance_framework (data_domain);

CREATE INDEX IF NOT EXISTS idx_infra_data_gov_access
ON omnex_system_infrastructure.infra_data_governance_framework (access_classification);

CREATE INDEX IF NOT EXISTS idx_infra_data_gov_status
ON omnex_system_infrastructure.infra_data_governance_framework (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 011
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_011
-- ENGINE NAME: Oversight & Safety Authority
-- ENGINE FUNCTION:
--   Defines lawful oversight regimes, inspection frequency,
--   safety enforcement actions, and accountability authorities
--   governing infrastructure assets and programs.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — oversight types and enforcement actions are authority data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Oversight & Safety Framework
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_oversight_framework (
    oversight_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id uuid NOT NULL,                    -- Reference to Infrastructure Policy Authority
    oversight_type text NOT NULL,               -- SAFETY / TECHNICAL / ENVIRONMENTAL / FINANCIAL
    inspection_frequency text NOT NULL,         -- CONTINUOUS / ANNUAL / BIENNIAL / EVENT-BASED

    enforcement_action text NOT NULL,           -- WARN / SUSPEND / SHUTDOWN / SANCTION
    authority_body text NOT NULL,               -- Regulator / Ministry / Independent Authority

    effective_from date NOT NULL,
    effective_to   date NULL,

    status text NOT NULL,                       -- DRAFT / ACTIVE / RETIRED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_011'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_oversight_framework IS
'Authoritative registry defining lawful infrastructure oversight, inspection, safety, and enforcement regimes';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_oversight_effective_range'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_oversight_framework
            ADD CONSTRAINT chk_infra_oversight_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Oversight type non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_oversight_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_oversight_framework
            ADD CONSTRAINT chk_infra_oversight_type_nonempty
            CHECK (length(oversight_type) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — oversight authority is constitutionally referenced, not FK-enforced

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation (append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_oversight_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA OVERSIGHT VIOLATION: authority records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_oversight_mutation
ON omnex_system_infrastructure.infra_oversight_framework;

CREATE TRIGGER trg_prevent_oversight_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_oversight_framework
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_oversight_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_oversight_framework
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_oversight
ON omnex_system_infrastructure.infra_oversight_framework;

CREATE POLICY deny_all_infra_oversight
ON omnex_system_infrastructure.infra_oversight_framework
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_oversight
ON omnex_system_infrastructure.infra_oversight_framework IS
'Infrastructure oversight frameworks are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_oversight_policy
ON omnex_system_infrastructure.infra_oversight_framework (policy_id);

CREATE INDEX IF NOT EXISTS idx_infra_oversight_type
ON omnex_system_infrastructure.infra_oversight_framework (oversight_type);

CREATE INDEX IF NOT EXISTS idx_infra_oversight_status
ON omnex_system_infrastructure.infra_oversight_framework (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 012
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_012
-- ENGINE NAME: Decision Emission Authority
-- ENGINE FUNCTION:
--   Emits binding, lawful infrastructure decisions to downstream
--   execution systems (ProjectOps), based on approved authority,
--   without performing execution itself.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — decision types and status are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Decision Emission Authority
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_decision (
    decision_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    decision_type text NOT NULL,             -- APPROVAL / SUSPENSION / TERMINATION / AUTHORIZATION
    subject_id uuid NOT NULL,                -- Project, asset, plan, or program reference

    legal_basis_id uuid NOT NULL,             -- Authoritative legal / policy reference
    decision_payload jsonb NOT NULL,          -- Binding instruction to execution plane

    decision_status text NOT NULL,            -- ISSUED / SUPERSEDED / REVOKED

    issued_at timestamptz NOT NULL DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_012'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_decision IS
'Authoritative emission of binding infrastructure decisions to execution systems (ProjectOps)';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Decision type non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_decision_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_decision
            ADD CONSTRAINT chk_infra_decision_type_nonempty
            CHECK (length(decision_type) > 0);
    END IF;
END $$;

-- Decision status non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_decision_status_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_decision
            ADD CONSTRAINT chk_infra_decision_status_nonempty
            CHECK (length(decision_status) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — decisions reference authority but do not depend on FK enforcement

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation (decisions are sovereign emissions)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_decision_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA DECISION VIOLATION: emitted decisions are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_decision_mutation
ON omnex_system_infrastructure.infra_decision;

CREATE TRIGGER trg_prevent_decision_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_decision
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_decision_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_decision
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_decision
ON omnex_system_infrastructure.infra_decision;

CREATE POLICY deny_all_infra_decision
ON omnex_system_infrastructure.infra_decision
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_decision
ON omnex_system_infrastructure.infra_decision IS
'Infrastructure decisions are emitted only by sovereign authority. No direct access permitted.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_decision_type
ON omnex_system_infrastructure.infra_decision (decision_type);

CREATE INDEX IF NOT EXISTS idx_infra_decision_subject
ON omnex_system_infrastructure.infra_decision (subject_id);

CREATE INDEX IF NOT EXISTS idx_infra_decision_status
ON omnex_system_infrastructure.infra_decision (decision_status);

CREATE INDEX IF NOT EXISTS idx_infra_decision_payload
ON omnex_system_infrastructure.infra_decision
USING GIN (decision_payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 012 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 013
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_013
-- ENGINE NAME: State & Epoch Binding Authority
-- ENGINE FUNCTION:
--   Binds Omnex_System_Infrastructure to national epochs and
--   records sovereign state transitions (activation, suspension)
--   under constitutional authority.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — system_state is authoritative data, not enum

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure State & Epoch Binding
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_state (
    infra_state_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    epoch_id uuid NOT NULL,              -- National / constitutional epoch reference
    system_state text NOT NULL,          -- ACTIVE / SUSPENDED / RETIRED

    activated_at timestamptz,
    suspended_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_013'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_state IS
'Authoritative binding of Omnex_System_Infrastructure to national epochs and system states';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- System state non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_state_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_state
            ADD CONSTRAINT chk_infra_state_nonempty
            CHECK (length(system_state) > 0);
    END IF;
END $$;

-- Temporal sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_state_temporal_order'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_state
            ADD CONSTRAINT chk_infra_state_temporal_order
            CHECK (
                suspended_at IS NULL
                OR activated_at IS NULL
                OR suspended_at > activated_at
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — epoch_id is referenced, not FK-enforced

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (state transitions are append-only)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_state_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA STATE VIOLATION: state bindings are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_state_mutation
ON omnex_system_infrastructure.infra_state;

CREATE TRIGGER trg_prevent_state_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_state
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_state_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_state
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_state
ON omnex_system_infrastructure.infra_state;

CREATE POLICY deny_all_infra_state
ON omnex_system_infrastructure.infra_state
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_state
ON omnex_system_infrastructure.infra_state IS
'Infrastructure state & epoch bindings are governed exclusively by sovereign authority';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_state_epoch
ON omnex_system_infrastructure.infra_state (epoch_id);

CREATE INDEX IF NOT EXISTS idx_infra_state_state
ON omnex_system_infrastructure.infra_state (system_state);

CREATE INDEX IF NOT EXISTS idx_infra_state_activated
ON omnex_system_infrastructure.infra_state (activated_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 013 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 014
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_014
-- ENGINE NAME: Public Transparency Projection Authority
-- ENGINE FUNCTION:
--   Publishes lawful, approved, and sealed infrastructure truth
--   snapshots for public disclosure, oversight, and trust.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — projection scope is authoritative data, not enum

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Public Transparency Projection
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_public_projection (
    projection_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    projection_scope text NOT NULL,           -- NATIONAL / SECTOR / ASSET_CLASS / PROJECT
    reference_object_id uuid NOT NULL,        -- Referenced authority object
    approved_snapshot_id uuid NOT NULL,       -- Approved & sealed snapshot reference

    published_at timestamptz NOT NULL DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_014'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_public_projection IS
'Authoritative registry of publishable infrastructure truth snapshots for transparency and public trust';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Projection scope non-empty
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_projection_scope_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_public_projection
            ADD CONSTRAINT chk_infra_projection_scope_nonempty
            CHECK (length(projection_scope) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — references are authoritative, not FK-enforced

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (published truth cannot be altered)
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_public_projection_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA PUBLIC PROJECTION VIOLATION: published projections are immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_public_projection_mutation
ON omnex_system_infrastructure.infra_public_projection;

CREATE TRIGGER trg_prevent_public_projection_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_public_projection
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_public_projection_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_public_projection
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_public_projection
ON omnex_system_infrastructure.infra_public_projection;

CREATE POLICY deny_all_infra_public_projection
ON omnex_system_infrastructure.infra_public_projection
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_public_projection
ON omnex_system_infrastructure.infra_public_projection IS
'Infrastructure public projections are centrally governed and published only via authority';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_projection_scope
ON omnex_system_infrastructure.infra_public_projection (projection_scope);

CREATE INDEX IF NOT EXISTS idx_infra_projection_reference
ON omnex_system_infrastructure.infra_public_projection (reference_object_id);

CREATE INDEX IF NOT EXISTS idx_infra_projection_published
ON omnex_system_infrastructure.infra_public_projection (published_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 014 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM INFRASTRUCTURE — ENGINE 015
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_012
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_INFRA
-- SYSTEM NAME: Omnex_System_Infrastructure

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_infrastructure

-- ENGINE NO: engine_015
-- ENGINE NAME: Audit Seal Authority
-- ENGINE FUNCTION:
--   Provides immutable cryptographic sealing of infrastructure
--   decisions, approvals, and authority artifacts for audit,
--   legal custody, and forensic reconstruction.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_infrastructure.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_infrastructure;
REVOKE ALL ON SCHEMA omnex_system_infrastructure FROM PUBLIC;

SET search_path = omnex_system_infrastructure, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — sealed object types are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Infrastructure Audit Seal Ledger
CREATE TABLE IF NOT EXISTS omnex_system_infrastructure.infra_audit_seal (
    seal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    sealed_object_type text NOT NULL,     -- DECISION / POLICY / PLAN / APPROVAL
    sealed_object_id uuid NOT NULL,       -- Authority object reference

    seal_hash text NOT NULL,              -- SHA256 or higher
    prior_hash text NULL,                 -- Hash chaining for custody

    sealed_at timestamptz NOT NULL DEFAULT now(),
    status text NOT NULL,                 -- ACTIVE / SUPERSEDED / REVOKED

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_015'
);

COMMENT ON TABLE omnex_system_infrastructure.infra_audit_seal IS
'Immutable audit seal ledger providing cryptographic custody and non-repudiation for infrastructure authority artifacts';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Seal hash must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_infra_seal_hash_nonempty'
    ) THEN
        ALTER TABLE omnex_system_infrastructure.infra_audit_seal
            ADD CONSTRAINT chk_infra_seal_hash_nonempty
            CHECK (length(seal_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — audit custody must never be FK-coupled

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of sealed audit records
CREATE OR REPLACE FUNCTION omnex_system_infrastructure.prevent_audit_seal_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'INFRA AUDIT SEAL VIOLATION: sealed records are immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_infra_audit_seal_mutation
ON omnex_system_infrastructure.infra_audit_seal;

CREATE TRIGGER trg_prevent_infra_audit_seal_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_infrastructure.infra_audit_seal
FOR EACH ROW
EXECUTE FUNCTION omnex_system_infrastructure.prevent_audit_seal_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_infrastructure.infra_audit_seal
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_infra_audit_seal
ON omnex_system_infrastructure.infra_audit_seal;

CREATE POLICY deny_all_infra_audit_seal
ON omnex_system_infrastructure.infra_audit_seal
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_infra_audit_seal
ON omnex_system_infrastructure.infra_audit_seal IS
'Infrastructure audit seals are governed exclusively by Audit and Core authority';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_infra_audit_seal_object
ON omnex_system_infrastructure.infra_audit_seal (sealed_object_type, sealed_object_id);

CREATE INDEX IF NOT EXISTS idx_infra_audit_seal_status
ON omnex_system_infrastructure.infra_audit_seal (status);

CREATE INDEX IF NOT EXISTS idx_infra_audit_seal_time
ON omnex_system_infrastructure.infra_audit_seal (sealed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 015 — OMNEX SYSTEM INFRASTRUCTURE
-- ============================================================
