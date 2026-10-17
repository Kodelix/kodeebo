# Licence Model: Kodeebo — cashier-device seats and offline lease

> **Path**: `docs/architecture/licence-model.md` · **Status**: Draft · **Owner**: `pricing-billing-designer` (commercial terms) + `security-lead` (crypto) + backend lead
> **Mode**: device licence (hosted) — `/license-design` device mode (studio 631002d). Kodeebo is a hosted product whose offline cashier device enforces the licence; `distribution.model` in `project.yaml` is still unset (`/setup-stack`)
> **Date**: 2026-10-17 · **ADR**: none yet — written after the library choice (custody and licensing ADR by `cto`) · **Threat model**: [`docs/architecture/threat-models/licensing.md`](threat-models/licensing.md) (Draft, NOT ASSESSED; residual risks R1-R8 accepted by name) · **Commercial terms**: no `design/specs/pricing-model.md`; the founder decisions recorded in [`docs/research/licensing.md`](../research/licensing.md) Part 1 § 5 stand in for them
> **Research**: [`docs/research/licensing.md`](../research/licensing.md) (Parts 1-3, F101-F324) and [`docs/research/licensing.part-4-custody.md`](../research/licensing.part-4-custody.md) (Part 4, F401-F430)
> **Core module**: none yet — this model is the core module's spec (`core.track` unset; stories are written against `saas-core-<track>` licensing, not the product repo; `/core-extract` when the core exists)
> **Assurance target**: ASVS 5.0.0 Level 3 for the licensing module (`security-baseline.md`)

Device-mode term mapping (`.claude/skills/license-design/references/1-scope-and-inputs.md` § 2):

| Self-hosted term | Kodeebo |
|---|---|
| instance, installation ID | cashier device; `device_id` issued at D1-A enrolment |
| per-instance keypair | non-exportable per-device key, ECDSA P-256 (TPM where present, else DPAPI) |
| online activation | D1-A enrolment against the hosted service, within the seats in the Kodelix-signed seat licence |
| offline activation files | not needed: enrolment always runs online |
| grace after expiry | the N5 offline lease G: how long the device sells without reaching the server |
| revalidation schedule | lease renewal on Kodeebo's own sync connection |
| instance move or clone | seat move on replacement; clone detection |
| update eligibility | not applicable: releases are not sold per version (hosted subscription) |

## 1. Goals & Non-Goals

- **Goals**:
  - charge and enforce **per cashier device**; the owner dashboard and Android app are not billable devices (founder, 2026-10-17);
  - seats come **only from Kodelix**, as a Kodelix-signed seat licence per tenant;
  - the counter keeps selling offline for a bounded, known lease;
  - a replaced PC moves its seat and never consumes a new one;
  - Kodelix is notified of every activation and seat move;
  - every licensing action is auditable with IDs only.
- **Non-goals**:
  - DRM against a venue administrator who patches the app or restores disk snapshots (residual R1, R2 in the threat model);
  - a remote kill switch over a venue's data;
  - any outbound call besides Kodeebo's own sync connection (licence traffic rides it; no extra endpoint or third party);
  - hardware-fingerprint binding.

## 2. Licence Types

| Type | Unit | Term | Updates | Typical customer |
|------|------|------|---------|-----------------|
| Seat licence (subscription) | **cashier device seat** per tenant (tenant = owner organisation; branch = venue; device = cashier PC) | the contract term — **NOT DECIDED** (contract length, renewal, prices: `/pricing-strategy`) | all releases while subscribed (no per-version sale) | venue owner with 1+ branches |
| N5 offline lease (per device) | one active device on one seat | **G = 7 days** on the base plan; higher plans longer, set with the plans in `/pricing-strategy`; **maximum 14 days** across plans (founder, 2026-10-17) | n/a | every enrolled cashier device |
| Evaluation / POC | **NOT DECIDED** | **NOT DECIDED** | — | — |

Rules (founder, 2026-10-17):
- **Enrolment.** The owner enrols devices (D1-A) only within the seats the seat licence carries; an enrolment code is valid only while a free seat exists, checked at create and at redeem.
- **Replacement.** A replacement moves its seat; **2 moves per device seat per year**, per seat, not pooled. A move beyond the allowance, or one carrying a clone or hardware-change signal, needs Kodelix approval (B3).
- **Release first (C2).** A move releases the old device first when it is reachable (zero overlap). Otherwise the old device may sell until its own lease ends (C1): overlap at most G per move, at most 2 × G device-days per seat per year.
- **Lease expiry mid-shift** follows the sync SC-25b rule:
  - a 24 h warning to cashier and owner;
  - at expiry, open sessions can still be closed and paid;
  - no new session or sale until the device reaches the server;
  - local data stays readable and exportable;
  - the whole backlog is accepted at reconnect.

## 3. Claims (licence payload)

Two signed artefact types, each verified over the **exact received bytes before parsing**, never re-serialised. Algorithm, key id and purpose live **inside** the signed bytes; there is **no `alg` field to trust**: the algorithm is fixed in code (lic F222). Claim names are proposals for `licensing-specialist`; the encoding (JSON, CBOR, protobuf inside a framed envelope) is open (lic Part 2 § 9).

**Envelope** (both types):

| Field | Purpose |
|---|---|
| `fmt` | envelope format version |
| `purpose` | `seat_licence` or `lease` (rejects cross-purpose replay; ASVS 9.2.2) |
| `kid` | issuing-key id; resolves only through a root-signed issuing-key certificate (§ 4) |
| payload bytes | the claims below |
| detached Ed25519 signature | 64 bytes, over the exact envelope bytes |

**Seat licence** (`purpose = seat_licence`, signed with K-seat, issued only with the required approvals):

| Claim | Type | Example (placeholder) | Purpose |
|-------|------|---------|---------|
| `licence_id` | string | `sl_<opaque>` | revocation and audit |
| `tenant_id` | UUID | `<tenant uuid>` | the owner organisation it is issued to |
| `product` | string | `kodeebo` | product |
| `plan` | string | `base` | plan; maps to the lease G (catalogue key NOT DECIDED, § 14 parity) |
| `seats` | int | `3` | cashier-device seats |
| `moves_per_seat_per_year` | int | `2` | allowance per seat (founder) |
| `lease_grace_seconds` | int | `604800` | G for this plan (7 days); device cap 14 days |
| `seq` | int | `5` | monotonic per tenant; a lower sequence is refused everywhere (downgrade) |
| `issued_at`, `not_before`, `expires_at` | server time | | term (contract dates; values NOT DECIDED) |
| `approval_mode` | enum | `single_approver` | `single_approver` now, `two_person` after the first hire |

**N5 lease** (`purpose = lease`, signed with K-lease on each renewal):

| Claim | Type | Purpose |
|-------|------|---------|
| `lease_id` | string | audit and reconciliation (the device reports the hash of the lease in use) |
| `tenant_id`, `branch_id`, `device_id`, `seat_id` | UUID | binding; the device refuses a lease that does not match its store binding (ti B4-A) |
| `device_key_thumbprint` | hash | binds the lease to the device's ECDSA P-256 public key |
| `seat_licence_seq` | int | the seat licence it was issued under (open row Q3 in the threat model) |
| `iat` | server time | anchor for the lease clock (§ 6); trusted time never goes back |
| `grace_seconds` | int | G for this device's plan; ≤ the certificate's `max_grace_seconds` and ≤ 14 days |
| `seq` | int | monotonic per device and per epoch |
| `status` | enum | `active`, `retiring`, `suspended`, `seat_moved` — applied before the lease is used |
| `key_status_seq` | int | the root-signed key-status list the device must hold |
| `nonce` | bytes | the device's renewal request nonce (no replay of old responses) |

No personal data: tenant, branch, device and seat ids only; no names, contact details, computer names or raw hardware serials.

## 4. Signing & Key Management

- **Algorithm**: **Ed25519** for every Kodelix signature (seat licence, lease, issuing-key certificates, key-status list, root-switch statement), pure mode over the exact bytes. The **device key is ECDSA P-256** (Windows CNG lists no EdDSA, lic F105) and signs sync requests (RFC 9421, D2-B).
- **Verification library per runtime**: **pending S204/S206 after the backend and desktop ADRs**. Part 2's recommendation, not chosen:
  - Go: standard library;
  - JVM (backend and desktop A): JDK built-in, Bouncy Castle 1.86 as fallback;
  - Electron (desktop B): `node:crypto` in the main process.

  Whatever is chosen, verifying keys are pinned, never read from an artefact (several libraries accept forgeries under a small-order key, lic F219). One wrapper returns a single "invalid" outcome, and the shared conformance vectors run in every runtime's CI.
- **Hierarchy (founder, 2026-10-17; zero-cost phase)**:
  - **Root 1** (active):
    - one Ed25519 root generated offline;
    - stored only encrypted under its own strong passphrase, in the founder's Bitwarden vault plus an encrypted offline copy at home (USB or paper);
    - decrypted only on an offline ceremony machine that is not the development laptop; never a plain file.
    - Reviewer's condition: the passphrase is not stored with the encrypted key.
  - **Backup root**:
    - a second Ed25519 root generated in the same session, printed on paper and sealed, never opened;
    - its public key is pinned in the app from the first release;
    - trusted **only** to sign a root-switch statement (and, after a switch, issuing-key certificates);
    - after a switch, root 1 is refused forever, and no app update is needed.
    - **Reviewer's note: the sealed backup root is stored in a different place from root 1's offline copy** (if both sat at home, one burglary would yield the backup in plain text, which can sign a switch).
  - **Issuing keys K-seat and K-lease** (separate per purpose):
    - phase 1: encrypted on the issuer host, decryption secret supplied at start as a Docker secret, decrypted only in process memory, never logged; only the current keys are on the server, pre-certified future keys stay offline.
    - Phase 2, at the first paying customer: AWS KMS `ECC_NIST_EDWARDS25519`, pure mode enforced by IAM, `kms:Sign` only for the issuer identity (about $2/month for two keys), with **no device change**.
  - **Issuing-key certificates** (root-signed) carry purpose, `kid`, `not_before`, `not_after` and `max_grace_seconds`. Chain depth is fixed at root → issuing key → artefact; issuing keys cannot certify keys.
  - **Separate keys** for licences, the desktop update manifest (its own root and pinned set, Q-1P8) and the ETA eSeal certificate. The eSeal is the tenant's own RSA certificate from an Egyptian CA, entirely outside the Kodelix hierarchy (security-lead, 2026-10-17).
- **Lifetimes and caps (accepted 2026-10-17)**:
  - each issuing key is in service for **30 days**;
  - certificate validity = 30 days + maximum lease + 7-day margin. **Reviewer's note: with the 14-day maximum lease this works out to 51 days** (44 only while every plan's lease is 7 days); it stays under the 60-day cap compiled into the app;
  - quarterly root ceremony, which pre-certifies the next issuing keys and one standby key per purpose;
  - floor raise (emergency revocation) published within **24 h**;
  - root cryptoperiod at most **3 years**;
  - caps compiled into the app: lease ≤ **14 days**, certificate validity ≤ **60 days**.
- **Approval (founder, 2026-10-17)**: one approver, the founder, for now. The issuer has a `required_approvers` setting, **1 now and 2 at the first hire**, so a second approver is switched on without redesign. Every approval binds the hash of the exact payload. Every issuance goes into an append-only issuance log with its approval mode, **reviewed monthly against signed contracts**. ASVS 2.3.5 is not met at 1 approver: exception accepted (threat-model R7).
- **Public key distribution**: the app ships a key set: root 1 and backup root for licences, plus a separate update-manifest key set. No `jku`/`x5u`-style fetching; keys come only from the build (ASVS 9.1.3).
- **Rotation**: monthly issuing-key windows certified quarterly; the next key is certified at least G plus the rollout window before the active certificate expires; an alert fires when the active certificate's remaining validity falls below a threshold.
- **Compromise response** (runbooks to write in `docs/runbooks/`):
  - **issuing key:** raise the epoch floor in the root-signed key-status list within 24 h, revoke the `kid`, certify a replacement, reconcile the issuance log;
  - **root 1:** open the backup root, sign the root-switch statement, re-certify the issuing keys;
  - **KMS provider** (phase 2).
- **Test keys**: generated at test time through each runtime's deterministic test-random hook, never committed; release builds reject test keys. No key material in the repo, CI variables or logs (gitleaks runs at commit).

## 5. Activation

### 5.1 Online activation = D1-A enrolment (device mode)
1. The owner, in an authenticated dashboard session, creates a branch-bound, single-use, expiring enrolment code. It is accepted only while a free seat exists, checked at create and at redeem under the seat lock.
2. The cashier PC generates its ECDSA P-256 key, TPM where present, else DPAPI (A3 binding), and redeems the code with its public key over TLS. The payload holds the code, the public key, the key tier claimed and salted component hashes for the change/clone signal. It carries no personal data.
3. The device appears as pending. The owner approves it by typing the key-fingerprint suffix shown on the device, and Kodelix is notified of the activation (server-side event; no device phone-home).
4. The server records the device on the seat. The first N5 lease is issued at the device's first signed sync.
- **Revalidation**: lease renewal on Kodeebo's own sync connection. An unreachable server never disables a valid unexpired lease: the device sells until G is used, then follows the SC-25b rule.

### 5.2 Offline / air-gapped activation
- **Not applicable**: enrolment always runs online (D1-A).
- **Emergency unlock — founder proposal (2026-10-17), not yet threat-modelled**: when the lease has run out and the venue cannot reach the server, the device shows a challenge code. The owner phones Kodelix, and the operator issues a short code bound to that device and that challenge, single use, that extends the lease by **3 days**, at most **3 per device seat per year**, each logged and alerting.
  - **Design proposal for `licensing-specialist`, NOT DECIDED.** A 64-byte signature is too long to read over the phone, so the code would be a truncated MAC over (device_id, challenge, days, unlock counter), keyed by a per-device unlock secret delivered inside a signed lease at enrolment. The 3 days are counted on the same lease clock (§ 6). The yearly cap is enforced by the issuer (the authoritative count) and mirrored on the device. Operator authentication is the console's (step-up).
  - **Must pass before it is built:** `/threat-model licensing --update` (code entropy and length, brute force of a spoken code, replay, a restored device-side counter, social engineering of the operator).

### 5.3 Binding & Instance Counting
- **Identity**: the `device_id` from enrolment plus the non-exportable device key. The binding is the key. The hardware/software fingerprint is a **change/clone signal that alerts Kodelix and the owner, never a binding and never an automatic lock-out** (A3).
- **Counting**: seats are counted server-side from the signed seat licence, never from editable database columns. At most one active plus one retiring device per seat. The seat row is locked during enrolment and moves (ASVS 2.3.4).
- **Moves and clones**:
  - release first when the old device is reachable (C2);
  - otherwise an unreleased move with overlap bounded by the old lease (C1);
  - a clone is detected at contact by sequence conflicts (SC-12), lease reuse or two active devices with one key, and raises `clone_suspected`; any move then needs Kodelix approval;
  - restore/clone policy per sync OQ7: the counter keeps selling, sync is quarantined, every money command is kept, the owner picks the real copy.
- **Key loss** (TPM clear, board swap): D1-A re-enrolment, counted as a move. Whether a same-PC re-key counts against the allowance is open (§ 14).

## 6. Validation at Runtime

| Check | When | Failure behaviour |
|-------|------|-------------------|
| Envelope size cap, then signature over the exact bytes, then parse | on every artefact received | reject the artefact; keep the previous valid one; reason enum logged, no body |
| Certificate chain: issuing-key certificate signed by a trusted root, purpose matches, `kid` known, not revoked by the key-status list, epoch ≥ floor | on every artefact | reject |
| Device rule V1 | on lease receipt | reject unless `not_before ≤ iat` and `iat + grace ≤ not_after` of the certificate (signed data only); a lease accepted this way stays valid for its own G after the certificate expires (no honest lock-out) |
| Device rule V2 | on lease receipt | reject a lease whose `iat` is below the device's trusted time (highest genuine `iat` + elapsed monotonic time, never going back) |
| Binding (tenant, branch, device, seat, key thumbprint) | on lease receipt and at start | reject; `store.binding_mismatch` event |
| Sequence ratchets (lease, seat licence, key-status list) | on receipt | reject lower; ratchets scoped per epoch and discarded when the floor rises (no lock-out by a forged huge sequence) |
| Status (`seat_moved`, `suspended`, `retiring`) | before the lease is used | `seat_moved` / `retiring`: stop new sales, upload backlog only |
| Lease time remaining | continuously | at G: SC-25b rule (24 h warning; open sessions close and pay; no new sale) |
| Clock (R-F) | at boot and at contact | powered-off gap counted when the Windows clock moved forward; counted as zero plus a `wall_backward` alert when it moved below the high-water mark; never stops sales mid-shift, never extends the lease |

- **Lease clock** (one clock: sync D1-B/D2-B): anchor = the signed lease `iat`, encrypted at rest. Consumed time = monotonic time while running plus the R-F rule across power-offs, with a persisted high-water mark. The V2 vs R-F interaction is open row Q13 in the threat model (S402).
- **Calendar-span alert (server, accepted 2026-10-17)**: per device at each contact, gap = (server time − last lease `iat`) − lease time used. Alert Kodelix when:
  - gap > 2 h with no `wall_backward` in the span;
  - gap > 36 h with one;
  - the 30-day sum of gaps > 24 h.
- Licence checks sit behind a `LicenceVerifier` port with an injected `Clock` and monotonic source (fakes in tests). Entitlement checks use the verified claims only.

## 7. Expiry & Grace

| Phase | Condition | Behaviour | Communication |
|-------|-----------|-----------|---------------|
| Active | lease time remaining > 24 h | full function | none |
| Warning | ≤ 24 h of lease left | full function | cashier and owner warned (SC-25b) |
| Restricted (lease ended, offline) | lease time used up | open sessions can still be closed and paid; **no new session or sale**; data readable and exportable; nothing deleted; backlog kept | persistent banner; emergency-unlock path if approved (§ 5.2) |
| Retiring (seat moved) | `seat_moved` received | stop new sales; upload backlog only | owner sees "seat moved" |
| Suspended / closed tenant | server status | as ti Part 5 A.6: uploads of already-sold commands accepted; selling stops at lease end; no auto-wipe | owner dashboard |
| Re-activated | reaches the server with a valid seat | full function at once | confirmation |

The venue's data stays accessible for reading and export in every phase. Money facts are never rejected (sync OQ6).

## 8. Revocation

- **Reasons**: seat moved; device revoked by the owner (lost or stolen PC); tenant suspended or closed; issuing-key compromise; root-1 compromise; fraud. Non-payment rules are NOT DECIDED (commercial).
- **Mechanisms**:
  - device status on the server, read `FOR SHARE` on every renewal (ti F329), so a revoke orders against an in-flight renewal;
  - status carried inside the signed lease;
  - root-signed, sequence-numbered **key-status list** (epoch floor, revoked kids) in every renewal response and every app update;
  - **root-switch statement** signed by the backup root.
- **Honest offline bound**:
  - an offline device learns nothing until contact. For a moved or revoked device, the bound is its own lease: at most G (≤ 14 days).
  - For a stolen issuing key, the bound is the remaining validity of its certificate under rules V1/V2: up to 51 days of trusted time, plus one lease.
  - For a root-1 compromise, the compiled caps apply (certificate ≤ 60 days, lease ≤ 14 days) until the device's next contact receives the switch.
  - Residual risks R4 and R6, accepted by name.
- **Behaviour**: never deletes data; a revoked device keeps its backlog for upload (`retiring` state; ti P3-OQ1 proposal).
- **Authority**: seat issuance and exceptional moves go through the issuer approval workflow (`required_approvers`, 1 now); every action in the append-only audit with a reason code.
- **Customer remedy**: appeal and reinstatement path NOT DECIDED (commercial).

## 9. Update Eligibility

- **Not applicable** in device mode: Kodeebo is a hosted subscription and releases are not sold per version. Every subscribed device takes every release.
- **Security-patch policy**: all subscribed devices receive security fixes as part of the release stream; no per-version maintenance term.
- **Update integrity** is the desktop updater's, with its own key and threat model (followups Q-1P7, Q-1P8):
  - signed manifests with a separate key;
  - downgrade refused by release sequence;
  - the server refuses sync below a minimum app version.

## 10. Tamper Resistance & Abuse

| Threat | Mitigation | Residual |
|--------|-----------|----------|
| Seat licence or lease edited | signature over exact bytes, verify before parse, purpose and binding checks | none (cryptographic) |
| Binary patched or root keys replaced | Authenticode plus update key; integrity check at start; minimum app version at sync; unknown-artefact reconciliation | **R1**, accepted (Kamel Mohamed, founder, 2026-10-17) |
| One seat on many devices (clone) | non-exportable device key (TPM where present); clone detection at contact; Kodelix approval for flagged moves | DPAPI tier copyable by an admin, detected after the fact |
| Owner runs extra devices through unreleased moves | release first; allowance of 2 per seat per year | **R5**, at most 2 × G device-days per seat per year |
| Clock rollback | R-F rule, high-water mark, calendar-span alert | **R3**, bounded by G of running time |
| Disk or VM snapshot restore | sequence reuse at contact, offline-period alert | **R2** |
| Stolen issuing key | per-purpose keys, V1/V2 rules, 24 h floor raise, issuance-log reconciliation | **R4** (High until KMS) |
| Root compromise | backup root with switch statement, compiled caps | **R6** |
| Seat issued without independent approval | single approver with monthly contract review; `required_approvers` → 2 at first hire | **R7** |
| Deployer or infrastructure admin removes controls | founder holds every role today; MFA; log review | **R8** |
| Key extraction from the product | only public keys are embedded | none |
| Licence server outage | valid leases keep working offline; standby issuing key per purpose | low |

Full analysis: [threat model](threat-models/licensing.md), 66 threats and 19 abuse cases.

## 11. Observability & Audit

- **Server**: counters and events for activation, approval, seat move (released or not, within allowance or not), release, refusal (reason enum), `clone_suspected`, `device_hardware_changed`, `sold_after_seat_moved`, calendar-span alert, issuance, unknown artefact, sign-count mismatch. Kodelix and the owner are notified of every activation and move.
- **Device**: `lease_remaining_seconds` and the tamper journal (`wall_backward`, large `wall_forward`, `restore_suspected`, `tpm_mode_downgrade`, key-tier change), sent at the next contact with device detection time and server receipt time. No other outbound traffic.
- **Audit**: issuance log hash-chained in the control journal outside the restorable database; append-only; reviewed monthly against signed contracts.
- **Privacy (condition for PII being out of scope)**: every licensing event carries **IDs only** (tenant, branch, device, seat, move, staff, kid, sequence, hashes). No names, contact details, computer names, raw serials, licence or lease bodies, or signatures (threat-model M17, M43).

## 12. Operations

- **Issuance**:
  - the founder through the operator console, behind WebAuthn plus step-up;
  - one approver now (`required_approvers` = 1), two at the first hire;
  - monthly issuance-log review against signed contracts.
- **Service level for exceptional-move approvals**: NOT DECIDED (threat-model Q8).
- **Ceremony**: quarterly, on an offline machine that is not the development laptop. The procedure is not written (threat-model Q15): which OS image, and how the issuing public key crosses the air gap.
- **Renewal flow**: contract renewal NOT DECIDED (commercial).
- **Support playbooks**:
  - dead PC replacement (release first, else unreleased move);
  - TPM cleared or board swapped (re-enrolment counted as a move);
  - allowance exhausted (Kodelix approval);
  - lease ended offline (SC-25b; emergency unlock if approved).
- **Runbooks** (none exist; `docs/runbooks/` absent):
  - `licensing.md` (support);
  - issuing-key compromise (floor raise ≤ 24 h);
  - root-1 compromise (backup root switch);
  - KMS migration and KMS outage (phase 2);
  - ceremony;
  - restore with licensing-fact replay.

## 13. Testing

- [ ] Byte flips in payload, signature, `kid` and envelope; unknown `kid`; non-canonical signature; small-order key vector; oversized payload; duplicate fields; unknown critical claim; fuzz target per runtime; shared conformance vectors in every runtime's CI
- [ ] Cross-purpose: a seat licence presented as a lease, and the reverse; a licence key in the update-verify path
- [ ] V1/V2: a lease beyond its certificate's window refused; a backdated forged `iat` does not move trusted time back; an honest lease whose certificate expires mid-lease keeps selling until G; caps of 14 days and 60 days enforced
- [ ] Ratchets: lower sequence refused; a forged huge sequence under a revoked `kid` does not lock out genuine leases after the floor rises
- [ ] Key-status list and root switch: revoked `kid` refused; switch statement signed by root 1 refused; backup root accepted only after a switch; root 1 refused afterwards
- [ ] Clock (R-F): forward gap counted, backward gap zero plus alert; calendar-span thresholds; SC-25b expiry mid-shift (open sessions close and pay, no new sale, export works); S306 tamper matrix; S402 V2 vs R-F
- [ ] Seats: enrolment code single use, expiry, brute-force rate limit, no free seat; parallel redeem and move (exactly one wins); allowance (third move needs approval); move approval object bound to its ids
- [ ] Issuer: no signing of caller-supplied bytes; approvals bound to the payload hash; `required_approvers` = 2 refuses self-approval; verify-after-sign; issuer start without the decryption secret refuses to sign; logs, core dumps and disk hold no key material; test keys rejected by release builds
- [ ] Cross-tenant: renewal naming another tenant's seat; IDOR on dashboard moves; RLS as the non-owner app role
- [ ] Audit: IDs-only schema allowlist; log grep for bodies, signatures, codes and fingerprints
- [ ] Every item above is a Security-type story with its negative test: [`production/qa/license-design-2026-10-17.md`](../../production/qa/license-design-2026-10-17.md) § 4

## 14. Open Questions

| Question | Owner | Due | Resolution |
|----------|-------|-----|-----------|
| Ed25519 verification library per runtime | user, after `cto` | after the backend and desktop ADRs and spikes S204/S206 | pending |
| Licensing and custody ADR (critical ADR, CTO-ADR) | `cto` | after the library choice | pending |
| Commercial terms: contract term, renewal, prices, evaluation/POC, non-payment and appeal | user via `/pricing-strategy`, `pricing-billing-designer` | before launch | NOT DECIDED |
| Higher-plan lease lengths (≤ 14 days) | user via `/pricing-strategy` | with the plans | pending |
| Entitlement parity: no billing catalogue exists (`design/specs/pricing-model.md`, `design/registry/entities.yaml` absent); the claims `plan`, `seats`, `moves_per_seat_per_year`, `lease_grace_seconds` must reuse its keys once it exists | `pricing-billing-designer` | with the catalogue | pending |
| Emergency unlock: design and threat-model update (code length and entropy, MAC scheme, operator flow) | `licensing-specialist`; `/threat-model licensing --update`; user approves | before the unlock story | proposal only |
| Envelope encoding (JSON, CBOR, protobuf) and parser facts | `licensing-specialist`, `cto` | before the verifier story | pending |
| Threat-model open rows Q1-Q5, Q7, Q8, Q12-Q15 (lease signer, seat-licence check on device, roles, same-PC re-key, allowance window, service level, KMS counsel, V2 vs R-F, root storage places, ceremony procedure) | see threat model § 9.1 | as listed there | pending |
| `distribution.model` and `tenancy.model` unset in `project.yaml` | user (`/setup-stack`) | before the ADR | pending |
