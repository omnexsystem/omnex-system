# ✅ Omnex Compliance Checklist

📁 Location: `/audit/compliance_checklist.md`  
🛡️ Authority: Omnex System Core – Engine 000  
📅 Version: Genesis 2026 — Final  
🔐 Scope: Verifiable compliance conditions for Omnex Systems at install-time, runtime, and audit review.

---

## I. 📦 Installation-Time Compliance

| No. | Requirement                                 | Status Check Method                          |
|-----|---------------------------------------------|----------------------------------------------|
| 1   | System registered in `omnex_system_registry`| Match `system_id`, `schema`, and `code`      |
| 2   | Valid migration filename                    | Matches `2026XXX_omnex_system_<name>.sql`    |
| 3   | Canonical migration header exists           | All 12 identifiers present                   |
| 4   | All 8 migration phases present              | Phase 0–8 applied in order                   |
| 5   | Schema matches declared system schema       | SQL matches registry schema name             |
| 6   | Enum definitions pre-exist table creation   | Phase 2 precedes Phase 3                     |
| 7   | No cross-system foreign keys                | FK source and target in same schema          |
| 8   | RLS policies defined                        | At least one `POLICY` per table              |
| 9   | Triggers enforce only state/legal rules     | No business logic in triggers                |
| 10  | Audit triggers declared                     | `audit_hash` and state checks present        |

---

## II. 🔐 Post-Install Immutability Checks

| No. | Requirement                               | Enforced By                     |
|-----|-------------------------------------------|---------------------------------|
| 11  | No table or column drops allowed          | Trigger + Registry Hash         |
| 12  | Enums not mutated or redefined            | Enum immutability policy        |
| 13  | No FK deletions or reassignments          | DB trigger + registry scan      |
| 14  | No schema renames or merges               | Schema name lock                |
| 15  | No destructive DDL post-install           | Lock audit + trigger enforcement|

---

## III. 🔒 Runtime Execution Compliance

| No. | Requirement                              | Validation Scope                 |
|-----|------------------------------------------|----------------------------------|
| 16  | RLS `DENY ALL` by default                | Checked on schema load           |
| 17  | Policies explicitly declare grants       | Must reference role model        |
| 18  | All insert/update go through state logic| Via trigger/constraint path only |
| 19  | All actions emit signals or events       | Signal + event bus capture       |
| 20  | Triggers validate immutable fields       | `BEFORE UPDATE` lock enforcement |

---

## IV. 🧾 Audit Readiness Requirements

| No. | Requirement                            | Evidence Required                        |
|-----|----------------------------------------|------------------------------------------|
| 21  | Audit hash exists per table            | `audit_hash` column with hash policy     |
| 22  | System emits lifecycle events          | `system_event_log` entries present       |
| 23  | Identity matches registry              | Compare runtime vs `system_registry`     |
| 24  | No mutations after `status = Final`    | Schema DDL logs, install fingerprint     |
| 25  | Schema self-validates on load          | `self_check()` result = `pass`           |

---

## V. 🧠 Governance Compliance (Constitutional)

| Clause | Law Title                 | Must Be True                                         |
|--------|---------------------------|------------------------------------------------------|
| C0     | Migration Identity        | Header + filename immutable                          |
| C1     | Schema Sovereignty        | One system = one schema                              |
| C2     | ENUM Formalization        | ENUMs declared before usage                          |
| C3     | Phase Separation          | Phase 0–8 not skipped or reordered                   |
| C4     | Constraint Absolutism     | Rules in DB only, not in app code                    |
| C5     | Relationship Explicitness | No cross-system foreign keys                         |
| C6     | Logic Enforcement         | Triggers for legal state, not business logic         |
| C7     | Universal RLS             | RLS enforced on every table                          |
| C8     | Production Finality       | No DDL after system enters `Final` status            |

---

## 🧩 Compliance Engine Enforcement

> All checklist items are validated via:
- Migration verifier engine
- System core validator
- Bootstrap compliance hooks
- Audit enforcement triggers

✅ Systems failing compliance are **blocked from installation** or flagged during **runtime audits**.

---

📜 **Custodian:** Omnex Enterprise  
🔐 **Compliance Class:** SoS Constitutional  
🕓 **Last Updated:** Genesis Epoch — 2026
