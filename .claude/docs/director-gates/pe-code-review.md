> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PE-CODE-REVIEW — Principal Engineer Code Review

Agent: `principal-engineer` | Model tier: session (inherit) | Domain: Code-level architecture, standards, review

**Trigger**: After a story is implemented (`/dev-story`, `/story-done`), or as
part of `/code-review`. Code-level review; evidence completeness for all eight
DoD gates is PE-DOD.

**Context to pass**:
- Implementation file paths (every code root touched: `backend/`, `web/`, `mobile/`, `contracts/`)
- Story file path (for acceptance criteria and story type)
- Relevant spec section (`design/specs/<feature>.md`)
- ADR(s) that govern this area, and the control manifest if it exists
- Test paths and `production/qa/evidence/<story-id>/` if present

**Checks**:
1. The code satisfies each acceptance criterion; map criterion to code and test (`file:line`).
2. Clean architecture holds (`clean-architecture.md`): the domain package imports no framework, DB or HTTP package; dependencies point inward; ports sit at the boundary. List any import that breaks this.
3. No violation of the governing ADR or a forbidden pattern in the control manifest or `.claude/rules/` for the layer.
4. Public APIs are documented with contract and failure modes (`coding-standards.md`) and constructible in a test with fakes (dependency injection, no singletons or globals).
5. Correctness against the spec rules: each rule that applies has a code location; edge cases and failure modes in the spec are handled.
6. Every query is tenant-scoped, and the tenant comes from the authenticated context, never from the request body.
7. Errors are values with context; mapped to RFC 9457 at the HTTP edge only; no internals or stack traces leak to clients.
8. Every external call has a timeout, a retry policy (idempotent calls only) and a circuit breaker or bulkhead where failure can cascade; every repeatable write is idempotent.
9. No hardcoded business values (prices, limits, quotas, TTLs, timeouts, flags) in code.
10. Shared capabilities (identity, OTP, storage, billing, licensing, observability) are consumed from `saas-core`, not re-implemented.
11. Observability and security code are present where the story requires them (span, RED metrics, structured log with `trace_id`; authorization check before side effects; no secrets or PII in logs).
12. Migrations in the change are forward-only for production and take no unplanned lock on a hot table.

**Prompt**:
> "Review this implementation against the story acceptance criteria, the
> governing ADR and the coding standards. Does the code match the architecture
> boundary definitions? Are there violations of the coding standards or
> forbidden patterns? Is the public API testable and documented? Are there any
> correctness issues against the spec rules? Return APPROVE, CONCERNS [specific
> issues], or REJECT [must be revised before merge]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the story file, the implementation paths or the governing
ADR for the area cannot be read. Tests that were not run are reported as not
run; they are not assumed green.

**Output**: the standard block, plus the agent's DoD table (Gate — Status — Evidence / gap) filled for the gates judgeable from the diff (2, 3, 4, 5, 6, 7, 8); for gates not judgeable from code, write `see PE-DOD`. Findings use the `[BLOCKER|MAJOR|MINOR] path:line` form and a `Not checked` list.
