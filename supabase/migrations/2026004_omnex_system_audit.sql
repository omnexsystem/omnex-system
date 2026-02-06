-- ============================================================
-- OMNEX SYSTEM IDENTITY — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_000
-- ENGINE NAME: Omnex Identity Constitutional Ledger
-- ENGINE FUNCTION:
--   Canonical immutable identity ledger declaring all identity
--   authorities, system identities, tenants, actors, and scopes.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_identity.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_identity;
REVOKE ALL ON SCHEMA omnex_system_identity FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_identity IS
'Omnex Identity Constitutional Schema — authoritative ledger for all identity declarations';

SET search_path = omnex_system_identity;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'identity_record_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.identity_record_type_enum AS ENUM (
            'SYSTEM_IDENTITY',
            'TENANT_IDENTITY',
            'USER_IDENTITY',
            'ROLE_IDENTITY',
            'SERVICE_IDENTITY',
            'CREDENTIAL_ISSUANCE',
            'IDENTITY_REVOCATION'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.identity_constitution_ledger (
    identity_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    record_type        omnex_system_identity.identity_record_type_enum NOT NULL,
    system_code        text NOT NULL,

    identity_ref       text NOT NULL,
    authority_ref      text,

    effective_from     timestamptz,
    effective_to       timestamptz,

    payload            jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum           text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at         timestamptz NOT NULL DEFAULT now(),
    created_by         text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_identity.identity_constitution_ledger IS
'Immutable identity ledger declaring canonical identities and authority bindings';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_identity_effective_time_range'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_constitution_ledger
            ADD CONSTRAINT chk_identity_effective_time_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_identity_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_constitution_ledger
            ADD CONSTRAINT chk_identity_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — this is a root constitutional identity store.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'compute_and_validate_identity_checksum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE FUNCTION omnex_system_identity.compute_and_validate_identity_checksum()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $fn$
        DECLARE
            computed text;
        BEGIN
            computed := encode(
                digest(
                    coalesce(NEW.system_code, '') ||
                    coalesce(NEW.record_type::text, '') ||
                    coalesce(NEW.identity_ref, '') ||
                    coalesce(NEW.authority_ref, '') ||
                    coalesce(NEW.payload::text, '') ||
                    coalesce(NEW.payload_schema_version::text, ''),
                    'sha256'
                ),
                'hex'
            );

            IF NEW.checksum <> computed THEN
                RAISE EXCEPTION 'IDENTITY CHECKSUM MISMATCH: invalid SHA256 checksum';
            END IF;

            RETURN NEW;
        END;
        $fn$;
    END IF;
END $$;

DROP TRIGGER IF EXISTS trg_validate_identity_checksum
ON omnex_system_identity.identity_constitution_ledger;

CREATE TRIGGER trg_validate_identity_checksum
BEFORE INSERT
ON omnex_system_identity.identity_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.compute_and_validate_identity_checksum();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_identity.identity_constitution_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_identity_constitution
ON omnex_system_identity.identity_constitution_ledger;

CREATE POLICY deny_all_identity_constitution
ON omnex_system_identity.identity_constitution_ledger
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_identity_constitution
ON omnex_system_identity.identity_constitution_ledger IS
'All access to identity constitutional ledger is centrally governed. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_identity_record_type
ON omnex_system_identity.identity_constitution_ledger (record_type);

CREATE INDEX IF NOT EXISTS idx_identity_system_code
ON omnex_system_identity.identity_constitution_ledger (system_code);

CREATE INDEX IF NOT EXISTS idx_identity_identity_ref
ON omnex_system_identity.identity_constitution_ledger (identity_ref);

CREATE INDEX IF NOT EXISTS idx_identity_payload
ON omnex_system_identity.identity_constitution_ledger USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM IDENTITY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_001
-- ENGINE NAME: Audit Event Log
-- ENGINE FUNCTION:
--   Records immutable evidence of all meaningful user, system,
--   and governance actions across Omnex.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — immutable evidence ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'audit_event_type_enum'
          AND n.nspname = 'omnex_system_audit'
    ) THEN
        CREATE TYPE omnex_system_audit.audit_event_type_enum AS ENUM (
            'USER_ACTION',
            'SYSTEM_ACTION',
            'GOVERNANCE_ACTION',
            'SECURITY_EVENT',
            'ORCHESTRATION_EVENT'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_event (
    audit_event_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    event_type         omnex_system_audit.audit_event_type_enum NOT NULL,

    actor_user_id      uuid,
    actor_system_id    uuid,
    tenant_id          uuid,

    source_system      text NOT NULL,
    action_code        text NOT NULL,

    occurred_at        timestamptz NOT NULL DEFAULT now(),

    immutable_hash     text NOT NULL,
    hash_algorithm     text NOT NULL DEFAULT 'SHA256'
);

COMMENT ON TABLE omnex_system_audit.audit_event IS
'Immutable audit evidence of user, system, and governance actions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_action_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_event
            ADD CONSTRAINT chk_audit_action_code_not_empty
            CHECK (length(btrim(action_code)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_immutable_hash_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_event
            ADD CONSTRAINT chk_audit_immutable_hash_not_empty
            CHECK (length(immutable_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Audit is sovereign evidence.
-- No foreign keys enforced to prevent dependency-induced evidence loss.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'validate_audit_event_hash'
          AND n.nspname = 'omnex_system_audit'
    ) THEN
        CREATE FUNCTION omnex_system_audit.validate_audit_event_hash()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $fn$
        DECLARE
            computed text;
        BEGIN
            computed := encode(
                digest(
                    coalesce(NEW.event_type::text, '') ||
                    coalesce(NEW.source_system, '') ||
                    coalesce(NEW.action_code, '') ||
                    coalesce(NEW.occurred_at::text, ''),
                    'sha256'
                ),
                'hex'
            );

            IF NEW.immutable_hash <> computed THEN
                RAISE EXCEPTION 'AUDIT HASH MISMATCH: immutable evidence violation';
            END IF;

            RETURN NEW;
        END;
        $fn$;
    END IF;
END $$;

DROP TRIGGER IF EXISTS trg_validate_audit_event_hash
ON omnex_system_audit.audit_event;

CREATE TRIGGER trg_validate_audit_event_hash
BEFORE INSERT
ON omnex_system_audit.audit_event
FOR EACH ROW
EXECUTE FUNCTION omnex_system_audit.validate_audit_event_hash();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_event ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_event
ON omnex_system_audit.audit_event;

CREATE POLICY deny_all_audit_event
ON omnex_system_audit.audit_event
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_event
ON omnex_system_audit.audit_event IS
'All audit evidence is read and accessed only via authorized system paths';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_audit_event_type
    ON omnex_system_audit.audit_event (event_type);

CREATE INDEX IF NOT EXISTS idx_audit_event_occurred_at
    ON omnex_system_audit.audit_event (occurred_at);

CREATE INDEX IF NOT EXISTS idx_audit_event_source_system
    ON omnex_system_audit.audit_event (source_system);

CREATE INDEX IF NOT EXISTS idx_audit_event_action_code
    ON omnex_system_audit.audit_event (action_code);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — AUDIT EVENT LOG
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_002
-- ENGINE NAME: Audit Action Context
-- ENGINE FUNCTION:
--   Stores contextual metadata associated with an audit event,
--   enabling rich, immutable evidence attribution.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — immutable evidence ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_event_context (
    context_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    audit_event_id   uuid NOT NULL,

    context_key      text NOT NULL,
    context_value    text NOT NULL
);

COMMENT ON TABLE omnex_system_audit.audit_event_context IS
'Contextual key-value metadata attached to immutable audit events';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_context_key_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_event_context
            ADD CONSTRAINT chk_audit_context_key_not_empty
            CHECK (length(btrim(context_key)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_context_value_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_event_context
            ADD CONSTRAINT chk_audit_context_value_not_empty
            CHECK (length(btrim(context_value)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Soft attachment to audit_event (attach only if base table exists)
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_audit'
          AND table_name   = 'audit_event'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_audit_context_event'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_event_context
            ADD CONSTRAINT fk_audit_context_event
            FOREIGN KEY (audit_event_id)
            REFERENCES omnex_system_audit.audit_event (audit_event_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Context records are declarative evidence extensions.
-- No mutation or execution logic permitted.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_event_context ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_event_context
ON omnex_system_audit.audit_event_context;

CREATE POLICY deny_all_audit_event_context
ON omnex_system_audit.audit_event_context
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_event_context
ON omnex_system_audit.audit_event_context IS
'Audit context is accessible only via authorized audit resolution paths';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_audit_context_event
    ON omnex_system_audit.audit_event_context (audit_event_id);

CREATE INDEX IF NOT EXISTS idx_audit_context_key
    ON omnex_system_audit.audit_event_context (context_key);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — AUDIT ACTION CONTEXT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 003
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_003
-- ENGINE NAME: Field Change Tracking
-- ENGINE FUNCTION:
--   Records before-and-after values for data mutations to
--   provide immutable, fine-grained change evidence.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — immutable evidence ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_field_change (
    field_change_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    audit_event_id    uuid NOT NULL,

    entity_type       text NOT NULL,
    entity_id         text NOT NULL,

    field_name        text NOT NULL,

    old_value         text,
    new_value         text
);

COMMENT ON TABLE omnex_system_audit.audit_field_change IS
'Immutable before-and-after field-level change records associated with audit events';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_field_change_entity_type_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_field_change
            ADD CONSTRAINT chk_audit_field_change_entity_type_not_empty
            CHECK (length(btrim(entity_type)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_field_change_entity_id_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_field_change
            ADD CONSTRAINT chk_audit_field_change_entity_id_not_empty
            CHECK (length(btrim(entity_id)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_audit_field_change_field_name_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_field_change
            ADD CONSTRAINT chk_audit_field_change_field_name_not_empty
            CHECK (length(btrim(field_name)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Soft attachment to audit_event (attach only if base table exists)
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_audit'
          AND table_name   = 'audit_event'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_audit_field_change_event'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_field_change
            ADD CONSTRAINT fk_audit_field_change_event
            FOREIGN KEY (audit_event_id)
            REFERENCES omnex_system_audit.audit_event (audit_event_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Field change records are immutable audit facts.
-- Population occurs via orchestration or execution layers only.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_field_change ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_field_change
ON omnex_system_audit.audit_field_change;

CREATE POLICY deny_all_audit_field_change
ON omnex_system_audit.audit_field_change
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_field_change
ON omnex_system_audit.audit_field_change IS
'Field-level audit changes are centrally governed and not directly accessible';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_audit_field_change_event
    ON omnex_system_audit.audit_field_change (audit_event_id);

CREATE INDEX IF NOT EXISTS idx_audit_field_change_entity
    ON omnex_system_audit.audit_field_change (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_audit_field_change_field
    ON omnex_system_audit.audit_field_change (field_name);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — FIELD CHANGE TRACKING
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 004
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_004
-- ENGINE NAME: Governance Audit Records
-- ENGINE FUNCTION:
--   Records governance evaluations, approvals, and enforcement
--   outcomes as immutable audit evidence.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — immutable governance evidence ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_governance_action (
    governance_audit_id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    audit_event_id         uuid NOT NULL,

    policy_id              uuid,
    rule_id                uuid,
    approval_request_id    uuid,

    outcome                text NOT NULL,

    recorded_at            timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_audit.audit_governance_action IS
'Immutable audit records capturing governance evaluations, approvals, and enforcement outcomes';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_governance_audit_outcome_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_governance_action
            ADD CONSTRAINT chk_governance_audit_outcome_not_empty
            CHECK (length(btrim(outcome)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Soft attachment to audit_event
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_audit'
          AND table_name   = 'audit_event'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_gov_audit_event'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_governance_action
            ADD CONSTRAINT fk_gov_audit_event
            FOREIGN KEY (audit_event_id)
            REFERENCES omnex_system_audit.audit_event (audit_event_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Governance audit actions are immutable evidence.
-- No procedural logic permitted at the audit layer.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_governance_action ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_governance_action
ON omnex_system_audit.audit_governance_action;

CREATE POLICY deny_all_audit_governance_action
ON omnex_system_audit.audit_governance_action
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_governance_action
ON omnex_system_audit.audit_governance_action IS
'Governance audit records are accessible only via authorized audit resolution paths';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_gov_audit_event
    ON omnex_system_audit.audit_governance_action (audit_event_id);

CREATE INDEX IF NOT EXISTS idx_gov_audit_policy
    ON omnex_system_audit.audit_governance_action (policy_id);

CREATE INDEX IF NOT EXISTS idx_gov_audit_rule
    ON omnex_system_audit.audit_governance_action (rule_id);

CREATE INDEX IF NOT EXISTS idx_gov_audit_approval_request
    ON omnex_system_audit.audit_governance_action (approval_request_id);

CREATE INDEX IF NOT EXISTS idx_gov_audit_recorded_at
    ON omnex_system_audit.audit_governance_action (recorded_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — GOVERNANCE AUDIT RECORDS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 005
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_005
-- ENGINE NAME: Security Event Records
-- ENGINE FUNCTION:
--   Records security-related incidents, anomalies, and threat
--   signals as immutable audit evidence.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — immutable security and evidence ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'security_severity_enum'
          AND n.nspname = 'omnex_system_audit'
    ) THEN
        CREATE TYPE omnex_system_audit.security_severity_enum AS ENUM (
            'LOW',
            'MEDIUM',
            'HIGH',
            'CRITICAL'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_security_event (
    security_event_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    audit_event_id      uuid NOT NULL,

    event_category      text NOT NULL,
    severity            omnex_system_audit.security_severity_enum NOT NULL,

    source_ip           inet,

    detected_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_audit.audit_security_event IS
'Immutable audit records of security incidents and anomaly detections';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_security_event_category_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_security_event
            ADD CONSTRAINT chk_security_event_category_not_empty
            CHECK (length(btrim(event_category)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Soft attachment to audit_event
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_audit'
          AND table_name   = 'audit_event'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_security_audit_event'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_security_event
            ADD CONSTRAINT fk_security_audit_event
            FOREIGN KEY (audit_event_id)
            REFERENCES omnex_system_audit.audit_event (audit_event_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Security event records are immutable evidence.
-- Detection logic exists outside the audit system.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_security_event ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_security_event
ON omnex_system_audit.audit_security_event;

CREATE POLICY deny_all_audit_security_event
ON omnex_system_audit.audit_security_event
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_security_event
ON omnex_system_audit.audit_security_event IS
'Security audit events are accessible only via authorized security and audit pathways';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_security_event_audit_event
    ON omnex_system_audit.audit_security_event (audit_event_id);

CREATE INDEX IF NOT EXISTS idx_security_event_severity
    ON omnex_system_audit.audit_security_event (severity);

CREATE INDEX IF NOT EXISTS idx_security_event_detected_at
    ON omnex_system_audit.audit_security_event (detected_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — SECURITY EVENT RECORDS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM AUDIT — ENGINE 006
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_004
-- SYSTEM ID: 2026004
-- SYSTEM CODE: OS_AUD
-- SYSTEM NAME: Omnex_System_Audit

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_audit

-- ENGINE NO: engine_006
-- ENGINE NAME: Audit Integrity Control
-- ENGINE FUNCTION:
--   Ensures immutability, chain-of-custody, and tamper detection
--   across all audit evidence records.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026004_omnex_system_audit.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_audit;
REVOKE ALL ON SCHEMA omnex_system_audit FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_audit IS
'Omnex Audit Constitutional Schema — integrity and chain-of-custody ledger';

SET search_path = omnex_system_audit;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_audit.audit_integrity_chain (
    integrity_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    audit_event_id   uuid NOT NULL,

    previous_hash    text,
    current_hash     text NOT NULL,

    sealed_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_audit.audit_integrity_chain IS
'Immutable hash chain enforcing audit evidence integrity and tamper detection';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_integrity_current_hash_not_empty'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_integrity_chain
            ADD CONSTRAINT chk_integrity_current_hash_not_empty
            CHECK (length(current_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Soft attachment to audit_event
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_audit'
          AND table_name   = 'audit_event'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_integrity_audit_event'
    ) THEN
        ALTER TABLE omnex_system_audit.audit_integrity_chain
            ADD CONSTRAINT fk_integrity_audit_event
            FOREIGN KEY (audit_event_id)
            REFERENCES omnex_system_audit.audit_event (audit_event_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Integrity chain records are immutable evidence.
-- Hash computation and chaining occur in orchestration layers.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_audit.audit_integrity_chain ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_audit_integrity_chain
ON omnex_system_audit.audit_integrity_chain;

CREATE POLICY deny_all_audit_integrity_chain
ON omnex_system_audit.audit_integrity_chain
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_audit_integrity_chain
ON omnex_system_audit.audit_integrity_chain IS
'Integrity chain records are strictly controlled and not directly accessible';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_integrity_chain_event
    ON omnex_system_audit.audit_integrity_chain (audit_event_id);

CREATE INDEX IF NOT EXISTS idx_integrity_chain_sealed_at
    ON omnex_system_audit.audit_integrity_chain (sealed_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — AUDIT INTEGRITY CONTROL
-- ============================================================
