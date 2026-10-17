# /license-design - Phase 3: Design Decisions

> Phase 3 of `SKILL.md`. Fill only the `{...}` slots of the briefs. Add nothing
> else: no expected answer, no pre-rating.

## 1. Parallel drafts

Spawn both in one turn.

### `licensing-specialist` - technical design draft

```text
Draft the technical design for /license-design. Draft only: write one new file
and change nothing else.
Read first: .claude/agents/licensing-specialist.md "Senior Bar" and "Anti-Patterns",
.claude/docs/templates/licence-model.md, .claude/rules/security-sensitive.md,
.claude/rules/deploy.md, docs/research/licensing.md, the commercial terms
{path | NOT DECIDED}, the threat model {path | not yet written}.
Write only to: {production/session-state/license-design-technical-draft.md}
Product: {slug}   Distribution: {value}   Core module: {module@version | none yet}
Library decision (user's): {per runtime | not yet chosen - draft both options}
Cover template sections 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 and 13, each decision with
the alternative rejected and why, and these specifically:
- envelope: exact payload bytes + detached Ed25519 signature + kid, versioned,
  size-bounded; verify before parse; fixed algorithm (no alg field); unknown kid
  rejects; duplicate fields rejected; unknown critical claims reject, unknown
  non-critical claims ignored; the claim set (licence_id, customer/tenant ID,
  edition, seats, feature keys, not_before, expires_at, maintenance_until,
  grace_days, issued_at, optional installation_id); and the mapping to the
  template's claim names (`maintenance_until` for update eligibility)
- key custody (offline ceremony or KMS/HSM behind an issuer service, two-person
  approval for production licences), kid rotation with overlap and cut-off,
  emergency rotation, signed sequence-numbered revocation list and its honest bound
- online activation (documented payload, no customer data; revalidation is
  triggered by an admin (button or CLI) or runs on a schedule the customer
  configures, **never automatic by default**: jitter applies only to a schedule the
  customer turned on; unreachable server never disables a valid unexpired licence) and offline
  activation (request file: installation_id, per-instance public key, nonce,
  product/version; response signed, bound to that key and nonce, single-use)
- installation identity: random UUID stored with the data volume + per-instance
  keypair (device mode: device ID from enrolment + non-exportable device key); no
  hardware-fingerprint binding: a fingerprint may be recorded as a change or clone
  signal that alerts the vendor or owner, never as the check that decides validity
  and never as an automatic lock-out (hardware swaps, TPM clears and firmware
  updates change it for honest users); move/clone flow; instance counting
- time: injected Clock, pure functions, boundary table (not_before, expires_at-1s,
  expires_at, expires_at+grace_days, maintenance_until), persisted high-water mark,
  stated tolerance, audit event on regression, never silently extends
- degradation: grace, then restricted (read-only, no new seats/premium features),
  export/login/backup always available
- update eligibility: maintenance_until vs the release date in the signed bundle
  manifest, never the install's wall clock; perpetual keeps running eligible builds
- audit and metrics: events and counters; fields limited to licence_id, kid,
  outcome, reason code; local licence_state and days_to_expiry; telemetry off by default
- test strategy per runtime (virtual time; deterministic randomness; fuzz target)
No key material anywhere: placeholders only, marked as placeholders.
Return (text, under 200 words): the path; decisions that need the user; items
NOT SOURCEABLE or NOT DECIDED; conflicts with the commercial terms. A reply without
the file is a failed phase.
```

### `pricing-billing-designer` - commercial terms and entitlement parity

```text
Draft the commercial inputs for /license-design. Draft only: write one new file and
change nothing else. You decide nothing: you propose with reasons and mark every
open term NOT DECIDED for the user.
Read first: design/specs/pricing-model.md (section "Licence Terms for Self-Hosted"),
design/registry/entities.yaml, design/product-brief.md, docs/research/licensing.md.
Write only to: {production/session-state/license-design-commercial-draft.md}
Cover: licence types and unit of licensing; term; grace_days; maintenance model
(perpetual + maintenance vs subscription) and the update-eligibility rule; the
security-patch policy for supported versions (to all customers with active support,
or to all - the commercial decision); renewal and reminder cadence; evaluation/POC
terms; the offline-expiry bound for high-risk licences (short terms); revocation
reasons and the appeal path.
And the ENTITLEMENT PARITY TABLE: every billing entitlement-catalogue key (plans,
features, quotas, seats) <-> the licence claim that carries it, one vocabulary - no
licence-only flag names. List catalogue keys with no licence claim and claims with
no catalogue key as gaps. State where per-tenant overrides and plan defaults fit
the evaluation order for self-hosted.
Return (text, under 200 words): the path; NOT DECIDED terms; parity gaps. A reply
without the file is a failed phase.
```

Verify both files exist before reading the replies. The two drafts are inputs, not
decisions. `production/session-state/` files are ephemeral drafts; they stay on disk
(this skill has no delete tool) and the report lists them for the user to delete.

## 2. Walk the decisions with the user

Go through the following in order, `AskUserQuestion` for each (2-4 options with
trade-offs, the recommendation first). In `guided` mode only the **major**
decisions ask; every item marked `[always asks]` asks in every mode.

1. Goals and non-goals (honest: not DRM; no kill switch over customer data; no default-on phone-home).
2. Licence types and the unit of licensing (from the commercial draft). `[always asks]`
3. Envelope and claim set; the single name for the update-eligibility claim.
4. Verification library per runtime (research note). `[always asks]`
5. Key custody and who holds the signing ceremony; two-person approval. `[always asks]`
6. Rotation cadence, overlap, cut-off; revocation list mechanism and the offline bound.
7. Activation: online endpoint (hosted by us - its own SLO/threat entry, journey J4 in `slos.md`) and the offline flow.
8. Time: grace days, clock-tamper tolerance, what "restricted" means in this product. `[always asks]`
9. Update eligibility and the security-patch policy. `[always asks]`
10. Entitlement parity: the table, and which gaps are fixed on which side.
11. Operations: issuance owner and SLA, renewal flow, support playbooks (lost licence, move host, expired in grace, offline renewal), runbook `docs/runbooks/licensing.md` and the key-compromise runbook.

A decision the user defers is `NOT DECIDED`: it goes into the model as such and
into the report. Disagreements between the two drafts are shown side by side with
the reason each gives; the user chooses.

## 3. Design rules that are not negotiable (enforced in checks L3-L14)

- Verify the signature over the **exact received bytes before parsing**; never over a re-serialised or canonicalised copy.
- The algorithm is fixed in code; there is no `alg` field to trust.
- The private signing key is never in the repo, CI variables, CI logs or a developer machine; test keypairs are generated at test time (deterministically through the runtime's test-random hook), never committed; release builds reject test keys.
- Expiry **degrades, never destroys**: login, export and backup stay available in every phase; customer data is never deleted.
- Revocation is signed and sequence-numbered; a verifier never accepts a lower sequence than it has seen.
- The only outbound call from an instance is the explicit, user-triggered activation or refresh.
- Logs and audit events carry `licence_id`, `kid`, outcome and reason code only - never the licence body, signature or customer contact data.
