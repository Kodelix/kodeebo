# ADR-0004: Operator access — owner-granted support sessions behind a database grant gate, no bypass role, no break-glass

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `cto` on the user's explicit
> confirmation. No other agent, and no skill on its own.**
> Why this is stated here: stories referencing a `Proposed` ADR are set `Blocked`,
> and epics require `Accepted`, so the field needs a named owner. `cto` is the
> role `coordination-rules.md` escalates technical conflicts to, and an ADR is
> that decision made durable.
>
> This does **not** relax the rule that `Status: Accepted` is never set without
> explicit user confirmation — it narrows *which agent* may set it once that
> confirmation exists. An agent that believes an ADR is ready says so and
> escalates; it does not edit this field.

## Date

2026-10-17

## Last Verified

2026-10-18

## Decision Makers

The founder (user) decided on 2026-10-17 (`docs/research/tenant-isolation.md` § 5, part 7: A + H + G, D on control-plane tables only, no break-glass) and set the values (grant 24 hours by default, 7 days at most; `clock_timestamp()`; audit committed before the read; superuser credential in the founder's Bitwarden; operator-id weak spot recorded, not fixed now). Drafted by `/architecture-decision`. **Revised 2026-10-18 at the user's instruction after an independent `/architecture-review` (FAIL, text fixes):** owner-only grant insert, the 7-day ceiling and the one-way revoke are now enforced in the database; the transaction limit is `transaction_timeout`; table classes and roles refer to ADR-0001; seats and lease state are tenant data (licensing M35), not control plane; the scope mechanics live in ADR-0002. **Founder decision 2026-10-18 added (§ 7a):** grant-free per-tenant usage counts (no money, names, items or bill contents), computed by `job_rt` in each tenant's scope and written to a CP table that `platform_rt` reads; the customer terms must disclose them. Stack-lead validation: NOT ASSESSED — `stack.backend` and `stack.data` are unset; it runs when `/setup-stack` picks the track. CTO-ADR: skipped — lean mode. Consulted roles named by the research (`cto`, `security-lead`): not spawned in this run. Acceptance: the user.

## Summary

Kodelix (the platform operator, one founder today) must be able to support venues and do guided installs without any login role that bypasses row-level security (ADR-0001), and without reading a tenant's staff data unless that tenant's owner allowed it. Decision: the only routine path to tenant data is an owner-approved, time-limited support grant (24 hours by default, 7 days at most, revocable at any time) that the ADR-0002 scope helper turns into a `support` scope and that the database itself checks in the support role's policies; writes go only through a fixed set of reviewed `SECURITY DEFINER` verbs, guided installs prefer a redacted diagnostic bundle, and when the owner cannot be reached the operator acts only on control-plane tables and infrastructure — there is no break-glass read of tenant data.

## Stack Compatibility

| Field | Value |
|-------|-------|
| **Stack layer(s)** | Data (PostgreSQL); Go backend **or** Ktor backend (undecided; the helper of ADR-0002) |
| **Domain** | Security (privileged access); Tenancy |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — PostgreSQL 18.6 role, policy and `SECURITY DEFINER` behaviours were executed in research spikes S70/S71 (tier E), beyond the stack reference |
| **References Consulted** | `docs/stack-reference/postgres/VERSION.md`, `postgres/best-practices.md` § 1 (`admin_batch` only if an ADR accepts it — this ADR accepts none); `docs/research/tenant-isolation.md` part 7 (F701–F726, evidence `docs/research/evidence/tenant-isolation/part-7/`), part 1 (F101–F111), part 3 (F328), part 6 (F601); `docs/registry/architecture.yaml`; `docs/architecture/threat-models/licensing.md` TB3 and M15 (operator console) |
| **Pinned versions relied on** | `postgres:18.6` (`pins.yaml`); Go 1.27.2 / pgx 5.11.0; Kotlin 2.4.21 / Exposed 1.5.1 (helper only, ADR-0002) |
| **Post-Cutoff APIs Used** | None beyond ADR-0002. PostgreSQL features relied on: RLS policies with `TO <role>`, `clock_timestamp()` in a policy, column-level `UPDATE` grants, `SECURITY DEFINER` with a pinned `search_path`, `REVOKE EXECUTE ... FROM PUBLIC`, `pg_hba.conf` `local`/`peer`/`hostssl`/`replication`/`reject` records (F710, F711, F714–F716, F722) |
| **Verification Required** | Branch-scoped grant composed with the ADR-0003 restrictive policy, and the cost of `clock_timestamp()` in a policy on a realistic table (S72 PENDING); an audit write that survives a client rollback (S73 PENDING); the `support` scope kind in the chosen track's helper, including second-set refusal and `transaction_timeout` set inside the running transaction (S74 PENDING); the grant table's insert and update policies and the 7-day `CHECK` (with the first support story); the `pg_hba.conf` record shapes for the superuser and the backup role (infra ADR). The spikes S70/S71 used a permissive tenant policy `TO app_rt` and `USING (true)` / `WITH CHECK (true)` on the journal; this ADR's shape (restrictive tenant predicate, journal written only through `audit_writer`'s function) differs and is re-tested with the first support story |

Critical ADR: yes — privileged access across the tenant boundary decides whether ADR-0001's isolation holds for Kodelix itself (Foundation).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (tenancy model; no bypass role), ADR-0002 (scope helper), ADR-0003 (branch scope and session) — all Proposed; this ADR cannot be Accepted before them |
| **Enables** | Support-tooling epic (operator console read views and support verbs); the guided-install diagnostic bundle; `/threat-model tenant-isolation` (abuse cases AC1–AC13); the storage ADR's audit sink (grant and access journal); a team-growth amendment of this ADR when a second operator is added |
| **Blocks** | Every support or admin tool that reads or writes tenant data (ADR-0001: none is built until this ADR is Accepted); the licensing operator console's views of tenant data. Seat issuance, moves and leases are tenant data (TD, licensing M35) handled by the licensing service roles under the licensing ADR, not by this ADR's support path (Decision § 7) |
| **Ordering Note** | Accept after ADR-0001–0003. The first `/architecture-review` (2026-10-18) returned FAIL with text fixes, applied in this revision; a second independent review follows in a fresh session. S72–S74 run before the first support story, not before acceptance. |

## Context

### Problem Statement

ADR-0001 forbids `BYPASSRLS` and superuser on every runtime, job and support role, and states that no support or admin tooling is built until the operator path is decided. Kodelix still has to help venues: guided installs on cashier PCs, support tickets ("why does this bill look wrong", "this device will not sync") and, later, more staff. Without a decision the choices left are a standing cross-tenant role (BYPASSRLS in substance, F702, ti F328), signing in as the owner (no attribution, no consent), or ad-hoc SQL as the superuser — each turns one stolen credential or one console bug into access to every tenant's staff data.

### Current State

No backend code, no operator console. The bootstrap superuser exists only in spike containers. The licensing design (Draft) already plans an operator console for seat issuance, behind WebAuthn and step-up (`threat-models/licensing.md` TB3, M15).

### Constraints

- No role with `BYPASSRLS` or superuser for runtime, job or support use (ADR-0001, FP-BYPASSRLS-RUNTIME-ROLE).
- Scope only through the one helper, once per transaction, from a server-side source (ADR-0002, FP-SESSION-LEVEL-SCOPE, FP-SCOPE-FROM-REQUEST).
- `app.branch_all = 'on'` only for a verified owner role (ADR-0003, TR-BRANCH-SCOPE).
- One operator (the founder) today; zero-cost tooling preferred.
- PDPL: venue owner = controller, Kodelix = processor acting on the owner's written instruction (founder decision 2026-10-17); counsel told the founder no PDPL licence is needed now (brief Q2). Whether an owner-approved grant is the "written instruction", and whether an unapproved read is a breach, is open for counsel (P7-OQ3).
- Hosted only; no customer bundle.

### Requirements

- The database refuses a support read of a tenant whose owner has not granted access, even if the console has a bug (ASVS 8.4.1, 8.4.2).
- Owner revoke and grant expiry take effect on the next statement (ASVS 8.3.2).
- Every grant and every support access leaves an append-only, tamper-evident record the owner can see, which a client rollback cannot erase (ASVS 16.3.2, 16.4.2, 16.4.3).
- Writes only through named, reviewed actions.
- No new server component.

Research note: `docs/research/tenant-isolation.md` (part 7; § 5 part 7 holds the user's decision).

## Decision

**1. Support grant (owner-approved, enforced in the database).** A grant names tenant, an explicit branch list, scope (`read`, or one named write verb), reason, operator, request time, owner approver, approval time, expiry and revocation time. The **owner** approves it in the dashboard and can **revoke it at any time**. Expiry is **24 hours after approval by default and at most 7 days** (the 7-day ceiling exists for guided installs). An owner who picks "all branches" gets the current branch list written into the grant; a grant never sets `app.branch_all` (ADR-0003). `support_grants` is a TD table (ADR-0001) with these database rules, so a dashboard bug cannot widen a grant:
- **Owner-only insert.** `app_rt`'s `INSERT` policy requires `current_setting('app.branch_all', true) = 'on'` — set by the helper only for a verified owner (ADR-0003) — so a manager's dashboard session cannot create a grant, and the restrictive tenant predicate keeps it inside the owner's tenant (F714). The same policy requires `approved_at` to lie within the inserting transaction (`approved_at >= transaction_timestamp() AND approved_at <= clock_timestamp()`), so an approval cannot be back- or forward-dated.
- **7-day ceiling as a constraint.** `CHECK (expires_at > approved_at AND expires_at <= approved_at + interval '7 days')`. The 24-hour default stays configuration with a typed default; the ceiling is a security bound and changes only by migration.
- **Revoke is one-way.** `app_rt` has column-level `UPDATE` on `revoked_at` only; its `UPDATE` policy requires `app.branch_all = 'on'` and has `WITH CHECK (revoked_at IS NOT NULL)`, so a revoked grant cannot be reopened.
- `support_rt` reads only its own operator's grants and can change none (F714). Approval window (how long a request may wait) and session length inside a grant: open (P7-OQ1).

**2. Database grant gate.** `support_rt` (ADR-0001 inventory: LOGIN, NOSUPERUSER, NOBYPASSRLS, owns nothing) has `SELECT` only on TD tables. ADR-0001's restrictive tenant predicate and ADR-0003's restrictive `branch_scope` policy both bind it, so the grant's branch list limits it like an assignment limits a manager. Its own permissive policy on each TD table, written `TO support_rt`, requires a live grant for the context tenant and operator: approved, not revoked, `expires_at > clock_timestamp()` — **`clock_timestamp()`, not `now()`**, because `now()` keeps a grant alive for the rest of a transaction that started before expiry (F715b). With no live grant the role reads 0 rows of that tenant although it can set any tenant context (F714). Because the tenant predicate is restrictive for every role, no other role's permissive policy gives `support_rt` a way around the gate (the first draft's permissive tenant policy did — review B1).

**3. Scope through the ADR-0002 helper.** The operator console uses the helper's **Support** scope kind (specified in ADR-0002): it refuses with `NoLiveGrant` before any tenant query, sets `app.tenant_id`, `app.branch_ids` (the grant's list) and `app.operator_id` once, first, from the grant and the authenticated operator session — never from the request — and bounds the support transaction with **`transaction_timeout`** set locally from configuration (PostgreSQL 17+, confirmed in `docs/stack-reference/postgres/best-practices.md` line 53; behaviour inside the running transaction checked in S74). No second helper exists.

**4. Audit committed before the read.** Before any support read or verb, the helper writes an "access opened" record (grant, operator, tenant, branch list, scope, purpose) in **its own committed transaction**, then runs the read; outcome and row count are appended afterwards (ADR-0002, Support kind). A record written inside the reading transaction disappears when the client rolls back (F717). The mechanism — application-side commit or a `dblink` loopback — is chosen with S73. Records hold IDs only: no staff names, no row contents, no secrets.

**5. Three audit layers.** (i) A per-tenant, append-only grant and access journal with a hash chain — a TD table (ADR-0001). It is written only through `SECURITY DEFINER` append functions owned by `audit_writer` (NOLOGIN; `INSERT` only, through its own permissive policy); `support_rt` has `EXECUTE` on those functions and no direct grant on the table; `app_rt` reads it only as the owner (`SELECT` policy requiring `app.branch_all = 'on'`); no role may `UPDATE` or `DELETE`, and no policy is `USING (true)` or `WITH CHECK (true)` (unlike spike S70). It is the same control journal as the device and deletion records (tenant-isolation § 4.2 item 3); its home outside the restorable database is the storage ADR's, flagged on S33. (ii) The pre-read commit of § 4. (iii) The PostgreSQL server log for support, superuser and replication sessions, shipped off-host to a logically separate system (ASVS 16.4.3) as the check on (i), because a superuser can edit (i) and a chain does not detect deletion of its newest row (F718); the latest chain hash is anchored off-host. Retention: open (P7-OQ4).

**6. Writes only through support verbs (Option H).** Each write is a named `SECURITY DEFINER` function (for example "reset enrolment code", "resend lease", "mark review item") owned by `support_fn` (ADR-0001 inventory: NOLOGIN, non-bypass, owns no table), whose own permissive policies are gated by a live grant whose scope names that verb (F716); the restrictive tenant and `branch_scope` policies bind it too. Each verb has `SET search_path = <schema>, pg_temp`, `EXECUTE` revoked from `PUBLIC` and granted only to `support_rt` in the same migration (F710, F716), its own test, and its own audit record. `support_rt` has no `INSERT`, `UPDATE` or `DELETE` on tenant tables.

**7. Owner unreachable: control plane only, no break-glass.** Without a live owner grant Kodelix never reads tenant data. In an emergency the operator acts only on ADR-0001's **class CP** tables — tenant status and suspension, plan assignment and limit values, restore watermark — through `platform_rt`, the one role with a `USING (true)` policy, on CP tables only (Option D), and on infrastructure (restart, suspend, restore service). **Seats, seat licences, devices, seat moves, approvals and lease state are tenant data (class TD)**, as the licensing threat model M35 places them under tenant RLS: Kodelix reaches them only through the licensing service roles, working per tenant with the context set as the licensing ADR defines, or through a grant-gated support verb such as "resend lease". Reopening a consent-free path needs the founder and counsel (P7-OQ2, P7-OQ3).

**7a. Usage counts without a grant (founder, 2026-10-18).** Kodelix may see aggregated per-tenant usage statistics without an owner grant, as **counts only**: bills per business day, sessions, active devices and data size. **Never** money amounts, names, items or bill contents. They are produced this way:
- A job computes them per tenant **inside that tenant's scope**: `job_rt` through the ADR-0002 helper, one transaction per tenant with the tenant context set, under the restrictive tenant predicate like any other job. Nothing reads tenant data across tenants.
- The job writes **only the counts** to a class CP table (ADR-0001), for example `tenant_usage_daily (tenant_id, business_day, bills, sessions, active_devices, data_bytes, computed_at)`. Its columns are integers and dates by schema; no column can hold an amount, a name or text from a bill. `job_rt` writes its own tenant's row under the CP restrictive tenant policy; `platform_rt` reads all rows through its CP `USING (true)` policy.
- Data size is a per-tenant estimate; the method is chosen in the story (no per-tenant size function is sourced).
- **Money totals are not collected.** They would need an owner grant or a contract clause; neither is decided (founder, 2026-10-18).
- **Customer terms must state that Kodelix collects these counts** (what is counted, why, retention), so the collection is disclosed to the owner as controller before the first production tenant (PDPL roles: owner = controller, Kodelix = processor). Whether the counts are processing on the owner's instruction or Kodelix's own purpose is for counsel with P7-OQ3.

**8. Guided installs: diagnostic bundle first (Option G).** The device or the owner produces a redacted bundle (allow-listed fields: versions, sync state, error codes, device ids); the operator works from it. Where hosted tenant data is needed during a guided install, the owner grants a support grant of up to 7 days. Whether guided installs need hosted data at all in the first release: P7-OQ12.

**9. Privileged database roles.** The **bootstrap superuser** exists for DDL, role creation, extensions, major upgrades and restore — never as a support path. Its credential is **held by the founder in Bitwarden** (zero-cost custody, as for the licensing root); `pg_hba.conf` allows it only through a local `peer` record, with remote logins rejected (F722); every login pages and is reviewed. Reading tenant data through it is misuse (AC10). The **backup role** has `REPLICATION` only (no superuser, no BYPASSRLS), connects through an address-limited `hostssl replication` record, and its output is encrypted at rest: a physical copy holds every tenant in clear (F721). Tool, encryption and address list: storage ADR (P7-OQ7). Rotation and drill cadence of the superuser credential: open (P7-OQ8).

**10. One operator today — the operator-id weak spot is recorded, not fixed now.** `app.operator_id` is a setting the helper writes, so a second operator could present another operator's id and use that operator's grant (F715a). With one operator this changes nothing. **Trigger:** before a second operator gets console access, operator identity moves into the database through a per-operator login (`current_user`) or a signed claim the helper verifies (P7-OQ6), requester and approver of verbs must differ, and this ADR is amended.

### Architecture

```mermaid
sequenceDiagram
  participant O as Owner (dashboard)
  participant C as Operator console (Kodelix, WebAuthn + step-up)
  participant S as Scope helper (ADR-0002, support kind)
  participant J as Grant and access journal (append-only, hash chain)
  participant DB as PostgreSQL 18.6 (support_rt policies)
  participant L as Off-host log
  C->>O: support request (tenant, branches, scope, reason)
  O->>J: approve grant (expires <= 7 d, default 24 h) / revoke any time
  C->>S: open support session (grant id)
  S->>J: commit "access opened" (own transaction)
  S->>DB: BEGIN; set_config tenant, branch list, operator — once
  DB->>DB: policy: tenant = ctx AND live grant (clock_timestamp())
  DB-->>S: rows (0 if no live grant)
  S->>J: append outcome, row count
  DB-->>L: server log (support, superuser, replication sessions)
  Note over C,DB: owner unreachable: control-plane tables and infrastructure only
```

Trust boundaries: operator console ↔ hosted backend (licensing TB3); support role ↔ tenant tables (the grant gate); database host ↔ off-host log.

### Key Interfaces

```text
SupportGrant (class TD table support_grants; owner-only insert and one-way revoke enforced by policy)
  id, tenant_id, branch_ids: List<BranchId>   // explicit, never "all"
  scope: read | verb:<name>
  operator_id, reason
  requested_at, approved_by (owner user id)
  approved_at  // within the inserting transaction (policy)
  expires_at   // default approved_at + 24 h (config); CHECK expires_at <= approved_at + interval '7 days'
  revoked_at?  // UPDATE only to non-null (WITH CHECK revoked_at IS NOT NULL)

Scope kind Support { grantId, operatorId } — specified in ADR-0002
  // errors: NoLiveGrant, ScopeAlreadySet, InvalidScope; access record committed before the read

Support verbs: SECURITY DEFINER functions support.<verb>(...)
  // owned by a NOLOGIN non-bypass role; EXECUTE only for support_rt; each appends its audit record

Audit record (IDs only): grant_id, operator_id, tenant_id, branch_ids, scope, action, outcome, row_count, at, prev_hash, hash
```

No HTTP contract is fixed here; the console's API goes to `contracts/` with the support-tooling epic.

### Implementation Guidelines

- **Must (adapters, data):** create `support_rt`, `support_fn`, `audit_writer` and `backup_rt` exactly as ADR-0001's role inventory lists them; `support_rt` has `SELECT` only on TD tables; generate its grant-gated permissive policy `TO support_rt` for every TD table in the same migration that creates the table.
- **Must (adapters, data):** `support_grants` has `app_rt` `INSERT` and `UPDATE` policies requiring `app.branch_all = 'on'`, the `approved_at` window check, `WITH CHECK (revoked_at IS NOT NULL)` on update, column-level `UPDATE` on `revoked_at` only, and `CHECK (expires_at > approved_at AND expires_at <= approved_at + interval '7 days')`.
- **Must (adapters, data):** test grant liveness with `clock_timestamp()` in every support policy; never `now()` or `current_timestamp`.
- **Must (app):** open every support access through the ADR-0002 helper with the `support` scope kind; the helper commits the "access opened" record in its own transaction before the read.
- **Must (app):** take tenant, branch list and operator from the live grant and the authenticated operator session only (FP-SCOPE-FROM-REQUEST).
- **Must (adapters, data):** write support verbs as `SECURITY DEFINER` functions owned by a NOLOGIN non-bypass, non-owner role, with a pinned `search_path` ending in `pg_temp`, `EXECUTE` revoked from `PUBLIC` in the creating migration, one test and one audit record each.
- **Must (app, config):** the grant default (24 h) and the support `transaction_timeout` come from configuration with typed defaults; the 7-day ceiling is the database `CHECK` above and the app validates against the same value before insert.
- **Must (CI):** ADR-0001's catalogue checks cover this ADR (P7-OQ14): `USING (true)` only for `platform_rt` on CP tables and `auth_lookup` on PL tables; every TD table has a permissive policy `TO support_rt` gated by the grant; `SECURITY DEFINER` functions owned only by `auth_lookup`, `support_fn` or `audit_writer`, none `PUBLIC`-executable; no unexpected role membership (`pg_read_all_data`, `pg_write_all_data`, server-file roles, `REPLICATION` other than `backup_rt`).
- **Must never:** give `support_rt` or any support path `INSERT`, `UPDATE` or `DELETE` on tenant tables, `BYPASSRLS`, superuser, or membership in `pg_read_all_data` / `pg_write_all_data`.
- **Must never:** let the operator sign in as the owner or mint an owner session ("log in as"); a view-as keeps the operator's own identity.
- **Must never:** create per-grant database logins for support; human SQL sessions are for superuser DBA work only.
- **Must never:** cache grant state (a cached grant outlives the owner's revoke).
- **Must never:** read tenant data without a live owner grant, including in an emergency; use the superuser for support reads.
- **Must (jobs, data):** compute usage counts only as `job_rt` through the ADR-0002 helper, one tenant per transaction, and write only integer counts and dates to the CP usage table; `platform_rt` reads that table only.
- **Must never:** put money amounts, names, items, bill contents or any free text in the usage table, or compute usage statistics across tenants in one query; money totals need a grant or a contract clause (not decided).
- **Must (legal):** the customer terms state that Kodelix collects the usage counts before the first production tenant.
- **Must never:** build support or admin tooling that touches tenant data before this ADR is Accepted.

## Alternatives Considered

### Alternative 1: Read-only support role with a tenant context, no grant gate (B)

- **Description**: `support_rt` with `SELECT` and a plain `tenant = context` policy; who may open which tenant is decided in the console only.
- **Pros**: the least code; the same role and helper as the chosen option, minus the gate.
- **Cons**: the role can set any tenant, so the database stops nothing; one console bug or one stolen operator session reads every tenant; no owner consent.
- **Cost / Risk / Performance / Operability**: low build; medium-high cross-tenant and PDPL risk (needs counsel, F725); same performance as the runtime role; easy to run, which is its danger.
- **Rejection Reason**: it is the standing cross-tenant role ADR-0001 bans in substance; the grant gate costs one `EXISTS` per support statement and gives the database a veto (F714).

### Alternative 2: Break-glass read that alerts the owner (C)

- **Description**: the operator self-issues an emergency grant, the owner is alerted at once, a post-review follows (Entra pattern, F709).
- **Pros**: help when the owner cannot be reached.
- **Cons**: consent-free access to staff personal data; with one operator the only brake is the alert; its lawfulness is unanswered (F725); the two vendors read publish no such path (F708, F724).
- **Cost / Risk / Performance / Operability**: low-medium build; medium legal and insider risk; no performance cost; adds a sealed emergency credential and a review duty.
- **Rejection Reason**: the founder declined it (2026-10-17). The emergencies Kodeebo can foresee — a venue that cannot sell, a device that will not sync — are solved on the control plane and the infrastructure, not by reading staff data.

### Alternative 3: Bypass role for jobs and support (`admin_batch`, E)

- **Description**: a `BYPASSRLS` login role for audited cross-tenant work (`postgres/best-practices.md` § 1 permits it only by ADR).
- **Pros**: simplest cross-tenant queries.
- **Cons**: one bug or one stolen credential exposes every tenant; the catalogue check C4 exists to forbid it.
- **Cost / Risk / Performance / Operability**: low build; high risk; no performance cost; reopens ADR-0001.
- **Rejection Reason**: ADR-0001 and FP-BYPASSRLS-RUNTIME-ROLE; cross-tenant jobs iterate tenants with the context set.

### Alternative 4: Impersonation — operator signs in as the owner (F)

- **Description**: owner credential, magic link or "log in as" issuing the owner's session.
- **Pros**: no new screens.
- **Cons**: actions attributed to the owner (repudiation), no operator in the audit, the owner's MFA and consent bypassed; minting owner scope breaks FP-SCOPE-CLAIMS-IN-TOKEN.
- **Cost / Risk / Performance / Operability**: low build; high risk; none; support disputes cannot be resolved from the record.
- **Rejection Reason**: destroys attribution and consent; a view-as that keeps the operator's identity is the chosen option.

### Alternative 5: Per-grant database login for psql (I)

- **Description**: each approval creates a login role with `VALID UNTIL`; the operator uses psql.
- **Pros**: familiar tooling.
- **Cons**: `VALID UNTIL` expires a password only, and a local trust or peer login ignores it (F711, F719); a human session can read, roll back and erase an in-transaction audit row (F717); the helper and its scope discipline are bypassed; seeing what ran needs pgaudit, absent from `postgres:18.6` (F719).
- **Cost / Risk / Performance / Operability**: medium build (role provisioning with CREATEROLE); medium-high risk; none; a second extension to pin and patch.
- **Rejection Reason**: leaves the helper and the audit behind.

## Consequences

### Positive

- The owner sees and controls every Kodelix access to its data; the database refuses a support read without a live grant (F714).
- No bypass role and no new server component; ADR-0001's isolation holds for Kodelix itself.
- Writes are a short, reviewed list; each verb is tested and audited.
- The design scales to a team by adding per-operator identity and a second approver, without redesign.

### Negative

- Support waits for the owner's approval; an unreachable owner means control-plane help only.
- A grant-gated policy per tenant table, a support verb per write action and an owner approval screen are extra work before the first support ticket.
- Three audit layers; layers (i) and (iii) depend on the storage and observability decisions.
- Until a second operator, the operator id is trusted from the helper (recorded weak spot, § 10).
- Usage counts (§ 7a) are a grant-free view of every tenant's activity level; the customer terms must disclose them, and the column list is the only thing keeping money and contents out.

### Neutral

- The licensing operator console's issuance and approval actions (seats, moves, leases) run through the licensing service roles under the licensing ADR, per tenant with the context set; any operator view of a tenant's data in that console falls under this ADR.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A console bug or stolen operator session reads a tenant with no grant (AC1) | Medium | Low (0 rows) | Grant gate in the policy (F714); denied attempts alerted |
| Read past expiry inside a long transaction (AC6) | Low | Medium | `clock_timestamp()` (F715b); helper bounds the transaction |
| Read-then-rollback erases the trace (AC5) | Low | High | Pre-read commit (F717); off-host log |
| Superuser edits or truncates the journal (AC4) | Low | High | Off-host log; hash anchored off-host; superuser logins page |
| Second operator uses another's grant (AC2) | Low today | High | Recorded; fixed before a second operator (§ 10, P7-OQ6) |
| Attacker poses as the owner to approve a grant (AC7) | Medium | High | Owner step-up on approval (ASVS 7.5.3, P7-OQ9); notify every owner contact; grant shows scope and expiry |
| A dashboard bug lets a manager create a grant, writes a long grant or reopens a revoked one | Low | High | Insert and update policies require `app.branch_all = 'on'`; 7-day `CHECK`; `WITH CHECK (revoked_at IS NOT NULL)` |
| `USING (true)` policy lands on a tenant table (AC12) | Low | High | Restrictive tenant predicate still holds (ADR-0001); catalogue test C2 allows `USING (true)` only for `platform_rt` on CP and `auth_lookup` on PL |
| Definer verb executable by `PUBLIC` or with an open `search_path` (AC9) | Low | High | Migration rule; catalogue test |
| Backup or replication credential stolen (AC8) | Low | High | Encrypted medium; address-limited record; alert on unexpected replication connections |
| Counsel rules a dashboard grant is not a "written instruction" (P7-OQ3) | Unknown | Medium | Contract text names the grant as the instruction; revisit on counsel's answer |

## Cross-Cutting Impact

| Concern | Impact |
|---------|--------|
| **Security / tenancy** | New trust boundary (support role ↔ tenant tables) and the operator console boundary (licensing TB3). ASVS 5.0.0: 8.4.1, 8.4.2, 8.3.1, 8.3.2, 8.2.2, 13.2.2, 13.3.1/13.3.2, 16.2.1, 16.3.2, 16.3.3, 16.4.2, 16.4.3, 7.3.2, 7.4.1, 7.4.5, 7.5.3, 6.3.2, 6.3.3, 2.3.5 (exception while one operator). Abuse cases AC1–AC13 to `docs/architecture/threat-models/tenant-isolation.md` (to be written). Usage counts (§ 7a): counts only, computed in each tenant's scope, disclosed in the customer terms |
| **Observability** | Spans `support.grant.request/approve/revoke`, `support.session`, `support.verb.<name>`, `audit.chain.verify`, `db.tenant_tx` with `scope.kind = support`; metrics `support_grant_total{state}`, `support_session_active`, `support_access_total{outcome}`, `support_grant_duration_seconds`, `audit_chain_verify_failures_total`; page on chain-verify failure, any superuser login, unexpected replication connection, denied support access, a grant past 7 days; runbooks: operator access and revoke, superuser custody and drill, backup credential rotation, restore drill. IDs only, no row data |
| **Caching** | No cache for grant state: a cached grant outlives the owner's revoke |
| **Self-hosted** | None — hosted only |
| **Cost** | No new component or licence; Bitwarden at zero cost; one `EXISTS` per support statement |

## Performance Implications

| Metric | Before | Expected After | Budget (`perf-budgets.md`) |
|--------|--------|---------------|--------|
| Latency p95 (affected endpoints) | n/a | counter and dashboard paths unchanged (policies are `TO support_rt`); support reads +1 `EXISTS` (unmeasured, S72) | budget not yet set |
| DB queries per request | n/a | support access +1 committed audit insert before the read, +1 append after | budget not yet set |
| Memory (service RSS) | n/a | unchanged | budget not yet set |
| Storage growth | n/a | one journal row per grant event and per support access; rare | budget not yet set |
| Network / payload | n/a | unchanged | budget not yet set |

## Migration Plan

Greenfield.

1. With the first tenant-table migration: create `support_rt` and its grant-gated policies; extend the catalogue checks (P7-OQ14).
2. Run S72–S74 on the chosen track before the first support story.
3. Support-tooling epic: grant table and owner approval screen, `support` scope kind in the helper, pre-read audit commit, journal, verbs one by one, diagnostic bundle.
4. Before the first production tenant: superuser custody runbook (Bitwarden, local `peer` only, rotation and drill — P7-OQ8), backup role and encryption (storage ADR).
5. Before a second operator gets console access: amend this ADR (§ 10).

**Rollback plan**: none needed before production. After production a grant-gate defect is fixed forward by migration; revoking all grants (owner or operator) stops all support access at once.

## Validation Criteria

- [ ] `support_rt` with no live grant reads 0 rows of a tenant; with a grant for tenant A reads A and 0 rows of B in B's context (F714).
- [ ] Owner revoke and expiry stop reads on the next statement, including inside a transaction that started before expiry (F715b).
- [ ] The owner cannot create a grant for another tenant or extend one; the support role cannot change any grant (F714).
- [ ] `support_rt` writes to a tenant table are refused; a verb without a live grant naming it changes nothing (F716).
- [ ] A support read whose client rolls back still leaves its "access opened" record (S73).
- [ ] The journal's chain verification detects an edited row; the off-host log shows the superuser session that made it (F718).
- [ ] Catalogue checks fail on a planted `USING (true)` policy on a tenant table, a `PUBLIC`-executable definer function and an unexpected `pg_read_all_data` membership.
- [ ] A grant with `expires_at` more than 7 days after `approved_at` fails the `CHECK` constraint, whatever the application sends; the default is 24 hours.
- [ ] As a manager (`app.branch_all` unset), inserting a grant fails in the database; as the owner it succeeds; a back- or forward-dated `approved_at` fails.
- [ ] Setting `revoked_at` back to NULL fails (`WITH CHECK`); changing any other column fails (`permission denied`).
- [ ] `support_rt` with a grant for branch A1 reads 0 rows of A2 on branch-scoped tables (ADR-0003 `branch_scope`).
- [ ] The usage job, run with tenant A's context, writes only tenant A's row; a write for tenant B is refused; the usage table has no money, name, item or text column (schema test); `platform_rt` reads the usage table and nothing on TD tables.
- [ ] The customer terms carry the usage-count disclosure before the first production tenant (release checklist item).
- [ ] A support transaction that runs past the configured `transaction_timeout` is ended by the server (S74).
- [ ] Performance: support policy cost measured on a realistic table (S72); checked against `perf-budgets.md` once it exists, not checked until then.

## Spec Requirements Addressed

Foundational — no spec requirement. Enables: the support-tooling epic (operator console read views and verbs), the guided-install diagnostic bundle, the owner's "who from Kodelix accessed my data" view, and the tenant-data views of the licensing operator console.

## Related

- Depends on ADR-0001 (no bypass role; restrictive tenant predicate; table classes TD/CP/G/PL; role inventory), ADR-0002 (scope helper; Support kind), ADR-0003 (`branch_scope` binds `support_rt` and `support_fn`; `app.branch_all` only for a verified owner).
- Review: independent `/architecture-review` of ADR-0001–0004 (2026-10-18, FAIL, text fixes) — applied in this revision; a second independent review follows in a fresh session.
- Research: `docs/research/tenant-isolation.md` part 7 (F701–F726; evidence `docs/research/evidence/tenant-isolation/part-7/`; S70 partly a wrong test, labelled; S71 corrected), § 5 part 7 (decision and founder values), § 9 part 7 (P7-OQ1–P7-OQ14).
- Licensing: `docs/architecture/threat-models/licensing.md` TB3 and M15 (operator console identity, WebAuthn, step-up — relied on, not decided here); `docs/architecture/licence-model.md` § 12 (Draft).
- Privacy: `docs/architecture/privacy/pdpl-counsel-brief-2026-10.md` (Q1 roles; Q2 answered by counsel; Q6.9 remote support).
- Threat model: `docs/architecture/threat-models/tenant-isolation.md` (to be written; add AC1–AC13).
- Runbooks (none exist yet): operator access and revoke; superuser custody and drill; backup credential rotation; restore drill.
