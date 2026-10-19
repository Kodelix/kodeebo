# Architecture Review — ADR-0007 staff authentication (independent, single ADR)

Date: 2026-10-19
Mode: `/architecture-review` scoped to one ADR (ADR-0007, Status Proposed, uncommitted), at the request of the orchestrating session; the reviewer did not author ADR-0007.
Stack: Ktor 3.6.0 / Kotlin 2.4.21 / Exposed 1.5.1 / HikariCP 7.1.0 (ADR-0006, `pins.yaml`); `postgres:18.6`; React 19.3.0 / Vite 8.3.4. `project.yaml` `stack.*` is still unset.
Distribution: hosted only (stated by ADR-0001..0007); `project.yaml` `distribution.model` unset.
Specs reviewed: 0 (`design/specs/` absent). ADRs read: 7 (ADR-0007 in full; ADR-0001 and ADR-0003 in full; ADR-0002, ADR-0004, ADR-0005, ADR-0006 by the sections ADR-0007 touches).
Also read: `docs/research/staff-auth-and-roles.md` (§ 5.0 founder decisions in full), `docs/registry/architecture.yaml` (uncommitted ADR-0007 diff), `docs/stack-reference/{ktor,vite-react,postgres,kotlin}`, `.claude/docs/security-baseline.md`, `.claude/docs/coding-standards.md`, `docs/architecture/threat-models/{tenant-isolation,licensing}.md`, the ASVS 5.0.0 chapter copies in `docs/research/evidence/tenant-isolation/part-6/src/` (every ASVS ID below was looked up there).

Reviewed-Content-Hash: docs/architecture/adr-0001-tenancy-model.md a1b3e6ea2c6620b020c5b6dcd49a6530a11df0bd
Reviewed-Content-Hash: docs/architecture/adr-0002-tenant-context.md 9429898b3f505b813cbc40f6623a23c3b494694e
Reviewed-Content-Hash: docs/architecture/adr-0003-branch-scope-and-session.md f75acdb3f996ba66bf5ab887e06b4bf8abec485d
Reviewed-Content-Hash: docs/architecture/adr-0004-operator-access.md cbc90299327aaa25a2937d49a53bb00918beb264
Reviewed-Content-Hash: docs/architecture/adr-0005-retention-deletion-export.md b874ec600bff2fbbb82ebe21faabca41db44b682
Reviewed-Content-Hash: docs/architecture/adr-0006-backend-track.md 1527e3d9301716656c5a71c8933b462bae4587f8
Reviewed-Content-Hash: docs/architecture/adr-0007-staff-auth.md 93225bc45f574a710cd29312722262abe72d04cb
Reviewed-Content-Hash: docs/research/staff-auth-and-roles.md c3307563829ca159a2cf00d811c3d16541cec084
Reviewed-Content-Hash: docs/registry/architecture.yaml c3efcfcd00b708d21b588ef45e7e4f21dc95739a

Nothing else was written. No ADR, registry, research note, traceability file or checkpoint was edited, and nothing was staged or committed.

---

## Verdict: FAIL (text fixes only)

Two findings block acceptance:
- **B1:** the § 1c amendment to ADR-0001 is incomplete, so ADR-0007's own rules could not be built under ADR-0001's "only through § 1c" rule.
- **B2:** ADR-0007 contradicts ADR-0004 § 10 and threat-model M37.

Every finding has a text fix. None needs new research. Several need a founder decision; each one says so.

**What is sound:**
- The ADR follows research § 5.0 decision by decision:
  - 2FA is mandatory for the owner and optional for staff.
  - The console uses a device-bound passkey.
  - Recovery is by email only, and no SMS is offered.
  - Argon2id runs with a pepper as RFC 9106 secret input, with the pepper in a file now and a KMS envelope later.
  - The PIN verifier lives only in the device store, and the store key plays the pepper's role.
  - PIN floors are 6 and 8, set by the owner and never lowered.
  - Sponsored enrolment needs no email.
- The residual-risk sentence matches § 5.0 word for word: name, date and review triggers.
- The alternatives are honest, and Alternative 6 (HMAC pre-hash) is kept as the fallback.
- The cookie rules match `vite-react/best-practices.md` § 2.
- No deprecated API is used: the typed auth DSL and Ktor's cookie `Sessions` are avoided, and the two-argument `limitedParallelism` is used.
- The ADR dependency graph is acyclic (`adr-dep-graph.sh`: 7 ADRs, 21 edges, no `CYCLE`, no `NO_DEPS_SECTION`), and ADR-0001..0006 are all Accepted.
- The 13 registry entries match the ADR text, except where findings H3, M4 and L7 say otherwise.

Severity scale: **B** blocks acceptance · **H** fix before acceptance · **M** fix before the first auth story · **L** wording or hygiene.

---

## Findings

### B1. The § 1c additions are incomplete; ADR-0007's own rules have no legal pre-context path (Key Interfaces "ADR-0001 § 1c additions"; Migration Plan 1)

ADR-0001 § 1c says these functions are "the only way to read or write a PL table before a tenant context exists". Several rules in ADR-0007 need a pre-context read or write that no listed function provides:

| Rule in ADR-0007 | Why no listed function does it |
|---|---|
| § 3: "the idle timestamp is refreshed at most once per configured interval" | `SessionLookup.find` only reads; no function writes `idle_expires_at` |
| § 3: "users list and end their sessions (7.5.2)"; "a password or factor change ends every other session" (7.4.3; threat model M33) | `Sessions.endAllForUser` is *inside, owner*, so a manager or cashier who changes their own password cannot call it; no list function exists |
| § 5: "After a reset: every session ends, outstanding codes are void" | The reset runs before any context; ending sessions needs the *inside, owner* function |
| § 3: `sessions` gains `aal`, `absolute_expires_at`, `idle_expires_at` | The `Sessions.create(user, tenant, tokenHash, expiresAt)` signature is not amended |
| § 5: the code goes to "a **verified** email address"; "every contact is notified" | `LoginLookup.find` returns user, tenant, status and verifier only. Contacts are tenant data, and ADR-0002 forbids opening a tenant scope from request input (ADR-0007 Alt 5 says so itself) |
| § 5: "verified" | No table or function verifies an address, and no rule says when a changed address may be used for recovery |
| § 3: passkey sign-in "counts as both factors"; challenge "single use" | `SecondFactors.forLogin(user)` needs a user already, so a sign-in that starts from the passkey has no lookup by credential id. No pre-session store exists for registration or assertion challenges |
| § 7: password-path enrolment "signs in on that device" | The counter talks to the server as `device_rt` (ADR-0001 § 1b). `LoginLookup.find` and `SecondFactors.*` are `EXECUTE` by `app_rt` only |
| § 3: removing the last factor of an account "takes effect after a delay … with a cancel link" | No pending state, no job function applies the removal and no function redeems the cancel link |
| `Logins.resetVerifier(user, …)` "(only from a redeemed request)" | The function takes a user id, so the database cannot enforce that a redeemed request exists |
| `Closure.purgeLogins()` extension | `step_up_grants` is not deleted at `purge_personal`; it is deleted only by `purgeRemaining` at `purged` |

**Suggested fix (Key Interfaces, ADR-0001 § 1c additions):** add these rows, and repeat them in Migration Plan 1 and `IC-PRE-CONTEXT-LOOKUPS-R7`.

```text
sessions          Sessions.create(user, tenant, tokenHash, aal, absoluteExpiresAt, idleExpiresAt)   before, app_rt (replaces the ADR-0001 signature)
                  Sessions.touch(tokenHash, idleExpiresAt) (no-op inside the configured interval)  before, app_rt
                  Sessions.listOwn(tokenHash) -> [sessionId, createdAt, aal, lastSeenAt]           before, app_rt
                  Sessions.endOwn(tokenHash, sessionId) / endOthers(tokenHash)                     before, app_rt, bound to the caller's session
recovery_requests Recovery.create(identifierHit, codeHash, expiresAt) -> verifiedAddress?          before, app_rt (reads the verified address from the PL contact row, never TD)
                  Recovery.redeem(codeHash) -> resetHandle | Expired | NotFound                     before, app_rt
login_identities  Logins.resetVerifier(resetHandle, verifier, pepperKeyId)                         before, app_rt; consumes the handle, ends every session of the user, voids
                                                                                                   outstanding recovery requests and step-up grants in the same transaction
login_contacts    Contacts.startVerify(tokenHash, addressHash, codeHash) / confirm(tokenHash, codeHash)  before, app_rt (new PL table: verified recovery address per login)
webauthn_challenges Challenges.create(purpose, bindTo, challengeHash, expiresAt) / consume(...)    before, app_rt (single use; purpose = register | assert | step-up)
second_factors    SecondFactors.findByCredentialId(credentialId) -> {user, tenant, publicKey, signCount, be}  before, app_rt
                  SecondFactors.applyPendingRemovals() / cancelRemoval(cancelHandle)                inside, job (job_rt) / before, app_rt
extended          Closure.endSessions(): also step_up_grants
```

Owner notification needs one more decision. Choose one of these two options, and state the choice:
- **Option 1:** notices "to every owner contact" (recovery, factor changes, recovery-code use) are sent by a `job_rt` job in the tenant's scope. An outbox row written by the pre-context function triggers it. This is the pattern ADR-0001 Decision 4 uses for closure notices.
- **Option 2:** the PL contact table holds the owner contacts as well.

For the counter password path, choose one of these two options and state it in § 7:
- **Option 1:** add the `device_rt` rows `LoginLookup.findForEnrolment` and `SecondFactors.verifyForEnrolment`.
- **Option 2:** the counter calls the dashboard sign-in API (`app_rt`). That API returns a single-use enrolment assertion bound to the device credential, never a session.

---

### B2. § 6 claims to close ADR-0004 § 10's weak spot; ADR-0004 and threat model M37 say it is not closed (Decision § 6, last bullet; Consequences Positive bullet 4)

ADR-0007 says: "`app.operator_id` … comes from the resolved operator session, never from a request; this closes ADR-0004 § 10's weak spot." ADR-0004 § 3 already sets `app.operator_id` "from the grant and the authenticated operator session — never from the request". The weak spot in § 10 is different: the database trusts a setting that any code running as `support_rt` can write. ADR-0004 § 10's trigger demands "a per-operator login (`current_user`) or a signed claim the helper verifies", plus an amendment. `tenant-isolation.md` M37 says the same: "Per-operator database identity before a second operator". If ADR-0007 is accepted as written, a future reader could believe M37 is already met.

**Suggested fix (§ 6):** replace the bullet with:

> "`app.operator_id` for the support scope is taken from the resolved operator session, never from a request (FP-OPERATOR-ID-FROM-REQUEST). This is an application control only. The database still trusts the setting, so ADR-0004 § 10's weak spot and threat model M37 remain open. Before a second operator gets console access, operator identity moves into the database (per-operator login or a verified signed claim) by an ADR-0004 amendment."

Then delete "this closes …" and change Consequences/Positive bullet 4 to: "a dashboard defect cannot mint an operator session; operator-id spoofing between operators stays open until ADR-0004 § 10."

---

### H1. A server restore brings back revoked credentials (gap against research § 5.0 F and § 6 abuse case "a restore reviving a revoked manager")

The ADR never says what a backup or PITR restore (ADR-0005 Decision 4) does to credentials. Every PL row returns to its state at the backup point:
- ended sessions become valid again (their token hashes are back);
- a factor an owner removed after a phish comes back;
- an old password hash returns over a reset;
- a consumed recovery code becomes usable again (breaking single use, ASVS 6.5.1);
- used step-up grants and a disabled login come back too.

Research § 5.0 F decided "authority changes also written to the control journal", and § 6 lists the restore abuse case. ADR-0007 does not carry either.

**Suggested fix (new bullet in § 3, plus a Validation line):**

> "**Restore.** After any server restore, the restore runbook ends every session and deletes every step-up grant and recovery request (a privileged step), so everyone signs in again. Every credential or authority change is also written to the control journal (ADR-0005 Decision 3): password reset, factor add or remove, recovery-code use, login disable, role change, device revoke. After a restore, the changes newer than the restore point are replayed from it. A replayed password reset marks the login `must_reset`."

- Validation: "after a restore to a point before a factor removal and a recovery-code use, the removed factor is not accepted and the used code is refused."
- Add the storage / server-sync-state ADR (D5-C) to Depends On (see M9).

---

### H2. Forgotten password: the new password is set before the second factor is checked (§ 5 bullet 1)

The text: "Redeeming leads only to setting a new password, and then the enrolled second factor must still be passed." An attacker who controls the mailbox but not the factor can still:
- replace the owner's password;
- end every session ("After a reset: every session ends");
- void the outstanding codes.

That gives a repeatable lockout of the owner, who holds every destructive power. The OWASP Forgot Password Cheat Sheet also says not to rely only on email when the account has stronger factors (F119). ASVS 6.4.3 reads: "a secure process for resetting a forgotten password … that does not bypass any enabled multi-factor authentication mechanisms."

**Suggested fix (§ 5 bullet 1):**

> "Redeeming the email code opens a reset step that **first requires the enrolled second factor** (TOTP, a UV passkey, or one recovery code). Only after it passes is the new password set. An account with no second factor sets it after the email code alone (AAL1; F109)."

Add to Validation: "a redeemed email code without the second factor cannot change the password of an account that has one."

---

### H3. "Strictly lower / strictly higher role" has no meaning with custom roles (§ 7 sponsored path; § 8 PIN reset; § 4 "owner unless"; registry `IC-COUNTER-ENROLMENT`)

The founder chose custom roles: P1, a role is a set of permission keys. The three-level hierarchy (P2) was rejected (research § 4.5, § 5.0 E). Roles therefore have no order, so "strictly lower role" cannot be implemented or tested. The research carries the same wording (B2-1), so the gap is inherited. The Ordering Note also says these checks read "owner only" until the ADR-0003 amendment, while § 7 says "a manager or owner".

**Suggested fix (§ 7 sponsored path and § 8 PIN reset):**

> "The actor holds the permission the ADR-0003 amendment names (`staff.enrol_device`, `staff.reset_pin`), is assigned to that branch, and the target's permission set is a **strict subset** of the actor's (the owner role is above every role). Until the ADR-0003 amendment is Accepted, only the owner may sponsor, reset a PIN or approve an override."

Apply the same wording to `IC-COUNTER-ENROLMENT`.

---

### H4. Losing a factor: the co-owner path contradicts § 3, and staff who lose their only factor have no path (§ 3 last bullet; § 5 "Owner who loses every factor")

- **The contradiction:** § 3 says "Removing the **last** second factor of an owner is refused", yet § 5 offers "a co-owner" as recovery for an owner who lost every factor. Nothing lets a co-owner act on another owner's factors.
- **The gap for staff:** a manager who enrolled TOTP and lost the phone has no path. `Logins.issueTemporary` resets a password only.
- ASVS 6.4.4: "if a multi-factor authentication factor is lost, evidence of identity proofing is performed at the same level as during enrollment."

**Suggested fix (new § 5 bullet):**

> "**Lost factor, another person helps.** A co-owner (for an owner) or the owner (for staff), with step-up, may start a factor reset for that person. After the configured delay, with notices to that person's contacts and a cancel link, the person's factors are removed and they must enrol a new one at their next sign-in. This is the only exception to 'the last factor of an owner is refused'. Recording the identity check is the helper's duty (the owner vouches for staff, a co-owner for an owner). Record the 6.4.4 reading here."

This needs a founder confirmation, because it is a new credential action.

---

### H5. Missing ASVS mappings and unrecorded deviations for an L3 module (Cross-Cutting Impact, Security row; Consequences Negative)

The repository standard is ASVS L2 everywhere and L3 for the auth module (`security-baseline.md` line 10). Each row below is looked up in the local ASVS 5.0.0 copy.

| ID (level) | Requirement, in short | Gap in ADR-0007 |
|---|---|---|
| **6.3.3 (L2)** | MFA, or a combination of single-factor mechanisms, to access the application | Staff 2FA is optional (founder), so password-only dashboard users do not meet L2. The baseline also says "MFA … enforced for admins". Only the owner's L3 hardware clause is mentioned (Q-l3) |
| **13.3.1 (L2)** | secrets in a secrets-management solution such as a key vault | The "encrypted server secret file" phase is not mapped |
| **13.3.3 (L3)** | all cryptographic operations in an isolated security module | The pepper and the TOTP key-encryption key are unwrapped into process memory even after KMS ("KMS never computes the hash"). This is a deviation and must be recorded |
| **13.3.4 (L3)** | secrets expire and rotate per documentation | The pepper and TOTP key have no rotation interval (see M2) |
| **11.1.1 / 11.1.2 (L2)** | key-management policy and crypto inventory | Not mapped. The inventory is: pepper, TOTP key, throttle-HMAC key, reset-code HMAC key, session-token hash, WebAuthn and recovery-code hashing |
| **16.3.1 (L2)** | all authentication operations logged, successful and unsuccessful | § 9 logs refused sign-ins only. Threat model M23 and M31 require "session created" records |
| **6.3.4 / 6.1.3 (L2)** | every authentication pathway documented with its strength | Only 6.1.3 is listed. The pathways are: password, password+TOTP, passkey, recovery code, temporary password, console passkey, counter password path, sponsored PIN, PIN, override PIN |
| **6.1.2 / 6.2.11 (L2)** | documented context-specific word list | The password policy names only a "common and breached-password blocklist" |
| **7.2.4 (L1)** | new session token on authentication **including re-authentication** | Step-up is re-authentication (see M3) |
| **6.3.2 (L1)** | no default accounts | The guided install creates the owner. State that no default or shared account exists |

**Suggested fix:**
- Add these IDs to the Security row.
- Add two deviations to "Deviations recorded":
  - "6.3.3 (L2): staff dashboard accounts without a second factor, which cannot run any step-up action."
  - "13.3.3 (L3): pepper and TOTP key used in process memory after one KMS decrypt at start-up."
  - Both are founder decisions to accept by name.
- Recommended alternative to the 6.3.3 deviation (founder's choice): enforce 2FA for any account holding a staff-management, approval or export permission, which matches the baseline's "enforced for admins".
- Add to § 9: "successful sign-ins and step-ups (session created, AAL, factor kind), and partially successful sign-ins (password right, factor wrong) (6.3.5)".

---

### H6. Console step-up list misses threat-model M36 (Decision § 4, "Console:" sentence; registry `IC-STEP-UP`)

`tenant-isolation.md` M36 requires: "Console: WebAuthn, step-up on suspend, end-all and plan change; rate cap; owner notified of suspension". ADR-0007 § 4 lists only seat and licence actions plus "the licensing ADR's list". These are control-plane actions through `platform_rt` (ADR-0004 § 7) that need no owner grant.

**Suggested fix (§ 4):**

> "Console: suspend or reinstate a tenant, `Sessions.endAllForTenant`, `SupportGrants.revokeAllForTenant`, plan or limit change, start a Kodelix closure (ADR-0005), request a support grant, issue, approve, move, suspend or revoke a seat or licence, and any operator action the licensing ADR lists (M36, M15)."

Apply the same wording to `IC-STEP-UP`.

---

### M1. Recovery and reset code storage does not meet ASVS 6.5.2 and the baseline's OTP rule (§ 2 "TOTP secrets" bullet; § 3 recovery codes; § 5; Key Interfaces `consumeRecoveryCode(user, codeHash)`, `Recovery.redeem(codeHash)`)

- **Recovery codes.** They carry "at least 64 bits", which is under 112. ASVS 6.5.2 then requires "an approved password storage hashing algorithm that incorporates a 32-bit random salt". A per-code salted slow hash cannot be found by a `codeHash` the app computes, so the signature conflicts with the rule.
- **Reset secret.** It is "a code or link". If it is a short typed code, a plain hash is "trivially reversible" (`security-baseline.md`: OTPs are stored "as an HMAC with a server-side key", attempt-limited), and code entry needs a rate limit (6.6.3, 6.3.1).

**Suggested fix:**
- **§ 5:** "The reset secret is a link token of at least 128 bits from a CSPRNG (11.5.1), stored as SHA-256 (allowed at ≥ 112 bits, 6.5.2). No short typed reset code is offered. If one is added later, it is stored as an HMAC under a server key, bound to its request (6.6.2), and attempt-limited (6.6.3)."
- **§ 3:** "Recovery codes are stored as salted Argon2id PHC strings, one per code."
- **Key Interfaces:** `SecondFactors.recoveryCodesFor(user) -> [codeId, phc]` and `consumeRecoveryCode(user, codeId)` (compare-and-set). The app verifies the codes.

---

### M2. Pepper and TOTP-key rotation never completes, and the forced reset is undefined (§ 2 "Rotation"; Validation 1)

"An old pepper is kept until no row uses its key id" never ends for a user who never signs in again, so a retired pepper lives indefinitely. The forced reset "for every account whose row still carries that key id" names no mechanism. The TOTP key has "its own key id" but no re-encryption rule. ASVS 13.3.4 (L3) asks for a documented rotation.

**Suggested fix (§ 2):**
- "A retired pepper has a deadline (configuration; default set in the auth spec). At the deadline, rows still on that key id are marked `must_reset` and their verifier is cleared. That person signs in again through the forgotten-password path, or through an owner-issued temporary password if they have no email."
- "A gauge `password_rows{pepper_key_id}` shows progress."
- "The TOTP key is rotated by an *inside, job* function `SecondFactors.reencrypt(oldKeyId, newKeyId)` (compare-and-set), with no user present."
- "Rotation intervals for both keys are configuration (13.3.4)."

Validation: "on the deadline, a row on the retired key cannot sign in with its old password."

---

### M3. Step-up versus session-token rotation, freshness, and the action list (Decision § 4; § 5 "Staff without an email")

- **Token rotation.** ASVS 7.2.4 requires a new token "on user authentication, including re-authentication". A step-up is a re-authentication, but the grant is bound to the session token hash and nothing says the token rotates.
- **Freshness.** "Fresh" is not defined. A passkey step-up challenge that does not encode the action and target can be replayed into another action inside the grant window.
- **Action list.** § 5 requires step-up for issuing a temporary password, but § 4 does not list it. Disabling or re-enabling a login, "require a PIN reset" from the dashboard, and the H4 factor reset are not listed either.
- **Recovery codes.** The text does not say whether a recovery code counts as a step-up factor.

**Suggested fix (§ 4):**

> "A step-up rotates the session token (7.2.4); the grant is bound to the new token hash. Fresh = the TOTP step or the WebAuthn challenge was created after the step-up request, and the WebAuthn challenge carries the action and target. A recovery code never satisfies step-up."

Add to the action list: "issue a temporary password; disable or re-enable a login; require a PIN reset; start another person's factor reset (H4)."

---

### M4. Counter expiries use the raw monotonic clock, which restarts at boot (§ 7 sponsored path "expires … on the monotonic clock"; § 7 Switching "Idle lock on the monotonic clock"; § 8 PIN reset "short life on the monotonic clock"; registry `IC-COUNTER-ENROLMENT`)

F217: QPC "restarts at boot". A temporary PIN measured on it never expires if the PC is rebooted inside its lifetime. Lockout already uses the lease clock (monotonic plus high-water mark).

**Suggested fix:** replace "on the monotonic clock" with "on the lease clock (monotonic plus the persisted high-water mark, F217)" in all three places and in `IC-COUNTER-ENROLMENT`. Validation: "a temporary PIN issued, then the PC rebooted, expires on time."

---

### M5. Counter lockout allows malicious lockout of an approver; the 6.1.1 trade-off is unstated (§ 7 Lockout; § 7 Manager override)

A cashier can enter ten wrong PINs for the manager in the override dialog. That locks the manager on that device. Offline, the lock lifts only through someone holding a strict superset of the manager's permissions (H3), or through online re-enrolment. The owner, the top role, stays locked until the device is online.

ASVS 6.1.1 asks that the documentation show how controls "prevent malicious account lockout". The ADR does not say whether override-dialog failures count, and it does not record the trade-off. Research § 8 lists a runbook "owner locked out offline" that the ADR omits.

**Suggested fix (§ 7 Lockout):**

> "PIN failures in the override dialog count toward the approver's counter. Locking at the 10th failure lets a co-worker lock a manager on that device while offline: a recorded deviation from 6.1.1, accepted by name (founder), with a security event at the 5th failure and the runbook 'owner or manager locked out offline'."

The founder may instead choose delay-only, with no lock, for people holding approval permissions. That choice is the founder's.

---

### M6. A passkey cannot be used on the counter (§ 7 Password path "and their second factor if they have one")

The counter realm has no RP ID (§ 1 table). A person whose only second factor is a dashboard passkey cannot present it there.

**Suggested fix (§ 7):** "On the counter the second factor is TOTP or one recovery code. A person whose only factor is a passkey enrols by the sponsored path."

---

### M7. Throttle and rate-limit state has no table class or store (§ 3 Sign-in; § 5 "Sends are rate-limited per account and per destination"; Cross-Cutting Caching)

Per-identifier and per-address delays, and per-destination send limits, need state. That state is cross-tenant and is not keyed by tenant (an address or an unknown identifier), so it fits none of ADR-0001's classes: G is "runtime roles read only". The Caching row does not mention it. `ktor/best-practices.md` marks RateLimit storage "NOT SOURCEABLE".

**Suggested fix:** decide and state one of these two options:
- **Option 1:** "Throttle state is kept in the memory of the single backend instance, keyed by an HMAC of the identifier or address under a server key (in the crypto inventory, H5). It is lost on restart, which is accepted; it moves to a shared store with a second instance." Record this in the Caching row as a cache decision (gate 5).
- **Option 2:** a new table class, through the ADR-0001 amendment.

---

### M8. Operator realm: the database separation of `console_rt` is real, but the console process holds other logins (§ 6; Validation "console_rt cannot select any TD, CP or PL table")

`console_rt` with grants on OP only is correct. But § 6 also says "the console reads tenant data only through ADR-0004 (`support_rt`) and acts on licensing only through the licensing service roles". The console process therefore holds `support_rt`, the licensing logins and, for suspension and plans (H6), `platform_rt`. Within its rights it can reach:
- any tenant's licensing TD tables, with no owner grant (by design, ADR-0004 § 7);
- every tenant's CP tables.

"No tenant data" is true of the role, not of the realm. Two more points are missing: the console cookie rules, and that WebAuthn Related Origin Requests (F116) must not be enabled for the console's RP ID.

**Suggested fix (§ 6, new bullets):**
- "The console process holds `console_rt`, `support_rt` (grant-gated reads), the licensing service logins (licensing TD of any tenant, ADR-0004 § 7) and `platform_rt` (CP only). Every call on those logins requires a live OP session, and step-up where § 4 lists it."
- "The console session cookie follows § 3 (`__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict`)."
- "No Related Origin Requests list is published for the console's RP ID."
- "OP has no RLS and no `tenant_id`. The catalogue check adds: OP tables have grants to `console_rt` only, and `console_rt` has grants on OP only."

---

### M9. Dependencies on unwritten decisions that are not stated (ADR Dependencies)

ADR-0007 relies on these, but they are missing from Depends On:
- **The storage / server-sync-state ADR (D5-C).** It homes the control journal (H1 replay, enrolment facts, authority changes) and the restore replay.
- **The key-custody ADR.** "The store key (DPAPI, or a TPM-bound key) plays the pepper's role", and the pepper's KMS move is "the same move as the licensing issuing keys".
- **The owner-client ADR.** It decides TWA or WebView, which governs the cookie and passkeys in the Play wrap. ADR-0003 Decision 2 defers token transport to "the auth/session spec and the owner-client ADR".
- **The domain-layout decision (Q-domains, `cto`).** It fixes the RP IDs (§ 1).

Ordering also needs a fix:
- Research § 9 Q-adr3 put the ADR-0003 amendment "before the staff-auth ADR". ADR-0007 lists it under Enables, yet its counter, override and step-up permissions depend on it.
- Research § 5.0 E (custom roles, immutable owner role, last-owner trigger) and F (audit trail B1 plus control journal, the retention row) have no named home. Only "ADR-0003 amendment (custom roles…, audit trail)" appears under Enables.

**Suggested fix (Depends On, "Not yet written"):** add the storage/sync-state ADR (control journal and restore replay), the key-custody ADR, the owner-client ADR and the domain layout (Q-domains). Then add:

> "The ADR-0003 amendment is a dependency of §§ 4, 7 and 8 (permission names, the strict-subset rule, the authority snapshot) and decides research § 5.0 E and F, including the activity-trail retention row in ADR-0005."

---

### M10. Research items due "before the ADR" are still open, and the staff-auth threat model is absent (Related "Open"; Validation last line)

Research § 9 marks these "before the ADR":
- Q-l3, Q-domains and Q-reread. Q-reread asks to re-read NIST SP 800-63B-4 §§ 3.2.10 and 4.2 before an ADR cites a number. ADR-0007 cites the 10-attempt ceiling (F208) and 64-bit codes (F209), both read through a summarising tool.
- S13.
- Q-adr3.
- Q-verifiers, which is closed in effect by per-device enrolment, though the ADR does not say so.

Founder § 5.0 "Gaps: none block the choices" covers S13 and S22/S23 only.

Separately, the skill's verdict rule makes a sensitive Foundation requirement (auth) with no threat model a FAIL. For tenant isolation the founder ruled (2026-10-18) that the threat model blocks the first story, not acceptance. ADR-0007 records no such ruling.

**Suggested fix:**
- **Related:** add "Founder ruling needed: Q-l3, Q-domains, Q-reread and Q-adr3 do not block acceptance (or close them first). Q-verifiers is closed: only people enrolled on a device have a verifier there."
- **Validation (last line):** "… exists before the first auth story starts; it does not block acceptance of this ADR (founder, <date>)". Add this only if the founder so rules.

---

### M11. One validation criterion is inverted, and one is missing (Validation Criteria, counter bullets)

"A sale by a person disabled on the server **before** the device's last contact is accepted and flagged". If the disable came before the last contact, the staff feed delivered it at that contact, and the device should have refused that person's sign-in. The intended case is a disable *after* the last contact.

**Suggested fix:**

> "Counter: a sale made offline by a person disabled on the server after the device's last contact is accepted and flagged; once the device has applied the disable from the staff feed, that person's PIN sign-in is refused."

---

### L1. Numeric values stated as fixed instead of configuration with typed defaults (§§ 5–7; coding standards "No hardcoded business values")

Values written as fixed:
- § 6: "Sessions 12 h absolute, 15 min idle" (§ 3 marks dashboard lifetimes as configuration; the console's are not).
- § 7: "a growing delay from the 5th failure, the person locked at the 10th". Research Q-limits lists "wrong-attempt count" as a founder number.
- § 5: "at most 10 minutes".

Values left without any number or config statement:
- the temporary-password lifetime;
- the device-wide slow-down threshold.

**Suggested fix (end of Decision):**

> "Every number in §§ 2–8 is configuration with a typed default. Figures taken from standards are compiled ceilings or floors that configuration cannot cross:
> - console sessions ≤ 12 h / ≤ 15 min (NIST AAL3);
> - PIN delay from 5 and lock at ≤ 10 (NIST § 3.2.10);
> - reset link ≤ 10 min (ASVS 6.5.5);
> - PIN floors 6 and 8 (founder);
> - password minimum 15, or 8 with a factor, and maximum ≥ 64;
> - recovery codes ≥ 64 bits;
> - challenges ≥ 16 bytes.
>
> Temporary-password and temporary-PIN lifetimes and the device-wide slow-down are set in the auth spec (Q-idle)."

### L2. PIN floor after a role change, and local suspend authority (§ 7 PIN policy; § 8 Local suspend)

When a role gains an approval permission, a person's existing 6-character PIN falls below the 8 floor. Local suspend does not say who may suspend whom, or who lifts it.

**Suggested fix:**
- "When a person's floor rises, the device requires a new PIN at their next sign-in."
- "Local suspend follows the strict-subset rule (H3). A higher person or the server lifts it, and the lift is a synced fact."

### L3. Does the console have a password? (§ 2 heading "dashboard and console"; § 6)

§ 2 and research § 5.0 ("operator-console passwords") imply a console password. § 6 accepts only a device-bound passkey.

**Suggested fix:** "Console accounts have no password. § 2 applies to the console's recovery codes only." Or the opposite: state that the console uses a password plus a passkey.

### L4. Passkey signature-counter regression has no stated response (§ 3 Passkeys)

F115 leaves the response to the RP.

**Suggested fix:** "If both counters are non-zero and the new one does not increase, the assertion is refused on the console and accepted with a security event on the dashboard (synced passkeys report 0)."

### L5. Argon2 dispatcher (§ 2 Concurrency cap; Implementation Guidelines)

Argon2id is CPU- and memory-bound. `kotlin/best-practices.md` line 32 says "`Dispatchers.Default` for CPU", and ADR-0006's IO rule is for blocking JDBC.

**Suggested fix:** "`Dispatchers.Default.limitedParallelism(n, "argon2")`", or state why the IO view is chosen. Not a deprecated API in either form.

### L6. Open items in other ADRs that this ADR settles or leaves (§ 3 Sessions; § 2)

- ADR-0007 decides the cookie transport that ADR-0003 Decision 2 deferred. It should say so for the browser and leave the Play wrap's storage to S11 and the owner-client ADR (MASVS).
- `tenant-isolation.md` M32 and R-3 name "verifying inside the database is an option for the auth ADR".

**Suggested fix:**
- "Settles ADR-0003 Decision 2's transport item for browsers."
- "Verification stays in the application. The pepper makes a database-only leak uncrackable, but does not change R-3 for an application compromise."

### L7. Registry wording follows the ADR's gaps (`docs/registry/architecture.yaml`, uncommitted)

Once the fixes above are applied, align these entries:
- `IC-COUNTER-ENROLMENT` (monotonic clock M4; "strictly lower role" H3);
- `IC-PRE-CONTEXT-LOOKUPS-R7` (B1 rows);
- `IC-STEP-UP` (H6, M3);
- `IC-PASSWORD-HASHER` (M2 deadline).

Three Accepted entries are already marked `superseded_by` although ADR-0007 is Proposed. That follows the ADR-0005 precedent. If ADR-0007 is rejected, those three `status:` lines go back to `active`, so say this in the header comment. The reviewer did not edit the registry.

### L8. Disabled and suspended users in recovery and step-up (§ 5; § 4)

**Suggested fix (§ 5):**
- "`Recovery.create` silently does nothing for a disabled login, and for a non-owner of a suspended tenant (ADR-0001 Decision 4). The uniform response is kept."
- "`Logins.disable` also voids the user's recovery requests and step-up grants (7.4.2)."

---

## Traceability Summary

- No feature spec exists (`design/specs/` absent), so 0 spec requirements were traced. ADR-0007 is Foundational, and its "Spec Requirements Addressed" names brief items 5, 8, 9 and 10.
- Coverage against the research decisions (§ 5.0, by area):

| Area | Coverage |
|---|---|
| A, B, C, D | 🟡 Covered (Proposed), with the gaps above |
| E (roles) | Deferred to the ADR-0003 amendment, not named (M9) |
| F (audit) | No home (M9, H1) |

- 🟡 is not a pass state. The route out is `/architecture-decision accept ADR-0007`, after the fixes and the founder's decisions.

## Threat-Model Coverage

| Sensitive area | Threat model | Covering ADR | Status |
|---|---|---|---|
| Authentication (dashboard, console, counter) | `docs/architecture/threat-models/staff-auth.md`: **MISSING** | ADR-0007 (Proposed) | GAP. Run `/threat-model staff-auth`; founder ruling on acceptance timing (M10) |
| Pre-context functions, sessions | `tenant-isolation.md` (T4.x, M23, M31–M35) | ADR-0001 / ADR-0007 | Needs rows for the B1 functions (M35 requires it) |
| Operator console | `licensing.md` TB3/M15, `tenant-isolation.md` M36/M37 | ADR-0004 / ADR-0007 | M36 incomplete in ADR-0007 (H6); M37 mis-stated (B2) |

## Cross-ADR Conflicts

| Conflict | Type | Blocking? |
|---|---|---|
| ADR-0007 § 6 vs ADR-0004 § 10 and threat model M37: claim that the operator-id weak spot is closed (B2) | Integration contract | 🔴 blocking |
| ADR-0007 key interfaces vs ADR-0001 § 1c "only way before a context": required pre-context writes are missing (B1) | Tenancy / integration contract | 🔴 blocking (amendment incomplete) |
| ADR-0007 ordering vs research Q-adr3 ("ADR-0003 amendment before the staff-auth ADR") (M9) | Dependency | no |

## ADR Dependency Order

Run 2026-10-19 (`adr-dep-graph.sh`): ADR-0001 → ADR-0002 → ADR-0003 → ADR-0004 → ADR-0005 → ADR-0006 → ADR-0007. No cycle. Every Accepted dependency is Accepted.

Unwritten dependencies: sync, desktop runtime, licensing, device credential, email provider (all stated). Not stated: storage/sync-state, key custody, owner client, domain layout and the ADR-0003 amendment (M9).

## Spec Revision Flags

None: no specs exist.

## Stack and Licence Issues

- **Deprecated APIs:** none referenced. The typed auth DSL (`@ExperimentalKtorApi`) and Ktor cookie `Sessions` are avoided, and two-argument `limitedParallelism` is used (`kotlin/deprecated-apis.md` line 25).
- **Version references:** consistent with `pins.yaml`. Bouncy Castle 1.86, WebAuthn4j 0.29.1 / Yubico 2.x, `@simplewebauthn/browser` 14.0.0 and Node 24.22.0 `crypto.argon2` are correctly marked "not yet pinned".
- **Stack note:** L5 (dispatcher choice).
- **Licence check:** not applicable per the ADRs (hosted only). `distribution.model` is unset in `project.yaml`, so this is NOT ASSESSED formally.

## Architecture Document Coverage

NOT ASSESSED: no `docs/architecture/architecture.md`.

## Checks Not Run

- Spec traceability: `design/specs/` absent.
- Phase 6: no `architecture.md`.
- Stack-lead consultation (`ktor-lead`, `web-lead`): **Stack validation: NOT ASSESSED**. No stack layer is configured in `project.yaml`, and no subagent was spawned.
- NIST SP 800-63B-4: not re-read. The numbers in ADR-0007 rest on summarised reads (F107, F208, F209); see M10.
- MASVS 2.1.0 IDs for the Play wrap: NOT SOURCEABLE (research § 6).
- The `staff-auth` threat model does not exist, so its coverage could not be checked.

## Required ADRs and Artefacts

1. The ADR-0003 amendment (custom roles, permission names, strict-subset rule, authority snapshot, activity trail): before ADR-0007's counter and step-up parts can be implemented.
2. `/threat-model staff-auth`.
3. The storage / server-sync-state ADR (control-journal home, restore replay; H1).
4. The domain-layout decision (Q-domains) and the owner-client ADR (S11).

---

# Re-check — 2026-10-19 (revised ADR-0007, still Proposed)

Scope: the revised `docs/architecture/adr-0007-staff-auth.md`, the founder's answers from the fix round as listed in the ADR's Decision Makers, and the seven new ADR-0007 registry entries. These are TR-TABLE-CLASSES-R6, IC-PRE-CONTEXT-LOOKUPS-R8, IC-PASSWORD-HASHER-R2, IC-STEP-UP-R2, IC-COUNTER-ENROLMENT-R2, FP-SYNCED-PASSKEY-ON-CONSOLE-R2 and FP-CONSOLE-CREDENTIAL-OUTSIDE-SCRIPT. TR-ROLE-INVENTORY-R6, which was not revised, was read as well. As in the first round, nothing else was edited, staged or committed.

Reviewed-Content-Hash: docs/architecture/adr-0007-staff-auth.md 0135b90eb8e567283a86e75ba8fdfd4a103f49cf
Reviewed-Content-Hash: docs/registry/architecture.yaml b03229cf5ee40f44ee5145b3dc3ef61f4d38d4dd

## Re-check verdict: CONCERNS

- All 27 findings (B1–L8) are resolved.
- No new conflict with ADR-0001–0006 blocks acceptance.
- One new internal contradiction (R1, High) should be fixed before acceptance.
- Two cross-ADR gaps (R2, R3) and five low items remain.
- The ADR is still `Proposed`, which caps the verdict at CONCERNS in any case.
- R1–R3 are one-sentence text fixes. With them applied, the ADR is ready for the founder's acceptance decision. The route is `/architecture-decision accept ADR-0007`.

## 1. Findings B1–L8

| # | Status | Evidence in the revised text |
|---|---|---|
| B1 | Resolved | Key Interfaces adds: `Sessions.create` with `aal` and expiries, `touch`, `rotate`, `listOwn/endOwn/endOthers`; `Contacts.startVerify/confirm`; `Recovery.create` returning the verified address; `redeem → resetHandle`; `Logins.resetVerifier(resetHandle, …)`, which ends sessions and voids grants; `findByCredentialId`; `Challenges`; `applyPendingRemovals/cancelRemoval`; `auth_notices` + `AuthNotices.claim`; `Enrolment.issueAssertion/consumeAssertion`; `Closure.endSessions` covering `step_up_grants`. Registry R8 matches. One residue is R6 below |
| B2 | Resolved | § 6 "Operator id" states that § 10 and M37 stay open; Consequences and Related agree |
| H1 | Resolved | § 3 "Restore", a Requirement, a Validation line and the Risks row. The new text raises R3 |
| H2 | Resolved | § 5 checks the factor before the password changes; Implementation Guideline; Validation |
| H3 | Resolved | § 7 strict-subset rule, "owner only until the ADR-0003 amendment"; § 8 local suspend and PIN reset; registry R2 |
| H4 | Resolved | § 5 "Lost factor, another person helps" (`startReset`, inside owner, step-up, delay, notices, cancel); § 3 names the one exception; 6.4.4 reading recorded |
| H5 | Resolved | § 3 2FA rule for privileged dashboard roles; Consequences deviations accepted by name (6.3.3 L2, 13.3.3); V11, V13, 16.3.1, 6.3.4, 6.1.2, 6.3.2 and 7.2.4 mapped; § 9 logs successes and partial successes |
| H6 | Resolved | § 4 console actions now cover M36 in full; registry IC-STEP-UP-R2 |
| M1 | Resolved | § 2 recovery codes stored as Argon2id PHC per code; reset token ≥ 128 bits as SHA-256; `recoveryCodesFor` / `consumeRecoveryCode(user, codeId)` |
| M2 | Resolved | § 2 pepper deadline, `must_reset`, `Logins.markMustReset`, gauge; TOTP key `reencrypt`; Validation |
| M3 | Resolved | § 4: fresh defined, `Sessions.rotate`, the recovery code excluded, action list extended. **This fix leads to R1** |
| M4 | Resolved | Lease clock for the temporary PIN (§ 7), idle lock (§ 7) and PIN reset (§ 8); registry R2; reboot Validation line |
| M5 | Resolved | § 7 override failures count; 6.1.1 deviation accepted by name; 5th-failure event; runbook |
| M6 | Resolved | § 7 password path: TOTP or recovery code only; a passkey-only person enrols by sponsor |
| M7 | Resolved | § 3 in-process throttle state on the single instance; Caching row; TR-TABLE-CLASSES-R6 |
| M8 | Resolved | § 6 console-process logins, cookie, no Related Origin Requests, two-way catalogue check |
| M9 | Resolved | Depends On lists the ADR-0003 amendment, storage/sync-state, key custody, owner client and domain layout; Ordering Note records the founder's ordering |
| M10 | Resolved | Related: founder ruling on Q-l3, Q-domains, Q-reread and Q-adr3; Q-verifiers closed (§ 8); Validation: the threat model blocks the first auth story, not acceptance |
| M11 | Resolved | Validation counter line rewritten; § 8 bullet 2 agrees |
| L1 | Resolved | New § 10 lists ceilings and floors; spec-owned lifetimes named |
| L2 | Resolved | § 7 raised floor forces a new PIN; § 8 local suspend and its lift |
| L3 | Resolved | § 1 and § 6: console accounts have no password; § 2 heading |
| L4 | Resolved | § 3 signature-counter regression rule |
| L5 | Resolved | `Dispatchers.Default.limitedParallelism(n, "argon2")` (§ 2, Guidelines, IC-PASSWORD-HASHER-R2) |
| L6 | Resolved | § 3 transport settled for browsers; § 2 verification stays in the app (R-3, M32) |
| L7 | Resolved, with residue R5 | Six entries superseded by their revisions; the header records how to roll back if ADR-0007 is rejected |
| L8 | Resolved | § 5 `Recovery.create` no-op cases; `Logins.disable` voids requests and grants |

## 2. New issues introduced by the revision

### R1 (High). First-factor enrolment and recovery-code re-enrolment are impossible as written (§ 4 dashboard action list and last bullet; § 3 "Who must have a second factor"; § 5 lost-factor reset)

Three rules combine badly:
- § 4 lists "add or remove a second factor" as a step-up action.
- § 4 says "A dashboard user without a second factor cannot perform a step-up action".
- § 4 says "A recovery code never satisfies step-up".

The consequences:
- An owner or privileged user with no factor, who "is sent to enrolment … and can reach nothing else", cannot add the first factor. This covers the guided install, and the next sign-in after a lost-factor reset (§ 5).
- An owner who lost the phone and signs in with a recovery code (§ 3 allows that) cannot enrol a replacement.

Validation line 3 expects enrolment to be reachable, so the ADR contradicts its own test. The first version already had the conflict; the M3 fix made the recovery-code case explicit. The reviewer missed it in round 1.

**Suggested fix (§ 4, after the dashboard action list):**

> "Exception: enrolling a factor when the person has **no usable factor** needs no step-up. This covers a first enrolment, enrolment after a lost-factor reset, and enrolment after a sign-in with a recovery code. It is allowed only from the enrolment-only session state, after a full sign-in (password, plus the recovery code where one was used). Every contact of that person, and every owner contact, is notified (6.3.7). Removing a factor, and adding a further factor once one exists, still need step-up."

Add a Validation line: "an owner with no factor can enrol one at first sign-in; after a recovery-code sign-in the owner can enrol a new factor but cannot run any other step-up action."

### R2 (Medium). The console lock-out script gives the bootstrap superuser a purpose that ADR-0001 § 1b's closed list does not contain (§ 6 "Console lock-out path"; Migration Plan 1; registry TR-ROLE-INVENTORY-R6)

ADR-0001 § 1b limits the bootstrap superuser to "cluster administration, extensions, upgrades, restore, and the rare privileged migrations … Never an application login". ADR-0004 § 9 repeats the limits. The script is a data write on OP tables: it ends operator sessions, removes credentials and issues a registration link. That is a new purpose. The § 3 restore step, which ends sessions and deletes grants as a privileged step, sits under "restore" and is acceptable. The Migration Plan 1 amendment does not list the new purpose, and TR-ROLE-INVENTORY-R6 still reads as before.

**Suggested fix:**
- **Migration Plan 1**, add: "… and the bootstrap superuser row gains one purpose: the audited console lock-out script (§ 6), on OP tables only, never tenant credentials."
- **Registry:** a TR-ROLE-INVENTORY-R7 with the same words.
- **ADR-0004 § 9** keeps "never as a support path". The script is not a support path, so no change is needed there.

### R3 (Medium). The new control-journal record kinds have no retention, and the restore replay needs them to outlive the backup window (§ 3 "Restore"; § 6 lock-out audit; ADR-0005 Decision 3)

ADR-0005 Decision 3 gives "one definition" of the control journal. Its kinds are: enrolment, approval, revocation, rotation, owner review decisions, the licence issuance log and deletion records. Other control facts follow "their own retention". ADR-0007 adds these kinds without a retention period:
- password reset, `must_reset`, factor add or remove;
- recovery-code use, login disable, role change;
- console lock-out runs.

The replay in § 3 works only if these records live longer than the backup window. The founder set that window to 30 days (ADR-0005 Decision 6). This is the same invariant ADR-0005 states for the deletion journal. Two smaller gaps:
- A replayed "factor add" cannot recreate the factor, because the journal holds ids only, never secrets.
- The restore step names sessions, grants, challenges and recovery requests, but not `operator_sessions`, `operator_step_up` or `enrolment_assertions`.

**Suggested fix (§ 3 Restore):**
- "These records join ADR-0005 Decision 3's control-journal kinds. They are kept longer than the backup window (CI-checked like the deletion journal; period in the retention table)."
- "A factor added after the restore point cannot be replayed: the person re-enrols, and is notified."
- "The restore step also ends every operator session and deletes `operator_step_up` rows and unconsumed `enrolment_assertions`."
- Add the matching retention row to ADR-0005 when the storage ADR homes the journal.

### R4 (Low). The reset step's factor check is an application control only (§ 5; Key Interfaces `Recovery.redeem`)

`Recovery.redeem(tokenHash) -> resetHandle` returns no user, but the factor check needs `SecondFactors.forLogin(user)`. The database also does not tie "factor passed" to the handle, so a bug could call `resetVerifier` straight after `redeem`. That is consistent with the R-2 trust model, but should be said.

**Suggested fix:** "`Recovery.redeem` returns `{user, resetHandle}`. `Logins.resetVerifier` refuses a handle not marked factor-passed (or of an account with no factor). The mark is set by `Recovery.markFactorPassed(resetHandle)` after the app verifies the factor."

### R5 (Low). TR-ROLE-INVENTORY-R6 is stale against the revised § 6

The entry says `console_rt` "reads tenant data only through ADR-0004 support_rt". Revised § 6 says the console process also holds the licensing service logins and `platform_rt`. It also lacks the R2 superuser purpose.

**Suggested fix:** supersede it with R7. Suggested text for `console_rt`: "(LOGIN, operator console, grants on OP only; the console process also holds support_rt, the licensing logins and platform_rt, each called only with a live OP session)".

### R6 (Low). The interim Bitwarden passkey's user-verification flag is not verified (§ 6 "Interim synced passkey"; Stack Compatibility "Verification Required")

The console requires UV. Nothing in the repository shows whether a Bitwarden-held passkey, used from the founder's Linux browser, asserts UV=1. If it does not, the console refuses the founder's only credential and the lock-out script becomes the everyday path. The question is NOT SOURCEABLE here; it was not researched.

**Suggested fix:** add to Verification Required: "register and assert the interim Bitwarden passkey on the console origin with `userVerification: required` on the founder's machine, and record the flags (UV, BE, BS), before the console story". Add a fallback if UV=0: buy the FIDO2 keys first.

### R7 (Low). Which roles need 2FA before the ADR-0003 amendment (§ 3 "Who must have a second factor")

The rule is keyed on "a role [that] holds a staff-management, approval or export permission". Those permissions are named by the unwritten ADR-0003 amendment, and until then every check reads "owner only". Read literally, no manager needs 2FA in the interim.

**Suggested fix:** "Until the ADR-0003 amendment, the rule covers the owner and every dashboard login with the manager role." Or say "the owner only" if that is the founder's intent.

### R8 (Low). Research § 5.0 and ADR-0007 now differ on three founder decisions (research note, not ADR-0007)

| Topic | Research § 5.0 | ADR-0007 (founder, fix round 2026-10-19) |
|---|---|---|
| 2FA scope | "2FA mandatory for the owner, optional for staff" | 2FA also for privileged dashboard roles |
| Console credential | C-a "two hardware-bound passkeys" | Interim synced passkey |
| Console lock-out | C-b, the superuser path, not chosen | The lock-out script is a C-b-like path |

The ADR records these founder decisions, so this is no contradiction in substance. But research § 5.0 is what later readers check against.

**Suggested fix:** add a dated addendum to research § 5.0 naming the three changes and this review. The reviewer did not edit the research note.

## 3. Checks against ADR-0001–0006, the registry and research § 5.0

- **ADR-0001:**
  - New PL tables follow the PL rules.
  - "Inside, job" functions are per tenant (`markMustReset`, `reencrypt`, `applyPendingRemovals`, `AuthNotices.claim`).
  - `device_rt` gains only `Enrolment.consumeAssertion`.
  - OP has no RLS, and its catalogue rule is two-way.
  - The only conflict is R2.
- **ADR-0002:** the sponsor check runs in Device scope. No scope is built from request input, and the notice job uses the Job kind. No conflict.
- **ADR-0003:** the browser transport item is settled, and the "owner only" interim is consistent. R7 is a wording gap.
- **ADR-0004:** § 10 is correctly left open. § 9 superuser custody is respected (local peer after SSH). Support verbs and grants are unchanged.
- **ADR-0005:**
  - Successful sign-ins added to the 1-year security-events store: consistent with M23.
  - Notices follow the Decision 4 job pattern.
  - Gap: R3.
- **ADR-0006:** Bouncy Castle and Password4j only; dispatcher rule aligned with `kotlin/best-practices.md`.
- **Registry:**
  - The six supersessions and one addition match the ADR text.
  - R8 of IC-PRE-CONTEXT-LOOKUPS matches Key Interfaces row for row.
  - Residue: R5.
- **Research § 5.0:** every decision from round 1 still holds. The three changes made in the fix round are recorded as founder decisions in the ADR (R8).

## Checks not run (unchanged from round 1)

- Spec traceability: there are no specs.
- Phase 6: there is no `architecture.md`.
- Stack-lead validation: NOT ASSESSED, because no stack is configured.
- The NIST re-read: now deferred to the first auth story by the founder.
- MASVS IDs: NOT SOURCEABLE.
- The staff-auth threat model: does not exist yet. By founder ruling it blocks the first auth story, not acceptance.
