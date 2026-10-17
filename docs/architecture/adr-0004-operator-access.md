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

2026-10-17

## Decision Makers

The founder (user) decided on 2026-10-17 (`docs/research/tenant-isolation.md` § 5, part 7: A + H + G, D on control-plane tables only, no break-glass) and set the values (grant 24 hours by default, 7 days at most; `clock_timestamp()`; audit committed before the read; superuser credential in the founder's Bitwarden; operator-id weak spot recorded, not fixed now). Drafted by `/architecture-decision`. Stack-lead validation: NOT ASSESSED — `stack.backend` and `stack.data` are unset; it runs when `/setup-stack` picks the track. CTO-ADR: skipped — lean mode. Consulted roles named by the research (`cto`, `security-lead`): not spawned in this run. Acceptance: the user.

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
| **Verification Required** | Branch-scoped grant composed with the ADR-0003 restrictive policy, and the cost of `clock_timestamp()` in a policy on a realistic table (S72 PENDING); an audit write that survives a client rollback (S73 PENDING); the `support` scope kind in the chosen track's helper, including second-set refusal (S74 PENDING); the `pg_hba.conf` record shapes for the superuser and the backup role (infra ADR) |

Critical ADR: yes — privileged access across the tenant boundary decides whether ADR-0001's isolation holds for Kodelix itself (Foundation).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (tenancy model; no bypass role), ADR-0002 (scope helper), ADR-0003 (branch scope and session) — all Proposed; this ADR cannot be Accepted before them |
| **Enables** | Support-tooling epic (operator console read views and support verbs); the guided-install diagnostic bundle; `/threat-model tenant-isolation` (abuse cases AC1–AC13); the storage ADR's audit sink (grant and access journal); a team-growth amendment of this ADR when a second operator is added |
| **Blocks** | Every support or admin tool that reads or writes tenant data (ADR-0001: none is built until this ADR is Accepted); the licensing operator console's tenant-data views (its control-plane actions — seats, moves, leases — are not tenant data, see Decision § 6) |
| **Ordering Note** | Accept after ADR-0001–0003. The user plans `/architecture-review` of ADR-0001–0004 together in a fresh session. S72–S74 run before the first support story, not before acceptance. |

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

**1. Support grant (owner-approved).** A grant names tenant, an explicit branch list, scope (`read`, or one named write verb), reason, operator, request time, owner approver, approval time, expiry and revocation time. The **owner** approves it in the dashboard and can **revoke it at any time**. Expiry is **24 hours after approval by default and at most 7 days** (the 7-day ceiling exists for guided installs). An owner who picks "all branches" gets the current branch list written into the grant; a grant never sets `app.branch_all` (TR-BRANCH-SCOPE). Grants are rows in a tenant-scoped table: the owner role can insert a grant only for its own tenant and can update only `revoked_at` (F714); the support role can read only its own operator's grants and can change none (F714). Approval window (how long a request may wait) and session length inside a grant: open (P7-OQ1).

**2. Database grant gate.** A dedicated login role `support_rt` (NOSUPERUSER, NOBYPASSRLS, owns nothing) has `SELECT` only on tenant tables. Its policies, written `TO support_rt`, require both the tenant context and a live grant: approved, not revoked, `expires_at > clock_timestamp()` — **`clock_timestamp()`, not `now()`**, because `now()` keeps a grant alive for the rest of a transaction that started before expiry (F715b). With no live grant the role reads 0 rows of that tenant although it can set any tenant context (F714). The runtime roles' policies are unchanged.

**3. Scope through the ADR-0002 helper.** The operator console calls the same helper with a `support` scope kind built from the live grant: it sets `app.tenant_id`, `app.branch_ids` (the grant's list) and `app.operator_id` once, first, from the grant and the authenticated operator session — never from the request. No second helper exists. The helper bounds the length of a support transaction (setting chosen when sourced, F726c).

**4. Audit committed before the read.** Before any support read or verb, the helper writes an "access opened" record (grant, operator, tenant, branch list, scope, purpose) in **its own committed transaction**, then runs the read; outcome and row count are appended afterwards. A record written inside the reading transaction disappears when the client rolls back (F717). The mechanism — application-side commit or a `dblink` loopback — is chosen with S73. Records hold IDs only: no staff names, no row contents, no secrets.

**5. Three audit layers.** (i) A per-tenant, append-only grant and access journal with a hash chain (INSERT only for the writer roles; the owner reads its own tenant's journal) — the same control journal as the device and deletion records (tenant-isolation § 4.2 item 3; its home outside the restorable database is the storage ADR's, flagged on S33). (ii) The pre-read commit of § 4. (iii) The PostgreSQL server log for support, superuser and replication sessions, shipped off-host to a logically separate system (ASVS 16.4.3) as the check on (i), because a superuser can edit (i) and a chain does not detect deletion of its newest row (F718); the latest chain hash is anchored off-host. Retention: open (P7-OQ4).

**6. Writes only through support verbs (Option H).** Each write is a named `SECURITY DEFINER` function (for example "reset enrolment code", "resend lease", "mark review item") owned by a NOLOGIN, non-bypass role that does not own the tables and whose own policies are gated by a live grant whose scope names that verb (F716). Each verb has `SET search_path = <schema>, pg_temp`, `EXECUTE` revoked from `PUBLIC` and granted only to `support_rt` in the same migration (F710, F716), its own test, and its own audit record. `support_rt` has no `INSERT`, `UPDATE` or `DELETE` on tenant tables.

**7. Owner unreachable: control plane only, no break-glass.** Without a live owner grant Kodelix never reads tenant data. In an emergency the operator acts only on **control-plane tables that hold no tenant data** (tenants, seats, plans, lease state, restore watermark) through roles whose policies match all rows (`USING (true)`, Option D) — allowed only on those tables and only with a catalogue test that lists every such policy — and on infrastructure (restart, suspend, restore service). Reopening a consent-free path needs the founder and counsel (P7-OQ2, P7-OQ3).

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
SupportGrant (tenant-scoped table; owner inserts, owner updates revoked_at only)
  id, tenant_id, branch_ids: List<BranchId>   // explicit, never "all"
  scope: read | verb:<name>
  operator_id, reason
  requested_at, approved_by (owner user id), approved_at
  expires_at  // approved_at + default 24 h; <= approved_at + 7 d (values as data, typed defaults)
  revoked_at?

Scope (ADR-0002) gains:  kind = Support { grantId, operatorId }
  // the helper derives tenant and branch list from the live grant; errors: NoLiveGrant, ScopeAlreadySet, InvalidScope

Support verbs: SECURITY DEFINER functions support.<verb>(...)
  // owned by a NOLOGIN non-bypass role; EXECUTE only for support_rt; each appends its audit record

Audit record (IDs only): grant_id, operator_id, tenant_id, branch_ids, scope, action, outcome, row_count, at, prev_hash, hash
```

No HTTP contract is fixed here; the console's API goes to `contracts/` with the support-tooling epic.

### Implementation Guidelines

- **Must (adapters, data):** create `support_rt` NOSUPERUSER, NOBYPASSRLS, owning nothing, with `SELECT` only on tenant tables; generate its grant-gated policy for every tenant table in the same migration that creates the table.
- **Must (adapters, data):** test grant liveness with `clock_timestamp()` in every support policy; never `now()` or `current_timestamp`.
- **Must (app):** open every support access through the ADR-0002 helper with the `support` scope kind; the helper commits the "access opened" record in its own transaction before the read.
- **Must (app):** take tenant, branch list and operator from the live grant and the authenticated operator session only (FP-SCOPE-FROM-REQUEST).
- **Must (adapters, data):** write support verbs as `SECURITY DEFINER` functions owned by a NOLOGIN non-bypass, non-owner role, with a pinned `search_path` ending in `pg_temp`, `EXECUTE` revoked from `PUBLIC` in the creating migration, one test and one audit record each.
- **Must (app, config):** grant default (24 h) and ceiling (7 days) come from configuration with typed defaults, not literals.
- **Must (CI):** extend the ADR-0001 catalogue checks: no `USING (true)` policy on a tenant table; every `USING (true)` policy listed and on an allow-listed control-plane table; no `PUBLIC` `EXECUTE` on a `SECURITY DEFINER` function; no unexpected role membership (`pg_read_all_data`, `pg_write_all_data`, server-file roles, `REPLICATION` other than the backup role) (P7-OQ14).
- **Must never:** give `support_rt` or any support path `INSERT`, `UPDATE` or `DELETE` on tenant tables, `BYPASSRLS`, superuser, or membership in `pg_read_all_data` / `pg_write_all_data`.
- **Must never:** let the operator sign in as the owner or mint an owner session ("log in as"); a view-as keeps the operator's own identity.
- **Must never:** create per-grant database logins for support; human SQL sessions are for superuser DBA work only.
- **Must never:** cache grant state (a cached grant outlives the owner's revoke).
- **Must never:** read tenant data without a live owner grant, including in an emergency; use the superuser for support reads.
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

### Neutral

- The licensing operator console's control-plane actions (seats, moves, leases) are untouched by this ADR; its tenant-data views fall under it.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| A console bug or stolen operator session reads a tenant with no grant (AC1) | Medium | Low (0 rows) | Grant gate in the policy (F714); denied attempts alerted |
| Read past expiry inside a long transaction (AC6) | Low | Medium | `clock_timestamp()` (F715b); helper bounds the transaction |
| Read-then-rollback erases the trace (AC5) | Low | High | Pre-read commit (F717); off-host log |
| Superuser edits or truncates the journal (AC4) | Low | High | Off-host log; hash anchored off-host; superuser logins page |
| Second operator uses another's grant (AC2) | Low today | High | Recorded; fixed before a second operator (§ 10, P7-OQ6) |
| Attacker poses as the owner to approve a grant (AC7) | Medium | High | Owner step-up on approval (ASVS 7.5.3, P7-OQ9); notify every owner contact; grant shows scope and expiry |
| `USING (true)` policy lands on a tenant table (AC12) | Low | High | Catalogue test; allow-list of control-plane tables |
| Definer verb executable by `PUBLIC` or with an open `search_path` (AC9) | Low | High | Migration rule; catalogue test |
| Backup or replication credential stolen (AC8) | Low | High | Encrypted medium; address-limited record; alert on unexpected replication connections |
| Counsel rules a dashboard grant is not a "written instruction" (P7-OQ3) | Unknown | Medium | Contract text names the grant as the instruction; revisit on counsel's answer |

## Cross-Cutting Impact

| Concern | Impact |
|---------|--------|
| **Security / tenancy** | New trust boundary (support role ↔ tenant tables) and the operator console boundary (licensing TB3). ASVS 5.0.0: 8.4.1, 8.4.2, 8.3.1, 8.3.2, 8.2.2, 13.2.2, 13.3.1/13.3.2, 16.2.1, 16.3.2, 16.3.3, 16.4.2, 16.4.3, 7.3.2, 7.4.1, 7.4.5, 7.5.3, 6.3.2, 6.3.3, 2.3.5 (exception while one operator). Abuse cases AC1–AC13 to `docs/architecture/threat-models/tenant-isolation.md` (to be written) |
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
- [ ] A grant request longer than the 7-day ceiling is refused; the default is 24 hours.
- [ ] Performance: support policy cost measured on a realistic table (S72); checked against `perf-budgets.md` once it exists, not checked until then.

## Spec Requirements Addressed

Foundational — no spec requirement. Enables: the support-tooling epic (operator console read views and verbs), the guided-install diagnostic bundle, the owner's "who from Kodelix accessed my data" view, and the tenant-data views of the licensing operator console.

## Related

- Depends on ADR-0001 (no bypass role; "the next ADR to write"), ADR-0002 (scope helper), ADR-0003 (branch scope; `app.branch_all` only for a verified owner).
- Research: `docs/research/tenant-isolation.md` part 7 (F701–F726; evidence `docs/research/evidence/tenant-isolation/part-7/`; S70 partly a wrong test, labelled; S71 corrected), § 5 part 7 (decision and founder values), § 9 part 7 (P7-OQ1–P7-OQ14).
- Licensing: `docs/architecture/threat-models/licensing.md` TB3 and M15 (operator console identity, WebAuthn, step-up — relied on, not decided here); `docs/architecture/licence-model.md` § 12 (Draft).
- Privacy: `docs/architecture/privacy/pdpl-counsel-brief-2026-10.md` (Q1 roles; Q2 answered by counsel; Q6.9 remote support).
- Threat model: `docs/architecture/threat-models/tenant-isolation.md` (to be written; add AC1–AC13).
- Runbooks (none exist yet): operator access and revoke; superuser custody and drill; backup credential rotation; restore drill.
