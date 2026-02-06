-- ============================================================
-- OMNEX SYSTEM IDENTITY — ENGINE 000
-- FINAL SAFE, RERUNNABLE MIGRATION (CANONICAL)
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_000
-- ENGINE NAME: Omnex Identity Init Engine
-- ENGINE FUNCTION:
--   Registers sovereign system identity declarations and integrity assertions
--   under the Omnex constitutional runtime.

-- VERSION: v1.1
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
'Omnex System Identity — sovereign identity runtime schema (ENGINE 000)';

SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'record_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.record_type_enum AS ENUM (
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
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.system_status_enum AS ENUM (
            'ACTIVE',
            'SUSPENDED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.core_system_init (
    core_id uuid PRIMARY KEY,

    record_type omnex_system_identity.record_type_enum NOT NULL,

    system_code   text NOT NULL,
    category_code text NOT NULL,

    authority_ref text,
    ops_ref       text,
    scope_ref     text,

    status         omnex_system_identity.system_status_enum NOT NULL,
    effective_from timestamptz,
    effective_to   timestamptz,

    payload jsonb,
    payload_schema_version integer NOT NULL DEFAULT 1,

    checksum text NOT NULL,
    checksum_algorithm text NOT NULL DEFAULT 'SHA256',

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by text NOT NULL DEFAULT 'ENGINE_000'
);

COMMENT ON TABLE omnex_system_identity.core_system_init IS
'ENGINE 000 — Registers sovereign Omnex identity declarations under constitutional control.';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_system_core_fields'
    ) THEN
        ALTER TABLE omnex_system_identity.core_system_init
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
        ALTER TABLE omnex_system_identity.core_system_init
            ADD CONSTRAINT chk_ops_requires_authority
            CHECK (
                record_type <> 'OPS_ENABLEMENT'
                OR (ops_ref IS NOT NULL AND authority_ref IS NOT NULL)
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_effective_time_range'
    ) THEN
        ALTER TABLE omnex_system_identity.core_system_init
            ADD CONSTRAINT chk_effective_time_range
            CHECK (
                effective_to IS NULL OR effective_to > effective_from
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None (by constitutional design)

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_identity.compute_and_validate_checksum()
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
ON omnex_system_identity.core_system_init;

CREATE TRIGGER trg_validate_checksum
BEFORE INSERT
ON omnex_system_identity.core_system_init
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.compute_and_validate_checksum();

CREATE OR REPLACE FUNCTION omnex_system_identity.prevent_core_id_update()
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
ON omnex_system_identity.core_system_init;

CREATE TRIGGER trg_prevent_core_id_update
BEFORE UPDATE ON omnex_system_identity.core_system_init
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.prevent_core_id_update();

-- ==========================
-- PHASE 7: ROW LEVEL SECURITY
-- ==========================
ALTER TABLE omnex_system_identity.core_system_init ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_core_system_init
ON omnex_system_identity.core_system_init;

CREATE POLICY deny_all_core_system_init
ON omnex_system_identity.core_system_init
FOR ALL
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_core_record_type
    ON omnex_system_identity.core_system_init (record_type);

CREATE INDEX IF NOT EXISTS idx_core_system_code
    ON omnex_system_identity.core_system_init (system_code);

CREATE INDEX IF NOT EXISTS idx_core_category_code
    ON omnex_system_identity.core_system_init (category_code);

CREATE INDEX IF NOT EXISTS idx_core_payload
    ON omnex_system_identity.core_system_init USING GIN (payload);

COMMIT;

-- ============================================================
-- END OF ENGINE 000 — OMNEX SYSTEM IDENTITY
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_001
-- ENGINE NAME: User Accounts & Credentials
-- ENGINE FUNCTION:
--   Defines canonical user identity across the platform,
--   including login credentials and actor classification.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'credential_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.credential_type_enum AS ENUM (
            'PASSWORD',
            'API_KEY',
            'OAUTH',
            'SSO',
            'BIOMETRIC'
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'identity_status_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.identity_status_enum AS ENUM (
            'ACTIVE',
            'LOCKED',
            'DISABLED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.identity_user (
    user_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    username          text NOT NULL UNIQUE,
    credential_hash   text NOT NULL,
    credential_type   omnex_system_identity.credential_type_enum NOT NULL,

    status            omnex_system_identity.identity_status_enum NOT NULL DEFAULT 'ACTIVE',
    is_system_actor   boolean NOT NULL DEFAULT false,

    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.identity_user IS
'Canonical user identity and authentication credentials for all human and system actors across Omnex';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_identity_user_username_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user
            ADD CONSTRAINT chk_identity_user_username_not_empty
            CHECK (length(username) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_identity_user_credential_hash_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user
            ADD CONSTRAINT chk_identity_user_credential_hash_not_empty
            CHECK (length(credential_hash) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — this is the root identity authority for all users.

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_identity.set_identity_user_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_identity_user_updated_at
ON omnex_system_identity.identity_user;

CREATE TRIGGER trg_set_identity_user_updated_at
BEFORE UPDATE
ON omnex_system_identity.identity_user
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.set_identity_user_updated_at();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.identity_user
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename = 'identity_user'
          AND policyname = 'deny_all_identity_user'
    ) THEN
        CREATE POLICY deny_all_identity_user
        ON omnex_system_identity.identity_user
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_identity_user
        ON omnex_system_identity.identity_user IS
        'User identity credentials are access-controlled; deny all by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_identity_user_username
ON omnex_system_identity.identity_user (username);

CREATE INDEX IF NOT EXISTS idx_identity_user_status
ON omnex_system_identity.identity_user (status);

COMMIT;

-- ============================================================
-- END OF ENGINE 001 — USER ACCOUNTS & CREDENTIALS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_002
-- ENGINE NAME: User Profile & Identity Attributes
-- ENGINE FUNCTION:
--   Stores extended identity attributes required for
--   display, communication, and cross-system correlation.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
-- Schema already declared in engine_001
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- No new enums required

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.identity_user_profile (
    profile_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            uuid NOT NULL,

    display_name       text,
    primary_email      text,
    primary_phone      text,
    identity_reference text,

    created_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.identity_user_profile IS
'Extended profile attributes linked to identity_user for communication and identity resolution';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_identity_user_profile_user'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_profile
            ADD CONSTRAINT uq_identity_user_profile_user
            UNIQUE (user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_profile_email_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_profile
            ADD CONSTRAINT chk_profile_email_not_empty
            CHECK (primary_email IS NULL OR length(primary_email) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_profile_phone_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_profile
            ADD CONSTRAINT chk_profile_phone_not_empty
            CHECK (primary_phone IS NULL OR length(primary_phone) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_identity_user_profile_user'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_profile
            ADD CONSTRAINT fk_identity_user_profile_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_identity.enforce_identity_profile_ownership()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.user_id <> OLD.user_id THEN
        RAISE EXCEPTION
            'OMNEX IDENTITY ERROR: Cannot reassign profile to different user';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_identity_profile_ownership
ON omnex_system_identity.identity_user_profile;

CREATE TRIGGER trg_enforce_identity_profile_ownership
BEFORE UPDATE ON omnex_system_identity.identity_user_profile
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.enforce_identity_profile_ownership();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.identity_user_profile ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename = 'identity_user_profile'
          AND policyname = 'deny_all_identity_user_profile'
    ) THEN
        CREATE POLICY deny_all_identity_user_profile
        ON omnex_system_identity.identity_user_profile
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_identity_user_profile
        ON omnex_system_identity.identity_user_profile IS
        'Identity profile data is access-controlled. Deny by default.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_profile_user_id
ON omnex_system_identity.identity_user_profile (user_id);

CREATE INDEX IF NOT EXISTS idx_profile_primary_email
ON omnex_system_identity.identity_user_profile (primary_email);

CREATE INDEX IF NOT EXISTS idx_profile_primary_phone
ON omnex_system_identity.identity_user_profile (primary_phone);

COMMIT;

-- ============================================================
-- END OF ENGINE 002 — USER PROFILE & IDENTITY ATTRIBUTES
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_003
-- ENGINE NAME: Authentication Mechanisms
-- ENGINE FUNCTION:
--   Defines all authentication methods supported by the platform,
--   including method type, enforcement state, and lifecycle.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
-- Schema already exists
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'auth_method_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.auth_method_type_enum AS ENUM (
            'PASSWORD',
            'API_KEY',
            'OAUTH',
            'SSO',
            'BIOMETRIC'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.auth_method (
    auth_method_id  uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    method_code     text NOT NULL UNIQUE,
    method_type     omnex_system_identity.auth_method_type_enum NOT NULL,
    enabled         boolean NOT NULL DEFAULT true,

    created_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.auth_method IS
'Defines supported authentication methods and their enforcement state';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_auth_method_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.auth_method
            ADD CONSTRAINT chk_auth_method_code_not_empty
            CHECK (length(method_code) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — root authority for auth methods

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- No trigger logic currently required

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.auth_method ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename = 'auth_method'
          AND policyname = 'deny_all_auth_method'
    ) THEN
        CREATE POLICY deny_all_auth_method
        ON omnex_system_identity.auth_method
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_auth_method
        ON omnex_system_identity.auth_method IS
        'Auth method registry is access-controlled. Default: deny all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_auth_method_code
ON omnex_system_identity.auth_method (method_code);

CREATE INDEX IF NOT EXISTS idx_auth_method_type
ON omnex_system_identity.auth_method (method_type);

CREATE INDEX IF NOT EXISTS idx_auth_method_enabled
ON omnex_system_identity.auth_method (enabled);

COMMIT;

-- ============================================================
-- END OF ENGINE 003 — AUTHENTICATION MECHANISMS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_004
-- ENGINE NAME: Authentication Token Store
-- ENGINE FUNCTION:
--   Issues and governs lifecycle of authentication tokens
--   issued after successful login, including expiry and revocation.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

BEGIN;

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
-- Schema already exists
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional: could add token_status_enum in future)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.auth_token (
    token_id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id          uuid NOT NULL,
    auth_method_id   uuid NOT NULL,

    token_hash       text NOT NULL,
    issued_at        timestamptz NOT NULL DEFAULT now(),
    expires_at       timestamptz NOT NULL,
    revoked          boolean NOT NULL DEFAULT false
);

COMMENT ON TABLE omnex_system_identity.auth_token IS
'Authentication token store — governs active and historical login sessions';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_auth_token_hash_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.auth_token
            ADD CONSTRAINT chk_auth_token_hash_not_empty
            CHECK (length(token_hash) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_auth_token_expiry_future'
    ) THEN
        ALTER TABLE omnex_system_identity.auth_token
            ADD CONSTRAINT chk_auth_token_expiry_future
            CHECK (expires_at > issued_at);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_auth_token_user'
    ) THEN
        ALTER TABLE omnex_system_identity.auth_token
            ADD CONSTRAINT fk_auth_token_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_auth_token_auth_method'
    ) THEN
        ALTER TABLE omnex_system_identity.auth_token
            ADD CONSTRAINT fk_auth_token_auth_method
            FOREIGN KEY (auth_method_id)
            REFERENCES omnex_system_identity.auth_method (auth_method_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional: could add automatic token expiry revoker

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.auth_token ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'auth_token'
          AND policyname = 'deny_all_auth_token'
    ) THEN
        CREATE POLICY deny_all_auth_token
        ON omnex_system_identity.auth_token
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_auth_token
        ON omnex_system_identity.auth_token IS
        'Token access is controlled by authentication governance; default deny-all';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_auth_token_user
ON omnex_system_identity.auth_token (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_token_method
ON omnex_system_identity.auth_token (auth_method_id);

CREATE INDEX IF NOT EXISTS idx_auth_token_issued_at
ON omnex_system_identity.auth_token (issued_at DESC);

CREATE INDEX IF NOT EXISTS idx_auth_token_revoked
ON omnex_system_identity.auth_token (revoked);

COMMIT;

-- ============================================================
-- END OF ENGINE 004 — AUTHENTICATION TOKEN STORE
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_005
-- ENGINE NAME: Tenant Membership Context
-- ENGINE FUNCTION:
--   Binds users to tenants as operational actors within
--   a governed multi-tenant execution environment.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'membership_status_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.membership_status_enum AS ENUM (
            'ACTIVE',
            'EXITED',
            'REVOKED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.user_tenant_membership (
    membership_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id           uuid NOT NULL,
    tenant_id         uuid NOT NULL,

    membership_status omnex_system_identity.membership_status_enum NOT NULL DEFAULT 'ACTIVE',
    joined_at         timestamptz NOT NULL DEFAULT now(),
    exited_at         timestamptz
);

COMMENT ON TABLE omnex_system_identity.user_tenant_membership IS
'Binds users to tenants under a specific operational context in the identity plane';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_tenant_exit_after_join'
    ) THEN
        ALTER TABLE omnex_system_identity.user_tenant_membership
            ADD CONSTRAINT chk_user_tenant_exit_after_join
            CHECK (
                exited_at IS NULL OR exited_at > joined_at
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_tenant_unique_active'
    ) THEN
        ALTER TABLE omnex_system_identity.user_tenant_membership
            ADD CONSTRAINT uq_user_tenant_unique_active
            UNIQUE (user_id, tenant_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_tenant_membership_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_tenant_membership
            ADD CONSTRAINT fk_user_tenant_membership_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_tenant_membership_tenant'
    ) THEN
        ALTER TABLE omnex_system_identity.user_tenant_membership
            ADD CONSTRAINT fk_user_tenant_membership_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE RESTRICT;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
CREATE OR REPLACE FUNCTION omnex_system_identity.enforce_user_tenant_membership_rules()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'OMNEX IDENTITY VIOLATION: tenant memberships may not be deleted';
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NEW.user_id <> OLD.user_id
           OR NEW.tenant_id <> OLD.tenant_id
           OR NEW.joined_at <> OLD.joined_at THEN
            RAISE EXCEPTION 'OMNEX IDENTITY VIOLATION: membership identity is immutable';
        END IF;

        IF OLD.exited_at IS NOT NULL AND NEW.exited_at IS NULL THEN
            RAISE EXCEPTION 'OMNEX IDENTITY VIOLATION: exited memberships may not be reactivated';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_user_tenant_membership_rules
ON omnex_system_identity.user_tenant_membership;

CREATE TRIGGER trg_enforce_user_tenant_membership_rules
BEFORE UPDATE OR DELETE
ON omnex_system_identity.user_tenant_membership
FOR EACH ROW
EXECUTE FUNCTION omnex_system_identity.enforce_user_tenant_membership_rules();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.user_tenant_membership
ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS deny_all_user_tenant_membership
ON omnex_system_identity.user_tenant_membership;

CREATE POLICY deny_all_user_tenant_membership
ON omnex_system_identity.user_tenant_membership
FOR ALL
USING (false);

COMMENT ON POLICY deny_all_user_tenant_membership
ON omnex_system_identity.user_tenant_membership IS
'Membership access is governed by Identity and Ops layers — deny-all by default.';

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_tenant_membership_user
ON omnex_system_identity.user_tenant_membership (user_id);

CREATE INDEX IF NOT EXISTS idx_user_tenant_membership_tenant
ON omnex_system_identity.user_tenant_membership (tenant_id);

CREATE INDEX IF NOT EXISTS idx_user_tenant_membership_status
ON omnex_system_identity.user_tenant_membership (membership_status);

COMMIT;

-- ============================================================
-- END OF ENGINE 005 — TENANT MEMBERSHIP CONTEXT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_006
-- ENGINE NAME: Role Definitions
-- ENGINE FUNCTION:
--   Canonical definition of platform roles used for
--   access control, responsibility, and tenant-context assignment.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (Optional: If role_scope_enum is required)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'role_scope_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.role_scope_enum AS ENUM (
            'TENANT',
            'SYSTEM',
            'GLOBAL'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.role (
    role_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    role_code      text NOT NULL UNIQUE,
    role_name      text NOT NULL,
    role_scope     omnex_system_identity.role_scope_enum NOT NULL DEFAULT 'TENANT',

    system_defined boolean NOT NULL DEFAULT false,
    created_at     timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.role IS
'Defines operational roles available within the platform for access control and responsibility scoping';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_role_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.role
            ADD CONSTRAINT chk_role_code_not_empty
            CHECK (length(role_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_role_name_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.role
            ADD CONSTRAINT chk_role_name_not_empty
            CHECK (length(role_name) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — root operational role table

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional: Add triggers for immutability or auditing

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.role ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'role'
          AND policyname = 'deny_all_role'
    ) THEN
        CREATE POLICY deny_all_role
        ON omnex_system_identity.role
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_role
        ON omnex_system_identity.role IS
        'Role definitions are access-controlled by system-level policy governance';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_role_scope
ON omnex_system_identity.role (role_scope);

CREATE INDEX IF NOT EXISTS idx_role_created
ON omnex_system_identity.role (created_at DESC);

COMMIT;

-- ============================================================
-- END OF ENGINE 006 — ROLE DEFINITIONS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_007
-- ENGINE NAME: Permission Definitions
-- ENGINE FUNCTION:
--   Defines fine-grained operational permissions
--   that can be assigned to roles, users, or contexts.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None required

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.permission (
    permission_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_code         text NOT NULL,
    permission_description  text NOT NULL,
    created_at              timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.permission IS
'Defines atomic, fine-grained permissions available for assignment to roles or users';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_permission_code_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.permission
            ADD CONSTRAINT chk_permission_code_not_empty
            CHECK (length(permission_code) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_permission_description_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.permission
            ADD CONSTRAINT chk_permission_description_not_empty
            CHECK (length(permission_description) > 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_permission_code'
    ) THEN
        ALTER TABLE omnex_system_identity.permission
            ADD CONSTRAINT uq_permission_code
            UNIQUE (permission_code);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None at this phase

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional future: immutability trigger for permission_code

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.permission ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'permission'
          AND policyname = 'deny_all_permission'
    ) THEN
        CREATE POLICY deny_all_permission
        ON omnex_system_identity.permission
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_permission
        ON omnex_system_identity.permission IS
        'Permission definitions are centrally governed; default deny-all access';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_permission_code
ON omnex_system_identity.permission (permission_code);

CREATE INDEX IF NOT EXISTS idx_permission_created_at
ON omnex_system_identity.permission (created_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 007 — PERMISSION DEFINITIONS
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_008
-- ENGINE NAME: Role–Permission Mapping
-- ENGINE FUNCTION:
--   Defines which permissions are granted to which roles in
--   the Omnex identity and access model.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None required

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.role_permission (
    role_permission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    role_id            uuid NOT NULL,
    permission_id      uuid NOT NULL,
    granted_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.role_permission IS
'Defines permissions granted to roles in the identity access model';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_role_permission_unique'
    ) THEN
        ALTER TABLE omnex_system_identity.role_permission
            ADD CONSTRAINT uq_role_permission_unique
            UNIQUE (role_id, permission_id);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_role_permission_role'
    ) THEN
        ALTER TABLE omnex_system_identity.role_permission
            ADD CONSTRAINT fk_role_permission_role
            FOREIGN KEY (role_id)
            REFERENCES omnex_system_identity.role (role_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_role_permission_permission'
    ) THEN
        ALTER TABLE omnex_system_identity.role_permission
            ADD CONSTRAINT fk_role_permission_permission
            FOREIGN KEY (permission_id)
            REFERENCES omnex_system_identity.permission (permission_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- (None required)

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.role_permission
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'role_permission'
          AND policyname = 'deny_all_role_permission'
    ) THEN
        CREATE POLICY deny_all_role_permission
        ON omnex_system_identity.role_permission
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_role_permission
        ON omnex_system_identity.role_permission IS
        'Access to role-permission mappings is centrally governed';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_role_permission_role
ON omnex_system_identity.role_permission (role_id);

CREATE INDEX IF NOT EXISTS idx_role_permission_permission
ON omnex_system_identity.role_permission (permission_id);

COMMIT;

-- ============================================================
-- END OF ENGINE 008 — ROLE–PERMISSION MAPPING
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_009
-- ENGINE NAME: User–Role–Tenant Binding
-- ENGINE FUNCTION:
--   Assigns roles to users in specific tenant contexts,
--   enabling scoped, governable role-based access control.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- (None required for this engine)

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.user_role_binding (
    binding_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id        uuid NOT NULL,
    tenant_id      uuid NOT NULL,
    role_id        uuid NOT NULL,

    assigned_by    uuid NOT NULL,
    assigned_at    timestamptz NOT NULL DEFAULT now(),
    revoked_at     timestamptz
);

COMMENT ON TABLE omnex_system_identity.user_role_binding IS
'Grants users specific roles within a tenant context for scoped access control';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_binding_revoked_after_assigned'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT chk_binding_revoked_after_assigned
            CHECK (
                revoked_at IS NULL OR revoked_at > assigned_at
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_user_role_tenant_unique_active'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT uq_user_role_tenant_unique_active
            UNIQUE (user_id, tenant_id, role_id)
            DEFERRABLE INITIALLY IMMEDIATE;
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_binding_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT fk_binding_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_binding_tenant'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT fk_binding_tenant
            FOREIGN KEY (tenant_id)
            REFERENCES omnex_system_core.tenant (tenant_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_binding_role'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT fk_binding_role
            FOREIGN KEY (role_id)
            REFERENCES omnex_system_identity.role (role_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_binding_assigned_by_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_role_binding
            ADD CONSTRAINT fk_binding_assigned_by_user
            FOREIGN KEY (assigned_by)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE SET NULL;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional: enforce immutability or uniqueness on active assignments

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.user_role_binding
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'user_role_binding'
          AND policyname = 'deny_all_user_role_binding'
    ) THEN
        CREATE POLICY deny_all_user_role_binding
        ON omnex_system_identity.user_role_binding
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_role_binding
        ON omnex_system_identity.user_role_binding IS
        'Access to user-role bindings is controlled by delegated tenant role governance';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_role_binding_user
ON omnex_system_identity.user_role_binding (user_id);

CREATE INDEX IF NOT EXISTS idx_user_role_binding_tenant
ON omnex_system_identity.user_role_binding (tenant_id);

CREATE INDEX IF NOT EXISTS idx_user_role_binding_role
ON omnex_system_identity.user_role_binding (role_id);

CREATE INDEX IF NOT EXISTS idx_user_role_binding_revoked
ON omnex_system_identity.user_role_binding (revoked_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 009 — USER–ROLE–TENANT BINDING
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_010
-- ENGINE NAME: Device Registration
-- ENGINE FUNCTION:
--   Registers devices used by identity users,
--   for trust evaluation, access governance, and lifecycle tracking.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'device_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.device_type_enum AS ENUM (
            'MOBILE',
            'TABLET',
            'DESKTOP',
            'LAPTOP',
            'KIOSK',
            'UNKNOWN'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.identity_user_device (
    device_id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id             uuid NOT NULL,
    device_type         omnex_system_identity.device_type_enum NOT NULL DEFAULT 'UNKNOWN',
    device_fingerprint  text NOT NULL,
    trusted             boolean NOT NULL DEFAULT false,

    registered_at       timestamptz NOT NULL DEFAULT now(),
    last_seen_at        timestamptz
);

COMMENT ON TABLE omnex_system_identity.identity_user_device IS
'Registers identity-linked devices for access control, trust, and session analysis';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_device_fingerprint_not_empty'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_device
            ADD CONSTRAINT chk_device_fingerprint_not_empty
            CHECK (length(device_fingerprint) > 0);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_device_user'
    ) THEN
        ALTER TABLE omnex_system_identity.identity_user_device
            ADD CONSTRAINT fk_device_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional future logic: flag suspicious devices or auto-revoke if inactive

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.identity_user_device
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'identity_user_device'
          AND policyname = 'deny_all_identity_user_device'
    ) THEN
        CREATE POLICY deny_all_identity_user_device
        ON omnex_system_identity.identity_user_device
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_identity_user_device
        ON omnex_system_identity.identity_user_device IS
        'Device access is scoped to identity trust layers — deny by default';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_device_user
ON omnex_system_identity.identity_user_device (user_id);

CREATE INDEX IF NOT EXISTS idx_user_device_fingerprint
ON omnex_system_identity.identity_user_device (device_fingerprint);

CREATE INDEX IF NOT EXISTS idx_user_device_trusted
ON omnex_system_identity.identity_user_device (trusted);

COMMIT;

-- ============================================================
-- END OF ENGINE 010 — DEVICE REGISTRATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_011
-- ENGINE NAME: Session Management
-- ENGINE FUNCTION:
--   Tracks user login sessions, associated devices, session state,
--   duration, and origin IP for trust and lifecycle management.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'session_status_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.session_status_enum AS ENUM (
            'ACTIVE',
            'ENDED',
            'REVOKED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.user_session (
    session_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id        uuid NOT NULL,
    device_id      uuid,
    session_status omnex_system_identity.session_status_enum NOT NULL DEFAULT 'ACTIVE',

    started_at     timestamptz NOT NULL DEFAULT now(),
    ended_at       timestamptz,
    ip_address     inet
);

COMMENT ON TABLE omnex_system_identity.user_session IS
'Tracks login sessions and their state over time for identity actors and their devices';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_session_end_after_start'
    ) THEN
        ALTER TABLE omnex_system_identity.user_session
            ADD CONSTRAINT chk_session_end_after_start
            CHECK (ended_at IS NULL OR ended_at >= started_at);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_session_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_session
            ADD CONSTRAINT fk_user_session_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_session_device'
    ) THEN
        ALTER TABLE omnex_system_identity.user_session
            ADD CONSTRAINT fk_user_session_device
            FOREIGN KEY (device_id)
            REFERENCES omnex_system_identity.identity_user_device (device_id)
            ON DELETE SET NULL;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional future: enforce only one active session per device if required

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.user_session
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'user_session'
          AND policyname = 'deny_all_user_session'
    ) THEN
        CREATE POLICY deny_all_user_session
        ON omnex_system_identity.user_session
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_session
        ON omnex_system_identity.user_session IS
        'User session data is trust-governed and must be explicitly exposed.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_user_session_user
ON omnex_system_identity.user_session (user_id);

CREATE INDEX IF NOT EXISTS idx_user_session_status
ON omnex_system_identity.user_session (session_status);

CREATE INDEX IF NOT EXISTS idx_user_session_device
ON omnex_system_identity.user_session (device_id);

CREATE INDEX IF NOT EXISTS idx_user_session_ip
ON omnex_system_identity.user_session (ip_address);

COMMIT;

-- ============================================================
-- END OF ENGINE 011 — SESSION MANAGEMENT
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_012
-- ENGINE NAME: Multi-Factor Authentication
-- ENGINE FUNCTION:
--   Stores MFA configuration and enforcement state per user,
--   enabling trust-based authentication layering.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'mfa_type_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.mfa_type_enum AS ENUM (
            'TOTP',
            'SMS',
            'EMAIL',
            'HARDWARE_KEY',
            'BIOMETRIC'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.user_mfa_config (
    mfa_config_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL,

    mfa_type        omnex_system_identity.mfa_type_enum NOT NULL,
    enabled         boolean NOT NULL DEFAULT false,
    enforced        boolean NOT NULL DEFAULT false,

    configured_at   timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE omnex_system_identity.user_mfa_config IS
'Stores per-user MFA configuration and enforcement state';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uq_user_mfa_type'
    ) THEN
        ALTER TABLE omnex_system_identity.user_mfa_config
            ADD CONSTRAINT uq_user_mfa_type
            UNIQUE (user_id, mfa_type);
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_mfa_config_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_mfa_config
            ADD CONSTRAINT fk_mfa_config_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Optional: add logic to prevent disabling enforced methods

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.user_mfa_config
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'user_mfa_config'
          AND policyname = 'deny_all_user_mfa_config'
    ) THEN
        CREATE POLICY deny_all_user_mfa_config
        ON omnex_system_identity.user_mfa_config
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_mfa_config
        ON omnex_system_identity.user_mfa_config IS
        'MFA configurations are centrally governed; access must be explicitly granted.';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_mfa_config_user
ON omnex_system_identity.user_mfa_config (user_id);

CREATE INDEX IF NOT EXISTS idx_mfa_config_type
ON omnex_system_identity.user_mfa_config (mfa_type);

CREATE INDEX IF NOT EXISTS idx_mfa_config_enabled
ON omnex_system_identity.user_mfa_config (enabled);

CREATE INDEX IF NOT EXISTS idx_mfa_config_enforced
ON omnex_system_identity.user_mfa_config (enforced);

COMMIT;

-- ============================================================
-- END OF ENGINE 012 — MULTI-FACTOR AUTHENTICATION
-- ============================================================
-- ============================================================
-- OMNEX SYSTEM IDENTITY MIGRATION FILE COMPLIANT
-- ============================================================

-- SYSTEM NO: system_002
-- SYSTEM ID: 2026002
-- SYSTEM CODE: OS_ID
-- SYSTEM NAME: Omnex_System_Identity

-- CATEGORY ID: C_OCF_2026001
-- CATEGORY CODE: OS_CF
-- CATEGORY NAME: Omnex_System_Core_Foundation

-- SCHEMA: omnex_system_identity

-- ENGINE NO: engine_013
-- ENGINE NAME: MFA Challenge Verification
-- ENGINE FUNCTION:
--   Stores time-sensitive MFA challenges and their verification outcomes,
--   supporting layered authentication events.

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026002_omnex_system_identity.sql

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
SET search_path = omnex_system_identity, public;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- Reuse existing ENUMs from omnex_system_identity schema
-- mfa_type_enum already defined in engine_012

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'mfa_challenge_status_enum'
          AND n.nspname = 'omnex_system_identity'
    ) THEN
        CREATE TYPE omnex_system_identity.mfa_challenge_status_enum AS ENUM (
            'PENDING',
            'VERIFIED',
            'FAILED',
            'EXPIRED'
        );
    END IF;
END $$;

-- ==========================
-- PHASE 3: TABLES
-- ==========================
CREATE TABLE IF NOT EXISTS omnex_system_identity.user_mfa_challenge (
    challenge_id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            uuid NOT NULL,
    mfa_type           omnex_system_identity.mfa_type_enum NOT NULL,
    challenge_status   omnex_system_identity.mfa_challenge_status_enum NOT NULL DEFAULT 'PENDING',
    issued_at          timestamptz NOT NULL DEFAULT now(),
    verified_at        timestamptz
);

COMMENT ON TABLE omnex_system_identity.user_mfa_challenge IS
'Stores MFA challenge artifacts and their verification lifecycle';

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_mfa_verified_after_issued'
    ) THEN
        ALTER TABLE omnex_system_identity.user_mfa_challenge
            ADD CONSTRAINT chk_mfa_verified_after_issued
            CHECK (
                verified_at IS NULL
                OR verified_at >= issued_at
            );
    END IF;
END $$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_mfa_challenge_user'
    ) THEN
        ALTER TABLE omnex_system_identity.user_mfa_challenge
            ADD CONSTRAINT fk_mfa_challenge_user
            FOREIGN KEY (user_id)
            REFERENCES omnex_system_identity.identity_user (user_id)
            ON DELETE CASCADE;
    END IF;
END $$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- Future: may enforce TTLs or revocation logic externally.

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_identity.user_mfa_challenge
ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'omnex_system_identity'
          AND tablename  = 'user_mfa_challenge'
          AND policyname = 'deny_all_user_mfa_challenge'
    ) THEN
        CREATE POLICY deny_all_user_mfa_challenge
        ON omnex_system_identity.user_mfa_challenge
        FOR ALL
        USING (false);

        COMMENT ON POLICY deny_all_user_mfa_challenge
        ON omnex_system_identity.user_mfa_challenge IS
        'MFA challenge records are sensitive and must be governed under RLS';
    END IF;
END $$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_mfa_challenge_user
ON omnex_system_identity.user_mfa_challenge (user_id);

CREATE INDEX IF NOT EXISTS idx_mfa_challenge_status
ON omnex_system_identity.user_mfa_challenge (challenge_status);

CREATE INDEX IF NOT EXISTS idx_mfa_challenge_issued_at
ON omnex_system_identity.user_mfa_challenge (issued_at);

COMMIT;

-- ============================================================
-- END OF ENGINE 013 — MFA CHALLENGE VERIFICATION
-- ============================================================
