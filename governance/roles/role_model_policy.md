# 🛡️ OMNEX SYSTEM ROLE MODEL POLICY
## Sovereign Access and Authority Law

Status: ACTIVE  
Authority: Omnex System Core  
Scope: All Systems, Engines, APIs, and Data  

---

## 1. PURPOSE

This policy defines the **only lawful mechanism** by which privileges are granted in Omnex.

There are:
- No ad-hoc grants
- No implicit access
- No engine-defined roles

---

## 2. ROLE SOVEREIGNTY

Roles are:
- Globally defined
- Centrally governed
- Immutable once activated

Roles are NOT:
- Users
- Groups
- Tenants

Roles are **authority constructs**.

---

## 3. ROLE CATEGORIES

1. **System Roles**
   - Control system lifecycle and configuration

2. **Operational Roles**
   - Execute domain-specific capabilities

3. **Governance Roles**
   - Audit, oversight, compliance, intervention

4. **Service Roles**
   - Machine or orchestration identities

---

## 4. PRIVILEGE RULES

- Privileges may ONLY be granted via roles.
- Direct GRANT statements are forbidden.
- Privileges must map to:
  - system_id
  - capability_code
  - access_level

---

## 5. TENANT BINDING

- Roles are assigned to tenants, not users.
- Users act through tenant-scoped role bindings.
- Revocation is immediate and absolute.

---

## 6. ENFORCEMENT

- All privilege checks resolve through Omnex System Core.
- Engines must never self-authorize.
- Audit logs are mandatory for all role assignments.

---

## 7. FINAL LAW

If access is not role-derived,  
**it is illegal**.
