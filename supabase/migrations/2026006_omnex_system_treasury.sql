-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_000
-- ENGINE NAME: Treasury Constitutional Ledger
-- ENGINE FUNCTION:
--   Canonical sovereign fiscal authority ledger declaring
--   lawful treasury instruments, fiscal mandates, budget authority,
--   public finance controls, and monetary governance anchors.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_treasury IS
'Omnex System Treasury — sovereign fiscal authority schema (ENGINE 000)';

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'treasury_record_type_enum'
          AND n.nspname = 'omnex_system_treasury'
    ) THEN
        CREATE TYPE omnex_system_treasury.treasury_record_type_enum AS ENUM (
            'FISCAL_INSTRUMENT',
            'BUDGET_AUTHORITY',
            'REVENUE_AUTHORITY',
            'EXPENDITURE_AUTHORITY',
            'DEBT_AUTHORITY',
            'GRANT_AUTHORITY',
            'SUBSIDY_AUTHORITY',
            'TREASURY_CONTROL',
            'FISCAL_CONSTRAINT',
            'AUDIT_ANCHOR'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_constitution_ledger (
    treasury_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    record_type omnex_system_treasury.treasury_record_type_enum NOT NULL,

    legal_ref text NOT NULL,
    authority_ref text NOT NULL,
    fiscal_domain text NOT NULL,

    title text NOT NULL,
    description text,

    effective_from timestamptz NOT NULL,
    effective_to   timestamptz,

    payload jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_treasury.treasury_constitution_ledger IS
'Immutable constitutional ledger declaring all sovereign fiscal authorities and treasury controls';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_effective_time'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_constitution_ledger
            ADD CONSTRAINT chk_treasury_effective_time
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_constitution_ledger
            ADD CONSTRAINT chk_treasury_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — Treasury is a sovereign authority root.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_treasury.compute_and_validate_treasury_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.record_type::text,'') ||
            coalesce(NEW.legal_ref,'') ||
            coalesce(NEW.authority_ref,'') ||
            coalesce(NEW.fiscal_domain,'') ||
            coalesce(NEW.payload::text,'') ||
            coalesce(NEW.payload_schema_version::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.checksum <> computed THEN
        RAISE EXCEPTION
            'TREASURY CHECKSUM VIOLATION: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_treasury_checksum
ON omnex_system_treasury.treasury_constitution_ledger;

CREATE TRIGGER trg_validate_treasury_checksum
BEFORE INSERT
ON omnex_system_treasury.treasury_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.compute_and_validate_treasury_checksum();

CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_treasury_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY CONSTITUTION VIOLATION: records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_treasury_mutation
ON omnex_system_treasury.treasury_constitution_ledger;

CREATE TRIGGER trg_prevent_treasury_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_treasury_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_constitution_ledger
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_constitution
ON omnex_system_treasury.treasury_constitution_ledger;

CREATE POLICY deny_all_treasury_constitution
ON omnex_system_treasury.treasury_constitution_ledger
FOR ALL
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_record_type
ON omnex_system_treasury.treasury_constitution_ledger (record_type);

CREATE INDEX IF NOT EXISTS idx_treasury_fiscal_domain
ON omnex_system_treasury.treasury_constitution_ledger (fiscal_domain);

CREATE INDEX IF NOT EXISTS idx_treasury_payload
ON omnex_system_treasury.treasury_constitution_ledger
USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM TREASURY
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_001
-- ENGINE NAME: Legal Instrument Authority
-- ENGINE FUNCTION:
--   Registers all fiscal legal instruments including Acts,
--   regulations, circulars, appropriations, and directives.
--   Enforces versioning, supersession, and cryptographic sealing.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_treasury IS
'Omnex System Treasury — sovereign fiscal authority schema';

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'treasury_instrument_type_enum'
          AND n.nspname = 'omnex_system_treasury'
    ) THEN
        CREATE TYPE omnex_system_treasury.treasury_instrument_type_enum AS ENUM (
            'CONSTITUTION',
            'ACT',
            'REGULATION',
            'APPROPRIATION',
            'CIRCULAR',
            'DIRECTIVE'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Legal Instrument Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_legal_instrument (
    instrument_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    instrument_type omnex_system_treasury.treasury_instrument_type_enum NOT NULL,
    instrument_code TEXT NOT NULL,
    title TEXT NOT NULL,

    issuing_authority TEXT NOT NULL,
    issued_date DATE NOT NULL,

    effective_from DATE NOT NULL,
    effective_to DATE,

    status TEXT NOT NULL
        CHECK (status IN ('DRAFT','ACTIVE','RETIRED','SUPERSEDED')),

    version INTEGER NOT NULL,
    supersedes_id UUID
        REFERENCES omnex_system_treasury.treasury_legal_instrument(instrument_id),

    sealed_hash TEXT NOT NULL,
    hash_algorithm TEXT NOT NULL DEFAULT 'SHA256',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_001'
);

COMMENT ON TABLE omnex_system_treasury.treasury_legal_instrument IS
'Authoritative registry of all treasury legal instruments with versioning, supersession, and cryptographic sealing';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_treasury_instrument_code'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_legal_instrument
            ADD CONSTRAINT uq_treasury_instrument_code
            UNIQUE (instrument_code, version);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_effective_dates'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_legal_instrument
            ADD CONSTRAINT chk_treasury_effective_dates
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Supersession is self-referential and legally enforced

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Compute and validate sealed hash
CREATE OR REPLACE FUNCTION omnex_system_treasury.compute_and_validate_instrument_hash()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed TEXT;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.instrument_code,'') ||
            coalesce(NEW.instrument_type::text,'') ||
            coalesce(NEW.title,'') ||
            coalesce(NEW.issuing_authority,'') ||
            coalesce(NEW.version::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.sealed_hash <> computed THEN
        RAISE EXCEPTION
            'TREASURY LEGAL INSTRUMENT VIOLATION: invalid sealed hash';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_treasury_instrument_hash
ON omnex_system_treasury.treasury_legal_instrument;

CREATE TRIGGER trg_validate_treasury_instrument_hash
BEFORE INSERT
ON omnex_system_treasury.treasury_legal_instrument
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.compute_and_validate_instrument_hash();

-- Prevent mutation of legal instruments
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_instrument_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY LEGAL INSTRUMENT VIOLATION: records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_instrument_mutation
ON omnex_system_treasury.treasury_legal_instrument;

CREATE TRIGGER trg_prevent_instrument_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_legal_instrument
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_instrument_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_legal_instrument
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_legal_instrument
ON omnex_system_treasury.treasury_legal_instrument;

CREATE POLICY deny_all_treasury_legal_instrument
ON omnex_system_treasury.treasury_legal_instrument
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_legal_instrument
ON omnex_system_treasury.treasury_legal_instrument IS
'All access to treasury legal instruments is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_instrument_code
ON omnex_system_treasury.treasury_legal_instrument (instrument_code);

CREATE INDEX IF NOT EXISTS idx_treasury_instrument_status
ON omnex_system_treasury.treasury_legal_instrument (status);

CREATE INDEX IF NOT EXISTS idx_treasury_instrument_effective
ON omnex_system_treasury.treasury_legal_instrument (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_002
-- ENGINE NAME: Fiscal Rule Authority
-- ENGINE FUNCTION:
--   Codifies fiscal rules, enforces legality gates,
--   and declares binding fiscal constraints across the state.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_treasury IS
'Omnex System Treasury — sovereign fiscal authority schema';

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'fiscal_enforcement_level_enum'
          AND n.nspname = 'omnex_system_treasury'
    ) THEN
        CREATE TYPE omnex_system_treasury.fiscal_enforcement_level_enum AS ENUM (
            'BLOCK',
            'WARN'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Fiscal Rule Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_fiscal_rule (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    rule_code TEXT NOT NULL,
    rule_scope TEXT NOT NULL,

    legal_basis_instrument_id UUID NOT NULL
        REFERENCES omnex_system_treasury.treasury_legal_instrument(instrument_id),

    enforcement_level omnex_system_treasury.fiscal_enforcement_level_enum NOT NULL,

    rule_logic_json JSONB NOT NULL,

    effective_from DATE NOT NULL,
    effective_to DATE,

    version INTEGER NOT NULL,

    status TEXT NOT NULL
        CHECK (status IN ('DRAFT','ACTIVE','RETIRED','SUPERSEDED')),

    sealed_hash TEXT NOT NULL,
    hash_algorithm TEXT NOT NULL DEFAULT 'SHA256',

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_002'
);

COMMENT ON TABLE omnex_system_treasury.treasury_fiscal_rule IS
'Authoritative registry of fiscal rules enforcing legality, ceilings, and constraints';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_treasury_fiscal_rule_code'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_fiscal_rule
            ADD CONSTRAINT uq_treasury_fiscal_rule_code
            UNIQUE (rule_code, version);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_fiscal_rule_effective_dates'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_fiscal_rule
            ADD CONSTRAINT chk_fiscal_rule_effective_dates
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Legal basis enforced via foreign key to treasury_legal_instrument

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Compute and validate fiscal rule seal
CREATE OR REPLACE FUNCTION omnex_system_treasury.compute_and_validate_fiscal_rule_hash()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed TEXT;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.rule_code,'') ||
            coalesce(NEW.rule_scope,'') ||
            coalesce(NEW.legal_basis_instrument_id::text,'') ||
            coalesce(NEW.enforcement_level::text,'') ||
            coalesce(NEW.rule_logic_json::text,'') ||
            coalesce(NEW.version::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.sealed_hash <> computed THEN
        RAISE EXCEPTION
            'TREASURY FISCAL RULE VIOLATION: invalid sealed hash';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_fiscal_rule_hash
ON omnex_system_treasury.treasury_fiscal_rule;

CREATE TRIGGER trg_validate_fiscal_rule_hash
BEFORE INSERT
ON omnex_system_treasury.treasury_fiscal_rule
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.compute_and_validate_fiscal_rule_hash();

-- Prevent mutation of fiscal rules
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_fiscal_rule_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY FISCAL RULE VIOLATION: records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_fiscal_rule_mutation
ON omnex_system_treasury.treasury_fiscal_rule;

CREATE TRIGGER trg_prevent_fiscal_rule_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_fiscal_rule
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_fiscal_rule_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_fiscal_rule
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_fiscal_rule
ON omnex_system_treasury.treasury_fiscal_rule;

CREATE POLICY deny_all_treasury_fiscal_rule
ON omnex_system_treasury.treasury_fiscal_rule
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_fiscal_rule
ON omnex_system_treasury.treasury_fiscal_rule IS
'All access to fiscal rules is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_fiscal_rule_code
ON omnex_system_treasury.treasury_fiscal_rule (rule_code);

CREATE INDEX IF NOT EXISTS idx_fiscal_rule_status
ON omnex_system_treasury.treasury_fiscal_rule (status);

CREATE INDEX IF NOT EXISTS idx_fiscal_rule_effective
ON omnex_system_treasury.treasury_fiscal_rule (effective_from, effective_to);

CREATE INDEX IF NOT EXISTS idx_fiscal_rule_logic
ON omnex_system_treasury.treasury_fiscal_rule
USING GIN (rule_logic_json);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 003
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_003
-- ENGINE NAME: Treasury Account Authority
-- ENGINE FUNCTION:
--   Defines sovereign treasury accounts, custody models,
--   ownership classification, and legal account authority.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_treasury IS
'Omnex System Treasury — sovereign fiscal authority schema';

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'treasury_account_type_enum'
          AND n.nspname = 'omnex_system_treasury'
    ) THEN
        CREATE TYPE omnex_system_treasury.treasury_account_type_enum AS ENUM (
            'CONSOLIDATED_FUND',
            'REVENUE_ACCOUNT',
            'EXPENDITURE_ACCOUNT',
            'ESCROW',
            'TRUST',
            'DEBT_SERVICE',
            'RESERVE',
            'SUSPENSE'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'treasury_custodian_type_enum'
          AND n.nspname = 'omnex_system_treasury'
    ) THEN
        CREATE TYPE omnex_system_treasury.treasury_custodian_type_enum AS ENUM (
            'CENTRAL_BANK',
            'COMMERCIAL_BANK',
            'TREASURY_INTERNAL',
            'EXTERNAL_AGENT'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Account Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_account (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    account_code TEXT NOT NULL,
    account_name TEXT NOT NULL,

    account_type omnex_system_treasury.treasury_account_type_enum NOT NULL,
    custodian_type omnex_system_treasury.treasury_custodian_type_enum NOT NULL,

    is_sovereign BOOLEAN NOT NULL DEFAULT true,

    status TEXT NOT NULL
        CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_003'
);

COMMENT ON TABLE omnex_system_treasury.treasury_account IS
'Authoritative registry of sovereign treasury accounts and custody definitions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_treasury_account_code'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_account
            ADD CONSTRAINT uq_treasury_account_code
            UNIQUE (account_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — treasury accounts are sovereign root entities

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of treasury accounts
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_treasury_account_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY ACCOUNT VIOLATION: account records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_treasury_account_mutation
ON omnex_system_treasury.treasury_account;

CREATE TRIGGER trg_prevent_treasury_account_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_account
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_treasury_account_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_account
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_account
ON omnex_system_treasury.treasury_account;

CREATE POLICY deny_all_treasury_account
ON omnex_system_treasury.treasury_account
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_account
ON omnex_system_treasury.treasury_account IS
'All access to treasury accounts is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_account_type
ON omnex_system_treasury.treasury_account (account_type);

CREATE INDEX IF NOT EXISTS idx_treasury_account_custodian
ON omnex_system_treasury.treasury_account (custodian_type);

CREATE INDEX IF NOT EXISTS idx_treasury_account_status
ON omnex_system_treasury.treasury_account (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 004
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_004
-- ENGINE NAME: Treasury Ledger Authority
-- ENGINE FUNCTION:
--   Defines canonical treasury ledgers as the authoritative
--   structural source of ledger identity, ownership, and currency truth.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_treasury IS
'Omnex System Treasury — sovereign fiscal authority schema';

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — ledger semantics are structural, not enumerated

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Ledger Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_ledger (
    ledger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    ledger_code TEXT NOT NULL,
    ledger_name TEXT NOT NULL,

    base_currency TEXT NOT NULL,
    owning_account_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_004'
);

COMMENT ON TABLE omnex_system_treasury.treasury_ledger IS
'Canonical treasury ledger registry defining authoritative ledger identity, ownership, and base currency';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_treasury_ledger_code'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_ledger
            ADD CONSTRAINT uq_treasury_ledger_code
            UNIQUE (ledger_code);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_treasury_ledger_account'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_ledger
            ADD CONSTRAINT fk_treasury_ledger_account
            FOREIGN KEY (owning_account_id)
            REFERENCES omnex_system_treasury.treasury_account(account_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Ledger → Treasury Account (sovereign ownership)
-- No downstream relationships permitted at authority layer

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of treasury ledgers
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_treasury_ledger_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY LEDGER VIOLATION: ledger records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_treasury_ledger_mutation
ON omnex_system_treasury.treasury_ledger;

CREATE TRIGGER trg_prevent_treasury_ledger_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_treasury_ledger_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_ledger
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_ledger
ON omnex_system_treasury.treasury_ledger;

CREATE POLICY deny_all_treasury_ledger
ON omnex_system_treasury.treasury_ledger
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_ledger
ON omnex_system_treasury.treasury_ledger IS
'All access to treasury ledgers is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_ledger_account
ON omnex_system_treasury.treasury_ledger (owning_account_id);

CREATE INDEX IF NOT EXISTS idx_treasury_ledger_currency
ON omnex_system_treasury.treasury_ledger (base_currency);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 005
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_005
-- ENGINE NAME: Value Instrument Authority
-- ENGINE FUNCTION:
--   Defines sovereign value instruments including currencies,
--   monetary instruments, and legal tender declarations.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — value instruments are sovereign declarations, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Value Instrument Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_value_instrument (
    instrument_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    instrument_code TEXT NOT NULL,
    instrument_type TEXT NOT NULL,

    currency_code TEXT NOT NULL,
    issuer_authority TEXT NOT NULL,

    is_legal_tender BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_005'
);

COMMENT ON TABLE omnex_system_treasury.treasury_value_instrument IS
'Authoritative registry of sovereign value instruments, currencies, and legal tender declarations';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_treasury_value_instrument_code'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_value_instrument
            ADD CONSTRAINT uq_treasury_value_instrument_code
            UNIQUE (instrument_code);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_currency_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_value_instrument
            ADD CONSTRAINT chk_currency_code_nonempty
            CHECK (length(currency_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- No foreign keys by design
-- Value instruments are sovereign primitives referenced by other authorities

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of value instruments
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_value_instrument_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'VALUE INSTRUMENT VIOLATION: value instruments are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_value_instrument_mutation
ON omnex_system_treasury.treasury_value_instrument;

CREATE TRIGGER trg_prevent_value_instrument_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_value_instrument
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_value_instrument_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_value_instrument
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_value_instrument
ON omnex_system_treasury.treasury_value_instrument;

CREATE POLICY deny_all_treasury_value_instrument
ON omnex_system_treasury.treasury_value_instrument
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_value_instrument
ON omnex_system_treasury.treasury_value_instrument IS
'All access to value instrument registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_value_instrument_currency
ON omnex_system_treasury.treasury_value_instrument (currency_code);

CREATE INDEX IF NOT EXISTS idx_value_instrument_legal_tender
ON omnex_system_treasury.treasury_value_instrument (is_legal_tender);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 006
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_006
-- ENGINE NAME: Budget Ceiling Authority
-- ENGINE FUNCTION:
--   Issues sovereign fiscal ceilings, vote limits, and sectoral
--   expenditure caps forming the legal upper bounds for spending.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — ceilings are sovereign fiscal declarations

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Budget Ceiling Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_ceiling (
    ceiling_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    fiscal_year INTEGER NOT NULL,
    vote_id UUID,

    ceiling_amount NUMERIC(18,2) NOT NULL,

    legal_basis_instrument_id UUID NOT NULL,

    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    status TEXT NOT NULL,

    sealed_hash TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_006'
);

COMMENT ON TABLE omnex_system_treasury.treasury_ceiling IS
'Authoritative registry of sovereign budget ceilings, vote limits, and fiscal caps';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_ceiling_amount_positive'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_ceiling
            ADD CONSTRAINT chk_ceiling_amount_positive
            CHECK (ceiling_amount >= 0);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_fiscal_year_reasonable'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_ceiling
            ADD CONSTRAINT chk_fiscal_year_reasonable
            CHECK (fiscal_year >= 2000);
    END IF;
END $$;

-- Prevent overlapping ceilings for same vote and fiscal year
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_vote_fiscal_year'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_ceiling
            ADD CONSTRAINT uq_vote_fiscal_year
            UNIQUE (vote_id, fiscal_year);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- legal_basis_instrument_id references treasury_legal_instrument
-- (not enforced here to preserve sovereign declaration independence)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability of budget ceilings
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_ceiling_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'BUDGET CEILING VIOLATION: fiscal ceilings are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_ceiling_mutation
ON omnex_system_treasury.treasury_ceiling;

CREATE TRIGGER trg_prevent_ceiling_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_ceiling
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_ceiling_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_ceiling
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_ceiling
ON omnex_system_treasury.treasury_ceiling;

CREATE POLICY deny_all_treasury_ceiling
ON omnex_system_treasury.treasury_ceiling
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_ceiling
ON omnex_system_treasury.treasury_ceiling IS
'All access to budget ceilings is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_ceiling_fiscal_year
ON omnex_system_treasury.treasury_ceiling (fiscal_year);

CREATE INDEX IF NOT EXISTS idx_treasury_ceiling_vote
ON omnex_system_treasury.treasury_ceiling (vote_id);

CREATE INDEX IF NOT EXISTS idx_treasury_ceiling_status
ON omnex_system_treasury.treasury_ceiling (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 007
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_007
-- ENGINE NAME: Budget Classification Authority
-- ENGINE FUNCTION:
--   Defines and governs canonical budget classification codes
--   (vote, program, economic, administrative) used uniformly
--   across planning, budgeting, execution, and reporting systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — classification types are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Budget Classification Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_classification_code (
    class_code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    class_type TEXT NOT NULL,              -- VOTE / PROGRAM / ECONOMIC / ADMIN
    class_code TEXT NOT NULL UNIQUE,
    class_name TEXT NOT NULL,

    parent_code_id UUID NULL,

    effective_from DATE NOT NULL,
    effective_to   DATE NULL,

    status TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_007'
);

COMMENT ON TABLE omnex_system_treasury.treasury_classification_code IS
'Authoritative registry of treasury budget classification codes and hierarchies';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Effective date sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_classification_effective_range'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_classification_code
            ADD CONSTRAINT chk_classification_effective_range
            CHECK (
                effective_to IS NULL
                OR effective_to > effective_from
            );
    END IF;
END $$;

-- Parent must not self-reference
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_no_self_parent'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_classification_code
            ADD CONSTRAINT chk_no_self_parent
            CHECK (parent_code_id IS NULL OR parent_code_id <> class_code_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

-- Hierarchical relationship (self-referencing)
ALTER TABLE omnex_system_treasury.treasury_classification_code
    ADD CONSTRAINT fk_parent_classification
    FOREIGN KEY (parent_code_id)
    REFERENCES omnex_system_treasury.treasury_classification_code (class_code_id)
    DEFERRABLE INITIALLY DEFERRED;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (append-only classification truth)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_classification_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'BUDGET CLASSIFICATION VIOLATION: classification codes are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_classification_mutation
ON omnex_system_treasury.treasury_classification_code;

CREATE TRIGGER trg_prevent_classification_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_classification_code
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_classification_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_classification_code
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_classification
ON omnex_system_treasury.treasury_classification_code;

CREATE POLICY deny_all_treasury_classification
ON omnex_system_treasury.treasury_classification_code
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_classification
ON omnex_system_treasury.treasury_classification_code IS
'All access to treasury classification codes is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_classification_type
ON omnex_system_treasury.treasury_classification_code (class_type);

CREATE INDEX IF NOT EXISTS idx_classification_parent
ON omnex_system_treasury.treasury_classification_code (parent_code_id);

CREATE INDEX IF NOT EXISTS idx_classification_status
ON omnex_system_treasury.treasury_classification_code (status);

CREATE INDEX IF NOT EXISTS idx_classification_effective
ON omnex_system_treasury.treasury_classification_code (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 008
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_008
-- ENGINE NAME: Fiscal Planning & Scenario Authority
-- ENGINE FUNCTION:
--   Establishes authoritative fiscal baselines, scenarios, and
--   approved fiscal plans used to guide budgeting, ceilings,
--   and execution systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — plan types and scenarios are governed as authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Fiscal Planning & Scenario Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_fiscal_plan (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    fiscal_year INTEGER NOT NULL,
    plan_type TEXT NOT NULL,              -- BASELINE / SCENARIO / MEDIUM_TERM / SUPPLEMENTARY
    scenario_name TEXT,

    approved_amount NUMERIC(20,2) NOT NULL,

    approval_id UUID NULL,                -- Governance / approval reference

    effective_from DATE NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_008'
);

COMMENT ON TABLE omnex_system_treasury.treasury_fiscal_plan IS
'Authoritative fiscal plans and scenario baselines governing national budgeting and execution';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Fiscal year sanity
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_fiscal_plan_year'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_fiscal_plan
            ADD CONSTRAINT chk_fiscal_plan_year
            CHECK (fiscal_year >= 1900);
    END IF;
END $$;

-- Scenario naming required for scenario plans
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_scenario_name_required'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_fiscal_plan
            ADD CONSTRAINT chk_scenario_name_required
            CHECK (
                plan_type <> 'SCENARIO'
                OR scenario_name IS NOT NULL
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Approval references resolved via Governance system (no FK by design)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (plans are append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_fiscal_plan_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FISCAL PLAN VIOLATION: fiscal plans are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_fiscal_plan_mutation
ON omnex_system_treasury.treasury_fiscal_plan;

CREATE TRIGGER trg_prevent_fiscal_plan_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_fiscal_plan
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_fiscal_plan_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_fiscal_plan
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_fiscal_plan
ON omnex_system_treasury.treasury_fiscal_plan;

CREATE POLICY deny_all_treasury_fiscal_plan
ON omnex_system_treasury.treasury_fiscal_plan
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_fiscal_plan
ON omnex_system_treasury.treasury_fiscal_plan IS
'All access to fiscal plans is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_fiscal_plan_year
ON omnex_system_treasury.treasury_fiscal_plan (fiscal_year);

CREATE INDEX IF NOT EXISTS idx_fiscal_plan_type
ON omnex_system_treasury.treasury_fiscal_plan (plan_type);

CREATE INDEX IF NOT EXISTS idx_fiscal_plan_effective
ON omnex_system_treasury.treasury_fiscal_plan (effective_from);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 009
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_009
-- ENGINE NAME: Allocation Authority
-- ENGINE FUNCTION:
--   Declares lawful fiscal allocations between sovereign accounts,
--   programs, or purposes. Allocations authorize movement intent
--   but do not execute transactions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — allocation purpose and constraints are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Allocation Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_allocation (
    allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_account_id UUID NOT NULL,
    target_account_id UUID NOT NULL,

    instrument_id UUID NOT NULL,              -- currency / value instrument

    allocation_purpose TEXT NOT NULL,
    allocation_amount NUMERIC(20,2) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_009'
);

COMMENT ON TABLE omnex_system_treasury.treasury_allocation IS
'Authoritative allocation declarations defining lawful fiscal intent between accounts';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Prevent self-allocation
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_allocation_accounts_distinct'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_allocation
            ADD CONSTRAINT chk_allocation_accounts_distinct
            CHECK (source_account_id <> target_account_id);
    END IF;
END $$;

-- Amount must be positive
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_allocation_amount_positive'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_allocation
            ADD CONSTRAINT chk_allocation_amount_positive
            CHECK (allocation_amount > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Referential integrity enforced logically:
-- - Accounts via Engine 003 (Treasury Account Authority)
-- - Instruments via Engine 005 (Value Instrument Authority)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (allocations are append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_allocation_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'ALLOCATION VIOLATION: allocation records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_allocation_mutation
ON omnex_system_treasury.treasury_allocation;

CREATE TRIGGER trg_prevent_allocation_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_allocation
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_allocation_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_allocation
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_allocation
ON omnex_system_treasury.treasury_allocation;

CREATE POLICY deny_all_treasury_allocation
ON omnex_system_treasury.treasury_allocation
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_allocation
ON omnex_system_treasury.treasury_allocation IS
'All access to allocation authority is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_allocation_source_account
ON omnex_system_treasury.treasury_allocation (source_account_id);

CREATE INDEX IF NOT EXISTS idx_allocation_target_account
ON omnex_system_treasury.treasury_allocation (target_account_id);

CREATE INDEX IF NOT EXISTS idx_allocation_instrument
ON omnex_system_treasury.treasury_allocation (instrument_id);

CREATE INDEX IF NOT EXISTS idx_allocation_created_at
ON omnex_system_treasury.treasury_allocation (created_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 010
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_010
-- ENGINE NAME: Reserve & Constraint Authority
-- ENGINE FUNCTION:
--   Declares and enforces sovereign reserve requirements,
--   fiscal constraints, and legality limits applicable to
--   treasury accounts. Constraints authorize boundaries
--   but do not execute enforcement actions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — constraint semantics are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Reserve & Constraint Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_constraint (
    constraint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    account_id UUID NOT NULL,

    constraint_type TEXT NOT NULL,          -- e.g. MIN_RESERVE, MAX_EXPOSURE, LEGAL_LOCK
    constraint_value NUMERIC(20,4) NOT NULL,

    legal_basis TEXT NOT NULL,               -- reference to legal instrument / rule

    effective_from TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_010'
);

COMMENT ON TABLE omnex_system_treasury.treasury_constraint IS
'Authoritative reserve and constraint declarations enforcing fiscal legality boundaries';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Constraint value must be non-negative
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_constraint_value_nonnegative'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_constraint
            ADD CONSTRAINT chk_constraint_value_nonnegative
            CHECK (constraint_value >= 0);
    END IF;
END $$;

-- Effective date must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_constraint_effective_from_required'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_constraint
            ADD CONSTRAINT chk_constraint_effective_from_required
            CHECK (effective_from IS NOT NULL);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Logical references only:
-- - account_id → Treasury Account Authority (ENGINE 003)
-- - legal_basis → Treasury Legal Instrument / Fiscal Rule

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (constraints are append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_constraint_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'CONSTRAINT VIOLATION: treasury constraints are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_constraint_mutation
ON omnex_system_treasury.treasury_constraint;

CREATE TRIGGER trg_prevent_constraint_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_constraint
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_constraint_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_constraint
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_constraint
ON omnex_system_treasury.treasury_constraint;

CREATE POLICY deny_all_treasury_constraint
ON omnex_system_treasury.treasury_constraint
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_constraint
ON omnex_system_treasury.treasury_constraint IS
'All access to reserve and constraint authority is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_constraint_account
ON omnex_system_treasury.treasury_constraint (account_id);

CREATE INDEX IF NOT EXISTS idx_constraint_type
ON omnex_system_treasury.treasury_constraint (constraint_type);

CREATE INDEX IF NOT EXISTS idx_constraint_effective_from
ON omnex_system_treasury.treasury_constraint (effective_from);

CREATE INDEX IF NOT EXISTS idx_constraint_created_at
ON omnex_system_treasury.treasury_constraint (created_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 011
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_011
-- ENGINE NAME: Delegation of Authority (DoA)
-- ENGINE FUNCTION:
--   Declares who may approve what, under which scope and thresholds,
--   enforcing segregation-of-duties and approval limits as
--   authoritative fiscal law (non-executing).

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

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
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — DoA semantics are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Delegation of Authority Matrix
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_delegation_matrix (
    doa_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    role_code TEXT NOT NULL,                  -- e.g. PS_TREASURY, CFO, ACCOUNTING_OFFICER
    action_type TEXT NOT NULL,                -- e.g. APPROVE_ALLOCATION, AUTHORIZE_PAYMENT
    scope TEXT NOT NULL,                      -- e.g. PROGRAM, VOTE, ACCOUNT, INSTRUMENT

    threshold_amount NUMERIC(20,4),            -- NULL = no monetary threshold
    conditions_json JSONB,                     -- additional conditions / SoD constraints

    legal_basis_instrument_id UUID NOT NULL,   -- FK to Treasury Legal Instrument Authority

    effective_from TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL,                      -- ACTIVE / SUSPENDED / REVOKED

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_011'
);

COMMENT ON TABLE omnex_system_treasury.treasury_delegation_matrix IS
'Authoritative Delegation of Authority matrix defining approval rights, thresholds, and segregation-of-duties rules';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Threshold must be non-negative when provided
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_doa_threshold_nonnegative'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_delegation_matrix
            ADD CONSTRAINT chk_doa_threshold_nonnegative
            CHECK (threshold_amount IS NULL OR threshold_amount >= 0);
    END IF;
END $$;

-- Status must be present
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_doa_status_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_delegation_matrix
            ADD CONSTRAINT chk_doa_status_nonempty
            CHECK (length(status) > 0);
    END IF;
END $$;

-- Effective date required
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_doa_effective_from_required'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_delegation_matrix
            ADD CONSTRAINT chk_doa_effective_from_required
            CHECK (effective_from IS NOT NULL);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Logical (constitutional) references only:
-- - role_code → Omnex_System_Identity (roles)
-- - legal_basis_instrument_id → Treasury Legal Instrument Authority (ENGINE 001)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce immutability (DoA is append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_doa_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'DELEGATION OF AUTHORITY VIOLATION: DoA records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_doa_mutation
ON omnex_system_treasury.treasury_delegation_matrix;

CREATE TRIGGER trg_prevent_doa_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_delegation_matrix
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_doa_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_delegation_matrix
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_doa
ON omnex_system_treasury.treasury_delegation_matrix;

CREATE POLICY deny_all_treasury_doa
ON omnex_system_treasury.treasury_delegation_matrix
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_doa
ON omnex_system_treasury.treasury_delegation_matrix IS
'Delegation of Authority is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_doa_role_code
ON omnex_system_treasury.treasury_delegation_matrix (role_code);

CREATE INDEX IF NOT EXISTS idx_doa_action_type
ON omnex_system_treasury.treasury_delegation_matrix (action_type);

CREATE INDEX IF NOT EXISTS idx_doa_scope
ON omnex_system_treasury.treasury_delegation_matrix (scope);

CREATE INDEX IF NOT EXISTS idx_doa_effective_from
ON omnex_system_treasury.treasury_delegation_matrix (effective_from);

CREATE INDEX IF NOT EXISTS idx_doa_status
ON omnex_system_treasury.treasury_delegation_matrix (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 012
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_012
-- ENGINE NAME: Governance Approval Authority
-- ENGINE FUNCTION:
--   Captures authoritative approval decisions, signatures,
--   and rejection reasons for treasury-governed actions,
--   forming the legal approval evidence layer.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — approval semantics are authoritative data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Governance Approval Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_governance_approval (
    governance_approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    approval_type TEXT NOT NULL,            -- e.g. BUDGET_APPROVAL, ALLOCATION_APPROVAL
    subject_id UUID NOT NULL,               -- ID of governed object (allocation, plan, ceiling)

    approver_role TEXT NOT NULL,             -- Role acting under DoA
    approver_user_id UUID NOT NULL,          -- Identity user reference

    decision TEXT NOT NULL,                  -- APPROVED / REJECTED / ESCALATED
    decided_at TIMESTAMPTZ NOT NULL,

    decision_reason TEXT,                    -- Mandatory for rejection
    signature_ref TEXT,                     -- Cryptographic / external signature reference

    sealed_hash TEXT NOT NULL,               -- Integrity seal of approval payload

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_012'
);

COMMENT ON TABLE omnex_system_treasury.treasury_governance_approval IS
'Authoritative record of treasury governance approvals, rejections, and signatures';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Decision must be present
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_approval_decision_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_governance_approval
            ADD CONSTRAINT chk_treasury_approval_decision_nonempty
            CHECK (length(decision) > 0);
    END IF;
END $$;

-- Rejection must include a reason
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_rejection_requires_reason'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_governance_approval
            ADD CONSTRAINT chk_treasury_rejection_requires_reason
            CHECK (
                decision <> 'REJECTED'
                OR (decision_reason IS NOT NULL AND length(decision_reason) > 0)
            );
    END IF;
END $$;

-- Seal must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_approval_sealed_hash'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_governance_approval
            ADD CONSTRAINT chk_treasury_approval_sealed_hash
            CHECK (length(sealed_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Constitutional references only:
-- approver_user_id → Omnex_System_Identity
-- approver_role → Treasury Delegation of Authority (ENGINE 011)
-- subject_id → governed treasury authority objects

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of approval records
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_governance_approval_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'GOVERNANCE APPROVAL VIOLATION: approval records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_governance_approval_mutation
ON omnex_system_treasury.treasury_governance_approval;

CREATE TRIGGER trg_prevent_governance_approval_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_governance_approval
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_governance_approval_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_governance_approval
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_governance_approval
ON omnex_system_treasury.treasury_governance_approval;

CREATE POLICY deny_all_treasury_governance_approval
ON omnex_system_treasury.treasury_governance_approval
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_governance_approval
ON omnex_system_treasury.treasury_governance_approval IS
'Governance approvals are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_approval_type
ON omnex_system_treasury.treasury_governance_approval (approval_type);

CREATE INDEX IF NOT EXISTS idx_treasury_approval_subject
ON omnex_system_treasury.treasury_governance_approval (subject_id);

CREATE INDEX IF NOT EXISTS idx_treasury_approval_role
ON omnex_system_treasury.treasury_governance_approval (approver_role);

CREATE INDEX IF NOT EXISTS idx_treasury_approval_user
ON omnex_system_treasury.treasury_governance_approval (approver_user_id);

CREATE INDEX IF NOT EXISTS idx_treasury_approval_decision
ON omnex_system_treasury.treasury_governance_approval (decision);

CREATE INDEX IF NOT EXISTS idx_treasury_approval_decided_at
ON omnex_system_treasury.treasury_governance_approval (decided_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 012 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 013
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_013
-- ENGINE NAME: Decision Emission Authority
-- ENGINE FUNCTION:
--   Emits binding sovereign treasury decisions to the execution plane
--   after legal basis validation and governance approval, forming the
--   final authoritative decision contract.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — decision semantics are authoritative data, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Decision Emission Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_decision (
    decision_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    decision_type TEXT NOT NULL,                     -- e.g. ALLOCATION_DECISION, RELEASE_DECISION
    decision_subject_id UUID NOT NULL,               -- Allocation, ceiling, plan, etc.

    legal_basis_instrument_id UUID NOT NULL,         -- FK to treasury_legal_instrument
    governance_approval_id UUID NOT NULL,            -- FK to treasury_governance_approval

    decision_payload_json JSONB NOT NULL,            -- Machine-readable execution contract
    decision_status TEXT NOT NULL,                   -- EMITTED / SUPERSEDED / REVOKED

    emitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    sealed_hash TEXT NOT NULL,                       -- Cryptographic seal of decision content

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_013'
);

COMMENT ON TABLE omnex_system_treasury.treasury_decision IS
'Authoritative sovereign decision emission ledger for treasury actions, binding on execution systems';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- Decision type must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_decision_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_decision
            ADD CONSTRAINT chk_treasury_decision_type_nonempty
            CHECK (length(decision_type) > 0);
    END IF;
END $$;

-- Decision status must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_decision_status_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_decision
            ADD CONSTRAINT chk_treasury_decision_status_nonempty
            CHECK (length(decision_status) > 0);
    END IF;
END $$;

-- Payload must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_decision_payload_present'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_decision
            ADD CONSTRAINT chk_treasury_decision_payload_present
            CHECK (decision_payload_json IS NOT NULL);
    END IF;
END $$;

-- Seal must exist
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_decision_sealed_hash'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_decision
            ADD CONSTRAINT chk_treasury_decision_sealed_hash
            CHECK (length(sealed_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Constitutional references only:
-- legal_basis_instrument_id → treasury_legal_instrument (ENGINE 001)
-- governance_approval_id → treasury_governance_approval (ENGINE 012)
-- decision_subject_id → governed authority objects (allocation, ceiling, plan, etc.)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of emitted decisions
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_decision_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY DECISION VIOLATION: emitted decisions are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_decision_mutation
ON omnex_system_treasury.treasury_decision;

CREATE TRIGGER trg_prevent_decision_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_decision
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_decision_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_decision
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_decision
ON omnex_system_treasury.treasury_decision;

CREATE POLICY deny_all_treasury_decision
ON omnex_system_treasury.treasury_decision
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_decision
ON omnex_system_treasury.treasury_decision IS
'Decision emission is centrally governed. Execution systems may only consume via authorized interfaces.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_decision_type
ON omnex_system_treasury.treasury_decision (decision_type);

CREATE INDEX IF NOT EXISTS idx_treasury_decision_subject
ON omnex_system_treasury.treasury_decision (decision_subject_id);

CREATE INDEX IF NOT EXISTS idx_treasury_decision_status
ON omnex_system_treasury.treasury_decision (decision_status);

CREATE INDEX IF NOT EXISTS idx_treasury_decision_emitted_at
ON omnex_system_treasury.treasury_decision (emitted_at);

CREATE INDEX IF NOT EXISTS idx_treasury_decision_payload
ON omnex_system_treasury.treasury_decision
USING GIN (decision_payload_json);

COMMIT;

-- ============================================================
-- END OF ENGINE 013 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 014
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_014
-- ENGINE NAME: Lifecycle & Epoch Binding Authority
-- ENGINE FUNCTION:
--   Binds the Treasury Authority system state to constitutional epochs,
--   enforcing lawful activation, suspension, and sealing across time.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — lifecycle states are authoritative records, not enums

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Lifecycle & Epoch Binding
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_state (
    treasury_state_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    epoch_id UUID NOT NULL,                -- FK to Omnex System Core epoch registry
    system_state TEXT NOT NULL,            -- INITIALIZED / ACTIVE / SUSPENDED / SEALED

    activated_at TIMESTAMPTZ,
    suspended_at TIMESTAMPTZ,
    sealed_at TIMESTAMPTZ,

    sealed_hash TEXT,                      -- Cryptographic seal at finalization

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT NOT NULL DEFAULT 'ENGINE_014'
);

COMMENT ON TABLE omnex_system_treasury.treasury_state IS
'Constitutional lifecycle ledger binding Treasury Authority to epochs and lawful state transitions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

-- System state must be present
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_state_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_state
            ADD CONSTRAINT chk_treasury_state_nonempty
            CHECK (length(system_state) > 0);
    END IF;
END $$;

-- Seal requires timestamp and hash
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_treasury_state_seal_integrity'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_state
            ADD CONSTRAINT chk_treasury_state_seal_integrity
            CHECK (
                sealed_at IS NULL
                OR (sealed_at IS NOT NULL AND sealed_hash IS NOT NULL)
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- epoch_id → Omnex System Core epoch authority (ENGINE 000)
-- No downstream dependencies — this is a terminal authority binding

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of lifecycle records
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_treasury_state_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY STATE VIOLATION: lifecycle records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_treasury_state_mutation
ON omnex_system_treasury.treasury_state;

CREATE TRIGGER trg_prevent_treasury_state_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_state
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_treasury_state_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_state
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_state
ON omnex_system_treasury.treasury_state;

CREATE POLICY deny_all_treasury_state
ON omnex_system_treasury.treasury_state
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_state
ON omnex_system_treasury.treasury_state IS
'Treasury lifecycle state is constitutionally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_treasury_state_epoch
ON omnex_system_treasury.treasury_state (epoch_id);

CREATE INDEX IF NOT EXISTS idx_treasury_state_system_state
ON omnex_system_treasury.treasury_state (system_state);

CREATE INDEX IF NOT EXISTS idx_treasury_state_created_at
ON omnex_system_treasury.treasury_state (created_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 014 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 015
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_015
-- ENGINE NAME: Transparency & Public Trust Authority
-- ENGINE FUNCTION:
--   Defines lawful, approved, and publishable treasury truth snapshots
--   for public disclosure, oversight, and trust assurance.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — projection scope is authority data, not enum

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Public Projection Authority
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_public_projection (
    projection_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    projection_scope text NOT NULL,
    reference_object_id uuid NOT NULL,

    approved_snapshot_id uuid NOT NULL,
    governance_approval_id uuid,

    published_at timestamptz NOT NULL DEFAULT now(),

    sealed_hash text NOT NULL,
    hash_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_015'
);

COMMENT ON TABLE omnex_system_treasury.treasury_public_projection IS
'Authority registry defining lawful, approved, and publishable treasury truth snapshots for public disclosure';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_projection_scope_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_public_projection
            ADD CONSTRAINT chk_projection_scope_nonempty
            CHECK (length(projection_scope) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_projection_sealed_hash_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_public_projection
            ADD CONSTRAINT chk_projection_sealed_hash_nonempty
            CHECK (length(sealed_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Intentionally none.
-- Projection authority references approved truth but does not depend on execution tables.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Validate projection seal
CREATE OR REPLACE FUNCTION omnex_system_treasury.validate_projection_seal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.projection_scope,'') ||
            coalesce(NEW.reference_object_id::text,'') ||
            coalesce(NEW.approved_snapshot_id::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.sealed_hash <> computed THEN
        RAISE EXCEPTION
            'TREASURY PROJECTION SEAL VIOLATION: invalid sealed hash';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_projection_seal
ON omnex_system_treasury.treasury_public_projection;

CREATE TRIGGER trg_validate_projection_seal
BEFORE INSERT
ON omnex_system_treasury.treasury_public_projection
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.validate_projection_seal();

-- Prevent mutation (append-only authority)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_projection_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY TRANSPARENCY AUTHORITY VIOLATION: projections are immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_projection_mutation
ON omnex_system_treasury.treasury_public_projection;

CREATE TRIGGER trg_prevent_projection_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_public_projection
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_projection_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_public_projection
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_public_projection
ON omnex_system_treasury.treasury_public_projection;

CREATE POLICY deny_all_treasury_public_projection
ON omnex_system_treasury.treasury_public_projection
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_public_projection
ON omnex_system_treasury.treasury_public_projection IS
'All treasury public projections are governed centrally. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_projection_scope
ON omnex_system_treasury.treasury_public_projection (projection_scope);

CREATE INDEX IF NOT EXISTS idx_projection_reference_object
ON omnex_system_treasury.treasury_public_projection (reference_object_id);

CREATE INDEX IF NOT EXISTS idx_projection_published_at
ON omnex_system_treasury.treasury_public_projection (published_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 015 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 016
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_016
-- ENGINE NAME: Sovereign Reality Projection Authority
-- ENGINE FUNCTION:
--   Provides a read-only, cryptographically sealed, near-real-time
--   projection of sovereign financial reality for executive visibility,
--   intelligence consumption, and lawful situational awareness.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — reality projection semantics are data-driven

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Sovereign Reality Read Model
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_reality_view (
    view_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    account_id uuid NOT NULL,
    instrument_id uuid NOT NULL,

    current_balance numeric(24,6) NOT NULL,

    budget_reference_id uuid,

    last_verified_at timestamptz NOT NULL,

    sealed_hash text NOT NULL,
    hash_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_016'
);

COMMENT ON TABLE omnex_system_treasury.treasury_reality_view IS
'Read-only sovereign reality projection providing authoritative financial truth snapshots for executive and intelligence use';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_reality_balance_nonnegative'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_reality_view
            ADD CONSTRAINT chk_reality_balance_nonnegative
            CHECK (current_balance >= 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_reality_sealed_hash_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_reality_view
            ADD CONSTRAINT chk_reality_sealed_hash_nonempty
            CHECK (length(sealed_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None by design.
-- Reality view references authority truth but remains decoupled
-- to preserve read-plane sovereignty.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Validate sovereign reality seal
CREATE OR REPLACE FUNCTION omnex_system_treasury.validate_reality_view_seal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.account_id::text,'') ||
            coalesce(NEW.instrument_id::text,'') ||
            coalesce(NEW.current_balance::text,'') ||
            coalesce(NEW.budget_reference_id::text,'') ||
            coalesce(NEW.last_verified_at::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.sealed_hash <> computed THEN
        RAISE EXCEPTION
            'TREASURY REALITY VIEW VIOLATION: invalid sealed hash';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_reality_view_seal
ON omnex_system_treasury.treasury_reality_view;

CREATE TRIGGER trg_validate_reality_view_seal
BEFORE INSERT
ON omnex_system_treasury.treasury_reality_view
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.validate_reality_view_seal();

-- Prevent mutation (strict read model)
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_reality_view_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY REALITY VIEW VIOLATION: read models are immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_reality_view_mutation
ON omnex_system_treasury.treasury_reality_view;

CREATE TRIGGER trg_prevent_reality_view_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_reality_view
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_reality_view_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_reality_view
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_reality_view
ON omnex_system_treasury.treasury_reality_view;

CREATE POLICY deny_all_treasury_reality_view
ON omnex_system_treasury.treasury_reality_view
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_reality_view
ON omnex_system_treasury.treasury_reality_view IS
'Reality projections are sovereign truth. Access only via controlled executive channels.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_reality_account
ON omnex_system_treasury.treasury_reality_view (account_id);

CREATE INDEX IF NOT EXISTS idx_reality_instrument
ON omnex_system_treasury.treasury_reality_view (instrument_id);

CREATE INDEX IF NOT EXISTS idx_reality_verified_at
ON omnex_system_treasury.treasury_reality_view (last_verified_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 016 — OMNEX SYSTEM TREASURY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM TREASURY — ENGINE 017
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_006
-- SYSTEM ID: 2026006
-- SYSTEM CODE: OS_TR
-- SYSTEM NAME: Omnex_System_Treasury

-- CATEGORY ID: C_AS_2026002
-- CATEGORY CODE: OS_AUTH
-- CATEGORY NAME: Omnex_System_Authority

-- SCHEMA: omnex_system_treasury

-- ENGINE NO: engine_017
-- ENGINE NAME: Audit Seal Authority
-- ENGINE FUNCTION:
--   Provides immutable cryptographic sealing, custody chaining,
--   and evidentiary integrity for all sovereign treasury artefacts.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026006_omnex_system_treasury.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_treasury;
REVOKE ALL ON SCHEMA omnex_system_treasury FROM PUBLIC;

SET search_path = omnex_system_treasury, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — sealed object types are authority data

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Treasury Audit Seal Ledger
CREATE TABLE IF NOT EXISTS omnex_system_treasury.treasury_audit_seal (
    seal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    sealed_object_type text NOT NULL,
    sealed_object_id uuid NOT NULL,

    seal_hash text NOT NULL,
    prior_hash text,

    sealed_at timestamptz NOT NULL DEFAULT now(),
    sealed_by text NOT NULL,

    status text NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_017'
);

COMMENT ON TABLE omnex_system_treasury.treasury_audit_seal IS
'Immutable audit seal ledger providing cryptographic evidence, custody chaining, and non-repudiation for all treasury authority artefacts';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_seal_hash_nonempty'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_audit_seal
            ADD CONSTRAINT chk_audit_seal_hash_nonempty
            CHECK (length(seal_hash) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_seal_status_valid'
    ) THEN
        ALTER TABLE omnex_system_treasury.treasury_audit_seal
            ADD CONSTRAINT chk_audit_seal_status_valid
            CHECK (status IN ('SEALED','SUPERSEDED','REVOKED'));
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None by design.
-- Audit seals reference artefacts across engines without foreign key coupling
-- to preserve cross-system evidentiary independence.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of sealed evidence
CREATE OR REPLACE FUNCTION omnex_system_treasury.prevent_audit_seal_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'TREASURY AUDIT SEAL VIOLATION: sealed evidence is immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_audit_seal_mutation
ON omnex_system_treasury.treasury_audit_seal;

CREATE TRIGGER trg_prevent_audit_seal_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_treasury.treasury_audit_seal
FOR EACH ROW
EXECUTE FUNCTION omnex_system_treasury.prevent_audit_seal_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_treasury.treasury_audit_seal
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_treasury_audit_seal
ON omnex_system_treasury.treasury_audit_seal;

CREATE POLICY deny_all_treasury_audit_seal
ON omnex_system_treasury.treasury_audit_seal
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_treasury_audit_seal
ON omnex_system_treasury.treasury_audit_seal IS
'Audit seals are sovereign evidence. Access only via court-grade, regulator-grade channels.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_audit_seal_object
ON omnex_system_treasury.treasury_audit_seal (sealed_object_type, sealed_object_id);

CREATE INDEX IF NOT EXISTS idx_audit_seal_status
ON omnex_system_treasury.treasury_audit_seal (status);

CREATE INDEX IF NOT EXISTS idx_audit_seal_sealed_at
ON omnex_system_treasury.treasury_audit_seal (sealed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 017 — OMNEX SYSTEM TREASURY
-- ============================================================
