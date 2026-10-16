# Test Evidence: [Story Title]

> **Story**: `[path to story file]`
> **Story Type**: [Logic | Integration | Contract | Security | Performance | UI | Config]
> **Date**: [date]
> **Tester**: [who performed the test]
> **Build / Commit**: [version or git hash]
> **Environment**: [local compose / staging; stack versions; data volume]

<!-- Logic / Integration / Contract are proved by automated tests that pass in CI
     (cite the test names and run). Use this record for the story types whose
     proof is an artefact: Security, Performance, UI, Config — and for the
     run-and-observe evidence every user-visible or callable change needs.
     Delete the sections that do not apply to this story type. -->

---

## What Was Tested

[One paragraph describing the feature or behaviour validated. Include the
acceptance criteria numbers from the story that this evidence covers.]

**Acceptance criteria covered**: [AC-1, AC-2, AC-3]

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | [exact criterion text] | PASS / FAIL | [any observations] |
| AC-2 | [exact criterion text — negative / cross-tenant case] | PASS / FAIL | |
| AC-3 | [exact criterion text] | PASS / FAIL | |

---

## Run-and-Observe (all types)

The feature was exercised end-to-end on a running stack (`run-and-observe.md`).

| Check | Done | Evidence file |
|-------|------|---------------|
| Happy path exercised | [ ] | `[file]` |
| Negative path exercised (wrong role / other tenant / invalid input) | [ ] | `[file]` |
| Trace of the request showing handler -> use case -> DB/cache | [ ] | `[file]` |

---

## Security Evidence (Security stories)

| Control | ASVS / MASVS ref | Negative test / result | Location |
|---------|-----------------|------------------------|----------|
| [e.g. object-level authz] | [ID from the official document, looked up at mapping time] | [test name; PASS] | `[path]` |
| [cross-tenant read blocked] | | | |
| [injection / rate-limit / etc.] | | | |

- Dependency scan: [clean | findings + waiver link]
- Threat model: `[docs/architecture/threat-models/<feature>.md]`

---

## Performance Evidence (Performance stories)

| Surface | Budget (`perf-budgets.md`) | Measured p95 | Queries/request | Result |
|---------|---------------------------|--------------|-----------------|--------|
| [GET /v1/...] | [150 ms] | [ms] | [N] | PASS / FAIL |

- Tool and scenario: [k6 script path; ramp / steady / spike]
- Data volume and environment: [rows, tenants, instance size]
- Raw result files: `[file]`

---

## Screenshots / Recordings (UI stories)

List all captured evidence below. Store files in `production/qa/evidence/[story-slug]/`.

**The file must actually be on disk.** The UI gate is BLOCKING by default, and
`/story-done` and `/test-evidence-review` glob for the image — a filename listed
here with no file beside it does not satisfy the gate.

| # | Filename | What It Shows | Viewport / Locale / Theme | Acceptance Criterion |
|---|----------|--------------|---------------------------|----------------------|
| 1 | `[filename.png]` | [brief description] | [1440 / EN / light] | AC-1 |
| 2 | `[filename.png]` | | [390 / AR (RTL) / dark] | AC-2 |

- `/impeccable audit` result: `[file]` — findings fixed: [yes / waived: reason]
- Accessibility spot-check (keyboard, focus, contrast, screen reader): [result]

---

## Config Smoke Check (Config stories)

- Value(s) changed: [limit / price / flag / TTL — old -> new]
- Smoke check: `production/qa/smoke-[date].md` — [PASS / FAIL]

---

## Test Conditions

- **Tenant / account used**: [test tenant, role(s)]
- **Seed data**: [`tools/seed/...`]
- **Platform / device**: [e.g. Chromium 1440 px; Pixel 8 emulator API 35; iPhone 16 simulator iOS 18]
- **Special setup**: [feature flags, provider sandbox, clock overrides]

---

## Observations

[Anything noteworthy that did not cause a FAIL but should be recorded: slow
query, jank, odd copy, a log line that should not be there. These become
candidates for follow-up stories.]

- [Observation 1]

If nothing notable: *No significant observations.*

---

## Sign-Off

A **Security** story needs `appsec-engineer` (or `security-lead`) sign-off, and a
**Performance** story needs `performance-engineer`, before `/story-done` marks it
COMPLETE. A **UI** story is closed by the retained screenshot of each screen it
touched; a sign-off is welcome but not required (`.claude/docs/coding-standards.md`).

**Solo developers**: you may sign yourself. The intent is that someone
deliberately reviews the evidence before marking complete.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Reviewer (appsec-engineer / performance-engineer / ux-designer) | | | [ ] Approved |

*Optional:* add a row for anyone else whose review you want. `/story-done` and
`/test-evidence-review` treat every row in this table as required, so add one
only for someone who will sign.

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances past
the sprint review.

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: Security, Performance, UI, Config story evidence and run-and-observe records*
*Location: `production/qa/evidence/[story-slug]-evidence.md`*
