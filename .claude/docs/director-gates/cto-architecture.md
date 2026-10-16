> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-ARCHITECTURE — Architecture Sign-Off

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After the master architecture document is drafted (`/create-architecture`),
and after any major architecture revision.

**Context to pass**:
- Architecture document path (`docs/architecture/architecture.md`)
- Technical requirements baseline (TR-IDs and count)
- ADR list with statuses (`docs/architecture/`)
- Stack-risk inventory: per layer, the pinned version and known risk areas (`docs/stack-reference/<layer>/`, `pins.yaml`)
- `project.yaml` facts: `stack.*`, `tenancy.model`, `deploy.target`, `distribution.model`

**Checks**:
1. Every technical requirement in the baseline is covered by an architectural decision (an ADR, or an entry in the decision log at `minimal`): list the TR-IDs with no covering decision.
2. Every HIGH-risk stack domain is explicitly addressed or recorded as an open question with an owner.
3. API boundaries are clean, minimal and implementable: each bounded context exposes a contract in `contracts/` or a port; no context reads another's tables.
4. Foundation-layer decisions are resolved before implementation starts — tenancy model, identity/auth, data store per context, messaging, API style, deployment topology, licensing — each with an Accepted ADR.
5. Dependencies point inward (`clean-architecture.md`): domain has no framework, DB or HTTP imports; ports sit at the boundary.
6. Tenant isolation is designed in depth (app-layer scoping plus RLS or schema/DB isolation per `tenancy.model`) and each sensitive feature has a threat model path (`docs/architecture/threat-models/`).
7. Both editions are covered per `distribution.model`: hosted topology and the self-hosted bundle, including the cache, Mongo and observability licence constraints in `.claude/rules/deploy.md`.
8. Shared capabilities come from `saas-core` modules; any re-implementation of identity, OTP, storage, billing, licensing or observability is flagged.
9. Cross-cutting decisions exist for observability (OTel backend ADR), caching, and the performance budget location (`docs/architecture/perf-budgets.md`).
10. Failure modes of each external provider are addressed (timeout, retry, circuit breaker, idempotency).

**Prompt**:
> "Review this master architecture document for technical soundness. Check: (1)
> Is every technical requirement from the baseline covered by an architectural
> decision? (2) Are all HIGH-risk stack domains explicitly addressed or flagged
> as open questions? (3) Are the context and API boundaries clean, minimal and
> implementable? (4) Are Foundation-layer ADR gaps resolved before implementation
> begins? (5) Are tenant isolation, both editions and the cross-cutting concerns
> designed rather than assumed? Return APPROVE, CONCERNS [list], or REJECT
> [blockers that must be resolved before coding starts]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the architecture document, the requirements baseline or
the ADR list cannot be read. A stack reference the skill reports as absent for a
configured layer is a finding; an unreadable one is a missing input.

**Output**: the standard block, with a coverage table (TR-ID — covering decision — status) under Check 1.
