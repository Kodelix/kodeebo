# /story-done — Phase 6: The Eight DoD Gates (PE-DOD)

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: The Eight DoD Gates (PE-DOD)

A story is not Done until each of the eight gates in
`.claude/docs/coding-standards.md` is met **or explicitly waived with a written
reason in the story file**. This phase assembles the eight-gate table from the
evidence Phases 3–5 collected, with a path or a number in every row — the same
table whether or not a director reviews it.

**In this file:**

- Build the eight-gate table
- Resolve unmet gates: fix, waive, or override
- The PE-DOD gate

### Build the eight-gate table

For each gate, fill **Level** (BLOCKING / ADVISORY from the Phase 3 resolution;
Security evidence on a sensitive story always BLOCKING), **Status** (`met` /
`waived` / `unmet` / `not checked`) and **Evidence / gap** (a path with `file:line`
or a measured number). A gate whose evidence could not be opened is
`not checked` and is **never counted as met**. A check that did not run is `not
run`, and a BLOCKING gate resting on it is `not checked` — **not** `unmet`: `unmet` means evidence was
checked and is absent or failing (→ BLOCKED); `not run` / `not checked` means nobody could tell (→ NOT ASSESSED for that
gate and for the overall verdict, outranking COMPLETE and never read as a pass).

| # | Gate | Met when (cite the artifact) | Evidence path |
|---|------|------------------------------|---------------|
| 1 | **Research first** | `docs/research/<feature>.md` exists, is `Status: Complete` (a `Draft` note needs the user's recorded acceptance of its named gaps — the story's `Research gap accepted:` line — else the gate is `unmet`), and is **dated before the first implementation work**: by the **Dating rule** (`2-read-story.md`) — first-commit dates when both the note and the earliest implementation file are committed; otherwise the note's `Date:` line against the story's `Started:` line (set by `/dev-story`), or the note's mtime against the oldest new implementation file's mtime (weaker; say so); no usable source is `not checked`, never `met`; cites primary sources, pinned versions (matching `docs/stack-reference/pins.yaml`), and alternatives rejected with a reason; unsourceable items say `NOT SOURCEABLE`. Or the story's exemption row is valid for its content (`research-protocol.md`). A note written *after* the code is `unmet` (research-first is the gate) | the note path + the dates compared and the `freshness source:` |
| 2 | **Clean architecture** | the domain package has no framework/DB/HTTP imports (the grep result — from `/code-review` or run now: `domain` imports); dependencies point inward; every external dependency of a use case is a port; no cross-context table reads; adapters constructed only in the composition root | `code-review.md` / grep output with `file:line` |
| 3 | **Tests** | the evidence for the story type is present **and passing** (Phase 3 "Test results"): unit tests on domain + use cases; Testcontainers integration tests on the real dependency; contract tests against `contracts/`; the by-change cases of `testing-standards.md` (use case: happy, each domain error, authz denied, tenant mismatch; repository: round trip/not-found/constraint/tenant isolation/pagination; cache: hit/miss/invalidation/TTL/cache-down; provider: success/4xx/5xx/duplicate webhook/bad signature; endpoint: contract + anonymous/wrong role/wrong tenant); deterministic, no skipped tests; coverage signal (≥ 85 % domain + app) at `qa.level: full` (extra evidence — the tests themselves are required at every tier) | `checks-<layer>.md` + test paths |
| 4 | **Observability** | every new endpoint, consumer and job emits a span, RED metrics and structured logs carrying `trace_id`; no PII in telemetry; **one retained trace** in the evidence directory for a user-visible or callable change | trace file in the folder + the code locations (`file:line`) |
| 5 | **Caching** | a written cache decision (pattern, key schema with tenant ID, TTL with jitter, invalidation, stampede protection, failure mode) in the spec/research note/ADR — **or** a written reason for no cache. If the story added a cache adapter: its hit/miss/invalidation/TTL/cache-down/tenant-isolation tests passed | the decision's path + test results |
| 6 | **Performance** | the story meets the surface's budget in `perf-budgets.md` (p95 latency, queries per request, payload size) with a measurement; no N+1 (a query-count assertion); a hot path has a load-test result in the folder with environment and data volume. A missing budget row is `budget not yet set` → the gate is `not checked` (cannot be `met`); level per `performance.enforce` | load-test file + budget row |
| 7 | **Security** | the ASVS / MASVS requirement IDs satisfied are listed (from the threat model/research note); negative tests (authz, cross-tenant, injection, rate limit) pass; the tenant-isolation test passes on tenant-owned data (SL-TENANT-ISOLATION verdict, or the Phase 3/4 evidence if skipped); a threat model exists for a sensitive story (SL-THREAT-MODEL verdict recorded, or `skipped — <mode> mode`; a skipped director opinion is not a skipped check — in **every** review mode this phase reads the model's `Status:` and its section 7 *Residual Risk — Accepted by Name*: each residual row needs a named acceptor, date and review-by date, or the model states there is none; `Needs update`, or an unaccepted residual row, makes gate 7 `unmet` and it cannot be waived by the model); the dependency scan is clean (`govulncheck` / `osv-scanner` / `pnpm audit` output — `not run` if the tool is absent); no secrets (gitleaks / grep); `appsec-engineer` review recorded for security-sensitive paths | ASVS table, test output, scan output |
| 8 | **Decision record** | an ADR (or, at `workflow: minimal`, a decision-log entry in `design/product-brief.md`) exists for **every architectural decision the story made** — new data store, broker, framework, engine-specific cache feature, tenancy deviation, new context boundary, a deviation from an Accepted ADR. A decision visible in the diff with no record is `unmet` | ADR path / decision-log line |
| — | **Run and observe** | the observation is retained in `production/qa/evidence/<STORY-ID>/` for anything a user can see or call (Phase 3 "Run-and-observe record"): API calls per role incl. the negative path, screenshots incl. Arabic/RTL, one trace | the folder listing |

Rules for filling the table:
- Quote numbers, not impressions: "p95 112 ms vs 150 ms budget", "5 queries/request (budget ≤ 5)", never "fast enough".
- A gate that does not apply to this story type (e.g. caching on a pure Config change) is `met — n/a: [reason]`; "n/a" without a reason is `not checked`.
- The recorded `## Definition of Done Evidence` table in the story is updated in Phase 8 from this table (its `Status` boxes).

### Resolve unmet gates — fix, waive, or override

For each gate that is **unmet** or **not checked**:

- **ADVISORY level** → note it in the Completion Notes; the user may also ask to fix first.
- **BLOCKING level** → the verdict cannot be COMPLETE (Phase 7). Offer three routes via `AskUserQuestion` (major decision):
  - `[A] Fix it first — list what is needed` (default; nothing is written)
  - `[B] Record a waiver — I will state the reason` (user-authored)
  - `[C] Stop`
- **A waiver is a written reason in the story file, approved by the user.** The user states the reason; this skill records it verbatim in `## Completion Notes` under `Waivers:` as `Gate [N] — [reason] — approved by [user] on [date]`. A waiver without both a reason and an approval is treated as unmet. The model never drafts a justification on the user's behalf and never infers a waiver from a "yes, close it".
- **Security evidence on a security-sensitive story cannot be waived by the model.** Do not offer `[B]` for gate 7's negative tests, ASVS mapping, threat model or tenant-isolation proof on such a story. The only path past it is the explicit close-anyway override in Phase 8 (`scope_changes` always-ask), and it requires the residual risk to be **named with an owner and an expiry date**, accepted by the user (not by the model, `security-lead` or `cto` on the company's behalf), and logged as security debt via `/tech-debt`.
- **Gate 1 (research first) with no note at all** — for a feature that introduced a new provider, library, or sensitive area — is not something this skill waives. The remedy is to write the note now (`/research [feature]`) and re-run; the gate then reads `unmet — note post-dates code`, and only the user may waive that *timing* defect, in writing.

### The PE-DOD gate

**Review mode check** — apply before spawning PE-DOD:
- `solo` → skip. Note: "PE-DOD skipped — Solo mode." **The table above stands as the record of the check** — Phase 6 has already checked all eight gates itself. Proceed to Phase 7.
- `lean` → skip (not a PHASE-GATE). Note: "PE-DOD skipped — Lean mode." Same.
- `full` → spawn `principal-engineer` via `Agent` using gate **PE-DOD** (`.claude/docs/director-gates/pe-dod.md`).

Pass the context that gate lists: the story file path (type, criteria, recorded
waivers); the evidence directory; the research note; the implementation paths
and governing ADR(s); `docs/architecture/perf-budgets.md`; the threat model path
for a sensitive story; the gate levels resolved from `testing.strict.*` and
`performance.enforce`; and the verdicts already obtained in this run for
PE-CODE-REVIEW, QL-TEST-COVERAGE, SL-TENANT-ISOLATION and SL-THREAT-MODEL (or
`skipped — [mode]`). Tell it where a gate verdict was skipped so it checks the
underlying evidence itself.

Apply the verdict:
- **APPROVE** → all eight gates met or validly waived. Proceed to Phase 7.
- **CONCERNS [list]** → ADVISORY gates unmet or evidence weak: carry the list to the report; the verdict becomes at best COMPLETE WITH NOTES. Surface via `AskUserQuestion`: `Fix first` / `Accept and proceed` / `Discuss further`.
- **REJECT [list]** → a BLOCKING gate is unmet and not validly waived: the verdict is **BLOCKED**. List the gates.
- **NOT ASSESSED [missing input]** → no judgement was made (story or evidence unreadable, gate levels unresolved); never read it as APPROVE. Name the input; the verdict stays at best NOT ASSESSED.

Compare the director's table with yours: where they differ, quote both with the
evidence and ask the user — do not silently adopt the more lenient reading. Where
PE-DOD disagrees with a "met" row, the row becomes `not checked` until
resolved.

---
