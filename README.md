````markdown
# 📘 OMNEX SYSTEM — MASTER README.md

**Sovereign Digital Infrastructure | System-of-Systems (SoS) Grade Architecture**  
**Version:** Genesis 2026 — Consolidated Rails SoS Edition  
**Status:** FINAL — Canonical — Constitutional Runtime  
**Authority:** Omnex_System_Core  
**Maintainer:** Omnex System Engineering  
**Contact:** omnexsystem.ke@gmail.com  

---

# 🔗 Table of Contents

1. [🏛 Overview](#-1-overview)
2. [⚖ Constitutional Engineering Principles](#-2-constitutional-engineering-principles)
3. [🧩 Omnex System-of-Systems Architecture](#-3-omnex-system-of-systems-architecture)
4. [🛡 Identity & UUID Standard](#-4-identity--uuid-standard)
5. [🔧 Omnex System Engineering Design Model](#-5-omnex-system-engineering-design-model)
6. [🏗 Systems vs Engines](#-6-systems-vs-engines)
7. [📡 Sovereign Signalization & Rail Runtime](#-7-sovereign-signalization--rail-runtime)
8. [📜 OSGMC-2026 — Omnex System Genesis Migration Constitution](#-8-osgmc-2026--omnex-system-genesis-migration-constitution)
9. [🧱 Infrastructure Stack](#-9-infrastructure-stack)
10. [🔐 Governance & Security Model](#-10-governance--security-model)
11. [🧪 CI/CD & Determinism Enforcement](#-11-cicd--determinism-enforcement)
12. [🚀 Installation & Deployment Order](#-12-installation--deployment-order)
13. [🛰 Roadmap & Evolution Law](#-13-roadmap--evolution-law)
14. [🏁 Constitutional Declaration](#-14-constitutional-declaration)

---

# 🏛 1. Overview

The **Omnex System** is a **Sovereign System-of-Systems (SoS)**.

The Omnex System is not a single app.  
The Omnex System is not a typical ERP.  
The Omnex System is not a loose collection of microservices.

The Omnex System is a **constitutional digital infrastructure framework** engineered to encode:

- Governance
- Identity
- Authority
- Fiscal truth
- Operational execution truth
- Economic continuity truth
- Political lifecycle truth
- Intelligence observability
- AI augmentation (advisory only)
- Deterministic orchestration by rail

The Omnex System evolves like **law**, not like feature software.

Every structural element is:

- Declared
- Versioned
- Audited
- UUID-bound
- Deterministic
- Zero-trust enforced

---

# ⚖ 2. Constitutional Engineering Principles

The Omnex System is governed by sovereign engineering doctrines:

| Doctrine | Meaning |
|----------|---------|
| **Determinism** | Same input → same outcome across all deployments |
| **Schema Sovereignty** | Each Omnex System owns its schema boundary |
| **UUID Unification** | All system and engine identity is UUID (`gen_random_uuid()`) |
| **Zero-Trust Governance** | RLS is mandatory and default-deny |
| **Append-Only Mutation** | State evolves through facts; destructive writes forbidden |
| **Rail-Oriented Execution** | Cross-system execution flows through rails (OS_ORC) |
| **Signalized Orchestration** | No direct system-to-system invocation |
| **Audit Finality** | No state mutation without audit trace and hash seal |

---

# 🧩 3. Omnex System-of-Systems Architecture

The Omnex System consists of **9 Constitutional Categories** and **59 Registered Systems**.

## Constitutional Installation Order

```text
OS_BOOT
→ OS_CF
→ OS_ORC
→ OS_AUTH
→ OS_OPS
→ OS_ECOFAB
→ OS_STECH
→ OS_SIM
→ OS_FTR
````

## Category Map

| Code      | Category              | Constitutional Role                                          |
| --------- | --------------------- | ------------------------------------------------------------ |
| OS_BOOT   | Bootstrap             | Schema initialization & extension enablement                 |
| OS_CF     | Core Foundation       | Registry, Identity, Governance, Audit, Foundation primitives |
| OS_ORC    | Orchestration & Rails | Deterministic routing + coordination + rails runtime         |
| OS_AUTH   | Authority             | Sector authorities (Treasury, Tax, Trade, etc.)              |
| OS_OPS    | Operations            | Execution systems (FinanceOps, TaxOps, etc.)                 |
| OS_ECOFAB | Economic Fabric       | Domain production & continuity systems                       |
| OS_STECH  | SmartTech             | Interface/gateway layer (Next.js/React)                      |
| OS_SIM    | Simulation            | Modeling, scenario execution, optimization                   |
| OS_FTR    | Future                | Reserved namespace for controlled expansion                  |

Every Omnex System:

* Owns exactly one schema
* Emits events
* Produces signals
* Subscribes via registry
* Executes via rails
* Enforces RLS
* Seals audit evidence

---

# 🛡 4. Identity & UUID Standard

The Omnex System enforces UUID identity everywhere.

## System Identity

All Omnex Systems use:

```sql
system_id UUID PRIMARY KEY DEFAULT gen_random_uuid()
```

## Engine Identity

All Omnex System engines use:

```sql
engine_id UUID NOT NULL DEFAULT gen_random_uuid()
```

## UUID Law (Non-negotiable)

* No integer primary keys for systems or engines
* No shared sequences across schemas
* Event IDs are UUID
* Signal IDs are UUID
* Correlation IDs are UUID

Identity authority is **UUID-only**.

---

# 🔧 5. Omnex System Engineering Design Model

Each Omnex System is engineered as a sovereign module with:

## A) Schema Boundary

Each Omnex System owns exactly one schema:

```text
omnex_system_<name>
```

No cross-schema foreign keys are permitted.

## B) Internal Layers (per system)

1. **Domain Layer** — tables and constraints for domain truth
2. **Event Layer** — immutable event emission (facts)
3. **Signal Layer** — event → signal transformation
4. **Governance Layer** — RLS + entitlements (OS_GOV compliance)
5. **Audit Layer** — evidence sealing (OS_AUD)

## C) Runtime Model

The Omnex System runtime is:

* Event-driven
* Signalized
* Rail-executed
* Coordinated for idempotency
* Audit sealed

---

# 🏗 6. Systems vs Engines

This is the correct logic:

## ✅ A “System” in the Omnex System

A **system** is a sovereign unit of capability and authority, identified by a UUID, owning a schema, and composed of **multiple engines**.

A system is:

* A schema boundary
* A registry identity (UUID)
* A declared installation target
* A producer of events and signals
* A subscriber through the signal registry

## ✅ An “Engine” in the Omnex System

An **engine** is a **sub-domain inside a single system schema**.

An engine is:

* Not a system
* Not deployable independently
* Not a cross-schema component
* A controlled internal layer used for deterministic migration structure and runtime separation

### Correct relationship

```text
A SYSTEM is composed of ENGINES.
ENGINES do not contain SYSTEMS.
```

So yes: **a system is a combination of engines** (sub-domains), not the other way around.

---

# 📡 7. Sovereign Signalization & Rail Runtime

The Omnex System forbids direct system invocation.

No Omnex System may:

* Call another Omnex System directly
* Perform cross-schema runtime queries into other systems
* Hardcode routing logic
* Bypass signals/rails

## Constitutional Rail Stack (OS_ORC)

* **OS_MR** — MasterRouter (sole routing authority)
* **OS_COORD** — coordination, idempotency, replay governance
* **OS_OPSR** — execution truth rail
* **OS_ERPR** — fiscal truth rail
* **OS_ASSR** — asset truth rail
* **OS_PROCR** — contract truth rail
* **OS_ESR** — supply truth rail
* **OS_LSR** — wellbeing truth rail
* **OS_POLR** — political lifecycle truth rail
* **OS_COGN** — intelligence observer rail
* **OS_AI** — advisory augmentation (signals only)

Constitutional flow:

```text
Event → Signal → OS_MR → OS_COORD → Rail → OS_AUD seal
```

If it is not a declared signal, it does not exist within the Omnex System.

---

# 📜 8. OSGMC-2026 — Omnex System Genesis Migration Constitution

```markdown
# OSGMC-2026 — OMNEX SYSTEM GENESIS MIGRATION CONSTITUTION

📜 Edition: Genesis Epoch · Year: 2026  
🛡️ Status: FINAL — LAW-BOUND — NON-NEGOTIABLE  
🔐 Applies To: ALL Omnex Systems (present and future)  
📁 File Name: osgmc_2026_constitution.md  
🧠 Authority Scope: System birth, migration structure, schema sovereignty, engine identity, install order, and execution legality enforcement.  
🆔 Identity Doctrine: All `system_id` and `engine_id` values MUST be `UUID` using `gen_random_uuid()`.

---

## I. MIGRATION STRUCTURE — 8-PHASE CONSTITUTIONAL INSTALL LOOP

All Omnex systems MUST be installed using the fixed eight-phase migration sequence.

| Phase | Layer | Constitutional Function |
|-------|--------|-------------------------|
| 0 | Extensions | Load PostgreSQL extensions required by system (including `pgcrypto` for UUID generation) |
| 1 | Schema | Create sovereign system schema |
| 2 | ENUMs | Declare enums before table usage |
| 3 | Tables | Create tables without constraints |
| 4 | Constraints | Apply NOT NULL, CHECK, UNIQUE |
| 5 | Relationships | Apply internal foreign keys only (UUID-based) |
| 6 | Triggers | Enforce state and immutability laws |
| 7 | RLS | Enforce tenant and role isolation |
| 8 | Indexes | Apply performance indexes last |

Violation of phase order = constitutional breach.

---

## II. MIGRATION FILE NAMING LAW

Migration files MUST follow this naming structure:

```
*omnex_system*<snake_case_system_name>.sql

```

Where:

Example:

```

omnex_system_treasury.sql

````

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
-- OMNEX SYSTEM MIGRATION FILE - (system name)
-- ============================================================
-- SYSTEM NO:
-- SYSTEM ID: (UUID REQUIRED — DEFAULT gen_random_uuid())
-- SYSTEM CODE:
-- SYSTEM NAME:

-- CATEGORY ID:
-- CATEGORY CODE:
-- CATEGORY NAME:

-- SCHEMA:

-- ENGINE NO:
-- ENGINE ID: (UUID REQUIRED — DEFAULT gen_random_uuid())
-- ENGINE NAME:
-- ENGINE FUNCTION:

-- VERSION:
-- STATUS:
-- FILE:
-- ============================================================
````

If header is malformed, contains non-UUID identity values, or is incomplete → migration is invalid.

---

## IV. SYSTEM SOVEREIGNTY LAW

Each Omnex system:

* Owns exactly one schema
* Owns its tables
* Owns its engines
* Owns its RLS
* Owns its audit structures
* Must be identified exclusively by `system_id UUID PRIMARY KEY DEFAULT gen_random_uuid()`

Forbidden:

* Shared schemas
* Cross-system table ownership
* Cross-system foreign keys
* Shared mutable structures
* Integer-based or sequential identity models

Systems are sovereign and isolation-bound.

---

## V. ENGINE SCOPE LAW

* Engines are sub-domains within a system
* Engines are never systems
* Engines cannot exist outside system identity
* Engine identity must be declared in system registry
* Engine identifiers required:

  * `engine_no` (documentation reference only)
  * `engine_id UUID NOT NULL DEFAULT gen_random_uuid()`
  * `engine_type`
  * `engine_function` (install-time bound)

All engine references must use UUID.

---

## VI. REGISTRY ALIGNMENT LAW

Every system and engine migration MUST resolve to a record in:

```
omnex_system_core.omnex_system_registry
```

Registry identity requirements:

* `system_id` MUST be UUID
* `engine_id` MUST be UUID
* All foreign keys referencing systems or engines MUST use UUID

If registry record missing → migration is illegal.

Registry is install-time authority source.

---

## VII. CONSTRAINT ABSOLUTISM

All invariants MUST be enforced at database layer:

* CHECK constraints
* UUID-based FK constraints
* Immutable state triggers
* Hash seals
* Transition guards

Example FK:

```sql
REFERENCES omnex_system_core.omnex_system_registry(system_id)
```

Application logic cannot substitute DB invariants.

---

## VIII. IMMUTABILITY DOCTRINE

After installation:

* No table drops
* No column removal
* No enum mutation
* No constraint removal
* No FK removal
* No audit overwrite
* No destructive DDL
* No mutation of `system_id`
* No mutation of `engine_id`

Corrections require forward migrations only.

Rollback forbidden outside Genesis reset window.

---

## IX. RLS UNIVERSAL ENFORCEMENT

Row Level Security is mandatory:

* Every table must have RLS
* Default = DENY ALL
* Access must be policy-bound
* Tenant isolation enforced at row level
* Role mapping must match role model policy
* All system references within RLS must use UUID

RLS disabled = system non-compliant.

---

## X. TRIGGER LAW

Triggers may enforce:

* Immutability
* State transitions
* Evidence capture
* Audit sealing
* UUID identity validation

Triggers may NOT implement business workflows.

---

## XI. SIGNAL & EVENT TRACEABILITY LAW

All state transitions must emit:

* Event records (`event_id` — UUID)
* Signal records (`signal_id` — UUID)
* Audit linkage
* Registry references (`system_id` — UUID)
* Engine references (`engine_id` — UUID)

No silent transitions allowed.

All orchestration is signal-driven, never direct coupling.

---

## XII. POST-INSTALL VIOLATION LIST

Automatic rejection if detected:

* Header mismatch
* Schema mismatch
* Missing registry entry
* Phase order violation
* Cross-system FK
* Missing RLS
* Enum redefinition
* Post-install destructive DDL
* Non-UUID `system_id`
* Non-UUID `engine_id`
* UUID mismatch between file and registry

---

## XIII. SELF-VALIDATION LAW

Each system must validate on load:

1. Header identity matches registry (UUID match)
2. Schema name matches registry
3. Engine identifiers declared (UUID)
4. All phases completed
5. RLS active
6. Audit triggers active
7. No illegal DDL detected

Failure = execution denied.

---

## XIV. CONSTITUTIONAL FINALITY SEAL

Once installed under OSGMC-2026:

* Identity is permanent
* Schema is sovereign
* Engines are UUID-bound
* Law is executable
* Behavior is auditable

Omnex systems execute law — not preference.
Identity authority = UUID (`gen_random_uuid()` mandatory).

---

**Custodian:** Omnex System Core
**Authority Epoch:** Genesis 2026
**Constitution Class:** SoS-Grade Enforcement

```

---

# 🧱 9. Infrastructure Stack

The Omnex System runs on a sovereign-grade modern infrastructure stack.

## Database Layer
- **Supabase (PostgreSQL 14+)**
  - RLS enforced
  - `pgcrypto` required for UUID generation (`gen_random_uuid()`)
  - Deterministic migrations
  - Audit sealing support

## Containerization
- **Docker**
  - Deterministic local environments
  - Reproducible builds
  - Parity across dev/staging/production

## Version Control & Review
- **GitHub**
  - Canonical migration ledger
  - PR-based constitutional review
  - CI enforcement

## Application Layer (SmartTech)
- **Next.js + React**
  - Interface/gateway systems (OS_STECH)
  - Secure routing patterns
  - Sovereign UI architecture

## Deployment Layer
- **Vercel**
  - SmartTech deployment
  - Secure runtime config
  - Edge delivery for frontends

---

# 🔐 10. Governance & Security Model

The Omnex System enforces:

- Schema isolation
- RLS mandatory, default deny
- Tenant-bound access
- Role-bound permissions
- Audit logging and hash sealing

Governance anchors:

- `Omnex_System_Governance (OS_GOV)`
- `Omnex_System_Audit (OS_AUD)`
- `Omnex_System_Core (OS_CORE)`

---

# 🧪 11. CI/CD & Determinism Enforcement

All pull requests must pass:

- Migration syntax validation
- UUID compliance validation
- OSGMC phase-order validation
- RLS presence validation
- Cross-schema dependency detection
- Signal/event schema compliance checks
- Deterministic diff checks

CI failure = constitutional breach.

---

# 🚀 12. Installation & Deployment Order

Constitutional order:

1. OS_BOOT
2. OS_CF
3. OS_ORC
4. OS_AUTH
5. OS_OPS
6. OS_ECOFAB
7. OS_STECH
8. OS_SIM
9. OS_FTR

Rollback forbidden (forward migrations only).

---

# 🛰 13. Roadmap & Evolution Law

All expansion must:

- Register new system identity (UUID)
- Declare new schema
- Bind to Core Foundation governance
- Declare signals before use
- Declare rail compatibility
- Pass constitutional review

Expansion must not mutate the constitutional core.

---

# 🏁 14. Constitutional Declaration

The Omnex System is a **Sovereign Digital Constitutional Runtime**.

Every Omnex System must uphold:

- Truth
- Determinism
- Sovereignty
- UUID identity
- Audit finality
- Zero trust
- Rail discipline
- Constitutional law

The Omnex System is not software.

The Omnex System is **sovereign-grade infrastructure computation**.

---

**MASTER README.md — SoS Grade Edition Complete**  
Genesis 2026 — Consolidated Rails SoS Runtime  
Authorized by Omnex_System_Core
```
