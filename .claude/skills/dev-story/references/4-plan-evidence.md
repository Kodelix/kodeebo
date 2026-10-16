# /dev-story — Phase 4: Plan the Evidence (before any code)

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Plan the Evidence (before any code)

Definition of Done is decided **before** coding, not discovered at `/story-done`.
This phase turns the story's `## Definition of Done Evidence` table and `## Test
Evidence` section into a concrete plan: for each of the eight gates, what this
story will produce, where it will live, and how it will be checked. The user
approves the plan; the lead is briefed with it.

**In this file:**

- Resolve the gate level per story type
- Build the eight-gate evidence plan
- Test-first sequence
- Show, ask, record

### Resolve the gate level for this story's type

Map the story Type to a `testing.strict` key — Logic→`logic`, Integration→`integration`,
Contract→`contract`, Security→`security`, Performance→`performance`, UI→`ui`,
Config→`config`. Take the value from the **resolved-config block at the top of
this skill**, not from `project.yaml` directly (`testing.strict.*` is locally
overridable; reading `project.yaml` alone ignores `project.local.yaml`):

1. `testing.strict.<key>` is `true` (case-insensitive) → BLOCKING; `false` → ADVISORY; `unset` → fall through.
2. Else, if `testing.strict` is a plain boolean (legacy form), it applies to every type.
3. Else the **default gate level** in `.claude/docs/coding-standards.md` → Test evidence by story type: Logic, Integration, Contract, Security, UI → BLOCKING; Performance → ADVISORY (BLOCKING when `performance.enforce: block`); Config → ADVISORY.

Only `true` and `false` are recognised. Any other present value (`maybe`, `1`, `yes`)
is treated as unset: continue to the next step and surface the unrecognised value
to the user. The Performance level also follows `performance.enforce` from the block
(`block` → BLOCKING; `warn` → ADVISORY; `off` → the plan says the performance gate
is switched off for this project, with the budget still recorded).

**What `qa.level` changes:** only how much *extra* test evidence the plan lists (manual
cases, the coverage signal at `full`, UAT). It never lowers the automated-test rows: for
Logic, Integration, Contract and Security stories the tests are BLOCKING at every tier and
the plan lists them in full, as it does the research note, the threat model, a Security
story's negative tests, tenant-isolation tests on tenant data, run-and-observe, and a UI
story's screenshots.

### Build the eight-gate evidence plan

For each gate, fill what this story will produce. Pre-fill from the story's
`Definition of Done Evidence` table and the research note's security,
performance & caching and observability sections — do not re-derive what the
story already states; correct it if the code root or lead changed it.

| # | Gate | Plan — what this story produces, where, how checked |
|---|------|------------------------------------------------------|
| 1 | Research first | Note path (from Gate A) or exemption row. Stale-version decision from Phase 2. |
| 2 | Clean architecture | The ports this story adds or consumes (named); context folder(s) and `domain`/`app`/`adapters` placement; composition-root change; the grep that proves `domain` imports nothing outward (per `clean-architecture.md` review checklist). No cross-context table reads. |
| 3 | Tests | Per story type (table below): files, levels (unit / integration / contract / negative), the cases from the story's `QA Test Cases`, plus the required-by-change list in `testing-standards.md` (every use case: happy path, each domain error, authz denied, tenant mismatch; every repository adapter: round trip, not-found, constraint violation, tenant isolation, pagination boundaries; every cache adapter: hit, miss, invalidation, TTL expiry, cache down → source; every provider integration: success, 4xx, 5xx/timeout with retry, duplicate webhook, bad signature; every endpoint: contract + authz tests for anonymous, wrong role, wrong tenant). Gate level: [BLOCKING / ADVISORY]. |
| 4 | Observability | Span names (low-cardinality), RED metrics, structured log events with `trace_id` and `tenant_id` where known, no-PII statement, health endpoints if a new service; the single retained trace (Phase 6). |
| 5 | Caching | The cache decision from the research note/spec — pattern, key schema with tenant ID, TTL with jitter, invalidation, stampede protection, failure mode — or `no cache: [written reason]`. If neither exists, the plan lists "write the decision" as a task for the lead (`caching-standard.md`). |
| 6 | Performance | The budget row (p95, queries per request, payload) from `perf-budgets.md` or `budget not yet set`; index named for every new query; the query-count assertion that proves no N+1; load test (k6) if the story is Performance type or a hot path (list/search/export, per-request middleware, bulk job) — with `performance.enforce` level. |
| 7 | Security | ASVS / MASVS requirement IDs this story satisfies (from the threat-model rows owned by this story, **looked up in the official documents, not recalled** — copy from the model/research note); the negative tests (authz bypass, cross-tenant read/list/update/delete/ID guess, injection, rate limit, replay/duplicate webhook, expired/forged token — whichever apply); dependency scan target (Phase 6); tenant-isolation test with real dependencies. Always BLOCKING for a sensitive story. |
| 8 | Decision record | `none expected`, or `ADR needed: [title]` for each architectural decision the story forces (new data store, broker, framework, tenancy deviation, cache engine-specific feature). A needed ADR is raised to the user now — before code — via `/architecture-decision`. At `workflow: minimal`, a decision-log line in `design/product-brief.md`. |
| — | Run and observe | Which operations/screens are exercised, as which actors (owner, member, other tenant, anonymous), the negative path, locales (UI: Arabic/RTL + English), viewports, and the evidence filenames under `production/qa/evidence/[STORY-ID]/` (`run-and-observe.md`). |

**Test evidence by story type** (locations from `.claude/docs/directory-structure.md`
→ Code roots; names per `.claude/rules/test-standards.md`):

| Type | Required evidence | Written where |
|---|---|---|
| Logic | Unit tests, table-driven where natural; **written first** | beside the code (`*_test.go`; `src/test/kotlin/`; `*.test.ts(x)`; `src/commonTest/kotlin/`; Swift Testing target) |
| Integration | Testcontainers tests against the real Postgres / Mongo / Redis-Valkey-Dragonfly / MinIO / broker; WireMock or `httptest` only for third-party HTTP you do not own | Go: `integration` build tag; Ktor: `src/integrationTest/kotlin/`; web: Vitest + MSW only for third-party |
| Contract | Consumer-side contract tests against `contracts/<file>`, response validation against the OpenAPI schema, breaking-change check output | per consumer; output in `production/qa/evidence/[STORY-ID]/` |
| Security | Negative tests + ASVS/MASVS mapping table in `production/qa/evidence/[STORY-ID]/` (template `.claude/docs/templates/test-evidence.md`) | tests in the layer; evidence on disk |
| Performance | k6 result vs the budget row: environment, data volume, thresholds; `EXPLAIN (ANALYZE, BUFFERS)` for hot queries | `production/qa/evidence/[STORY-ID]/` |
| UI | Retained screenshots of every screen touched (1440 px and 390 px; light/dark if supported; Arabic/RTL and English; Android/iOS: emulator/simulator shots incl. RTL), `/impeccable audit` summary, accessibility spot-check | `production/qa/evidence/[STORY-ID]/` |
| Config | Smoke check pass | `production/qa/smoke-[date].md` |

A UI, Contract or Security story still has Logic-level unit tests for any rule it
contains; the table names the *distinguishing* evidence, not the only evidence.

### Test-first sequence

For every story whose Type is **Logic** (and for the rule-bearing parts of any
other type), the lead writes the tests **before** the code that satisfies them:

1. Write the unit tests for each acceptance criterion and each domain error, against the port interfaces with fakes (injected `Clock`, `IDGenerator`; no network, disk or DB).
2. Run them. They must **fail for the right reason** (the code under test does not exist yet or returns the wrong thing) — capture the failing output. A test that passes before the implementation exists tests nothing; fix the test.
3. Implement until green. Do not edit a test to make it pass unless the criterion itself was misread — then say so in the summary.
4. Add the Integration tests (Testcontainers) for the adapters, then the contract and negative tests.

Contract stories write the contract test from the OpenAPI document first.
Security stories write the negative tests from the threat-model rows first.
The failing-then-passing output for the Logic tests goes in the Phase 7 summary
(first and last line of each run is enough; the full output stays in the
lead's report).

### Show, ask, record

Show the plan (eight rows + run-and-observe + test-first order + lane order from
Phase 3) and ask via `AskUserQuestion` (major decision):
- Prompt: "This is the evidence this story will produce before it can be closed. Does it match what you want?"
- Options: `[A] Approve and start implementation (Recommended)` / `[B] Adjust the plan` / `[C] Stop`

On **[A]**: ask "May I record this plan in the story under an `## Evidence Plan` heading?" and, if yes, write it (a new section; the existing DoD table rows stay as they are — their `Status` boxes are for `/story-done`). The `Evidence plan:` block is the only story edit of this phase. If the user declines, keep the plan in the conversation and the session state, and print `Evidence plan not recorded in the story — declined` in the Phase 7 summary.

**A waiver is never written by the model.** If a gate cannot be met (no budget
row yet, a provider sandbox unavailable), the plan marks it `waiver requested —
[reason]`, and the user decides; a waiver is a written reason **in the story
file approved by the user**. Security evidence on a security-sensitive story
cannot be waived by the model at all.

---
