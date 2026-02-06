-- ============================================================
-- THIS FILE IS A LAW-BOUND MIGRATION. IT MUST NEVER BE RENAMED,
-- MODIFIED, RESHUFFLED, OR MANIPULATED IN ANY WAY AFTER INSTALL.
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_000
-- ENGINE NAME: Omnex Foundation Constitutional Ledger
-- ENGINE FUNCTION:
--   Canonical immutable semantic ledger defining shared meaning,
--   classifications, vocabularies, reference codes, and interpretive truth
--   used uniformly across all Omnex systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_foundation IS
'Omnex System Foundation — canonical semantic substrate (ENGINE 000)';

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'foundation_record_type_enum'
          AND n.nspname = 'omnex_system_foundation'
    ) THEN
        CREATE TYPE omnex_system_foundation.foundation_record_type_enum AS ENUM (
            'STATUS_CODE',
            'SEVERITY_LEVEL',
            'OUTCOME_CODE',
            'CLASSIFICATION',
            'REFERENCE_CODE',
            'TIME_SEMANTIC',
            'MEASUREMENT_UNIT',
            'CURRENCY_CODE',
            'BOOLEAN_SEMANTIC',
            'ENUM_DEFINITION'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_constitution_ledger (
    foundation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    record_type omnex_system_foundation.foundation_record_type_enum NOT NULL,

    semantic_code text NOT NULL,
    semantic_name text NOT NULL,
    semantic_domain text NOT NULL,

    description text,

    effective_from timestamptz,
    effective_to   timestamptz,

    payload jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_foundation.foundation_constitution_ledger IS
'Immutable semantic ledger defining shared meaning and interpretive truth for all Omnex systems';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_effective_time_range'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_constitution_ledger
            ADD CONSTRAINT chk_foundation_effective_time_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_constitution_ledger
            ADD CONSTRAINT chk_foundation_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_semantic_code_domain'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_constitution_ledger
            ADD CONSTRAINT uq_foundation_semantic_code_domain
            UNIQUE (semantic_code, semantic_domain, effective_from);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — Foundation is a semantic root, not a relational authority.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_foundation.compute_and_validate_foundation_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.record_type::text, '') ||
            coalesce(NEW.semantic_code, '') ||
            coalesce(NEW.semantic_domain, '') ||
            coalesce(NEW.payload::text, '') ||
            coalesce(NEW.payload_schema_version::text, ''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.checksum <> computed THEN
        RAISE EXCEPTION
            'FOUNDATION CHECKSUM VIOLATION: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_foundation_checksum
ON omnex_system_foundation.foundation_constitution_ledger;

CREATE TRIGGER trg_validate_foundation_checksum
BEFORE INSERT
ON omnex_system_foundation.foundation_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.compute_and_validate_foundation_checksum();

CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_foundation_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION VIOLATION: semantic records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_foundation_update
ON omnex_system_foundation.foundation_constitution_ledger;

CREATE TRIGGER trg_prevent_foundation_update
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_foundation_update();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_constitution_ledger
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_constitution
ON omnex_system_foundation.foundation_constitution_ledger;

CREATE POLICY deny_all_foundation_constitution
ON omnex_system_foundation.foundation_constitution_ledger
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_constitution
ON omnex_system_foundation.foundation_constitution_ledger IS
'All access to foundation semantics is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_record_type
ON omnex_system_foundation.foundation_constitution_ledger (record_type);

CREATE INDEX IF NOT EXISTS idx_foundation_semantic_code
ON omnex_system_foundation.foundation_constitution_ledger (semantic_code);

CREATE INDEX IF NOT EXISTS idx_foundation_semantic_domain
ON omnex_system_foundation.foundation_constitution_ledger (semantic_domain);

CREATE INDEX IF NOT EXISTS idx_foundation_payload
ON omnex_system_foundation.foundation_constitution_ledger
USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM FOUNDATION
-- ============================================================
---- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_001
-- ENGINE NAME: Semantic Status Registry
-- ENGINE FUNCTION:
--   Defines canonical system-wide status meanings used consistently
--   across Core, Identity, Governance, Audit, and all operational systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — statuses are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Semantic Status Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_status (
    status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    status_code text NOT NULL,
    status_domain text NOT NULL,
    status_description text NOT NULL,

    terminal boolean NOT NULL DEFAULT false,
    active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_001'
);

COMMENT ON TABLE omnex_system_foundation.foundation_status IS
'Canonical semantic registry defining system-wide status meanings';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_status_code_domain'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_status
            ADD CONSTRAINT uq_foundation_status_code_domain
            UNIQUE (status_code, status_domain);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_status_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_status
            ADD CONSTRAINT chk_foundation_status_code_nonempty
            CHECK (length(status_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_status_domain_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_status
            ADD CONSTRAINT chk_foundation_status_domain_nonempty
            CHECK (length(status_domain) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic registry is referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical status records
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_status_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION STATUS VIOLATION: status records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_status_mutation
ON omnex_system_foundation.foundation_status;

CREATE TRIGGER trg_prevent_status_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_status
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_status_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_status
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_status
ON omnex_system_foundation.foundation_status;

CREATE POLICY deny_all_foundation_status
ON omnex_system_foundation.foundation_status
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_status
ON omnex_system_foundation.foundation_status IS
'Semantic status registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_status_code
ON omnex_system_foundation.foundation_status (status_code);

CREATE INDEX IF NOT EXISTS idx_foundation_status_domain
ON omnex_system_foundation.foundation_status (status_domain);

CREATE INDEX IF NOT EXISTS idx_foundation_status_active
ON omnex_system_foundation.foundation_status (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_002
-- ENGINE NAME: Outcome & Decision Semantics
-- ENGINE FUNCTION:
--   Defines standardized outcome semantics for approvals, evaluations,
--   enforcement, and execution results.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — outcomes are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Outcome & Decision Semantics Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_outcome (
    outcome_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    outcome_code text NOT NULL,
    outcome_category text NOT NULL,
    outcome_description text NOT NULL,

    finality boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_002'
);

COMMENT ON TABLE omnex_system_foundation.foundation_outcome IS
'Canonical semantic registry defining standardized outcomes and decision meanings';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_outcome_code_category'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_outcome
            ADD CONSTRAINT uq_foundation_outcome_code_category
            UNIQUE (outcome_code, outcome_category);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_outcome_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_outcome
            ADD CONSTRAINT chk_foundation_outcome_code_nonempty
            CHECK (length(outcome_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_outcome_category_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_outcome
            ADD CONSTRAINT chk_foundation_outcome_category_nonempty
            CHECK (length(outcome_category) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic registry is referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical outcome records
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_outcome_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION OUTCOME VIOLATION: outcome records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_outcome_mutation
ON omnex_system_foundation.foundation_outcome;

CREATE TRIGGER trg_prevent_outcome_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_outcome
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_outcome_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_outcome
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_outcome
ON omnex_system_foundation.foundation_outcome;

CREATE POLICY deny_all_foundation_outcome
ON omnex_system_foundation.foundation_outcome
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_outcome
ON omnex_system_foundation.foundation_outcome IS
'Outcome semantics registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_outcome_code
ON omnex_system_foundation.foundation_outcome (outcome_code);

CREATE INDEX IF NOT EXISTS idx_foundation_outcome_category
ON omnex_system_foundation.foundation_outcome (outcome_category);

CREATE INDEX IF NOT EXISTS idx_foundation_outcome_finality
ON omnex_system_foundation.foundation_outcome (finality);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 003
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_003
-- ENGINE NAME: Severity & Risk Classification
-- ENGINE FUNCTION:
--   Defines severity levels and risk semantics used for governance,
--   audit, security, and incident handling.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — severity semantics are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Severity & Risk Classification Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_severity (
    severity_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    severity_code text NOT NULL,
    severity_level integer NOT NULL,
    severity_description text NOT NULL,

    escalation_required boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_003'
);

COMMENT ON TABLE omnex_system_foundation.foundation_severity IS
'Canonical semantic registry defining severity levels and risk classification semantics';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_severity_code_level'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_severity
            ADD CONSTRAINT uq_foundation_severity_code_level
            UNIQUE (severity_code, severity_level);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_severity_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_severity
            ADD CONSTRAINT chk_foundation_severity_code_nonempty
            CHECK (length(severity_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_severity_level_positive'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_severity
            ADD CONSTRAINT chk_foundation_severity_level_positive
            CHECK (severity_level >= 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic registry is referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical severity records
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_severity_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION SEVERITY VIOLATION: severity records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_severity_mutation
ON omnex_system_foundation.foundation_severity;

CREATE TRIGGER trg_prevent_severity_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_severity
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_severity_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_severity
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_severity
ON omnex_system_foundation.foundation_severity;

CREATE POLICY deny_all_foundation_severity
ON omnex_system_foundation.foundation_severity
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_severity
ON omnex_system_foundation.foundation_severity IS
'Severity and risk semantics registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_severity_code
ON omnex_system_foundation.foundation_severity (severity_code);

CREATE INDEX IF NOT EXISTS idx_foundation_severity_level
ON omnex_system_foundation.foundation_severity (severity_level);

CREATE INDEX IF NOT EXISTS idx_foundation_severity_escalation
ON omnex_system_foundation.foundation_severity (escalation_required);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 004
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_004
-- ENGINE NAME: Temporal & Validity Semantics
-- ENGINE FUNCTION:
--   Defines shared meaning for time-bound concepts such as effective dates,
--   expiry, grace periods, and validity windows.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — temporal semantics are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Temporal & Validity Semantics Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_temporal_rule (
    temporal_rule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    temporal_code text NOT NULL,
    applies_to text NOT NULL,
    description text NOT NULL,

    default_duration_days integer,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_004'
);

COMMENT ON TABLE omnex_system_foundation.foundation_temporal_rule IS
'Canonical semantic registry defining time-bound validity, expiry, and grace period semantics';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_temporal_code_applies'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_temporal_rule
            ADD CONSTRAINT uq_foundation_temporal_code_applies
            UNIQUE (temporal_code, applies_to);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_temporal_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_temporal_rule
            ADD CONSTRAINT chk_foundation_temporal_code_nonempty
            CHECK (length(temporal_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_temporal_applies_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_temporal_rule
            ADD CONSTRAINT chk_foundation_temporal_applies_nonempty
            CHECK (length(applies_to) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_temporal_duration_nonnegative'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_temporal_rule
            ADD CONSTRAINT chk_foundation_temporal_duration_nonnegative
            CHECK (default_duration_days IS NULL OR default_duration_days >= 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic registry is referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical temporal rules
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_temporal_rule_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION TEMPORAL VIOLATION: temporal rules are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_temporal_rule_mutation
ON omnex_system_foundation.foundation_temporal_rule;

CREATE TRIGGER trg_prevent_temporal_rule_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_temporal_rule
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_temporal_rule_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_temporal_rule
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_temporal_rule
ON omnex_system_foundation.foundation_temporal_rule;

CREATE POLICY deny_all_foundation_temporal_rule
ON omnex_system_foundation.foundation_temporal_rule
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_temporal_rule
ON omnex_system_foundation.foundation_temporal_rule IS
'Temporal and validity semantics registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_temporal_code
ON omnex_system_foundation.foundation_temporal_rule (temporal_code);

CREATE INDEX IF NOT EXISTS idx_foundation_temporal_applies
ON omnex_system_foundation.foundation_temporal_rule (applies_to);

CREATE INDEX IF NOT EXISTS idx_foundation_temporal_duration
ON omnex_system_foundation.foundation_temporal_rule (default_duration_days);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 005
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_005
-- ENGINE NAME: Classification & Taxonomy Registry
-- ENGINE FUNCTION:
--   Defines controlled vocabularies and classification schemes used
--   across systems for policy, analytics, compliance, and regulation.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — classifications are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Classification & Taxonomy Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_classification (
    classification_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    classification_code text NOT NULL,
    classification_type text NOT NULL,
    classification_description text NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_005'
);

COMMENT ON TABLE omnex_system_foundation.foundation_classification IS
'Canonical registry defining controlled vocabularies and classification taxonomies';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_classification_code_type'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_classification
            ADD CONSTRAINT uq_foundation_classification_code_type
            UNIQUE (classification_code, classification_type);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_classification_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_classification
            ADD CONSTRAINT chk_foundation_classification_code_nonempty
            CHECK (length(classification_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_classification_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_classification
            ADD CONSTRAINT chk_foundation_classification_type_nonempty
            CHECK (length(classification_type) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic registry is referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical classification records
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_classification_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION CLASSIFICATION VIOLATION: classification records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_classification_mutation
ON omnex_system_foundation.foundation_classification;

CREATE TRIGGER trg_prevent_classification_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_classification
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_classification_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_classification
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_classification
ON omnex_system_foundation.foundation_classification;

CREATE POLICY deny_all_foundation_classification
ON omnex_system_foundation.foundation_classification
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_classification
ON omnex_system_foundation.foundation_classification IS
'Classification and taxonomy registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_classification_code
ON omnex_system_foundation.foundation_classification (classification_code);

CREATE INDEX IF NOT EXISTS idx_foundation_classification_type
ON omnex_system_foundation.foundation_classification (classification_type);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 006
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_006
-- ENGINE NAME: Measurement & Quantitative Semantics
-- ENGINE FUNCTION:
--   Defines canonical units, scales, and quantitative meaning
--   for limits, metrics, thresholds, and entitlements across all systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — measurement semantics must remain data-driven and extensible

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Measurement & Quantitative Semantics Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_measurement_unit (
    unit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    unit_code text NOT NULL,
    unit_name text NOT NULL,
    unit_type text NOT NULL,        -- e.g. COUNT, STORAGE, TIME, CURRENCY, ENERGY
    base_unit text,                 -- canonical reference unit where applicable

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_006'
);

COMMENT ON TABLE omnex_system_foundation.foundation_measurement_unit IS
'Canonical registry defining units and quantitative semantics for limits, metrics, and entitlements';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_measurement_unit_code'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_measurement_unit
            ADD CONSTRAINT uq_foundation_measurement_unit_code
            UNIQUE (unit_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_unit_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_measurement_unit
            ADD CONSTRAINT chk_foundation_unit_code_nonempty
            CHECK (length(unit_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_unit_type_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_measurement_unit
            ADD CONSTRAINT chk_foundation_unit_type_nonempty
            CHECK (length(unit_type) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — quantitative semantics are referenced, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical measurement units
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_measurement_unit_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION MEASUREMENT VIOLATION: measurement unit records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_measurement_unit_mutation
ON omnex_system_foundation.foundation_measurement_unit;

CREATE TRIGGER trg_prevent_measurement_unit_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_measurement_unit
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_measurement_unit_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_measurement_unit
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_measurement_unit
ON omnex_system_foundation.foundation_measurement_unit;

CREATE POLICY deny_all_foundation_measurement_unit
ON omnex_system_foundation.foundation_measurement_unit
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_measurement_unit
ON omnex_system_foundation.foundation_measurement_unit IS
'Measurement and quantitative semantics are centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_measurement_unit_code
ON omnex_system_foundation.foundation_measurement_unit (unit_code);

CREATE INDEX IF NOT EXISTS idx_foundation_measurement_unit_type
ON omnex_system_foundation.foundation_measurement_unit (unit_type);

CREATE INDEX IF NOT EXISTS idx_foundation_measurement_base_unit
ON omnex_system_foundation.foundation_measurement_unit (base_unit);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 007
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_007
-- ENGINE NAME: Reference Code Registry
-- ENGINE FUNCTION:
--   Provides canonical reference codes shared across systems,
--   including currency codes, country codes, document types,
--   standards identifiers, and other controlled references.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — reference codes are data, not enums (constitutionally extensible)

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Reference Code Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_reference_code (
    reference_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    reference_domain text NOT NULL,     -- e.g. CURRENCY, COUNTRY, DOCUMENT_TYPE, STANDARD
    reference_code text NOT NULL,       -- e.g. USD, KE, PASSPORT, ISO9001
    reference_value text NOT NULL,      -- human-readable or resolved meaning

    active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_007'
);

COMMENT ON TABLE omnex_system_foundation.foundation_reference_code IS
'Canonical registry of reference codes shared across all Omnex systems';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_reference_domain_code'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_reference_code
            ADD CONSTRAINT uq_foundation_reference_domain_code
            UNIQUE (reference_domain, reference_code);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_reference_domain_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_reference_code
            ADD CONSTRAINT chk_foundation_reference_domain_nonempty
            CHECK (length(reference_domain) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_reference_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_reference_code
            ADD CONSTRAINT chk_foundation_reference_code_nonempty
            CHECK (length(reference_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — reference codes are resolved, never depended upon

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of canonical reference codes
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_reference_code_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION REFERENCE CODE VIOLATION: reference code records are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_reference_code_mutation
ON omnex_system_foundation.foundation_reference_code;

CREATE TRIGGER trg_prevent_reference_code_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_reference_code
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_reference_code_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_reference_code
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_reference_code
ON omnex_system_foundation.foundation_reference_code;

CREATE POLICY deny_all_foundation_reference_code
ON omnex_system_foundation.foundation_reference_code
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_reference_code
ON omnex_system_foundation.foundation_reference_code IS
'Reference code registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_reference_domain
ON omnex_system_foundation.foundation_reference_code (reference_domain);

CREATE INDEX IF NOT EXISTS idx_foundation_reference_code
ON omnex_system_foundation.foundation_reference_code (reference_code);

CREATE INDEX IF NOT EXISTS idx_foundation_reference_active
ON omnex_system_foundation.foundation_reference_code (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 008
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_008
-- ENGINE NAME: Semantic Versioning & Ratification
-- ENGINE FUNCTION:
--   Tracks ratification, versioning, and lifecycle of semantic
--   definitions to prevent semantic drift across the Omnex System.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None — semantic versioning is data-driven, not enum-driven

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Semantic Version Registry
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_semantic_version (
    version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    semantic_domain text NOT NULL,          -- e.g. STATUS, OUTCOME, SEVERITY, TEMPORAL, CLASSIFICATION
    version_number text NOT NULL,           -- e.g. v1.0, v1.1, v2.0

    ratified_by text NOT NULL,               -- e.g. Omnex_System_Core, Governance Council
    ratified_at timestamptz NOT NULL,

    active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_008'
);

COMMENT ON TABLE omnex_system_foundation.foundation_semantic_version IS
'Canonical registry tracking ratified semantic versions to prevent uncontrolled semantic drift';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_foundation_semantic_domain_version'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_semantic_version
            ADD CONSTRAINT uq_foundation_semantic_domain_version
            UNIQUE (semantic_domain, version_number);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_semantic_domain_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_semantic_version
            ADD CONSTRAINT chk_foundation_semantic_domain_nonempty
            CHECK (length(semantic_domain) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_foundation_version_number_nonempty'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_semantic_version
            ADD CONSTRAINT chk_foundation_version_number_nonempty
            CHECK (length(version_number) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — semantic versions are referenced conceptually, not enforced via FK

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Enforce append-only semantics for semantic versions
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_semantic_version_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION SEMANTIC VERSION VIOLATION: semantic versions are immutable — append only';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_semantic_version_mutation
ON omnex_system_foundation.foundation_semantic_version;

CREATE TRIGGER trg_prevent_semantic_version_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_semantic_version
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_semantic_version_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_semantic_version
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_semantic_version
ON omnex_system_foundation.foundation_semantic_version;

CREATE POLICY deny_all_foundation_semantic_version
ON omnex_system_foundation.foundation_semantic_version
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_semantic_version
ON omnex_system_foundation.foundation_semantic_version IS
'Semantic version registry is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_semantic_domain
ON omnex_system_foundation.foundation_semantic_version (semantic_domain);

CREATE INDEX IF NOT EXISTS idx_foundation_semantic_version
ON omnex_system_foundation.foundation_semantic_version (version_number);

CREATE INDEX IF NOT EXISTS idx_foundation_semantic_active
ON omnex_system_foundation.foundation_semantic_version (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — OMNEX SYSTEM FOUNDATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM FOUNDATION — ENGINE 009
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_005
-- SYSTEM ID: 2026005
-- SYSTEM CODE: OS_FND
-- SYSTEM NAME: Omnex_System_Foundation

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_foundation

-- ENGINE NO: engine_009
-- ENGINE NAME: Core Foundation Completion Seal
-- ENGINE FUNCTION:
--   Constitutionally seals the Omnex System Core Foundation category
--   as complete and ready for installation of standalone systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026005_omnex_system_foundation.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_foundation;
REVOKE ALL ON SCHEMA omnex_system_foundation FROM PUBLIC;

SET search_path = omnex_system_foundation, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'foundation_seal_status_enum'
          AND n.nspname = 'omnex_system_foundation'
    ) THEN
        CREATE TYPE omnex_system_foundation.foundation_seal_status_enum AS ENUM (
            'COMPLETE',
            'SEALED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Core Foundation Seal Ledger
CREATE TABLE IF NOT EXISTS omnex_system_foundation.foundation_completion_seal (
    seal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    category_code text NOT NULL,
    category_name text NOT NULL,

    seal_status omnex_system_foundation.foundation_seal_status_enum NOT NULL,
    sealed_version text NOT NULL,

    sealed_at timestamptz NOT NULL DEFAULT now(),
    sealed_by text NOT NULL DEFAULT 'ENGINE_009',

    declaration text NOT NULL
);

COMMENT ON TABLE omnex_system_foundation.foundation_completion_seal IS
'Constitutional seal asserting completion of the Omnex System Core Foundation category';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_single_core_foundation_seal'
    ) THEN
        ALTER TABLE omnex_system_foundation.foundation_completion_seal
            ADD CONSTRAINT chk_single_core_foundation_seal
            CHECK (category_code = 'OS_CF');
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — this is a terminal constitutional declaration

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent any mutation after sealing
CREATE OR REPLACE FUNCTION omnex_system_foundation.prevent_seal_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'FOUNDATION SEAL VIOLATION: Core Foundation is sealed and immutable';
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_seal_mutation
ON omnex_system_foundation.foundation_completion_seal;

CREATE TRIGGER trg_prevent_seal_mutation
BEFORE UPDATE OR DELETE
ON omnex_system_foundation.foundation_completion_seal
FOR EACH ROW
EXECUTE FUNCTION omnex_system_foundation.prevent_seal_mutation();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_foundation.foundation_completion_seal
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_foundation_seal
ON omnex_system_foundation.foundation_completion_seal;

CREATE POLICY deny_all_foundation_seal
ON omnex_system_foundation.foundation_completion_seal
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_foundation_seal
ON omnex_system_foundation.foundation_completion_seal IS
'Foundation completion seal is constitutional. No direct access permitted.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_foundation_seal_category
ON omnex_system_foundation.foundation_completion_seal (category_code);

CREATE INDEX IF NOT EXISTS idx_foundation_seal_status
ON omnex_system_foundation.foundation_completion_seal (seal_status);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — OMNEX SYSTEM CORE FOUNDATION SEALED
-- ============================================================
