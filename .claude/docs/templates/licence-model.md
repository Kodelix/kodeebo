# Licence Model: [Product]

> **Path**: `docs/architecture/licence-model.md` · **Status**: Draft | Approved | Implemented · **Owner**: pricing-billing-designer (commercial terms) + security-lead (crypto) + backend lead
> **Date**: [YYYY-MM-DD] · **ADR**: [ADR-NNNN] · **Threat model**: [`docs/architecture/threat-models/licensing.md`] · **Commercial terms**: [`design/specs/pricing-model.md` — "Licence Terms for Self-Hosted"]
> **Core module**: [`saas-core-<track>` licensing @ version, or "product-specific"] — licensing is a shared capability; extend core rather than re-implementing it (`/core-extract`).
> **Assurance target**: ASVS Level 3 for the licensing module (`security-baseline.md`)

<!-- Self-hosted software cannot be made tamper-proof; the goal is to make honest use easy, casual copying inconvenient, and misuse detectable and contractually actionable. Never block a customer's own data access when a licence lapses: degrade to read-only/export. -->

## 1. Goals & Non-Goals

- **Goals**: [enforce edition and limits; support online and air-gapped installs; fair renewal; auditability]
- **Non-goals**: [DRM against a determined attacker; remote kill-switch over customer data; phoning home without opt-in]

## 2. Licence Types

| Type | Unit | Term | Updates | Typical customer |
|------|------|------|---------|-----------------|
| [Annual subscription] | [instance / seat / tenant count] | [1 year] | [all releases within term] | |
| [Perpetual + maintenance] | | [perpetual] | [releases published before maintenance expiry] | |
| [Evaluation / POC] | | [30 days] | | |

## 3. Claims (licence payload)

<!-- Signed payload: the signature covers the exact payload bytes as delivered; the verifier checks the signature over those bytes BEFORE parsing and never re-serialises. Payload format versioned. No personal data beyond what is necessary. -->

| Claim | Type | Example | Purpose |
|-------|------|---------|---------|
| `v` | int | `1` | Licence format version |
| `lid` | string | `lic_01H...` | Licence ID (for revocation and audit) |
| `customer` | string | opaque customer ID | Who it is issued to |
| `product` | string | `acme-crm` | Product |
| `edition` | string | `enterprise` | Edition / plan |
| `entitlements` | map | `{max_seats: 200, features: ["sso","audit"]}` | Feature flags and limits (data, not code) |
| `issued_at` | RFC 3339 | | |
| `not_before` | RFC 3339 | | |
| `expires_at` | RFC 3339 | | Licence term end |
| `maintenance_until` | RFC 3339 | | Update eligibility cut-off (compared with the release date in the signed bundle manifest) |
| `instance_binding` | object | `{type: "install_id", value: "..."}` or none | Optional binding to an install |
| `grace_days` | int | `30` | Full-function grace after expiry |
| `kid` | string | `2026-01` | Signing key ID |

## 4. Signing & Key Management

- **Algorithm**: Ed25519 signatures over the exact payload bytes (`security-baseline.md`); verification library from the stack reference (no custom crypto)
- **Signing key custody**: offline / in a KMS or HSM; **never** in the product repo, CI logs or developer machines; signing happens in a controlled issuance service/process with audit logging and two-person approval for production licences
- **Public key distribution**: embedded in the product (multiple `kid`s allowed); product ships a key set, not a single key
- **Rotation**: [planned rotation period]; new releases add the next public key before the old key is retired; old licences remain valid until expiry or are reissued; **emergency rotation** procedure: [steps, communication]
- **Compromise response**: revoke the key ID, publish a revocation list, reissue licences, force an update that drops the compromised key
- **Test keys**: separate key set for development/CI; never accepted by release builds

## 5. Activation

### 5.1 Online activation
1. Customer enters or the installer receives the licence key/file
2. Instance sends `{lid, install_id, product version}` to the licence service over TLS (no customer data)
3. Service verifies the licence, checks revocation and binding, records the activation (count within `max_instances`), returns a signed activation receipt (`receipt_exp`)
4. Instance stores the receipt; periodically re-validates (every [N] days) with jitter; failure to reach the service never disables a valid, unexpired licence

### 5.2 Offline / air-gapped activation
1. Instance exports a signed request file (`install_id`, nonce, version)
2. Customer uploads it to the licence portal from a connected machine (or sends to support)
3. Portal returns an activation file signed with the issuing key, bound to `install_id` and the nonce
4. Customer imports it; the instance verifies the signature and binding locally
- Offline licences are file-based, work without any network call, and renew by importing a new file

### 5.3 Binding & Instance Counting
- `install_id`: random UUID generated at install and stored with the data volume; **not** derived from hardware fingerprints that change on cloud migrations
- Moves/clones: [deactivate then activate; portal self-service with rate limit]
- Seat/tenant limits: enforced by the application from `entitlements`, not by crashing

## 6. Validation at Runtime

| Check | When | Failure behaviour |
|-------|------|-------------------|
| Signature + `kid` known | Start-up, on import, daily | Reject the licence; keep the previous valid one if any |
| Format version supported | On import | Clear error with upgrade hint |
| `not_before` / `expires_at` | Daily and on use | Enter grace (section 7) |
| Binding match | On start-up | Warn; block activation of the second instance beyond limits |
| Revocation | On online re-validation / revocation list import | Section 8 |
| Clock tampering | Compare against last-seen monotonic time stored with data | Warn; do not hard-fail on small skew; tolerate [x h] |

- Licence checks are a **port** (`LicenceVerifier`) with a fake for tests; entitlement checks use the verified claims, cached in memory with a short TTL
- Verification failures are logged (no secrets) and visible in the admin UI with the next step

## 7. Expiry & Grace

| Phase | Condition | Behaviour | Communication |
|-------|-----------|-----------|---------------|
| Active | before `expires_at` | Full function | Renewal reminders at [60/30/7] days to admins |
| Grace | `expires_at` + `grace_days` | Full function with banner | Daily banner; email to admins |
| Restricted | after grace | **Read-only + export**; no data deletion; no new tenants/seats beyond the lowest edition; background jobs for existing data continue | Persistent banner; support link |
| Re-activated | valid licence imported | Immediately full function | Confirmation |

Customer data remains accessible for export in every phase.

## 8. Revocation

- **Reasons**: [non-payment after notice, fraud, breach of terms, key compromise, reissue]
- **Mechanisms**: online — revocation list/endpoint checked on re-validation; offline — signed revocation file imported by the operator or a short-lived licence that simply lapses
- **Behaviour**: revoked licence enters Restricted immediately after confirmation (no grace for fraud; documented exceptions); never deletes data
- **Authority**: revocation requires [two-person approval]; every action is audit-logged with reason
- **Customer remedy**: appeal path and reinstatement process

## 9. Update Eligibility

- Each release has a `released_at` timestamp embedded in the signed build metadata
- A build is **eligible** when `released_at <= maintenance_until` of the active licence (perpetual + maintenance model) or `expires_at` (subscription)
- The updater/installer verifies bundle signatures **and** eligibility before applying; ineligible updates are refused with a clear explanation and renewal link
- Security patches policy: [security fixes for supported versions are released to all customers with active support / to all, as decided commercially — state it]
- Downgrade/rollback: always permitted to previously eligible versions

## 10. Tamper Resistance & Abuse

| Threat | Mitigation | Residual |
|--------|-----------|----------|
| Licence file edited | Signature verification | None (cryptographic) |
| Binary patched to skip checks | Signed bundles; integrity check at start; contractual terms and audit rights | Accepted — documented in the threat model |
| One licence on many instances | Instance counting online; offline binding to `install_id` | Offline sharing detectable only via audit/contract |
| Clock rollback to extend term | Monotonic last-seen time stored; tolerance window | Low |
| Key extraction from the product | Public keys only are embedded | None |
| Licence server DoS blocks activation | Valid licences keep working offline; retries with backoff | Low |

## 11. Observability & Audit

- **Licence service**: activations, validations, denials, revocations counted; alert on abnormal activation rates per licence (sharing signal)
- **Instance**: licence state exposed in admin UI and metrics (`licence_state`, `days_to_expiry`) — local only unless the operator opts in to telemetry
- **Audit log**: issuance, activation, deactivation, revocation, key operations — append-only
- **Privacy**: no customer data in activation traffic; documented in the privacy notice

## 12. Operations

- Issuance process and owner: [portal/CLI; approval; SLA]
- Renewal flow: [automatic reminders; sales-assisted; payment link]
- Support playbooks: [lost licence, move to new host, expired in grace, offline renewal]
- Runbook: [`docs/runbooks/licensing.md`]

## 13. Testing

- [ ] Valid, expired-within-grace, expired-after-grace, not-yet-valid, revoked, tampered, unknown `kid`, wrong binding, future format version
- [ ] Clock skew and rollback cases
- [ ] Online and offline activation round-trips; deactivate/move
- [ ] Update eligibility accepts and refuses correctly; signature failure refuses the update
- [ ] Key rotation: old licences verify under the old key; new under the new
- [ ] Restricted mode keeps export working and never deletes data
- [ ] Licensing code covered by Security-type stories (negative tests) and the threat model

## 14. Open Questions

| Question | Owner | Due | Resolution |
|----------|-------|-----|-----------|
