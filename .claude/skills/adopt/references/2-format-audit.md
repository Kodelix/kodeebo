# /adopt — Phase 2: Format Audit

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Format Audit

**In this file:**

- 2a: Feature Spec Format Audit
- 2b: ADR Format Audit
- 2c: domain-map.md Format Audit
- 2d: Story Format Audit
- 2e: Infrastructure Audit
- 2f: Project Config Audit
- 2g: Legacy State and Code Structure Observations

For each artifact type in scope (based on argument mode **and the resolved
workflow tier**), check not just that the file exists but that it contains the
internal structure the studio requires. At `minimal`, scope the audit to
`design/product-brief.md` — do not audit for specs, ADRs, or UX specs (they are not expected).
Steps 2e (the stack-reference rows only), 2f (project config) and 2g (legacy
state and code structure) run at every tier.

### 2a: Feature Spec Format Audit

**Gather section presence deterministically — do not read the specs to count
headings.** For each spec discovered in Phase 1, pass its path explicitly to the
structure-check script:

```
Bash: bash .claude/scripts/spec-structure-check.sh [path-to-spec]
```

**Pass paths one at a time; do not invoke it bare.** The no-argument form sweeps
`design/specs/` only, and a brownfield project's specs are not guaranteed to live
there — pass whatever paths Phase 1 found. The script prints a `PRESENT:` list
and, when applicable, an `ABSENT:` list per file. It reports **presence only**
and makes no REQUIRED/ADVISORY judgment (that is the tier logic below), and it
already accepts common heading aliases (`Detailed Rules`, `Failure Modes`, `NFRs`,
`Jobs-to-be-done`), so do not flag an alias as missing.

If the script prints `Not found:` for a path, errors, or is missing, that is a
**discovery failure, not a format gap** — report it as "could not audit [path]"
under NOT ASSESSED and do not count it as a missing-sections finding.

**Then apply the workflow tier** resolved above to each file's PRESENT/ABSENT
lists. Which sections are **required** (a miss = gap) vs **advisory** (a miss =
informational):
- **`full`** — all 8 sections are required.
- **`standard`** — the 5 required (Overview, Detailed Behaviour, Data & Contracts,
  Non-Functional Requirements, Acceptance Criteria) + Edge Cases & Failure Modes
  when the feature calls an external provider, moves money, changes entitlements,
  or runs asynchronously; User Value and Dependencies are advisory. See
  `.claude/docs/workflow-modes.md`.
- **`minimal`** — specs are not expected; audit `design/product-brief.md` instead,
  against `.claude/docs/templates/product-brief.md`: each required field present
  and not a placeholder; the recommended lines advisory. Any spec that does exist
  is checked at the `standard` bar, advisorily.

The script's 8 canonical labels are: Overview, User Value, Detailed Behaviour,
Data & Contracts, Edge Cases & Failure Modes, Dependencies, Non-Functional
Requirements, Acceptance Criteria.

A section reported PRESENT can still be an empty heading. For each spec, also
record with a targeted grep (not a full read):
- Placeholder-only sections — `Grep pattern="\[To be (designed|written)\]"` (or an
  equivalent empty/single-line body) marks a present-but-unwritten section.
- The `**Status**:` header field — `Grep pattern="^>?[[:space:]]*\*\*Status\*\*:"`.
  Valid values: `Draft`, `In Review`, `Approved`, `Implemented`.
- For a Security-class feature (auth, billing, uploads, PII): is a threat model
  linked from the Non-Functional Requirements section?

> **The `>?` is load-bearing, and so are `Draft`/`Implemented`.** Both emitters
> write this field inside a blockquote — `.claude/docs/templates/feature-spec.md`
> and `/design-spec` produce `> **Status**: …` — so an anchor of
> `^\*\*Status\*\*:` matches nothing and reports *every* template-compliant spec
> as missing its Status.

### 2b: ADR Format Audit

For each ADR file found, check for these critical sections (the shape of
`.claude/docs/templates/architecture-decision-record.md`):

| Section | Impact if missing |
|---|---|
| `## Status` | **BLOCKING** — `/story-readiness` ADR status check silently passes everything |
| `## ADR Dependencies` | HIGH — dependency ordering in `/architecture-review` breaks |
| `## Stack Compatibility` | HIGH — post-cutoff API and version risk is unknown |
| `## Spec Requirements Addressed` | MEDIUM — traceability matrix loses coverage |
| `## Performance Implications` | LOW — not pipeline-critical |

For each ADR, record: which sections present, which missing, current Status value
if the Status section exists. Valid Status values: `Proposed`, `Accepted`,
`Deprecated`, `Superseded by ADR-XXXX`. Never change a Status during the audit —
`Accepted` is the user's call, not this skill's.

### 2c: domain-map.md Format Audit

If `design/specs/domain-map.md` exists:

1. **Parenthetical status values** — Grep for any Status cell containing
   parentheses: `"Needs Revision ("`, `"In Design ("`, etc.
   These break exact-string matching in `/gate-check`, `/create-stories`,
   and `/architecture-review`. **BLOCKING.**

2. **Valid status values** — check that the feature table's Status column values
   are only from: `Not Started`, `In Design`, `In Review`, `Approved`,
   `Implemented`. Flag any unrecognised values.

3. **Column structure** — check that the feature table has at minimum: Feature,
   Context, Priority, Status, Spec columns, and that the bounded-contexts table
   has Context, Kind and Owns. Missing columns degrade skill functionality.

### 2d: Story Format Audit

For each story file found:

- **`Manifest Version:` field** — present in story header? (LOW — auto-passes if absent)
- **TR-ID reference** — does story contain `TR-[a-z0-9-]+-[0-9]+` pattern? (MEDIUM — no staleness tracking)
- **ADR reference** — does story reference at least one ADR? (check for `ADR-` pattern)
- **Status field** — present and readable?
- **Story type** — one of Logic, Integration, Contract, Security, Performance, UI, Config? (MEDIUM — the DoD evidence required at `/story-done` depends on it)
- **Acceptance criteria** — does the story have a checkbox list (`- [ ]`)?
- **Research note link** — does it reference a `docs/research/` note? (MEDIUM — gate 1 of the Definition of Done)

### 2e: Infrastructure Audit

| Artifact | Path | Impact if missing |
|---|---|---|
| TR registry | `docs/architecture/tr-registry.yaml` | HIGH — no stable requirement IDs |
| Control manifest | `docs/architecture/control-manifest.md` | HIGH — no layer rules for stories |
| Manifest version stamp | In manifest header: `Manifest Version:` | MEDIUM — staleness checks blind |
| Sprint status | `production/sprint-status.yaml` | MEDIUM — `/sprint-status` falls back to markdown |
| Stage file | `project.stage` in `project.yaml` (fallback `production/stage.txt`) | MEDIUM — phase auto-detect unreliable |
| Stack reference | `docs/stack-reference/<layer>/VERSION.md` for each configured layer, and `docs/stack-reference/pins.yaml` | HIGH — ADR stack checks blind |
| Architecture traceability | `docs/architecture/requirements-traceability.md` | MEDIUM — no persistent matrix |
| Performance budgets | `docs/architecture/perf-budgets.md` | MEDIUM — Definition of Done gate 6 has nothing to measure against |
| Threat models | `docs/architecture/threat-models/` for each Security-class feature | HIGH for a built sensitive feature; MEDIUM before it is built |
| Research notes | `docs/research/<feature>.md` per built feature | MEDIUM — gate 1 |
| API contracts | `contracts/` when a backend serves a web or mobile client | HIGH — no single source of truth between clients and backend |

At `workflow: minimal` only the Stack reference row applies, plus the research-note
row for features being built. The TR registry, control manifest and its version
stamp, sprint status, stage file, traceability matrix and performance budgets are
not on the minimal path, so their absence is not a gap.

### 2f: Project Config Audit

Read `project.yaml` (the config store). A setting counts as configured only when
it holds a real value (an empty string or empty list is unconfigured):
- `stack.backend` / `stack.web` / `stack.site` / `stack.mobile` / `stack.data` → HIGH if all unconfigured when code or ADRs exist (stack-aware skills route to nobody). Each set value must be in the enum list in `.claude/hooks/yaml-helper.sh` (`_yaml_helper_enums`) — an invalid value is a finding.
- `deploy.target`, `distribution.model`, `tenancy.model` → HIGH if unconfigured when ADRs or code exist (isolation and bundle decisions depend on them)
- `layout.code_roots` → MEDIUM if code lives outside the conventional directories and this is empty (hooks that scan source will miss it)
- `core.track` → MEDIUM when `stack.backend` is set; must follow it (`go` → `go`, `ktor` → `kotlin`)
- `performance.enforce`, `accessibility.target` → LOW (they carry defaults)

### 2g: Legacy State and Code Structure Observations

Observations, not verdicts — record them and let Phase 3 classify.

**Legacy mirrors.** Report, do not fix:
- `production/review-mode.txt` present — it sits above the `modes.rigor`
  expansion in the resolution chain, so it pins `modes.review_mode` regardless of
  rigor. Ask whether that is intended. (Pinning it on purpose belongs in
  `project.local.yaml` via `/settings --local`.)
- `production/stage.txt` and `project.stage` disagree — `project.yaml` wins; say
  which value each holds.
- A legacy technical-preferences file carrying real values (from an older
  framework version): not read by this studio; list its values so they can be
  carried into `project.yaml` by `/setup-stack` where they map.

**Code structure** (only for the code roots Phase 1 resolved; if none, record
`NOT ASSESSED — code roots unresolved`):
- Layers present (`backend/`, `web/`, `site/`, `mobile/`, `contracts/`, `deploy/`)
  and which backend track the manifests indicate (`go.mod` → Go, `build.gradle.kts`
  with Ktor → Ktor).
- Whether the backend follows the `domain` / `app` / `adapters` split
  (`.claude/docs/clean-architecture.md`) — count contexts that do vs. do not. This
  is an observation for `/architecture-review`; do not report it as a gap here.
- Whether migrations exist and where; whether `contracts/` holds OpenAPI or proto
  sources; whether `deploy/self-hosted/` exists when `distribution.model` includes
  self-hosted.
- Whether tests exist beside the code (counts only).

---
