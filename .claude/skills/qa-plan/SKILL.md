---
name: qa-plan
description: "QA test plan for a sprint, feature or story — classifies stories by Logic/Integration/Contract/Security/Performance/UI/Config with the evidence and gate level each needs, plus smoke scope and flaky-test policy."
argument-hint: "[sprint | feature: feature-name | story: path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/qa-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.


# QA Plan

This skill generates a structured QA plan for a sprint, feature, or individual
story. It reads all in-scope story files and their referenced feature specs,
classifies each story by test type, and produces a plan that tells engineers
exactly what to automate, what to verify against a running stack, what the
smoke scope is, and when usability sessions are needed.

Run this before a sprint begins so the team knows upfront what testing work
is required. A test plan written after implementation is a post-mortem, not a
plan.

**Output:** `production/qa/plan-[slug]-[date].md` (template:
`.claude/docs/templates/test-plan.md`; the file name is the one `qa-lead` and
`test-automation-engineer` cite as `production/qa/plan-*.md`).

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolve per the spec's feature as each is read (per
`.claude/docs/workflow-modes.md`; the feature is the spec filename stem):
`workflow_overrides.system_overrides.<feature>` if the block lists one, else the
project value. It sets how many spec sections the test plan is mined from — see
Phase 2.

**`qa.level`** changes only how much **extra** evidence the plan asks for, never
whether a test exists: every level plans the automated tests for Logic,
Integration, Contract and Security stories (`.claude/docs/coding-standards.md`),
the negative tests of a Security story, the retained screenshots of a UI story,
and the run-and-observe plan for anything a user can see or call. At `minimal`
that is the whole plan; at `standard`, add the smoke scope and the usability
requirements; at `full`, also add per-feature coverage targets (domain + app
packages ≥ 85 % line coverage per `testing-standards.md`). Distinct axis from
`workflow`.

**Gate level per story type** — resolve once from the block's `testing.strict`
line and `performance.enforce`; `unset` means apply the default below, never
"off":

| Story type | Default | `testing.strict.<type>` |
|---|---|---|
| Logic, Integration, Contract, Security, UI | BLOCKING | `true` → BLOCKING, `false` → ADVISORY |
| Performance | ADVISORY — BLOCKING when `performance.enforce: block` | as above; `performance.enforce: block` always wins |
| Config | ADVISORY | as above |

A plan states the effective level next to every story and says whether it came
from config or from the default.

## Phase 1: Parse Scope

**Argument:** `$ARGUMENTS` (blank = ask user via AskUserQuestion)

Determine scope from the argument:

- **`sprint`** — read the most recent file in `production/sprints/`, extract
  every story file path referenced. If `production/sprint-status.yaml` exists,
  use it as the primary story list and fall back to the sprint plan for story
  metadata.
- **`feature: [feature-name]`** — glob `production/epics/*/story-*.md`, filter
  to stories whose file path, title or `Spec:` stem contains the feature name.
  Also check the epic index file (`EPIC.md`) in that epic's directory.
- **`story: [path]`** — validate that the path exists and load that single file.
- **No argument** — use `AskUserQuestion`:
  - "What is the scope for this QA plan?"
  - Options: "Current sprint", "Specific feature (enter feature name)",
    "Specific story (enter path)", "Full epic"

After resolving scope, report: "Building QA plan for [N] stories in [scope]."

If a story file path is referenced but the file does not exist, note it as
MISSING and continue with the remaining stories. Do not fail the entire plan
for one missing file.

> **If the resolved scope contains ZERO stories, stop — do not build a plan.**
> Report `NOT ASSESSED — no stories in scope`, naming which scope was searched
> and which path was empty, and route:
> - no file in `production/sprints/` → "No sprint plan found. Run `/sprint-plan new`."
>   At `workflow: minimal` there are no sprints by design — route instead to
>   `/qa-plan feature: [epic-slug]` or `/qa-plan story: [path]`.
> - a sprint plan exists but references no stories → "Sprint plan `[path]` lists no
>   stories. Run `/create-stories [epic-slug]`."
> - `feature:`/`story:` scope matched nothing → name the glob that came back empty.
>
> **The N=0 guard is mandatory.** Without it an empty scope reports "Building QA
> plan for 0 stories" and continues into Phase 4, producing a plan document with
> empty tables — and **a QA plan for zero stories looks exactly like a completed
> QA plan.** This skill gates the hand-off to QA, so a false-clean here sends a
> build to QA on the strength of a plan that tested nothing.
>
> Phase 2 states **"Never treat an absent section as an absent story"** — the
> inner case, correctly handled. This is the outer boundary: no stories at all.
> One missing file among several is MISSING-and-continue; this is the different
> case where there is no *several*.

---

## Phase 2: Load Inputs

Establish the denominator first — glob the in-scope story files and count **N** —
then collect the fields below with **targeted section greps, not a full read of
each story**. A QA plan needs each story's type and acceptance criteria; it does
not need its implementation notes, out-of-scope boundaries or ADR rationale, and
reading N stories whole to reach two sections is where this phase's cost lives:

```
Grep pattern="^## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
Grep pattern="^> \*\*(Type|Status|Estimate|Code root|Owner agent)\*\*" glob="production/epics/**/story-*.md" output_mode="content"
Grep pattern="^## (Context|Dependencies)" glob="production/epics/**/story-*.md" output_mode="content" -A 12
```

(Scope the globs to the sprint plan's story paths in `sprint` mode.) From those:

- **Story title** and story ID — from the file name and path; no read at all
- **Story Type** field — from the header grep (e.g., `Type: Security`)
- **Code root / layer** — decides the test location (`directory-structure.md` → Code roots)
- **Acceptance criteria** — the complete numbered/bulleted list, from the first grep
- **Spec**, **Research note**, **Threat model**, **Contract** and **ADR** references
  and **Dependencies** — from the `## Context` grep
- **Estimate** — from the header grep if present
- **Implementation notes** and **Stack notes** — only needed for stories whose
  test plan actually turns on them; full-read those individual stories

**Never treat an absent section as an absent story.** If a story matched no
`## Acceptance Criteria`, full-read that one and say so — a story with no
testable criteria is a QA finding in its own right, not a story to skip.

After reading stories, load supporting context once (not per story):

- `design/specs/domain-map.md` — to understand feature priorities and which
  specs are approved
- For each unique spec referenced across all stories: mine test material per that
  feature's workflow tier (resolved above) — at `full`, mine all 8 sections; at
  `standard`, mine the test-relevant subset (**Acceptance Criteria**, **Edge Cases
  & Failure Modes** when present, **Detailed Behaviour** for rules and permissions
  per role, **Data & Contracts** for the endpoints and events to cover, and the
  **Non-Functional Requirements** performance and security rows); at `minimal`,
  **Acceptance Criteria in the story only** plus `docs/research/[feature].md`
  for the provider behaviours to fake. Do not load the full spec text. If an
  Edge Cases section is absent (or not expected at the tier), note per spec: "No
  Edge Cases section found — edge case coverage inferred from acceptance
  criteria only."
- `docs/architecture/perf-budgets.md` — the budget row for each Performance
  story's surface. Absent, or no row for the surface → write
  `budget not yet set` in the plan and flag it for `performance-engineer`; a
  load test with no budget has no threshold to check.
- `docs/architecture/threat-models/[feature].md` — the abuse cases each Security
  story's negative tests must cover. A Security story with no threat model on a
  security-baseline trigger (auth, billing, file upload, PII) is flagged as a gap.
- `docs/architecture/control-manifest.md` — scan for forbidden patterns that
  automated tests should guard against (if the file exists)
- `contracts/` — the operation files the Contract stories name

If no spec is referenced in a story, note it as a gap but do not block the plan.
The story is classified using acceptance criteria alone.

---

## Phase 3: Classify Each Story

For each story, assign a Story Type:

- **If the story already has a `Type:` field in its header**: accept it as the primary type — it was set at story creation and is authoritative. Record it as-is; the only change allowed is to *add* a heavier secondary type (next bullet), never to replace it.
- **If a declared `Type:` contradicts the criteria** (for example a Logic story
  whose criteria add an authorisation check, or a Contract story that stores
  data), do not switch it: record the declared type as primary, add the heavier
  type's evidence as secondary (Security over Integration over Logic), and flag
  "declared type under-classifies this story — ask the story owner to correct it"
  in the classification table. A plan never moves a story to a lighter type.
- **If the `Type:` field is missing**: infer the type from the acceptance criteria using the table below, and note in the report that the type was inferred (not declared). Flag this as a gap — the story should have its Type declared explicitly before implementation begins.

| Story Type | Classification Indicators | Required evidence |
|---|---|---|
| **Logic** | Criteria reference calculations, proration or pricing rules, thresholds, state machines, validation, entitlement or quota decisions — any testable computation | Unit tests beside the code, must pass |
| **Integration** | Criteria involve a data store (Postgres, Mongo, Redis/Dragonfly/Valkey), a queue, an outbound provider call, a webhook, a migration, or two bounded contexts interacting | Testcontainers integration test on the pinned image |
| **Contract** | Criteria add or change an endpoint, event or error shape between backend and clients | Contract test against `contracts/` per consumer |
| **Security** | Criteria touch auth, sessions, OTP, billing, licensing, tenancy, admin or impersonation, file upload, PII, or reference a threat model or ASVS/MASVS control | Negative tests (authz bypass, cross-tenant, injection, replay, rate limit) + control mapping in `production/qa/evidence/` |
| **Performance** | Criteria name a latency, throughput, query-count or payload number; hot paths (listing, search, dashboards, auth, webhooks); jobs with a max runtime | Query-count assertion + k6 result vs `perf-budgets.md` in `production/qa/evidence/` |
| **UI** | Criteria reference screens, forms, navigation, states, empty/error/loading, RTL, responsive layout (web or mobile) | Retained screenshot of every screen touched + `/impeccable audit` result |
| **Config** | Changes limited to limits, flags, prices, TTLs or seed data — no new logic | Smoke check pass (`production/qa/smoke-[date].md`) |

**Mixed stories** (e.g., a story that adds a pricing rule and a billing screen):
assign the primary type by which criteria carry the highest implementation risk,
and note the secondary type — the plan carries the evidence of **both**. A story
that is both Logic and Security is planned as Security. When a story is ambiguous
between Logic and Integration, classify it as Integration (it needs both unit and
integration tests); between anything and Security, classify it as Security.

After classifying all stories, produce a classification summary table in
conversation before proceeding to Phase 4 — story, declared/inferred type,
secondary type, code root, effective gate level and its source (config or
default). This gives the user visibility into how tests will be allocated.

---

## Phase 4: Generate Test Plan

Assemble the full QA plan document from the template at
`.claude/docs/templates/test-plan.md`. Use this structure:

````markdown
# QA Plan: [Sprint/Feature Name]
**Date**: [date]
**Generated by**: /qa-plan
**Scope**: [N stories across [N bounded contexts]]
**Stack**: [layers in scope with pinned versions — from the `stack` line of the resolved config and `docs/stack-reference/pins.yaml`; "Not configured" if absent]
**Sprint File**: [path to sprint plan if applicable]
**Gate levels**: [type → BLOCKING/ADVISORY, each marked (config) or (default)]

---

## Test Summary

| Story | Type | Gate | Automated evidence required | Run / manual verification required |
|-------|------|------|-----------------------------|------------------------------------|
| [story title] | Logic | BLOCKING | Unit test — beside the code | Run-and-observe if user-visible |
| [story title] | Integration | BLOCKING | Testcontainers test — `[path]` | Smoke check |
| [story title] | Contract | BLOCKING | Contract test vs `contracts/[file]` — per consumer | None |
| [story title] | Security | BLOCKING | Negative tests — `[path]` | Control mapping + evidence |
| [story title] | Performance | ADVISORY | Query-count assertion + k6 scenario | Load-test result vs budget |
| [story title] | UI | BLOCKING | Component / e2e test (optional) | Retained screenshots + `/impeccable audit` |
| [story title] | Config | ADVISORY | Data validation (optional) | Smoke check pass |

---

## Automated Tests Required

### [Story Title] — [Type]
**Test file path**: per the story's code root, from `directory-structure.md`:
Go `backend/internal/[context]/{app,adapters}/[x]_test.go` (integration behind
the `integration` build tag) · Ktor `backend/src/test/kotlin/` and
`src/integrationTest/kotlin/` · web `web/src/features/[feature]/[x].test.tsx`,
Playwright `web/e2e/` · Android `mobile/android/app/src/test/` and `androidTest/` ·
KMP `mobile/shared/src/commonTest/kotlin/` · iOS Swift Testing / XCTest target.
**What to test**:
- [Rule from the spec's Detailed Behaviour or the story's criteria — with the numbers]
- [Each state transition and permission per role]
- [Each side effect that should or should not occur — event emitted, email queued, audit row written]

**Required by change** (`testing-standards.md`): the use case's happy path, each
domain error, authorization denied and tenant mismatch; for adapters: round-trip,
not-found, constraint violation, tenant isolation, pagination boundaries; for
cache adapters: hit, miss, invalidation, TTL, **cache down**; for provider
integrations: success, 4xx, 5xx/timeout with retry, duplicate webhook,
invalid signature; for migrations: up on empty, up on seeded, down (dev), suite
green after.

**Edge cases to cover**:
- Zero/minimum/maximum/boundary values (limit, limit ± 1, empty page, last page)
- Invalid or missing input; unknown enum values
- Repeated requests (idempotency key), concurrent writes
- [Any edge case from the spec's Edge Cases & Failure Modes section]

**Estimated test count**: ~[N] tests

[If no rule or number could be found for this story, note:]
*No rule found in the referenced spec — test cases must be derived from acceptance
criteria directly. Review the spec's Detailed Behaviour before writing tests.*

### [Story Title] — Contract
**Consumers touched**: [web | Android | iOS | KMP shared | self-hosted client]
**What to test**: real handler responses validated against `contracts/[file]`,
including every `application/problem+json` error status; an authz table with
three actors (anonymous, wrong role, wrong tenant) in the same file; a
response field missing from the spec fails the build.

### [Story Title] — Security
**Threat model**: `docs/architecture/threat-models/[feature].md` — [present | MISSING]
**Negative tests** (named so a reader can list the guarantees):
- Anonymous, wrong role, **other tenant** (tenant B's resource ID used by tenant A → 404, no data)
- Mass assignment, injection, SSRF where the endpoint takes a URL, replay, expired/forged token
- Rate limit / quota exhaustion where the spec defines one
- [Each abuse case in the threat model]
**Control mapping**: ASVS / MASVS IDs looked up in the official document at mapping time, saved to `production/qa/evidence/[STORY-ID]/`

---

## Manual QA Checklist

### [Story Title] — UI
**Verification method**: Retained screenshot of every screen touched
**Matrix**: web 1440 px and 390 px; Arabic (RTL) and English; light/dark if
supported; empty, loading, error and partial states. Mobile: each touched screen
on a device or emulator, plus RTL (and Dynamic Type large on iOS).
**Evidence to capture**: `production/qa/evidence/[STORY-ID]/web-[screen]-[width]-[lang].png`
(or the per-platform equivalent), plus the `/impeccable audit` summary
**Who must sign off**: [ux-designer / design-director — optional; the retained screenshot is what closes the gate]

Checklist:
- [ ] [Specific observable condition — concrete and falsifiable]
- [ ] Every acceptance criterion translated into a check item
- [ ] Keyboard-only path works; focus visible; labels announced
- [ ] Mirrored layout, truncated labels, number/date formatting, mixed-direction strings
- [ ] `/impeccable audit` findings fixed or waived with a reason

*If any criterion uses subjective language ("fast", "clean", "intuitive"), it must
be supplemented with a measurable benchmark or a usability-session protocol.*

### [Story Title] — Performance
**Budget**: [surface, metric, percentile, number — `perf-budgets.md` row | `budget not yet set`]
**Verification method**: k6 ramp, steady and spike against a stack brought up with
`up --wait`, seeded data volume and tenant mix stated (`/load-test`)
**Who must sign off**: performance-engineer

- [ ] p95 within budget at [N] req/s steady; spike recovers; error rate bound met
- [ ] No N+1 (query-count assertion green); reads ≤ 5 queries

---

## Run-and-Observe Plan

For every story that changes something a user can see or call
(`.claude/docs/run-and-observe.md`): exercise the happy path **and** one
negative path on the running stack as the relevant actors (owner, member, other
tenant, anonymous); retain `api-<endpoint>.md` transcripts, screenshots and one
trace in `production/qa/evidence/[STORY-ID]/`. Not waived at `qa.level: minimal`.

| Story | Layer | Actors | Negative path | Evidence files |
|-------|-------|--------|---------------|----------------|

---

## Smoke Test Scope

Critical paths to verify before any QA hand-off for this sprint:

1. The stack starts and every healthcheck passes (`docker compose -f deploy/compose.dev.yaml up -d --wait`); migrations applied
2. Sign up / log in / token refresh for the seeded test tenant
3. [Primary journey introduced or changed this sprint]
4. [Any area with a regression risk from this sprint's changes]
5. Tenant isolation spot-check: a user in tenant A cannot read tenant B's resource
6. Payment / entitlement / licence path (provider sandbox) if billing or licensing was touched
7. Hot paths of any Performance story answer within their budget on the local dev stack (the full ramp, steady, spike and soak measurement is `/load-test`, not a smoke check)

*Smoke tests are verified via `/smoke-check`, which touches the local dev stack and the seeded tenant only. Reference this list when running that skill.*

---

## Test Suite Policy

- **Flaky tests**: a test that fails then passes on rerun is quarantined **within
  one day** with an issue and an owner; quarantined tests still run in a separate
  non-blocking job and are listed in every gate report; each is fixed or deleted
  within **14 days**. Rerun-until-green is never configured in CI.
- **Flake detection on changed tests before merge**: Go `-race -shuffle=on -count=N`;
  others N repeated runs; N stated in the PR.
- **Budgets**: unit suite < 30 s; per-test < 2 s after container start; domain +
  app coverage ≥ 85 % or the drop is explained.
- **Environments and data**: dev compose stack with a dedicated seeded test
  tenant (`tools/seed/`); image tags from `docs/stack-reference/pins.yaml`; only
  the engines the product's `deploy/` bundle ships are in the matrix.
- **Not run in this plan**: [list anything the plan cannot cover and why — no
  device, no provider sandbox, no budget row]

---

## Usability Testing Requirements

| Story | Question to Answer | Min Sessions | Target User |
|-------|-------------------|--------------|-------------|
| [story] | [What must we learn?] | [N] | [new tenant admin / invited member / ...] |

**Sign-off requirement**: Notes must be written to
`production/session-logs/usability-[sprint]-[story-slug].md` and structured with
`/usability-report` before the story can be marked COMPLETE.

If no stories require usability validation: *No usability sessions required for
this sprint.*

---

## Definition of Done — This Sprint

A story is DONE when ALL of the following are true (every row applies at every
`qa.level`, except the smoke row, which follows the gate's level):

- [ ] All acceptance criteria verified — automated test result OR retained evidence
- [ ] The eight DoD gates met, or waived in writing in the story file
- [ ] Test files exist and pass for Logic, Integration, Contract and Security stories *(every qa.level)*
- [ ] Load-test evidence vs budget for Performance stories (BLOCKING when `performance.enforce: block`)
- [ ] Retained screenshot of each screen touched, in `production/qa/evidence/`, for UI stories *(every qa.level)*
- [ ] Run-and-observe evidence (happy and negative path) for every user-visible or callable change *(every qa.level)*
- [ ] Smoke check passes (`/smoke-check sprint` before QA hand-off) *(required at qa.level standard/full; optional at minimal)*
- [ ] No regressions — previous sprints' critical journeys still pass (`/regression-suite`)
- [ ] Code reviewed (`/code-review` or documented peer review)
- [ ] Story file updated to `Status: Complete` (via `/story-done`)
````

When generating content, use the actual story titles, spec rules, numbers and
acceptance criteria extracted in Phase 2. Do not use placeholder text — every
test entry should reflect the real requirements of these specific stories. A
section that does not apply is stated as skipped with the reason
(`Contract: none in scope`), never silently dropped.

---

## Phase 5: Write Output

Show the complete plan in conversation (or a summary if the plan is very long),
then ask two questions together using `AskUserQuestion`:

```
question: "Ready to write the QA plan. Choose output options:"
multiSelect: true
options:
  - "Write QA plan to production/qa/plan-[slug]-[date].md"
  - "Also back-fill test case specs into each story file's ## QA Test Cases section (Recommended — enables /dev-story and /code-review traceability)"
```

If "Write QA plan" is selected: write the plan file exactly as generated — do not truncate.

If "Also back-fill story files" is selected: for each Logic, Integration, Contract and Security story in scope, edit the story file at its path. Find the `## QA Test Cases` section and replace its content with the test case specs generated in Phase 4 for that story (Given / When / Then / Negative / Edge cases per acceptance criterion). If a story has no `## QA Test Cases` section, append it before `## Definition of Done Evidence`. For UI stories, write the manual verification steps (setup, verify, pass condition) instead of test specs. Never overwrite qa-lead specs already present without showing the diff.

After writing:

"QA plan written to `production/qa/plan-[slug]-[date].md`.

Next steps:
- Share this plan with the team before sprint implementation begins
- Once all sprint stories are implemented, run `/smoke-check sprint` to gate QA hand-off — not yet, only after implementation is complete
- For Logic, Integration, Contract and Security stories, create the test files at the listed paths before marking stories done — `/story-done` checks for them"

Silently append to `production/session-state/active.md` (create the file if it does not exist):

```
<!-- QA-PLAN: [date] | Scope: [feature/sprint identifier] | Plan written: production/qa/plan-[identifier]-[date].md -->
```

**Checkpoint.** Also update the CHECKPOINT block per
`.claude/docs/checkpoint-handoff.md`: Current task `/qa-plan <scope> —
<verdict>`, Next step = the first next step above (share the plan, then
implement), plus Blocked on / Files in progress / Open questions; append the Notes
line. A declined write or the `NOT ASSESSED — no stories in scope` path still
updates the checkpoint with the blocker.

Close with the verdict: **COMPLETE** — QA plan written; or **COMPLETE WITH GAPS** —
plan written with named gaps (see below); or `BLOCKED — write declined by user`
if the plan write was declined (the plan stays in conversation, nothing is
reported as recorded). The only other outcome is the `NOT ASSESSED — no stories
in scope` path in Phase 1. Anything the plan could not
cover (missing budget row, missing threat model, no spec, inferred or
under-classified types) is listed under "Not run in this plan" and in the closing
message, and makes the verdict **COMPLETE WITH GAPS** — a plan with silent gaps
reads as a complete plan.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never write the plan without asking** — Phase 5 requires explicit approval.
- **Classify conservatively**: Integration over Logic when ambiguous; Security
  over everything else when ambiguous.
- **Do not invent test cases** beyond what acceptance criteria, spec rules and the
  threat model support. If a rule or number is absent from the spec, flag it
  rather than guessing.
- **Never write an API, flag, or tool version from memory** — test tooling and
  versions come from `docs/stack-reference/` and `pins.yaml`; if the stack
  reference does not cover it, write `NOT SOURCEABLE` and suggest `/research`.
- **Usability requirements are advisory**: the user decides whether a session is
  warranted for borderline UI stories. Flag the case; do not mandate.
- **Weakening is not planning**: never plan around a BLOCKING gate by choosing a
  lighter story type; a waiver is a written reason in the story file, approved
  by the user.
- Use `AskUserQuestion` for scope selection when no argument is provided.
  Keep all other phases non-interactive — present findings, then ask once to
  approve the write.
