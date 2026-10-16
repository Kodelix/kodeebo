> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PE-DOD — Definition of Done Evidence Review

Agent: `principal-engineer` | Model tier: session (inherit) | Domain: Code-level architecture, standards, review

**Trigger**: `/story-done`, for each story before it is marked Complete. It is
the independent review of the evidence `/story-done` has already collected for
the eight gates in `coding-standards.md`. Skipping this gate (review mode)
never waives a gate: `/story-done` still checks all eight itself
(`director-gates.md` → Review Modes).

**Context to pass**:
- Story file path (story type, acceptance criteria, recorded waivers)
- Evidence directory `production/qa/evidence/<story-id>/`
- Research note (`docs/research/<feature>.md`)
- Implementation paths and the governing ADR(s) in `docs/architecture/`
- Budget file `docs/architecture/perf-budgets.md`; threat model path for sensitive stories
- Gate levels resolved from `testing.strict.*` and `performance.enforce` in `project.yaml`
- Verdicts already recorded in the story header for PE-CODE-REVIEW, QL-TEST-COVERAGE, SL-TENANT-ISOLATION and SL-THREAT-MODEL, if they ran

**Checks** (one per DoD gate; each row cites the artifact and `file:line`, or the number measured):
1. **Research first** — `docs/research/<feature>.md` exists, dated before the first implementation commit; it cites primary sources, pinned versions, and alternatives rejected with a reason (`research-protocol.md`). Unsourceable items say `NOT SOURCEABLE`.
2. **Clean architecture** — the domain package has no framework, DB or HTTP imports; dependencies point inward; ports at the boundary (`clean-architecture.md`). Cite the PE-CODE-REVIEW verdict, or check the imports directly if it was skipped.
3. **Tests** — the evidence required for the story's type is present and passing (`coding-standards.md` → Test evidence by story type; `testing-standards.md`): unit on domain and use cases; Testcontainers integration on the real dependency; contract test against `contracts/`. Cite the QL-TEST-COVERAGE verdict, or check directly if it was skipped.
4. **Observability** — every new endpoint, consumer and job emits a span, RED metrics and structured logs carrying `trace_id`; no PII in telemetry; one retained trace in the evidence directory for a user-visible or callable change (`observability-standard.md`).
5. **Caching** — a written cache decision exists (pattern, key schema, TTL, invalidation, stampede protection) or a written reason for no cache (`caching-standard.md`).
6. **Performance** — the story meets the budget in `perf-budgets.md` (p95 latency, queries per request, payload size); no N+1 (a query-count assertion); hot paths have a load-test result in the evidence directory with environment and data volume (`performance-standard.md`).
7. **Security** — the ASVS / MASVS requirement IDs satisfied are listed; negative tests (authz, cross-tenant, injection, rate limit) pass; a threat model exists for sensitive stories; the dependency scan is clean (`security-baseline.md`). Cite SL-THREAT-MODEL and SL-TENANT-ISOLATION verdicts where applicable.
8. **Decision record** — an ADR (or, at `workflow: minimal`, a decision-log entry in `design/product-brief.md`) exists for every architectural decision the story made; none is made without a record (`workflow-modes.md`).
9. **Run and observe** — for any change a user can see or call, the observation is retained in `production/qa/evidence/<story-id>/` (`run-and-observe.md`): endpoint calls per role, screenshots including Arabic/RTL, a trace.
10. **Waivers** — every gate not met has a written reason in the story file approved by the user; a waiver without both is treated as unmet. Security evidence on a security-sensitive story cannot be waived by the model.

Gate level per row: BLOCKING or ADVISORY from the resolved `testing.strict.*` / `performance.enforce` values (defaults in `coding-standards.md`). Security evidence on a security-sensitive story is always BLOCKING.

**Prompt**:
> "Review this story's Definition of Done evidence. For each of the eight gates
> — research, clean architecture, tests, observability, caching, performance,
> security, decision record — is the evidence present, dated, passing and
> sufficient for the story type? Is run-and-observe evidence retained? Is every
> unmet gate covered by a written, user-approved waiver? Where an earlier gate
> verdict was skipped by review mode, did you check the underlying evidence
> yourself? Return APPROVE (all eight gates met or validly waived), CONCERNS
> [ADVISORY gates unmet or evidence weak], or REJECT [a BLOCKING gate is unmet
> and not validly waived — the story is not Done]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the story file or the evidence directory cannot be read,
or the gate levels could not be resolved from `project.yaml`. A gate whose
evidence could not be opened is `not checked` and is never counted as met.
A gate the skipped review mode left unreviewed is still checked here from the
evidence.

**Output**: the standard block, where the Checks table has exactly eight DoD rows (Gate — Level — Status: met / waived / unmet / not checked — Evidence / gap), followed by the Run-and-observe and Waivers rows, and the `Not checked` list.
