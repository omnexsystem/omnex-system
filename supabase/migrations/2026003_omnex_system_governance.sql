-- ============================================================
-- OMNEX SYSTEM GOVERNANCE — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_000
-- ENGINE NAME: Omnex Governance Constitutional Ledger
-- ENGINE FUNCTION:
--   Canonical immutable record for all governance-level declarations,
--   including roles, rules, approvals, and exceptions.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026003_engine_000_omnex_system_governance.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;

COMMENT ON SCHEMA omnex_system_governance IS
'Omnex Governance Constitutional Schema — authoritative ledger for all governance domain logic';

SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'gov_record_type_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE omnex_system_governance.gov_record_type_enum AS ENUM (
            'GOV_POLICY',
            'GOV_RULE',
            'GOV_ROLE',
            'GOV_ASSIGNMENT',
            'GOV_APPROVAL',
            'GOV_EXCEPTION',
            'GOV_COMPLIANCE',
            'GOV_EVALUATION',
            'GOV_ENFORCEMENT'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_governance.gov_constitution_ledger (
    governance_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    record_type     omnex_system_governance.gov_record_type_enum NOT NULL,
    system_code     text NOT NULL,
    policy_code     text,
    rule_code       text,
    authority_ref   text,

    effective_from  timestamptz,
    effective_to    timestamptz,

    payload         jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum        text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_governance.gov_constitution_ledger IS
'Immutable governance ledger — declares formal governance control artifacts (policies, rules, roles, workflows)';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_gov_effective_time_range'
    ) THEN
        ALTER TABLE omnex_system_governance.gov_constitution_ledger
            ADD CONSTRAINT chk_gov_effective_time_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_gov_payload_checksum_nonempty'
    ) THEN
        ALTER TABLE omnex_system_governance.gov_constitution_ledger
            ADD CONSTRAINT chk_gov_payload_checksum_nonempty
            CHECK (length(checksum) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — this is a root constitutional store.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_governance.compute_and_validate_gov_checksum()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    computed text;
BEGIN
    computed := encode(
        digest(
            coalesce(NEW.system_code, '') ||
            coalesce(NEW.record_type::text, '') ||
            coalesce(NEW.policy_code, '') ||
            coalesce(NEW.rule_code, '') ||
            coalesce(NEW.payload::text, '') ||
            coalesce(NEW.payload_schema_version::text, ''),
            'sha256'
        ),
        'hex'
    );

    IF NEW.checksum <> computed THEN
        RAISE EXCEPTION 'GOVERNANCE CHECKSUM MISMATCH: invalid SHA256 checksum';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_gov_checksum
ON omnex_system_governance.gov_constitution_ledger;

CREATE TRIGGER trg_validate_gov_checksum
BEFORE INSERT
ON omnex_system_governance.gov_constitution_ledger
FOR EACH ROW
EXECUTE FUNCTION omnex_system_governance.compute_and_validate_gov_checksum();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_governance.gov_constitution_ledger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_gov_constitution
ON omnex_system_governance.gov_constitution_ledger;

CREATE POLICY deny_all_gov_constitution
ON omnex_system_governance.gov_constitution_ledger
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_gov_constitution
ON omnex_system_governance.gov_constitution_ledger IS
'All access to governance ledger is governed centrally. No direct reads or writes.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_gov_record_type
ON omnex_system_governance.gov_constitution_ledger (record_type);

CREATE INDEX IF NOT EXISTS idx_gov_system_code
ON omnex_system_governance.gov_constitution_ledger (system_code);

CREATE INDEX IF NOT EXISTS idx_gov_policy_code
ON omnex_system_governance.gov_constitution_ledger (policy_code);

CREATE INDEX IF NOT EXISTS idx_gov_rule_code
ON omnex_system_governance.gov_constitution_ledger (rule_code);

CREATE INDEX IF NOT EXISTS idx_gov_payload
ON omnex_system_governance.gov_constitution_ledger USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM GOVERNANCE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM GOVERNANCE — ENGINE 001
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_001
-- ENGINE NAME: Governance Policies
-- ENGINE FUNCTION:
--   Defines formal organizational policies that constrain or permit
--   system operations across the Omnex System-of-Systems.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026003_engine_001_governance_policy.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;

SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None required for this engine

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_governance.governance_policy (
    policy_id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_code          text NOT NULL,
    policy_name          text NOT NULL,
    policy_description   text,
    policy_scope         text NOT NULL,
    active               boolean NOT NULL DEFAULT true,
    effective_from       timestamptz NOT NULL,
    effective_to         timestamptz,
    created_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_governance.governance_policy IS
'Defines formal organizational policies that constrain or permit system operations';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_policy
            ADD CONSTRAINT chk_policy_code_nonempty
            CHECK (length(policy_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_scope_nonempty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_policy
            ADD CONSTRAINT chk_policy_scope_nonempty
            CHECK (length(policy_scope) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_policy_effective_range'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_policy
            ADD CONSTRAINT chk_policy_effective_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_policy_code'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_policy
            ADD CONSTRAINT uq_policy_code
            UNIQUE (policy_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None at this layer (independent policy declarations)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- No procedural logic needed at this stage

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_governance.governance_policy ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename = 'governance_policy'
          AND policyname = 'deny_all_governance_policy'
    ) THEN
        CREATE POLICY deny_all_governance_policy
        ON omnex_system_governance.governance_policy
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_policy
        ON omnex_system_governance.governance_policy IS
        'All access to governance policies is centrally mediated.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_governance_policy_code
    ON omnex_system_governance.governance_policy (policy_code);

CREATE INDEX IF NOT EXISTS idx_governance_policy_scope
    ON omnex_system_governance.governance_policy (policy_scope);

CREATE INDEX IF NOT EXISTS idx_governance_policy_active
    ON omnex_system_governance.governance_policy (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — GOVERNANCE POLICIES
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM GOVERNANCE — ENGINE 002
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_002
-- ENGINE NAME: Governance Rules
-- ENGINE FUNCTION:
--   Encodes machine-enforceable rules derived from governance policies
--   that constrain, require, or trigger governed operations.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026003_engine_002_governance_rule.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;
SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'rule_severity_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE omnex_system_governance.rule_severity_enum AS ENUM (
            'LOW',
            'MEDIUM',
            'HIGH',
            'CRITICAL'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'rule_type_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE omnex_system_governance.rule_type_enum AS ENUM (
            'PRE_CONDITION',
            'APPROVAL_REQUIREMENT',
            'PROHIBITION',
            'ESCALATION_TRIGGER'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_governance.governance_rule (
    rule_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id         uuid NOT NULL,

    rule_code         text NOT NULL,
    rule_expression   text NOT NULL,
    rule_type         omnex_system_governance.rule_type_enum NOT NULL,
    severity          omnex_system_governance.rule_severity_enum NOT NULL,

    active            boolean NOT NULL DEFAULT true,
    created_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_governance.governance_rule IS
'Encodes machine-enforceable rules derived from governance policies.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_rule_code_nonempty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_rule
            ADD CONSTRAINT chk_rule_code_nonempty
            CHECK (length(rule_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_rule_expression_nonempty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_rule
            ADD CONSTRAINT chk_rule_expression_nonempty
            CHECK (length(rule_expression) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_rule_code_per_policy'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_rule
            ADD CONSTRAINT uq_rule_code_per_policy
            UNIQUE (policy_id, rule_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_governance_rule_policy'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_rule
            ADD CONSTRAINT fk_governance_rule_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_governance.governance_policy (policy_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- No procedural logic needed at this stage

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_governance.governance_rule ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename = 'governance_rule'
          AND policyname = 'deny_all_governance_rule'
    ) THEN
        CREATE POLICY deny_all_governance_rule
        ON omnex_system_governance.governance_rule
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_rule
        ON omnex_system_governance.governance_rule IS
        'All access to governance rules is centrally governed.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_governance_rule_policy
    ON omnex_system_governance.governance_rule (policy_id);

CREATE INDEX IF NOT EXISTS idx_governance_rule_type
    ON omnex_system_governance.governance_rule (rule_type);

CREATE INDEX IF NOT EXISTS idx_governance_rule_severity
    ON omnex_system_governance.governance_rule (severity);

CREATE INDEX IF NOT EXISTS idx_governance_rule_active
    ON omnex_system_governance.governance_rule (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — GOVERNANCE RULES
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM GOVERNANCE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_003
-- ENGINE NAME: Governance Roles
-- ENGINE FUNCTION:
--   Defines governance-specific roles responsible for oversight
--   and approval within the Omnex governance framework.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026003_omnex_system_governance.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;
SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_governance.governance_role (
    governance_role_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    role_code        text NOT NULL,
    role_name        text NOT NULL,
    role_description text,

    created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_governance.governance_role IS
'Defines governance-specific oversight and approval roles';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_governance_role_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_role
            ADD CONSTRAINT chk_governance_role_code_not_empty
            CHECK (length(role_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_governance_role_name_not_empty'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_role
            ADD CONSTRAINT chk_governance_role_name_not_empty
            CHECK (length(role_name) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_governance_role_code'
    ) THEN
        ALTER TABLE omnex_system_governance.governance_role
            ADD CONSTRAINT uq_governance_role_code
            UNIQUE (role_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_governance.governance_role
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_role'
          AND policyname = 'deny_all_governance_role'
    ) THEN
        CREATE POLICY deny_all_governance_role
        ON omnex_system_governance.governance_role
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_role
        ON omnex_system_governance.governance_role IS
        'Governance roles are centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_governance_role_code
ON omnex_system_governance.governance_role (role_code);

CREATE INDEX IF NOT EXISTS idx_governance_role_name
ON omnex_system_governance.governance_role (role_name);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — GOVERNANCE ROLES
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM GOVERNANCE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_004
-- ENGINE NAME: Governance Role Assignments
-- ENGINE FUNCTION:
--   Assigns governance roles to users within tenant or system scope,
--   enabling controlled enforcement of oversight responsibility.

-- VERSION: v1.1
-- STATUS: Final
-- FILE: 2026003_engine_004_governance_role_assignment.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;
SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_role_assignment (
    assignment_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    governance_role_id   uuid NOT NULL,
    user_id              uuid NOT NULL,
    runtime_tenant_id    uuid NOT NULL,

    assigned_at          timestamptz NOT NULL DEFAULT now(),
    revoked_at           timestamptz
);

COMMENT ON TABLE governance_role_assignment IS
'Assignments of governance roles to users in specific tenant scopes for oversight authority';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_assignment_revoked_after_assigned'
    ) THEN
        ALTER TABLE governance_role_assignment
            ADD CONSTRAINT chk_assignment_revoked_after_assigned
            CHECK (revoked_at IS NULL OR revoked_at > assigned_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_active_governance_role_assignment'
    ) THEN
        ALTER TABLE governance_role_assignment
            ADD CONSTRAINT uq_active_governance_role_assignment
            UNIQUE (governance_role_id, user_id, runtime_tenant_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_assignment_governance_role'
    ) THEN
        ALTER TABLE governance_role_assignment
            ADD CONSTRAINT fk_assignment_governance_role
            FOREIGN KEY (governance_role_id)
            REFERENCES omnex_system_governance.governance_role (governance_role_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_assignment_user'
    ) THEN
        ALTER TABLE governance_role_assignment
            ADD CONSTRAINT fk_assignment_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_assignment_runtime_tenant'
    ) THEN
        ALTER TABLE governance_role_assignment
            ADD CONSTRAINT fk_assignment_runtime_tenant
            FOREIGN KEY (runtime_tenant_id)
            REFERENCES omnex_system_core.tenant_runtime_identity (runtime_tenant_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (None yet; lifecycle governance triggers may be added later)

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_role_assignment ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_role_assignment'
          AND policyname = 'deny_all_governance_role_assignment'
    ) THEN
        CREATE POLICY deny_all_governance_role_assignment
        ON governance_role_assignment
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_role_assignment
        ON governance_role_assignment IS
        'Governance role assignments are centrally controlled; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_assignment_user
ON governance_role_assignment (user_id);

CREATE INDEX IF NOT EXISTS idx_assignment_runtime_tenant
ON governance_role_assignment (runtime_tenant_id);

CREATE INDEX IF NOT EXISTS idx_assignment_governance_role
ON governance_role_assignment (governance_role_id);

CREATE INDEX IF NOT EXISTS idx_assignment_revoked
ON governance_role_assignment (revoked_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — GOVERNANCE ROLE ASSIGNMENTS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM GOVERNANCE MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_003
-- SYSTEM ID: 2026003
-- SYSTEM CODE: OS_GOV
-- SYSTEM NAME: Omnex_System_Governance

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_governance

-- ENGINE NO: engine_005
-- ENGINE NAME: Governance Approval Workflow Definitions
-- ENGINE FUNCTION:
--   Defines approval workflows required for governed operations
--   by associating them with governance policies and sequencing logic.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026003_engine_005_governance_approval_workflow.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_governance;
REVOKE ALL ON SCHEMA omnex_system_governance FROM PUBLIC;
SET search_path = omnex_system_governance, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_approval_workflow (
    workflow_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_code     text NOT NULL,
    policy_id         uuid NOT NULL,

    approval_levels   integer NOT NULL CHECK (approval_levels > 0),
    sequential        boolean NOT NULL DEFAULT true,
    active            boolean NOT NULL DEFAULT true,
    created_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE governance_approval_workflow IS
'Defines approval workflows required for governed operations, including sequencing and policy reference';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_workflow_code_not_empty'
    ) THEN
        ALTER TABLE governance_approval_workflow
            ADD CONSTRAINT chk_workflow_code_not_empty
            CHECK (length(workflow_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_workflow_code'
    ) THEN
        ALTER TABLE governance_approval_workflow
            ADD CONSTRAINT uq_workflow_code
            UNIQUE (workflow_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_workflow_policy'
    ) THEN
        ALTER TABLE governance_approval_workflow
            ADD CONSTRAINT fk_workflow_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_governance.governance_policy (policy_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (No triggers at this phase; optional future immutability)

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_approval_workflow ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_approval_workflow'
          AND policyname = 'deny_all_governance_approval_workflow'
    ) THEN
        CREATE POLICY deny_all_governance_approval_workflow
        ON governance_approval_workflow
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_approval_workflow
        ON governance_approval_workflow IS
        'Approval workflows are centrally defined; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_workflow_policy
ON governance_approval_workflow (policy_id);

CREATE INDEX IF NOT EXISTS idx_workflow_code
ON governance_approval_workflow (workflow_code);

CREATE INDEX IF NOT EXISTS idx_workflow_active
ON governance_approval_workflow (active);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — GOVERNANCE APPROVAL WORKFLOW DEFINITIONS
-- ============================================================
