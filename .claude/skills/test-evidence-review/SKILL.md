---
name: test-evidence-review
description: "Quality review of test files and evidence — goes beyond existence, evaluates assertion coverage, negative and tenant-isolation tests, and retained artefacts. ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED per story."
argument-hint: "[story-path | sprint | epic-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,performance.enforce`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`testing.strict`** (resolved above) decides what this review may call a
blocker — the same rules `/story-done` closes stories by, so a BLOCKING item here
is one that would stop `/story-done`:
- **`qa.level` never waives a test.** Logic, Integration, Contract and Security
  tests exist and pass at every level (`.claude/docs/coding-standards.md`), and
  the retained screenshots of a UI story and the run-and-observe evidence for
  anything a user can see or call are required at every level too. `qa.level`
  only changes how much *extra* evidence is asked for (smoke scope, coverage
  targets), so it never turns a MISSING story into anything softer.
- **Gate level per story type**: take `testing.strict.<type>` from the resolved
  block (`logic`, `integration`, `contract`, `security`, `performance`, `ui`,
  `config`): `true` → BLOCKING, `false` → ADVISORY, `unset` → a plain-boolean
  `testing.strict: true|false` (legacy form) applies to every type; else the
  Default Gate Level in `.claude/docs/coding-standards.md` (BLOCKING for Logic,
  Integration, Contract, Security and UI; ADVISORY for Performance — BLOCKING
  when `performance.enforce: block` — and Config). Every "BLOCKING" below means
  that story type's gate level.

# Test Evidence Review

`/smoke-check` verifies that test files **exist** and **pass**. This skill
goes further — it reviews the **quality** of those tests and evidence documents.
A test file that exists and passes may still leave critical behaviour uncovered.
A security story whose tests never try another tenant's ID proves nothing about
isolation. A load-test file that omits its data volume proves nothing about the
budget.

**Output:** Summary report (in conversation) + optional `production/qa/evidence-review-[date].md`

**When to run:**
- Before QA hand-off sign-off (`/team-qa`)
- On any story where test quality is in question
- As part of milestone review for an audit of test and evidence quality

**Read-only on tests and evidence.** This skill reads and evaluates; it never
edits a test file or an evidence document, and never runs a suite (that is
`/smoke-check`). Evidence it did not read is not described as reviewed.

---

## 1. Parse Arguments

**Modes:**
- `/test-evidence-review [story-path]` — review a single story's evidence
- `/test-evidence-review sprint` — review all stories in the current sprint
- `/test-evidence-review [epic-name]` — review all stories in an epic
- No argument — ask which scope: "Single story", "Current sprint", "An epic"

---

## 2. Load Stories in Scope

Based on the argument:

**Single story**: Read the story file directly. Extract: Story Type, Code root,
Test Evidence section, story ID, epic name.

**Sprint**: Read the most recently modified file in `production/sprints/`; extract
the list of story file paths from the sprint plan.

**Epic**: Glob `production/epics/[epic-name]/story-*.md`.

> **If the resolved scope contains ZERO stories, stop here.** Report
> `NOT ASSESSED — no stories in scope`, name which scope was searched and which
> path was empty, and route: no sprint file → `/sprint-plan new` (at `workflow: minimal`,
> which has no sprints, `/test-evidence-review [epic-name]` instead); a sprint plan
> listing no stories → `/create-stories [epic-name]`; an `[epic-name]` glob that
> matched nothing → name the glob. Do not continue to Section 3.
>
> **Guard the empty scope, not just the per-story unknown.** The verdict
> vocabulary here — ADEQUATE / INCOMPLETE / MISSING — needs a "could not check"
> value, or an unverifiable story acquires a verdict claiming somebody verified
> it; that is what `NOT ASSESSED` is for. **But giving the per-story unknown a
> home does nothing for the empty-scope unknown.** With no stories
> the Section 6 report renders an empty Summary table and ends
> `BLOCKING items: 0 / ADVISORY items: 0` — which reads as *everything reviewed,
> all fine*. This skill gates story closure, and `coding-standards.md` marks Logic,
> Integration, Contract, Security and UI evidence BLOCKING, so a false-clean closes
> stories nobody reviewed.
>
> This is a recurring shape: the sophisticated inner rule present, the outer
> boundary unguarded. Ask it of any skill that aggregates —
> **what does this emit when the set is empty?**

For the resulting story set, collect the fields below with **targeted section
greps, not a full read of each story**:
```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 12
Grep pattern="## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
Grep pattern="^> \*\*(Type|Code root)\*\*" glob="production/epics/**/story-*.md" output_mode="content"
```
- **Story Type** (Logic / Integration / Contract / Security / Performance / UI /
  Config), **Code root**, and the stated evidence path.
- Acceptance Criteria list — the `## Acceptance Criteria` block from the second grep.
- Story ID (from the file name and header) and epic (from the directory path) — no read.
Full-read a story only when its Test Evidence section is missing or ambiguous.
(In Sprint mode, scope the globs to the sprint plan's story paths.)

---

## 3. Locate Evidence Files

For each story, find the evidence. **Check the story's stated evidence path first**
— the one Section 2 captured from its `## Test Evidence` section. If it exists, use
it. Fall back to searching only when no path is stated or it is not found. The
test location is the story's code root (`.claude/docs/directory-structure.md` →
Code roots); an empty code-root resolution means the search did not run and the
story is `NOT ASSESSED`, never MISSING.

**Logic stories**: unit tests beside the code — Go `backend/internal/<context>/**/*_test.go`,
Ktor `src/test/kotlin/`, web `*.test.ts(x)`, Android `app/src/test/`, KMP
`commonTest`, iOS test targets — in files whose name or path contains the story's
feature, context or ID. Test files are named per `.claude/rules/test-standards.md`,
not necessarily after the story.

**Integration stories**: the integration locations — Go files with the
`//go:build integration` line, Ktor `src/integrationTest/kotlin/`, Android
`app/src/androidTest/`.

**Contract stories**: the consumer contract tests that read `contracts/` (path or
name containing `contract`), plus the breaking-change check output if the story names one.

**Security stories**: the negative tests (per layer) **and**
`production/qa/evidence/<STORY-ID>/` for the ASVS/MASVS mapping and the threat
model link (`docs/architecture/threat-models/<feature>.md`).

**Performance stories**: `production/qa/evidence/<STORY-ID>/` for the k6 script,
raw result and summary, and the query-count assertion test.

**UI stories**: Glob `production/qa/evidence/<STORY-ID>/` (and
`production/qa/evidence/` for the story slug) for retained images
(`*.png`, `*.jpg`, `*.gif`, `*.webp`) and the `/impeccable audit` summary.

**Config stories**: Glob `production/qa/smoke-*.md` (any smoke check report).

**Every story that changes something a user can see or call**: run-and-observe
evidence in `production/qa/evidence/<STORY-ID>/` (`api-<endpoint>.md`, screenshots,
a trace), per `.claude/docs/run-and-observe.md`.

Note what was found (path) or not found (gap) for each story. A path listed in a
story or evidence record with **no file on disk** is "not found", not "found" —
captured-and-discarded is an assertion, not evidence.

---

## 4. Review Automated Test Quality (Logic / Integration / Contract / Security)

For each test file found, read it and evaluate:

### Assertion coverage

Count the distinct assertions (Go `t.Errorf`/`t.Fatalf`/comparison helpers, Kotlin
`assertEquals`/`assertFailsWith`, TypeScript `expect`, Swift `#expect`/`#require` —
use the idiom the file uses). A low assertion count is a quality signal.

Thresholds:
- **3+ assertions per test function** → normal
- **1-2 assertions per test function** → note as potentially thin
- **0 assertions** (test exists but no asserts) → flag as BLOCKING (the story
  type's gate level) — the test passes vacuously and proves nothing
- **Assertion that cannot fail** (`assert true`, asserting the value just set,
  swallowing the error under test, `expect(...).toBeDefined()` on a literal) →
  flag as BLOCKING, same rule as zero assertions

### Required tests by change (`testing-standards.md`)

For each story, look for the test names that the standard requires for what the
story changes, **by reading the names**:

| Story changes | Required tests (by name or body) |
|---|---|
| A use case | happy path, each domain error, authorization denied, tenant mismatch |
| A repository adapter | round-trip, not-found, constraint violation, **tenant isolation** (A's row invisible to B), pagination boundaries |
| A cache adapter | hit, miss, invalidation on write, TTL expiry, **cache down** degrades to source |
| A provider integration | success, 4xx, 5xx/timeout with retry, **duplicate webhook** (idempotency), **invalid signature** |
| A migration | up on empty, up on seeded, down (dev), app suite green after |
| An endpoint | contract test and an authz test with three actors: anonymous, wrong role, wrong tenant |

A missing required test is BLOCKING at the story type's gate level and is
reported by name ("no cache-down test for `<adapter>`").

### Real dependencies and determinism

- Integration tests use Testcontainers on a pinned image from `docs/stack-reference/pins.yaml`
  — a mocked database or cache **client** in an "integration" test is BLOCKING
  (`testing-standards.md`: real dependencies for integration). Mocking third-party
  HTTP you do not own is fine.
- Postgres/RLS tests connect as the **non-owner, NOBYPASSRLS application role**;
  a test that connects as the container superuser passes vacuously — BLOCKING for
  a Security or tenant-isolation test.
- Time and IDs are injected: `time.Now()`, `Clock.System`, `Date.now()`, an unseeded
  random source or a `sleep`/fixed delay in a test is flagged (BLOCKING for a
  sleep or real clock in a unit test; ADVISORY elsewhere). Waits are polls with a
  deadline.
- Each test owns its tenant and data; a test that reads rows another test
  created, or depends on order, is flagged.
- A skipped or disabled test (`t.Skip`, `@Ignore`, `it.skip`, `@Disabled`) with no
  linked issue and owner is flagged BLOCKING; a quarantined test must appear in
  `production/qa/flaky-register.md` with an owner and a deadline.

### Edge case coverage

For each acceptance criterion in the story that contains a number, threshold,
or "when X happens" conditional: check whether a test function name or
test body references that specific case — the limit, limit ± 1, zero, empty
page, last page, duplicate submission.

Heuristics:
- Grep the test file for "zero", "max", "empty", "invalid", "boundary", "limit",
  "duplicate", "expired" — presence of any is a positive signal
- If the spec has numeric rules (proration, quotas, thresholds): check that tests
  exercise them at the minimum and maximum values

### Negative and tenant-isolation tests (Security, and every endpoint or adapter)

- Anonymous, wrong role and **other tenant** are each exercised; the other-tenant
  case asserts **404 and no data in the body**, not just a non-200.
- For auth/billing/licensing/upload/PII stories: replay, expired or forged token,
  brute force or rate limit, malformed input, mass assignment where the endpoint
  binds a body — as applicable to the threat model's abuse cases.
- ASVS/MASVS mapping is present in the evidence and the IDs are plausible for the
  control claimed (they are looked up in the official documents at mapping time,
  not recalled). A mapping that cites no ID, or a threat-model abuse case with no
  matching negative test, is BLOCKING for a Security story.

### Naming quality

Test names should describe the scenario and the expected result
(`.claude/rules/test-standards.md`): Go `Test<Subject>_<Action>_<Expectation>`,
Kotlin backtick sentences, TypeScript `it('…')`, Swift `@Test("…")`. Flag
functions named generically (`TestOne`, `test1`, `testBasic`, `it('works')`) as
**naming issues** — a reader should be able to list the feature's guarantees from
names alone.

### Traceability

For each acceptance criterion: is there at least one test or evidence file that
maps to it (by name, comment or the story's QA Test Cases entry)? List the
unmapped criteria. Where a spec Edge Cases & Failure Modes entry exists for the
feature, check it is tested or has a written reason.

---

## 5. Review Evidence Artefact Quality (Security / Performance / UI / Config)

For each evidence record found, read it and evaluate the checks below.

**A UI story needs no evidence document.** When it has none, its retained
screenshots are the evidence: apply only Screenshot / artefact completeness (an
image of each screen the story changes — a screen a criterion only navigates to
needs none of its own) and Date coverage (the images' dates), plus the
`/impeccable audit` summary. A UI story is ADEQUATE on those — never INCOMPLETE for
lacking a document, its criterion linkage or a sign-off.

### Criterion linkage

The evidence record should reference each acceptance criterion from the story.
Missing criteria mean a criterion was never verified.

### Sign-off completeness

What closes the story follows the evidence table in
`.claude/docs/coding-standards.md` — the same rule `/story-done` applies, at every
`qa.level`:
- **Security**: sign-off from `appsec-engineer` (or `security-lead`) —
  a blank or missing row is INCOMPLETE; "Deferred — [reason]" is noted and must be
  resolved before the story advances past the sprint review.
- **Performance**: sign-off from `performance-engineer`, same rule.
- **UI**: no sign-off is required — the retained screenshots close it. Note a
  sign-off if one exists; never mark a UI story INCOMPLETE for lacking one.
- **Config**: no sign-off; the smoke report is the evidence.

### Security evidence

- Negative-test results (names and pass/fail) for the cases in Section 4.
- The control mapping table (control → ASVS/MASVS ID → negative test → location).
- The threat model link resolves to a file that exists; the dependency-scan line
  is present ("clean" or findings with a waiver link).
- Secrets, tokens, OTP codes and personal data are redacted in any transcript;
  an unredacted credential in an evidence file is BLOCKING and is reported to
  `security-lead` without quoting the value.

### Performance evidence

- States the budget it was checked against (surface, metric, percentile, number,
  from `docs/architecture/perf-budgets.md`) — "no budget" is `budget not yet set`
  and means the result checks nothing (INCOMPLETE).
- States p50/p95/p99, error rate and throughput; the three scenarios (ramp, steady,
  spike) or the reason one was not run; **environment, data volume (rows and
  tenants) and tool version**. A run against an empty database, or with no data
  volume stated, is INCOMPLETE.
- More than one run with variance when a before/after claim is made; a single run
  is not a result.
- A query-count assertion (no N+1; reads ≤ 5 queries) exists as a test.
- The gate level is BLOCKING only when `performance.enforce: block`; otherwise
  ADVISORY — say which applies.

### Screenshot / artefact completeness

For UI stories: Glob for a retained image of **each screen touched**, in the
matrix `run-and-observe.md` requires — 1440 px and 390 px for web, English and
Arabic (RTL), light/dark if supported, and per touched screen on mobile (plus
Dynamic Type large on iOS). A doc that describes a visual check but retains no
image is INCOMPLETE — this gate is BLOCKING by default, and a description is an
assertion rather than evidence. The `/impeccable audit` summary must be present
with its findings fixed or waived with a reason.

### Run-and-observe evidence

For any story that changes something a user can see or call: a happy-path record
**and** a negative-path record (wrong role / other tenant / invalid input) on a
running stack, plus a trace for background jobs and webhooks. Missing negative
path → INCOMPLETE. Not waived at `qa.level: minimal`.

### Date coverage

Evidence should have a date. If the date is earlier than the story's last major
change (heuristic: compare against the sprint start date from the sprint plan),
flag as POTENTIALLY STALE — the evidence may not cover the final implementation.

---

## 6. Build the Review Report

For each story, assign a verdict:

| Verdict | Meaning |
|---------|---------|
| **ADEQUATE** | Test/evidence exists, passes quality checks, all criteria covered |
| **INCOMPLETE** | Test/evidence exists but has quality gaps (thin assertions, missing negative tests, missing sign-offs, missing data volume) |
| **MISSING** | No test or evidence found for a story type that requires it (every `qa.level`) |
| **NOT ASSESSED** | The review could not be performed for this story — see below |

> **`NOT ASSESSED` is required, and it is not a softer `MISSING`.**
> The other verdicts all presume the review actually ran. `MISSING` means
> *I looked and there was nothing there* — a real, reportable failure. It must
> never be used for *I could not look*, which is not a finding about the story
> at all. Use `NOT ASSESSED` when:
>
> - the story's **type cannot be determined**, so the required evidence is
>   unknown (the type→evidence mapping in `.claude/docs/coding-standards.md` is
>   what makes any other verdict meaningful);
> - the evidence path is named but **unreadable or outside this run's scope**;
> - the code roots resolved to an empty list, so the test search did not run;
> - the story file itself could not be parsed.
>
> **Say which of those it was, per story.** A reader cannot act on a bare
> `NOT ASSESSED`, and the whole point of separating it from `MISSING` is that
> the two have different fixes: one needs a test written, the other needs the
> reviewer given access or the story classified.

The overall sprint/epic verdict is the worst story verdict present, in this
order, worst first: **`MISSING` > `INCOMPLETE` > `NOT ASSESSED` > `ADEQUATE`**.
`NOT ASSESSED` outranks `ADEQUATE`: a run that could not assess part of its
scope has not established that the scope is adequate. It does not outrank
`INCOMPLETE` or `MISSING` — a known failure is more actionable than an unknown,
and demoting a real failure behind an access problem would bury it. `MISSING`
ranks above `INCOMPLETE` because nothing exists to review; the report still lists
every story's own verdict and names the NOT ASSESSED ones with their cause.

> Why this needed saying: evidence review **gates story completion**, and
> `coding-standards.md` makes Logic, Integration, Contract, Security and UI
> evidence BLOCKING. A verdict vocabulary with no way to express "I could not
> check" forces every unknown into one of the claims about the story — which is
> how a story nobody verified acquires a verdict that says somebody did.

```markdown
## Test Evidence Review

> **Date**: [date]
> **Scope**: [single story path | Sprint [N] | [epic name]]
> **Stories reviewed**: [N]
> **Overall verdict**: ADEQUATE / INCOMPLETE / MISSING / NOT ASSESSED
> **qa.level**: [minimal | standard | full] (does not change any verdict) — **testing.strict**: [the resolved per-type values, or "unset — coding-standards.md defaults"] — **performance.enforce**: [warn | block | off]

---

### Story-by-Story Results

#### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration/Contract/Security)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none / cannot fail]
- Required tests by change: [present / missing: <named>]
- Negative and tenant isolation: [anonymous / wrong role / other tenant: covered / partial / absent]
- Real dependencies and determinism: [Testcontainers + pinned image / mocked client ⚠ / sleep or real clock ⚠]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Traceability: [N/M criteria mapped; unmapped: <list>]

**Evidence quality** *(Security/Performance/UI/Config, and run-and-observe)*:
- Criterion linkage: [N/M criteria referenced]
- Sign-off: [✓ approved | ✗ missing | deferred — reason] *(Security: appsec-engineer/security-lead; Performance: performance-engineer; UI/Config: none)*
- Artefacts: [screenshots / transcripts / k6 raw output present on disk / missing / N/A]
- Run-and-observe: [happy + negative path present / negative path missing / not applicable]
- Freshness: [dated [date] — current / potentially stale]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

### Summary

| Story | Type | Gate | Verdict | Issues |
|-------|------|------|---------|--------|
| [title] | Logic | BLOCKING | ADEQUATE | None |
| [title] | Integration | BLOCKING | INCOMPLETE | Mocked cache client; no cache-down test |
| [title] | Security | BLOCKING | INCOMPLETE | No other-tenant test; sign-off missing |
| [title] | Performance | ADVISORY | INCOMPLETE | Data volume not stated |
| [title] | UI | BLOCKING | MISSING | No retained screenshot |
| [title] | Config | ADVISORY | NOT ASSESSED | Smoke report unreadable — see Not reviewed |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]

### Not reviewed
[Every story, layer or artefact the review could not read or locate, and why.
"Nothing was skipped" is stated explicitly when true.]
```

---

## 7. Write Output (Optional)

Present the report in conversation.

Ask: "May I write this test evidence review to
`production/qa/evidence-review-[date].md`?"

This is optional — the report is useful standalone. Write only if the user
wants a persistent record.

After the report:

- For BLOCKING items: "These must be resolved before `/story-done` can mark the
  story Complete. Would you like to address any of them now?" Route test fixes to
  the owning stack lead via `principal-engineer`, and evidence capture to `qa-tester`.
- For thin assertions or missing isolation tests: "Consider running `/test-helpers [context]`
  to scaffold the two-tenant fixture and fakes."
- For missing sign-offs: "Sign-off is required from [role]. Share
  `[evidence-path]` with them to complete it."
- For an unredacted credential: report the file path to `security-lead` via
  `qa-lead`; do not quote the value anywhere.

The closing line is the **overall verdict** from Section 6 (ADEQUATE,
INCOMPLETE, MISSING or NOT ASSESSED) — this skill has no second vocabulary — plus
the BLOCKING and ADVISORY counts. If the optional record was declined, add
"record not written (declined)"; the verdict itself is unchanged, because the
review is complete and reported in conversation.

**Checkpoint.** Before the closing line, when the record was written or the verdict
changes what happens next (INCOMPLETE, MISSING, NOT ASSESSED, BLOCKING items open),
update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/test-evidence-review <scope> — <verdict>`, Next step = the first
action for the BLOCKING items above (else `/story-done [story-path]`), plus Blocked
on / Files in progress (the record, if written) / Open questions; append the Notes
line. An ADEQUATE run that wrote nothing may skip it.

---

## Collaborative Protocol

- **Report quality issues, do not fix them** — this skill reads and evaluates;
  it does not modify test files or evidence documents
- **ADEQUATE means adequate for shipping, not perfect** — avoid nitpicking
  tests that are functioning and comprehensive enough to give confidence
- **BLOCKING vs. ADVISORY distinction is important** — only flag BLOCKING when
  the gap leaves a story criterion genuinely unverified
- **Never weaken a standard to get ADEQUATE** — a waiver is a written reason in the
  story file, approved by the user; this skill does not grant one
- **Ask before writing** — the report file is optional; always confirm before writing
