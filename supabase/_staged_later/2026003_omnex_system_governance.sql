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

-- ENGINE NO: engine_006
-- ENGINE NAME: Governance Approval Requests
-- ENGINE FUNCTION:
--   Represents proposed operations requiring governance approval
--   through workflows defined and assigned to policies.

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
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'approval_status_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE approval_status_enum AS ENUM (
            'PENDING',
            'APPROVED',
            'REJECTED',
            'EXPIRED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_approval_request (
    approval_request_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    workflow_id           uuid NOT NULL,
    operation_code        text NOT NULL,

    requester_user_id     uuid NOT NULL,
    tenant_id             uuid NOT NULL,

    requested_at          timestamptz NOT NULL DEFAULT now(),
    status                approval_status_enum NOT NULL DEFAULT 'PENDING'
);

COMMENT ON TABLE governance_approval_request IS
'Proposed operations that require governance approval via structured workflows';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_operation_code_not_empty'
    ) THEN
        ALTER TABLE governance_approval_request
            ADD CONSTRAINT chk_operation_code_not_empty
            CHECK (length(operation_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Workflow dependency (Governance internal)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_request_workflow'
    ) THEN
        ALTER TABLE governance_approval_request
            ADD CONSTRAINT fk_request_workflow
            FOREIGN KEY (workflow_id)
            REFERENCES omnex_system_governance.governance_approval_workflow (workflow_id)
            ON DELETE CASCADE;
    END IF;

    -- Identity dependency (hard dependency)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_request_user'
    ) THEN
        ALTER TABLE governance_approval_request
            ADD CONSTRAINT fk_request_user
            FOREIGN KEY (requester_user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    -- Core dependency (soft dependency — attach only if Core exists)
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'omnex_system_core'
          AND table_name   = 'runtime_tenant'
    )
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_request_tenant'
    ) THEN
        ALTER TABLE governance_approval_request
            ADD CONSTRAINT fk_request_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.runtime_tenant (tenant_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Governance does not execute business logic.
-- Approval lifecycle logic is handled by orchestration engines.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_approval_request ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_approval_request'
          AND policyname = 'deny_all_governance_approval_request'
    ) THEN
        CREATE POLICY deny_all_governance_approval_request
        ON governance_approval_request
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_approval_request
        ON governance_approval_request IS
        'Governance approval requests are centrally evaluated; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_request_user
    ON governance_approval_request (requester_user_id);

CREATE INDEX IF NOT EXISTS idx_request_tenant
    ON governance_approval_request (tenant_id);

CREATE INDEX IF NOT EXISTS idx_request_workflow
    ON governance_approval_request (workflow_id);

CREATE INDEX IF NOT EXISTS idx_request_status
    ON governance_approval_request (status);

CREATE INDEX IF NOT EXISTS idx_request_operation_code
    ON governance_approval_request (operation_code);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — GOVERNANCE APPROVAL REQUESTS
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

-- ENGINE NO: engine_007
-- ENGINE NAME: Governance Approval Decisions
-- ENGINE FUNCTION:
--   Records individual approval or rejection decisions made by
--   authorized approvers against approval requests.

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
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'approval_decision_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE approval_decision_enum AS ENUM (
            'APPROVED',
            'REJECTED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_approval_decision (
    decision_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    approval_request_id   uuid NOT NULL,
    approver_user_id      uuid NOT NULL,

    decision              approval_decision_enum NOT NULL,
    decision_reason       text,

    decided_at            timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE governance_approval_decision IS
'Individual approval/rejection decisions recorded against governance approval requests';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_decision_reason_if_rejected'
    ) THEN
        ALTER TABLE governance_approval_decision
            ADD CONSTRAINT chk_decision_reason_if_rejected
            CHECK (
                decision <> 'REJECTED'
                OR (decision_reason IS NOT NULL AND length(btrim(decision_reason)) > 0)
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_decision_request'
    ) THEN
        ALTER TABLE governance_approval_decision
            ADD CONSTRAINT fk_decision_request
            FOREIGN KEY (approval_request_id)
            REFERENCES omnex_system_governance.governance_approval_request (approval_request_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_decision_approver_user'
    ) THEN
        ALTER TABLE governance_approval_decision
            ADD CONSTRAINT fk_decision_approver_user
            FOREIGN KEY (approver_user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional: enforce single decision per approver per request, or decision immutability,
-- can be introduced in later phases.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_approval_decision ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_approval_decision'
          AND policyname = 'deny_all_governance_approval_decision'
    ) THEN
        CREATE POLICY deny_all_governance_approval_decision
        ON governance_approval_decision
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_approval_decision
        ON governance_approval_decision IS
        'Governance approval decisions are centrally evaluated; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_decision_request
    ON governance_approval_decision (approval_request_id);

CREATE INDEX IF NOT EXISTS idx_decision_approver_user
    ON governance_approval_decision (approver_user_id);

CREATE INDEX IF NOT EXISTS idx_decision_decision
    ON governance_approval_decision (decision);

CREATE INDEX IF NOT EXISTS idx_decision_decided_at
    ON governance_approval_decision (decided_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — GOVERNANCE APPROVAL DECISIONS
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

-- ENGINE NO: engine_008
-- ENGINE NAME: Governance Exceptions
-- ENGINE FUNCTION:
--   Records approved deviations from standard governance policies
--   or rules with explicit justification and expiry.

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
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_exception (
    exception_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id         uuid NOT NULL,
    rule_id           uuid,

    justification     text NOT NULL,

    approved_by       uuid NOT NULL,

    approved_at       timestamptz NOT NULL DEFAULT now(),
    expires_at        timestamptz
);

COMMENT ON TABLE governance_exception IS
'Approved deviations from governance policies or rules with documented justification and expiry';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_exception_justification_not_empty'
    ) THEN
        ALTER TABLE governance_exception
            ADD CONSTRAINT chk_exception_justification_not_empty
            CHECK (length(btrim(justification)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_exception_expiry_after_approval'
    ) THEN
        ALTER TABLE governance_exception
            ADD CONSTRAINT chk_exception_expiry_after_approval
            CHECK (expires_at IS NULL OR expires_at > approved_at);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Governance policy (mandatory)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_exception_policy'
    ) THEN
        ALTER TABLE governance_exception
            ADD CONSTRAINT fk_exception_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_governance.governance_policy (policy_id)
            ON DELETE CASCADE;
    END IF;

    -- Governance rule (optional)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_exception_rule'
    ) THEN
        ALTER TABLE governance_exception
            ADD CONSTRAINT fk_exception_rule
            FOREIGN KEY (rule_id)
            REFERENCES omnex_system_governance.governance_rule (rule_id)
            ON DELETE SET NULL;
    END IF;

    -- Approving user (Identity dependency)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_exception_approved_by'
    ) THEN
        ALTER TABLE governance_exception
            ADD CONSTRAINT fk_exception_approved_by
            FOREIGN KEY (approved_by)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Governance exceptions are declarative records.
-- Enforcement and expiry evaluation occur outside this system.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_exception ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_exception'
          AND policyname = 'deny_all_governance_exception'
    ) THEN
        CREATE POLICY deny_all_governance_exception
        ON governance_exception
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_exception
        ON governance_exception IS
        'Governance exceptions are centrally controlled; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_exception_policy
    ON governance_exception (policy_id);

CREATE INDEX IF NOT EXISTS idx_exception_rule
    ON governance_exception (rule_id);

CREATE INDEX IF NOT EXISTS idx_exception_approved_by
    ON governance_exception (approved_by);

CREATE INDEX IF NOT EXISTS idx_exception_expires_at
    ON governance_exception (expires_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — GOVERNANCE EXCEPTIONS
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

-- ENGINE NO: engine_009
-- ENGINE NAME: Governance Compliance Mapping
-- ENGINE FUNCTION:
--   Maps governance policies to regulatory or compliance
--   frameworks and clauses for audit and traceability.

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
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_compliance_mapping (
    mapping_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id            uuid NOT NULL,

    compliance_standard  text NOT NULL,
    compliance_clause    text NOT NULL,

    mapped_at            timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE governance_compliance_mapping IS
'Maps governance policies to regulatory or compliance standards and clauses';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_compliance_standard_not_empty'
    ) THEN
        ALTER TABLE governance_compliance_mapping
            ADD CONSTRAINT chk_compliance_standard_not_empty
            CHECK (length(btrim(compliance_standard)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_compliance_clause_not_empty'
    ) THEN
        ALTER TABLE governance_compliance_mapping
            ADD CONSTRAINT chk_compliance_clause_not_empty
            CHECK (length(btrim(compliance_clause)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Governance policy (mandatory)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_compliance_mapping_policy'
    ) THEN
        ALTER TABLE governance_compliance_mapping
            ADD CONSTRAINT fk_compliance_mapping_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_governance.governance_policy (policy_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Compliance mappings are declarative.
-- No enforcement or evaluation logic resides in Governance.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_compliance_mapping ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_compliance_mapping'
          AND policyname = 'deny_all_governance_compliance_mapping'
    ) THEN
        CREATE POLICY deny_all_governance_compliance_mapping
        ON governance_compliance_mapping
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_compliance_mapping
        ON governance_compliance_mapping IS
        'Governance compliance mappings are centrally controlled; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_compliance_mapping_policy
    ON governance_compliance_mapping (policy_id);

CREATE INDEX IF NOT EXISTS idx_compliance_mapping_standard
    ON governance_compliance_mapping (compliance_standard);

CREATE INDEX IF NOT EXISTS idx_compliance_mapping_mapped_at
    ON governance_compliance_mapping (mapped_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — GOVERNANCE COMPLIANCE MAPPING
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

-- ENGINE NO: engine_010
-- ENGINE NAME: Governance Evaluation Log
-- ENGINE FUNCTION:
--   Records governance evaluations performed on proposed
--   operations against applicable governance policies.

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
-- No enums required for this engine.

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_evaluation (
    evaluation_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    operation_code    text NOT NULL,
    policy_id         uuid NOT NULL,

    evaluation_result text NOT NULL,

    evaluated_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE governance_evaluation IS
'Records governance policy evaluations performed on proposed operations';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_evaluation_operation_code_not_empty'
    ) THEN
        ALTER TABLE governance_evaluation
            ADD CONSTRAINT chk_evaluation_operation_code_not_empty
            CHECK (length(btrim(operation_code)) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_evaluation_result_not_empty'
    ) THEN
        ALTER TABLE governance_evaluation
            ADD CONSTRAINT chk_evaluation_result_not_empty
            CHECK (length(btrim(evaluation_result)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Governance policy (mandatory)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_evaluation_policy'
    ) THEN
        ALTER TABLE governance_evaluation
            ADD CONSTRAINT fk_evaluation_policy
            FOREIGN KEY (policy_id)
            REFERENCES omnex_system_governance.governance_policy (policy_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Governance evaluation records are immutable audit facts.
-- No enforcement or execution logic exists in this engine.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_evaluation ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_evaluation'
          AND policyname = 'deny_all_governance_evaluation'
    ) THEN
        CREATE POLICY deny_all_governance_evaluation
        ON governance_evaluation
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_evaluation
        ON governance_evaluation IS
        'Governance evaluations are centrally controlled; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_evaluation_operation_code
    ON governance_evaluation (operation_code);

CREATE INDEX IF NOT EXISTS idx_evaluation_policy
    ON governance_evaluation (policy_id);

CREATE INDEX IF NOT EXISTS idx_evaluation_evaluated_at
    ON governance_evaluation (evaluated_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — GOVERNANCE EVALUATION LOG
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

-- ENGINE NO: engine_011
-- ENGINE NAME: Governance Enforcement Outcome
-- ENGINE FUNCTION:
--   Records the final governance outcome that allows or blocks
--   execution of a governed operation.

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
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'enforcement_status_enum'
          AND n.nspname = 'omnex_system_governance'
    ) THEN
        CREATE TYPE enforcement_status_enum AS ENUM (
            'ALLOWED',
            'BLOCKED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS governance_enforcement_result (
    enforcement_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    operation_code        text NOT NULL,
    approval_request_id   uuid,

    enforcement_status    enforcement_status_enum NOT NULL,

    enforced_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE governance_enforcement_result IS
'Final governance enforcement outcome determining whether an operation is allowed or blocked';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_enforcement_operation_code_not_empty'
    ) THEN
        ALTER TABLE governance_enforcement_result
            ADD CONSTRAINT chk_enforcement_operation_code_not_empty
            CHECK (length(btrim(operation_code)) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    -- Approval request (optional but authoritative when present)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_enforcement_approval_request'
    ) THEN
        ALTER TABLE governance_enforcement_result
            ADD CONSTRAINT fk_enforcement_approval_request
            FOREIGN KEY (approval_request_id)
            REFERENCES omnex_system_governance.governance_approval_request (approval_request_id)
            ON DELETE SET NULL;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Governance enforcement outcomes are immutable audit facts.
-- Execution engines consume this result; Governance does not execute.

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE governance_enforcement_result ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_governance'
          AND tablename  = 'governance_enforcement_result'
          AND policyname = 'deny_all_governance_enforcement_result'
    ) THEN
        CREATE POLICY deny_all_governance_enforcement_result
        ON governance_enforcement_result
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_governance_enforcement_result
        ON governance_enforcement_result IS
        'Governance enforcement outcomes are centrally controlled; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_enforcement_operation_code
    ON governance_enforcement_result (operation_code);

CREATE INDEX IF NOT EXISTS idx_enforcement_approval_request
    ON governance_enforcement_result (approval_request_id);

CREATE INDEX IF NOT EXISTS idx_enforcement_status
    ON governance_enforcement_result (enforcement_status);

CREATE INDEX IF NOT EXISTS idx_enforcement_enforced_at
    ON governance_enforcement_result (enforced_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — GOVERNANCE ENFORCEMENT OUTCOME
-- ============================================================
