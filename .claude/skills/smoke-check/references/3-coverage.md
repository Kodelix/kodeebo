# /smoke-check — Phase 3: Check Test Coverage

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Check Test Coverage

Draw the story list from, in priority order:
1. The QA plan found in Phase 1 (its Test Summary table lists expected test
   file paths and evidence per story)
2. The current sprint plan from `production/sprints/` (most recently modified
   file)
3. If the `quick` argument was passed, skip this phase entirely and note:
   "Coverage scan skipped — run `/smoke-check sprint` for full coverage
   analysis."

For each story in scope:

1. Read the story's `Code root` and `Type` header fields (`> **Code root**`,
   `> **Type**`) and its epic slug from the file path
   (e.g., `production/epics/billing/story-001.md` → `billing`)
2. Glob the test location for that code root (`directory-structure.md` → Code
   roots) for files whose name contains the story slug or a closely related
   term — e.g. `backend/internal/<context>/**/*_test.go`,
   `web/src/features/<feature>/**/*.test.ts(x)`, `web/e2e/`,
   `src/integrationTest/kotlin/`
3. Check the story file itself for a `## Test Evidence` section and a
   `Test file:` field, and the evidence directory
   `production/qa/evidence/<STORY-ID>/` for the files that story type requires

Assign a coverage status to each story:

| Status | Meaning |
|--------|---------|
| **COVERED** | Logic / Integration / Contract: a test file was found matching this story's context and scope |
| **EVIDENCED** | Security, Performance or UI: the required artifact is **on disk** — Security: negative tests plus the control mapping; Performance: a load-test result; UI: a screenshot image file for each screen touched |
| **MISSING** | Logic, Integration, Contract or Security story with no matching test or required artifact; Performance or UI story with no evidence file |
| **EXPECTED** | Config story — no test file required; this smoke run is its evidence |
| **UNKNOWN** | Story file missing or unreadable |

A filename listed in a story's Test Evidence section with no file beside it is
**MISSING**, not EVIDENCED — `/story-done` globs for the file, so this check
does too. A Security story whose threat model is missing
(`docs/architecture/threat-models/<feature>.md`) is MISSING regardless of its
tests.

Show each row's gate level next to its status, resolved from `testing.strict`
in the config block (`unset` → the default in `coding-standards.md`:
Logic, Integration, Contract, Security, UI BLOCKING; Performance ADVISORY, or
BLOCKING when `performance.enforce: block`; Config ADVISORY). The level does not
change this skill's verdict — `/story-done` is where a missing test blocks a
story — but the reader sees which gaps will block there.

MISSING entries are advisory gaps. They do not cause a FAIL verdict but must
appear prominently in the report and must be resolved before `/story-done` can
fully close those stories.

---
