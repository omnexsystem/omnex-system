# 🛡️ OMNEX SYSTEM MIGRATION GOVERNANCE MANUAL
## Constitutional Law for System Installation and Evolution

Status: ACTIVE  
Authority: Omnex System Core  
Scope: All Omnex System Systems and Engines  

---

## 1. PURPOSE

This document defines the **immutable law governing all database migrations** within the Omnex System-of-Systems (SoS).

A migration is not a development artifact.  
A migration is a **constitutional act** that alters sovereign system state.

---

## 2. FUNDAMENTAL PRINCIPLES

1. **Registry First**
   - No migration may execute unless the system and engine are declared in:
     `omnex_system_core.omnex_system_registry`

2. **Install-Time Finality**
   - Once applied, a migration is final.
   - No ALTER, DROP, or REWRITE is permitted on law-bound migrations.

3. **Deterministic Order**
   - Migrations must execute strictly by:
     SYSTEM → ENGINE → PHASE (0–8)

4. **Engine-Scoped Execution**
   - Each migration belongs to exactly one:
     - system_id
     - engine_no
   - Cross-system migrations are prohibited.

---

## 3. MIGRATION PHASE MODEL (MANDATORY)

Every migration file MUST follow this phase order:

0. Extensions  
1. Schema  
2. Enums  
3. Tables  
4. Constraints  
5. Relationships  
6. Logic / Triggers  
7. RLS  
8. Indexes  

Skipping or reordering phases is a constitutional breach.

---

## 4. IMMUTABILITY RULES

The following are **ABSOLUTELY FORBIDDEN** after installation:

- ALTER TABLE (except additive indexes if explicitly permitted)
- DROP TABLE
- DROP COLUMN
- RENAME ANYTHING
- Editing historical migration files

Violations invalidate system integrity.

---

## 5. VERSIONING LAW

- Version applies to **migration intent**, not code iteration.
- Version changes require a NEW migration file.
- Old migrations remain permanently intact.

---

## 6. ENFORCEMENT

- CI/CD must validate migration headers against the System Registry.
- Runtime loaders must refuse unregistered migrations.
- Audit must record every migration execution.

---

## 7. FINAL LAW

If a migration is not registry-declared, phase-correct, and immutable —  
**it does not exist**.
