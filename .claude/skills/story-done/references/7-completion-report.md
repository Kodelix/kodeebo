# /story-done — Phase 7: Present the Completion Report

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Present the Completion Report

**In this file:**

- The completion report template
- Verdict definitions
- `NOT ASSESSED` and verdict precedence

Before updating any files, present the full report:

```markdown
## Story Done: [Story Name]
**Story**: [file path]  (ID: [STORY-ID])
**Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [Criterion 1] — auto-verified (test passed: `[test]`, exit 0)
- [x] [Criterion 2] — confirmed
- [ ] [Criterion 3] — FAILS: [reason]
- [?] [Criterion 4] — DEFERRED: requires [deployed stack | provider live mode | store review]

### Test-Criterion Traceability
| Criterion | Test / evidence | Status |
|-----------|-----------------|--------|
| AC-1: [text] | [test file::test name] | COVERED |
| AC-2: [text] | production/qa/evidence/[STORY-ID]/[file] | COVERED |
| AC-3: [text] | — | UNTESTED |

### Test Results
| Layer | Command | Result |
|-------|---------|--------|
| backend | `go test -race ./...` | passed (exit 0, N tests) / FAILED / not run — [reason] / stale |

### Test Evidence
**Story Type**: [Logic | Integration | Contract | Security | Performance | UI | Config | Not declared]
**Required evidence**: [unit tests | Testcontainers tests | contract tests | negative tests + ASVS/MASVS mapping | load test vs budget | screenshots + audit | smoke check]
**Evidence found**: [YES — `[path]` | NO — BLOCKING | NO — ADVISORY]

### Run and Observe
**Run result**: [OBSERVED — [what]  | OBSERVED — partial: [missing] | NOT VERIFIED — [reason] | N/A — [reason]]
**Evidence folder** (`production/qa/evidence/[STORY-ID]/`): [listing — every file named in the story is on disk: yes/no]
**Images opened**: [one line per screenshot: what it shows vs the criterion]

### Definition of Done — the eight gates
| # | Gate | Level | Status (met / waived / unmet / not checked) | Evidence / gap |
|---|------|-------|---------------------------------------------|----------------|
| 1 | Research first | BLOCKING | | `docs/research/[feature].md` (dated [d] vs first commit [d]) |
| 2 | Clean architecture | BLOCKING | | [grep result / code-review.md] |
| 3 | Tests | [level] | | [paths; results] |
| 4 | Observability | [level] | | [trace file; spans; log fields] |
| 5 | Caching | [level] | | [decision / "no cache: reason"] |
| 6 | Performance | [level; performance.enforce] | | [p95 vs budget; queries/request; load test] |
| 7 | Security | BLOCKING if sensitive | | [ASVS/MASVS IDs; negatives; scan; threat model] |
| 8 | Decision record | [level] | | [ADR path / none expected] |

**Waivers** (user-approved, written): [None] or [Gate N — reason — approved by — date]

### Gates and Reviews
PE-CODE-REVIEW: [verdict | skipped — mode | reused from [date]]   QL-TEST-COVERAGE: [verdict | skipped — mode | skipped — Config story]
SL-TENANT-ISOLATION: [verdict | skipped — mode | not applicable — reason]   SL-THREAT-MODEL: [verdict recorded in header | not required | skipped — mode]
PE-DOD: [APPROVE | CONCERNS | REJECT | NOT ASSESSED — input | skipped — mode]

### Deviations
[NONE] OR:
- BLOCKING: [description] — [spec/ADR/threat-model reference]
- ADVISORY: [description] — user accepted / flagged for tech debt

### Scope
[All changes within stated scope] OR:
- Extra files touched: [list] — [note whether valid or scope creep]

### Not run / not checked
- [every check that did not run, with the reason and what would run it — or "none"]

### Verdict: COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED
```

**Verdict definitions:**
- **COMPLETE**: all criteria pass, all eight gates met (or validly waived and
  none of the waivers is a BLOCKING security gate), no blocking deviations,
  nothing under "Not run / not checked" that a BLOCKING gate depends on
- **COMPLETE WITH NOTES**: every criterion passes or is `DEFERRED` (Phase 3 —
  evaluable, awaiting a deployed stack, provider live mode or store review),
  with advisory deviations, ADVISORY gate gaps, validly waived gates or deferred
  criteria documented — list each so it is not lost
- **NOT ASSESSED**: one or more acceptance criteria or DoD gates could not be
  evaluated at all — name which, and why
- **BLOCKED**: failing criteria, a failed test run, a BLOCKING gate unmet and not
  validly waived, or blocking deviations must be resolved first

**`NOT ASSESSED` — the story nobody could verify.** Rank: it **outranks COMPLETE
and COMPLETE WITH NOTES** (a review that could not evaluate a criterion or gate
has not shown it is met) and **ranks below BLOCKED** (a criterion known to fail is
more actionable than one nobody could check, and demoting it would bury it). It is
not a gentler BLOCKED: "this fails" and "I could not tell whether it passes" send
the reader to different fixes — one needs work done, the other needs a tool run,
an input supplied or a criterion rewritten.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**BLOCKED**, then **NOT ASSESSED**, then **COMPLETE WITH NOTES**, then
**COMPLETE**. A run with both a failing criterion and an unassessable one is
BLOCKED.

**BLOCKED when any of:** a criterion FAILS; a test run FAILED; a BLOCKING test
evidence or gate gap exists that is `unmet` (evidence checked and absent — e.g.
no test file, no screenshot, no negative tests) and not validly waived; PE-DOD or
PE-CODE-REVIEW or SL-TENANT-ISOLATION returned REJECT; QL-TEST-COVERAGE returned
INADEQUATE; a BLOCKING deviation; >50% of criteria UNTESTED; a sensitive story
with no threat model or no security evidence.

**Emit NOT ASSESSED when any of:**

- An acceptance criterion **cannot be evaluated at all** — it names no observable outcome, so no evidence could settle it either way.
  > **Not the same as Phase 3's `DEFERRED`.** A criterion that is evaluable but needs a deployed stack, a live provider or a store review is `DEFERRED`, does **not** block, and Phase 3 keeps ownership of it. This trigger is for a criterion no session could ever settle as written.
- A criterion the user answered **`Not tested yet`** — it could be checked, but nobody has. Name it and what would settle it, then re-run `/story-done`.
- A **test or scan that a BLOCKING gate depends on was `not run`** (suite not executed, `govulncheck`/`osv-scanner` not installed, container runtime missing, Swift tests off macOS, no CI output supplied) — the gate's evidence exists only as a file that nobody executed. Name the command and what would run it.
- A **`budget not yet set`** row for a BLOCKING performance gate (`performance.enforce: block`), or `tenancy.model` unset for a tenant-data story — the gate has nothing to be measured against.
- QL-TEST-COVERAGE, SL-TENANT-ISOLATION, SL-THREAT-MODEL, PE-CODE-REVIEW or PE-DOD returned **NOT ASSESSED** and the input it named was not supplied.
- The **evidence is present but unreadable or unclassifiable** — corrupt, empty, or of a type that cannot be determined.
  > **Absent evidence is Phase 3's and Phase 6's, not this trigger's.** A missing file is resolved through `testing.strict` and the DoD level: BLOCKING → **BLOCKED**, ADVISORY → **COMPLETE WITH NOTES**. Re-routing "absent" here would silently override an explicit advisory ruling. *Unreadable* and *not run* are the genuinely unassessable cases.
- **`/test-evidence-review` returned `NOT ASSESSED`** for this story — applicable only when that skill was actually run against it, which this skill does not do itself. It propagates: "could not check" is not "checked and fine".
- A **deviation's severity cannot be determined** because the spec or ADR it would be judged against is missing.
- A gate row is `not checked` and nothing else settles it.

A `NOT ASSESSED` verdict takes the same Phase 8 path as BLOCKED: do not
automatically proceed, list what could not be checked and what would make it
checkable. Closing anyway remains the user's explicit call, and stays gated by
Phase 8's `scope_changes` always-ask rule.

If the verdict is **BLOCKED**: do not *automatically* proceed to Phase 8. List
what must be fixed and offer to help fix the blocking items. This is the default
path, not an absolute stop — the user may still explicitly ask to close the story
anyway. That request routes to Phase 8's menu, and Phase 8's own `scope_changes`
always-ask rule is what stands between that request and a silent close in
autonomous mode.

---
