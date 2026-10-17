# /license-design report — Kodeebo cashier-device licensing (device mode)

> **Date**: 2026-10-17 · **Verdict**: NOT ASSESSED (causes in § 3)
> **Model**: [`docs/architecture/licence-model.md`](../../docs/architecture/licence-model.md) (Draft) · **Threat model**: [`docs/architecture/threat-models/licensing.md`](../../docs/architecture/threat-models/licensing.md) (Draft, NOT ASSESSED) · **Research**: [`docs/research/licensing.md`](../../docs/research/licensing.md) Parts 1-3, [`docs/research/licensing.part-4-custody.md`](../../docs/research/licensing.part-4-custody.md) Part 4
> **Scope**: Kodeebo, distribution hosted (device mode; `distribution.model` unset), core module none yet (this model is the core module's spec), review mode lean

## 1. Decisions

| Decision | Value | Who decided, when |
|---|---|---|
| Unit of licensing | per cashier device; dashboard and Android app not billable | founder, 2026-10-17 |
| Seat issuance | seats only from Kodelix, as a Kodelix-signed seat licence per tenant; enrolment only within seats | founder, 2026-10-17 |
| Binding (a) | A3: non-exportable device key binds; fingerprint is an alert-only change/clone signal | founder, 2026-10-17 |
| Approval vs allowance (b) | B3: first activation owner-approved within signed seats; 2 moves per device seat per year, per seat, not pooled; beyond → Kodelix approval | founder, 2026-10-17 |
| Old device after a move (c) | C1 + C2: release first; else overlap bounded by the old lease | founder, 2026-10-17 |
| Offline lease | G = 7 days base plan; maximum 14 days; higher plans in `/pricing-strategy` | founder, 2026-10-17 |
| Lease end mid-shift | sync SC-25b rule (24 h warning, open sessions close and pay, no new sale) | founder, 2026-10-17 |
| Clock | R-F plus server calendar-span alert (2 h / 36 h / 24 h per 30 days) | founder, 2026-10-17 |
| Algorithms | device key ECDSA P-256; Kodelix signatures Ed25519 | founder, 2026-10-17 |
| Custody (zero-cost) | encrypted root 1 (Bitwarden + home copy), sealed backup root pinned from release 1, issuing keys K-seat/K-lease encrypted on the server until the first paying customer, then AWS KMS; one approver with monthly review; 30-day keys; certificate 51 days with the 14-day maximum lease; quarterly ceremony; floor raise ≤ 24 h | founder, 2026-10-17 (security-lead recommended hardware tokens; the founder chose zero cost) |
| Residual risks R1-R8 | accepted | Kamel Mohamed, founder, 2026-10-17; review by 2027-04-17 or at the first hire / first paying customer |
| Emergency unlock | challenge code, +3 days, 3 per device seat per year | founder **proposal**, 2026-10-17; not designed or threat-modelled |
| Ed25519 library per runtime | — | **NOT DECIDED**: pending S204/S206 after the backend and desktop ADRs |
| Contract term, prices, renewal, evaluation, non-payment, appeal | — | **NOT DECIDED** (`/pricing-strategy`) |

## 2. Checks L1-L17

| ID | Result | Evidence |
|---|---|---|
| L1 | **met** for scope (device mode with its term mapping, model header and table); commercial terms partly **NOT DECIDED** (listed) | licence-model header, § 2, § 14 |
| L2 | **not met** — library not chosen (pending S204/S206); behaviour on non-canonical signatures and small-order keys cited (lic F201, F202, F219); advisories searched 2026-10-17 (lic F214) | licence-model § 4 |
| L3 | **met (design)** — exact bytes + detached Ed25519 + kid, versioned `fmt`, size cap, verify before parse, no `alg` field, unknown kid rejects, duplicates rejected, critical-claim rule, fuzz target | licence-model § 3, § 6, § 13 |
| L4 | **met (device mode)** — claims for seat licence and lease; `maintenance_until` not applicable (§ 9); `device_id` replaces `installation_id`; IDs only | licence-model § 3 |
| L5 | **not met (exception accepted)** — offline ceremony and issuer service ✓; no key in repo/CI/logs ✓; test keys at test time ✓; gitleaks at commit ✓; **two-person approval not met** (one approver; threat-model R7, accepted by name) | licence-model § 4; threat model § 7 |
| L6 | **met (design)** — kid set with overlap, monthly windows, emergency floor raise ≤ 24 h, root switch, key-status list with sequence, honest offline bound, short certificates; runbooks to write (stories) | licence-model § 4, § 8 |
| L7 | **met** — enrolment payload documented with no personal data; renewal rides Kodeebo's own sync; an outage never disables a valid lease | licence-model § 5.1 |
| L8 | **not applicable** — enrolment always online; emergency unlock is a proposal still to be designed and threat-modelled | licence-model § 5.2 |
| L9 | **met** — enrolment `device_id` + non-exportable device key; fingerprint alert-only; move and clone flow; counting from the signed seat licence | licence-model § 5.3 |
| L10 | **met (design)** — injected Clock and monotonic port; boundary rules V1/V2, 24 h warning, G; high-water mark; audit on regression (tamper journal); rollback tests | licence-model § 6, § 13 |
| L11 | **met** — restricted phase keeps reading and export, no deletion, backlog accepted; test listed | licence-model § 7, § 13 |
| L12 | **not applicable** (hosted subscription, no per-version sale); security-patch policy stated | licence-model § 9 |
| L13 | **not assessed** — no billing catalogue exists; parity table pending (open row) | licence-model § 14 |
| L14 | **met** — events and counters listed, IDs only, no bodies or signatures; no outbound call besides the sync connection | licence-model § 11 |
| L15 | **met with gap** — threat model exists, covers the 12 licensing threats, residuals accepted by name; SL-THREAT-MODEL skipped (lean mode); **emergency unlock not covered** (needs `--update`) | threat model § 5.1, § 7 |
| L16 | **not met (deferred by the user)** — the ADR is written after the library choice | licence-model header |
| L17 | **met** — § 4 below | this file |

## 3. Verdict

**NOT ASSESSED.** Causes, and what closes each:

| Cause | What closes it |
|---|---|
| Ed25519 library not chosen (L2) | backend and desktop ADRs, then S204/S206, then the user's choice |
| Commercial terms NOT DECIDED (L1, L13) | `/pricing-strategy` and a billing catalogue |
| `distribution.model` and `tenancy.model` unset | `/setup-stack` |
| Threat model NOT ASSESSED (no licensing spec; scope facts unset) | `/design-spec licensing`, `/setup-stack` |
| Gaps once assessed | L5 (single approver, accepted exception), L15 (emergency unlock not modelled), L16 (ADR pending) |

`COMPLETE` would be a design verdict only; `SL-RELEASE-SECURITY` and `/pentest` still apply before the first release.

## 4. Security-type story list (for `/create-stories`)

No epic exists (`production/epics/` absent). Every story is type **Security** and has `Threat model: docs/architecture/threat-models/licensing.md`. Stories are written against `saas-core-<track>` licensing where the module lives; product wiring is noted. The negative tests are named plans (design-time). Mitigation IDs are the threat model's.

| # | Story | Covers (mitigations) | Negative tests that prove it | Owner | Blocked by |
|---|---|---|---|---|---|
| LS-01 | Verifier core: envelope, verify-before-parse, fixed algorithm, pinned key set, single "invalid" outcome | M2, M40 | byte flips per region (payload, signature, kid, envelope) → invalid; unknown kid → invalid; non-canonical signature and small-order key vectors → invalid; oversized payload, duplicate fields, unknown critical claim → invalid, no crash; 31-byte key → invalid; fuzz target in CI; shared conformance vectors in every runtime | `licensing-specialist`, backend and desktop leads | library choice (S204/S206) |
| LS-02 | Issuing-key certificates, key-status list, epoch floor and root switch on the device | M2, M5, M6, M7 | issuing-key-signed certificate → refused; purpose mismatch → refused; revoked kid after the list → refused; lower list sequence → ignored; switch statement signed by root 1 → refused; backup root before a switch → refused; root 1 after a switch → refused; forged huge sequence under a revoked kid does not lock out genuine leases | `licensing-specialist`, desktop lead | LS-01 |
| LS-03 | Lease acceptance rules V1/V2, caps and binding on the device | M3, M23, M24 | lease beyond its certificate window → refused; backdated forged iat → trusted time does not move back; lease grace 15 days → refused; certificate validity 61 days → refused; honest lease whose certificate expires mid-lease keeps selling until G; lease for another device or tenant → refused; stale nonce → refused; lease without status → refused | desktop lead | LS-01, threat-model Q13 (S402) |
| LS-04 | Lease clock (R-F) and expiry behaviour | M3, M28, M33 | forward wall gap counted; backward gap counted zero + `wall_backward`; SC-25b: at expiry open sessions close and pay, new sale refused, export works; S306 tamper matrix; restored older state file → `restore_suspected` at contact | desktop lead | S301-S306 |
| LS-05 | Calendar-span alert (server) | M28 | gap 3 h without `wall_backward` → Kodelix alert; 2 h → none; 37 h with `wall_backward` → alert; 30-day sum 25 h → alert | backend lead, `observability-engineer` | — |
| LS-06 | Issuer service: typed payloads, registry invariants, verify-after-sign, standby key | M10, M13, M36, M41 | raw bytes to sign → 400; lease for a third device on a seat → refused; seat licence without approval → refused; corrupted or pre-hash signature → not released; primary key down → standby kid signs and devices accept; direct DB seat-count edit → capped at signed count + reconciliation alert; older seat-licence blob → refused | `licensing-specialist`, backend lead | backend track ADR |
| LS-07 | Approval workflow with `required_approvers` (1 now, 2 later) and monthly review report | M14, M8 | setting 2: self-approval and a second account of the same person → refused; payload changed after approval → refused; expired approval → refused; setting 1: every issuance carries `single_approver` and appears in the monthly report | backend lead | LS-06 |
| LS-08 | Issuance log and reconciliation | M8, M12, M18 | device presents a validly signed lease absent from the log → `licence.unknown_artefact`; edited log entry → chain verification fails; sign count ≠ log count → alert; UPDATE/DELETE on audit rows as the app role → denied | backend lead, `observability-engineer` | LS-06 |
| LS-09 | Issuing-key custody phase 1 (encrypted on the server, current keys only) | M9 | start without the decryption secret → refuses to sign; logs, core dumps and disk after start contain no key material; hosted-server identity reads the key file → denied; release build rejects test keys | `platform-lead`, `security-lead` | — |
| LS-10 | KMS migration (phase 2, at the first paying customer) | M9, M12 | non-issuer principal calls Sign → denied; pre-hash algorithm → denied by IAM; CloudTrail sign count ≠ log count → alert; devices accept the KMS-backed kid with no app change | `platform-lead` | first paying customer; counsel on key location (threat-model Q12); S401 |
| LS-11 | Root and ceremony procedure, backup root, runbooks | M1, M4, M5, M42 | dry-run ceremony with a planted mismatching key → aborts; encrypted root cannot be opened from its vault item alone; ceremony on a networked machine refused by the checklist; tabletop: floor raise reaches online devices; root switch accepted and root 1 refused afterwards | `security-lead`, founder | threat-model Q14, Q15 |
| LS-12 | Enrolment code and device approval (D1-A within seats) | M20, M21 | guess loop → 429 then code invalidated; used or expired code → refused; redeem with no free seat → refused; approve with a wrong fingerprint suffix → refused | backend lead, `web-lead` | — |
| LS-13 | Seat invariants, moves, release, allowance | M16, M22, M24, M25, M45 | N parallel redeems or moves → exactly one succeeds; abandoned move → lock expires, renewal continues; replayed `seat_release` → refused; `approved_by_kodelix=true` in an owner request → ignored or 400; approval for move X replayed on move Y → refused; third move in the window → needs Kodelix approval; move during an in-flight renewal → renewal refused or ordered before the move | backend lead | threat-model Q5, Q7 |
| LS-14 | Clone detection and fingerprint signal | M26, M27, M32 | two clients with one key renew alternately → `clone_suspected`; move with the signal → needs Kodelix approval; owner of tenant B asks for a match against tenant A → no data; payload with a raw serial → refused by schema; device claims TPM tier but key shows software → flagged | backend lead, desktop lead | S32 |
| LS-15 | Owner dashboard licensing authorization | M34 | anonymous → 401; wrong role → 403; another tenant's device id → 404; privileged fields → ignored or 400; oversized body → 413; flood → 429 | `web-lead` | threat-model Q4 |
| LS-16 | Operator console hardening | M15, M19 | issue without fresh step-up → 401; cross-site POST → refused; approval older than the service level → escalation alert | `web-lead`, `security-lead` | threat-model Q8 |
| LS-17 | Licensing tables: RLS, jobs, cache keys, restore replay | M35, M37, M38, M39 | as the app role with tenant B context, SELECT/UPDATE/DELETE on tenant A rows → 0 rows; catalogue finds no tenant table without FORCE; job writing a tenant-B event while on tenant A → FK or RLS error; restore drill: revoked device stays revoked, allowance not refunded, next lease sequence above the device's highest | `data-lead` | tenancy ADR-0001/0002 accepted |
| LS-18 | Audit and events, IDs only (the PII-scope condition) | M17, M43, M44 | every event type serialised with name, email, phone and hostname strings in every input → none appear; a non-allowlisted field fails the build; log grep finds no bodies, signatures, codes or fingerprints; 1,000 bad signatures with a victim's key_id → one aggregated alert | `observability-engineer` | — |
| LS-19 | Device local state, integrity and minimum version | M29, M30, M31 | cashier user reads, copies or replaces state, key or database files → access denied (TS-08); USB boot at install audit → blocked; sync from a build below the minimum → refused; integrity check with a modified root key set → refuses start | desktop lead | desktop runtime ADR; sync M1 decision |
| LS-20 | Emergency unlock (challenge code, +3 days, 3 per seat per year) | new (to model) | to be named by `/threat-model licensing --update`: wrong device, reused challenge, fourth unlock in a year, brute force of a spoken code, operator without step-up | `licensing-specialist` | design and threat-model update; founder approval |
| LS-21 | Entitlement port and parity with the billing catalogue | L13 | same grants → identical decisions from the licence adapter and the billing adapter; seat counts server-side only | `pricing-billing-designer`, backend lead | billing catalogue (`/pricing-strategy`) |

## 5. Not run / not checked

- `SL-THREAT-MODEL` and `CTO-ADR`: skipped / deferred (lean mode; the ADR follows the library choice).
- Ed25519 library choice; spikes S32, S11, S301-S306, S204, S206, S401, S402: not run.
- Emergency unlock: not designed or threat-modelled.
- Commercial terms and the billing catalogue: not decided.
- Scanners: gitleaks runs at commit; no dependency or image scan (no code).
- Draft files `production/session-state/license-design-*-draft.md`: none were created (Phase 3 drafting agents were not run; decisions came from the research and the founder directly).

## 6. Follow-ups

`/create-stories` with § 4 (once an epic exists) · `/design-spec licensing` · `/setup-stack` (distribution, tenancy, backend, desktop) · `/pricing-strategy` (terms, higher-plan G, catalogue) · `/threat-model licensing --update` (emergency unlock; then S402 results) · `/architecture-decision` (licensing and custody, after the library choice) · merge Part 4 into `docs/research/licensing.md`.
