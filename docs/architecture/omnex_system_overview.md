# 🧭 OMNEX SYSTEM OVERVIEW — SoS GRADE
> **Document Class:** SoS-Grade System Architecture Overview  
> **Scope:** Full Constitutional Landscape of Omnex Systems  
> **Audience:** System Architects, Infrastructure Custodians, Governance Authorities  
> **Status:** Immutable Canonical Overview  
> **File:** omnex_system_overview.md  
> **Location:** /docs/architecture/

---

## I. 🎯 DEFINITION: SYSTEM-OF-SYSTEMS (SoS)

Omnex is not a software suite.  
Omnex is a **System-of-Systems (SoS)** framework:  
Each system is **sovereign**, self-governing, and designed for **constitutional operation**.

Key characteristics:

- **One system = one schema**
- **Systems do not talk to each other**
- **All cross-system operations occur via signals and orchestration**
- **Every system declares its engine(s) during install**
- **No shared data. No shared logic. No shared identity**

---

## II. 🏛️ SYSTEM CLASSIFICATIONS — BY CATEGORY

| Category ID          | Code      | Category Name                  | Purpose Domain                                         |
|----------------------|-----------|--------------------------------|--------------------------------------------------------|
| C_OSB_2026000        | OS_BOOT   | Omnex_System_Bootstrap         | Foundational bootstrap and loader                      |
| C_OCF_2026(001-005)  | OSCF      | Omnex_System_Core_Foundation   | Identity, registry, governance, install rules          |
| C_AS_2026(006-014)   | OSAS      | Omnex_System_Authority         | Treasury, Tax, Labour, Agriculture, etc.               |
| C_OPS_2026(015-023)  | OS_OPS    | Omnex_System_Operationals      | TaxOps, TradeOps, RevenueOps, HumanCapital             |
| C_EF_2026(027-033)   | OS_EF     | Omnex_System_EconomicFabric    | Procurement, Logistics, ICT, Manufacturing, etc.       |
| C_CO_2026(024-026)   | OS_CO     | Omnex_System_Orchestration     | Signal routing, ERP Rails, Intelligence                |
| C_ST_2026(034-043)   | OS_ST     | Omnex_System_Smarttech         | Smart systems (Pay, Ushuru, Clinic, etc.)              |
| C_FS_2026044         | OS_FUTURE | Omnex_System_Futuresystem      | Reserved for future expansion                          |

---

## III. ⚙️ SYSTEM STRUCTURE — THE 14-LINE SYSTEM IDENTITY

Every system in Omnex declares the following:

```text
-- SYSTEM NO:
-- SYSTEM ID:
-- SYSTEM CODE:
-- SYSTEM NAME:

-- CATEGORY ID:
-- CATEGORY CODE:
-- CATEGORY NAME:

-- SCHEMA:

-- ENGINE NO:
-- ENGINE ID:
-- ENGINE TYPE:
-- ENGINE NAME:
-- ENGINE FUNCTION:

-- VERSION:
-- STATUS:
-- FILE:
```

> This declaration is law-bound.  
> Enforced via: `/omnex_system_core/registry/omnex_system_registry.sql`  
> No system can execute without exact match to this identity header.

---

## IV. 🔐 SYSTEM SOVEREIGNTY PRINCIPLES

Every Omnex system must follow:

- 📦 **Schema Ownership:** Each system owns its schema completely  
- 🔐 **Access Control:** All access defined by system-specific roles and RLS  
- 🧠 **Engine Identity:** Declared at install — not discovered dynamically  
- 🛡️ **No Cross-System FKs:** Systems do not bind each other through constraints  
- 📶 **Signal-Only Communication:** All external interface via `system_signal_spec.json` and orchestration layer  
- 📑 **Auditable Actions:** Each system logs its own transitions and audit states independently

---

## V. 🧠 SYSTEM INTELLIGENCE LAYERS

Three critical layers elevate Omnex into orchestration and inference mode:

| Layer          | Purpose                                          | Declared In                                    |
|----------------|--------------------------------------------------|-------------------------------------------------|
| 🔀 ERP Rails   | Workflow automation + canonical flow channeling  | `omnex_system_orchestration.yaml`              |
| 📡 MasterRouter| Signal routing + state change dispatching        | `system_signal_spec.json`                      |
| 🧠 Intelligence| State prediction, inference, audit prescription  | `intelligence_trace_model.md`                  |

All 3 layers are **declarative only**.  
No imperative logic allowed.  
Execution is **driven by orchestration**, not coupling.

---

## VI. 🔁 ORCHESTRATION OVER COUPLING

Omnex systems do not “call” or “connect” to each other.

Instead:

1. One system emits a signal
2. Signal is routed by MasterRouter
3. ERP Rails resolve the canonical flow
4. Intelligence interprets, seals, and learns
5. Target system reacts to signal if it owns the trigger

---

## VII. 📚 MIGRATION ENFORCEMENT RULES

Each system migration must:

- Reside in `/migrations/` directory
- Begin with complete canonical header
- Use the 8-phase install loop:
  - Extensions → Schema → Enums → Tables → Constraints → Relationships → Triggers → RLS → Indexes
- Be final, sealed, immutable
- Be declared in the registry

All rules declared in:

- `osgmc_2026_constitution.md`
- `migration_governance_manual.md`

---

## VIII. ✅ SYSTEM SELF-ENFORCEMENT

Every system self-validates:

- ✔️ Registry match
- ✔️ Engine declared
- ✔️ Header integrity
- ✔️ Phases enforced
- ✔️ RLS activated
- ✔️ Signals declared
- ✔️ Audits enabled

If any fail → system blocks execution.

---

## IX. 🧱 FILE STRUCTURE LOCATION SUMMARY

| Artifact                             | Path                                      |
|-------------------------------------|-------------------------------------------|
| System Registry                     | `/core/registry/omnex_system_registry_law.sql` |
| Engine Catalogue                    | `/catalogue/engines/engine_catalogue.yaml`     |
| System Categories Index             | `/catalogue/system_catalogue.yaml`             |
| Signal Specification                | `/catalogue/events/system_signal_spec.json`    |
| Event Model                         | `/catalogue/events/system_event_spec.json`     |
| Orchestration Definition            | `/catalogue/events/event_and_signal_spec.md`   |
| Audit Enforcement                   | `/audit/compliance_checklist.md`               |
| Intelligence Trace Model            | `/intelligence/intelligence_trace_model.md`    |
| Stateless Execution Law             | `/intelligence/stateless_execution_policy.md`  |
| Migration Law                       | `/docs/constitution/osgmc_2026_constitution.md`|

---

## X. 🚫 ANTI-PATTERNS (ILLEGAL IN OMNEX)

- ❌ Cross-system foreign keys
- ❌ Dynamic schema discovery
- ❌ Engine execution outside declared system
- ❌ Orchestration via procedural logic
- ❌ Application-layer ownership of identity
- ❌ Shared schemas between systems
- ❌ Unlogged migrations
- ❌ Mutable post-install behavior

---

## 🛡️ SUMMARY

Omnex is a **self-validating constitutional platform** — not an application stack.

Systems are:

- Sovereign
- Immutable
- Signal-aware
- Stateless
- Auditable
- Install-order governed

All system behavior is bound to registry, schema, and signal.

**This is infrastructure-as-law.**

---

📜 Authored & Enforced by: `Omnex Enterprise`  
🔒 Classification: SoS Enforcement — Epoch 2026  
📁 Save as: `/docs/architecture/omnex_system_overview.md`

