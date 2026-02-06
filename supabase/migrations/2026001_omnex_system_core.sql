-- ============================================================
-- OMNEX SYSTEM CORE — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_000
-- ENGINE NAME: Omnex System Core Runtime Engine
-- ENGINE FUNCTION:
--  Constitutional runtime ledger for the Omnex System-of-Systems.

-- VERSION: v1.1
-- STATUS: Final
-- FILE: 2026001_engine_000_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_core IS
'Omnex System Core — sovereign constitutional runtime schema (ENGINE 000)';

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'record_type_enum'
          AND n.nspname = 'omnex_system_core'
    ) THEN
        CREATE TYPE omnex_system_core.record_type_enum AS ENUM (
            'SYSTEM_CORE',
            'SYSTEM_IDENTITY',
            'SYSTEM_GOVERNANCE',
            'AUTHORITY_SYSTEM',
            'OPS_ENABLEMENT',
            'ECONOMIC_RAIL',
            'ORCHESTRATION',
            'SMARTTECH_SYSTEM',
            'ESCALATION',
            'SYSTEM_SUSPENSION',
            'AUDIT_SEAL',
            'SYSTEM_ADMISSION'
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'system_status_enum'
          AND n.nspname = 'omnex_system_core'
    ) THEN
        CREATE TYPE omnex_system_core.system_status_enum AS ENUM (
            'ACTIVE',
            'SUSPENDED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.core_system_init (
    core_id uuid PRIMARY KEY,

    record_type omnex_system_core.record_type_enum NOT NULL,

    system_code   text NOT NULL,
    category_code text NOT NULL,

    authority_ref text,
    ops_ref       text,
    scope_ref     text,

    status         omnex_system_core.system_status_enum NOT NULL,
    effective_from timestamptz,
    effective_to   timestamptz,

    payload jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_core.core_system_init IS
'ENGINE 000 canonical runtime ledger — sole authoritative store for all Omnex systems';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_system_core_fields'
    ) THEN
        ALTER TABLE omnex_system_core.core_system_init
            ADD CONSTRAINT chk_system_core_fields
            CHECK (
                record_type <> 'SYSTEM_CORE'
                OR (
                    system_code = 'OS_CORE'
                    AND category_code = 'OS_CF'
                    AND effective_from IS NOT NULL
                )
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_ops_requires_authority'
    ) THEN
        ALTER TABLE omnex_system_core.core_system_init
            ADD CONSTRAINT chk_ops_requires_authority
            CHECK (
                record_type <> 'OPS_ENABLEMENT'
                OR (ops_ref IS NOT NULL AND authority_ref IS NOT NULL)
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_effective_time_range'
    ) THEN
        ALTER TABLE omnex_system_core.core_system_init
            ADD CONSTRAINT chk_effective_time_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None by constitutional design

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

CREATE OR REPLACE FUNCTION omnex_system_core.compute_and_validate_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.system_code,'') ||
            coalesce(NEW.category_code,'') ||
            coalesce(NEW.record_type::text,'') ||
            coalesce(NEW.payload::text,'') ||
            coalesce(NEW.payload_schema_version::text,''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.checksum <> computed THEN
        RAISE EXCEPTION
            'ENGINE_000 CHECKSUM VIOLATION: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_checksum
ON omnex_system_core.core_system_init;

CREATE TRIGGER trg_validate_checksum
BEFORE INSERT
ON omnex_system_core.core_system_init
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.compute_and_validate_checksum();

CREATE OR REPLACE FUNCTION omnex_system_core.prevent_core_id_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.core_id <> NEW.core_id THEN
        RAISE EXCEPTION 'ENGINE_000 VIOLATION: core_id is immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_core_id_update
ON omnex_system_core.core_system_init;

CREATE TRIGGER trg_prevent_core_id_update
BEFORE UPDATE ON omnex_system_core.core_system_init
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_core_id_update();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_core.core_system_init ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_core_system_init
ON omnex_system_core.core_system_init;

CREATE POLICY deny_all_core_system_init
ON omnex_system_core.core_system_init
FOR ALL
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_core_record_type
    ON omnex_system_core.core_system_init (record_type);

CREATE INDEX IF NOT EXISTS idx_core_system_code
    ON omnex_system_core.core_system_init (system_code);

CREATE INDEX IF NOT EXISTS idx_core_category_code
    ON omnex_system_core.core_system_init (category_code);

CREATE INDEX IF NOT EXISTS idx_core_payload
    ON omnex_system_core.core_system_init USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM CORE
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT (UUID VERSION)
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_001
-- ENGINE NAME: system_registry
-- ENGINE FUNCTION:
--   Establishes the sovereign system registry and seeds canonical
--   Omnex systems. Acts as the authoritative identity ledger for the
--   entire Omnex System System-of-Systems.

-- VERSION: v2.0-uuid
-- STATUS: Final
-- FILE: 2026001_omnex_system_core_uuid.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_core IS
'Omnex System Core — sovereign system registry, identity authority, and SoS control plane';

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_registry (
    -- SYSTEM IDENTITY (LAW)
    system_no          text    NOT NULL,
    system_id          uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
    system_code        text    NOT NULL,
    system_name        text    NOT NULL,
    system_title       text    NOT NULL,

    -- CATEGORY IDENTITY
    category_id        text    NOT NULL,
    category_code      text    NOT NULL,
    category_name      text    NOT NULL,

    -- EXECUTION CONTEXT
    schema_name        text    NOT NULL,

    -- ENGINE IDENTITY
    engine_no          text    NOT NULL,
    engine_name        text    NOT NULL,
    engine_function    text    NOT NULL,

    -- MIGRATION IDENTITY
    version            text    NOT NULL,
    status             text    NOT NULL,
    file               text    NOT NULL,

    -- STATE
    active             boolean NOT NULL DEFAULT true,
    created_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_registry IS
'Canonical, sovereign identity registry for all Omnex systems. No system may exist or execute outside this registry.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
CREATE UNIQUE INDEX IF NOT EXISTS uq_system_registry_system_no
ON omnex_system_core.system_registry (system_no);

CREATE UNIQUE INDEX IF NOT EXISTS uq_system_registry_system_code
ON omnex_system_core.system_registry (system_code);

CREATE UNIQUE INDEX IF NOT EXISTS uq_system_registry_schema
ON omnex_system_core.system_registry (schema_name);

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_system_identity_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF
        OLD.system_no   <> NEW.system_no OR
        OLD.system_id   <> NEW.system_id OR
        OLD.system_code <> NEW.system_code OR
        OLD.system_name <> NEW.system_name OR
        OLD.schema_name <> NEW.schema_name OR
        OLD.file        <> NEW.file
    THEN
        RAISE EXCEPTION
            'OMNEX LAW VIOLATION: System identity fields are immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_system_identity_mutation
ON omnex_system_core.system_registry;

CREATE TRIGGER trg_prevent_system_identity_mutation
BEFORE UPDATE ON omnex_system_core.system_registry
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_system_identity_mutation();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_registry
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_system_registry
ON omnex_system_core.system_registry;

CREATE POLICY deny_all_system_registry
ON omnex_system_core.system_registry
FOR ALL
USING (false);

-- ==========================
-- PHASE 8: DATA SEED (UUID)
-- ==========================

INSERT INTO omnex_system_core.system_registry (
    system_no, system_id, system_code, system_name, system_title,
    category_id, category_code, category_name,
    schema_name,
    engine_no, engine_name, engine_function,
    version, status, file
)
SELECT *
FROM (
VALUES

('system_000', gen_random_uuid(),'OS_BOOT','Omnex_System_Bootstrap','Bootstrap Engine & Loader',
 'C_OSB_2026000','OS_BOOT','Omnex_System_Bootstrap',
 'omnex_system_bootstrap',
 'engine_000','omnex_system_init','Initializes Omnex platform',
 'v1.0','Final','2026000_omnex_system_bootstrap.sql'),

('system_001', gen_random_uuid(),'OS_CORE','Omnex_System_Core','Core Governance & Registry',
 'C_OSCF_2026001','OS_CORE','Omnex_System_Core_foundation',
 'omnex_system_core',
 'engine_001','system_registry','Establishes the sovereign system registry and seeds canonical Omnex systems',
 'v2.0','Final','2026001_omnex_system_core_uuid.sql'),

('system_002', gen_random_uuid(),'OS_ID','Omnex_System_Identity','System Identity Generator',
 'C_OSCF_2026001','OS_CORE','Omnex_System_Core_foundation',
 'omnex_system_identity',
 'engine_000','omnex_system_init','System identity anchoring',
 'v1.0','Final','2026002_omnex_system_identity.sql'),

('system_003', gen_random_uuid(),'OS_GOV','Omnex_System_Governance','Governance & RLS',
 'C_OCF_2026001','OS_CORE','Omnex_System_Core',
 'omnex_system_governance',
 'engine_000','omnex_system_init','Policy and access control',
 'v1.0','Final','2026003_omnex_system_governance.sql'),

('system_004', gen_random_uuid(),'OS_AUD','Omnex_System_Audit','Audit & Evidence',
 'C_OCF_2026001','OS_CORE','Omnex_System_Core',
 'omnex_system_audit',
 'engine_000','omnex_system_init','Audit enforcement',
 'v1.0','Final','2026004_omnex_system_audit.sql'),

('system_005', gen_random_uuid(),'OS_FND','Omnex_Systems_Foundation','Shared Foundations',
 'C_OCF_2026001','OS_CORE','Omnex_System_Core',
 'omnex_system_foundation',
 'engine_000','omnex_system_init','Shared system contracts',
 'v1.0','Final','2026005_omnex_system_foundation.sql'),

('system_006', gen_random_uuid(),'OS_TR','Omnex_System_Treasury','Fiscal authority & public finance',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_treasury',
 'engine_000','omnex_system_init','Fiscal authority system',
 'v1.0','Final','2026006_omnex_system_treasury.sql'),

('system_007', gen_random_uuid(),'OS_TX','Omnex_System_Tax','Statutory taxation governance',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_tax',
 'engine_000','omnex_system_init','Taxation authority system',
 'v1.0','Final','2026007_omnex_system_tax.sql'),

('system_008', gen_random_uuid(),'OS_TD','Omnex_System_Trade','Trade regulation and licensing',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_trade',
 'engine_000','omnex_system_init','Trade regulation system',
 'v1.0','Final','2026008_omnex_system_trade.sql'),

('system_009', gen_random_uuid(),'OS_LB','Omnex_System_Labour','Labour law and workforce authority',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_labour',
 'engine_000','omnex_system_init','Labour governance system',
 'v1.0','Final','2026009_omnex_system_labour.sql'),

('system_010', gen_random_uuid(),'OS_AGRI','Omnex_System_Agriculture','Agriculture governance',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_agriculture',
 'engine_000','omnex_system_init','Agriculture regulation system',
 'v1.0','Final','2026010_omnex_system_agriculture.sql'),

('system_011', gen_random_uuid(),'OS_EN','Omnex_System_Energy','Energy sector authority',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_energy',
 'engine_000','omnex_system_init','Energy sector governance',
 'v1.0','Final','2026011_omnex_system_energy.sql'),

('system_012', gen_random_uuid(),'OS_INFRA','Omnex_System_Infrastructure','Infrastructure governance',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_infrastructure',
 'engine_000','omnex_system_init','National infrastructure system',
 'v1.0','Final','2026012_omnex_system_infrastructure.sql'),

('system_013', gen_random_uuid(),'OS_H','Omnex_System_Health','National health authority',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_health',
 'engine_000','omnex_system_init','Public health system',
 'v1.0','Final','2026013_omnex_system_health.sql'),

('system_014', gen_random_uuid(),'OS_ED','Omnex_System_Education','Education governance',
 'C_AS_2026002','OS_AUTH','Omnex_System_Authority',
 'omnex_system_education',
 'engine_000','omnex_system_init','National education authority',
 'v1.0','Final','2026014_omnex_system_education.sql')

) AS seed(
    system_no, system_id, system_code, system_name, system_title,
    category_id, category_code, category_name,
    schema_name,
    engine_no, engine_name, engine_function,
    version, status, file
)
ON CONFLICT (system_id) DO NOTHING;


COMMIT;

-- ============================================================
-- END OF ENGINE 001 — OMNEX SYSTEM REGISTRY (UUID VERSION)
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_002
-- ENGINE NAME: Core Identity Engine
-- ENGINE FUNCTION: Establishes canonical, immutable identity root for all human entities.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_core IS
'Omnex System Core — sovereign canonical foundation schema';

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_account (
    user_id        uuid PRIMARY KEY,
    global_uid     text NOT NULL,
    legal_name     text NOT NULL,
    date_of_birth  date,
    gender_code    text,
    status         text NOT NULL,
    created_at     timestamptz NOT NULL,
    updated_at     timestamptz
);

COMMENT ON TABLE omnex_system_core.user_account IS
'Canonical, immutable human identity record for the Omnex System';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_account_global_uid'
    ) THEN
        ALTER TABLE omnex_system_core.user_account
            ADD CONSTRAINT uq_user_account_global_uid UNIQUE (global_uid);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_account_status'
    ) THEN
        ALTER TABLE omnex_system_core.user_account
            ADD CONSTRAINT chk_user_account_status
            CHECK (status IN ('active', 'suspended', 'archived'));
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Identity root — no foreign keys by law

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_global_uid_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.global_uid <> NEW.global_uid THEN
        RAISE EXCEPTION
            'OMNEX IDENTITY VIOLATION: global_uid is immutable';
    END IF;
    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_prevent_global_uid_change'
          AND tgrelid = 'omnex_system_core.user_account'::regclass
    ) THEN
        CREATE TRIGGER trg_prevent_global_uid_change
        BEFORE UPDATE ON omnex_system_core.user_account
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.prevent_global_uid_change();
    END IF;
END $$;

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_account
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename = 'user_account'
          AND policyname = 'deny_all_user_account'
    ) THEN
        CREATE POLICY deny_all_user_account
        ON omnex_system_core.user_account
        FOR ALL
        USING (false);
    END IF;
END $$;

COMMENT ON POLICY deny_all_user_account
ON omnex_system_core.user_account IS
'Default deny-all policy; access must be explicitly granted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_account_global_uid
ON omnex_system_core.user_account (global_uid);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — CORE IDENTITY (CANONICAL)
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_003
-- ENGINE NAME: Core Identity — User Identifiers
-- ENGINE FUNCTION: Links all internal and external identifiers to the canonical user_account while preventing duplication, reassignment, and identity collision.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (No ENUMs declared)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_identifier (
    identifier_id     uuid PRIMARY KEY,
    user_id           uuid NOT NULL,
    identifier_type   text NOT NULL,
    identifier_value  text NOT NULL,
    status            text NOT NULL,
    confidence_score  numeric(5,4),
    verified_at       timestamptz,
    created_at        timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_identifier IS
'Resolves all internal and external identifiers to a canonical user_account';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_identifier_status'
    ) THEN
        ALTER TABLE omnex_system_core.user_identifier
            ADD CONSTRAINT chk_user_identifier_status
            CHECK (status IN ('active', 'revoked', 'superseded'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_identifier_confidence'
    ) THEN
        ALTER TABLE omnex_system_core.user_identifier
            ADD CONSTRAINT chk_user_identifier_confidence
            CHECK (
                confidence_score IS NULL
                OR confidence_score BETWEEN 0 AND 1
            );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_identifier_type_value'
    ) THEN
        ALTER TABLE omnex_system_core.user_identifier
            ADD CONSTRAINT uq_user_identifier_type_value
            UNIQUE (identifier_type, identifier_value);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'omnex_system_core'
          AND table_name = 'user_account'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_identifier_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_identifier
            ADD CONSTRAINT fk_user_identifier_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_identifier_reassignment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.user_id <> NEW.user_id THEN
        RAISE EXCEPTION
            'OMNEX IDENTITY VIOLATION: identifier reassignment is forbidden';
    END IF;
    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_prevent_identifier_reassignment'
          AND tgrelid = 'omnex_system_core.user_identifier'::regclass
    ) THEN
        CREATE TRIGGER trg_prevent_identifier_reassignment
        BEFORE UPDATE ON omnex_system_core.user_identifier
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.prevent_identifier_reassignment();
    END IF;
END $$;

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_identifier
ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename = 'user_identifier'
          AND policyname = 'deny_all_user_identifier'
    ) THEN
        CREATE POLICY deny_all_user_identifier
        ON omnex_system_core.user_identifier
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_identifier
        ON omnex_system_core.user_identifier IS
        'Default deny-all policy; identifier access must be explicitly granted';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_identifier_lookup
ON omnex_system_core.user_identifier (identifier_type, identifier_value);

CREATE INDEX IF NOT EXISTS idx_user_identifier_user
ON omnex_system_core.user_identifier (user_id);

-- ============================================================
-- END OF ENGINE 003 — USER IDENTIFIERS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_004
-- ENGINE NAME: Master User Profile — Contacts & Reachability
-- ENGINE FUNCTION: Stores communication endpoints without defining identity

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (No ENUMs defined)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_contact (
    contact_id     uuid PRIMARY KEY,
    user_id        uuid NOT NULL,
    contact_type   text NOT NULL,
    contact_value  text NOT NULL,
    is_primary     boolean NOT NULL DEFAULT false,
    is_verified    boolean NOT NULL DEFAULT false,
    verified_at    timestamptz,
    status         text NOT NULL,
    created_at     timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_contact IS
'Reachable communication endpoints for a user; does not establish identity';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_contact_status'
    ) THEN
        ALTER TABLE omnex_system_core.user_contact
            ADD CONSTRAINT chk_user_contact_status
            CHECK (status IN ('active', 'inactive', 'blocked'));
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_contact_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_contact
            ADD CONSTRAINT fk_user_contact_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_single_primary_contact()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_primary = true THEN
        UPDATE omnex_system_core.user_contact
        SET is_primary = false
        WHERE user_id = NEW.user_id
          AND contact_type = NEW.contact_type
          AND contact_id <> NEW.contact_id;
    END IF;
    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_enforce_single_primary_contact'
          AND tgrelid = 'omnex_system_core.user_contact'::regclass
    ) THEN
        CREATE TRIGGER trg_enforce_single_primary_contact
        BEFORE INSERT OR UPDATE ON omnex_system_core.user_contact
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.enforce_single_primary_contact();
    END IF;
END $$;

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_contact
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'user_contact'
          AND policyname = 'deny_all_user_contact'
    ) THEN
        CREATE POLICY deny_all_user_contact
        ON omnex_system_core.user_contact
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_contact
        ON omnex_system_core.user_contact IS
        'Default deny-all policy; contact access must be explicitly granted';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_contact_lookup
ON omnex_system_core.user_contact (contact_type, contact_value);

CREATE INDEX IF NOT EXISTS idx_user_contact_user
ON omnex_system_core.user_contact (user_id);

CREATE INDEX IF NOT EXISTS idx_user_contact_primary
ON omnex_system_core.user_contact (user_id, contact_type)
WHERE is_primary = true;

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — CONTACTS & REACHABILITY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_005
-- ENGINE NAME: Contact Preferences & Consent
-- ENGINE FUNCTION: Enforces channel permissions, user consent, and time windows for communications.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (No ENUMs required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_contact_preference (
    preference_id   uuid PRIMARY KEY,
    user_id         uuid NOT NULL,
    channel         text NOT NULL,
    allowed         boolean NOT NULL,
    allowed_from    time,
    allowed_to      time,
    created_at      timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_contact_preference IS
'User consent, channel permissions, and time-window rules for communications';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_contact_preference_time_window'
    ) THEN
        ALTER TABLE omnex_system_core.user_contact_preference
        ADD CONSTRAINT chk_user_contact_preference_time_window
        CHECK (
            (allowed_from IS NULL AND allowed_to IS NULL)
            OR (allowed_from IS NOT NULL AND allowed_to IS NOT NULL AND allowed_from < allowed_to)
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_contact_preference_user_channel'
    ) THEN
        ALTER TABLE omnex_system_core.user_contact_preference
        ADD CONSTRAINT uq_user_contact_preference_user_channel
        UNIQUE (user_id, channel);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'omnex_system_core'
        AND table_name = 'user_account'
    ) AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_contact_preference_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_contact_preference
        ADD CONSTRAINT fk_user_contact_preference_user
        FOREIGN KEY (user_id)
        REFERENCES omnex_system_core.user_account (user_id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_invalid_contact_preferences()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.allowed = false
       AND (NEW.allowed_from IS NOT NULL OR NEW.allowed_to IS NOT NULL) THEN
        RAISE EXCEPTION
            'OMNEX CONSENT VIOLATION: Time windows cannot exist when communication is disallowed';
    END IF;
    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_prevent_invalid_contact_preferences'
          AND tgrelid = 'omnex_system_core.user_contact_preference'::regclass
    ) THEN
        CREATE TRIGGER trg_prevent_invalid_contact_preferences
        BEFORE INSERT OR UPDATE ON omnex_system_core.user_contact_preference
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.prevent_invalid_contact_preferences();
    END IF;
END $$;

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_contact_preference
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename = 'user_contact_preference'
          AND policyname = 'deny_all_user_contact_preference'
    ) THEN
        CREATE POLICY deny_all_user_contact_preference
        ON omnex_system_core.user_contact_preference
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_contact_preference
        ON omnex_system_core.user_contact_preference IS
        'Default deny-all policy; contact preferences require explicit grants';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_contact_preference_channel
ON omnex_system_core.user_contact_preference (user_id, channel);

-- ============================================================
-- END OF ENGINE 005 — CONTACT PREFERENCES & CONSENT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_006
-- ENGINE NAME: Addresses & Geography
-- ENGINE FUNCTION: Captures structured geographic and jurisdictional locations associated with a user.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql


-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (No ENUMs required)


-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_address (
    address_id      uuid PRIMARY KEY,
    user_id         uuid NOT NULL,
    address_type    text NOT NULL,
    address_line_1  text NOT NULL,
    address_line_2  text,
    city            text,
    county          text,
    region          text,
    country_code    char(2) NOT NULL,
    postal_code     text,
    latitude        numeric(9,6),
    longitude       numeric(9,6),
    is_primary      boolean NOT NULL DEFAULT false,
    valid_from      date,
    valid_to        date,
    created_at      timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_address IS
'Structured geographic and jurisdictional addresses associated with a user';


-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_address_validity_period'
    ) THEN
        ALTER TABLE omnex_system_core.user_address
        ADD CONSTRAINT chk_user_address_validity_period
        CHECK (
            valid_from IS NULL
            OR valid_to IS NULL
            OR valid_from <= valid_to
        );
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_address_latitude'
    ) THEN
        ALTER TABLE omnex_system_core.user_address
        ADD CONSTRAINT chk_user_address_latitude
        CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_address_longitude'
    ) THEN
        ALTER TABLE omnex_system_core.user_address
        ADD CONSTRAINT chk_user_address_longitude
        CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180);
    END IF;
END $$;


-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_core'
          AND table_name   = 'user_account'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_address_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_address
        ADD CONSTRAINT fk_user_address_user
        FOREIGN KEY (user_id)
        REFERENCES omnex_system_core.user_account (user_id)
        ON DELETE CASCADE;
    END IF;
END $$;


-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_single_primary_address()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_primary = true THEN
        UPDATE omnex_system_core.user_address
        SET is_primary = false
        WHERE user_id = NEW.user_id
          AND address_type = NEW.address_type
          AND address_id <> NEW.address_id;
    END IF;
    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_enforce_single_primary_address'
          AND tgrelid = 'omnex_system_core.user_address'::regclass
    ) THEN
        CREATE TRIGGER trg_enforce_single_primary_address
        BEFORE INSERT OR UPDATE ON omnex_system_core.user_address
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.enforce_single_primary_address();
    END IF;
END $$;


-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_address
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'user_address'
          AND policyname = 'deny_all_user_address'
    ) THEN
        CREATE POLICY deny_all_user_address
        ON omnex_system_core.user_address
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_address
        ON omnex_system_core.user_address IS
        'Default deny-all policy; address access must be explicitly granted';
    END IF;
END $$;


-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_address_user
ON omnex_system_core.user_address (user_id);

CREATE INDEX IF NOT EXISTS idx_user_address_primary
ON omnex_system_core.user_address (user_id, address_type)
WHERE is_primary = true;

CREATE INDEX IF NOT EXISTS idx_user_address_country
ON omnex_system_core.user_address (country_code);


-- ============================================================
-- END OF ENGINE 006 — ADDRESSES & GEOGRAPHY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_007
-- ENGINE NAME: Personas & Segments
-- ENGINE FUNCTION: Represents declared or inferred personas a user operates under with confidence and provenance.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql


-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (No ENUMs required)


-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_persona (
    persona_id        uuid PRIMARY KEY,
    user_id           uuid NOT NULL,
    persona_code      text NOT NULL,
    confidence_score  numeric(5,4),
    derived_source    text NOT NULL,
    active            boolean NOT NULL DEFAULT true,
    created_at        timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_persona IS
'Declared or inferred personas under which a user operates across systems';


-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_persona_confidence'
    ) THEN
        ALTER TABLE omnex_system_core.user_persona
        ADD CONSTRAINT chk_user_persona_confidence
        CHECK (
            confidence_score IS NULL
            OR confidence_score BETWEEN 0 AND 1
        );
    END IF;
END $$;


-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_core'
          AND table_name   = 'user_account'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_persona_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_persona
        ADD CONSTRAINT fk_user_persona_user
        FOREIGN KEY (user_id)
        REFERENCES omnex_system_core.user_account (user_id)
        ON DELETE CASCADE;
    END IF;
END $$;


-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_duplicate_active_persona()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.active = true THEN
        IF EXISTS (
            SELECT 1
            FROM omnex_system_core.user_persona
            WHERE user_id = NEW.user_id
              AND persona_code = NEW.persona_code
              AND active = true
              AND persona_id <> NEW.persona_id
        ) THEN
            RAISE EXCEPTION
                'OMNEX PERSONA VIOLATION: duplicate active persona is not allowed';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_prevent_duplicate_active_persona'
          AND tgrelid = 'omnex_system_core.user_persona'::regclass
    ) THEN
        CREATE TRIGGER trg_prevent_duplicate_active_persona
        BEFORE INSERT OR UPDATE ON omnex_system_core.user_persona
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.prevent_duplicate_active_persona();
    END IF;
END $$;


-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_persona
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'user_persona'
          AND policyname = 'deny_all_user_persona'
    ) THEN
        CREATE POLICY deny_all_user_persona
        ON omnex_system_core.user_persona
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_persona
        ON omnex_system_core.user_persona IS
        'Default deny-all policy; persona access must be explicitly granted';
    END IF;
END $$;


-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_persona_user
ON omnex_system_core.user_persona (user_id);

CREATE INDEX IF NOT EXISTS idx_user_persona_active
ON omnex_system_core.user_persona (user_id, persona_code)
WHERE active = true;


-- ============================================================
-- END OF ENGINE 007 — PERSONAS & SEGMENTS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_008
-- ENGINE NAME: Personas & Segments
-- ENGINE FUNCTION:
--   Groups users into policy, business, or risk segments for decision-making and system behavior governance.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_segment (
    segment_id       uuid PRIMARY KEY,
    user_id          uuid NOT NULL,
    segment_code     text NOT NULL,
    segment_type     text NOT NULL,
    assigned_by      uuid NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.user_segment IS
'Groups users into policy, business, or risk segments for decision-making and dynamic system behavior';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_segment_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.user_segment
            ADD CONSTRAINT chk_segment_code_not_empty
            CHECK (length(segment_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_segment_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.user_segment
            ADD CONSTRAINT chk_segment_type_not_empty
            CHECK (length(segment_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_segment_unique'
    ) THEN
        ALTER TABLE omnex_system_core.user_segment
            ADD CONSTRAINT uq_user_segment_unique
            UNIQUE (user_id, segment_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_segment_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_segment
            ADD CONSTRAINT fk_user_segment_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_segment_reassignment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.user_id <> NEW.user_id THEN
        RAISE EXCEPTION 'OMNEX SEGMENTATION VIOLATION: user_id in a segment assignment is immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_segment_reassignment
ON omnex_system_core.user_segment;

CREATE TRIGGER trg_prevent_segment_reassignment
BEFORE UPDATE ON omnex_system_core.user_segment
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_segment_reassignment();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_segment
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_segment
ON omnex_system_core.user_segment;

CREATE POLICY deny_all_user_segment
ON omnex_system_core.user_segment
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_segment
ON omnex_system_core.user_segment IS
'Default deny-all policy; segment access is strictly centrally governed';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_segment_user
ON omnex_system_core.user_segment (user_id);

CREATE INDEX IF NOT EXISTS idx_user_segment_code
ON omnex_system_core.user_segment (segment_code);

CREATE INDEX IF NOT EXISTS idx_user_segment_type
ON omnex_system_core.user_segment (segment_type);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — PERSONAS & SEGMENTS
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_009
-- ENGINE NAME: Relationships & Networks
-- ENGINE FUNCTION:
--   Defines user-to-user relationship links, direction, strength, and time-bound validity.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_relationship (
    relationship_id   uuid PRIMARY KEY,
    user_id           uuid NOT NULL,
    related_user_id   uuid NOT NULL,
    relationship_type text NOT NULL,
    strength_score    numeric(5,4),
    valid_from        date,
    valid_to          date,
    created_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.user_relationship IS
'Directed relationships between users with type, strength, and validity period';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_relationship_not_self'
    ) THEN
        ALTER TABLE omnex_system_core.user_relationship
            ADD CONSTRAINT chk_user_relationship_not_self
            CHECK (user_id <> related_user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_relationship_strength'
    ) THEN
        ALTER TABLE omnex_system_core.user_relationship
            ADD CONSTRAINT chk_user_relationship_strength
            CHECK (strength_score IS NULL OR strength_score BETWEEN 0 AND 1);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_relationship_validity'
    ) THEN
        ALTER TABLE omnex_system_core.user_relationship
            ADD CONSTRAINT chk_user_relationship_validity
            CHECK (
                valid_from IS NULL OR
                valid_to IS NULL OR
                valid_from <= valid_to
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_relationship_unique'
    ) THEN
        ALTER TABLE omnex_system_core.user_relationship
            ADD CONSTRAINT uq_user_relationship_unique
            UNIQUE (user_id, related_user_id, relationship_type);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_relationship_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_relationship
            ADD CONSTRAINT fk_user_relationship_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_relationship_reassignment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.user_id <> NEW.user_id OR OLD.related_user_id <> NEW.related_user_id THEN
        RAISE EXCEPTION 'OMNEX RELATIONSHIP VIOLATION: relationship endpoints are immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_relationship_reassignment
ON omnex_system_core.user_relationship;

CREATE TRIGGER trg_prevent_relationship_reassignment
BEFORE UPDATE ON omnex_system_core.user_relationship
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_relationship_reassignment();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_relationship
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_relationship
ON omnex_system_core.user_relationship;

CREATE POLICY deny_all_user_relationship
ON omnex_system_core.user_relationship
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_relationship
ON omnex_system_core.user_relationship IS
'Default deny-all policy; relationship access must be explicitly granted';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_relationship_user
ON omnex_system_core.user_relationship (user_id);

CREATE INDEX IF NOT EXISTS idx_user_relationship_related
ON omnex_system_core.user_relationship (related_user_id);

CREATE INDEX IF NOT EXISTS idx_user_relationship_type
ON omnex_system_core.user_relationship (relationship_type);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — RELATIONSHIPS & NETWORKS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_010
-- ENGINE NAME: Socio-Economic Profile
-- ENGINE FUNCTION: Stores assessable socio-economic attributes for policy, eligibility, and analytics.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_socioeconomic_profile (
    profile_id         uuid PRIMARY KEY,
    user_id            uuid NOT NULL,
    education_level    text,
    income_band        text,
    vulnerability_flag boolean NOT NULL DEFAULT false,
    disability_flag    boolean NOT NULL DEFAULT false,
    household_size     integer,
    primary_language   text,
    data_source        text NOT NULL,
    last_assessed_at   timestamptz
);

COMMENT ON TABLE omnex_system_core.user_socioeconomic_profile IS
'Socio-economic attributes used for policy enforcement, analytics, and eligibility decisions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- One profile per user
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_socioeconomic_profile_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_socioeconomic_profile
            ADD CONSTRAINT uq_user_socioeconomic_profile_user
            UNIQUE (user_id);
    END IF;

    -- Household size realism
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_socioeconomic_household_size'
    ) THEN
        ALTER TABLE omnex_system_core.user_socioeconomic_profile
            ADD CONSTRAINT chk_user_socioeconomic_household_size
            CHECK (household_size IS NULL OR household_size > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_socioeconomic_profile_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_socioeconomic_profile
            ADD CONSTRAINT fk_user_socioeconomic_profile_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_socioeconomic_reassignment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.user_id <> NEW.user_id THEN
        RAISE EXCEPTION
            'OMNEX SOCIO-ECONOMIC PROFILE VIOLATION: user_id is immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_socioeconomic_reassignment
ON omnex_system_core.user_socioeconomic_profile;

CREATE TRIGGER trg_prevent_socioeconomic_reassignment
BEFORE UPDATE ON omnex_system_core.user_socioeconomic_profile
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_socioeconomic_reassignment();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_socioeconomic_profile
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_socioeconomic_profile
ON omnex_system_core.user_socioeconomic_profile;

CREATE POLICY deny_all_user_socioeconomic_profile
ON omnex_system_core.user_socioeconomic_profile
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_socioeconomic_profile
ON omnex_system_core.user_socioeconomic_profile IS
'Default deny-all; socio-economic data requires explicit lawful grants';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_socioeconomic_profile_user
ON omnex_system_core.user_socioeconomic_profile (user_id);

CREATE INDEX IF NOT EXISTS idx_user_socioeconomic_profile_flags
ON omnex_system_core.user_socioeconomic_profile
(vulnerability_flag, disability_flag);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — SOCIO-ECONOMIC PROFILE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_011
-- ENGINE NAME: Employment & Organization Context
-- ENGINE FUNCTION: Captures employment, organizational affiliation, and role context for a user.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_employment (
    employment_id   uuid PRIMARY KEY,
    user_id         uuid NOT NULL,
    organization_id uuid NOT NULL,
    role_title      text NOT NULL,
    employment_type text NOT NULL,
    start_date      date NOT NULL,
    end_date        date,
    is_primary      boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_employment IS
'Employment, organizational affiliation, and role context for a user';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Valid employment period
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_employment_dates'
    ) THEN
        ALTER TABLE omnex_system_core.user_employment
            ADD CONSTRAINT chk_user_employment_dates
            CHECK (end_date IS NULL OR end_date >= start_date);
    END IF;
END $$;

-- One primary employment per user
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_employment_primary
ON omnex_system_core.user_employment (user_id)
WHERE is_primary = true;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_employment_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_employment
            ADD CONSTRAINT fk_user_employment_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- NOTE:
-- organization_id intentionally NOT FK-bound here.
-- Organization authority belongs to governance / registry engines.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_user_employment_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Identity linkage is immutable
    IF TG_OP = 'UPDATE' AND OLD.user_id <> NEW.user_id THEN
        RAISE EXCEPTION
            'OMNEX EMPLOYMENT VIOLATION: user_id is immutable';
    END IF;

    -- Enforce single primary employment
    IF NEW.is_primary = true THEN
        UPDATE omnex_system_core.user_employment
        SET is_primary = false
        WHERE user_id = NEW.user_id
          AND employment_id <> NEW.employment_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_employment_rules
ON omnex_system_core.user_employment;

CREATE TRIGGER trg_enforce_user_employment_rules
BEFORE INSERT OR UPDATE ON omnex_system_core.user_employment
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_user_employment_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_employment
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_employment
ON omnex_system_core.user_employment;

CREATE POLICY deny_all_user_employment
ON omnex_system_core.user_employment
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_employment
ON omnex_system_core.user_employment IS
'Default deny-all; access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_employment_user
ON omnex_system_core.user_employment (user_id);

CREATE INDEX IF NOT EXISTS idx_user_employment_org
ON omnex_system_core.user_employment (organization_id);

CREATE INDEX IF NOT EXISTS idx_user_employment_dates
ON omnex_system_core.user_employment (start_date, end_date);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — EMPLOYMENT & ORGANIZATION CONTEXT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_012
-- ENGINE NAME: Devices & Channels
-- ENGINE FUNCTION: Tracks user devices and access channels for authentication, risk, and security purposes.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_device (
    device_id          uuid PRIMARY KEY,
    user_id            uuid NOT NULL,
    device_type        text NOT NULL,
    os_type            text NOT NULL,
    device_fingerprint text NOT NULL,
    trusted            boolean NOT NULL DEFAULT false,
    first_seen_at      timestamptz NOT NULL,
    last_seen_at       timestamptz,
    status             text NOT NULL,
    created_at         timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_device IS
'Devices and access channels associated with a user for security evaluation';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Status must be valid
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_device_status'
    ) THEN
        ALTER TABLE omnex_system_core.user_device
            ADD CONSTRAINT chk_user_device_status
            CHECK (status IN ('active', 'revoked', 'lost', 'compromised', 'archived'));
    END IF;

    -- Timestamp order
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_device_seen_order'
    ) THEN
        ALTER TABLE omnex_system_core.user_device
            ADD CONSTRAINT chk_user_device_seen_order
            CHECK (last_seen_at IS NULL OR last_seen_at >= first_seen_at);
    END IF;

    -- Unique fingerprint per user
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_device_fingerprint'
    ) THEN
        ALTER TABLE omnex_system_core.user_device
            ADD CONSTRAINT uq_user_device_fingerprint
            UNIQUE (user_id, device_fingerprint);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_device_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_device
            ADD CONSTRAINT fk_user_device_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_user_device_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.user_id <> NEW.user_id THEN
            RAISE EXCEPTION 'OMNEX DEVICE VIOLATION: user_id is immutable';
        END IF;

        IF OLD.device_fingerprint <> NEW.device_fingerprint THEN
            RAISE EXCEPTION 'OMNEX DEVICE VIOLATION: device_fingerprint is immutable';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_device_rules
ON omnex_system_core.user_device;

CREATE TRIGGER trg_enforce_user_device_rules
BEFORE UPDATE ON omnex_system_core.user_device
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_user_device_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_device
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_device
ON omnex_system_core.user_device;

CREATE POLICY deny_all_user_device
ON omnex_system_core.user_device
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_device
ON omnex_system_core.user_device IS
'Default deny-all; access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_device_user
ON omnex_system_core.user_device (user_id);

CREATE INDEX IF NOT EXISTS idx_user_device_fingerprint
ON omnex_system_core.user_device (device_fingerprint);

CREATE INDEX IF NOT EXISTS idx_user_device_status
ON omnex_system_core.user_device (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 012 — DEVICES & CHANNELS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_013
-- ENGINE NAME: Behaviour & Lifecycle
-- ENGINE FUNCTION: Records lifecycle and behavioral events for analytics, intelligence, eligibility, and audit.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_lifecycle_event (
    lifecycle_event_id uuid PRIMARY KEY,
    user_id            uuid NOT NULL,
    event_type         text NOT NULL,
    event_source       text NOT NULL,
    occurred_at        timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_lifecycle_event IS
'Append-only record of significant user lifecycle and behavioral events';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
ALTER TABLE omnex_system_core.user_lifecycle_event
DROP CONSTRAINT IF EXISTS chk_user_lifecycle_event_time;

ALTER TABLE omnex_system_core.user_lifecycle_event
ADD CONSTRAINT chk_user_lifecycle_event_time
CHECK (occurred_at <= now());

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
ALTER TABLE omnex_system_core.user_lifecycle_event
DROP CONSTRAINT IF EXISTS fk_user_lifecycle_event_user;

ALTER TABLE omnex_system_core.user_lifecycle_event
ADD CONSTRAINT fk_user_lifecycle_event_user
FOREIGN KEY (user_id)
REFERENCES omnex_system_core.user_account (user_id)
ON DELETE CASCADE;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_lifecycle_event_append_only()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX LIFECYCLE VIOLATION: lifecycle events are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX LIFECYCLE VIOLATION: lifecycle events cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_lifecycle_event_append_only
ON omnex_system_core.user_lifecycle_event;

CREATE TRIGGER trg_enforce_lifecycle_event_append_only
BEFORE UPDATE OR DELETE
ON omnex_system_core.user_lifecycle_event
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_lifecycle_event_append_only();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_lifecycle_event
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_lifecycle_event
ON omnex_system_core.user_lifecycle_event;

CREATE POLICY deny_all_user_lifecycle_event
ON omnex_system_core.user_lifecycle_event
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_lifecycle_event
ON omnex_system_core.user_lifecycle_event IS
'Default deny-all; lifecycle access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_lifecycle_event_user_time
ON omnex_system_core.user_lifecycle_event (user_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_lifecycle_event_type
ON omnex_system_core.user_lifecycle_event (event_type);

CREATE INDEX IF NOT EXISTS idx_user_lifecycle_event_source
ON omnex_system_core.user_lifecycle_event (event_source);

COMMIT;

-- ============================================================
-- END OF ENGINE 013 — BEHAVIOUR & LIFECYCLE EVENTS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026012
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_014
-- ENGINE NAME: AI Intelligence & Signals
-- ENGINE FUNCTION: Stores AI-generated user signals for advisory use, not identity definition.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026012_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_ai_signal (
    signal_id        uuid PRIMARY KEY,
    user_id          uuid NOT NULL,
    signal_type      text NOT NULL,
    signal_value     text NOT NULL,
    confidence_score numeric(5,4),
    generated_by     text NOT NULL,
    generated_at     timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_ai_signal IS
'Append-only AI-generated signals and intelligence related to a user';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Valid confidence range
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_ai_signal_confidence'
    ) THEN
        ALTER TABLE omnex_system_core.user_ai_signal
            ADD CONSTRAINT chk_user_ai_signal_confidence
            CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1);
    END IF;

    -- Must not be future-dated
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_ai_signal_time'
    ) THEN
        ALTER TABLE omnex_system_core.user_ai_signal
            ADD CONSTRAINT chk_user_ai_signal_time
            CHECK (generated_at <= now());
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_ai_signal_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_ai_signal
            ADD CONSTRAINT fk_user_ai_signal_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_ai_signal_append_only()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX AI SIGNAL VIOLATION: AI signals are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX AI SIGNAL VIOLATION: AI signals cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_ai_signal_append_only
ON omnex_system_core.user_ai_signal;

CREATE TRIGGER trg_enforce_ai_signal_append_only
BEFORE UPDATE OR DELETE
ON omnex_system_core.user_ai_signal
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_ai_signal_append_only();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_ai_signal
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_ai_signal
ON omnex_system_core.user_ai_signal;

CREATE POLICY deny_all_user_ai_signal
ON omnex_system_core.user_ai_signal
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_ai_signal
ON omnex_system_core.user_ai_signal IS
'Default deny-all; AI intelligence access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_ai_signal_user_time
ON omnex_system_core.user_ai_signal (user_id, generated_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_ai_signal_type
ON omnex_system_core.user_ai_signal (signal_type);

CREATE INDEX IF NOT EXISTS idx_user_ai_signal_confidence
ON omnex_system_core.user_ai_signal (confidence_score);

COMMIT;

-- ============================================================
-- END OF ENGINE 014 — AI INTELLIGENCE & SIGNALS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_015
-- ENGINE NAME: User Notes
-- ENGINE FUNCTION: Human-authored annotations attached to a user profile; append-only, advisory, non-authoritative.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_note (
    note_id          uuid PRIMARY KEY,
    user_id          uuid NOT NULL,
    note_text        text NOT NULL,
    visibility_scope text NOT NULL,
    created_by       text NOT NULL,
    created_at       timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_note IS
'Human-authored annotations for user profile — advisory, immutable, and audit-aligned.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Lawful visibility scope
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_note_visibility'
    ) THEN
        ALTER TABLE omnex_system_core.user_note
        ADD CONSTRAINT chk_user_note_visibility
        CHECK (visibility_scope IN ('private','internal','audit','public'));
    END IF;

    -- Temporal validity: no future-dated notes
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_note_time'
    ) THEN
        ALTER TABLE omnex_system_core.user_note
        ADD CONSTRAINT chk_user_note_time
        CHECK (created_at <= now());
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_note_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_note
        ADD CONSTRAINT fk_user_note_user
        FOREIGN KEY (user_id)
        REFERENCES omnex_system_core.user_account (user_id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_user_note_append_only()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'OMNEX NOTE VIOLATION: Notes are immutable once created';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'OMNEX NOTE VIOLATION: Notes cannot be deleted';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_note_append_only
ON omnex_system_core.user_note;

CREATE TRIGGER trg_enforce_user_note_append_only
BEFORE UPDATE OR DELETE ON omnex_system_core.user_note
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_user_note_append_only();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_note ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_note
ON omnex_system_core.user_note;

CREATE POLICY deny_all_user_note
ON omnex_system_core.user_note
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_note
ON omnex_system_core.user_note IS
'Default deny-all; note access governed by Omnex System Governance.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
-- Review timelines
CREATE INDEX IF NOT EXISTS idx_user_note_user_time
ON omnex_system_core.user_note (user_id, created_at DESC);

-- Filter by visibility
CREATE INDEX IF NOT EXISTS idx_user_note_visibility
ON omnex_system_core.user_note (visibility_scope);

-- Search by author
CREATE INDEX IF NOT EXISTS idx_user_note_created_by
ON omnex_system_core.user_note (created_by);

COMMIT;

-- ============================================================
-- END OF ENGINE 015 — USER NOTES
-- ============================================================
-- ============================================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_016
-- ENGINE NAME: Tags & 360° View
-- ENGINE FUNCTION: Enables tagging of users for classification, policy routing, and segmentation.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_tag (
    tag_id      uuid PRIMARY KEY,
    user_id     uuid NOT NULL,
    tag_code    text NOT NULL,
    tag_source  text NOT NULL,
    created_at  timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_tag IS
'Lightweight tags attached to users for classification and discovery';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Tag must not be future dated
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_tag_time'
    ) THEN
        ALTER TABLE omnex_system_core.user_tag
        ADD CONSTRAINT chk_user_tag_time
        CHECK (created_at <= now());
    END IF;

    -- Prevent duplicate tags from same source
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_tag_source_code'
    ) THEN
        ALTER TABLE omnex_system_core.user_tag
        ADD CONSTRAINT uq_user_tag_source_code
        UNIQUE (user_id, tag_code, tag_source);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_tag_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_tag
        ADD CONSTRAINT fk_user_tag_user
        FOREIGN KEY (user_id)
        REFERENCES omnex_system_core.user_account (user_id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_user_tag_append_only()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX TAG VIOLATION: tags are immutable once created';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX TAG VIOLATION: tags cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_tag_append_only
ON omnex_system_core.user_tag;

CREATE TRIGGER trg_enforce_user_tag_append_only
BEFORE UPDATE OR DELETE ON omnex_system_core.user_tag
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_user_tag_append_only();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_tag
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_tag
ON omnex_system_core.user_tag;

CREATE POLICY deny_all_user_tag
ON omnex_system_core.user_tag
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_tag
ON omnex_system_core.user_tag IS
'Default deny-all; tag access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
-- User-centric tag queries
CREATE INDEX IF NOT EXISTS idx_user_tag_user
ON omnex_system_core.user_tag (user_id);

-- Tag-based discovery
CREATE INDEX IF NOT EXISTS idx_user_tag_code
ON omnex_system_core.user_tag (tag_code);

-- Source-based audits
CREATE INDEX IF NOT EXISTS idx_user_tag_source
ON omnex_system_core.user_tag (tag_source);

COMMIT;

-- ============================================================================
-- END OF ENGINE 016 — TAGS & 360° VIEW
-- ============================================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_017
-- ENGINE NAME: User Metadata
-- ENGINE FUNCTION: Extensible, append-only key-value metadata on users.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.user_metadata (
    metadata_id     uuid PRIMARY KEY,
    user_id         uuid NOT NULL,
    metadata_key    text NOT NULL,
    metadata_value  text NOT NULL,
    source          text NOT NULL,
    created_at      timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.user_metadata IS
'Extensible key-value metadata attached to a user without schema mutation';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    -- Prevent future timestamps
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_user_metadata_time'
    ) THEN
        ALTER TABLE omnex_system_core.user_metadata
            ADD CONSTRAINT chk_user_metadata_time
            CHECK (created_at <= now());
    END IF;

    -- One metadata key per user per source
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_metadata_key_source'
    ) THEN
        ALTER TABLE omnex_system_core.user_metadata
            ADD CONSTRAINT uq_user_metadata_key_source
            UNIQUE (user_id, metadata_key, source);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_user_metadata_user'
    ) THEN
        ALTER TABLE omnex_system_core.user_metadata
            ADD CONSTRAINT fk_user_metadata_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_core.user_account (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_user_metadata_append_only()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX METADATA VIOLATION: metadata entries are immutable once created';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX METADATA VIOLATION: metadata entries cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_metadata_append_only
ON omnex_system_core.user_metadata;

CREATE TRIGGER trg_enforce_user_metadata_append_only
BEFORE UPDATE OR DELETE ON omnex_system_core.user_metadata
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_user_metadata_append_only();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.user_metadata
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_metadata
ON omnex_system_core.user_metadata;

CREATE POLICY deny_all_user_metadata
ON omnex_system_core.user_metadata
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_metadata
ON omnex_system_core.user_metadata IS
'Default deny-all; metadata access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_metadata_user
ON omnex_system_core.user_metadata (user_id);

CREATE INDEX IF NOT EXISTS idx_user_metadata_key
ON omnex_system_core.user_metadata (metadata_key);

CREATE INDEX IF NOT EXISTS idx_user_metadata_source
ON omnex_system_core.user_metadata (source);

COMMIT;

-- ============================================================
-- END OF ENGINE 017 — USER METADATA
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_018
-- ENGINE NAME: Tenant Identity & Classification
-- ENGINE FUNCTION: Authoritative commercial tenant identity for licensing, billing, and jurisdiction.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

COMMENT ON SCHEMA omnex_system_core IS
'Access, Licensing & Subscription Engine (ALSE) — Commercial authority';

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant (
    tenant_id         uuid PRIMARY KEY,
    tenant_name       text NOT NULL,
    tenant_type       text NOT NULL,
    jurisdiction_code text NOT NULL,
    official_email    text NOT NULL,
    official_phone    text,
    created_at        timestamptz NOT NULL,
    updated_at        timestamptz
);

COMMENT ON TABLE omnex_system_core.tenant IS
'Commercial and legal tenant entity consuming the Omnex platform';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_tenant_jurisdiction'
    ) THEN
        ALTER TABLE omnex_system_core.tenant
            ADD CONSTRAINT chk_tenant_jurisdiction
            CHECK (length(jurisdiction_code) BETWEEN 2 AND 10);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_tenant_type'
    ) THEN
        ALTER TABLE omnex_system_core.tenant
            ADD CONSTRAINT chk_tenant_type
            CHECK (tenant_type IN (
                'individual',
                'organization',
                'enterprise',
                'government',
                'partner'
            ));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_tenant_official_email'
    ) THEN
        ALTER TABLE omnex_system_core.tenant
            ADD CONSTRAINT uq_tenant_official_email
            UNIQUE (official_email);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None by design (tenant is a commercial root authority)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_identity_stability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.tenant_id <> NEW.tenant_id THEN
        RAISE EXCEPTION
            'OMNEX TENANT VIOLATION: tenant_id is immutable';
    END IF;
    RETURN NEW;
END;
$$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_enforce_tenant_identity_stability'
          AND tgrelid = 'omnex_system_core.tenant'::regclass
    ) THEN
        CREATE TRIGGER trg_enforce_tenant_identity_stability
        BEFORE UPDATE ON omnex_system_core.tenant
        FOR EACH ROW
        EXECUTE FUNCTION omnex_system_core.enforce_tenant_identity_stability();
    END IF;
END $$;

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant'
          AND policyname = 'deny_all_tenant'
    ) THEN
        CREATE POLICY deny_all_tenant
        ON omnex_system_core.tenant
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant
        ON omnex_system_core.tenant IS
        'Default deny-all; tenant access governed by Omnex System Governance';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_name
ON omnex_system_core.tenant (tenant_name);

CREATE INDEX IF NOT EXISTS idx_tenant_jurisdiction
ON omnex_system_core.tenant (jurisdiction_code);

CREATE INDEX IF NOT EXISTS idx_tenant_type
ON omnex_system_core.tenant (tenant_type);

COMMIT;

-- ============================================================
-- END OF ENGINE 018 — TENANT IDENTITY & CLASSIFICATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_019
-- ENGINE NAME: Tenant Experience Shell & Tier
-- ENGINE FUNCTION: Determines which UI shell and experience tier a tenant receives.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_core IS
'Access, Licensing & Subscription Engine (ALSE) — Commercial authority';

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_experience (
    tenant_experience_id uuid PRIMARY KEY,
    tenant_id            uuid NOT NULL,
    experience_code      text NOT NULL,
    tier_code            text NOT NULL,
    assigned_at          timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.tenant_experience IS
'Assigned experience shell and tier determining tenant UI and feature exposure';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
ALTER TABLE omnex_system_core.tenant_experience
DROP CONSTRAINT IF EXISTS chk_tenant_experience_time;

ALTER TABLE omnex_system_core.tenant_experience
ADD CONSTRAINT chk_tenant_experience_time
    CHECK (assigned_at <= now());

ALTER TABLE omnex_system_core.tenant_experience
DROP CONSTRAINT IF EXISTS uq_tenant_experience_unique;

ALTER TABLE omnex_system_core.tenant_experience
ADD CONSTRAINT uq_tenant_experience_unique
    UNIQUE (tenant_id, experience_code, tier_code, assigned_at);

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
ALTER TABLE omnex_system_core.tenant_experience
DROP CONSTRAINT IF EXISTS fk_tenant_experience_tenant;

ALTER TABLE omnex_system_core.tenant_experience
ADD CONSTRAINT fk_tenant_experience_tenant
    FOREIGN KEY (tenant_id)
    REFERENCES omnex_system_core.tenant (tenant_id)
    ON DELETE CASCADE;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_experience_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX EXPERIENCE VIOLATION: experience assignments are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX EXPERIENCE VIOLATION: experience assignments cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tenant_experience_immutability
ON omnex_system_core.tenant_experience;

CREATE TRIGGER trg_enforce_tenant_experience_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.tenant_experience
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_tenant_experience_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_experience
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_tenant_experience
ON omnex_system_core.tenant_experience;

CREATE POLICY deny_all_tenant_experience
ON omnex_system_core.tenant_experience
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_tenant_experience
ON omnex_system_core.tenant_experience IS
'Default deny-all; experience access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_experience_tenant
ON omnex_system_core.tenant_experience (tenant_id, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_tenant_experience_code
ON omnex_system_core.tenant_experience (experience_code);

CREATE INDEX IF NOT EXISTS idx_tenant_experience_tier
ON omnex_system_core.tenant_experience (tier_code);

COMMIT;

-- ============================================================
-- END OF ENGINE 019 — TENANT EXPERIENCE SHELL & TIER
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_020
-- ENGINE NAME: Subscription Plan
-- ENGINE FUNCTION: Defines commercial subscription offerings, pricing, billing, and entitlement posture.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_core IS
'Access, Licensing & Subscription Engine (ALSE) — Commercial authority';

SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.subscription_plan (
    plan_id           uuid PRIMARY KEY,
    plan_code         text NOT NULL,
    tenant_type       text NOT NULL,
    billing_cycle     text NOT NULL,
    is_system_buyer   boolean NOT NULL DEFAULT false,
    default_ai_tier   text NOT NULL,
    price_amount      numeric(12,2) NOT NULL,
    currency          text NOT NULL,
    active            boolean NOT NULL DEFAULT true
);

COMMENT ON TABLE omnex_system_core.subscription_plan IS
'Commercial subscription plans defining pricing, billing, and default posture';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- Tenant type eligibility
ALTER TABLE omnex_system_core.subscription_plan
    DROP CONSTRAINT IF EXISTS chk_subscription_plan_tenant_type;

ALTER TABLE omnex_system_core.subscription_plan
    ADD CONSTRAINT chk_subscription_plan_tenant_type
        CHECK (tenant_type IN (
            'individual',
            'organization',
            'enterprise',
            'government',
            'partner'
        ));

-- Billing cycle validity
ALTER TABLE omnex_system_core.subscription_plan
    DROP CONSTRAINT IF EXISTS chk_subscription_plan_billing_cycle;

ALTER TABLE omnex_system_core.subscription_plan
    ADD CONSTRAINT chk_subscription_plan_billing_cycle
        CHECK (billing_cycle IN (
            'monthly',
            'quarterly',
            'annual',
            'multi_year'
        ));

-- Price validity
ALTER TABLE omnex_system_core.subscription_plan
    DROP CONSTRAINT IF EXISTS chk_subscription_plan_price;

ALTER TABLE omnex_system_core.subscription_plan
    ADD CONSTRAINT chk_subscription_plan_price
        CHECK (price_amount >= 0);

-- Currency validation
ALTER TABLE omnex_system_core.subscription_plan
    DROP CONSTRAINT IF EXISTS chk_subscription_plan_currency;

ALTER TABLE omnex_system_core.subscription_plan
    ADD CONSTRAINT chk_subscription_plan_currency
        CHECK (length(currency) BETWEEN 3 AND 5);

-- Unique plan code
ALTER TABLE omnex_system_core.subscription_plan
    DROP CONSTRAINT IF EXISTS uq_subscription_plan_code;

ALTER TABLE omnex_system_core.subscription_plan
    ADD CONSTRAINT uq_subscription_plan_code
        UNIQUE (plan_code);

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- (None — commercial primitive, not tenant-bound)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_subscription_plan_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Only 'active' flag may change
        IF (
            OLD.plan_code       IS DISTINCT FROM NEW.plan_code OR
            OLD.tenant_type     IS DISTINCT FROM NEW.tenant_type OR
            OLD.billing_cycle   IS DISTINCT FROM NEW.billing_cycle OR
            OLD.is_system_buyer IS DISTINCT FROM NEW.is_system_buyer OR
            OLD.default_ai_tier IS DISTINCT FROM NEW.default_ai_tier OR
            OLD.price_amount    IS DISTINCT FROM NEW.price_amount OR
            OLD.currency        IS DISTINCT FROM NEW.currency
        ) THEN
            RAISE EXCEPTION
                'OMNEX PLAN VIOLATION: subscription plans are immutable once published';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX PLAN VIOLATION: subscription plans cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_subscription_plan_immutability
ON omnex_system_core.subscription_plan;

CREATE TRIGGER trg_enforce_subscription_plan_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.subscription_plan
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_subscription_plan_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.subscription_plan
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_subscription_plan
ON omnex_system_core.subscription_plan;

CREATE POLICY deny_all_subscription_plan
ON omnex_system_core.subscription_plan
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_subscription_plan
ON omnex_system_core.subscription_plan IS
'Default deny-all; subscription plan access governed by Omnex System Governance';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_subscription_plan_code
ON omnex_system_core.subscription_plan (plan_code);

CREATE INDEX IF NOT EXISTS idx_subscription_plan_active
ON omnex_system_core.subscription_plan (active);

CREATE INDEX IF NOT EXISTS idx_subscription_plan_tenant_type
ON omnex_system_core.subscription_plan (tenant_type);

COMMIT;

-- ============================================================
-- END OF ENGINE 020 — SUBSCRIPTION PLAN
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_021
-- ENGINE NAME: Tenant Subscription Lifecycle
-- ENGINE FUNCTION: Tracks contractual validity of tenant subscriptions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_subscription (
    subscription_id uuid PRIMARY KEY,
    tenant_id       uuid NOT NULL,
    plan_id         uuid NOT NULL,
    start_at        timestamptz NOT NULL,
    end_at          timestamptz NOT NULL,
    grace_end_at    timestamptz,
    is_current      boolean NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.tenant_subscription IS
'Tracks tenant subscription lifecycles including validity and grace periods';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
ALTER TABLE omnex_system_core.tenant_subscription
    DROP CONSTRAINT IF EXISTS chk_tenant_subscription_time;

ALTER TABLE omnex_system_core.tenant_subscription
    ADD CONSTRAINT chk_tenant_subscription_time
        CHECK (end_at > start_at);

ALTER TABLE omnex_system_core.tenant_subscription
    DROP CONSTRAINT IF EXISTS chk_tenant_subscription_grace;

ALTER TABLE omnex_system_core.tenant_subscription
    ADD CONSTRAINT chk_tenant_subscription_grace
        CHECK (
            grace_end_at IS NULL
            OR grace_end_at >= end_at
        );

DROP INDEX IF EXISTS omnex_system_core.uq_tenant_current_subscription;

CREATE UNIQUE INDEX uq_tenant_current_subscription
ON omnex_system_core.tenant_subscription (tenant_id)
WHERE is_current = true;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
ALTER TABLE omnex_system_core.tenant_subscription
    DROP CONSTRAINT IF EXISTS fk_tenant_subscription_tenant;

ALTER TABLE omnex_system_core.tenant_subscription
    ADD CONSTRAINT fk_tenant_subscription_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES omnex_system_core.tenant (tenant_id)
        ON DELETE RESTRICT;

ALTER TABLE omnex_system_core.tenant_subscription
    DROP CONSTRAINT IF EXISTS fk_tenant_subscription_plan;

ALTER TABLE omnex_system_core.tenant_subscription
    ADD CONSTRAINT fk_tenant_subscription_plan
        FOREIGN KEY (plan_id)
        REFERENCES omnex_system_core.subscription_plan (plan_id)
        ON DELETE RESTRICT;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_subscription_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF (
            OLD.tenant_id    IS DISTINCT FROM NEW.tenant_id OR
            OLD.plan_id      IS DISTINCT FROM NEW.plan_id OR
            OLD.start_at     IS DISTINCT FROM NEW.start_at OR
            OLD.end_at       IS DISTINCT FROM NEW.end_at OR
            OLD.grace_end_at IS DISTINCT FROM NEW.grace_end_at OR
            OLD.created_at   IS DISTINCT FROM NEW.created_at
        ) THEN
            RAISE EXCEPTION
                'OMNEX SUBSCRIPTION VIOLATION: subscription records are immutable';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX SUBSCRIPTION VIOLATION: subscriptions cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tenant_subscription_rules
ON omnex_system_core.tenant_subscription;

CREATE TRIGGER trg_enforce_tenant_subscription_rules
BEFORE UPDATE OR DELETE ON omnex_system_core.tenant_subscription
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_tenant_subscription_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_subscription
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_tenant_subscription
ON omnex_system_core.tenant_subscription;

CREATE POLICY deny_all_tenant_subscription
ON omnex_system_core.tenant_subscription
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_tenant_subscription
ON omnex_system_core.tenant_subscription IS
'Default deny-all; tenant subscription access governed centrally';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_subscription_tenant
ON omnex_system_core.tenant_subscription (tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_subscription_current
ON omnex_system_core.tenant_subscription (tenant_id)
WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_tenant_subscription_end
ON omnex_system_core.tenant_subscription (end_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 021 — TENANT SUBSCRIPTION LIFECYCLE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_022
-- ENGINE NAME: Tenant State Machine
-- ENGINE FUNCTION: Governs tenant operational state transitions with immutable historical records.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_state_history (
    state_history_id uuid PRIMARY KEY,
    tenant_id        uuid NOT NULL,
    state_code       text NOT NULL,
    changed_by       text NOT NULL,
    changed_at       timestamptz NOT NULL,
    reason           text
);

COMMENT ON TABLE omnex_system_core.tenant_state_history IS
'Immutable history of tenant operational state transitions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_tenant_state_code'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_state_history
            ADD CONSTRAINT chk_tenant_state_code
            CHECK (length(state_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_tenant_state_changed_by'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_state_history
            ADD CONSTRAINT chk_tenant_state_changed_by
            CHECK (length(changed_by) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_tenant_state_history_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_state_history
            ADD CONSTRAINT fk_tenant_state_history_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_state_history_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX TENANT STATE VIOLATION: state history records are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX TENANT STATE VIOLATION: state history records cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tenant_state_history_immutability
ON omnex_system_core.tenant_state_history;

CREATE TRIGGER trg_enforce_tenant_state_history_immutability
BEFORE UPDATE OR DELETE
ON omnex_system_core.tenant_state_history
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_tenant_state_history_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_state_history
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_tenant_state_history
ON omnex_system_core.tenant_state_history;

CREATE POLICY deny_all_tenant_state_history
ON omnex_system_core.tenant_state_history
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_tenant_state_history
ON omnex_system_core.tenant_state_history IS
'Default deny-all; tenant state transitions are centrally governed';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_state_history_tenant
ON omnex_system_core.tenant_state_history (tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_state_history_latest
ON omnex_system_core.tenant_state_history (tenant_id, changed_at DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 022 — TENANT STATE MACHINE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_023
-- ENGINE NAME: Licensing & Entitlement
-- ENGINE FUNCTION: Defines and enforces subscription-level entitlements, engine access, and quantitative limits.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.subscription_license (
    license_id        uuid PRIMARY KEY,
    subscription_id   uuid NOT NULL,
    engine_code       text NOT NULL,
    full_domain_stack boolean NOT NULL DEFAULT false,

    max_users         integer,
    max_branches      integer,
    max_storage_mb    integer,
    max_ai_calls      integer,

    created_at        timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.subscription_license IS
'Authoritative entitlements granted by a subscription';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_subscription_license_engine_code'
    ) THEN
        ALTER TABLE omnex_system_core.subscription_license
            ADD CONSTRAINT chk_subscription_license_engine_code
            CHECK (length(engine_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_subscription_license_positive_limits'
    ) THEN
        ALTER TABLE omnex_system_core.subscription_license
            ADD CONSTRAINT chk_subscription_license_positive_limits
            CHECK (
                (max_users IS NULL OR max_users > 0)
            AND (max_branches IS NULL OR max_branches > 0)
            AND (max_storage_mb IS NULL OR max_storage_mb > 0)
            AND (max_ai_calls IS NULL OR max_ai_calls > 0)
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_subscription_license_subscription'
    ) THEN
        ALTER TABLE omnex_system_core.subscription_license
            ADD CONSTRAINT fk_subscription_license_subscription
            FOREIGN KEY (subscription_id)
            REFERENCES omnex_system_core.tenant_subscription (subscription_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- One entitlement per engine per subscription
CREATE UNIQUE INDEX IF NOT EXISTS uq_subscription_license_engine
ON omnex_system_core.subscription_license (subscription_id, engine_code);

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.subscription_license
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'subscription_license'
          AND policyname = 'deny_all_subscription_license'
    ) THEN
        CREATE POLICY deny_all_subscription_license
        ON omnex_system_core.subscription_license
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_subscription_license
        ON omnex_system_core.subscription_license IS
        'Default deny-all; entitlements are governed centrally by ALSE';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_subscription_license_subscription
ON omnex_system_core.subscription_license (subscription_id);

CREATE INDEX IF NOT EXISTS idx_subscription_license_engine
ON omnex_system_core.subscription_license (engine_code);

COMMIT;

-- ============================================================
-- END OF ENGINE 023 — LICENSING & ENTITLEMENT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_024
-- ENGINE NAME: Payment & Verification
-- ENGINE FUNCTION: Records and verifies all payments from external financial providers.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.payment (
    payment_id          uuid PRIMARY KEY,
    tenant_id           uuid NOT NULL,
    plan_id             uuid NOT NULL,
    provider_code       text NOT NULL,
    external_reference  text NOT NULL,
    amount              numeric(18,2) NOT NULL,
    currency            char(3) NOT NULL,
    paid_at             timestamptz NOT NULL,
    verification_status text NOT NULL,
    settled             boolean NOT NULL DEFAULT false
);

COMMENT ON TABLE omnex_system_core.payment IS
'Authoritative record of payments from external financial providers';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_payment_provider_code'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT chk_payment_provider_code
            CHECK (length(provider_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_payment_external_reference'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT chk_payment_external_reference
            CHECK (length(external_reference) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_payment_amount_positive'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT chk_payment_amount_positive
            CHECK (amount > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_payment_currency_iso'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT chk_payment_currency_iso
            CHECK (currency ~ '^[A-Z]{3}$');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_payment_verification_status'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT chk_payment_verification_status
            CHECK (verification_status IN ('pending','verified','rejected'));
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_payment_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT fk_payment_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_payment_plan'
    ) THEN
        ALTER TABLE omnex_system_core.payment
            ADD CONSTRAINT fk_payment_plan
            FOREIGN KEY (plan_id)
            REFERENCES omnex_system_core.subscription_plan (plan_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Enforce verification-settlement safety
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_payment_settlement_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.settled = true AND NEW.verification_status <> 'verified' THEN
        RAISE EXCEPTION
            'OMNEX PAYMENT VIOLATION: payment cannot be settled unless verified';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_payment_settlement_rules
ON omnex_system_core.payment;

CREATE TRIGGER trg_enforce_payment_settlement_rules
BEFORE INSERT OR UPDATE ON omnex_system_core.payment
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_payment_settlement_rules();

-- Enforce external_reference uniqueness per provider
CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_external_reference
ON omnex_system_core.payment (provider_code, external_reference);

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.payment
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'payment'
          AND policyname = 'deny_all_payment'
    ) THEN
        CREATE POLICY deny_all_payment
        ON omnex_system_core.payment
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_payment
        ON omnex_system_core.payment IS
        'Default deny-all; payment records are centrally governed';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_payment_tenant
ON omnex_system_core.payment (tenant_id);

CREATE INDEX IF NOT EXISTS idx_payment_plan
ON omnex_system_core.payment (plan_id);

CREATE INDEX IF NOT EXISTS idx_payment_paid_at
ON omnex_system_core.payment (paid_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_verification_status
ON omnex_system_core.payment (verification_status);

COMMIT;

-- ============================================================
-- END OF ENGINE 024 — PAYMENT & VERIFICATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_025
-- ENGINE NAME: Activation & Renewal
-- ENGINE FUNCTION: Converts verified payments into time-bound activation capability via controlled activation codes.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.activation_code (
    activation_id        uuid PRIMARY KEY,
    tenant_id            uuid NOT NULL,
    payment_id           uuid NOT NULL,
    activation_code_hash text NOT NULL,
    issued_at            timestamptz NOT NULL,
    expires_at           timestamptz NOT NULL,
    consumed             boolean NOT NULL DEFAULT false,
    consumed_at          timestamptz
);

COMMENT ON TABLE omnex_system_core.activation_code IS
'Activation codes converting verified payments into time-bound system access';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_activation_code_hash'
    ) THEN
        ALTER TABLE omnex_system_core.activation_code
            ADD CONSTRAINT chk_activation_code_hash
            CHECK (length(activation_code_hash) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_activation_time_window'
    ) THEN
        ALTER TABLE omnex_system_core.activation_code
            ADD CONSTRAINT chk_activation_time_window
            CHECK (expires_at > issued_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_activation_consumption_consistency'
    ) THEN
        ALTER TABLE omnex_system_core.activation_code
            ADD CONSTRAINT chk_activation_consumption_consistency
            CHECK (
                (consumed = false AND consumed_at IS NULL)
             OR (consumed = true  AND consumed_at IS NOT NULL)
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_activation_code_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.activation_code
            ADD CONSTRAINT fk_activation_code_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_activation_code_payment'
    ) THEN
        ALTER TABLE omnex_system_core.activation_code
            ADD CONSTRAINT fk_activation_code_payment
            FOREIGN KEY (payment_id)
            REFERENCES omnex_system_core.payment (payment_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE UNIQUE INDEX IF NOT EXISTS uq_activation_code_hash
ON omnex_system_core.activation_code (activation_code_hash);

CREATE OR REPLACE FUNCTION omnex_system_core.enforce_activation_code_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.consumed = true AND NEW.expires_at <= now() THEN
        RAISE EXCEPTION
            'OMNEX ACTIVATION VIOLATION: activation code has expired';
    END IF;

    IF TG_OP = 'UPDATE'
       AND OLD.consumed = true
       AND NEW.consumed = true THEN
        RAISE EXCEPTION
            'OMNEX ACTIVATION VIOLATION: activation code already consumed';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_activation_code_rules
ON omnex_system_core.activation_code;

CREATE TRIGGER trg_enforce_activation_code_rules
BEFORE INSERT OR UPDATE ON omnex_system_core.activation_code
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_activation_code_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.activation_code
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'activation_code'
          AND policyname = 'deny_all_activation_code'
    ) THEN
        CREATE POLICY deny_all_activation_code
        ON omnex_system_core.activation_code
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_activation_code
        ON omnex_system_core.activation_code IS
        'Default deny-all; activation governed centrally';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_activation_code_tenant
ON omnex_system_core.activation_code (tenant_id);

CREATE INDEX IF NOT EXISTS idx_activation_code_payment
ON omnex_system_core.activation_code (payment_id);

CREATE INDEX IF NOT EXISTS idx_activation_code_expires
ON omnex_system_core.activation_code (expires_at);

CREATE INDEX IF NOT EXISTS idx_activation_code_consumed
ON omnex_system_core.activation_code (consumed);

COMMIT;

-- ============================================================
-- END OF ENGINE 025 — ACTIVATION & RENEWAL
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_026
-- ENGINE NAME: Grace Period & Enforcement Window
-- ENGINE FUNCTION: Tracks tenant grace period after subscription expiry and when degradation enforcement begins.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_grace_window (
    grace_id             uuid PRIMARY KEY,
    tenant_id            uuid NOT NULL,
    plan_id              uuid NOT NULL,
    original_expiry_at   timestamptz NOT NULL,
    grace_starts_at      timestamptz NOT NULL,
    grace_ends_at        timestamptz NOT NULL,
    enforced_at          timestamptz,
    enforcement_trigger  text,
    audit_note           text,
    created_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.tenant_grace_window IS
'Tracks tenant grace period after subscription expiry and when enforcement is triggered';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_grace_window_temporal_validity'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_grace_window
            ADD CONSTRAINT chk_grace_window_temporal_validity
            CHECK (
                grace_starts_at >= original_expiry_at AND
                grace_ends_at   >  grace_starts_at
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_grace_window_enforced_at_valid'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_grace_window
            ADD CONSTRAINT chk_grace_window_enforced_at_valid
            CHECK (
                enforced_at IS NULL OR enforced_at >= grace_ends_at
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_grace_window_audit_note_limit'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_grace_window
            ADD CONSTRAINT chk_grace_window_audit_note_limit
            CHECK (audit_note IS NULL OR length(audit_note) <= 1000);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_grace_window_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_grace_window
            ADD CONSTRAINT fk_grace_window_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_grace_window_plan'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_grace_window
            ADD CONSTRAINT fk_grace_window_plan
            FOREIGN KEY (plan_id)
            REFERENCES omnex_system_core.subscription_plan (plan_id)
            ON DELETE SET NULL;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_grace_window_mutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.enforced_at IS NOT NULL THEN
        RAISE EXCEPTION
            'OMNEX GRACE WINDOW VIOLATION: record already enforced; update not allowed';
    END IF;

    IF TG_OP = 'DELETE' AND OLD.enforced_at IS NOT NULL THEN
        RAISE EXCEPTION
            'OMNEX GRACE WINDOW VIOLATION: enforced records cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_grace_window_mutability
ON omnex_system_core.tenant_grace_window;

CREATE TRIGGER trg_enforce_grace_window_mutability
BEFORE UPDATE OR DELETE ON omnex_system_core.tenant_grace_window
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_grace_window_mutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_grace_window
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_grace_window'
          AND policyname = 'deny_all_grace_window'
    ) THEN
        CREATE POLICY deny_all_grace_window
        ON omnex_system_core.tenant_grace_window
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_grace_window
        ON omnex_system_core.tenant_grace_window IS
        'Default deny-all; grace window records centrally governed';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_grace_window_tenant
ON omnex_system_core.tenant_grace_window (tenant_id);

CREATE INDEX IF NOT EXISTS idx_grace_window_plan
ON omnex_system_core.tenant_grace_window (plan_id);

CREATE INDEX IF NOT EXISTS idx_grace_window_expiry
ON omnex_system_core.tenant_grace_window (grace_ends_at);

CREATE INDEX IF NOT EXISTS idx_grace_window_enforced
ON omnex_system_core.tenant_grace_window (enforced_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 026 — GRACE PERIOD & ENFORCEMENT WINDOW
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_027
-- ENGINE NAME: Override, Repair & Support
-- ENGINE FUNCTION: Enables controlled repair of payment or activation failures with audit.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.alse_override (
    override_id    uuid PRIMARY KEY,
    tenant_id      uuid NOT NULL,
    override_type  text NOT NULL,
    reference_id   uuid,
    performed_by   text NOT NULL,
    justification  text NOT NULL,
    performed_at   timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.alse_override IS
'Controlled override and repair actions with full audit justification';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_override_type'
    ) THEN
        ALTER TABLE omnex_system_core.alse_override
            ADD CONSTRAINT chk_override_type
            CHECK (length(override_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_override_performed_by'
    ) THEN
        ALTER TABLE omnex_system_core.alse_override
            ADD CONSTRAINT chk_override_performed_by
            CHECK (length(performed_by) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_override_justification'
    ) THEN
        ALTER TABLE omnex_system_core.alse_override
            ADD CONSTRAINT chk_override_justification
            CHECK (length(justification) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_alse_override_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.alse_override
            ADD CONSTRAINT fk_alse_override_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_override_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX OVERRIDE VIOLATION: override records are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX OVERRIDE VIOLATION: override records cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_override_immutability
ON omnex_system_core.alse_override;

CREATE TRIGGER trg_enforce_override_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.alse_override
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_override_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.alse_override
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'alse_override'
          AND policyname = 'deny_all_alse_override'
    ) THEN
        CREATE POLICY deny_all_alse_override
        ON omnex_system_core.alse_override
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_alse_override
        ON omnex_system_core.alse_override IS
        'Default deny-all; override actions are governed centrally by platform owners';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_alse_override_tenant
ON omnex_system_core.alse_override (tenant_id);

CREATE INDEX IF NOT EXISTS idx_alse_override_type
ON omnex_system_core.alse_override (override_type);

CREATE INDEX IF NOT EXISTS idx_alse_override_performed_at
ON omnex_system_core.alse_override (performed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 027 — OVERRIDE, REPAIR & SUPPORT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_028
-- ENGINE NAME: Security, Fraud & Alerting
-- ENGINE FUNCTION: Detects fraud, abuse, and anomalous behavior across subscriptions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.alse_security_event (
    security_event_id uuid PRIMARY KEY,
    tenant_id         uuid NOT NULL,
    event_type        text NOT NULL,
    severity          text NOT NULL,
    description       text,
    source_ip         inet,
    occurred_at       timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.alse_security_event IS
'Immutable security, fraud, and anomaly events for tenant subscriptions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_security_event_type'
    ) THEN
        ALTER TABLE omnex_system_core.alse_security_event
            ADD CONSTRAINT chk_security_event_type
            CHECK (length(event_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_security_event_severity'
    ) THEN
        ALTER TABLE omnex_system_core.alse_security_event
            ADD CONSTRAINT chk_security_event_severity
            CHECK (severity IN ('low', 'medium', 'high', 'critical'));
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_alse_security_event_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.alse_security_event
            ADD CONSTRAINT fk_alse_security_event_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_security_event_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX SECURITY VIOLATION: security events are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX SECURITY VIOLATION: security events cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_security_event_immutability
ON omnex_system_core.alse_security_event;

CREATE TRIGGER trg_enforce_security_event_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.alse_security_event
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_security_event_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.alse_security_event
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'alse_security_event'
          AND policyname = 'deny_all_alse_security_event'
    ) THEN
        CREATE POLICY deny_all_alse_security_event
        ON omnex_system_core.alse_security_event
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_alse_security_event
        ON omnex_system_core.alse_security_event IS
        'Default deny-all; security events are governed by platform security';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_alse_security_event_tenant
ON omnex_system_core.alse_security_event (tenant_id);

CREATE INDEX IF NOT EXISTS idx_alse_security_event_type
ON omnex_system_core.alse_security_event (event_type);

CREATE INDEX IF NOT EXISTS idx_alse_security_event_severity
ON omnex_system_core.alse_security_event (severity);

CREATE INDEX IF NOT EXISTS idx_alse_security_event_occurred_at
ON omnex_system_core.alse_security_event (occurred_at);

CREATE INDEX IF NOT EXISTS idx_alse_security_event_source_ip
ON omnex_system_core.alse_security_event (source_ip);

COMMIT;

-- ============================================================
-- END OF ENGINE 028 — SECURITY, FRAUD & ALERTING
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_029
-- ENGINE NAME: System Owner & Governance
-- ENGINE FUNCTION: Records authoritative actions taken by platform owner roles for governance.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_owner_action (
    owner_action_id uuid PRIMARY KEY,
    action_type     text NOT NULL,
    parameters      jsonb,
    performed_by    text NOT NULL,
    performed_at    timestamptz NOT NULL
);

COMMENT ON TABLE omnex_system_core.system_owner_action IS
'Immutable record of platform owner governance actions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_owner_action_type'
    ) THEN
        ALTER TABLE omnex_system_core.system_owner_action
            ADD CONSTRAINT chk_owner_action_type
            CHECK (length(action_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_owner_action_performed_by'
    ) THEN
        ALTER TABLE omnex_system_core.system_owner_action
            ADD CONSTRAINT chk_owner_action_performed_by
            CHECK (length(performed_by) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None (platform sovereign authority)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_owner_action_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: system owner actions are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: system owner actions cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_owner_action_immutability
ON omnex_system_core.system_owner_action;

CREATE TRIGGER trg_enforce_owner_action_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.system_owner_action
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_owner_action_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_owner_action
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_owner_action'
          AND policyname = 'deny_all_system_owner_action'
    ) THEN
        CREATE POLICY deny_all_system_owner_action
        ON omnex_system_core.system_owner_action
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_owner_action
        ON omnex_system_core.system_owner_action IS
        'Default deny-all; system owner governance actions are highly restricted';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_owner_action_type
ON omnex_system_core.system_owner_action (action_type);

CREATE INDEX IF NOT EXISTS idx_system_owner_action_performed_by
ON omnex_system_core.system_owner_action (performed_by);

CREATE INDEX IF NOT EXISTS idx_system_owner_action_performed_at
ON omnex_system_core.system_owner_action (performed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 029 — SYSTEM OWNER & GOVERNANCE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_030
-- ENGINE NAME: Audit, Evidence & Compliance
-- ENGINE FUNCTION: Maintains immutable audit trails for legal and regulatory evidence.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.alse_audit_log (
    audit_id        uuid PRIMARY KEY,
    entity_type     text NOT NULL,
    entity_id       uuid NOT NULL,
    action          text NOT NULL,
    actor_id        uuid,
    actor_type      text NOT NULL,
    occurred_at     timestamptz NOT NULL,
    immutable_hash  text NOT NULL
);

COMMENT ON TABLE omnex_system_core.alse_audit_log IS
'Immutable audit log for legal, regulatory, and forensic evidence';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_entity_type'
    ) THEN
        ALTER TABLE omnex_system_core.alse_audit_log
            ADD CONSTRAINT chk_audit_entity_type
            CHECK (length(entity_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_action'
    ) THEN
        ALTER TABLE omnex_system_core.alse_audit_log
            ADD CONSTRAINT chk_audit_action
            CHECK (length(action) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_actor_type'
    ) THEN
        ALTER TABLE omnex_system_core.alse_audit_log
            ADD CONSTRAINT chk_audit_actor_type
            CHECK (length(actor_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_hash_length'
    ) THEN
        ALTER TABLE omnex_system_core.alse_audit_log
            ADD CONSTRAINT chk_audit_hash_length
            CHECK (length(immutable_hash) >= 64);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- No foreign keys — evidence must survive external deletions

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_audit_log_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX AUDIT VIOLATION: audit records are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX AUDIT VIOLATION: audit records cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_alse_audit_log_immutability
ON omnex_system_core.alse_audit_log;

CREATE TRIGGER trg_enforce_alse_audit_log_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.alse_audit_log
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_audit_log_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.alse_audit_log
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'alse_audit_log'
          AND policyname = 'deny_all_alse_audit_log'
    ) THEN
        CREATE POLICY deny_all_alse_audit_log
        ON omnex_system_core.alse_audit_log
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_alse_audit_log
        ON omnex_system_core.alse_audit_log IS
        'Default deny-all; audit evidence is accessed only via controlled services';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_alse_audit_entity
ON omnex_system_core.alse_audit_log (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_alse_audit_occurred_at
ON omnex_system_core.alse_audit_log (occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_alse_audit_actor
ON omnex_system_core.alse_audit_log (actor_type, actor_id);

COMMIT;

-- ============================================================
-- END OF ENGINE 030 — AUDIT, EVIDENCE & COMPLIANCE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_031
-- ENGINE NAME: Tenant Operational Identity
-- ENGINE FUNCTION: Defines tenants as operational system actors with runtime isolation and execution boundaries.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_runtime_identity (
    runtime_tenant_id   uuid PRIMARY KEY,
    tenant_id           uuid NOT NULL,

    runtime_code        text NOT NULL,
    isolation_model     text NOT NULL,
    owning_org_unit     text,
    environment_scope   text NOT NULL,

    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.tenant_runtime_identity IS
'Defines tenants as operational runtime actors with isolation, ownership, and environment scope';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_runtime_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_identity
            ADD CONSTRAINT chk_runtime_code_not_empty
            CHECK (length(runtime_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_isolation_model_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_identity
            ADD CONSTRAINT chk_isolation_model_not_empty
            CHECK (length(isolation_model) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_environment_scope_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_identity
            ADD CONSTRAINT chk_environment_scope_not_empty
            CHECK (length(environment_scope) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_tenant_runtime_environment'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_identity
            ADD CONSTRAINT uq_tenant_runtime_environment
            UNIQUE (tenant_id, environment_scope);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_runtime_identity_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_identity
            ADD CONSTRAINT fk_runtime_identity_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.touch_runtime_identity_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_runtime_identity_updated_at
ON omnex_system_core.tenant_runtime_identity;

CREATE TRIGGER trg_touch_runtime_identity_updated_at
BEFORE UPDATE ON omnex_system_core.tenant_runtime_identity
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.touch_runtime_identity_updated_at();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_runtime_identity
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_runtime_identity'
          AND policyname = 'deny_all_tenant_runtime_identity'
    ) THEN
        CREATE POLICY deny_all_tenant_runtime_identity
        ON omnex_system_core.tenant_runtime_identity
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant_runtime_identity
        ON omnex_system_core.tenant_runtime_identity IS
        'Runtime tenant identity is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_runtime_identity_tenant
ON omnex_system_core.tenant_runtime_identity (tenant_id);

CREATE INDEX IF NOT EXISTS idx_runtime_identity_environment
ON omnex_system_core.tenant_runtime_identity (environment_scope);

COMMIT;

-- ============================================================
-- END OF ENGINE 031 — TENANT OPERATIONAL IDENTITY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_032
-- ENGINE NAME: Tenant System Membership
-- ENGINE FUNCTION:
--   Associates operational tenant runtime identities with the systems
--   they are authorized to operate within.

-- VERSION: v1.1
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_system_membership (
    membership_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    runtime_tenant_id  uuid NOT NULL,
    system_id          uuid NOT NULL,
    membership_role    text NOT NULL,
    active             boolean NOT NULL DEFAULT true,
    granted_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.tenant_system_membership IS
'Associates operational tenant runtime identities with systems they are authorized to operate within';

-- ==========================
-- PHASE 3B: COLUMN REPAIR (BIGINT → UUID)
-- ==========================
DO $$
DECLARE
    col_type text;
BEGIN
    SELECT data_type
    INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'omnex_system_core'
      AND table_name = 'tenant_system_membership'
      AND column_name = 'system_id';

    IF col_type = 'bigint' THEN
        ALTER TABLE omnex_system_core.tenant_system_membership
            ALTER COLUMN system_id TYPE uuid
            USING gen_random_uuid();
    END IF;
END $$;

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_membership_role_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_system_membership
            ADD CONSTRAINT chk_membership_role_not_empty
            CHECK (length(membership_role) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_runtime_tenant_system'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_system_membership
            ADD CONSTRAINT uq_runtime_tenant_system
            UNIQUE (runtime_tenant_id, system_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    ALTER TABLE omnex_system_core.tenant_system_membership
        DROP CONSTRAINT IF EXISTS fk_membership_system_registry;

    ALTER TABLE omnex_system_core.tenant_system_membership
        DROP CONSTRAINT IF EXISTS fk_membership_runtime_tenant;

    ALTER TABLE omnex_system_core.tenant_system_membership
        ADD CONSTRAINT fk_membership_runtime_tenant
        FOREIGN KEY (runtime_tenant_id)
        REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
        ON DELETE RESTRICT;

    ALTER TABLE omnex_system_core.tenant_system_membership
        ADD CONSTRAINT fk_membership_system_registry
        FOREIGN KEY (system_id)
        REFERENCES omnex_system_core.system_registry (system_id)
        ON DELETE RESTRICT;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_system_membership_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: tenant system memberships cannot be deleted; deactivate instead';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tenant_system_membership_immutability
ON omnex_system_core.tenant_system_membership;

CREATE TRIGGER trg_enforce_tenant_system_membership_immutability
BEFORE DELETE
ON omnex_system_core.tenant_system_membership
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_tenant_system_membership_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_system_membership
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_tenant_system_membership
ON omnex_system_core.tenant_system_membership;

CREATE POLICY deny_all_tenant_system_membership
ON omnex_system_core.tenant_system_membership
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_tenant_system_membership
ON omnex_system_core.tenant_system_membership IS
'System memberships are centrally governed; default deny-all access';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_membership_runtime_tenant
ON omnex_system_core.tenant_system_membership (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_membership_system
ON omnex_system_core.tenant_system_membership (system_id);

CREATE INDEX IF NOT EXISTS idx_membership_active
ON omnex_system_core.tenant_system_membership (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 032 — TENANT SYSTEM MEMBERSHIP
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_033
-- ENGINE NAME: Tenant Runtime Operational State
-- ENGINE FUNCTION:
--   Governs operational runtime states of tenants independent
--   of billing, licensing, or payment status. Enables controlled
--   execution, lifecycle enforcement, and audit of runtime states.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;


-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_runtime_state (
    runtime_state_id   uuid PRIMARY KEY,
    runtime_tenant_id  uuid NOT NULL,
    state_code         text NOT NULL,
    effective_from     timestamptz NOT NULL DEFAULT now(),
    effective_to       timestamptz,
    changed_by         uuid NOT NULL
);

COMMENT ON TABLE omnex_system_core.tenant_runtime_state IS
'Tracks operational runtime state transitions for tenants independent of commercial lifecycle';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_runtime_state_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state
            ADD CONSTRAINT chk_runtime_state_code_not_empty
            CHECK (length(state_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_effective_window_valid'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state
            ADD CONSTRAINT chk_effective_window_valid
            CHECK (effective_to IS NULL OR effective_to > effective_from);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_single_active_runtime_state'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state
            ADD CONSTRAINT uq_single_active_runtime_state
            UNIQUE (runtime_tenant_id)
            DEFERRABLE INITIALLY DEFERRED;
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_runtime_state_runtime_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state
            ADD CONSTRAINT fk_runtime_state_runtime_tenant
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_runtime_state_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: runtime states are immutable; close state using effective_to instead';
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.state_code <> NEW.state_code THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: runtime state_code cannot be modified; insert a new state row';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_runtime_state_immutability
ON omnex_system_core.tenant_runtime_state;

CREATE TRIGGER trg_enforce_runtime_state_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.tenant_runtime_state
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_runtime_state_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_runtime_state
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_runtime_state'
          AND policyname = 'deny_all_tenant_runtime_state'
    ) THEN
        CREATE POLICY deny_all_tenant_runtime_state
        ON omnex_system_core.tenant_runtime_state
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant_runtime_state
        ON omnex_system_core.tenant_runtime_state IS
        'Runtime operational states are centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_runtime_state_runtime_tenant
ON omnex_system_core.tenant_runtime_state (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_runtime_state_code
ON omnex_system_core.tenant_runtime_state (state_code);

CREATE INDEX IF NOT EXISTS idx_runtime_state_effective
ON omnex_system_core.tenant_runtime_state (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 033 — TENANT RUNTIME OPERATIONAL STATE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_034
-- ENGINE NAME: Tenant Runtime State History
-- ENGINE FUNCTION:
--   Maintains a complete, immutable audit trail of tenant runtime
--   operational state transitions, independent of billing or subscription.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_runtime_state_history (
    state_history_id   uuid PRIMARY KEY,
    runtime_tenant_id  uuid NOT NULL,

    previous_state     text,
    new_state          text NOT NULL,

    transition_reason  text NOT NULL,
    transitioned_by    text NOT NULL,
    transitioned_at    timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.tenant_runtime_state_history IS
'Immutable audit history of tenant runtime operational state transitions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_runtime_state_history_new_state'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state_history
            ADD CONSTRAINT chk_runtime_state_history_new_state
            CHECK (length(new_state) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_runtime_state_history_reason'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state_history
            ADD CONSTRAINT chk_runtime_state_history_reason
            CHECK (length(transition_reason) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_runtime_state_history_transitioned_by'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state_history
            ADD CONSTRAINT chk_runtime_state_history_transitioned_by
            CHECK (length(transitioned_by) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_runtime_state_history_runtime_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_runtime_state_history
            ADD CONSTRAINT fk_runtime_state_history_runtime_tenant
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_runtime_state_history_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: runtime state history records are immutable';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: runtime state history records cannot be deleted';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_runtime_state_history_immutability
ON omnex_system_core.tenant_runtime_state_history;

CREATE TRIGGER trg_enforce_runtime_state_history_immutability
BEFORE UPDATE OR DELETE
ON omnex_system_core.tenant_runtime_state_history
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_runtime_state_history_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_runtime_state_history
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_runtime_state_history'
          AND policyname = 'deny_all_tenant_runtime_state_history'
    ) THEN
        CREATE POLICY deny_all_tenant_runtime_state_history
        ON omnex_system_core.tenant_runtime_state_history
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant_runtime_state_history
        ON omnex_system_core.tenant_runtime_state_history IS
        'Runtime state history is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_runtime_state_history_runtime_tenant
ON omnex_system_core.tenant_runtime_state_history (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_runtime_state_history_new_state
ON omnex_system_core.tenant_runtime_state_history (new_state);

CREATE INDEX IF NOT EXISTS idx_runtime_state_history_transitioned_at
ON omnex_system_core.tenant_runtime_state_history (transitioned_at DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 034 — TENANT RUNTIME STATE HISTORY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_036
-- ENGINE NAME: System Tagging Framework
-- ENGINE FUNCTION:
--   Applies structured, domain-aligned tags to systems for categorization,
--   grouping, or operational logic mapping. Enables decoupled routing,
--   labeling, and identity overlay on registered systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_tag (
    tag_id           uuid PRIMARY KEY,
    system_id        bigint NOT NULL,
    tag_key          text NOT NULL,
    tag_value        text NOT NULL,
    tagged_at        timestamptz NOT NULL DEFAULT now(),
    active           boolean NOT NULL DEFAULT true
);

COMMENT ON TABLE omnex_system_core.system_tag IS
'Applies structured tags to systems within the Omnex registry for classification, routing, and labeling';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_tag_key_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_tag
            ADD CONSTRAINT chk_tag_key_not_empty
            CHECK (length(tag_key) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_tag_value_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_tag
            ADD CONSTRAINT chk_tag_value_not_empty
            CHECK (length(tag_value) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_system_tag'
    ) THEN
        ALTER TABLE omnex_system_core.system_tag
            ADD CONSTRAINT uq_system_tag
            UNIQUE (system_id, tag_key);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_system_tag_system_registry'
    ) THEN
        ALTER TABLE omnex_system_core.system_tag
            ADD CONSTRAINT fk_system_tag_system_registry
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_system_tag_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: tags may not be deleted; deactivate instead';
    END IF;

    IF TG_OP = 'UPDATE' AND (OLD.tag_key <> NEW.tag_key OR OLD.tag_value <> NEW.tag_value) THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: tags are immutable once assigned';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_system_tag_immutability
ON omnex_system_core.system_tag;

CREATE TRIGGER trg_enforce_system_tag_immutability
BEFORE UPDATE OR DELETE
ON omnex_system_core.system_tag
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_system_tag_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_tag
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_tag'
          AND policyname = 'deny_all_system_tag'
    ) THEN
        CREATE POLICY deny_all_system_tag
        ON omnex_system_core.system_tag
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_tag
        ON omnex_system_core.system_tag IS
        'System tagging is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_tag_system
ON omnex_system_core.system_tag (system_id);

CREATE INDEX IF NOT EXISTS idx_system_tag_key
ON omnex_system_core.system_tag (tag_key);

CREATE INDEX IF NOT EXISTS idx_system_tag_active
ON omnex_system_core.system_tag (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 036 — SYSTEM TAGGING FRAMEWORK
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_037
-- ENGINE NAME: System Capability Exposure
-- ENGINE FUNCTION:
--   Declares engines, APIs, AI features, and capabilities exposed by each system.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- Optional: none required at this stage.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_capability (
    capability_id     uuid PRIMARY KEY,
    system_id         bigint NOT NULL,
    capability_code   text NOT NULL,
    capability_type   text NOT NULL,
    version           text NOT NULL,
    exposed           boolean NOT NULL DEFAULT true,
    created_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_capability IS
'Declares capabilities exposed by a system — e.g., APIs, engines, AI features';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_capability_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_capability
            ADD CONSTRAINT chk_capability_code_not_empty
            CHECK (length(capability_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_capability_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_capability
            ADD CONSTRAINT chk_capability_type_not_empty
            CHECK (length(capability_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_capability_version_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_capability
            ADD CONSTRAINT chk_capability_version_not_empty
            CHECK (length(version) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_system_capability_unique'
    ) THEN
        ALTER TABLE omnex_system_core.system_capability
            ADD CONSTRAINT uq_system_capability_unique
            UNIQUE (system_id, capability_code, version);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_system_capability_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_capability
            ADD CONSTRAINT fk_system_capability_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional immutability logic can be added later if needed.

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_capability
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_capability'
          AND policyname = 'deny_all_system_capability'
    ) THEN
        CREATE POLICY deny_all_system_capability
        ON omnex_system_core.system_capability
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_capability
        ON omnex_system_core.system_capability IS
        'System capabilities are centrally declared; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_capability_system
ON omnex_system_core.system_capability (system_id);

CREATE INDEX IF NOT EXISTS idx_system_capability_code
ON omnex_system_core.system_capability (capability_code);

CREATE INDEX IF NOT EXISTS idx_system_capability_type
ON omnex_system_core.system_capability (capability_type);

CREATE INDEX IF NOT EXISTS idx_system_capability_exposed
ON omnex_system_core.system_capability (exposed);

COMMIT;

-- ============================================================
-- END OF ENGINE 037 — SYSTEM CAPABILITY EXPOSURE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_038
-- ENGINE NAME: Tenant Capability State
-- ENGINE FUNCTION:
--   Tracks and governs the temporal activation state of system capabilities
--   for runtime tenants. Enables lifecycle control, auditability, and
--   operational risk containment over tenant-specific capabilities.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_capability_state (
    state_id          uuid PRIMARY KEY,
    runtime_tenant_id uuid NOT NULL,
    capability_id     uuid NOT NULL,
    state_code        text NOT NULL,  -- ENABLED, DISABLED, EXPIRED, etc.
    reason_code       text,           -- Optional governance or business reason
    effective_from    timestamptz NOT NULL DEFAULT now(),
    effective_to      timestamptz,
    recorded_at       timestamptz NOT NULL DEFAULT now(),
    recorded_by       text NOT NULL
);

COMMENT ON TABLE omnex_system_core.tenant_capability_state IS
'Tracks the lifecycle and runtime state of system capabilities per tenant. Used for capability gating, enforcement, expiry, and compliance handling.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_state_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_capability_state
            ADD CONSTRAINT chk_state_code_not_empty
            CHECK (length(state_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_recorded_by_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_capability_state
            ADD CONSTRAINT chk_recorded_by_not_empty
            CHECK (length(recorded_by) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_effective_range_valid'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_capability_state
            ADD CONSTRAINT chk_effective_range_valid
            CHECK (effective_to IS NULL OR effective_to > effective_from);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_tenant_capability_state_runtime'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_capability_state
            ADD CONSTRAINT fk_tenant_capability_state_runtime
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_tenant_capability_state_capability'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_capability_state
            ADD CONSTRAINT fk_tenant_capability_state_capability
            FOREIGN KEY (capability_id)
            REFERENCES omnex_system_core.system_capability (capability_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_tenant_capability_state_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: tenant capability state is immutable';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: tenant capability state records cannot be deleted';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_tenant_capability_state_immutability
ON omnex_system_core.tenant_capability_state;

CREATE TRIGGER trg_enforce_tenant_capability_state_immutability
BEFORE UPDATE OR DELETE ON omnex_system_core.tenant_capability_state
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_tenant_capability_state_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_capability_state
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_capability_state'
          AND policyname = 'deny_all_tenant_capability_state'
    ) THEN
        CREATE POLICY deny_all_tenant_capability_state
        ON omnex_system_core.tenant_capability_state
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant_capability_state
        ON omnex_system_core.tenant_capability_state IS
        'Capability state enforcement is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_capability_state_runtime
ON omnex_system_core.tenant_capability_state (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_capability_state_capability
ON omnex_system_core.tenant_capability_state (capability_id);

CREATE INDEX IF NOT EXISTS idx_tenant_capability_state_code
ON omnex_system_core.tenant_capability_state (state_code);

CREATE INDEX IF NOT EXISTS idx_tenant_capability_state_effective
ON omnex_system_core.tenant_capability_state (effective_from, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 038 — TENANT CAPABILITY STATE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_039
-- ENGINE NAME: System Provisioning & Runtime Control
-- ENGINE FUNCTION:
--   Controls actual system enablement and disablement for runtime tenants
--   after commercial activation and governance approval.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_provisioning (
    provisioning_id     uuid PRIMARY KEY,
    runtime_tenant_id   uuid NOT NULL,
    system_id           bigint NOT NULL,

    provisioning_status text NOT NULL,
    provisioned_at      timestamptz,
    deprovisioned_at    timestamptz
);

COMMENT ON TABLE omnex_system_core.system_provisioning IS
'Controls runtime provisioning and deprovisioning of systems for operational tenants';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_provisioning_status_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_provisioning
            ADD CONSTRAINT chk_provisioning_status_not_empty
            CHECK (length(provisioning_status) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_provisioning_time_consistency'
    ) THEN
        ALTER TABLE omnex_system_core.system_provisioning
            ADD CONSTRAINT chk_provisioning_time_consistency
            CHECK (
                deprovisioned_at IS NULL
                OR provisioned_at IS NOT NULL
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_runtime_tenant_system_provisioning'
    ) THEN
        ALTER TABLE omnex_system_core.system_provisioning
            ADD CONSTRAINT uq_runtime_tenant_system_provisioning
            UNIQUE (runtime_tenant_id, system_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_provisioning_runtime_tenant'
    ) THEN
        ALTER TABLE omnex_system_core.system_provisioning
            ADD CONSTRAINT fk_provisioning_runtime_tenant
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_provisioning_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_provisioning
            ADD CONSTRAINT fk_provisioning_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_system_provisioning_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: system provisioning records cannot be deleted';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_system_provisioning_rules
ON omnex_system_core.system_provisioning;

CREATE TRIGGER trg_enforce_system_provisioning_rules
BEFORE DELETE
ON omnex_system_core.system_provisioning
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_system_provisioning_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_provisioning
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_provisioning'
          AND policyname = 'deny_all_system_provisioning'
    ) THEN
        CREATE POLICY deny_all_system_provisioning
        ON omnex_system_core.system_provisioning
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_provisioning
        ON omnex_system_core.system_provisioning IS
        'System provisioning is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_provisioning_runtime_tenant
ON omnex_system_core.system_provisioning (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_provisioning_system
ON omnex_system_core.system_provisioning (system_id);

CREATE INDEX IF NOT EXISTS idx_provisioning_status
ON omnex_system_core.system_provisioning (provisioning_status);

COMMIT;

-- ============================================================
-- END OF ENGINE 039 — SYSTEM PROVISIONING & RUNTIME CONTROL
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_040
-- ENGINE NAME: Provisioning Jobs & Execution Tracking
-- ENGINE FUNCTION:
--   Tracks execution jobs related to system provisioning and
--   deprovisioning, including retries, failures, and outcomes.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.provisioning_job (
    job_id            uuid PRIMARY KEY,
    provisioning_id   uuid NOT NULL,

    job_type          text NOT NULL,
    execution_status  text NOT NULL,

    started_at        timestamptz NOT NULL DEFAULT now(),
    completed_at      timestamptz,

    error_message     text
);

COMMENT ON TABLE omnex_system_core.provisioning_job IS
'Execution jobs, retries, and outcomes for system provisioning operations';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_job_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.provisioning_job
            ADD CONSTRAINT chk_job_type_not_empty
            CHECK (length(job_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_execution_status_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.provisioning_job
            ADD CONSTRAINT chk_execution_status_not_empty
            CHECK (length(execution_status) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_job_completion_consistency'
    ) THEN
        ALTER TABLE omnex_system_core.provisioning_job
            ADD CONSTRAINT chk_job_completion_consistency
            CHECK (
                completed_at IS NULL
                OR completed_at >= started_at
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_job_provisioning'
    ) THEN
        ALTER TABLE omnex_system_core.provisioning_job
            ADD CONSTRAINT fk_job_provisioning
            FOREIGN KEY (provisioning_id)
            REFERENCES omnex_system_core.system_provisioning (provisioning_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_provisioning_job_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: provisioning job records are immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_provisioning_job_immutability
ON omnex_system_core.provisioning_job;

CREATE TRIGGER trg_enforce_provisioning_job_immutability
BEFORE UPDATE OR DELETE
ON omnex_system_core.provisioning_job
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_provisioning_job_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.provisioning_job
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'provisioning_job'
          AND policyname = 'deny_all_provisioning_job'
    ) THEN
        CREATE POLICY deny_all_provisioning_job
        ON omnex_system_core.provisioning_job
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_provisioning_job
        ON omnex_system_core.provisioning_job IS
        'Provisioning job execution is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_provisioning_job_provisioning
ON omnex_system_core.provisioning_job (provisioning_id);

CREATE INDEX IF NOT EXISTS idx_provisioning_job_status
ON omnex_system_core.provisioning_job (execution_status);

CREATE INDEX IF NOT EXISTS idx_provisioning_job_type
ON omnex_system_core.provisioning_job (job_type);

CREATE INDEX IF NOT EXISTS idx_provisioning_job_started
ON omnex_system_core.provisioning_job (started_at DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 040 — PROVISIONING JOBS & EXECUTION TRACKING
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_041
-- ENGINE NAME: System Configuration Store
-- ENGINE FUNCTION:
--   Stores centralized configuration values applied across systems,
--   environments, and runtime scopes with validity periods.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_041_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_configuration (
    config_id        uuid PRIMARY KEY,
    system_id        uuid NOT NULL,

    config_key       text NOT NULL,
    config_value     text NOT NULL,

    environment      text NOT NULL,

    effective_from   timestamptz NOT NULL DEFAULT now(),
    effective_to     timestamptz,

    created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_configuration IS
'Centralized configuration values applied across systems and environments (time-bound and authoritative)';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_config_key_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_configuration
            ADD CONSTRAINT chk_config_key_not_empty
            CHECK (length(config_key) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_environment_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_configuration
            ADD CONSTRAINT chk_environment_not_empty
            CHECK (length(environment) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_effective_window'
    ) THEN
        ALTER TABLE omnex_system_core.system_configuration
            ADD CONSTRAINT chk_effective_window
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_system_config_version'
    ) THEN
        ALTER TABLE omnex_system_core.system_configuration
            ADD CONSTRAINT uq_system_config_version
            UNIQUE (system_id, config_key, environment, effective_from);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_system_configuration_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_configuration
            ADD CONSTRAINT fk_system_configuration_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.enforce_system_configuration_immutability()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: system configuration records are immutable';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_system_configuration_immutability
ON omnex_system_core.system_configuration;

CREATE TRIGGER trg_enforce_system_configuration_immutability
BEFORE UPDATE OR DELETE
ON omnex_system_core.system_configuration
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.enforce_system_configuration_immutability();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_configuration
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_configuration'
          AND policyname = 'deny_all_system_configuration'
    ) THEN
        CREATE POLICY deny_all_system_configuration
        ON omnex_system_core.system_configuration
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_configuration
        ON omnex_system_core.system_configuration IS
        'System configuration is centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_configuration_system
ON omnex_system_core.system_configuration (system_id);

CREATE INDEX IF NOT EXISTS idx_system_configuration_key
ON omnex_system_core.system_configuration (config_key);

CREATE INDEX IF NOT EXISTS idx_system_configuration_env
ON omnex_system_core.system_configuration (environment);

CREATE INDEX IF NOT EXISTS idx_system_configuration_effective
ON omnex_system_core.system_configuration
(system_id, config_key, environment, effective_from DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 041 — SYSTEM CONFIGURATION STORE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_042
-- ENGINE NAME: Feature Flag Store
-- ENGINE FUNCTION:
--   Controls conditional feature rollouts using flags, toggles,
--   percentages and environment scope.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_042_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.feature_flag (
    flag_id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id            uuid NOT NULL,

    flag_code            text NOT NULL,
    flag_type            text NOT NULL, -- e.g. 'boolean', 'percentage', 'custom'
    enabled              boolean NOT NULL DEFAULT false,
    rollout_percentage   integer CHECK (rollout_percentage BETWEEN 0 AND 100),

    environment          text NOT NULL,
    created_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.feature_flag IS
'Feature flags and toggles for Omnex systems, used for runtime rollout control and experimentation.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_flag_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.feature_flag
            ADD CONSTRAINT chk_flag_code_not_empty
            CHECK (length(flag_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_flag_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.feature_flag
            ADD CONSTRAINT chk_flag_type_not_empty
            CHECK (length(flag_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_environment_not_empty_flag'
    ) THEN
        ALTER TABLE omnex_system_core.feature_flag
            ADD CONSTRAINT chk_environment_not_empty_flag
            CHECK (length(environment) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_flag_identity'
    ) THEN
        ALTER TABLE omnex_system_core.feature_flag
            ADD CONSTRAINT uq_flag_identity
            UNIQUE (system_id, flag_code, environment);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_feature_flag_system'
    ) THEN
        ALTER TABLE omnex_system_core.feature_flag
            ADD CONSTRAINT fk_feature_flag_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_flag_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: Feature flags are immutable after creation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_flag_mutation
ON omnex_system_core.feature_flag;

CREATE TRIGGER trg_prevent_flag_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_core.feature_flag
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_flag_mutation();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.feature_flag
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'feature_flag'
          AND policyname = 'deny_all_feature_flag'
    ) THEN
        CREATE POLICY deny_all_feature_flag
        ON omnex_system_core.feature_flag
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_feature_flag
        ON omnex_system_core.feature_flag IS
        'Feature flags are centrally governed and must not be accessed directly by unauthorized entities';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_feature_flag_system
ON omnex_system_core.feature_flag (system_id);

CREATE INDEX IF NOT EXISTS idx_feature_flag_code
ON omnex_system_core.feature_flag (flag_code);

CREATE INDEX IF NOT EXISTS idx_feature_flag_env
ON omnex_system_core.feature_flag (environment);

CREATE INDEX IF NOT EXISTS idx_feature_flag_enabled
ON omnex_system_core.feature_flag (enabled);

COMMIT;

-- ============================================================
-- END OF ENGINE 042 — FEATURE FLAG STORE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_043
-- ENGINE NAME: Tenant Feature Flag Overrides
-- ENGINE FUNCTION:
--   Applies tenant-specific overrides to feature flags defined in
--   the system-wide feature flag registry. Enables runtime control
--   of tenant experiences, experimentation, and flag exceptions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_043_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.tenant_feature_flag (
    tenant_flag_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    runtime_tenant_id  uuid NOT NULL,
    flag_id            uuid NOT NULL,

    override_value     boolean NOT NULL,
    effective_from     timestamptz NOT NULL DEFAULT now(),
    effective_to       timestamptz,

    created_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.tenant_feature_flag IS
'Tenant-specific overrides for feature flags. Allows scoped flag behavior across tenants and environments.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_effective_window_tenant_flag'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_feature_flag
            ADD CONSTRAINT chk_effective_window_tenant_flag
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_tenant_flag_identity'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_feature_flag
            ADD CONSTRAINT uq_tenant_flag_identity
            UNIQUE (runtime_tenant_id, flag_id, effective_from);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_tenant_feature_flag_flag'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_feature_flag
            ADD CONSTRAINT fk_tenant_feature_flag_flag
            FOREIGN KEY (flag_id)
            REFERENCES omnex_system_core.feature_flag (flag_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_tenant_feature_flag_runtime'
    ) THEN
        ALTER TABLE omnex_system_core.tenant_feature_flag
            ADD CONSTRAINT fk_tenant_feature_flag_runtime
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_core.prevent_tenant_flag_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION
            'OMNEX GOVERNANCE VIOLATION: Tenant flag overrides are immutable once defined';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_tenant_flag_mutation
ON omnex_system_core.tenant_feature_flag;

CREATE TRIGGER trg_prevent_tenant_flag_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_core.tenant_feature_flag
FOR EACH ROW
EXECUTE FUNCTION omnex_system_core.prevent_tenant_flag_mutation();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.tenant_feature_flag
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'tenant_feature_flag'
          AND policyname = 'deny_all_tenant_feature_flag'
    ) THEN
        CREATE POLICY deny_all_tenant_feature_flag
        ON omnex_system_core.tenant_feature_flag
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_tenant_feature_flag
        ON omnex_system_core.tenant_feature_flag IS
        'Tenant flag overrides are centrally managed. Default access is denied.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_tenant_feature_flag_flag
ON omnex_system_core.tenant_feature_flag (flag_id);

CREATE INDEX IF NOT EXISTS idx_tenant_feature_flag_tenant
ON omnex_system_core.tenant_feature_flag (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_feature_flag_effective
ON omnex_system_core.tenant_feature_flag (effective_from DESC, effective_to);

COMMIT;

-- ============================================================
-- END OF ENGINE 043 — TENANT FEATURE FLAG OVERRIDES
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_044
-- ENGINE NAME: System Health Status
-- ENGINE FUNCTION:
--   Captures real-time and historical health status of systems
--   for operational monitoring, diagnostics, and visibility
--   across environments and deployments.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_044_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_health_status (
    health_status_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id          uuid NOT NULL,
    status_code        text NOT NULL,
    measured_at        timestamptz NOT NULL DEFAULT now(),
    reported_by        text NOT NULL,
    notes              text,

    created_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_health_status IS
'Captures real-time and historical health state of Omnex systems across environments for monitoring and observability.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_status_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_health_status
            ADD CONSTRAINT chk_status_code_not_empty
            CHECK (length(status_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_reported_by_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_health_status
            ADD CONSTRAINT chk_reported_by_not_empty
            CHECK (length(reported_by) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_health_status_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_health_status
            ADD CONSTRAINT fk_health_status_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (No immutability enforcement; history intended to be additive)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_health_status
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_health_status'
          AND policyname = 'deny_all_system_health_status'
    ) THEN
        CREATE POLICY deny_all_system_health_status
        ON omnex_system_core.system_health_status
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_health_status
        ON omnex_system_core.system_health_status IS
        'System health status data is centrally controlled. Default access is denied.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_health_status_system
ON omnex_system_core.system_health_status (system_id);

CREATE INDEX IF NOT EXISTS idx_health_status_measured
ON omnex_system_core.system_health_status (measured_at DESC);

CREATE INDEX IF NOT EXISTS idx_health_status_status_code
ON omnex_system_core.system_health_status (status_code);

COMMIT;

-- ============================================================
-- END OF ENGINE 044 — SYSTEM HEALTH STATUS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_045
-- ENGINE NAME: System Incident Store
-- ENGINE FUNCTION:
--   Records incidents, outages, and degradation events impacting
--   system availability, performance, or security posture.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_045_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional future enums for severity / incident types)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_incident (
    incident_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id       uuid NOT NULL,

    severity        text NOT NULL,
    incident_type   text NOT NULL,

    started_at      timestamptz NOT NULL DEFAULT now(),
    resolved_at     timestamptz,

    summary         text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_incident IS
'Incident log for availability outages, performance issues, or security degradation affecting system operations.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_incident_severity_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_incident
            ADD CONSTRAINT chk_incident_severity_not_empty
            CHECK (length(severity) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_incident_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_incident
            ADD CONSTRAINT chk_incident_type_not_empty
            CHECK (length(incident_type) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_incident_window'
    ) THEN
        ALTER TABLE omnex_system_core.system_incident
            ADD CONSTRAINT chk_incident_window
            CHECK (
                resolved_at IS NULL OR resolved_at > started_at
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_incident_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_incident
            ADD CONSTRAINT fk_incident_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (None for now)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_incident
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_incident'
          AND policyname = 'deny_all_system_incident'
    ) THEN
        CREATE POLICY deny_all_system_incident
        ON omnex_system_core.system_incident
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_incident
        ON omnex_system_core.system_incident IS
        'Incident data is governed centrally; default deny-all.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_incident_system
ON omnex_system_core.system_incident (system_id);

CREATE INDEX IF NOT EXISTS idx_system_incident_started
ON omnex_system_core.system_incident (started_at DESC);

CREATE INDEX IF NOT EXISTS idx_system_incident_type
ON omnex_system_core.system_incident (incident_type);

CREATE INDEX IF NOT EXISTS idx_system_incident_severity
ON omnex_system_core.system_incident (severity);

COMMIT;

-- ============================================================
-- END OF ENGINE 045 — SYSTEM INCIDENT STORE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_046
-- ENGINE NAME: System Metric Store
-- ENGINE FUNCTION:
--   Stores quantitative metrics reflecting system performance,
--   availability, reliability, and operational telemetry.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_046_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional: define metric_unit ENUM later if standardization required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_metric (
    metric_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id       uuid NOT NULL,

    metric_name     text NOT NULL,
    metric_value    numeric NOT NULL,
    unit            text NOT NULL,

    recorded_at     timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_metric IS
'Telemetry store for performance, availability, and reliability metrics per system over time.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_metric_name_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_metric
            ADD CONSTRAINT chk_metric_name_not_empty
            CHECK (length(metric_name) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_metric_unit_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_metric
            ADD CONSTRAINT chk_metric_unit_not_empty
            CHECK (length(unit) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_metric_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_metric
            ADD CONSTRAINT fk_metric_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (Optional future: deduplication or anomaly detection logic)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_metric
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_metric'
          AND policyname = 'deny_all_system_metric'
    ) THEN
        CREATE POLICY deny_all_system_metric
        ON omnex_system_core.system_metric
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_metric
        ON omnex_system_core.system_metric IS
        'Metrics are controlled under Omnex observability governance; access denied by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_metric_system
ON omnex_system_core.system_metric (system_id);

CREATE INDEX IF NOT EXISTS idx_system_metric_name
ON omnex_system_core.system_metric (metric_name);

CREATE INDEX IF NOT EXISTS idx_system_metric_time
ON omnex_system_core.system_metric (recorded_at DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 046 — SYSTEM METRIC STORE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_047
-- ENGINE NAME: System Signal Event Bus
-- ENGINE FUNCTION:
--   Canonical event bus ledger for inter-system signals,
--   lifecycle broadcasts, and asynchronous triggers.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_047_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional future: ENUM for signal_type or dispatch status)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_signal_event (
    signal_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_system_id uuid NOT NULL,

    signal_type      text NOT NULL,
    payload          jsonb,

    dispatched_at    timestamptz NOT NULL DEFAULT now(),
    consumed_by      text,
    consumed_at      timestamptz
);

COMMENT ON TABLE omnex_system_core.system_signal_event IS
'Canonical inter-system signal ledger — captures triggers, broadcasts, and lifecycle dispatches across the Omnex System-of-Systems.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_signal_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_signal_event
            ADD CONSTRAINT chk_signal_type_not_empty
            CHECK (length(signal_type) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_signal_source_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_signal_event
            ADD CONSTRAINT fk_signal_source_system
            FOREIGN KEY (source_system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (Optional future: trigger on dispatch logging / downstream orchestration)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_signal_event
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_signal_event'
          AND policyname = 'deny_all_system_signal_event'
    ) THEN
        CREATE POLICY deny_all_system_signal_event
        ON omnex_system_core.system_signal_event
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_signal_event
        ON omnex_system_core.system_signal_event IS
        'Signal bus is centrally governed — access denied by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_signal_event_system
ON omnex_system_core.system_signal_event (source_system_id);

CREATE INDEX IF NOT EXISTS idx_signal_event_type
ON omnex_system_core.system_signal_event (signal_type);

CREATE INDEX IF NOT EXISTS idx_signal_event_dispatch
ON omnex_system_core.system_signal_event (dispatched_at DESC);

CREATE INDEX IF NOT EXISTS idx_signal_event_consumed
ON omnex_system_core.system_signal_event (consumed_by, consumed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 047 — SYSTEM SIGNAL EVENT BUS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_048
-- ENGINE NAME: System Policy Version Registry
-- ENGINE FUNCTION:
--   Tracks governance policy versions, effective periods,
--   and system-level enforcement declarations.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_engine_048_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional: policy_scope ENUM can be defined if needed later)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.system_policy_version (
    policy_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id        uuid NOT NULL,

    policy_code      text NOT NULL,
    version          text NOT NULL,

    effective_from   timestamptz NOT NULL,
    effective_to     timestamptz,

    enforced         boolean NOT NULL DEFAULT true,

    created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_core.system_policy_version IS
'Registry of governance policies enforced by systems — versioned and time-bound.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_policy_version
            ADD CONSTRAINT chk_policy_code_not_empty
            CHECK (length(policy_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_version_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.system_policy_version
            ADD CONSTRAINT chk_policy_version_not_empty
            CHECK (length(version) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_window_valid'
    ) THEN
        ALTER TABLE omnex_system_core.system_policy_version
            ADD CONSTRAINT chk_policy_window_valid
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_policy_system'
    ) THEN
        ALTER TABLE omnex_system_core.system_policy_version
            ADD CONSTRAINT fk_policy_system
            FOREIGN KEY (system_id)
            REFERENCES omnex_system_core.system_registry (system_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (Optional future: enforce non-overlapping policy windows)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.system_policy_version
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'system_policy_version'
          AND policyname = 'deny_all_system_policy_version'
    ) THEN
        CREATE POLICY deny_all_system_policy_version
        ON omnex_system_core.system_policy_version
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_system_policy_version
        ON omnex_system_core.system_policy_version IS
        'Policy registries are centrally governed — access denied by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_policy_version_system
ON omnex_system_core.system_policy_version (system_id);

CREATE INDEX IF NOT EXISTS idx_policy_code
ON omnex_system_core.system_policy_version (policy_code);

CREATE INDEX IF NOT EXISTS idx_policy_effective_from
ON omnex_system_core.system_policy_version (effective_from DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 048 — SYSTEM POLICY VERSION REGISTRY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM CORE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_001
-- SYSTEM ID: 2026001
-- SYSTEM CODE: OS_CORE
-- SYSTEM NAME: Omnex_System_Core

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_core

-- ENGINE NO: engine_049
-- ENGINE NAME: Deployment Hash Ledger
-- ENGINE FUNCTION:
--   Captures version lineage, hash attestations, and
--   deployed file integrity for audit and rollback assurance.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026001_omnex_system_core.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_core;
REVOKE ALL ON SCHEMA omnex_system_core FROM PUBLIC;
SET search_path = omnex_system_core, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional: deployment_status_enum could be introduced in future)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_core.deployment_hash_ledger (
    deployment_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    system_code     text NOT NULL,
    engine_no       integer NOT NULL,
    file_name       text NOT NULL,

    sha256_hash     text NOT NULL,
    deployed_at     timestamptz NOT NULL DEFAULT now(),
    deployed_by     text NOT NULL,

    deployment_note text
);

COMMENT ON TABLE omnex_system_core.deployment_hash_ledger IS
'Immutable deployment ledger capturing hash attestations, versions, and timestamps for all system/engine deployments.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_hash_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.deployment_hash_ledger
            ADD CONSTRAINT chk_hash_not_empty
            CHECK (length(sha256_hash) = 64); -- SHA256 hex string length
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_file_name_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.deployment_hash_ledger
            ADD CONSTRAINT chk_file_name_not_empty
            CHECK (length(file_name) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_system_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_core.deployment_hash_ledger
            ADD CONSTRAINT chk_system_code_not_empty
            CHECK (length(system_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — standalone ledger by design (decoupled from FK risk)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (Optional future: automatic verification trigger)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_core.deployment_hash_ledger
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_core'
          AND tablename  = 'deployment_hash_ledger'
          AND policyname = 'deny_all_deployment_hash_ledger'
    ) THEN
        CREATE POLICY deny_all_deployment_hash_ledger
        ON omnex_system_core.deployment_hash_ledger
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_deployment_hash_ledger
        ON omnex_system_core.deployment_hash_ledger IS
        'Deployment hash attestation is a secure ledger — access denied by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_deployment_hash_system_engine
ON omnex_system_core.deployment_hash_ledger (system_code, engine_no);

CREATE INDEX IF NOT EXISTS idx_deployment_hash_timestamp
ON omnex_system_core.deployment_hash_ledger (deployed_at DESC);

CREATE INDEX IF NOT EXISTS idx_deployment_hash_file
ON omnex_system_core.deployment_hash_ledger (file_name);

COMMIT;

-- ============================================================
-- END OF ENGINE 049 — DEPLOYMENT HASH LEDGER
-- ============================================================
