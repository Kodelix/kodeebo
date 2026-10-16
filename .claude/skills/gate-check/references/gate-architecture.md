> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Product Design → Architecture


**Required Artifacts:**
- [ ] Domain map exists at `design/specs/domain-map.md` with the MVP features enumerated, grouped into bounded contexts, with a design order and a mapped dependency graph
- [ ] All MVP feature specs exist in `design/specs/` and individually pass `/spec-review`
- [ ] A cross-spec review report exists in `design/specs/` (`spec-cross-review-[date].md`, from `/review-all-specs`)
- [ ] The plan, pricing and entitlement model is specified: `design/specs/pricing-model.md` (or the path the brief links; `Glob design/**/pricing-model*.md`; template `.claude/docs/templates/pricing-model.md`), consistent with the brief
- [ ] For `distribution.model: self-hosted` or `hybrid`: the pricing model carries the commercial licence terms (its "Licence Terms for Self-Hosted" section — what is licensed, renewal, offline grace, the update channel). The technical licence model (`docs/architecture/licence-model.md`) belongs to the Architecture stage and is checked at the next gate
- [ ] Entity registry `design/registry/entities.yaml` holds the plans, roles, permissions, quotas and events the specs reference (`/consistency-check`)
- [ ] Security-sensitive features (auth, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, new external integration) are **identified** in the domain map or their specs, so the Architecture stage knows which need a threat model

**Quality Checks:**
- [ ] All MVP specs pass individual review: required sections present at their effective tier (spec-structure-check), no MAJOR REVISION NEEDED verdict
- [ ] `/review-all-specs` verdict is not FAIL (contradictions, permission/plan conflicts, tenancy and data-ownership clashes). A NOT ASSESSED verdict does not satisfy this: that review could not compare the specs, so this item is NOT ASSESSED for the gate
- [ ] All cross-spec issues flagged by `/review-all-specs` are resolved or explicitly accepted
- [ ] Feature dependencies are mapped in the domain map and are bidirectionally consistent; no circular dependency between bounded contexts without an accepted reason
- [ ] The MVP tier is defined and matches the brief's MVP list; every spec traces to a job-to-be-done
- [ ] Each spec's Non-Functional Requirements section states security (ASVS/MASVS references), a performance budget, a caching decision, observability (spans, metrics, alerts), accessibility and localization (Arabic/English, RTL) — spot-read the sections the verdict turns on; an empty heading is not a section
- [ ] Each spec's Acceptance Criteria include negative and cross-tenant cases
- [ ] No stale references: older specs updated to reflect decisions made in later ones (`/propagate-spec-change`)
- [ ] PD-FEATURES and CTO-CONTEXT-BOUNDARY recorded for the domain map; PD-SPEC-ALIGN recorded per spec (where review mode ran them)
- [ ] The stack is configured or the decision to configure it first is explicit: `/create-architecture` works against the stack reference, so `/setup-stack` must have run before it. Run `bash .claude/scripts/project-coherence.sh` and report its lines (informational at this gate: `ABSENT` is expected before code exists; a `SKIPPED` line is reported as not run, and `pins.yaml` missing is NOT ASSESSED for the stack item)

## Floors at every tier

Even where a spec section is optional or the whole spec is dropped, the
research note per feature before its code (`docs/research/<feature>.md`) and
the eight DoD gates still apply later; this gate does not waive them.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — domain map + all MVP specs at all 8 sections + cross-spec review report + pricing model (with licence terms for self-hosted/hybrid) + entity registry all required
- **`standard`** — MVP specs validated at the **5 required sections** (+ Edge Cases & Failure Modes where the feature calls an external provider, moves money, changes entitlements or runs asynchronously); cross-spec review report → recommended; entity registry → recommended; pricing model required only if the brief's pricing model is not a single flat price; the licence terms in the pricing model stay required for self-hosted/hybrid
- **`minimal`** — **gate not applicable** — there is no gate between the brief and code; auto-PASS with a note (see below)

> **`minimal` "not applicable" gate.** The Product Design → Architecture gate
> has no meaning at `minimal` (no domain map or specs exist by design). Return a
> PASS verdict with the note: *"No design gate at minimal workflow — minimal
> skips the Product Design stage; advancing brief → architecture."* The Section 6
> stage write still applies on user confirmation. Do NOT flag absent specs as
> blockers. This is the named exception to Section 2b's rule that a gate with no
> required artifacts left may not PASS; the director panel does not run for it.
>
> **Exception to the exception:** if `workflow_overrides.system_overrides` pins a
> feature above `minimal`, the gate is not a bare auto-PASS for that feature —
> check its spec at the pinned tier (Section 2b "Per-feature overrides") and run
> the unmatched-key check. Every other feature stays unchecked.

## Director gates at this transition

The PHASE-GATE panel (Section 4b) runs at the width `workflow` sets (not at
`minimal` unless an override lifted the exemption). Recorded, not re-spawned:
PD-FEATURES, CTO-CONTEXT-BOUNDARY, PR-SCOPE, PD-SPEC-ALIGN (per spec).
