# OSGMC-2026 — OMNEX SYSTEM GENESIS MIGRATION CONSTITUTION

📜 Edition: Genesis Epoch · Year: 2026  
🛡️ Status: FINAL — LAW-BOUND — NON-NEGOTIABLE  
🔐 Applies To: ALL Omnex Systems (present and future)  
📁 File Name: osgmc_2026_constitution.md  
🧠 Authority Scope: System birth, migration structure, schema sovereignty, engine identity, install order, and execution legality enforcement.

---

## I. MIGRATION STRUCTURE — 8-PHASE CONSTITUTIONAL INSTALL LOOP

All Omnex systems MUST be installed using the fixed eight-phase migration sequence.

| Phase | Layer         | Constitutional Function |
|-------|----------------|-------------------------|
| 0 | Extensions | Load PostgreSQL extensions required by system |
| 1 | Schema | Create sovereign system schema |
| 2 | ENUMs | Declare enums before table usage |
| 3 | Tables | Create tables without constraints |
| 4 | Constraints | Apply NOT NULL, CHECK, UNIQUE |
| 5 | Relationships | Apply internal foreign keys only |
| 6 | Triggers | Enforce state and immutability laws |
| 7 | RLS | Enforce tenant and role isolation |
| 8 | Indexes | Apply performance indexes last |

Violation of phase order = constitutional breach.

---

## II. MIGRATION FILE NAMING LAW

Migration files MUST follow this naming structure:

```
<SYSTEM_ID>_omnex_system_<snake_case_system_name>.sql
```

Example:

```
2026006_omnex_system_treasury.sql
```

Rules:

- File name immutable after install
- No renaming permitted
- No abbreviations
- Snake_case only
- Must reside in authorized migrations directory

---

## III. CANONICAL MIGRATION HEADER — MANDATORY

Every migration file MUST begin with this header block.

Nothing may precede it.

```sql
-- ============================================================
-- OMNEX SYSTEM MIGRATION FILE OUTLINE (CONSTITUTIONAL - FINAL)
-- ============================================================
-- SYSTEM NO:
-- SYSTEM ID:
-- SYSTEM CODE:
-- SYSTEM NAME:

-- CATEGORY ID:
-- CATEGORY CODE:
-- CATEGORY NAME:

-- SCHEMA:

-- ENGINE NO:
-- ENGINE NAME:
-- ENGINE FUNCTION:

-- VERSION:
-- STATUS:
-- FILE:
-- ============================================================
```

If header is malformed or incomplete → migration is invalid.

---

## IV. SYSTEM SOVEREIGNTY LAW

Each Omnex system:

- Owns exactly one schema
- Owns its tables
- Owns its engines
- Owns its RLS
- Owns its audit structures

Forbidden:

- Shared schemas
- Cross-system table ownership
- Cross-system foreign keys
- Shared mutable structures

Systems are sovereign and isolation-bound.

---

## V. ENGINE SCOPE LAW

- Engines are sub-domains within a system
- Engines are never systems
- Engines cannot exist outside system identity
- Engine identity must be declared in system registry
- Engine identifiers required:
  - engine_no
  - engine_id
  - engine_type
  - engine_function (install-time bound)

---

## VI. REGISTRY ALIGNMENT LAW

Every system and engine migration MUST resolve to a record in:

```
omnex_system_core.omnex_system_registry
```

If registry record missing → migration is illegal.

Registry is install-time authority source.

---

## VII. CONSTRAINT ABSOLUTISM

All invariants MUST be enforced at database layer:

- CHECK constraints
- FK constraints
- Immutable state triggers
- Hash seals
- Transition guards

Application logic cannot substitute DB invariants.

---

## VIII. IMMUTABILITY DOCTRINE

After installation:

- No table drops
- No column removal
- No enum mutation
- No constraint removal
- No FK removal
- No audit overwrite
- No destructive DDL

Corrections require forward migrations only.

Rollback forbidden outside Genesis reset window.

---

## IX. RLS UNIVERSAL ENFORCEMENT

Row Level Security is mandatory:

- Every table must have RLS
- Default = DENY ALL
- Access must be policy-bound
- Tenant isolation enforced at row level
- Role mapping must match role model policy

RLS disabled = system non-compliant.

---

## X. TRIGGER LAW

Triggers may enforce:

- Immutability
- State transitions
- Evidence capture
- Audit sealing

Triggers may NOT implement business workflows.

---

## XI. SIGNAL & EVENT TRACEABILITY LAW

All state transitions must emit:

- Event records
- Signal records
- Audit linkage
- Registry references

No silent transitions allowed.

All orchestration is signal-driven, never direct coupling.

---

## XII. POST-INSTALL VIOLATION LIST

Automatic rejection if detected:

- Header mismatch
- Schema mismatch
- Missing registry entry
- Phase order violation
- Cross-system FK
- Missing RLS
- Enum redefinition
- Post-install destructive DDL

---

## XIII. SELF-VALIDATION LAW

Each system must validate on load:

1. Header identity matches registry
2. Schema name matches registry
3. Engine identifiers declared
4. All phases completed
5. RLS active
6. Audit triggers active
7. No illegal DDL detected

Failure = execution denied.

---

## XIV. CONSTITUTIONAL FINALITY SEAL

Once installed under OSGMC-2026:

- Identity is permanent
- Schema is sovereign
- Engines are bound
- Law is executable
- Behavior is auditable

Omnex systems execute law — not preference.

---

**Custodian:** Omnex System Core  
**Authority Epoch:** Genesis 2026  
**Constitution Class:** SoS-Grade Enforcement
