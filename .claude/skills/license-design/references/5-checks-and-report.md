# /license-design - Phase 7: Checks, Stories, Report

> Each check is `met` / `not met` / `not applicable (reason)` / `not run
> (reason)` with the model section, file or gate cited. Never `met` without the
> evidence.

## Checks

| ID | Check |
|---|---|
| L1 | Scope: `distribution.model` includes self-hosted, or device mode is recorded with its term mapping (or `not applicable - hosted`); commercial terms decided or listed `NOT DECIDED` |
| L2 | Research note exists; library per runtime chosen by the user from sourced options; non-canonical-signature and key-size behaviour cited; advisories searched (date) |
| L3 | Envelope: exact payload bytes + detached Ed25519 signature + `kid`; versioned; size cap; verify before parse; **no `alg` field**; unknown `kid` rejects; duplicate fields rejected; critical/non-critical claim rule; fuzz target planned |
| L4 | Claims complete (`licence_id`, customer/tenant, edition, seats, feature keys, `not_before`, `expires_at`, `maintenance_until`, `grace_days`, `issued_at`, optional `installation_id`); one name for the update-eligibility claim; no personal data beyond necessity |
| L5 | Key custody: offline ceremony or KMS/HSM behind an issuer service; two-person approval for production licences; no key in repo/CI/CI variable/logs; test keys generated at test time and rejected by release builds; gitleaks check planned |
| L6 | Rotation and compromise: `kid` set with overlap and announced cut-off; rotation rehearsed by test; emergency procedure; compromise runbook path; signed, sequence-numbered revocation list; honest offline bound stated; short terms for high-risk licences |
| L7 | Online activation: documented payload with no customer data; revalidation only when an admin triggers it or on a customer-configured schedule (no default-on phone-home; jitter only on that schedule); unreachable server never disables a valid unexpired licence |
| L8 | Offline activation: request/response files complete; response bound to the instance key and nonce, single-use; tests named (wrong instance, reused nonce, expired response, tampered request) |
| L9 | Identity: random installation ID stored with the data volume (device mode: enrolment device ID); per-instance keypair (device mode: non-exportable device key); no hardware-fingerprint binding (a fingerprint is at most an alerting signal); move/clone flow; instance counting |
| L10 | Time: injected `Clock`; boundary table; persisted high-water mark with tolerance; audit on regression; rollback test keeps an expired licence expired |
| L11 | Degradation: grace and restricted phases defined; login, export, backup always available; no deletion; a test proves export in the expired state |
| L12 | Update eligibility: `maintenance_until` vs the release date in the signed bundle manifest (never the wall clock); installer tests (eligible, ineligible, expired-but-running); security-patch policy decided |
| L13 | Entitlement parity: one `Entitlements` port, licence adapter and billing adapter, same feature keys as the billing catalogue, parity table with no orphan on either side, a test asserts identical decisions for the same grants |
| L14 | Audit and observability: activation, refusal, tamper, grace-entry, expiry each emit an audit event and a counter; fields limited to `licence_id`, `kid`, outcome, reason code; local `licence_state` and `days_to_expiry`; telemetry off by default; the only outbound call is documented |
| L15 | Threat model exists and covers the 12 threats of `4-threat-model-and-adr.md`; SL-THREAT-MODEL verdict recorded; residual risk accepted by a named person with an expiry |
| L16 | Decision recorded: ADR via `/architecture-decision` with CTO-ADR verdict (`standard`/`full`), or the brief's decision log (`minimal`); marked critical; core-first decision recorded |
| L17 | Security-type stories listed, each mitigation with a named negative test (below) |

## Verdict (first match wins)

1. **BLOCKED** - any design choice that breaks a non-negotiable (see `SKILL.md`
   verdict note): L3 verify-after-parse or an `alg` field, L5 key in repo/CI, L11 a
   lock-out that blocks export, L7/L14 a default-on outbound call or a licence-server
   dependency that disables a valid licence, L9 hardware-fingerprint binding (a signal-only fingerprint is not a cause), or L15 gate =
   REJECT.
2. **NOT ASSESSED** - L2 library choice `NOT SOURCEABLE`, unresearched or not chosen;
   L1/L12 commercial terms `NOT DECIDED` (term, grace, maintenance, security-patch
   policy); `distribution` unset; core not reachable; a gate or agent could not run;
   the threat model not yet run. Name each cause and what closes it.
3. **COMPLETE WITH GAPS** - every check assessed; at least one `not met` (named),
   an SL-THREAT-MODEL of CONCERNS, or a model Status of `Draft` because of open
   questions.
4. **COMPLETE** - all applicable checks met with evidence, gates APPROVE, ADR
   written (not necessarily Accepted: only the user accepts it), open questions
   empty or owned.

`COMPLETE` is a design verdict, not a release approval: `SL-RELEASE-SECURITY` and
`/pentest` apply before the first self-hosted release.

## Story list (Security type)

One story per row, each with a named negative test; hand to `/create-stories`:

| Story | Negative tests that prove it |
|---|---|
| Verifier (core module): verify-before-parse, fixed algorithm, key set | byte flips per region; unknown `kid`; non-canonical signature; oversized payload; duplicate fields; unknown critical claim; fuzz target |
| Issuer service and signing ceremony | key not in repo (gitleaks), not in CI logs; two-person approval enforced; audit of every issuance; test key rejected by release build |
| Clock and grace logic | boundary table; rollback past expiry stays expired; high-water mark tamper; export works while expired |
| Online activation endpoint | replay; rate limit; no customer data in payload; outage keeps valid licence working |
| Offline activation | wrong instance; reused nonce; expired response; tampered request |
| Revocation list | lower sequence rejected; signed list tamper; offline bound behaviour |
| Key rotation | licence signed by key B verifies against {A, B}; A removed rejects A-signed files only after the cut-off |
| Update eligibility in the installer | eligible, ineligible, expired-but-running; signature failure refuses the update |
| Entitlement port and adapters | parity test: same grants -> identical decisions from both adapters; seat counts server-side |
| Audit and metrics | each event emitted; no body/signature in logs |
| Runbooks | key-compromise and support playbooks exist (`docs/runbooks/`, `templates/runbook.md`) |
| Parser fuzzing | fuzz target in CI |

## Report

Present: scope, decisions table (each with who decided and when, or `NOT
DECIDED`), the checks table, gate verdicts (`SL-THREAT-MODEL`, `CTO-ADR` or "not
required at minimal"), the story list, **Not run / not checked** (every unresearched
item, undecided term, skipped phase by name), and follow-ups. Ask: "May I write the
report to `production/qa/license-design-[date].md`?" Write only after approval.
**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/license-design <target> —
<verdict>`, Next step = the first Recommended Next Step in `SKILL.md`, plus
Blocked on / Files in progress / Open questions; append the Notes line. BLOCKED,
NOT ASSESSED or a declined write still updates the checkpoint with the blocker.
Never include key material, licence bodies or customer data. This skill has no
delete tool: list the draft files `production/session-state/license-design-*-draft.md`
in the report and tell the user they may delete them; do not ask to remove them.
If the report write is declined, the verdict line reads `BLOCKED — write declined
by user` and nothing is reported as COMPLETE.
