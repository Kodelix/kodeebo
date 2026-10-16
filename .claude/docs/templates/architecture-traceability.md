# Architecture Traceability Index

<!-- Living document — updated by /architecture-review after each review run.
     Do not edit manually unless correcting an error. -->

## Document Status

- **Last Updated**: [YYYY-MM-DD]
- **Stack**: [e.g. Go 1.x + React SPA + Compose/SwiftUI — see `pins.yaml`]
- **Feature specs indexed**: [N]
- **ADRs indexed**: [M]
- **Last Review**: [link to docs/architecture/architecture-review-[date].md]

## Coverage Summary

| Status | Count | Percentage |
|--------|-------|-----------|
| Covered | [X] | [%] |
| Partial | [Y] | [%] |
| Gap | [Z] | [%] |
| **Total** | **[N]** | |

---

## Traceability Matrix

<!-- One row per technical requirement extracted from a feature spec.
     A "technical requirement" is any spec statement that implies a specific
     architectural decision: data ownership, tenancy, API style, performance or
     security constraint, external provider, caching, async processing, state
     persistence, cross-context communication. -->

| Req ID | Spec | Bounded Context | Requirement Summary | ADR(s) | Status | Notes |
|--------|------|-----------------|---------------------|--------|--------|-------|
| TR-[feature]-001 | [filename] | [context] | [one-line summary] | [ADR-NNNN] | Covered | |
| TR-[feature]-002 | [filename] | [context] | [one-line summary] | — | GAP | Needs `/architecture-decision [title]` |

---

## Known Gaps

Requirements with no ADR coverage, prioritised by layer (Foundation first):

### Foundation Layer Gaps (BLOCKING — must resolve before coding)
- [ ] TR-[id]: [requirement] — Spec: [file] — Suggested ADR: "[title]"

### Core Layer Gaps (must resolve before the relevant context is built)
- [ ] TR-[id]: [requirement] — Spec: [file] — Suggested ADR: "[title]"

### Feature Layer Gaps (should resolve before the feature sprint)
- [ ] TR-[id]: [requirement] — Spec: [file] — Suggested ADR: "[title]"

### Presentation Layer Gaps (can defer to implementation)
- [ ] TR-[id]: [requirement] — Spec: [file] — Suggested ADR: "[title]"

---

## Threat Model & Security Coverage

<!-- Security-sensitive requirements (auth, authz, billing, licensing, file
     upload, webhooks, PII export/delete, admin/impersonation, new integration)
     must link a threat model. -->

| Req ID | Sensitive area | Threat model | Mitigation story | Status |
|--------|----------------|--------------|------------------|--------|
| TR-[id] | [billing] | `docs/architecture/threat-models/[feature].md` | [STORY-ID] | Covered / GAP |

---

## Cross-ADR Conflicts

<!-- Pairs of ADRs that make contradictory claims. Must be resolved. -->

| Conflict ID | ADR A | ADR B | Type | Status |
|-------------|-------|-------|------|--------|
| CONFLICT-001 | ADR-NNNN | ADR-MMMM | Data ownership | Unresolved |

---

## ADR → Spec Coverage (Reverse Index)

| ADR | Title | Spec Requirements Addressed | Knowledge Risk |
|-----|-------|----------------------------|----------------|
| ADR-0001 | [title] | TR-billing-001, TR-billing-002 | HIGH |

---

## Superseded Requirements

<!-- Requirements that existed in a spec when an ADR was written, but the spec
     has since changed. The ADR may need updating. -->

| Req ID | Spec | Change | Affected ADR | Status |
|--------|------|--------|-------------|--------|
| TR-[id] | [file] | [what changed] | ADR-NNNN | ADR needs update |

---

## How to Use This Document

**When writing a new ADR**: add it to "ADR → Spec Coverage" and mark the
requirements it satisfies as Covered in the matrix.

**When approving a spec change**: scan the matrix for requirements from that spec
and check whether the change invalidates an existing ADR. Add to "Superseded
Requirements" if so (`/propagate-spec-change`).

**When running `/architecture-review`**: the skill updates this document with
the current state.

**Gate check**: the Architecture → Pre-Production gate requires this document to
exist and to have zero Foundation Layer Gaps.
