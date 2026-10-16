> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# QL-STORY-READY — QA Lead Story Readiness Check

Agent: `qa-lead` | Model tier: session (inherit) | Domain: Test strategy, acceptance criteria testability, quality gates

**Trigger**: Before a story is accepted into a sprint — invoked by `/create-stories`
and `/story-readiness`.

**Context to pass**:
- Story file path — or, from `/create-stories` (which runs this gate before any story is written), the story inline
- Story type (Logic / Integration / Contract / Security / Performance / UI / Config — `coding-standards.md`)
- Acceptance criteria list (verbatim from the story)
- The spec requirement (TR-ID and text) the story covers
- Research note path (`docs/research/<feature>.md`) and, for security-sensitive stories, the threat model path (`docs/architecture/threat-models/<feature>.md`)

**Checks**:
1. Every criterion is specific enough that a developer would know unambiguously when they are done; list criteria that use words like "fast", "secure", "user-friendly" without a number or observable.
2. Logic stories: every criterion can be verified with an automated unit test.
3. Integration stories: each criterion is observable in a controlled test environment (Testcontainers with the real Postgres / Mongo / Redis / Valkey, provider sandbox or WireMock).
4. Contract stories: each criterion maps to a path in `contracts/` and a consumer contract test.
5. Security stories: negative cases are listed — wrong role, other tenant, injection, rate limit, replay — and the ASVS / MASVS requirement IDs the story satisfies are named.
6. Performance stories: the budget (p95, queries per request, payload) is stated and a load test is named.
7. UI stories: every screen touched is listed, with the evidence expected (screenshots in Arabic/RTL and English, `/impeccable audit` result).
8. Criteria that cannot be tested until a deployed stack, real provider or store review exist are marked DEFERRED (with the condition), not BLOCKED.
9. Acceptance criteria include negative and cross-tenant cases where the story touches tenant data (spec rule in `.claude/rules/specs.md`).
10. The research note exists (DoD gate 1); a security-sensitive story has a threat model (SL-THREAT-MODEL) before it enters the sprint.

**Prompt**:
> "Review this story's acceptance criteria for testability before it enters the
> sprint. Are all criteria specific enough that a developer would know
> unambiguously when they are done? For Logic stories: can every criterion be
> verified with an automated test? For Integration stories: is each criterion
> observable in a controlled test environment? Flag criteria that are too vague
> to implement against, and flag criteria that require a deployed stack, a real
> provider or store review to test (mark these DEFERRED, not BLOCKED). Return
> ADEQUATE (criteria are implementable as written), GAPS [specific criteria
> needing refinement], or INADEQUATE [criteria are too vague — story must be
> revised before sprint inclusion]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

**NOT ASSESSED when**: the story (path or inline), its type or its criteria were
not passed or cannot be read. A missing research note or threat model that the
skill reports as absent is a finding (GAPS or INADEQUATE), not a missing input.

**Output**: the standard block, with a criteria table (criterion — verifiable how — status: ok / vague / DEFERRED).
