# /architecture-review — Phases 3 and 3b: Traceability Matrix and Story Linkage

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Build the Traceability Matrix

**In this file:**

- Coverage matrix and status values
- Threat-model and security coverage
- Step 3b-1 — Load stories
- Step 3b-2 — Load test files
- Step 3b-3 — Build the extended RTM

For each technical requirement extracted in Phase 2, search the ADRs:

1. Use the ADRs **already loaded in Phase 1b** — do not re-read them. Extract each
   ADR's "Spec Requirements Addressed" section from what is already in context.
   (If Phase 1b ran in a mode that did not load every ADR, `Grep pattern="## Spec
   Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content"
   -A 15` fills the gap without a full re-read.)
2. Check if it explicitly references the requirement or its spec
3. Check if the ADR's decision text implicitly covers the requirement
4. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An **Accepted** ADR explicitly addresses this requirement |
| 🟡 **Covered (Proposed)** | An ADR addresses it, but that ADR is still `Proposed` |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |
| ❓ **Not assessed** | The ADR is unreadable, or has no `## Status` section |

> **Read each ADR's `## Status` before marking coverage — an unaccepted decision
> is not coverage.** If `✅` meant only that *an ADR addresses this*, with no
> status qualification, a requirement covered entirely by `Proposed` ADRs would
> count as covered and this review could return **PASS: All requirements
> covered** over an architecture nobody had accepted. Four skills downstream
> (`create-control-manifest`, `create-epics`, `create-stories`, `gate-check`)
> require `Accepted`, so a PASS on that basis sends work forward that every one
> of them will refuse.
>
> `🟡` is **not** a pass state: it caps the verdict at **CONCERNS**, and names the
> route out — `/architecture-decision accept ADR-NNNN`. That route is the only
> thing that moves an ADR to `Accepted`; without it, grading `Proposed` as
> covered would be the only option, which is why it must never be graded so.

Build the full matrix:

```
## Traceability Matrix

| Requirement ID | Spec | Context | Requirement | ADR Coverage | Status |
|---------------|------|---------|-------------|--------------|--------|
| TR-billing-001 | billing.md | Billing | Subscription state machine | ADR-0003 | ✅ |
| TR-billing-002 | billing.md | Billing | Dunning schedule | — | ❌ GAP |
| TR-team-invitations-001 | team-invitations.md | Identity | Single-use invite tokens | ADR-0005 | ✅ |
```

Count the totals: X covered, P covered (Proposed), Y partial, Z gaps.

### Threat-model and security coverage

For each requirement marked `SENSITIVE` in Phase 2, check
`docs/architecture/threat-models/<feature>.md` exists (Glob from Phase 1b) and
that the covering ADR links it or names the ASVS/MASVS controls:

| Req ID | Sensitive area | Threat model | Covering ADR | Status |
|--------|----------------|--------------|--------------|--------|
| TR-billing-001 | billing | `docs/architecture/threat-models/billing.md` / MISSING | ADR-0003 | Covered / GAP |

A sensitive requirement with no threat model is a **GAP** even when an ADR covers
it architecturally: the missing artifact is `/threat-model <feature>`. Threat
models are required for authentication, authorization model, billing, licensing,
file upload, webhooks, PII export/delete, admin/impersonation and new external
integrations (`security-baseline.md`).

### Tenancy and edition coverage

For each requirement touching tenant data, confirm the covering ADR (or the
tenancy ADR it depends on) states tenant scoping; for each requirement whose spec
says it must work in the self-hosted edition, confirm an ADR states the bundle
effect. A requirement with no such statement is `⚠️ Partial`, not Covered.

---

## Phase 3b: Story and Test Linkage (RTM mode only)

*Skip this phase unless the argument is `rtm` or `full` with stories present.*

This phase extends the Phase 3 matrix to include the story that implements
each requirement and the test that verifies it — producing the full
Requirements Traceability Matrix (RTM).

### Step 3b-1 — Load stories

Glob `production/epics/**/*.md` (excluding EPIC.md index files) to establish the
denominator. Then collect the fields with **targeted section greps, not a full
read of each story**:

```
Grep pattern="## Definition of Done Evidence|## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 12
Grep pattern="TR-" glob="production/epics/**/story-*.md" output_mode="content"
```

- **TR-ID** — from the second grep.
- **Test file path(s) and evidence paths** — under the evidence section, captured by the first grep's `-A 12`.
- **Story type** — Logic / Integration / Contract / Security / Performance / UI / Config.
- **Status** — from the story header; add `Grep pattern="^> \*\*Status\*\*"` if not already captured.
- **Story path and title** — from the file name and path; no read at all.

Full-read a story only when its evidence section is missing or ambiguous.

### Step 3b-2 — Load test files

Glob the test locations for the layers in use (`.claude/docs/directory-structure.md`
"Code roots" table): Go `*_test.go` and `integration`-tagged tests under `backend/`;
Ktor `src/test/kotlin/` and `src/integrationTest/kotlin/`; web `*.test.ts(x)` and
`web/e2e/`; Android `app/src/test/` and `app/src/androidTest/`; KMP
`src/commonTest/kotlin/`; iOS test targets; contract tests run from each consumer.
Take the layers from `resolve_code_root` output. **If `resolve_code_root` yields
no root, say the test index could not be built rather than reading an empty glob
as "no tests".** Build an index: feature → [test file paths].

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.

### Step 3b-3 — Build the extended RTM

For each TR-ID in the Phase 3 matrix, add:
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Test File**: the test file path stated in the story's evidence section
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated; acceptable only for a story type whose
  evidence is a screenshot or smoke check, e.g. UI/Config) / NO STORY
  (requirement has no story yet — pre-production gap)

Extended matrix format:

```
## Requirements Traceability Matrix (RTM)

| TR-ID | Spec | Requirement | ADR | Story | Test File | Test Status |
|-------|------|-------------|-----|-------|-----------|-------------|
| TR-billing-001 | billing.md | Subscription state machine | ADR-0003 | story-001-subscription-states.md | backend/internal/billing/domain/subscription_test.go | COVERED |
| TR-billing-002 | billing.md | Dunning schedule | — | story-002-dunning.md | — | NONE (Config) |
| TR-reports-001 | reports.md | Async export | ADR-0007 | — | — | NO STORY |
```

RTM coverage summary:
- COVERED: [N] — requirements with ADR + story + passing test
- MISSING test: [N] — story exists but test file not found
- NO STORY: [N] — requirements with ADR but no story yet
- NO ADR: [N] — requirements without architectural coverage (from Phase 3 gaps)
- Full chain complete (COVERED): [N/total] ([%])

---
