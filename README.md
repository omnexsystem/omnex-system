# 📘 OMNEX SYSTEM — MASTER README.md

**Sovereign Digital Infrastructure | System-of-Systems Edition (2026)**  
**Version:** 1.0 – *Genesis Epoch*  
**Maintainer:** Omnex Systems Engineering  
**Contact:** [omnexsystem.ke@gmail.com](mailto:omnexsystem.ke@gmail.com)

---

## 🔗 Table of Contents

1. [🏛️ Overview](#-1-overview)
2. [⚙️ Core Principles](#-2-core-principles)
3. [🧩 Omnex Architecture](#-3-omnex-architecture)
4. [🔧 Engine Architecture (Bootstrap Canonical)](#-4-engine-architecture-bootstrap-canonical)
5. [📜 OGMC-2026 — Migration Constitution](#-5-ogmc-2026--migration-constitution)
6. [🧱 Installation & Deployment](#-6-installation--deployment)
7. [🔐 Governance & Security](#-7-governance--security)
8. [📡 Orchestration & Intelligence](#-8-orchestration--intelligence)
9. [🧬 Data & Immutability Laws](#-9-data--immutability-laws)
10. [🧪 Testing & CI](#-10-testing--ci)
11. [🚀 Developer Quick Start](#-11-developer-quick-start)
12. [🛰️ Roadmap](#-12-roadmap)
13. [🏁 Closing Declaration](#-13-closing-declaration)

---

## 🏛️ 1. Overview

Omnex is a **Sovereign Digital Infrastructure Platform** engineered as a **System-of-Systems (SoS)**.  
It is not an app. It is not a product.  
It is a **constitutional computing framework** designed to encode:

- Governance  
- Identity  
- Authority  
- Commercial logic  
- Operational state  
- Compliance  
- Intelligence  
- System orchestration  

Into a single deterministic, immutable, inspectable machine.

Omnex does **not evolve like software**.  
**Omnex evolves like law.**

### 📚 Foundations

- **OGMC-2026**: Omnex Governance & Migration Constitution  
- **Engine-based architecture**  
- Schema sovereignty  
- Deterministic migrations  
- Append-only data flow  
- Zero trust execution  
- Canonical registries  

This README is the **master documentation anchor** for:

> 📁 State Architecture | 👨‍💻 Engineers | 👮 Auditors | ⚙️ Operators | 🧠 System Maintainers

---

## ⚙️ 2. Core Principles

Omnex is governed by **five constitutional engineering doctrines**:

| Principle       | Definition                                                                 |
|----------------|------------------------------------------------------------------------------|
| **1. Determinism** | All systems and engines behave **exactly the same** wherever deployed |
| **2. Sovereignty** | Each system owns its schema, logic, identity, and audit                |
| **3. Immutability** | No destructive writes. Updates = new facts. Deletes forbidden        |
| **4. Auditability** | Every action must be traceable and verifiable                        |
| **5. SoS Readiness** | Engineered to serve both current and future national ecosystems     |

---

## 🧩 3. Omnex Architecture

Omnex consists of **seven architecture categories**, each made up of multiple sovereign systems:

| Category | Systems | Description |
|----------|---------|-------------|
| **0** | 1 | Bootstrap Core (8 engines) |
| **1** | 5 | Core Foundation: Core, Identity, Governance, Audit, Foundation Layer |
| **2** | 9 | Authority Systems: Treasury, Tax, Trade, etc. |
| **3** | 9 | Operational Systems: FinanceOps, TaxOps, etc. |
| **4** | 7 | EconomicFabric: Procurement, Logistics, etc. |
| **5** | 3 | Orchestration: MasterRouter, ERPRail, Intelligence |
| **6** | 10 | SmartTech Systems (SmartUshuru, SmartBiz, etc.) |
| **7** | 1 | Future Systems (reserved) |

---

## 🔧 4. Engine Architecture (Bootstrap Canonical)

Every system **must conform to the 8-engine model**:

| Engine No. | Engine Name                 | Functionality Description                                       |
|------------|-----------------------------|-----------------------------------------------------------------|
| 000        | Identity Context            | System identity, schema init, search paths                     |
| 001        | Governance & Security       | Roles, policies, privileges                                     |
| 002        | Orchestration Core          | Command and control layer                                       |
| 003        | Coordination Registry       | Coordination and registration functions                         |
| 004        | Immutability                | Append-only enforcement, archival                              |
| 005        | Utilities & Automation      | Internal helpers, tasks, pipelines                              |
| 006        | Liveness & Integration      | External integration, uptime tracking                           |
| 007        | Intelligence Execution      | Inference, AI, automated judgment                               |
| 008        | Universal Framework         | Cross-system common libraries and reference layers              |

---

## 📜 5. OGMC-2026 — Migration Constitution

**All migrations must follow constitutional law.**

### 🧾 Law 1 — Naming Convention
```txt
<YEAR><SEQ>_omnex_system_<systemname>.sql
```
Example:
```txt
2026001_omnex_system_core.sql
2026027_omnex_system_procurement.sql
```

### 📑 Law 2 — File Header
- Must declare: system ID, schema, engine number, version, etc.  
- **Header must never change**

### 🔒 Law 3 — No Update, No Delete
- Only **append** new facts unless explicitly permitted.

### 🔁 Law 4 — Engine Ordering
- Engines execute **in order: 000 → 008**
- Never swap or reorder

### 🏛️ Law 5 — Schema Sovereignty
- No shared sequences, tables, or logic across schemas

### 🚫 Law 6 — Search Path
- `public` schema is forbidden
- All roles must use **explicit search paths**

---

## 🧱 6. Installation & Deployment

### 💻 Requirements

- PostgreSQL 14+  
- Zero-trust roles  
- Supabase optional (hosting only)

### 🔧 Install Order

1. Bootstrap Engine-000 → Engine-008  
2. Core Foundation (start with `omnex_system_core`)  
3. Authority Systems  
4. Operational Systems  
5. EconomicFabric  
6. Orchestration Systems  
7. SmartTech Systems  
8. Future Systems

### ❌ Rollback Policy

- **No rollback allowed**
- All changes = **new migrations only**

---

## 🔐 7. Governance & Security

- Full **schema isolation**
- **Mandatory RLS** on all data systems
- Immutable audit trails
- Access governed via `omnex_system_core`

Each system defines:

- Roles  
- Privileges  
- Policies  
- Sovereign data boundaries  

---

## 📡 8. Orchestration & Intelligence

Handled by:

- 🧠 **ERPRail**  
- 🌐 **MasterRouter**  
- 🛰️ **Omnex Intelligence**

These systems enable:

- Stateless cross-system events  
- Inference engine logic  
- AI-assisted workflows  
- Immutable event trails

---

## 🧬 9. Data & Immutability Laws

Every domain table must uphold:

- Primary keys never reused  
- Archives preserve lineage  
- No overwrite of historical values  
- Events = append-only  

---

## 🧪 10. Testing & CI

All PRs must pass constitutional tests:

- ✅ Migration syntax validation  
- ✅ Determinism compliance  
- ✅ Schema diff protections  
- ✅ OGMC law enforcement  
- ✅ Engine order integrity  
- ✅ RLS policy enforcement  

---

## 🚀 11. Developer Quick Start

1. **Clone the repo**
2. Apply **Bootstrap Engine-000**
3. Apply **Core Foundation migrations**
4. Proceed system-by-system
5. Never violate OGMC laws

> Start every system with:  
> 🔑 `Engine-000` → System Initialization

---

## 🛰️ 12. Roadmap

- Implement 38+ Engine-000s for sovereign systems  
- Build **Omnex System Core**  
- Integrate Identity, Governance, Audit  
- Attach MasterRouter → ERPRail → Intelligence Stack  

---

## 🏁 13. Closing Declaration

Omnex is **not software** — it is the **constitutional fabric** for:

- National governance  
- Operational execution  
- Economic coordination  

Every schema, engine, and file must uphold:

> ✅ **Truth**  
> ✅ **Determinism**  
> ✅ **Sovereignty**  
> ✅ **Auditability**  
> ✅ **Immutable Law**

---

**MASTER README.md complete.**
