# ADR-[NNNN]: [Title]

## Status

[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

> **Who may move this to `Accepted`: the user, or `cto` on the user's explicit
> confirmation. No other agent, and no skill on its own.**
> Why this is stated here: stories referencing a `Proposed` ADR are set `Blocked`,
> and epics require `Accepted`, so the field needs a named owner. `cto` is the
> role `coordination-rules.md` escalates technical conflicts to, and an ADR is
> that decision made durable.
>
> This does **not** relax the rule that `Status: Accepted` is never set without
> explicit user confirmation — it narrows *which agent* may set it once that
> confirmation exists. An agent that believes an ADR is ready says so and
> escalates; it does not edit this field.

## Date

[YYYY-MM-DD — when this ADR was written]

## Last Verified

[YYYY-MM-DD — when this ADR was last confirmed accurate against the pinned stack
versions and the specs. Update when you re-read and confirm, even if nothing changed.]

## Decision Makers

[Who was involved in this decision]

## Summary

[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether to
read the full decision. Be specific: name the bounded context, the problem and
the chosen approach.]

## Stack Compatibility

| Field | Value |
|-------|-------|
| **Stack layer(s)** | [Go backend / Ktor backend / Web (Vite+React) / Marketing (Astro) / Android / iOS / KMP / Data / Deploy] |
| **Domain** | [Identity / Tenancy / Billing / Licensing / Data / API / Messaging / Caching / Observability / Security / UI / Deploy / Core] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW — in training data / MEDIUM — near cutoff, verify / HIGH — post-cutoff, must verify] |
| **References Consulted** | [e.g. `docs/stack-reference/<layer>/VERSION.md`, `breaking-changes.md`, `docs/research/<feature>.md`] |
| **Pinned versions relied on** | [library/service @ version, from `docs/stack-reference/pins.yaml`] |
| **Post-Cutoff APIs Used** | [Specific APIs from post-cutoff versions this decision depends on, or "None"] |
| **Verification Required** | [Concrete behaviours to test against the pinned versions before release, or "None"] |

> If Knowledge Risk is MEDIUM or HIGH, re-validate this ADR whenever a pin in
> `pins.yaml` changes. Mark it "Superseded" and write a new ADR if it no longer holds.

> **`Layer` is the ADR's own layer, not the referencing epic's — and it is a
> different taxonomy from `Domain`.** Several skills branch on whether an ADR is
> *critical (Foundation layer)*: `/create-stories`, `/create-epics`,
> `/architecture-decision`, `/story-readiness`, `/propagate-spec-change` and the
> pre-production gate; a missing row counts as critical. At `standard`,
> `/create-stories` **stops** for a missing critical ADR and only **warns** for a
> non-critical one. A Foundation-layer ADR (tenancy model, identity, data store,
> messaging, API style, deployment topology, licensing) is commonly referenced
> by a Core-layer epic — do not infer the layer from the referencing epic.
>
> `Domain` says *what part of the product this touches*; `Layer` says *how early
> in the build it must exist*. Do not invent a fifth `Layer` value.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint not captured above] |

## Context

### Problem Statement

[What problem are we solving? Why must this be decided now? What does not deciding cost?]

### Current State

[How does the system work today? What is wrong with the current approach?]

### Constraints

- [Technical — pinned stack versions, platform requirements, `saas-core` module in use]
- [Operational — hosted and self-hosted must both work; who runs it]
- [Timeline / team size / expertise]
- [Compatibility — existing contracts, data, customers on older versions]
- [Legal / privacy — PDPL, GDPR, data residency]

### Requirements

- [Functional requirement 1]
- [Non-functional: latency / throughput — specific, measurable]
- [Scalability: tenants, rows, requests per second]
- [Security / tenancy requirement]

## Decision

[The specific decision, in enough detail for an engineer to implement it without
further clarification.]

### Architecture

```
[Diagram-as-code (Mermaid) or ASCII showing components, data flow direction and
key interfaces, including tenant boundary and trust boundaries.]
```

### Key Interfaces

```
[Port interfaces / API contracts this decision creates. These are the contracts
implementers must respect. Link to `contracts/` where applicable.]
```

### Implementation Guidelines

[Specific guidance for the engineer implementing this: which module, which layer
of `{domain,app,adapters}`, what must never be imported where.]

## Alternatives Considered

### Alternative 1: [Name]

- **Description**: [How this approach would work]
- **Pros**: [What is good about it]
- **Cons**: [What is bad about it]
- **Estimated Effort**: [Relative to the chosen approach]
- **Rejection Reason**: [Why it was not chosen]

### Alternative 2: [Name]

[Same structure]

## Consequences

### Positive

- [Good outcomes]

### Negative

- [Trade-offs and costs we accept]

### Neutral

- [Changes that are neither good nor bad, just different]

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|

## Cross-Cutting Impact

<!-- One line each. "None" is a valid answer; blank is not. -->

| Concern | Impact |
|---------|--------|
| **Security / tenancy** | [New trust boundary? ASVS/MASVS refs? threat model needed? cross-tenant effect?] |
| **Observability** | [New spans, metrics, alerts; runbook needed] |
| **Caching** | [Cache decision or "no cache" reason] |
| **Self-hosted** | [Works offline / air-gapped? Extra services in the bundle? Upgrade path?] |
| **Cost** | [Infra cost per tenant or per request, vendor lock-in] |

## Performance Implications

| Metric | Before | Expected After | Budget (`perf-budgets.md`) |
|--------|--------|---------------|--------|
| Latency p95 (affected endpoints) | [X] ms | [Y] ms | [Z] ms |
| DB queries per request | [X] | [Y] | [Z] |
| Memory (service RSS) | [X] MB | [Y] MB | [Z] MB |
| Storage growth | [X] GB/month | [Y] GB/month | [Z] |
| Network / payload (if applicable) | [X] KB | [Y] KB | [Z] KB |

## Migration Plan

[If this changes existing systems, the step-by-step plan, including data
migrations (forward-only in production) and the self-hosted upgrade path.]

1. [Step 1 — what changes, what breaks, how to verify]
2. [Step 2]
3. [Step 3]

**Rollback plan**: [How to revert if the decision proves wrong, including data]

## Validation Criteria

[How we will know this decision was correct after implementation.]

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Performance criterion against the budget]
- [ ] [Security criterion — negative test or scan result]

## Spec Requirements Addressed

<!-- MANDATORY. Every ADR traces to at least one feature-spec requirement, or
     explicitly states it is a foundational decision with no spec dependency.
     Traceability is audited by /architecture-review. -->

| Feature Spec | Bounded Context | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| [e.g. `design/specs/team-invitations.md`] | [e.g. Identity] | [e.g. "Invite links expire after 7 days"] | [e.g. "Signed single-use tokens stored hashed, TTL enforced in the use case"] |

> If this is a foundational decision with no direct spec dependency, write:
> "Foundational — no spec requirement. Enables: [list the contexts or features
> this decision unlocks or constrains]"

## Related

- [Related ADRs — note if supersedes, contradicts, or depends on]
- [Threat model / research note / runbook links]
- [Code paths once implemented]
