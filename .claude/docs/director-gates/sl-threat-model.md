> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SL-THREAT-MODEL — Threat Model Adequacy

Agent: `security-lead` | Model tier: session (inherit) | Domain: Security baseline, threat models, ASVS/MASVS mapping

**Trigger**: Before any story touching a sensitive area is implemented, and
whenever its threat model is written or revised. Sensitive areas
(`security-baseline.md` → Threat modelling): authentication, authorization
model, billing, licensing, file upload, webhooks, PII export/delete,
admin/impersonation, or a new external integration. Invoked by `/threat-model`
(after it writes the model), by `/story-readiness` and `/dev-story` for
sensitive stories, and by `/create-architecture` for sensitive features. Per
feature at `workflow: full` and `standard`; at `minimal` the research note
carries the threat analysis, but a sensitive story still needs this gate.

**Context to pass**:
- Threat model path (`docs/architecture/threat-models/<feature>.md`)
- Feature spec path (`design/specs/<feature>.md`) and the story or stories it covers
- Architecture data-flow and trust boundaries (`docs/architecture/architecture.md`)
- Research note (`docs/research/<feature>.md`) with the ASVS / MASVS / API Top 10 requirement IDs looked up
- `tenancy.model`, `distribution.model` and `stack.*` from `project.yaml`
- Related ADRs (identity, tenancy, licensing)

**Checks**:
1. A threat model exists for every sensitive area the feature or story touches (list each area and the model section that covers it).
2. Assets, actors, entry points and trust boundaries are named, with a data-flow description; STRIDE is applied to each element crossing a boundary (cite the table).
3. Abuse cases are listed for business flows, not only technical ones: trial abuse, coupon stacking, seat inflation, quota evasion, replayed webhooks, licence sharing, account enumeration.
4. Cross-tenant threats are covered explicitly (guessing IDs, shared caches and queues, search, exports, background jobs, admin and impersonation paths).
5. Every threat has a mitigation, and every mitigation maps to a requirement ID in ASVS 5.0.0 (Level 2; Level 3 for authentication, billing, licensing), MASVS 2.1.0 for mobile, or API Security Top 10 2023 — IDs taken from the official documents via the research note, not recalled.
6. Every mitigation is linked to a story and a negative test (bypass, cross-tenant, replay, brute force / rate limit, expired or forged token, injection) that will prove it.
7. Residual risk is recorded by name with an owner and an expiry date, and was accepted by the user — not by the model, `security-lead` or `cto` on the company's behalf.
8. Secrets, keys and sensitive-data handling are addressed: where each key lives (KMS / offline signing key for licences), rotation, logging exclusions (`security-baseline.md` → Secrets, Errors & logging).
9. External integrations list their failure and compromise modes (provider outage, forged callbacks, SSRF through user-supplied URLs).
10. Personal data flows name their legal basis and retention with `privacy-compliance-specialist` (PDPL / GDPR) where PII is involved.

**Prompt**:
> "Review this threat model for adequacy before the feature is implemented. Does
> it cover every sensitive area the feature touches? Are trust boundaries and
> abuse cases explicit, including cross-tenant paths? Does every threat have a
> mitigation mapped to a verified ASVS / MASVS / API Top 10 requirement and
> linked to a story and a negative test? Is residual risk named with an owner
> and expiry? Return APPROVE (implementation may begin), CONCERNS [specific
> gaps to close during the stories], or REJECT [the model is missing or too thin
> to guide implementation — do not start the sensitive story]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the threat model file exists but cannot be read, or the
spec or architecture data-flow it must be checked against cannot be read. A
threat model the skill reports as absent for a sensitive story is a finding
(REJECT), not a missing input.

**Output**: the standard block, with a threat table (threat — mitigation — requirement ID — story — negative test) and an accepted-residual-risk list (risk — owner — expiry).
