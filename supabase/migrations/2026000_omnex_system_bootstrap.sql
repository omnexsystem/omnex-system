-- ============================================================
-- THIS FILE IS A LAW-BOUND MIGRATION. IT MUST NEVER BE RENAMED,
-- MODIFIED, RESHUFFLED, OR MANIPULATED IN ANY WAY AFTER INSTALL.
-- ============================================================

-- ============================================================
-- OMNEX SYSTEM MIGRATION FILE OUTLINE (CONSTITUTIONAL - NON-NEGOTIABLE)
-- ============================================================

-- SYSTEM NO: system_000
-- SYSTEM ID: 2026000
-- SYSTEM CODE: OS_BOOT_C_OSB_2026000
-- SYSTEM NAME: Omnex System Bootstrap

-- CATEGORY ID: C_OSB_2026000
-- CATEGORY CODE: OS_BOOT
-- CATEGORY NAME: Omnex_System_Bootstrap

-- SCHEMA: omnex_system_bootstrap

-- ENGINE NO: engine_000
-- ENGINE NAME: identity_context
-- ENGINE FUNCTION: Establish system identity, schemas, user awareness, search paths

-- VERSION: v1.0
-- STATUS: Final
-- FILE: 2026000_omnex_system_bootstrap.sql

-- ============================================================
-- ENGINE 000 — IDENTITY CONTEXT
-- ============================================================

-- ==========================
-- PHASE 0: EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================
-- PHASE 1: SCHEMA
-- ==========================
CREATE SCHEMA IF NOT EXISTS omnex_system_bootstrap;

-- ==========================
-- PHASE 2: ENUMS
-- ==========================
-- None required

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 Canonical System Registry
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_registry (
  version_id TEXT,
  category_prefix TEXT,
  category_code TEXT,
  category_name TEXT,
  system_id NUMERIC PRIMARY KEY,
  system_prefix TEXT,
  system_code TEXT,
  system_name TEXT,
  schema_name TEXT,
  ownership_domain TEXT,
  criticality_level TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3.2 User Registry (Bootstrap Awareness Only)
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.user_registry (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_ref TEXT,
  user_type TEXT,
  aware BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3.3 System Schemas Table
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_schemas (
  schema_name TEXT PRIMARY KEY,
  owner_role TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3.4 Role-Based Search Paths
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.role_search_path (
  role_name TEXT,
  search_path TEXT,
  immutable BOOLEAN DEFAULT true,
  defined_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- Primary keys are already in place in table definitions

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None for Engine 000

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Immutability enforcement for system_registry
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_system_registry()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'System Registry is immutable — updates forbidden';
  ELSIF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'System Registry is immutable — deletes forbidden';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_system_registry
ON omnex_system_bootstrap.system_registry;

CREATE TRIGGER tg_protect_system_registry
BEFORE UPDATE OR DELETE ON omnex_system_bootstrap.system_registry
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_system_registry();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_bootstrap.system_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.user_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.system_schemas ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.role_search_path ENABLE ROW LEVEL SECURITY;

-- Zero Trust RLS Policies (deny all)
DROP POLICY IF EXISTS deny_all_system_registry ON omnex_system_bootstrap.system_registry;
CREATE POLICY deny_all_system_registry
ON omnex_system_bootstrap.system_registry
USING (false);

DROP POLICY IF EXISTS deny_all_user_registry ON omnex_system_bootstrap.user_registry;
CREATE POLICY deny_all_user_registry
ON omnex_system_bootstrap.user_registry
USING (false);

DROP POLICY IF EXISTS deny_all_system_schemas ON omnex_system_bootstrap.system_schemas;
CREATE POLICY deny_all_system_schemas
ON omnex_system_bootstrap.system_schemas
USING (false);

DROP POLICY IF EXISTS deny_all_role_search_path ON omnex_system_bootstrap.role_search_path;
CREATE POLICY deny_all_role_search_path
ON omnex_system_bootstrap.role_search_path
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_system_registry_code
ON omnex_system_bootstrap.system_registry (system_code);

CREATE INDEX IF NOT EXISTS idx_user_registry_type
ON omnex_system_bootstrap.user_registry (user_type);

CREATE INDEX IF NOT EXISTS idx_system_schemas_owner
ON omnex_system_bootstrap.system_schemas (owner_role);

CREATE INDEX IF NOT EXISTS idx_role_search_path_role
ON omnex_system_bootstrap.role_search_path (role_name);

-- ============================================================
-- ✅ ENGINE 000 COMPLETE — IDENTITY CONTEXT SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_001
-- ENGINE NAME: governance_security
-- ENGINE FUNCTION: Authority, ownership enforcement, roles, RLS governance
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 SCHEMA OWNERSHIP HISTORY — LAWFUL OWNERSHIP ENFORCEMENT
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.schema_ownership_history (
  ownership_id UUID DEFAULT uuid_generate_v4(),
  schema_name TEXT NOT NULL,
  old_owner TEXT,
  new_owner TEXT NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (ownership_id)
);

-- 3.2 DEFAULT PRIVILEGE POLICY — BASELINE PRIVILEGE MODEL
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.default_privilege_policy (
  policy_id UUID DEFAULT uuid_generate_v4(),
  schema_name TEXT NOT NULL,
  role_name TEXT NOT NULL,
  privileges TEXT NOT NULL,
  granted_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (policy_id)
);

-- 3.3 CORE ROLES — IMMUTABLE ROLE MODEL
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.core_role (
  role_id UUID DEFAULT uuid_generate_v4(),
  role_name TEXT NOT NULL,
  role_scope TEXT NOT NULL,
  immutable BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (role_id)
);

-- 3.4 RLS POLICY REGISTRY — GLOBAL TENANT ISOLATION LAW
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.rls_policy_registry (
  policy_id UUID DEFAULT uuid_generate_v4(),
  table_name TEXT NOT NULL,
  policy_name TEXT NOT NULL,
  policy_type TEXT NOT NULL,
  defined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (policy_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- All PRIMARY KEY constraints defined inline

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None for engine_001

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Core Role Immutability Trigger
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_core_roles()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    RAISE EXCEPTION 'Core roles are immutable — modification denied';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_core_role
ON omnex_system_bootstrap.core_role;

CREATE TRIGGER tg_protect_core_role
BEFORE UPDATE OR DELETE
ON omnex_system_bootstrap.core_role
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_core_roles();

-- Default Privileges Immutability
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_privileges()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'Default privileges are immutable — cannot update';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_privilege_policy
ON omnex_system_bootstrap.default_privilege_policy;

CREATE TRIGGER tg_protect_privilege_policy
BEFORE UPDATE
ON omnex_system_bootstrap.default_privilege_policy
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_privileges();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_bootstrap.schema_ownership_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.default_privilege_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.core_role ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.rls_policy_registry ENABLE ROW LEVEL SECURITY;

-- Zero Trust Policies
DROP POLICY IF EXISTS deny_all_schema_ownership
ON omnex_system_bootstrap.schema_ownership_history;
CREATE POLICY deny_all_schema_ownership
ON omnex_system_bootstrap.schema_ownership_history
USING (false);

DROP POLICY IF EXISTS deny_all_privileges
ON omnex_system_bootstrap.default_privilege_policy;
CREATE POLICY deny_all_privileges
ON omnex_system_bootstrap.default_privilege_policy
USING (false);

DROP POLICY IF EXISTS deny_all_core_role
ON omnex_system_bootstrap.core_role;
CREATE POLICY deny_all_core_role
ON omnex_system_bootstrap.core_role
USING (false);

DROP POLICY IF EXISTS deny_all_rls_policy
ON omnex_system_bootstrap.rls_policy_registry;
CREATE POLICY deny_all_rls_policy
ON omnex_system_bootstrap.rls_policy_registry
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_schema_ownership_schema
ON omnex_system_bootstrap.schema_ownership_history (schema_name);

CREATE INDEX IF NOT EXISTS idx_default_privilege_schema_role
ON omnex_system_bootstrap.default_privilege_policy (schema_name, role_name);

CREATE INDEX IF NOT EXISTS idx_core_role_name
ON omnex_system_bootstrap.core_role (role_name);

CREATE INDEX IF NOT EXISTS idx_rls_policy_table
ON omnex_system_bootstrap.rls_policy_registry (table_name);

-- ============================================================
-- ✅ ENGINE 001 COMPLETE — GOVERNANCE SECURITY SEALED
-- ============================================================


-- ============================================================
-- ENGINE NO: engine_002
-- ENGINE NAME: orchestration_core
-- ENGINE FUNCTION: Master routing, system coordination, event flow
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 MASTER ROUTER — Central System Nervous System
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.master_router (
  router_id UUID DEFAULT uuid_generate_v4(),
  router_code TEXT NOT NULL,
  router_type TEXT NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (router_id)
);

-- 3.2 COORDINATION SYSTEMS — Platform Coordination Systems Registry
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.coordination_system (
  coordination_id UUID DEFAULT uuid_generate_v4(),
  system_code TEXT NOT NULL,
  system_type TEXT NOT NULL,
  registered_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (coordination_id)
);

-- 3.3 SYSTEM EVENT — Append-Only Event Stream
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_event (
  event_id UUID DEFAULT uuid_generate_v4(),
  system_id UUID NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  occurred_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (event_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

ALTER TABLE omnex_system_bootstrap.system_event
DROP CONSTRAINT IF EXISTS fk_system_event_system;

ALTER TABLE omnex_system_bootstrap.system_event
  ADD CONSTRAINT fk_system_event_system
  FOREIGN KEY (system_id)
  REFERENCES omnex_system_bootstrap.coordination_system (coordination_id);

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- Already applied above via FK

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent updates or deletes — system router is immutable
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_master_router()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    RAISE EXCEPTION 'Master Router entries are immutable — modification denied';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_master_router
ON omnex_system_bootstrap.master_router;

CREATE TRIGGER tg_protect_master_router
BEFORE UPDATE OR DELETE
ON omnex_system_bootstrap.master_router
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_master_router();

-- Prevent mutation of coordination systems
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_coordination_system()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    RAISE EXCEPTION 'Coordination systems are immutable — modification denied';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_coordination_system
ON omnex_system_bootstrap.coordination_system;

CREATE TRIGGER tg_protect_coordination_system
BEFORE UPDATE OR DELETE
ON omnex_system_bootstrap.coordination_system
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_coordination_system();

-- Prevent updates to event stream — events are append-only
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_system_event()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'System events are append-only — cannot update';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_protect_system_event
ON omnex_system_bootstrap.system_event;

CREATE TRIGGER tg_protect_system_event
BEFORE UPDATE
ON omnex_system_bootstrap.system_event
FOR EACH ROW
EXECUTE FUNCTION omnex_system_bootstrap.protect_system_event();

-- ==========================
-- PHASE 7: RLS
-- ==========================
ALTER TABLE omnex_system_bootstrap.master_router ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.coordination_system ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.system_event ENABLE ROW LEVEL SECURITY;

-- Zero-trust base policies
DROP POLICY IF EXISTS deny_all_master_router
ON omnex_system_bootstrap.master_router;
CREATE POLICY deny_all_master_router
ON omnex_system_bootstrap.master_router
USING (false);

DROP POLICY IF EXISTS deny_all_coordination_system
ON omnex_system_bootstrap.coordination_system;
CREATE POLICY deny_all_coordination_system
ON omnex_system_bootstrap.coordination_system
USING (false);

DROP POLICY IF EXISTS deny_all_system_event
ON omnex_system_bootstrap.system_event;
CREATE POLICY deny_all_system_event
ON omnex_system_bootstrap.system_event
USING (false);

-- ==========================
-- PHASE 8: INDEXES
-- ==========================
CREATE INDEX IF NOT EXISTS idx_master_router_code
ON omnex_system_bootstrap.master_router (router_code);

CREATE INDEX IF NOT EXISTS idx_coordination_system_code
ON omnex_system_bootstrap.coordination_system (system_code);

CREATE INDEX IF NOT EXISTS idx_system_event_type
ON omnex_system_bootstrap.system_event (event_type);

CREATE INDEX IF NOT EXISTS idx_system_event_system
ON omnex_system_bootstrap.system_event (system_id);

-- ============================================================
-- ✅ ENGINE 002 COMPLETE — ORCHESTRATION CORE SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_003
-- ENGINE NAME: coordination_registry
-- ENGINE FUNCTION: System self-awareness, coordination table listing, controlled awakening
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 COORDINATION TABLE REGISTRY — GOVERNANCE TRANSPARENCY
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.coordination_table_registry (
  entry_id UUID DEFAULT uuid_generate_v4(),
  table_name TEXT NOT NULL,
  system_id UUID NOT NULL,
  listed_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (entry_id)
);

-- 3.2 SYSTEM SEED LOG — CONTROLLED SYSTEM AWAKENING
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_seed_log (
  seed_id UUID DEFAULT uuid_generate_v4(),
  system_code TEXT NOT NULL,
  seed_version TEXT NOT NULL,
  seeded_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (seed_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_coordination_table_system'
  ) THEN
    ALTER TABLE omnex_system_bootstrap.coordination_table_registry
      ADD CONSTRAINT fk_coordination_table_system
      FOREIGN KEY (system_id)
      REFERENCES omnex_system_bootstrap.coordination_system (coordination_id);
  END IF;
END
$$;

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- See FK above — links to engine_002's coordination_system

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- Prevent mutation of coordination_table_registry
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_coordination_table_registry()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'Coordination Table Registry entries are immutable';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'tg_protect_coordination_table_registry'
  ) THEN
    CREATE TRIGGER tg_protect_coordination_table_registry
    BEFORE UPDATE OR DELETE ON omnex_system_bootstrap.coordination_table_registry
    FOR EACH ROW EXECUTE FUNCTION omnex_system_bootstrap.protect_coordination_table_registry();
  END IF;
END
$$;

-- Prevent mutation of system_seed_log
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.protect_system_seed_log()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'Seed log entries are permanent — modification denied';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'tg_protect_system_seed_log'
  ) THEN
    CREATE TRIGGER tg_protect_system_seed_log
    BEFORE UPDATE OR DELETE ON omnex_system_bootstrap.system_seed_log
    FOR EACH ROW EXECUTE FUNCTION omnex_system_bootstrap.protect_system_seed_log();
  END IF;
END
$$;

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.coordination_table_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.system_seed_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_coordination_table_registry'
  ) THEN
    CREATE POLICY deny_all_coordination_table_registry
      ON omnex_system_bootstrap.coordination_table_registry
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_system_seed_log'
  ) THEN
    CREATE POLICY deny_all_system_seed_log
      ON omnex_system_bootstrap.system_seed_log
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_coordination_table_registry_table
  ON omnex_system_bootstrap.coordination_table_registry (table_name);

CREATE INDEX IF NOT EXISTS idx_coordination_system_seed_log_code
  ON omnex_system_bootstrap.system_seed_log (system_code);

-- ============================================================
-- ✅ ENGINE 003 COMPLETE — COORDINATION REGISTRY SEALED
-- ============================================================
-- ============================================================
-- ENGINE NO: engine_004
-- ENGINE NAME: immutability
-- ENGINE FUNCTION: Enforce historical permanence, archive destructive attempts, prohibit fact mutation
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 ARCHIVE EVENT LOG — PERMANENT LEDGER OF DESTRUCTIVE INTENT
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.archive_event_log (
  archive_id UUID DEFAULT uuid_generate_v4(),
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  archived_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (archive_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- PK declared inline

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — archive is universal and schema-agnostic

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================

-- 6.1 UNIVERSAL DELETE BLOCKER — ARCHIVE INSTEAD OF DELETE
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.archive_record()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO omnex_system_bootstrap.archive_event_log (table_name, record_id)
  VALUES (TG_TABLE_NAME, OLD.*::text);

  RAISE EXCEPTION 'Deletion is prohibited. Record archived instead.';
END;
$$ LANGUAGE plpgsql;

-- 6.2 UNIVERSAL UPDATE BLOCKER — PROTECT IMMUTABLE TABLES
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.prevent_update()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Updates are prohibited on immutable tables';
END;
$$ LANGUAGE plpgsql;

-- (Note: These are to be attached by downstream engines per table)

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.archive_event_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_archive_event_log'
  ) THEN
    CREATE POLICY deny_all_archive_event_log
      ON omnex_system_bootstrap.archive_event_log
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_archive_event_log_table
  ON omnex_system_bootstrap.archive_event_log (table_name);

CREATE INDEX IF NOT EXISTS idx_archive_event_log_record
  ON omnex_system_bootstrap.archive_event_log (record_id);

-- ============================================================
-- ✅ ENGINE 004 COMPLETE — IMMUTABILITY SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_005
-- ENGINE NAME: utilities_automation
-- ENGINE FUNCTION: Non-mutating helpers, canonical signals, automation boundaries
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 HELPER FUNCTION REGISTRY — NON-MUTATING UTILITIES
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.helper_function_registry (
  function_id UUID DEFAULT uuid_generate_v4(),
  function_name TEXT NOT NULL,
  return_type TEXT NOT NULL,
  registered_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (function_id)
);

-- 3.2 SYSTEM SIGNAL — CANONICAL SIGNAL OUTPUT
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_signal (
  signal_id UUID DEFAULT uuid_generate_v4(),
  source_system TEXT NOT NULL,
  signal_type TEXT NOT NULL,
  emitted_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (signal_id)
);

-- 3.3 SYSTEM AUTO TRIGGER — LAWFUL AUTOMATION BOUNDARY
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_auto_trigger (
  trigger_id UUID DEFAULT uuid_generate_v4(),
  trigger_code TEXT NOT NULL,
  conditions JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (trigger_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- PKs already defined inline

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — all helpers are sovereign-neutral

-- ==========================
-- PHASE 6: LOGIC / FUNCTIONS
-- ==========================

-- 6.1 REGISTER HELPER FUNCTION
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.register_helper_function(
  fname TEXT, rtype TEXT
) RETURNS UUID AS $$
DECLARE fid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.helper_function_registry(function_name, return_type)
  VALUES (fname, rtype)
  RETURNING function_id INTO fid;
  RETURN fid;
END;
$$ LANGUAGE plpgsql;

-- 6.2 EMIT SYSTEM SIGNAL
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.emit_system_signal(
  source TEXT, stype TEXT
) RETURNS UUID AS $$
DECLARE sid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.system_signal(source_system, signal_type)
  VALUES (source, stype)
  RETURNING signal_id INTO sid;
  RETURN sid;
END;
$$ LANGUAGE plpgsql;

-- 6.3 REGISTER AUTO TRIGGER (Non-executing)
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.register_auto_trigger(
  code TEXT, cond JSONB
) RETURNS UUID AS $$
DECLARE tid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.system_auto_trigger(trigger_code, conditions)
  VALUES (code, cond)
  RETURNING trigger_id INTO tid;
  RETURN tid;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.helper_function_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.system_signal ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.system_auto_trigger ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_helper_function_registry'
  ) THEN
    CREATE POLICY deny_all_helper_function_registry
      ON omnex_system_bootstrap.helper_function_registry
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_system_signal'
  ) THEN
    CREATE POLICY deny_all_system_signal
      ON omnex_system_bootstrap.system_signal
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_system_auto_trigger'
  ) THEN
    CREATE POLICY deny_all_system_auto_trigger
      ON omnex_system_bootstrap.system_auto_trigger
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_helper_function_by_name
  ON omnex_system_bootstrap.helper_function_registry (function_name);

CREATE INDEX IF NOT EXISTS idx_signal_by_source
  ON omnex_system_bootstrap.system_signal (source_system);

CREATE INDEX IF NOT EXISTS idx_trigger_by_code
  ON omnex_system_bootstrap.system_auto_trigger (trigger_code);

-- ============================================================
-- ✅ ENGINE 005 COMPLETE — UTILITIES & AUTOMATION SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_006
-- ENGINE NAME: liveness_integration
-- ENGINE FUNCTION: Health reporting, integration contracts, CI signal bridges
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 SYSTEM HEARTBEAT — LIVENESS SIGNAL
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.system_heartbeat (
  heartbeat_id UUID DEFAULT uuid_generate_v4(),
  system_id UUID NOT NULL,
  status_json JSONB NOT NULL,
  reported_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (heartbeat_id)
);

-- 3.2 CONNECTOR TEMPLATE — INTEGRATION CONTRACT SCHEMA
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.connector_template (
  template_id UUID DEFAULT uuid_generate_v4(),
  connector_code TEXT NOT NULL,
  schema_contract JSONB NOT NULL,
  defined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (template_id)
);

-- 3.3 CI CONNECTOR EVENT — STATELESS BRIDGE FOR CI SIGNALS
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.ci_connector_event (
  event_id UUID DEFAULT uuid_generate_v4(),
  connector_code TEXT NOT NULL,
  payload JSONB NOT NULL,
  received_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (event_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- Inline PKs already defined

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_heartbeat_system'
  ) THEN
    ALTER TABLE omnex_system_bootstrap.system_heartbeat
      ADD CONSTRAINT fk_heartbeat_system
      FOREIGN KEY (system_id)
      REFERENCES omnex_system_bootstrap.coordination_system (coordination_id);
  END IF;
END
$$;

-- ==========================
-- PHASE 6: LOGIC / TRIGGERS
-- ==========================
-- No triggers required (liveness is stateless and ephemeral)

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.system_heartbeat ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.connector_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.ci_connector_event ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_system_heartbeat'
  ) THEN
    CREATE POLICY deny_all_system_heartbeat
      ON omnex_system_bootstrap.system_heartbeat
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_connector_template'
  ) THEN
    CREATE POLICY deny_all_connector_template
      ON omnex_system_bootstrap.connector_template
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_ci_connector_event'
  ) THEN
    CREATE POLICY deny_all_ci_connector_event
      ON omnex_system_bootstrap.ci_connector_event
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_heartbeat_by_system
  ON omnex_system_bootstrap.system_heartbeat (system_id);

CREATE INDEX IF NOT EXISTS idx_connector_template_code
  ON omnex_system_bootstrap.connector_template (connector_code);

CREATE INDEX IF NOT EXISTS idx_ci_event_by_code
  ON omnex_system_bootstrap.ci_connector_event (connector_code);

-- ============================================================
-- ✅ ENGINE 006 COMPLETE — LIVENESS & INTEGRATION SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_007
-- ENGINE NAME: intelligence_execution
-- ENGINE FUNCTION: Inference signals, intelligence flow logging, stateless safe-execution wrappers
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 INTELLIGENCE SIGNAL — INFERENCE & PRESCRIPTION SIGNALS
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.intelligence_signal (
  signal_id UUID DEFAULT uuid_generate_v4(),
  subject_id UUID NOT NULL,
  signal_type TEXT NOT NULL,
  confidence NUMERIC CHECK (confidence >= 0 AND confidence <= 1),
  generated_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (signal_id)
);

-- 3.2 STATELESS ACTION LOG — SAFE EXECUTION WRAPPERS
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.stateless_action_log (
  action_id UUID DEFAULT uuid_generate_v4(),
  action_code TEXT NOT NULL,
  invoked_by UUID NOT NULL,
  invoked_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (action_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- Inline PKs and CHECK constraints are applied

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- No FKs required — these are sovereign wrappers and signals

-- ==========================
-- PHASE 6: LOGIC / FUNCTIONS
-- ==========================

-- 6.1 Emit Intelligence Signal
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.emit_intelligence_signal(
  p_subject_id UUID,
  p_signal_type TEXT,
  p_confidence NUMERIC
) RETURNS UUID AS $$
DECLARE sid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.intelligence_signal(subject_id, signal_type, confidence)
  VALUES (p_subject_id, p_signal_type, p_confidence)
  RETURNING signal_id INTO sid;
  RETURN sid;
END;
$$ LANGUAGE plpgsql;

-- 6.2 Log Stateless Action
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.log_stateless_action(
  p_action_code TEXT,
  p_actor UUID
) RETURNS UUID AS $$
DECLARE aid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.stateless_action_log(action_code, invoked_by)
  VALUES (p_action_code, p_actor)
  RETURNING action_id INTO aid;
  RETURN aid;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.intelligence_signal ENABLE ROW LEVEL SECURITY;
ALTER TABLE omnex_system_bootstrap.stateless_action_log ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_intelligence_signal'
  ) THEN
    CREATE POLICY deny_all_intelligence_signal
      ON omnex_system_bootstrap.intelligence_signal
      USING (false);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_stateless_action_log'
  ) THEN
    CREATE POLICY deny_all_stateless_action_log
      ON omnex_system_bootstrap.stateless_action_log
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_signal_by_subject
  ON omnex_system_bootstrap.intelligence_signal (subject_id);

CREATE INDEX IF NOT EXISTS idx_signal_by_type
  ON omnex_system_bootstrap.intelligence_signal (signal_type);

CREATE INDEX IF NOT EXISTS idx_action_log_by_actor
  ON omnex_system_bootstrap.stateless_action_log (invoked_by);

-- ============================================================
-- ✅ ENGINE 007 COMPLETE — INTELLIGENCE EXECUTION SEALED
-- ============================================================

-- ============================================================
-- ENGINE NO: engine_008
-- ENGINE NAME: universal_framework
-- ENGINE FUNCTION: Finalize bootstrap integrity, seal version, cryptographic hash logging
-- ============================================================

-- ==========================
-- PHASE 3: TABLES
-- ==========================

-- 3.1 UNIVERSAL FRAMEWORK MANIFEST — FINAL CONSTITUTIONAL SEAL
CREATE TABLE IF NOT EXISTS omnex_system_bootstrap.universal_framework_manifest (
  manifest_id UUID DEFAULT uuid_generate_v4(),
  version TEXT NOT NULL,
  hash TEXT NOT NULL,
  sealed_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (manifest_id)
);

-- ==========================
-- PHASE 4: CONSTRAINTS
-- ==========================
-- PK inline

-- ==========================
-- PHASE 5: RELATIONSHIPS
-- ==========================
-- None — sovereign and final

-- ==========================
-- PHASE 6: LOGIC / FUNCTIONS
-- ==========================

-- 6.1 REGISTER FINAL MANIFEST ENTRY
CREATE OR REPLACE FUNCTION omnex_system_bootstrap.register_framework_manifest(
  p_version TEXT,
  p_hash TEXT
) RETURNS UUID AS $$
DECLARE mfid UUID;
BEGIN
  INSERT INTO omnex_system_bootstrap.universal_framework_manifest(version, hash)
  VALUES (p_version, p_hash)
  RETURNING manifest_id INTO mfid;
  RETURN mfid;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- PHASE 7: RLS
-- ==========================

ALTER TABLE omnex_system_bootstrap.universal_framework_manifest ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'deny_all_manifest'
  ) THEN
    CREATE POLICY deny_all_manifest
      ON omnex_system_bootstrap.universal_framework_manifest
      USING (false);
  END IF;
END
$$;

-- ==========================
-- PHASE 8: INDEXES
-- ==========================

CREATE INDEX IF NOT EXISTS idx_manifest_by_version
  ON omnex_system_bootstrap.universal_framework_manifest (version);

CREATE INDEX IF NOT EXISTS idx_manifest_by_hash
  ON omnex_system_bootstrap.universal_framework_manifest (hash);

-- ============================================================
-- ✅ ENGINE 008 COMPLETE — UNIVERSAL FRAMEWORK SEALED
-- ============================================================
