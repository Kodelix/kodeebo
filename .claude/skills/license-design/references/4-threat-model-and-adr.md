# /license-design - Phases 4 and 6: Threat Model and ADR

## 1. Threat model (SL-THREAT-MODEL) - mandatory

Licensing is a sensitive area at every `workflow` tier (`security-baseline.md`
"Threat modelling"). Run `/threat-model licensing` (`docs/architecture/threat-models/licensing.md`;
`--update` if it exists) **before** the licensing stories are started. Pass it:
the research note, the draft licence model, the commercial draft, the architecture
data flow and `distribution.model`. The skill does not write the model itself.

The model must list, each with a mitigation, a **story** and a **named negative
test** (`licensing-specialist` Senior Bar):

| # | Threat | Mitigation to be shown in the model |
|---|---|---|
| 1 | Forged licence | signature over exact bytes; fixed algorithm; byte-flip tests across payload, signature, `kid`, header |
| 2 | Patched or replaced embedded public key | signed bundles; installer verifies signatures before applying; integrity at start; residual accepted |
| 3 | Activation replay to a second instance | response bound to the per-instance key and a single-use nonce; instance counting online |
| 4 | Clock rollback | persisted high-water mark; tolerance; audit event; never silently extends |
| 5 | Downgrade to an older licence with more seats | sequence/issue ordering: newer `issued_at`/`licence_id` supersedes; revocation list sequence |
| 6 | Licence sharing | binding to `installation_id`; online counting; offline sharing detectable only by audit and contract (residual) |
| 7 | Revocation evasion by blocking the network | signed revocation list via update channel; offline instance limited by `expires_at`; short terms for high-risk licences (stated bound) |
| 8 | Signing-key compromise | custody in KMS/HSM or offline; `kid` rotation; compromise runbook in `docs/runbooks/`; force-update dropping the key |
| 9 | Licence-server outage | valid unexpired licences keep working offline; retries with backoff; no hard dependency |
| 10 | Cross-tenant licence use | `customer`/tenant claim checked against the instance; hosted entitlements never read a self-hosted licence |
| 11 | Hostile input to the parser | size cap, duplicate-field rejection, unknown critical claims reject; fuzz target |
| 12 | Information leakage | no body/signature in logs; documented activation payload; telemetry off |

Residual risk (a customer who patches the binary) is stated, not hidden, and is
**accepted by a named person with an expiry date** - never by the model,
`licensing-specialist`, `security-lead` or `cto` on the company's behalf.
Requirement IDs (ASVS 5.0.0, Level 3 for licensing) are looked up in the official
document by `/threat-model`; this skill recalls none.

Record the gate verdict (APPROVE / CONCERNS / REJECT / NOT ASSESSED). REJECT is
`BLOCKED`; NOT ASSESSED is `NOT ASSESSED`; CONCERNS is `COMPLETE WITH GAPS` at best.
In `lean` or `solo` the gate runs inside `/threat-model` per its own rules; this
skill records what `/threat-model` reports, and never records a gate as passed
that did not run.

## 2. ADR (CTO-ADR)

A licensing ADR is a **critical ADR**. Prepare for `/architecture-decision` (do
not write the ADR file yourself):

- **Title:** "Self-hosted licence format, verification and key custody"
- **Problem:** what must be enforced offline, by whom, against which threats
- **Decision:** envelope and claims, algorithm and library per runtime (with versions
  from `pins.yaml`/the research note), key custody and rotation, activation
  model, time and grace policy, update-eligibility rule, entitlement parity port
- **Alternatives rejected, each specific to this product:** random keys checked
  against a database (needs a server, fails air-gapped); JSON re-serialised then
  verified; hardware fingerprints; a CI-held signing key; a remote kill switch
  over customer data; a separate feature-flag vocabulary for licences
- **Consequences:** what becomes harder (offline revocation latency bounded by
  `expires_at`, rotation ceremonies, installer coupling to the manifest), what must
  be revisited and when
- **Effect on both editions:** hosted uses billing entitlements; self-hosted uses
  the licence; one `Entitlements` port with two adapters
- **Links:** research note, threat model, spec requirements (TR-IDs) it covers, the
  core module

`CTO-ADR` runs inside `/architecture-decision` (the agent reads the gate file; this
skill does not). The ADR is moved to `Accepted` only by the user, or by `cto` on the
user's explicit confirmation; this skill never edits that field. At
`workflow: minimal`, write the same decision into the decision log of
`design/product-brief.md` (with approval) and report `CTO-ADR not required at
minimal`.
