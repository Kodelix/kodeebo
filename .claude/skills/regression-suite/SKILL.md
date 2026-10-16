---
name: regression-suite
description: "Map test coverage to the critical journeys (sign-in, core action, billing, licence activation, tenant isolation), find fixed bugs lacking regression tests, flag drift from new features."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.


# Regression Suite

This skill ensures that every bug fix is backed by a test that would have
caught the original bug — and that the regression suite stays current as the
product evolves. It also detects when new features have been added without
corresponding regression coverage.

A regression suite is not a new test category — it is a **curated list of
tests already in the code roots** that collectively cover the product's
critical journeys and known failure points. This skill maintains that list.

**Output:** `production/qa/regression-suite.md`

**When to run:**
- After fixing a bug (confirm a regression test was written or identify the gap)
- Before a phase gate — at `qa.level: full`, `/gate-check` requires a regression suite
- Before a release (`/release-checklist`, `/team-release`) and as part of sprint close, to detect coverage drift

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: `modes.workflow` as resolved above — supplied by `modes.rigor`
unless set explicitly — per `.claude/docs/workflow-modes.md`; in `audit` mode consider
`workflow_overrides.system_overrides.<feature>` per feature (the spec filename
stem) as each spec is read. It sets whether spec acceptance criteria are mapped or
coverage is smoke-only — see Step 2c.

**`qa.level`**: controls whether this **extra** artefact (the curated suite
manifest) is generated at all — it never waives a test. At `minimal`, the
manifest is **not generated** (report that and stop; the verdict is `WAIVED`,
Section 7); at `standard`, generate it at Hardening-stage entry; at `full`, at
Production-stage entry. Logic, Integration, Contract and Security tests exist and
pass at every level (`.claude/docs/coding-standards.md`). Distinct axis from
`workflow`.

## 1. Parse Arguments

**Early `qa.level` guard (resolved above):** if `qa.level: minimal`, the
regression suite is **not generated** — report "Regression suite not generated at
qa.level minimal" and **STOP here, before any scan**, in every mode
(`update` / `audit` / `report`). This is the `qa.level` axis; it is distinct from
the `workflow`-tier `minimal` branch in Step 2c (which only changes the
critical-journey *source*, not *whether* the suite runs). Do not enter Step 2c's
`minimal` branch on account of `qa.level`. This stop's verdict is
**WAIVED** (Section 7) — a deliberate level choice, not a failure to look; the
tests themselves are not waived, and nothing was scanned.

**Modes:**
- `/regression-suite update` — scan new bug fixes this sprint and check
  for regression test presence; add new tests to the suite manifest
- `/regression-suite audit` — full audit of all critical journeys vs.
  existing test coverage; flag journeys with no regression test
- `/regression-suite report` — read-only status report (no writes); suitable
  for sprint reviews
- No argument — if a sprint is clearly active (sprint plan exists with in-progress stories), run `update`. If ambiguous or no active sprint is detected, use `AskUserQuestion`:
  - Prompt: "No subcommand specified. Which mode do you want to run?"
  - Options:
    - `[A] update — scan new bug fixes this sprint and add missing regression tests`
    - `[B] audit — full audit of all critical journeys vs. existing test coverage`
    - `[C] report — read-only status report (no writes)`

---

## 2. Load Context

### Step 2a — Load existing regression suite

Read `production/qa/regression-suite.md` if it exists. Extract:
- Total registered regression tests
- Last updated date
- Any tests flagged as `STALE` or `QUARANTINED`

If it does not exist: note "No regression suite found — will create one."

### Step 2b — Load test inventory

Resolve the code roots with `resolve_code_root` (`layout.code_roots`, else the
conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist —
`.claude/docs/directory-structure.md` → Code roots). **An empty result means the
inventory scan did not run** — report `Coverage: NOT ASSESSED — no code roots
resolved`, never "no tests". Then glob the test files of each root:

| Layer | Test files |
|---|---|
| Go backend | `backend/**/*_test.go` (integration tests carry the `integration` build tag) |
| Ktor backend | `backend/src/test/kotlin/**`, `backend/src/integrationTest/kotlin/**` |
| Web / site | `web/**/*.test.ts(x)`, `web/e2e/**`, `site/e2e/**` |
| KMP shared | `mobile/shared/src/commonTest/kotlin/**` |
| Android | `mobile/android/app/src/test/**`, `mobile/android/app/src/androidTest/**` |
| iOS | the Swift Testing / XCTest targets under `mobile/ios/` |
| Contracts | consumer contract tests (by path or name containing `contract`) |

For each file, note the layer, the feature or bounded context (from the directory
path) and the file name. Do not read test file contents unless needed for
name-to-test mapping. Report the count per layer and **name every layer in the
`stack` line that has no test files** — silence about a layer reads as coverage.

### Step 2c — Load critical journeys

For `audit` mode, build the journey list. The studio treats these five as
critical for a SaaS product; each is either mapped or recorded
`NOT APPLICABLE — [reason]` (never silently dropped):

| Journey | Applies when | Expected coverage |
|---|---|---|
| **Sign-in and session** (sign-up, login, MFA/OTP, token refresh, logout) | always | use-case tests with authz denied; auth/refresh contract tests; one e2e journey |
| **Core action** (the one thing the product exists to do — from `design/product-brief.md`) | always | use-case and adapter tests; contract test; one e2e journey |
| **Billing and entitlements** (subscribe, upgrade/downgrade, webhook, entitlement change, invoice) | the product takes money | provider-integration tests (success, 4xx, 5xx/timeout, duplicate webhook, invalid signature); idempotency; one e2e journey on the provider sandbox |
| **Licence activation** (issue, activate, offline grace, revoke) | `distribution` is `self-hosted` or `hybrid` | signature and expiry tests; activation negative tests; one e2e journey |
| **Tenant isolation** | `tenancy.model` is not `single-tenant` | per repository adapter: tenant A's row invisible to tenant B; per endpoint: wrong-tenant returns 404; RLS enabled and forced on every `tenant_id` table |

Add the product's own journeys from the sources below. Then scope the rest of
the list by each feature's workflow tier (resolved above):
- **`full`** — read the spec (`design/specs/<feature>.md`) and map critical
  journeys from all sections.
- **`standard`** — same, from the required sections (Detailed Behaviour, Data &
  Contracts, Acceptance Criteria, and Edge Cases & Failure Modes where the
  feature calls a provider, moves money, changes entitlements or runs
  asynchronously). A feature pinned higher via `system_overrides` is mapped at
  its higher tier.
- **`minimal`** — **skip the spec scan** (there are no specs at this tier). Take
  the journeys from `design/product-brief.md` (its core journey and MVP features)
  plus the five above, and read the latest smoke-check report in
  `production/qa/smoke-*.md`: the critical paths it exercised are the regression
  scope (Step 3 maps coverage against those). If no smoke report exists, stop with
  Verdict: **NOT ASSESSED — no smoke report to take critical journeys from** —
  run `/smoke-check` first.

(Tier affects `audit` mode only; `update` and `report` modes are tier-independent.)

For each in-scope feature's spec, extract:
- Acceptance Criteria (these define the critical journeys), including the
  negative and cross-tenant criteria
- Detailed Behaviour rules with numbers (limits, proration, thresholds) — each
  rule with a number must have a boundary test
- Edge Cases & Failure Modes (known edge cases should have regression tests)

For `update` mode: skip the full spec scan. Instead read the current sprint plan
and story files to find stories with Status: Complete this sprint.

### Step 2d — Load closed bugs

Glob `production/qa/bugs/*.md` and filter for bugs with a `Status: Closed`
or `Status: Fixed` field. Note:
- Which story, feature or layer the bug was in
- Its severity (S1–S4 by the `qa-lead` rule)
- Whether a regression test was mentioned in the fix description

If `production/qa/bugs/` does not exist or holds no closed bug, say so in the
report: `Bug regression coverage: NOT ASSESSED — no closed bugs found`. It is not
"all bugs covered".

---

## 3. Map Coverage — Critical Journeys

For `audit` mode only. (At `minimal` the critical journeys come from the product
brief and the smoke-check report identified in Step 2c, not from spec acceptance
criteria — map coverage against those and skip the spec-criterion loop below.)

For each critical journey and each spec acceptance criterion, determine whether a
test exists **at the level that can catch it**:

1. Grep the test files from Step 2b for file names and test names related to the
   criterion's key noun/verb (test names state the behaviour —
   `.claude/rules/test-standards.md`)
2. Assign coverage:

| Status | Meaning |
|--------|---------|
| **COVERED** | A test exists at the right level that targets this criterion's logic, including its negative path |
| **PARTIAL** | A test exists but doesn't cover all cases (e.g. happy path only; no wrong-tenant or authz-denied case; no cache-down case; no duplicate-webhook case) |
| **MISSING** | No test found for this critical path |
| **EXEMPT** | UI visual criterion — verified by its retained screenshots (`production/qa/evidence/`), not by an automated test; the evidence must exist on disk, else MISSING |

3. Elevate MISSING or PARTIAL items on money, entitlements, licences, auth,
   tenant isolation, formulas or state machines to **HIGH PRIORITY** gaps — these
   are the most likely sources of an S1/S2 regression.
4. For the **tenant-isolation** journey, derive the set instead of listing it:
   every repository adapter and every endpoint found in the code roots and
   `contracts/` is checked for its isolation or wrong-tenant test. An adapter or
   endpoint without one is a MISSING row of its own.

---

## 4. Map Coverage — Fixed Bugs

For each closed bug:

1. Extract the feature or layer from the bug's metadata
2. Grep the test files for a test that references the bug ID or the specific
   failure scenario
3. Assign:
   - **HAS REGRESSION TEST** — a test was found that would catch this bug
   - **MISSING REGRESSION TEST** — bug was fixed but no test guards against recurrence

For MISSING REGRESSION TEST items:
- Flag them as regression gaps; an **S1 or S2** bug without one is a HIGH
  PRIORITY gap
- Suggest the test at the **lowest level that reproduces the bug**, with a name
  that states the behaviour and a reference to the bug ID — Go
  `Test<Subject>_<Action>_<Expectation>` with `// Regression: BUG-NNNN`, Kotlin a
  backtick sentence, TypeScript `it('… (BUG-NNNN)')`, Swift `@Test("…")`; for a
  cross-tenant bug, a repository or endpoint isolation test as well
- Note: "Without this test, this bug can silently return in a future sprint."

---

## 5. Detect Coverage Drift

Coverage drift occurs when the product grows but the regression suite doesn't.

Check for drift indicators:
- Stories completed this sprint with no corresponding test files in the code roots
- New features added to `design/specs/domain-map.md` since the last regression-suite update
- Specs added or revised since the regression suite was last updated (use Grep
  on file modification hints if available, or ask the user)
- Operations in `contracts/` with no contract test and no authz test
- Migrations added since the last update with no migration test
- Quarantined tests past their 14-day fix-or-delete deadline
  (`production/qa/flaky-register.md`)
- `production/qa/regression-suite.md` last-updated date vs. current date — if gap >
  2 sprints, flag as likely stale

---

## 6. Generate Report and Suite Manifest

### Report format (in conversation)

```
## Regression Suite Status

**Mode**: [update | audit | report]
**Existing registered tests**: [N]
**Test files scanned**: [N across N layers; layers with none: [list]]

### Critical Journey Coverage (audit mode only)
| Journey / feature | Total ACs | Covered | Partial | Missing | Exempt |
|-------------------|-----------|---------|---------|---------|--------|
| Sign-in and session | [N] | [N] | [N] | [N] | [N] |
| Core action | | | | | |
| Billing and entitlements | | | | | |
| Licence activation | NOT APPLICABLE — hosted only | | | | |
| Tenant isolation | | | | | |
| [feature] | | | | | |

**Coverage rate (non-exempt)**: [N]%

### Bug Regression Coverage
| Bug ID | Layer / feature | Severity | Has Regression Test? |
|--------|-----------------|----------|----------------------|
| BUG-NNNN | [layer / feature] | S[N] | YES / NO ⚠ |

**Bugs without regression tests**: [N]

### Coverage Drift Indicators
[List new features, stories, contract operations or migrations with no test coverage, or "None detected."]

### Not checked
[Every scan that did not run and why — a layer with no tests, no code roots, no
bugs directory. "Nothing skipped" is stated explicitly when true.]

### Recommended New Regression Tests
| Priority | Layer | Suggested Test File | Covers |
|----------|-------|---------------------|--------|
| HIGH | [layer] | `[test location for the code root]/[slug]_regression_test.[ext]` | BUG-NNNN / AC-[N] |
| MEDIUM | [layer] | `[test location for the code root]/[slug]_test.[ext]` | [criterion] |
```

### Suite manifest format (`production/qa/regression-suite.md`)

> **Before computing coverage, check the denominator.** If the journey/spec
> sources return **zero critical journeys**, or the test globs return **zero test
> files**, do not emit a percentage — report
> `Coverage: NOT ASSESSED — [no specs or product brief found | no test files found | no code roots resolved]`
> and name which side was empty and the skill that produces it (`/brainstorm`
> for the brief, `/map-domains` and `/design-spec` for specs, `/test-setup` for the test scaffold).
>
> A percentage computed from an empty denominator is not a low score; it is not a
> number. `0%` reads as "measured and terrible" and `100%` as "measured and
> perfect" — both are claims about a comparison that never happened. This is the
> same defect `/scope-check` carries a Phase 4 guard against, in the same words:
> *"a percentage computed from no baseline items is not a small number; it is not
> a number."*
>
> **A hand-written list of skills required to carry `NOT ASSESSED` pins what was
> known when it was written**, so a skill added later inherits no obligation and
> nothing notices. Derive that set rather than enumerating it.

The manifest is a curated index — not the tests themselves, but a registry
of which tests should always pass before a release:

```markdown
# Regression Suite Manifest

> Last Updated: [date]
> Total registered tests: [N]
> Coverage: [N]% of critical-journey criteria

## How to run

[Per layer, the product's own command — from its scripts or CI workflow, never
from memory. A layer whose command could not be sourced: `NOT SOURCEABLE — ask
for /research`.]

## Critical Journeys

| Journey | Layers | Tests | Level (unit / integration / contract / e2e) |
|---------|--------|-------|----------------------------------------------|
| Tenant isolation | backend | `[test file]::[name]` | integration |

## Registered Regression Tests

### [Feature or bounded context]

| Test File | Test Name (if known) | Covers | Added |
|-----------|----------------------|--------|-------|
| `[test file path]` | `[Test name]` | AC-N / BUG-NNNN | [date] |

## Known Gaps

Tests that should exist but don't yet:

| Priority | Layer | Suggested Path | Covers | Reason Not Yet Written |
|----------|-------|----------------|--------|------------------------|
| HIGH | [layer] | `[path]` | BUG-NNNN | Bug fixed without test |

## Quarantined Tests

Flaky tests, running in the separate non-blocking job (register:
`production/qa/flaky-register.md`; quarantine within one day, fix or delete
within 14 days):

| Test File | Test Name | Reason | Quarantined Since | Owner / Issue |
|-----------|-----------|--------|-------------------|---------------|
| (none) | | | | |
```

---

## 7. Write Output

In `update` or `audit` mode, ask: "May I write/update `production/qa/regression-suite.md` with the current
regression suite manifest?"

For `update` mode: append new entries; never remove existing entries
(use `Edit` with targeted insertions).
For `audit` mode: rewrite the full manifest with updated coverage data.
For `report` mode: do not write anything.

After writing (if approved):

- For each HIGH priority gap: "Consider creating the missing regression test
  before the next sprint. Run `/test-helpers` to scaffold factories and fakes, and
  `/test-setup` if the layer has no test framework yet."
- If bug regression gaps > 0: "These bugs can silently return without regression
  tests. The next sprint should include a story to write the missing tests."
- If coverage drift detected: "Regression suite may be drifting. Consider
  running `/regression-suite audit` at the next sprint boundary."

At `workflow: minimal`, which has no sprints, say "next story" for "next sprint" in the three lines above.

**Checkpoint.** When the manifest was written or the run ended in a verdict below
(WAIVED, NOT ASSESSED, BLOCKED), update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/regression-suite <mode> —
<verdict>`, Next step = the first gap action above (or the fix that clears the
NOT ASSESSED), plus Blocked on / Files in progress / Open questions; append the
Notes line. `report` mode, which writes nothing and gates nothing, may skip it.

Verdict, first match wins:
- **WAIVED — qa.level: minimal** — the Section 1 stop: "Regression suite not
  generated at qa.level minimal". The manifest is not produced at this level
  (the tests it would index are still required and run); nothing was scanned or
  written. A waived run and an unassessable run have different fixes: this one
  needs `qa.level` raised, not more inputs.
- **NOT ASSESSED** — the `minimal` stop above: no smoke report to take critical
  journeys from; name `/smoke-check` as the fix.
- **NOT ASSESSED** — coverage came back `Coverage: NOT ASSESSED — [reason]` (no
  journey sources, no test files or no code roots); name the reason. Never report
  COMPLETE over a coverage figure that was not computed.
- **NOT ASSESSED** — `Bug regression coverage: NOT ASSESSED` (no closed bugs
  found, or `production/qa/bugs/` absent): the bug scan did not run, so the
  overall result is not a clean COMPLETE; name it in the closing message beside
  the journey result.
- **BLOCKED — write declined by user** — `update` or `audit` mode and the user
  declined the write; nothing is reported as recorded.
- **COMPLETE** — `update` / `audit`: regression suite updated; `report`: coverage
  report shown (report mode writes nothing).

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never remove existing regression tests from the manifest** without
  explicit user approval — removing a test that was deliberately written is a
  regression risk itself
- **Gaps are advisory, not blocking** — surface them clearly but do not prevent
  other work from proceeding (except at `qa.level: full`, where phase gates require the regression suite).
  A cross-tenant, billing or licence gap is flagged as HIGH PRIORITY and routed to `qa-lead`.
- **Quarantine is not deletion** — tests with intermittent failures are
  quarantined (noted in the manifest and the flaky register) within one day and
  fixed or deleted within 14 days via `/test-flakiness`; never retried into green
- **Never weaken a test to make the suite green** — a failing registered test is
  a defect to route to the owning stack lead, not an entry to edit
- **Never write a command from memory** — how-to-run lines come from the
  product's scripts and CI; the stack reference wins over training data
- **Ask before writing** — always confirm before creating or updating the manifest
