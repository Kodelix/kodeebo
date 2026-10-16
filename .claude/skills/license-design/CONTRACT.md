# /license-design - Handoff Contract

## Role in Pipeline
Designs the self-hosted licence mechanism before any licensing code exists.
Called by `/team-billing` (pricing -> entitlements -> billing integration ->
licence enforcement), `/design-spec` and `/create-architecture` (routing, when a
self-hosted edition exists), `/studio`. Reads and feeds `/threat-model`,
`/architecture-decision`, `/research`, `/core-use`, `/core-extract`,
`/create-stories`, `/security-audit selfhosted`, `/pentest`, `/release-checklist`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| `distribution.model` via `resolve_config` (`stack`) | Yes (unset = asked, then NOT ASSESSED) | Yes |
| `design/specs/pricing-model.md` "Licence Terms for Self-Hosted", entitlement catalogue | For terms and parity (absent = NOT DECIDED / NOT ASSESSED) | Yes |
| `docs/research/licensing.md` | Produced in Phase 2 | Written by `researcher` |
| `saas-core-<track>` licensing module docs | For the core-first check (unreachable = NOT ASSESSED) | Yes |
| `deploy/self-hosted/`, installer and release-manifest format | For update eligibility and bundle signing | Yes |
| `.claude/docs/templates/licence-model.md`, `security-baseline.md`, `rules/security-sensitive.md`, `rules/deploy.md` | Yes | Yes |

## Preconditions
- The product has, or is planning, a self-hosted edition
- No key material is in the conversation, the repository or CI

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. SL-THREAT-MODEL: REJECT ->
BLOCKED, CONCERNS -> COMPLETE WITH GAPS at best, NOT ASSESSED -> NOT ASSESSED.
CTO-ADR: REJECT -> COMPLETE WITH GAPS at best until revised, NOT ASSESSED -> NOT
ASSESSED.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/research/licensing.md` | nine sections; per-runtime library options with sourced verification behaviour or `NOT SOURCEABLE` | by `researcher` to the approved path |
| `docs/architecture/licence-model.md` | all template sections; one claim name for update eligibility; parity table; every undecided term `NOT DECIDED`; placeholder values marked as placeholders | after approval |
| `docs/architecture/threat-models/licensing.md` | via `/threat-model`; the 12 licensing threats with story and negative test | not written here |
| ADR / decision log entry | via `/architecture-decision` (`standard`/`full`) or the brief (`minimal`) | `Accepted` only by the user or `cto` on the user's confirmation |
| `production/qa/license-design-[date].md` | decisions, checks L1-L17, gate verdicts, Security story list, Not run list | after approval |

## Output Guarantees
- No key material, licence body, signature, customer data or secret appears in any output
- Every cryptographic or library statement cites the research note or is `NOT SOURCEABLE`
- Every commercial term has a decision owner or is `NOT DECIDED`
- The honest residual risk is stated and accepted by a named person with an expiry, or listed as open

## Immutability Rules
- Never edits code, `saas-core-*`, `pricing-model.md`, CI, deploy files or the installer
- Never sets an ADR to Accepted, accepts a risk, or decides price, term, grace or maintenance
- Draft files under `production/session-state/` are removed only with approval

## Hard Constraints (Never Violate)
- Never generates, requests, stores or prints a private key, seed or test key
- Never designs verification over re-serialised bytes, an `alg` field, a CI-held signing key, a hardware fingerprint, a default-on outbound call, or a lock-out that blocks data export
- Never recalls a library API, key size, encoding or requirement ID

## Downstream Skill Expects
- `/create-stories`: the Security story list with a named negative test per mitigation
- `/story-readiness`: the research note and threat model paths for each licensing story
- `/team-billing`: the parity table and the single `Entitlements` port
- `SL-RELEASE-SECURITY` / `/pentest`: the threat model and licence model as scope input

## Known Fragile Points
- The stack reference documents no Ed25519 library APIs; library choice depends entirely on the research note
- The cores are built after the studio: until the licensing module exists the model is its specification
