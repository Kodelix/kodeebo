# /story-done — Phase 3: Verify Acceptance Criteria and Test Results

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Verify Acceptance Criteria and Test Results

**In this file:**

- Automatic verification (run without asking)
- Manual verification with confirmation (use `AskUserQuestion`)
- Unverifiable (flag without blocking)
- Test-Criterion Traceability
- Test results — did they pass?
- Test Evidence Requirement by story type
- Run-and-observe record

For each acceptance criterion in the story, attempt verification using one of
three methods:

### Automatic verification (run without asking)

- **File existence check**: `Glob` for files the story said would be created.
- **Test file check**: if a test file path is mentioned, confirm the file exists
  with `Glob` — existence is established here; whether the tests **passed** is
  established under "Test results" below, from output, never from the file's presence.
- **No hardcoded business values check**: `Grep` the implemented files (all code
  roots from `resolve_code_root`) for numeric/string literals that should be
  configuration — prices, plan limits, quotas, TTLs, timeouts, retry counts, feature
  flags. **If the code roots are unresolved, report `NOT ASSESSED — code roots
  unresolved` rather than zero hits.**
- **No hardcoded user-facing strings check** (web, mobile): `Grep` UI code for
  literal user-visible strings that should be in the translation resources
  (Arabic + English). Same unresolved-roots rule.
- **Dependency check**: if a criterion says "depends on X", check that X exists
  (a contract operation in `contracts/`, a migration, a port, a config key).
- **Secrets check**: `Grep` the changed files for credential-shaped literals
  (keys, tokens, `password =`, connection strings with passwords); and, if
  `gitleaks` is installed, run `gitleaks dir <changed paths>` and quote the
  output — not installed → `not run — gitleaks not installed`.

### Manual verification with confirmation (use `AskUserQuestion`)

- Criteria about subjective qualities ("clear error message", "feels responsive")
- Criteria about visible behaviour that has no retained screenshot or API record
  yet — these are asked, never marked verified from reading the code: the code
  says what should happen, not what the running product does
- Performance criteria ("completes within X ms") — **a number or nothing**: if a
  measured result is in the evidence directory, quote it; otherwise it is
  `UNTESTED`, not "accepted as assumed"

Batch up to 4 manual verification questions into a single `AskUserQuestion` call:

```
question: "Does [criterion]?"
options: "Yes — passes", "No — fails", "Not tested yet"
```

Map each answer: `Yes — passes` → confirmed; `No — fails` → FAILS;
`Not tested yet` → not evaluated — UNTESTED in the traceability table below, and
the verdict is NOT ASSESSED (Phase 7) until someone checks it. A user's
`Yes — passes` for a criterion that names something visible or callable, with no
retained observation behind it, is an assertion — flag it under Run-and-observe
below.

### Unverifiable (flag without blocking)

Criteria that cannot be tested until a deployed stack, a real provider or a
store review exists (production TLS, a provider's live mode, Play/App Store
review, a customer's self-hosted environment):
- Mark as: `DEFERRED — requires [deployed stack | provider live mode | store review | customer environment]` and name the condition that releases it.
- A DEFERRED criterion is **evaluable later**, so it does not block — but it is listed in the Completion Notes so it is not lost, and the release checklist picks it up.

### Test-Criterion Traceability

After completing the pass/fail/deferred check above, map each acceptance
criterion to the test or evidence that covers it:

1. For each acceptance criterion, is there a test or retained observation that
   directly verifies it?
   - **Unit test**: a test file/function name matching the criterion's subject in the layer's unit-test location (`*_test.go`, `src/test/kotlin/`, `*.test.ts(x)`, `src/commonTest/kotlin/`, Swift Testing target) — `Glob` and `Grep`.
   - **Integration test**: Testcontainers test in the layer's integration location (`integration` build tag, `src/integrationTest/kotlin/`, …).
   - **Contract test**: consumer contract test against `contracts/<file>`.
   - **Negative test**: wrong role, other tenant, injection, rate limit, replay — covers the corresponding negative criterion.
   - **Manual confirmation**: verified via `AskUserQuestion` above with "Yes — passes" — counts for subjective criteria only.
   - **Retained observation**: a retained screenshot, API request/response record or trace under `production/qa/evidence/<STORY-ID>/` that shows it (the `Run result: OBSERVED` from `/dev-story`). "Shows it" means you opened the file with `Read` and saw it; a checkpoint's `Run result: OBSERVED — <text>` is `/dev-story`'s description, to quote as such, not yours. **Never describe an image you have not opened.**

2. Produce a traceability table:

```
| Criterion | Test / evidence | Status |
|-----------|-----------------|--------|
| AC-1: [criterion text] | backend/internal/billing/app/change_plan_test.go::TestChangePlan_RejectsOverQuota | COVERED |
| AC-2: [other tenant gets 404] | backend/internal/billing/adapters/http/invoice_authz_test.go::TestInvoice_OtherTenant_NotFound | COVERED |
| AC-3: [criterion text] | production/qa/evidence/BILLING-003/02-plan-page-ar.png | COVERED |
| AC-4: [p95 ≤ 150 ms] | — | UNTESTED |
```

3. Apply these escalation rules at every `qa.level`:

   - If **>50% of criteria are UNTESTED**: escalate to **BLOCKING** — evidence is insufficient to confirm the story is actually done. The verdict in Phase 7 cannot be COMPLETE until coverage improves.
   - If **some (≤50%) criteria are UNTESTED**: remain ADVISORY — does not block completion, but must appear in Completion Notes.
   - **Any negative or cross-tenant criterion that is UNTESTED is BLOCKING** for a story that touches tenant data, whatever the percentage.
   - If **all criteria are COVERED**: no action beyond including the table in the report.

4. For any ADVISORY untested criteria, add to the Completion Notes in Phase 8:
   `"Untested criteria: [AC-N list]. Recommend adding tests in a follow-up story."`

### Test results — did they pass?

`.claude/docs/coding-standards.md` and `testing-standards.md` require tests that
**pass**, not tests that exist. This phase establishes which half is known.

Skip the run-level checks for a Config story (no code tests). They are **not skippable
at any `qa.level`** for Logic, Integration, Contract and Security stories, a Security
story's negative tests, or a tenant-data story's isolation tests.

1. **Find the result evidence** for each layer the story touched, newest first:
   - `production/qa/evidence/<STORY-ID>/checks-<layer>.md` written by `/dev-story` Phase 6 (command, exit code, trimmed output);
   - a CI run URL/output the user pastes;
   - output of a run made now (step 3).
2. **Check it is current** by the **Dating rule** in `2-read-story.md` — not by `git log` alone, which cannot see uncommitted edits: the evidence file's date (its recorded date line, else its commit date if clean, else its mtime) must be at or after the newest change to the story's implementation and test files (commit date if each is tracked and clean, else `git status --porcelain` shows it modified and its mtime counts). Evidence older than the code is **stale** — treat as absent. Print the `freshness source:` next to each layer's result; no usable source on either side → the result is `stale` (unknown currency is not currency).
3. **If absent or stale**, ask via `AskUserQuestion` (major decision):
   - Prompt: "No current test results for this story. Run the layer checks now?"
   - Options: `[A] Run them now (Recommended)` / `[B] I'll supply CI output` / `[C] Skip — record as not run`
   - On [A]: run the commands in `/dev-story`'s layer-checks table (directory `.claude/skills/dev-story`, then `references`, file `layer-checks.md`) for each lane the story touched — unit, integration (needs a container runtime), lint, dependency scan. This skill's `Bash` grants cover the root-level commands (`go -C`, `pnpm -C`, `swift test`, `./gradlew`, `osv-scanner`, `gitleaks`, `migration-lint.sh`, `project-coherence.sh`); a row that names an agent there (`golangci-lint`, `govulncheck` in `backend/`; the migration up/down matrix) is run by that agent spawned via `Agent`, and a command with no grant and no agent is `not run — not runnable from this skill`. Save each output to `production/qa/evidence/<STORY-ID>/checks-<layer>.md` (new files under a path this skill names — no second prompt). Report real output: command, exit code, decisive lines.
   - On [C], or when a tool is missing / the container runtime is unreachable / the host is wrong (Swift tests off macOS): that check is **`not run — [reason]`**.
4. **Classify** per layer: `passed (exit 0, N tests)` / `FAILED` / `not run — [reason]` / `stale`. A **FAILED** result is a failing criterion → **BLOCKED** (report the failing test; never auto-fix). A `not run` result on a BLOCKING test gate means the gate is **not checked** (not `unmet`, not `met`) and the verdict is at best **NOT ASSESSED** — never COMPLETE on the strength of a test file that nobody executed.
5. Confirm the new tests are in the count the runner reported (a test file at a path no runner picks up is "0 tests" — check the summary line). **A suite that started and executed zero tests is `FAILED — 0 tests executed`** (a vacuous pass is a fail, BLOCKED); a suite that could not start is `not run` (NOT ASSESSED).

### Test Evidence Requirement by story type

**`qa.level` (Phase 1) never removes a presence check.** The Logic, Integration,
Contract and Security presence checks below, the UI and run-and-observe checks and the
tenant-isolation tests run at every tier. `qa.level` only adds: at `standard`, the
extra evidence for the story's own type; at `full`, for every story type, plus the
coverage signal. The `testing.strict` resolution below applies to every check that runs.

**Resolve the gate level for this story's type.** BLOCKING means a gap prevents
the COMPLETE verdict in Phase 7; ADVISORY means a gap is noted in the Completion
Notes but does not block. Resolve it from the `testing.strict` / `performance.enforce`
values **already in the resolved-config block at the top of this skill** — not by
reading `project.yaml` yourself (`testing.strict.*` is on the `/settings --local`
whitelist; reading `project.yaml` alone silently ignores a developer's local override):

1. Map the story Type to a `testing.strict` key — Logic→`logic`, Integration→`integration`, Contract→`contract`, Security→`security`, Performance→`performance`, UI→`ui`, Config→`config`. If its value is `true` (case-insensitive) → BLOCKING; `false` → ADVISORY; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — it applies to every type.
3. Else use the default in the table below. For Performance, `performance.enforce: block` makes it BLOCKING; `warn` → ADVISORY; `off` → the performance gate is switched off for the project and the report says so (the budget is still recorded).

Only `true` and `false` are recognised; any other present value is treated as
unset and surfaced to the user.

| Story Type | Required evidence | Default gate level |
|---|---|---|
| **Logic** | Unit tests beside the code — exist **and pass** | BLOCKING |
| **Integration** | Testcontainers integration test against the real dependency — exist and pass | BLOCKING |
| **Contract** | Consumer contract test against `contracts/` passing + breaking-change check output; authz tests per endpoint | BLOCKING |
| **Security** | Negative tests (authz bypass, cross-tenant, injection, rate limit as applicable) passing + ASVS/MASVS mapping in `production/qa/evidence/<STORY-ID>/`; sign-off by `appsec-engineer` or `security-lead` (the user may sign for themselves — a deliberate review) | BLOCKING |
| **Performance** | Load-test result (k6) vs the `perf-budgets.md` row, with environment and data volume, in `production/qa/evidence/<STORY-ID>/`; query-count assertion | ADVISORY (BLOCKING when `performance.enforce: block`) |
| **UI** | Retained screenshot of every screen touched (1440 px and 390 px; Arabic/RTL and English; light and dark if supported) + `/impeccable audit` result, in `production/qa/evidence/<STORY-ID>/` | BLOCKING |
| **Config** | Smoke-check pass in `production/qa/smoke-*.md` | ADVISORY |

The **Default** column applies when `testing.strict` is unset. **Security evidence
on a security-sensitive story is always BLOCKING**, whatever the setting
(`pe-dod.md`).

> **Exception — `/smoke-check`.** The ADVISORY default for **Config** governs
> per-story evidence, which is what this skill checks. `/smoke-check` is a
> build-health gate, so its own unset default is BLOCKING. The divergence is
> intentional; do not "fix" either side.

**For Logic stories**: read the story's **Test Evidence** section for the exact
required path; `Glob` that path; if not found, search the layer's test location
broadly. No test file → flag at the resolved level: "Logic story has no unit test
file at `[exact-path]`." A file that exists but whose result is `FAILED`,
`stale` or `not run` is handled by "Test results" above, not here.

**For Integration stories**: `Glob` the exact path, then the layer's integration
location. Confirm it uses a real container (Testcontainers/compose service), not a
mocked database or cache client — a "mocked integration test" is not evidence.
None found → flag at the resolved level.

**For Contract stories**: the consumer test and the breaking-change output exist,
the operation is in `contracts/`, and generated clients were regenerated in the
same change (no hand-edited generated code).

**For Security stories**: the ASVS / MASVS requirement IDs satisfied are listed
(copied from the threat model/research note — **IDs looked up in the official
documents, never recalled**); each is tied to a passing negative test; the
dependency scan result is retained. A Security story with no ASVS mapping or no
negative tests is flagged BLOCKING.

**For Performance stories and any story on a hot path**: the load-test file
exists with environment, data volume and thresholds that equal the budget row;
the budget row is cited (`budget not yet set` is a finding, not a pass).

**For UI stories**: glob `production/qa/evidence/<STORY-ID>/` for retained
screenshots — one per screen touched, at the viewports/locales the plan lists,
including Arabic (RTL) — and the `/impeccable audit` summary. What closes the
story follows the evidence table in `coding-standards.md`, the same at every
`qa.level`:
- No screenshot: "No visual evidence found. Capture each screen this story touched and save it under `production/qa/evidence/<STORY-ID>/` before final closure."
- A listing or evidence doc but no image on disk: "Evidence doc found at `[path]` but no screenshot is retained. A described check is an assertion, not evidence."
- Screenshots in English only for a screen with text: "No Arabic/RTL capture found — RTL is a requirement (`web-react.md`)." (flag at the resolved level)
- No `/impeccable audit` result: flag at the resolved level.
- **Open each image with `Read`** and compare it to the criteria — clipped text, un-mirrored RTL layout, missing empty/error state, a raw ID or token on screen are defects. Record what you saw in one line per image.

**For Config stories**: any `production/qa/smoke-*.md`. None → flag at the resolved level: "No smoke check report found. Run `/smoke-check`." A config value that is a price, quota or flag must live in config/database (not inline) — the hardcoded-value grep above applies.

**If no Story Type is set**: flag as **ADVISORY** — "Story Type not declared. Add
`Type: [Logic|Integration|Contract|Security|Performance|UI|Config]` to the story
header to enable evidence-gate enforcement in future stories."

Any BLOCKING test-evidence gap prevents the COMPLETE verdict in Phase 7.

### Run-and-observe record

**A compile is not a run** (`.claude/docs/run-and-observe.md`). For every story
that changes something a user can see or call, the observation is on disk in
`production/qa/evidence/<STORY-ID>/`. Not waived at any `qa.level`.

Check, from the Phase 2 directory listing:

| What the story changed | Required in the folder | Missing → |
|---|---|---|
| An API endpoint / job / webhook | request + response records per actor (owner, member, other tenant, anonymous) + one invalid-input call (`api-<endpoint>.md`), secrets redacted; for a job or webhook, the trace/span list and resulting state | flag at the resolved gate level for the story type (Contract/Integration/Security: BLOCKING by default) |
| A web or mobile screen | the UI screenshots above | UI gate (BLOCKING by default) |
| Anything user-visible or callable | one retained **trace** (screenshot or exported span list) showing handler → use case → DB/cache, with `trace_id` in the matching log line | DoD gate 4 evidence gap (Phase 6) |
| Nothing visible or callable (pure domain refactor) | the `/dev-story` line `Run result: N/A — <reason>` with a reason that names why nothing is observable ("it's a Logic story" is not a reason) | — |

Read the `Run result:` line from the `/dev-story` checkpoint in
`production/session-state/active.md` — only when its **Current task** names this
story; a later `/dev-story` overwrites it — or from the story's `## Completion
Notes`. `OBSERVED` with retained paths: note it, and confirm the paths are on
disk. `NOT VERIFIED — <reason>` on a story whose criteria name anything visible or
callable: flag at the resolved gate level. No `Run result:` line at all: flag as
ADVISORY — "the implementation summary carries no run result; confirm the stack
was brought up and the feature exercised before closure" — unless the folder
holds the observations, in which case the folder is the evidence. A user's
`Yes — passes` to a criterion that names something visible or callable, with no
retained observation in the folder, is flagged at the resolved gate level for
the story type, as for `NOT VERIFIED`.

**The negative path counts**: an observation set with only the happy path is
`OBSERVED — partial` and is reported with the missing negative calls named.

---
