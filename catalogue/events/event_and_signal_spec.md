# 🛡️ OMNEX SYSTEM EVENT AND SIGNAL SPECIFICATION
> Sovereign Signalization & Orchestration Law

Status: ACTIVE  
Authority: Omnex System Core  
Scope: Entire Omnex System-of-Systems (SoS)

---

## 1. PURPOSE

This specification defines the **only lawful method of system orchestration** in Omnex.  
No Omnex system may directly invoke another.  
All coordination occurs through **signals**, routed via constitutional infrastructure:

- `MasterRouter`
- `ERP Rails`
- `Omnex Intelligence Layer`

---

## 2. DEFINITIONS

### 🧾 EVENT

> A verifiable fact emitted by a system or engine upon a meaningful state change.

Characteristics:
- Immutable
- Contextual (origin, tenant, timestamp)
- Triggered by system activity or external input

---

### 📡 SIGNAL

> A **governed orchestration unit**, derived from an event, carrying explicit routing and execution metadata.

Signals are:
- Observable
- Declarative
- Registered in the `System Signal Registry`
- Audited in the `Audit Signal Pipeline`

No execution may occur outside the signal channel.

---

## 3. ARCHITECTURAL LAYERS

### 1️⃣ SYSTEM EMITTER

Each Omnex system:
- Emits signals via its engine(s)
- Does **not know who consumes** the signal
- Cannot trigger other systems directly

Emitters declare:
- `event_code`
- `trigger_type`
- `signal_name`
- `severity`

---

### 2️⃣ MASTER ROUTER

A core coordination system responsible for:
- Reading the `Signal Registry`
- Resolving destinations
- Managing handoff to ERP Rails and/or Intelligence

The router is **declarative-only**.  
No hard-coded routes are allowed.

---

### 3️⃣ ERP RAILS

A structured relay engine responsible for:
- Coordinating transactional or sequential state changes
- Applying orchestration logic based on:
  - System role
  - Signal classification
  - Tenant context

ERP Rails execute **stateless dispatch**.

---

### 4️⃣ INTELLIGENCE LAYER

This layer:
- Observes signal traffic and event emissions
- Applies pattern recognition
- Emits **inference signals**
- Triggers **context-aware prescriptions**

> Intelligence does not act as an agent — it acts as an observer-judge-emitter.  
> It is always auditable and never procedural.

---

## 4. SYSTEM ISOLATION

Each system:
- Has no knowledge of others
- May not include references, foreign keys, or runtime calls to others
- Listens to signals only if explicitly subscribed (via system registry)

---

## 5. SIGNAL DESIGN SPEC

Each signal MUST include:

| Field               | Type      | Description                                |
|--------------------|-----------|--------------------------------------------|
| `signal_id`        | UUID      | Unique identifier                          |
| `source_system_id` | INTEGER   | Who emitted the signal                     |
| `event_code`       | TEXT      | Type of originating event                  |
| `trigger_type`     | TEXT      | manual, system, inference, subscription    |
| `severity`         | TEXT      | info, warning, critical                    |
| `payload_schema`   | TEXT      | JSON schema definition reference           |
| `router_policy`    | TEXT      | MasterRouter directive                     |
| `erp_rail_track`   | TEXT      | ERP Rail assignment                        |
| `audit_mandate`    | BOOLEAN   | True if auditable                          |

---

## 6. OPERATIONAL FLOW

| Event Origin      | Routed By     | Received By           | Audited By               |
|------------------|---------------|------------------------|---------------------------|
| System Engine     | MasterRouter  | Subscribed System(s)  | Audit Signal Pipeline     |
| External Trigger  | ERP Rail      | Declared system flow  | Omnex Governance Engine   |
| Intelligence      | Signal Bus    | Context Resolver      | System Intelligence Trace |

---

## 7. GOVERNANCE ENFORCEMENT

- Signals must be declared before they can be routed
- Undeclared signals are ignored and logged
- Only **MasterRouter** may perform routing
- **All signal transitions must be auditable**
- Intelligence layer must never act without emitting a signal

---

## 8. ILLEGAL BEHAVIOR

❌ Direct engine-to-engine calls  
❌ Hard-coded routing or logic  
❌ Undeclared signals or payloads  
❌ Manual routing outside MasterRouter  
❌ Hidden triggers or non-audited orchestration

---

## ✅ FINAL LAW

If it’s not declared as a signal,  
**it cannot exist in the Omnex System**.

If orchestration is not routed through MasterRouter,  
**it is unconstitutional**.

If state changes without audit trace,  
**it is illegal**.

---

> Omnex orchestration is not messaging.  
> Omnex orchestration is **constitutional signalization.**

