# /test-setup — Phase 2: Present Plan

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Present Plan

Based on the layers detected and the existing state, present a plan. List only
the layers in scope, but **name every configured layer you are not touching and
why** (already set up, not in the argument, `PENDING`), so an omitted layer is
never mistaken for a covered one.

```
## Test Setup Plan — [stack summary]

I will create the following (skipping any that already exist):

[backend: Go]        backend/**/*_test.go beside the code — no files needed;
                     integration tests go behind the `integration` build tag
[backend: Ktor]      backend/src/test/kotlin/, backend/src/integrationTest/kotlin/
[web]                web/e2e/ + Vitest and Playwright config (versions from pins.yaml)
[site]               site/e2e/ (Playwright smoke)
[android]            mobile/android/app/src/test/ and androidTest/
[kmp]                mobile/shared/src/commonTest/kotlin/
[ios]                test targets notes only (Xcode project edits are not scaffolded)
[contracts]          consumer contract-test locations + README entry

production/qa/
  README.md         — test framework documentation and conventions
  smoke-tests.md    — critical-path list that /smoke-check reads
  evidence/         — run-and-observe records, screenshots, load-test results
  cases/            — test cases per story (qa-tester)

.github/workflows/tests.yml — CI: tests on every push to main and every PR,
                              third-party actions pinned by commit SHA

Pending (NOT SOURCEABLE — not created, listed in the summary):
  [each item the stack reference and research note do not cover]

Layers not touched: [layer — reason]

Estimated time: ~10 minutes.
```

Ask: "May I create these files? I will not overwrite any test files or configs
that already exist at these paths. Build files (`build.gradle.kts`, `package.json`,
`go.mod`) are not edited — I will show the exact change for you to approve."

**If the user declines**, close with `BLOCKED — approval declined` (nothing is
created, nothing is reported as COMPLETE or PARTIAL).

**At `collaborative` and `guided`** — do not proceed without approval. These are
**new** files, and `automation-modes.md` gates new-file writes in `guided` too,
so the answer is the same in both modes. **At `autonomous`** — create them and log
the decision; do not block. An unconditional gate here would read as "block even
in autonomous" and contradict this skill's own header.

---
