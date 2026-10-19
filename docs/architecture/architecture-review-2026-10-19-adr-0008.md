# Architecture Review — ADR-0008 roles, permissions and activity trail (independent, single ADR)

Date: 2026-10-19
Mode: `/architecture-review` scoped to one ADR (ADR-0008, Status Proposed, committed 3244204), at the request of the orchestrating session. The reviewer did not author ADR-0008.
Stack: `postgres:18.6`; Ktor 3.6.0 / Exposed 1.5.1 (ADR-0006, `pins.yaml`). `project.yaml` `stack.*` is still unset.
Distribution: hosted only (stated by ADR-0001..0008); `project.yaml` `distribution.model` unset.
Specs reviewed: 0 (`design/specs/` absent). ADRs read: 8.
- In full: ADR-0008, ADR-0007, ADR-0003.
- By the sections ADR-0008 touches: ADR-0001 §§ 1a–1c and Decision 4; ADR-0004 § 5; ADR-0005 Decisions 1–7.
- By reference only: ADR-0002 and ADR-0006.

Also read:
- `docs/research/staff-auth-and-roles.md`: §§ 3.3, 3.5, 4.5, 4.6, 5.0, 5.4 (part 3 § 5.1–5.7), 5.5, 6–9 and the Appendix (part 4 §§ 4–9).
- The registry diff of 3244204.
- `docs/stack-reference/postgres/{VERSION,breaking-changes,deprecated-apis,best-practices}.md`, `docs/stack-reference/ktor/VERSION.md` and `pins.yaml`.
- `.claude/docs/security-baseline.md` and `.claude/docs/coding-standards.md`.
- The ASVS 5.0.0 chapter copies in `docs/research/evidence/tenant-isolation/part-6/src/`. Every ASVS ID below was looked up there.

Reviewed-Content-Hash: docs/architecture/adr-0001-tenancy-model.md 4ad2f776be6d98ed0377e9a0489db464ad55bc90
Reviewed-Content-Hash: docs/architecture/adr-0002-tenant-context.md 9429898b3f505b813cbc40f6623a23c3b494694e
Reviewed-Content-Hash: docs/architecture/adr-0003-branch-scope-and-session.md f75acdb3f996ba66bf5ab887e06b4bf8abec485d
Reviewed-Content-Hash: docs/architecture/adr-0004-operator-access.md cbc90299327aaa25a2937d49a53bb00918beb264
Reviewed-Content-Hash: docs/architecture/adr-0005-retention-deletion-export.md b874ec600bff2fbbb82ebe21faabca41db44b682
Reviewed-Content-Hash: docs/architecture/adr-0006-backend-track.md 1527e3d9301716656c5a71c8933b462bae4587f8
Reviewed-Content-Hash: docs/architecture/adr-0007-staff-auth.md 18851bf4ca59722f18699574820aecdfb47689c2
Reviewed-Content-Hash: docs/architecture/adr-0008-roles-permissions.md 9e04c1d11273a6fb5137c9273b9ddf7bc5249893
Reviewed-Content-Hash: docs/research/staff-auth-and-roles.md ee165aba5ca270fdaa3c7f4b1f78a7e091961fee
Reviewed-Content-Hash: docs/registry/architecture.yaml 764ac444e2824b6da741bedc856c832023f76972

Nothing else was written. No ADR, registry, research note, traceability file or checkpoint was edited, and nothing was staged or committed.

---

## Verdict: FAIL (text fixes only)

Two findings block acceptance:
- **B1:** § 10.3's upload rule promises a control it does not deliver. Three of the four accepted fact kinds, and the parameter rehash, are minted by the device itself. So in practice an upload "carrying only a valid device credential" is accepted, and part 4's abuse case 4 stays open.
- **B2:** the last-owner trigger and the owner-role trigger refuse the deletions that ADR-0005's closure purge makes. ADR-0005 is Accepted, so this is a cross-ADR conflict.

Every finding has a text fix, and none needs new research. B1, M5, M7, M9 and M10 need a founder choice; each one says so.

**What is sound:**
- §§ 1–4 and 6 follow research § 5.4 (part 3 § 5.1–5.7) key by key. Each place they depart from it is stated as a founder change of 2026-10-19:
  - `report.xz` is split into `report.x` / `report.z`, with `approve.report_z`;
  - `day.end` is approvable, but its refusal while anything is open is not;
  - `staff.manage` is out of the manager template;
  - the Tier-2 keys are reserved;
  - the subset rule is active rather than dormant, and is applied to the ADR-0007 §§ 7–8 actions.
- Research § 5.0 E and F are carried: P1 + O1 + S1; S2 off by default; the owner role is immutable; at least one owner remains, under the per-tenant transaction lock; B1 with the control-journal copy.
- § 10 carries all seven of part 4's conditions and the founder's PIN-not-in-password addition (table below). It names the 13.3.1/13.3.3 and aggregate-lockout deviations with a name and a date.
- Flag-never-reject holds throughout: § 4.5, the Implementation Guidelines and FP-TRAIL-WRITE-OUTSIDE-FUNCTIONS.
- No number is invented. Limits stay unset until install, retention periods are configuration rows, and the ceilings are ADR-0007 § 10's.
- The ADR dependency graph is acyclic (`adr-dep-graph.sh`: 8 ADRs, no `CYCLE`, no `NO_DEPS_SECTION`), and ADR-0001..0007 are all Accepted.
- Every ASVS ID cited exists in 5.0.0 with the meaning the ADR uses. The mapping gaps are in M10.

**Part 4's seven conditions and the founder addition (research Appendix § 5; § 5.5):**

| # | Condition | ADR-0008 § 10 | Result |
|---|---|---|---|
| 1 | Upload only against a single-use enrolment or reset fact | item 3 | carried; does not hold as written (B1) |
| 2 | Server never verifies a PIN | item 4 | carried |
| 3 | AEAD, tenant and person bound, key id, unique nonces, no key in DB/backup/log/repo, 13.3.1/13.3.3 named | items 5, 10 | carried; "no key in a backup, a log or the repository" not written (L3) |
| 4 | Compromise runbook: PIN reset, not key rotation | item 9 | carried |
| 5 | Feed delivery and removal; backups stated | item 6 | carried; delivery shape contradicts § 5 (M1) |
| 6 | Clamps both sides, fleet minimum (S40), rehash only when typed | items 2, 7 | carried; "clamp" of a received verifier undefined (M8); a rehash upload has no fact (B1) |
| 7 | Per-device lockout plus a person lock at contact; named deviation | item 8 | carried; threshold has no ceiling; the malicious-lockout widening is not named (M7) |
| + | Founder: PIN not equal to, or contained in, the password | item 1 | carried; a later password change is never checked (M9) |

Severity scale: **B** blocks acceptance · **H** fix before acceptance · **M** fix before the first story that depends on it · **L** wording or hygiene.

---

## Findings

### B1. Verifier upload: facts minted on the device are accepted as if the server had checked them (§ 10.3, § 10.7; Key Interfaces `PinVerifiers.accept`; Risks row F423a; IC-PIN-VERIFIER-CUSTODY)

§ 10.3 accepts an upload against three facts:
- an enrolment assertion (password path);
- a sponsor enrolment;
- a temporary-PIN reset.

It also accepts a self-change on the counter, and it says: "Any other upload is refused, including one carrying only a valid device credential." Only one of these facts is checked by the server:

| Fact | What the server can check | Stronger than the device credential? |
|---|---|---|
| Password-path enrolment assertion | password plus factor, verified by the server (`Enrolment.issueAssertion`, ADR-0007 § 7) | yes |
| Sponsored enrolment | the device says "sponsor X entered their PIN". The server only "confirms the sponsor's current status and authority" (ADR-0007 § 7); it never checks the sponsor's PIN (§ 10.4) | no |
| Temporary-PIN reset on the counter | minted on the device, possibly offline (ADR-0007 § 8) | no |
| Self-change ("first enters the current PIN") | checked by the device, against a verifier every device of the branch already holds | no |
| Parameter rehash (§ 10.7) | no fact at all, so either item 3 refuses it or it is an unstated path | — |
| Dashboard "reset required" | step-up on the server, but it only removes; the new PIN arrives through one of the rows above | — |

So anyone who controls one counter's process or store can upload a PIN they know for any person of that branch, including a manager or a co-owner, by claiming a sponsor or a self-change. That includes the venue's Windows administrator or malware on that PC; ADR-0008's Constraints say the counter "is not a security boundary".
- Under ADR-0007 that PIN stayed on the attacker's own device.
- Under § 10 the feed carries it to every counter of every branch the victim is assigned to, where it approves overrides.

This is part 4's abuse case 4 (F423a). Risks rates it mitigated by "Upload only against a single-use enrolment or reset fact", but that mitigation covers only the password path. Q-upload-auth is listed as open, yet § 10.3 states a guarantee that no answer to it can deliver for these paths.

**Suggested fix (founder choice; (a) recommended):**
- § 10.3, replace the second bullet with: "The server authenticates two facts itself: the password-path enrolment assertion, and a dashboard-issued reset followed by a password-path enrolment. A sponsored enrolment, a counter temporary-PIN reset, a self-change and a parameter rehash are minted by the device and are no stronger than its credential."
- Then one of:
  - **(a) Delivery scoped by provenance (recommended):** "A verifier accepted from a device-minted fact is delivered only to the device that minted it, until a server-authenticated fact confirms it: the person's own password-path sign-in on any counter, or the owner's confirmation in the dashboard (step-up). For a person whose roles hold a privileged key (§ 1), only a confirmed verifier is ever delivered beyond the minting device." The unverifiable paths keep ADR-0007's one-device behaviour, and every person gets enrol-once after one confirmation.
  - **(b) Fleet-wide, with detection, accepted by name:** "Every accepted upload writes an activity-trail entry and a control-journal entry naming the person, the device and the fact kind, and sends an owner notice (ADR-0007 § 3 notice job). Uploads are rate-limited per device (configuration). A device-minted upload for a person holding a privileged key is flagged for owner review. A forged upload from a compromised counter is a residual accepted by Kamel Mohamed, founder, <date>; review at <trigger>."
- § 10.7, add: "A rehash on a parameter upgrade is uploaded as a self-change and follows the rule above."
- Key Interfaces: `PinVerifiers.accept(personId, phc, fact: {kind ∈ password_assertion | dashboard_reset | sponsor | counter_reset | self_change, factId}, baseVersion)`.
- Risks row F423a: give the mitigation of the chosen option.
- Validation, add: "A sponsor or self-change upload minted by device D for a manager is not delivered to any other device until it is confirmed" (a) / "is flagged and noticed to the owner" (b).
- Registry: IC-PIN-VERIFIER-CUSTODY and FP-PIN-VERIFIER-OFF-DEVICE-R2 ("a verifier upload accepted without a single-use enrolment or reset fact") take the same wording.

### B2. The last-owner and owner-role triggers refuse ADR-0005's closure purge (§ 2, § 3.5; ADR-0005 Decision 1; ADR-0001 § 1c `Closure.purgeLogins`)

ADR-0005 (Accepted) deletes every staff personal-data row at `purge_personal`, and every remaining PL row at `purged`. ADR-0001 § 1c says `Closure.purgeLogins` deletes "every login of the tenant, the owner's included".

ADR-0008 has no exception for any of this:
- § 3.5 refuses any delete or disable that leaves zero active owners.
- § 2's `BEFORE UPDATE OR DELETE` trigger refuses deleting the owner role.

Run as written, `purge_personal` fails on the last owner. ADR-0005's step is "idempotent and resumable", but it can never complete, so the closure state machine stops. The same happens to the `roles` rows if `purged` deletes the remaining TD tables.

**Suggested fix:**
- § 3.5, add: "The guard and the owner-role trigger let a delete through only when the current role is `job_rt` **and** the context tenant's CP `tenant_status` is `purge_personal` or later (ADR-0005 Decision 1). Every other path is refused, `job_rt` on an active tenant included."
- § 2, owner-role bullet: "…refuses any change except the label, and except the closure purge (§ 3.5)."
- Validation, add: "`purge_personal` completes on a tenant with one owner; the same delete as `job_rt` on an active tenant is refused."
- Registry TR-OWNER-ROLE: add the exception.

### H1. "At least one active owner" does not cover every path (§ 3.5, § 2; ADR-0001 § 1c; TR-OWNER-ROLE)

1. **Disabling a login is not a staff-status change.** A dashboard login is disabled through `Logins.disable` (ADR-0001 § 1c, *inside, owner*). That writes the PL table `login_identities`, not the TD staff status the trigger watches. Two owners can disable each other's logins, and the tenant is left with no usable owner. There is no break-glass (ADR-0004; ADR-0007 § 5). `Erasure.erasePersonLogin` is the same.
2. **"Active owner" is not defined:** staff status active? Login enabled? Not person-locked?
3. **"Exactly one owner role per tenant" is stated, but nothing enforces it.** A `BEFORE UPDATE OR DELETE` trigger does not stop an `INSERT … is_owner = true` from the owner's `app_rt` session, and F421 lets the owner write `roles`.
4. **The lock key collides.** ADR-0004 § 5 already takes a per-tenant transaction advisory lock for its journal append, and the activity trail's per-tenant server chain needs one too (§ 6; M6). One-argument keys "on the tenant" collide across these purposes.
5. **PostgreSQL 18 breaking change** (`stack-reference/postgres/breaking-changes.md` line 14): AFTER triggers, deferred constraint triggers included, run as the role that was active when the event was queued.
   - So the trigger counts as `app_rt` or `job_rt`, under RLS, with whatever tenant context is set at commit.
   - S31 ran on its own seed, not under those roles.

**Suggested fix (§ 3.5):**
- "An **active owner** holds the owner role, has staff status active and has an enabled dashboard login."
- "The guard runs on every path that can end one:
  - `staff_roles` delete or update, FK cascades included;
  - staff status update or delete;
  - the § 1c functions `Logins.disable` and `Erasure.erasePersonLogin`, which take the same lock and refuse the last active owner. This ADR amends their ADR-0001 § 1c rows."
- "The lock is `pg_advisory_xact_lock(<last-owner class id>, <tenant key>)`, the two-key form. Its class id is registered beside ADR-0004's journal lock and the trail's append lock. A transaction that takes more than one lock takes them in this order: journal, trail, last-owner."
- "The trigger function runs as the queuing role (PostgreSQL 18) and counts the tenant's staff rows under the tenant context. It is tested as `app_rt` and as `job_rt`, with FORCE RLS."
- § 2: "Exactly one: a partial unique index on `roles (tenant_id) WHERE is_owner`; `app_rt` has no INSERT or UPDATE privilege on `is_owner`."
- Verification Required: add the PG 18 AFTER-trigger role rule.
- Validation, add: "Two owners each disabling the other's login leaves one; erasing the last owner is refused (closure instead); inserting a second `is_owner` role fails."

### H2. The strict-subset rule misses `staff.manage`, so a custom role can act on owners (§ 1, § 3.3, § 8)

§ 3.3 applies the strict-subset rule only to sponsoring, PIN reset and local suspend.

`staff.manage` can be put in a custom role ("the owner may add them to a custom role", § 2). It allows creating, disabling and enabling staff, and per § 8 also "issuing a temporary password and requiring a PIN reset". So a custom-role holder can:
- disable a co-owner who is not the last owner (H1 protects only the last one);
- re-enable a person the owner disabled;
- issue a temporary password to a manager (ADR-0007 § 5).

§ 1 and § 8 also disagree on which key covers "require a PIN reset": § 1 says `staff.reset_pin`, § 8 says `staff.manage`.

**Suggested fix:**
- § 3.3, replace the first sentence with:
  - "Where a non-owner acts on another person, the target's permission set (keys and limits) must be a strict subset of the actor's, and the target must be assigned to a branch the actor holds. This covers:
    - `staff.manage`: disable, enable, temporary password;
    - `staff.reset_pin`: temporary PIN, require PIN reset;
    - `staff.enrol_device`;
    - `staff.suspend_local`."
  - "An owner is never the target of a non-owner."
  - "The rule is checked in the Authorizer. `Logins.issueTemporary` and `Logins.disable` also check it in their § 1c function: the target is not an owner unless `app.branch_all = 'on'`."
- § 8: "requiring a PIN reset `staff.reset_pin`; issuing a temporary password `staff.manage`".
- Validation, add: "A custom role holding `staff.manage` cannot disable an owner, or a person whose permissions are not a strict subset of its own."

### H3. The ADR-0007 amendment list leaves contradicting text in an Accepted ADR (§ 10, "ADR-0007 text this amends")

The list names:
- § 7 "Verifier";
- the Must (device) rule;
- the § 8 sentence;
- Alternative 3;
- one Consequences line.

These other ADR-0007 passages also contradict enrol-once and are not listed:
- **Summary:** "a per-device enrolment … to an alphanumeric PIN whose Argon2id verifier never leaves the device's encrypted store".
- **§ 1 realm table, Counter row:** "anyone enrolled on that device"; "alphanumeric PIN, device-local".
- **§ 7, first bullet:** "**Enrolment is per device**, and needs the device online".
- **§ 7, Manager override:** the approver "must be enrolled on that device".
- **Key Interfaces:** `EnrolmentFact … // synced; never a PIN or verifier`; the diagram node "No verifier on server".
- **Consequences, Negative:** "A person enrols on each device separately; an approver can approve only where enrolled."
- **Cross-Cutting Impact:** treats "13.3.1 secrets in a secret store: the encrypted secret file now, KMS later" as met. § 10.10 now names 13.3.1 (L3) as a deviation for the pepper too.
- **Validation:** "no PIN or verifier appears in any synced fact or log". The upload is now a synced fact.

ADR-0008 line 268 also keeps "ADR-0007's per-device enrolment fact", which reads as per-device enrolment.

**Suggested fix:** extend the list with each item above. Replace line 268 with: "ADR-0007's enrolment fact stays: one per person per enrolment, naming the device it was made on. So do its sponsored path, PIN floors, temporary PINs and lease-clock rules. A temporary PIN never leaves the device that issued it; only the lasting PIN's verifier is uploaded."

### M1. Verifier delivery: § 5 and § 10.6 disagree (§ 5 bullets 1–3; § 10.6; TR-AUTHORITY-SNAPSHOT)

§ 5 puts the verifiers inside "an immutable versioned snapshot in the config feed". § 10.6 says the **staff** feed delivers them. This causes three problems:
- An immutable snapshot cannot express a removal.
- A verifier change or a person lock does not increment `authority_version`, so a snapshot would carry a stale or removed verifier.
- `authority_snapshots.payload_hash` covers a payload without verifiers, so it is not the hash of what was delivered.

In addition, `authority_version` is per tenant while snapshots are per branch, and the ADR does not say which snapshot judges a fact.

**Suggested fix (§ 5):**
- "The authority snapshot (config feed) carries staff ids, status, role ids, permissions, limits and person locks, never verifiers."
- "`authority_version` also increments on a person lock or unlock."
- "Verifiers travel in the staff feed, keyed by `(person, verifier_version)`, with removals as tombstones (§ 10.6). Neither feed's server history stores a verifier."
- "A fact is judged against the snapshot of its branch with the greatest version ≤ its `authority_version` that the server delivered to that device. A version never delivered to that device is flagged `config_version_unknown`, never rejected."
- Add `config_version_unknown` to the flag list in § 4.5, `FactAuthority.judge` and TR-AUTHORITY-SNAPSHOT.

### M2. Judging `approver_authority_changed` against "current authority" flags legitimate approvals (§ 4.5; Validation)

The server also judges each fact against current authority, so every approval by a manager who is later demoted, or who leaves, gets flagged, even when the approval came first. After each staff change the review queue fills with false flags.

**Suggested fix:** "…against authority at the version the device held, and against **authority in force at the fact's claimed time** (lease clock). `approver_authority_changed` is set only when a change the device had not received took effect before the claimed time." Validation, add: "An approval made before a later demotion is not flagged."

### M3. The exposure bound does not hold in Restricted mode (§ 4.6; Q-restricted)

§ 4.6 bounds the exposure: "a device that has not reached the server for the lease cannot start new sales".
- In Restricted mode, open sessions are still closed and paid (licence model; research F234).
- Closing them can need a void, a discount, or a Z or End Day approval, checked against a snapshot of unbounded age.
- Who may override then is Q-restricted, which is still open with the user.

**Suggested fix:** § 4.6, add: "In Restricted mode (lease ended), no override runs until Q-restricted is decided; once it is, every override there is flagged `config_version_stale`." List Q-restricted under Open as due "before the override story".

### M4. The new stores' classes, roles and functions are not amended into ADR-0001 (§ 5, § 6, § 10; Migration Plan 1; TR-ROLE-INVENTORY-R8, TR-TABLE-CLASSES-R6)

Migration Plan 1 amends only ADR-0001 § 1b's `audit_writer` row. Missing:
- **Verifier store:**
  - the class of the verifier table and of the per-tenant wrapped-key table (TD or PL);
  - whether `PinVerifiers.accept` is enforced in the database or only in the app. In the database, it would be a function that consumes the fact, as ADR-0007 did for `Logins.resetVerifier`;
  - which role writes these tables: `device_rt` for uploads, `job_rt` for rotation and rewrap.
- **Role rows:**
  - `device_rt`: verifier upload, `LockoutReport`, `ActivityTrail.acceptDeviceBatch`;
  - `job_rt`: `verifyChains`, `pruneBefore`, key rotation;
  - EXECUTE on `appendServer`: `app_rt` and `job_rt`.
- **`migrator` row:** `permission_catalogue` is a new G table written by migration. Registry R8 adds it, but the ADR text does not.
- **Owner-only tenant settings:** § 1 says the owner-only keys are checked in "server, database", but § 9 extends the database guard to four tables only. The settings are PIN floors, ceilings, the backdate window and `override_offline_max_age`. Name the guard on their table(s).
- **ADR-0005:**
  - D4: the verifier and key tables must be on the export exclusion list (they hold credentials), or the M47 coverage test fails;
  - D5: the erasure job must delete the server ciphertext, through a named function or policy.

**Suggested fix:** add an "ADR-0001 amendment" block to Migration Plan 1 that lists each row above with its class, role, grant, function and EXECUTE. Add the ADR-0005 D4/D5 lines to § 7. Supersede TR-TABLE-CLASSES-R6 and revise TR-ROLE-INVENTORY-R8 in the registry to match.

### M5. "Closing a tenant destroys its data key" does not erase the backups (§ 10.5; ADR-0005 Decision 7)

The wrapped per-tenant data key sits in "a small key table" in the database, so every backup holds it. The master key that unwraps it outlives the tenant.
- So deleting the live row erases nothing the backups hold. The ciphertext in them stays decryptable until they age out (30 days).
- ADR-0005 Decision 7 counts key destruction as erasure only for a key held outside the database.
- Verifiers are personal credentials, so they go at `purge_personal`, not at `purged`.

**Suggested fix (founder choice):** either
- "The wrapped tenant keys are kept outside the restorable database (with the control journal; storage ADR). Deleting one at `purge_personal` is then erasure of every backup copy (ADR-0005 Decision 7)."

or
- "Deleting the tenant key at `purge_personal` removes access in the live database only. Backup copies age out inside the backup window, like every other personal row."

Related lists Q-erasure-backup as open, although § 10.6 answers it. Close it with the chosen sentence.

### M6. Activity trail: closure, prune guards, append lock, readers, restore (§ 6, § 7; IC-ACTIVITY-TRAIL)

- **Closure.** The trail is TD. ADR-0005's `purge_personal` and `purged` steps do not mention it, and it carries no `personal` / `tax` / `other` marker. The reason given for 5 years is "beside the sale it changed", which holds only if the trail follows the archive. Fix: "`activity_trail` is marked `tax` (ids only) and follows the archive: kept through `archive_retained`, deleted with the archive at `purged`, and pruned by `pruneBefore` while the tenant is active."
- **Prune guards.** `pruneBefore(cutoff)` takes its cutoff from the caller. ADR-0004's support-journal prune (TR-SUPPORT-JOURNAL-PRUNE-R3) refuses two things: a cutoff later than now minus the retention period, and a period below a compiled floor. Fix: "`ActivityTrail.pruneBefore(cutoff)`, EXECUTE by `job_rt` only, refuses a cutoff later than `clock_timestamp()` minus the trail period read from the retention table, and refuses a period below a compiled floor of 5 years."
- **Append lock.** `appendServer` keeps a per-tenant chain, so it needs ADR-0004's per-tenant append lock, because two concurrent appends fork the chain. Say so, with the lock id from H1.
- **Rows with no branch.** Role, staff and config events have no branch, and ADR-0003's `branch_scope` (`branch_id = ANY(…)` is NULL) hides them from every non-owner. State it: "Tenant-level events (no branch) are readable by the owner only."
- **Restore.** A server restore loses trail rows and acknowledged chain heads newer than the backup, while the devices have already dropped those facts from their outboxes. Only authority changes are in the control journal. Name it as a storage / sync ADR dependency: "the restore replays the trail, or records the gap and resets the acknowledged heads."

### M7. Lockout aggregation is incomplete (§ 10.8; `LockoutReport`)

- **No ceiling.** The per-person threshold is "configured" without a compiled ceiling, unlike every other count in ADR-0007 § 10, and the accepted deviation rests on it. Fix: "The per-person threshold is configuration with a compiled ceiling of 10 (NIST § 3.2.10)."
- **Reset rule.** Does a successful sign-in on device A clear failures reported by device B? Fix: "A successful PIN sign-in reported at contact clears that person's sum. Failures are counted per person across devices since the last reported success."
- **Wider malicious lockout (founder):** ADR-0007 accepted a 6.1.1 deviation: an approver locked on one counter by override-dialog failures. The person lock widens it to every counter of every branch, so a co-worker can now lock a manager or the owner everywhere. § 10.10 does not name this. Fix, add to § 10.10: "6.1.1: the person lock lets failures typed on one or more counters lock an approver on every counter. Accepted by Kamel Mohamed, founder, <date>. Security event at the threshold; the runbook 'owner or manager locked out offline' is extended."
- **Owner unlock.** Nobody is above an owner to issue a counter temporary PIN. State: "An owner's person lock is cleared by a dashboard 'reset required' followed by a password-path enrolment."
- **Forged reports.** Lockout reports are minted by the device (as in B1), so a compromised counter can lock anyone, or suppress its own reports. Add this to the threat-model inputs.

### M8. A received verifier cannot be "clamped"; upload ordering is unstated (§ 10.7, § 10.3)

A verifier's cost parameters are inside its PHC string, and hashing with clamped parameters gives a different hash, so a "clamped" verifier never verifies.

**Fix:** "A device refuses to install a received verifier whose PHC parameters lie outside its floor or ceiling. It reports `feed.param.clamped`, and refuses that person's PIN sign-in until a new PIN is set. The server refuses such an upload."

Two devices can upload for the same person; for example, an offline counter reset on device B arrives after a newer password-path enrolment. `Refused(stale_version)` implies compare-and-set, but the rule is not written. Fix:
- "An upload names the `verifier_version` it replaces, and the server accepts it only if that version is current."
- "A device whose upload is refused keeps its local verifier for that person only until the next feed delivery replaces it."
- "A PIN changed offline is valid only on that device until its upload is accepted."

### M9. PIN-not-in-password is checked only once (§ 10.1)

The device compares the PIN with the password only at password-path enrolment. Two cases are never compared, and the server cannot compare them, since it never sees the PIN:
- a later dashboard password change;
- a PIN set by the sponsored path for a person who also has a dashboard login.

**Suggested fix (founder: accept, or extend the check):** "The check runs when the PIN is set on the password path. A later password change can make the password contain the PIN, and a sponsored PIN for a person with a dashboard login is not checked. This is a residual accepted by <name, date>; the dashboard password page tells the person not to reuse their PIN." Adjust the Validation line to match.

### M10. ASVS mapping and residuals (Cross-Cutting Impact; § 10.9–10.10; Risks)

- **16.4.3** (logs securely sent to a logically separate system) is listed as met. But the trail lives in the primary database; only authority changes (control journal) and the chain head (off-host anchor) leave it. Fix: "16.4.3 partial: authority changes and chain heads go off-host, the rest of the trail stays in the primary database; recorded deviation." Alternatively, the storage ADR moves a trail copy off-host.
- **16.3.2 at L3** requires logging all authorization decisions, and the auth modules are L3 (`security-baseline.md` line 10). The ADR logs denials and gated actions only. Fix (founder): "every server `Authorizer` decision on a privileged key is logged (16.3.2 L3); other allowed decisions are not, a recorded deviation". Or accept the L2 reading by name.
- **13.3.1 for the pepper** changes ADR-0007's Cross-Cutting row, which lists 13.3.1 as met (H3).
- **Residuals F421, F422 and R-7 (founder):** F421 (a stolen store holds the branch's verifiers, approvers included) and F422 (a database plus key compromise exposes every affected verifier) are "stated plainly". They are not accepted by name, date and review trigger, as the founder's rule and ADR-0007's residual require. ADR-0005 R-7 (a lost device keeps staff data, accepted 2026-10-18) now also covers every branch person's verifier. Fix, add to § 10.10: "Residuals F421 and F422, and R-7 widened to the branch's verifiers: accepted by Kamel Mohamed, founder, <date>; review at <trigger>."

### M11. § 10 has no observability (Cross-Cutting Impact, Observability row; DoD gate 4)

The row lists only roles and trail telemetry. Part 4 § 8 lists the § 10 telemetry, and none of it is in the row:
- **spans:** `staff.verifier.upload`, `staff.feed.build`, `staff.verifier.decrypt`, `staff.key.rotate` / `rewrap`;
- **metrics:** `staff_verifier_upload_rejected_total{reason}`, `staff_verifier_removed_total{cause}`, `staff_verifier_decrypt_failures_total`, `key_custody_unavailable_total`, `staff_lockout_reported_total{scope}`, `feed_param_clamped_total{side}`;
- **alerts:** rejected-upload spike; unexpected decrypt volume; key custody unavailable; rewrap behind its deadline;
- **runbooks:** verifier-key compromise, key rotation, erasure with backups, device lost.

§ 10.9 names the compromise runbook and Risks names "alert on rejected uploads", but the Observability row has neither. **Fix:** copy the list into the row, and add: "IDs, enums and counts only; no PIN, verifier, salt, key or wrapped key in any signal."

### M12. Dependencies the ADR relies on but does not list (ADR Dependencies)

Listed: sync, storage, desktop-runtime, key-custody. Also relied on:
- **Device-credential ADR:** B1 and M7 rest on what a device credential proves. The TPM anchoring of the per-device counter is also there (ADR-0007 § 7).
- **Licensing ADR:** research § 5.4 marks `device.enrol` / `device.revoke` "to be settled with licensing", and the ADR drops that caveat. Q-restricted (M3) is also there.
- **Sync ADR's retry window:** it sets the `authority_snapshots` retention (§ 5). That store needs an ADR-0005 retention row, like the two rows § 7 adds: "Delivered authority snapshots | longest lease + feed retry window | from the sync ADR; CI checks it against the lease cap".
- **Storage ADR:** the trail restore gap (M6) and the wrapped keys' home (M5).

**Fix:** add these to Depends On, each with the part it owns, and add the retention row to § 7.

### L1. Registry count

3244204 adds **17** entries: 5 tenancy rules, 6 interface contracts and 6 forbidden patterns. The registry header comment and the commit message say 11; correct the header line. TR-TABLE-CLASSES-R6 is not superseded, although new TD and G tables arrive (M4).

### L2. The owner's verifier goes everywhere

An owner has `branches = All`, so § 10.6 sends the owner's verifier to every device of the tenant. Say so; it closes research Q-verifiers explicitly.

### L3. Condition 3 wording

§ 10.5 says the master key is "outside the database", but not "never in a backup, a log or the repository" (part 4 condition 3). Add it, and cover the verifier master key and the unwrapped data keys in FP-PEPPER-IN-DATABASE, or in a new FP.

### L4. Crypto inventory naming

The inventory names "the master key, data keys and verifier key", but there is no separate verifier key. Fix: "the verifier master key and the per-tenant data keys".

### L5. No API returns a verifier

Research § 5.4 (part 3 § 5.5) says the server's field-level rules "never return verifiers". Add to § 5's field-level bullet: "No API returns a verifier or its ciphertext; only the staff feed carries it."

### L6. S2 clock

S2's `override_offline_max_age` is measured on the lease clock (ADR-0007 § 7), never the Windows clock. Say so.

### L7. Threat-model ruling

`security-baseline.md` requires a threat model before any story touching authorization, and ADR-0008 places it there. ADR-0007 recorded the founder's ruling that the missing staff-auth threat model does not block acceptance; ADR-0008 records no such ruling. Under this skill's rules, a sensitive Foundation requirement with no threat model is a FAIL criterion. Fix: record the same ruling in ADR-0008, or run `/threat-model staff-auth` first. Add B1, M5 and M7 to its inputs.

### L8. Field-level overlap

`staff.view_personal` "see phone, attendance" overlaps `attendance.view_all` "everyone's" attendance. Fix: attendance records sit under `attendance.view_all`, and phone and contact fields under `staff.view_personal`.

---

## Registry check (3244204)

- **Superseded (6):** TR-ROLE-ASSIGNMENT-GUARD, TR-RETENTION-DEFAULTS-R3, TR-ROLE-INVENTORY-R7, IC-SESSION-AUTHORIZER-R3, IC-COUNTER-ENROLMENT-R2, FP-PIN-VERIFIER-OFF-DEVICE.
  - Each points to a successor that exists.
  - Statuses are quoted (valid YAML).
  - Only `status:` lines changed (append-only).
- **Added (17):** each is marked effective only on acceptance. They match the ADR text except where these findings apply:
  - B1: IC-PIN-VERIFIER-CUSTODY, FP-PIN-VERIFIER-OFF-DEVICE-R2;
  - B2 and H1: TR-OWNER-ROLE;
  - M1: TR-AUTHORITY-SNAPSHOT;
  - M4: TR-ROLE-INVENTORY-R8;
  - M6: IC-ACTIVITY-TRAIL;
  - L1: the count.

## Traceability summary

- Requirements traced from specs: 0 (`design/specs/` absent).
- ADR-0008's own requirements (Context § Requirements): 6, all 🟡 covered by a Proposed ADR. 2 of them are partial:
  - "at least one active owner": H1, B2;
  - "enrol once": B1.

## Threat-model coverage

- `staff-auth`: **absent** (auth, authorization, crypto, PII).
- Inputs: the ADR lists them under Related. Add B1 (device-minted uploads), M5 and M7 (fleet-wide malicious lockout; forged or suppressed reports).
- `tenant-isolation.md` and `licensing.md` exist; ADR-0008 adds no row to either.

## Cross-ADR conflicts

- 🔴 ADR-0008 § 2 / § 3.5 vs ADR-0005 Decision 1 and ADR-0001 § 1c `Closure.purgeLogins` (B2).
- 🟡 ADR-0008 § 10 vs ADR-0007 text the amendment does not list (H3).
- 🟡 ADR-0008 § 6 `pruneBefore` vs ADR-0004 § 5's prune guards (M6).
- 🟡 ADR-0008 § 10.5 vs ADR-0005 Decision 7 key destruction (M5).
- 🟡 ADR-0008 § 3.5 vs ADR-0001 § 1c `Logins.disable` (H1).

## ADR dependency order

ADR-0001 → 0002 → 0003 → 0004 → 0005 → 0006 → 0007 → 0008 (`adr-dep-graph.sh`: 8 ADRs, no cycle).
- Not yet written: sync, storage / server-sync-state, desktop-runtime, key-custody (listed).
- Not yet written and not listed: device-credential, licensing (M12).

## Spec revision flags

None (no specs exist).

## Stack and licence issues

- **PostgreSQL 18.6:** no deprecated API used. The PG 18 change to the role an AFTER trigger runs as bears on the deferred last-owner trigger (H1.5). Constraint triggers and `pg_advisory_xact_lock` are not in the stack reference; the ADR says so itself (F325) and puts the manual pages under Verification Required.
- **Ktor 3.6.0 / Exposed 1.5.1:** no API named in this ADR.
- **Licence:** hosted only; no customer bundle; no new component. The AEAD library is not chosen yet (Q-crypto-ref; S41 pending).

## Architecture document coverage

**NOT ASSESSED** — `docs/architecture/architecture.md` does not exist.

## Checks not run

- Stack-lead consultation: no stack layer configured (lean mode).
- Spec traceability: no specs.
- Phase 6: no `architecture.md`.
- PostgreSQL 18 manual pages for constraint triggers and advisory locks: not fetched. They are the ADR's own Verification Required item.
- No spike was run, and S31 was not re-run.

## Blocking issues (must resolve before PASS)

1. B1: state which upload facts the server authenticates, and the rule for device-minted ones (founder choice).
2. B2: the closure-purge exception in the last-owner and owner-role triggers.

## Required ADRs

No new ADR is required by this review. M12 adds the device-credential and licensing ADRs to ADR-0008's Depends On; both are already planned (ADR-0007 Depends On).

---

## Re-check 2026-10-19 (same reviewer)

Scope: the revised ADR-0008 (still Proposed, uncommitted), diffed against `production/session-state/drafts/adr-0008-before-review-fixes.md` (identical to HEAD 3244204). Also the uncommitted registry diff (10 superseded, 12 added), checked by parsing the file as YAML. Includes the founder's new § 10 item 11. Nothing else was written, staged or committed.

Reviewed-Content-Hash: docs/architecture/adr-0008-roles-permissions.md 4eb810589c15a6318d6dc2732370d68fe36196cb
Reviewed-Content-Hash: docs/registry/architecture.yaml 3f0ea31a13d9200ae29a06addf07c7298790dcee

### Re-check verdict: FAIL (text fixes only), one sentence from CONCERNS

- 23 of the 25 findings are resolved.
- **B1 is resolved in shape, but its confirmation step reopens it for the people it protects (R1).** One sentence fixes it.
- H1 and H2 are resolved for the table paths, but the new § 1c checks cannot be built under ADR-0001's class rules (R2).
- Item 11 is consistent with § 1 and with § 10 items 3–4. It needs two precisions (R3, R5) and adds three low items.

Once R1 is fixed, the rest are CONCERNS-level.

### Status of each finding

| # | Status | Where |
|---|---|---|
| B1 | **Shape resolved; R1 reopens it** | § 10.3: kinds split server-checked / device-minted; unconfirmed verifiers stay on the minting device; privileged people never get one beyond it; rehash = `self_change`; Validation and Risks updated |
| B2 | Resolved | § 3.5 closure exception (`job_rt` and `purge_personal` or later); § 2; Validation |
| H1 | Resolved for the table paths; R2 for the § 1c paths | § 3.5: "active owner" defined; two-key lock and order; PG 18 queuing role; partial unique index; `is_owner` privilege |
| H2 | Resolved; R2 for the § 1c check | § 3.3 covers `staff.manage`, `reset_pin`, `enrol_device`, `suspend_local`; owner never a target; § 1 and § 8 agree |
| H3 | Resolved (item 11 adds two more passages, L-R9) | § 10, amended-text list (13 passages); line 369 replaced |
| M1 | Resolved | § 5: snapshot never carries verifiers; person lock bumps the version; staff feed with tombstones; judging rule; `config_version_unknown` |
| M2 | Resolved | § 4.5: authority in force at the claimed time |
| M3 | Resolved | § 4.6: no override in Restricted mode until Q-restricted is decided |
| M4 | Resolved; grant gaps in R3 | Migration Plan 1, ADR-0001 amendment block; Must (data); § 7 D4/D5 |
| M5 | Resolved (founder) | § 10.5: key deleted at `purge_personal`; live access only; backups age out |
| M6 | Resolved (ADR-0005 D1 line in L-R8) | § 6: `tax` marker, follows the archive, prune guards, append lock, owner-only tenant events, restore gap delegated |
| M7 | Resolved | § 10.8: ceiling 10, reset rule, owner unlock, widened 6.1.1 accepted by name, forged reports |
| M8 | Resolved | § 10.7 refuse-not-clamp; § 10.3 base version and offline rule |
| M9 | Resolved (founder) | § 10.1 residual; § 10.10 |
| M10 | Resolved (founder) | § 6 16.3.2 L3; § 10.10 residuals with review trigger; Cross-Cutting |
| M11 | Resolved | Cross-Cutting Observability: § 10 and item 11 telemetry |
| M12 | Resolved (table rendering in L-R7) | Depends On; § 7 snapshot row |
| L1 | Resolved | registry correction line (17) |
| L2 | Resolved | § 10.6 |
| L3 | Resolved in the ADR; no registry FP (L-R10) | § 10.5 |
| L4 | Resolved | § 10.5 |
| L5 | Resolved | § 5, Must never |
| L6 | Resolved | § 4.6 |
| L7 | Resolved (founder) | Decision Makers; Validation |
| L8 | Resolved | § 1 |

### New findings

#### R1 (blocks). Confirming by "password-path sign-in on any counter" confirms whatever verifier is pending, including a planted one (§ 10.3 third bullet; Key Interfaces `PinVerifiers.confirm(personId, verifierVersion, by: password_signin)`; IC-COUNTER-ENROLMENT-R4; IC-PIN-VERIFIER-CUSTODY-R2)

The confirmation proves who the person is. It does not prove that the pending verifier holds their PIN:
- `confirm(…, by: password_signin)` takes no PIN.
- The sign-in may happen on a counter that does not even hold the pending verifier.

The attack:
1. A compromised counter uploads a `self_change` or `sponsor` verifier with a PIN the attacker knows, for manager M. It stays on that counter, as intended.
2. M later signs in by the password path on any counter, for example to enrol after a reset.
3. That sign-in confirms the planted verifier, and the feed carries it to every counter of M's branches.

That is exactly what B1 (a) set out to prevent for privileged people.

**Suggested fix (§ 10.3, third bullet):**
- Replace "The confirming fact is the person's own password-path sign-in on any counter, or the owner's confirmation in the dashboard (step-up)" with: "A pending verifier is confirmed only by:
  - (i) **the person setting a PIN on the password path**: a new `password_assertion` upload, which replaces the pending verifier; or
  - (ii) the owner's confirmation in the dashboard (step-up). The page shows the person, device, fact kind and time, and the owner confirms only after checking with the person.

  A password-path sign-in that sets no PIN confirms nothing."
- Key Interfaces: `PinVerifiers.confirm(personId, verifierVersion, by: owner_dashboard)`.
- Registry: IC-COUNTER-ENROLMENT-R4 ("the person's password-path sign-in on any counter") and IC-PIN-VERIFIER-CUSTODY-R2 ("password sign-in or owner dashboard") take the same wording.
- Validation, add: "A password-path sign-in that sets no PIN leaves a pending verifier unconfirmed."

#### R2 (H). The § 1c checks need tenant data that `auth_lookup` cannot read (§ 3.3, § 3.5; Migration Plan 1 § 1c; TR-OWNER-ROLE-R2, TR-STRICT-SUBSET)

`Logins.disable`, `Erasure.erasePersonLogin` and `Logins.issueTemporary` are `auth_lookup` functions on PL tables. The revision makes them do two things:
- refuse the last active owner;
- refuse an owner target unless `app.branch_all = 'on'`.

Both need to know who holds the owner role, which lives in TD `staff_roles` / `roles`. But ADR-0001 § 1a gives `auth_lookup` permissive policies on PL tables only, and § 1c's `EnrolmentCodeLookup` row says "`auth_lookup` never reads TD tables".

The TD trigger has the opposite problem. Its "active owner" needs the login's enabled state, which is PL. `app_rt` can read it only through `Logins.statusOf`, which `job_rt` (closure and erasure) cannot execute.

There is also a lock-order point. A `Logins.disable` that takes the last-owner lock immediately, followed by the use case's `appendServer`, takes the locks as last-owner then trail, against § 3.5's stated order.

**Suggested fix (cto choice; (a) recommended):**
- **(a) A narrow read for `auth_lookup`.** Amend ADR-0001 § 1a / § 1c: "`auth_lookup` may SELECT `staff_roles` and `roles` (`is_owner` only) inside the tenant context, for the owner checks of `Logins.disable`, `Logins.issueTemporary` and `Erasure.erasePersonLogin` only." `Logins.statusOf` gains EXECUTE for `job_rt`, so the TD trigger can count enabled logins on every path.
- **(b) An owner mark in PL.** `login_identities.owner_mark` is kept in step by a new § 1c function `Logins.setOwnerMark(user, on)`. It is called in the same transaction as every owner-role assignment and checked by a consistency job.

With either option, § 3.5 adds: "`Logins.disable` and `Erasure.erasePersonLogin` take the last-owner lock after any trail append in the same transaction."

#### R3 (M). Who may write upload facts, and of which kind (§ 10.3; Must (data); Migration Plan 1 § 1b)

"Single use holds in the database" only if a server-checked kind cannot be inserted without its proof. The ADR does not say who writes `pin_upload_facts`, or of which kind.
- `password_assertion` comes from `Enrolment.consumeAssertion`, a PL function. It cannot write TD, so the sync endpoint (`device_rt`) would insert that row itself, and the database cannot check it.
- The `app_rt` grants are not listed either: `PinActivation.issue` (INSERT `pin_activation_codes`), the `dashboard_reset` fact, and `PinVerifiers.confirm` (UPDATE `confirmed` while "`app_rt` has no SELECT on `pin_verifiers`").

**Suggested fix (Must (data)):**
- "A `pin_upload_facts` row of kind `activation_code` is written only by `PinActivation.redeem`, in the transaction that consumes the code."
- "A `dashboard_reset` row is written only by `app_rt` with step-up."
- "A `password_assertion` row is written by the sync endpoint in the same transaction as `Enrolment.consumeAssertion` returns. This is an application check, stated as such."
- "`device_rt` may insert only the device-minted kinds."
- "The upload trigger takes `confirmed` from the consumed fact's kind, never from the request."
- "`app_rt` gets INSERT on `pin_activation_codes` and `pin_upload_facts` (kind `dashboard_reset`), and UPDATE of `pin_verifiers.confirmed` through `PinVerifiers.confirm` only."

#### R4 (M). What other devices hold while a new verifier is pending (§ 10.3, § 10.6)

When a device-minted verifier N+1 is accepted but unconfirmed, the ADR does not say whether other devices keep the confirmed verifier N or receive a tombstone.
- If they keep N, the old PIN still works everywhere else. That defeats a self-change made because the PIN leaked.
- If they get a tombstone, a compromised counter can wipe a manager's PIN fleet-wide with one forged `self_change` (a lockout-type DoS).

**Suggested fix (founder choice; keeping N recommended):** "Other devices keep the last confirmed verifier until the new one is confirmed. The counter tells the person: 'new PIN valid on this counter until confirmed'. A person who wants the old PIN gone everywhere asks the owner for a dashboard 'reset required'."

#### R5 (M). Item 11 has no permission key (§ 10 item 11; § 1)

"Issued by the owner from the dashboard" names no catalogue key, so `Authorizer.require` has nothing to check (deny by default), and the owner-only list in § 1 does not include it. Also unstated: whether a code may be issued for a person who already has a PIN, which would make it a remote PIN reset.

**Suggested fix:**
- § 1, owner-only row: add "`staff.activation_code` (issue a dashboard temporary PIN, § 10 item 11)".
- Item 11: "For a person who already has a verifier, a redeemed code replaces it fleet-wide (an owner-started reset; ASVS 6.4.6 holds, since the person sets the PIN)." Or: "only for a person with no verifier yet". The founder chooses.

### Item 11 against § 1, § 10 items 3–4, ADR-0007 and the registry

- **§ 1:** refers to the privileged set by reference (`permission_catalogue.privileged`) and checks it at issue and at use. Consistent; `approve.*` is in the set, so "never an approver" follows.
- **§ 10 item 3:** `activation_code` is a server-checked kind and its verifier is confirmed. Consistent. The verifier is set by the person; the code never becomes the lasting PIN (ASVS 6.4.1 second sentence, 6.4.6).
- **§ 10 item 4 and FP-SERVER-PIN-VERIFY-R2:** the exception is stated in both places, and is limited to a one-time code that is never a lasting PIN. Consistent with research § 5.5's condition 2 as amended by the founder.
- **ASVS 6.4.1** ("securely randomly generated, follow the existing password policy, and expire after a short period of time or after they are initially used"): CSPRNG and single use are met; the floor of 8 meets the PIN policy; "short period" is the founder's 24 h default, as the ADR states. **6.5.2:** under 112 bits, so salted Argon2id is correct.
- **ADR-0007:** the step-up is ADR-0007 § 4's, and the notice is ADR-0007 § 3's job outbox. But ADR-0007 § 7 says "Two paths" and § 4's dashboard step-up list does not include issuing a code (L-R9).
- **Registry:** IC-PIN-ACTIVATION matches the ADR text, except for the missing key (R5).

**No new hole beyond these:**
- online-only;
- the per-code attempt ceiling;
- the voiding rules;
- the wrong-branch refusal;
- the role re-check at use;
- the owner notice.

Together these cover the interception, guessing, stolen-session and role-change cases the ADR lists. One more threat-model input is in L-R11.

### Low

- **L-R6 (item 11):** the code lifetime has a default (24 h) but no compiled ceiling, unlike every other ADR-0007 § 10 number. Fix: "lifetime is configuration with a compiled ceiling of <founder value>".
- **L-R7 (§ 7):** the `authority_snapshots` row sits after a blank line, so it renders as a separate table with no header. Fix: move it into the table above.
- **L-R8 (§ 6 / § 7):** "deleted with the archive at `purged`" changes ADR-0005 Decision 1's `purged` list, but § 7 amends only the retention rows, D4 and D5. Fix: add "D1: `purged` also removes `activity_trail`" to § 7.
- **L-R9 (§ 10, ADR-0007 text list):** add "§ 7 'Two paths' gains the activation path (item 11)" and "§ 4 dashboard step-up actions gain 'issue an activation code'".
- **L-R10 (registry):** the master-key rule (§ 10.5) is in IC-PIN-VERIFIER-CUSTODY-R2 but not in any forbidden pattern; FP-PEPPER-IN-DATABASE still names only the pepper and the TOTP key. Fix: extend it to "the verifier master key or an unwrapped tenant data key".
- **L-R11 (threat-model input):** the counter on which a code is redeemed can substitute its own verifier for the person's. The result is confirmed and fleet-wide, but only for a non-privileged person, and it shows when the person's PIN fails on another counter. Add it to item 11's threat-model inputs.

### Registry (uncommitted diff)

- **Superseded (10)**, each pointing to a successor that exists:
  - TR-TABLE-CLASSES-R6 (ADR-0007, Accepted; the header says it returns to active if ADR-0008 is rejected);
  - TR-ROLE-INVENTORY-R8, TR-OWNER-ROLE, TR-AUTHORITY-SNAPSHOT;
  - IC-OVERRIDE, IC-ACTIVITY-TRAIL, IC-COUNTER-ENROLMENT-R3, IC-PIN-VERIFIER-CUSTODY;
  - FP-PIN-VERIFIER-OFF-DEVICE-R2, FP-SERVER-PIN-VERIFY.
- **Added (12)**, each with `status: active`, `adr_status: Proposed` and "effective when ADR-0008 is Accepted":
  - 10 replacements, plus TR-STRICT-SUBSET and IC-PIN-ACTIVATION.
- The file parses as YAML.
- The new entries match the revised ADR, except:
  - R1: IC-COUNTER-ENROLMENT-R4, IC-PIN-VERIFIER-CUSTODY-R2;
  - R2: TR-OWNER-ROLE-R2, TR-STRICT-SUBSET;
  - R5: IC-PIN-ACTIVATION;
  - L-R10.

### Cross-ADR and research consistency

- No new contradiction with ADR-0001–0007, other than R2 (ADR-0001 § 1a/§ 1c: `auth_lookup` and TD).
- Research §§ 5.0, 5.4 and 5.5 and the Appendix: the revision departs from them only where the founder decided (B1 (a), item 11's server check, the M5/M7/M9/M10 acceptances), and each departure is recorded with name and date.

### Blocking before acceptance

1. R1: the confirmation must replace the pending verifier through a new password-path PIN or an owner's checked confirmation, never confirm it by sign-in alone.
