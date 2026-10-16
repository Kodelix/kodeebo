# /dev-story — Phase 5: Implement

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Implement

Spawn `principal-engineer` via `Agent` with the full context package and the
lane plan from Phase 3. `principal-engineer` designs the module boundaries
(port list, composition root, `domain`/`app`/`adapters` placement) **before** any
implementation, then delegates each lane to its lead in the order Phase 3 fixed,
and integrates the results. (Config stories skip this phase — Phase 3 Step 3.)

Brief the agent with file paths and targeted reading instructions — do not
serialize document content into the `Agent` prompt. The agent reads what it
needs directly.

> **Tier note (from Phase 2):** items 2–4 below assume the `full` baseline. At
> `standard`, include the TR registry only if it exists and the governing ADR
> only where the story references one — at any tier, a story whose ADR field
> reads `N/A` has no item 3. At `minimal`, the TR registry, ADR and control
> manifest are typically absent — **omit items 2–4 and brief the agent to
> implement against the story's Acceptance Criteria and the spec/brief** (the
> story file from item 1). **Items 5–10 are never omitted at any tier.** Never
> instruct the agent to read a file Phase 2 confirmed missing.
>
> **Say which items you dropped, and say it to both readers.** *An omitted item
> and a forgotten one are indistinguishable to the agent.* They are equally
> indistinguishable to the user reading the Phase 7 summary.
> - **To the agent**, in the prompt: *"No TR registry entry is passed for this
>   story — `docs/architecture/tr-registry.yaml` does not exist at this tier.
>   Implement against the story's Acceptance Criteria and the spec/brief. Do not
>   go looking for it."* Same form for an absent ADR or control manifest.
> - **To the user**, one line before spawning: `Briefing omits: TR registry
>   (absent), ADR guidance (story references no ADR), control manifest
>   (absent) — implementing against acceptance criteria + spec.`

1. **Story file**: `[story-path]` — the agent reads this one file; it carries the acceptance criteria, Out of Scope boundaries, QA test cases and the DoD table.
2. **Spec requirement**: look up TR-ID `[TR-XXX-NNN]` in `docs/architecture/tr-registry.yaml` — use the `requirement` field as source of truth.
3. **ADR guidance**: pass the story's `**ADR Decision Summary**` and `## Implementation Notes` **inline in the prompt** — do not pass the ADR path. Phase 2 already established that this summary is current; handing the agent a path makes it re-read the whole ADR in its own context. After mismatch option `[A]`, pass the guidance freshly read from the ADR's `## Decision`, never the stale summary; after `[B]`, pass the story's summary and tell the agent it predates the current ADR.
4. **Control manifest**: `docs/architecture/control-manifest.md` — read rules for the **[layer/context]** only.
5. **Research note**: `docs/research/[feature].md` — the agent reads its Versions, Decision, Security notes, Performance & caching notes and Observability notes before designing; `NOT SOURCEABLE` items are not to be filled from memory. (Or the exemption row, stated.) If implementation would contradict the note: **update the note first, then the code**, and tell the user.
6. **Threat model** (sensitive stories): `docs/architecture/threat-models/[feature].md` and the rows this story owns, each with its ASVS/MASVS ID and its negative test. Every row is a mandatory test case and a mandatory code check. Security-sensitive paths (`.claude/rules/security-sensitive.md`) also get `appsec-engineer` at review.
7. **Stack reference and rules**: for each lane, `docs/stack-reference/<layer>/` (all four files), `docs/stack-reference/pins.yaml`, and the `.claude/rules/*.md` files whose `paths:` match. The reference wins over memory for every API, flag, config key and version. Include the Phase 2 stack-risk instruction when the layer is HIGH / `NOT ASSESSED`. Also: `deprecated-apis.md` entries are forbidden unless the ADR says otherwise.
8. **Evidence plan** (Phase 4, as approved) and the test-first sequence. Tests are written **alongside**, and for Logic stories **before**, the implementation — never deferred. Each acceptance criterion has at least one test covering it; each negative/cross-tenant criterion has its own. The tests exist and pass at every `qa.level` (Logic, Integration, Contract and Security are BLOCKING at every tier); `qa.level` only adds extra evidence. Test naming and rules: `.claude/rules/test-standards.md` and `.claude/docs/testing-standards.md` (deterministic, isolated, real dependencies for integration, no skips).
9. **Senior-bar instruction** (the standards the code is held to — `coding-standards.md`, `clean-architecture.md`, `api-standards.md`, `security-baseline.md`):
   - `domain` imports nothing outward; ports declared by the consumer (`app`); wiring only in the composition root; transactions owned by the use case.
   - Doc comments on every exported/public API stating contract and failure modes.
   - No hardcoded business values (prices, limits, quotas, TTLs, timeouts, flags) — config/database with typed defaults.
   - Dependency injection over singletons and globals; every use case constructible in a test with fakes.
   - Errors as values with context, wrapped with cause; mapped to RFC 9457 problem details at the HTTP edge only; no internals or stack traces to clients.
   - Every external call: timeout, retry policy (idempotent calls only), circuit breaker or bulkhead where failure can cascade. Every repeatable write idempotent.
   - Every query tenant-scoped, the tenant taken from the authenticated context, never from the request body; RLS (or schema/DB isolation) per `tenancy.model` backing the app-layer predicate.
   - Secrets never in code, logs, URLs or client bundles. No PII in telemetry.
   - Every endpoint/consumer/job: OTel span, RED metrics, structured logs carrying `trace_id`. Health endpoints on new services.
   - Shared capabilities (identity, OTP, storage, billing, licensing, observability) come from `saas-core` — never re-implemented in the product; a gap goes upstream (`/core-extract`), not into a local copy.
   - Migrations forward-only in production, reversible in development, no unplanned lock on a hot table.
10. **Explicit instruction**: implement this story following the ADR guidelines, respect the manifest rules, stay within the story's Out of Scope boundaries; return a report that lists files created/modified, commands run **with their real output summary**, and any check that could not run **as `not run — [reason]`**.

The agent should:
- Create or modify files only under the **resolved code roots** (Phase 2, `resolve_code_root`); **if a code root cannot be resolved, do not write: report it and stop.**
- Respect all Required and Forbidden patterns from the control manifest.
- Stay within the story's Out of Scope boundaries (do not touch unrelated files).
- Never weaken, skip or delete a test, a rule or a gate to make work pass.
- Surface — not decide — any architectural choice the ADRs do not cover, and any need to touch `saas-core`, CI/CD or `deploy/` files outside its lane.

### Lane sequencing and hand-offs

- **Contract lane first**: `api-designer` writes/updates `contracts/` and the breaking-change check; downstream lanes receive the merged operation, never a draft. The contract change is reviewed (`.claude/rules/contracts.md`) before the clients start.
- **Data lane**: `data-lead` produces the migration (forward-only in production; up on empty and on seeded DB; `.claude/rules/migrations.md`), RLS policies for new tenant-owned tables, and the index each new query uses, before the backend lane relies on them. The migration passes `bash .claude/scripts/migration-lint.sh` (Phase 6).
- **Backend lane**: use cases, adapters and handlers on the ports; the lead returns the plan for each endpoint's span/metrics/logs.
- **Client lanes**: consume only the merged contract (generated client); authorization in the client is UX only.

After each lane returns, verify its artifact exists on disk (Error Recovery Protocol) before spawning the next.

### UI stories

For `Type: UI`, implementation follows Phase 3 Step 4: `ui-designer` first, then the lead briefed with its output. The *look* half of the acceptance criteria — layout, clipping, RTL mirroring, states (loading/empty/error), contrast — is verified in Phase 6 by running the screen and retaining screenshots; it is not deferred. The *feel* half — motion timing, perceived responsiveness — is not something a still shows: say which half the run covered and leave feel to `/team-qa`.

---
