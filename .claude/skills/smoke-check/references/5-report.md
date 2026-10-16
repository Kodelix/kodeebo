# /smoke-check — Phase 5: Generate Report

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Generate Report

**In this file:**

- The report template, with the verdict rules
- `NOT ASSESSED` and where it ranks

Assemble the full smoke check report:

````markdown
## Smoke Check Report
**Date**: [date]
**Sprint**: [sprint name / number, or "Not identified"]
**Stack**: [`stack` line of the resolved config; layers in scope with code roots]
**Environment**: [compose file; stack started by this run | already running; coherence `BEHIND` / `FLOATING` / `SKIPPED` lines, or "coherent"; toolchains missing]
**QA Plan**: [path, or "Not found — run /qa-plan first"]
**Argument**: [sprint | quick | blank]

---

### Automated Tests

One line per suite. **Status** is one of: PASS ([N] tests, [N] passing) |
PASS WITH WARNINGS ([N] passing; [skipped tests without a linked issue /
quarantined tests]) | FAIL ([N] failures, or did not complete: [timeout | build
error | no fresh results], or zero tests executed) | NOT ASSESSED ([reason, e.g.
Testcontainers not exercised]) | NOT RUN ([reason, e.g. Docker unavailable, no
emulator, not a macOS host, command not sourced]) | NO TESTS (layer in scope, no
test files).

| Suite | Command source | Status |
|---|---|---|
| Go unit | [product script / CI / stack reference] | |
| Go integration (`-tags integration`) | | |
| Ktor / Kotlin unit and integration | | |
| Web unit (Vitest) | | |
| Web e2e (Playwright) | | |
| Android unit / instrumented | | |
| KMP shared | | |
| iOS (Swift Testing / XCUITest) | | |
| Contract | | |

[Delete rows for layers not in scope — but state each deleted layer by name:
"Layers not in scope: [list]". A layer in scope with no row is a report defect.]

[If FAIL, list failing tests:]
- `[test name]` — [brief failure description from runner output]

[If NOT RUN:]
"Manual confirmation required: did the [layer] suite pass in your IDE or CI?
This determines whether the row contributes to a FAIL verdict."

**Quarantined tests** (from `production/qa/flaky-register.md`): [list, past-deadline
ones named | none | register not found]

---

### Test Coverage

| Story | Type | Gate | Test file / evidence | Coverage Status |
|-------|------|------|----------------------|----------------|
| [title] | Logic | BLOCKING | `backend/internal/[context]/app/[x]_test.go` | COVERED |
| [title] | Security | BLOCKING | `production/qa/evidence/[STORY-ID]/` | EVIDENCED |
| [title] | UI | BLOCKING | `production/qa/evidence/[STORY-ID]/web-[screen]-1440-ar.png` | EVIDENCED |
| [title] | Contract | BLOCKING | — | MISSING ⚠ |
| [title] | Config | ADVISORY | — | EXPECTED |

**Summary**: [N] covered, [N] evidenced, [N] missing, [N] expected, [N] unknown.

---

### Critical-Journey Checks (Part A)

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| A1 | Stack healthy | PASS / FAIL / NOT RUN — [reason] | `production/qa/evidence/smoke-[date]/…` |
| A2 – A10 | … | | |

---

### Manual Smoke Checks (Part B)

- [x] Current build opened this session — yes [or: `NOT RUN — build not opened this session`; the batches below were not asked]
- [x] App shell loads and sign-in works — PASS
- [x] [Primary feature] — PASS
- [ ] [Other check] — FAIL: [user's description]
- [x] Migrations / existing tenant data — PASS
- [-] Performance — not checked this session

---

### Missing Test Evidence

Stories that must have test evidence before they can be marked COMPLETE via
`/story-done`:

- **[story title]** (`[path]`) — Logic story has no test file.
  Expected location: `[test location for its code root]`

[If none:] "All Logic, Integration, Contract and Security stories have test coverage."

---

### Surface-Specific Results *(only if `--surface` was provided)*

| Surface | Checks Run | Passed | Failed | Not run | Surface Verdict |
|---------|-----------|--------|--------|---------|-----------------|
| Web | [N] | [N] | [N] | [N] | PASS / FAIL / NOT ASSESSED |
| Android | [N] | [N] | [N] | [N] | PASS / FAIL / NOT ASSESSED |
| iOS | [N] | [N] | [N] | [N] | PASS / FAIL / NOT ASSESSED |
| Self-hosted | [N] | [N] | [N] | [N] | PASS / FAIL / NOT ASSESSED |

**Surface notes**: [any surface-specific observations not captured in pass/fail]

Any surface with one or more FAIL checks contributes to the overall FAIL verdict.

---

### Not run

[Every check that did not execute, by name, with the reason and the one thing
that would make it runnable. "Nothing was skipped" is stated explicitly when
true — a silent skip and a successful run are the same artifact.]

---

### Verdict: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[Verdict rules — first matching rule wins:]

**FAIL** if ANY of:
- A suite ran and reported one or more test failures
- A suite did not complete: a timeout, a build or compile error, or no fresh
  results file after the run (Phase 2 names each layer's form)
- A suite started and **executed zero tests** (exit code notwithstanding) — a
  vacuous pass is a fail
- The stack never became healthy (`up --wait` failed, an unhealthy service, a
  migration failure) — the finding is the failing service's log tail
- Any Part A check A1 – A8 returned FAIL — **A7 (tenant isolation) is an S1**
- Any Batch 1 (core stability) check returned FAIL
- Any Batch 2 (primary sprint feature or regression check) returned FAIL
- Any surface check returned FAIL

**NOT ASSESSED** if ANY of:
- A suite is **unconfirmed NOT RUN** — nobody has reported a result
- A runner could not run (Docker unavailable for a Testcontainers suite, toolchain
  missing, command not sourced for the layer)
- A layer is in scope with test files, but one of its suites (Android
  instrumented, iOS) is `NOT RUN`, unconfirmed — the unit result does not cover it
- A layer in scope has `NO TESTS` (at every `qa.level` — tests are not waived at `minimal`)
- `contracts/` exists and the Contract line is `NO TESTS` or `NOT RUN`
- Part A could not run (no Docker, no compose file, stack not started, endpoint not
  defined, no seeded tenant) and the developer has not confirmed the equivalent
  checks as passed — **including A7**: a skipped tenant-isolation check is not a
  passed one
- A Batch 1 or Batch 2 check could not be executed (no build, no device,
  surface unavailable) as opposed to executing and failing — including a Batch 1
  answer that the build was not opened this session
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suites pass matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 3 was offered and skipped** ("Performance not checked this session").
  It is not a FAIL, not an execution failure, and not "PASS or N/A", so without
  this line it matches no rule at all and renders as `[-]` beside a PASS
- The code-root scan returned an empty list (Phase 1 step 1)

**PASS WITH WARNINGS** if ALL of:
- Automated tests PASS or PASS WITH WARNINGS, or
  NOT RUN **and the developer has confirmed the result from their IDE or CI**
- Part A and all Batch 1 and Batch 2 smoke checks PASS or N/A
- At least one warning: a Logic, Integration, Contract or Security story with
  MISSING test evidence, a Performance or UI story with MISSING evidence, a
  skipped test without a linked issue, a quarantined test (or one past its
  14-day deadline), an unpinned CI action, a toolchain below its pin, a `BEHIND`
  coherence line, or a NOT RUN suite the developer confirmed

**PASS** if ALL of:
- Automated tests PASS
- All Part A checks and all smoke checks in all batches PASS or N/A
- No MISSING test evidence entries
- Nothing under "Not run" other than checks marked N/A with a reason
````

**`NOT ASSESSED` — the build nobody could check.** Rank: it **outranks PASS and
PASS WITH WARNINGS** and **ranks below FAIL**. A suite that never ran has not
shown the build is healthy; a suite that ran and failed is the more actionable
finding and must not be demoted behind one that did not run.

The rule below — **never treat NOT RUN as an automatic FAIL** — is unchanged and
still correct: NOT ASSESSED is not a FAIL, and it ranks below one. What matters is
that an unrun suite never resolves to a *pass* verdict while waiting for a
confirmation that may never come. Confirmed NOT RUN (the developer reports the
result from their own IDE or CI) lands at PASS WITH WARNINGS, because somebody
did look.

---
