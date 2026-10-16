---
name: project-stage-detect
description: "Analyze project state, detect stage, identify gaps, recommend next steps. 'Where are we in development?'"
argument-hint: "[optional: role filter like 'engineer', 'designer', 'producer', 'security' or 'operations']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh), Bash(bash ".claude/scripts/artifact-check.sh"), Bash(bash ./.claude/scripts/artifact-check.sh), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash ".claude/scripts/artifact-check.sh" *), Bash(bash ./.claude/scripts/artifact-check.sh *)
model: haiku
# Read-only diagnostic skill — no specialist agent delegation needed
---

# Project Stage Detection

This skill scans your project to determine its current development stage, completeness
of artifacts, and gaps that need attention. It's especially useful when:
- Starting with an existing product repository
- Onboarding to a codebase
- Checking what's missing before a milestone or a release
- Understanding "where are we?"

---

## Workflow

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

> **Resolve the tier — do not assume it.** Saying "surface gaps per the **resolved** workflow
> tier" without resolving it — no bootstrap, no helper call — leaves
> the tier as whatever the model assumed. The tier decides what counts as a gap
> at all: at `full` every missing doc is one; at `minimal` none of them are,
> because a brief plus a configured stack is the normal state and code is the
> expected next step. Guessing high tells a first-version project it is missing
> specs, a domain map and ADRs — the exact "process feels mismatched to my
> project" experience `modes.rigor` exists to prevent. A missing bootstrap is
> invisible to a static read — the config block simply does not render — so
> verify it by running.

**`workflow`** (per `.claude/docs/workflow-modes.md`). The tier governs
which absent documents count as gaps (step 3) — below `full`, optional docs are
not flagged. **It never governs the eight Definition of Done gates**
(`.claude/docs/coding-standards.md`): missing tests, a missing research note for
built code, no tenant-isolation test, or no observability on a shipped endpoint
are engineering gaps at every tier.

### 1. Scan Key Directories

**Start with the deterministic pass — it answers "what exists" for every
catalogued artifact in one call:**

```
Bash: bash .claude/scripts/artifact-check.sh
```

Run it exactly as written — from the project root, relative path, no
arguments, no `cd`, no `2>&1`. This skill's permission grant matches that form;
any other asks the user to approve it.

With no `--phase` it reports every phase, so a single call covers the whole
project: per step, `PRESENT` / `ABSENT` / `SHORT` (with `count=` and `min=`) /
`PATTERN_MISS` / `NO_CHECK`. Use it instead of hand-globbing each artifact
below, and treat its `NO_CHECK` total as the honest bound on what existence
checks can tell you. If the script cannot read `.claude/docs/workflow-catalog.yaml`
or prints no `STEPS:` line, it evaluated nothing: say
`NOT ASSESSED — catalog unreadable` and carry on with the manual scan below,
never "no artifacts missing".

It reports observations only — this skill still decides what stage those
observations imply, and the tier still governs which absences are gaps at all
(see the workflow-tier note below).

Then analyze what the script cannot: content quality, counts it does not
track, and the judgement calls.

**Product design documentation** (`design/`):
- Check for `design/product-brief.md` (a template with placeholders in its
  required fields counts as absent), `design/specs/domain-map.md`
- Count feature specs in `design/specs/*.md` (excluding the domain map)
- If the domain map exists, count features listed vs. features with a spec
- Analyze completeness against the tier's required sections (Overview, Detailed
  Behaviour, Data & Contracts, Non-Functional Requirements, Acceptance Criteria
  at `standard`; all eight at `full`)
- Count UX specs in `design/ux/`; check `PRODUCT.md` / `DESIGN.md` at the repo
  root (the impeccable design context)
- Check `design/growth/` and `design/localization/`

**Stack and configuration** (`project.yaml`, `docs/stack-reference/`):
- Read `stack.*`, `deploy.target`, `distribution.model`, `tenancy.model`,
  `core.track` from `project.yaml`. Empty = not configured — report it as such,
  never infer a stack from the files on disk
- For each configured layer, does `docs/stack-reference/<layer>/VERSION.md`
  exist? (`/setup-stack` checks freshness; do not duplicate it here)

**Source code** (the code roots — `layout.code_roots` in `project.yaml`, else the
conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist on
disk; the same resolution as `resolve_code_root` in `.claude/hooks/yaml-helper.sh`):
- Count source files per root (language-agnostic)
- Identify bounded contexts: directories under `backend/internal/` (Go) or
  `backend/src/main/kotlin/<pkg>/` (Ktor) with 5+ files, and whether each has the
  `domain` / `app` / `adapters` split; features under `web/src/features/`
- Check `contracts/` for OpenAPI / proto sources and `backend/` for migrations
- Estimate lines of code (rough scale)
- An unresolved root means none of these ran: report
  `NOT ASSESSED — code roots unresolved`, never zero source files — zero files
  reads as a greenfield product, and the source-file rows of the stage table
  cannot be decided without the count

**Architecture and decisions** (`docs/architecture/`):
- Count ADRs and check for an architecture document
- Check for `perf-budgets.md` and threat models (`docs/architecture/threat-models/`)
  vs. features that touch auth, billing, uploads or PII

**Research notes** (`docs/research/`):
- Count notes; list built features that have no note (gate 1 of the Definition of Done)

**Production artifacts** (`production/`):
- Check for active sprint plans. At `workflow: minimal` there are no sprints:
  read the story files' progress through the brief's build order instead, and
  never report a missing sprint plan, milestone or roadmap as a gap
- Look for milestone definitions, epics and stories

**Tests and evidence** (per layer — see `.claude/docs/directory-structure.md` "Code roots"):
- Count test files beside the code of each root, integration tests, contract tests
- Check `production/qa/evidence/` for evidence folders against closed stories
- Estimate coverage (rough heuristic); never claim a number the scan did not produce

**Operations** (`deploy/`, `docs/runbooks/`):
- `deploy/hosted/` and `deploy/self-hosted/` present? (self-hosted only matters
  when `distribution.model` is `self-hosted` or `hybrid`)
- Runbooks, observability configuration, backups

**Prototypes** (`prototypes/`):
- Count prototype directories
- Check for READMEs or reports (documented vs undocumented)
- Assess if prototypes are archived or active

### 2. Classify Project Stage

Based on scanned artifacts, determine stage. Check `project.stage` in `project.yaml` first (if present); else `production/stage.txt` (legacy fallback) — either is an explicit override from `/gate-check`. Otherwise, auto-detect using these heuristics (check from most-advanced backward):

> **Always run the heuristics, even when a stage is configured — then COMPARE.**
> The configured value is authoritative for what the stage *is*; it is not
> evidence that the artifacts support it. Report both, and when they disagree say
> so explicitly:
>
> > "Configured stage: **Release**. Observed artifacts indicate
> > **Pre-Production** (2 source files, 0 ADRs, no architecture doc, no epics).
> > These disagree — the configured stage may be stale, or work exists outside
> > this repo."
>
> Reading config and reporting it back is not detection. This skill's own
> description promises "analyze project state, detect stage", and a stage
> detector that cannot contradict its input is the one thing it must never be —
> it would report `Release` for a project whose artifacts match its own
> Pre-Production row, and say nothing.
>
> **A disagreement makes Stage Confidence CONCERNS** (step 4) — ambiguous
> signals by definition — however complete the artifacts are. One exception: at
> `workflow: minimal` nothing runs `/gate-check`, so the configured stage stays
> where `/start` set it. There, report the observed stage and say the configured
> one is not advanced at this tier; that lag is expected, not a disagreement.

| Stage | Indicators |
|-------|-----------|
| **Discovery** | No product brief, ideation phase |
| **Product Design** | Product brief exists; domain map missing, or feature specs incomplete |
| **Architecture** | Domain map and specs exist; stack not configured, or no architecture document / ADRs |
| **Pre-Production** | Stack configured and architecture documented; code roots hold <10 source files in total |
| **Production** | Code roots hold 10+ source files, active development |
| **Hardening** | Explicit only (set by `/gate-check` Production → Hardening gate) |
| **Release** | Explicit only (set by `/gate-check` Hardening → Release gate) |
| **Live** | Explicit only (set by `/gate-check` once a release has shipped to customers) |

### 3. Collaborative Gap Identification

**Surface gaps per the resolved workflow tier:**
- **`full`** — flag every missing doc type (feature specs, UX specs, ADRs, threat models, SLOs) as a gap.
- **`standard`** — flag only required docs: missing specs for built features,
  missing critical ADRs (tenancy, identity, data stores, messaging, API style,
  deployment topology, licensing), missing threat models for sensitive features.
  Do NOT flag an absent UX spec for a non-core screen.
- **`minimal`** — a `design/product-brief.md` + configured stack is the normal state. Do NOT flag
  absent specs, domain map, UX specs, ADR files, epics or sprint plans as gaps: the brief's build
  order is the plan, and the expected next step is code.

**DO NOT** just list missing files. Instead, **ask clarifying questions** (only
for gaps the tier above says to surface):

- "I see billing code (`backend/internal/billing/`) but no `design/specs/billing.md`. Was this built from the brief alone, or should we reverse-document it (`/reverse-document spec billing`)?"
- "You have 15 ADRs but no architecture overview. Should I create one to help new contributors?"
- (`standard`/`full` only) "I see [N] bounded contexts under `backend/` but no ADRs in `docs/architecture/`. Were those decisions recorded somewhere else, or should we write the critical ones with `/architecture-decision`?"
- (`standard`/`full` only) "No sprint plans in `production/`. Are you tracking work elsewhere (Jira, Linear, etc.)?"
- "I found a product brief but no domain map. Have you decomposed the product into bounded contexts yet, or should we run `/map-domains`?"
- "Prototypes directory has 3 spikes with no README. Were these experiments, or do they need documentation?"

**Engineering gaps — asked at every tier** (they are not documents):
- "`backend/internal/files/` handles uploads but I found no threat model and no negative tests. Is that covered somewhere else?"
- "`web/src/features/billing/` has no screenshot in `production/qa/evidence/`. Was it run and looked at?"
- "No `docs/research/` note for [built feature]. Was it researched before it was implemented?"

### 4. Generate Stage Report

Use template: `.claude/docs/templates/project-stage-report.md`

**Report structure**:
```markdown
# Project Stage Analysis

**Date**: [date]
**Stage**: [Discovery/Product Design/Architecture/Pre-Production/Production/Hardening/Release/Live]
**Stage Confidence**: [PASS — clearly detected / CONCERNS — ambiguous signals / NOT ASSESSED — a check the stage depends on did not run / FAIL — critical gaps block progress]

## Completeness Overview
- Product design: [X%] ([N] docs, [gaps])
- Code: [X%] ([N] files across [roots], [contexts])
- Architecture: [X%] ([N] ADRs, [gaps])
- Production: [X%] ([status] — at `minimal`: stories complete in the brief's build order, never "no sprint plan")
- Tests and evidence: [X%] ([coverage estimate])

## Gaps Identified
1. [Gap description + clarifying question]
2. [Gap description + clarifying question]

## Recommended Next Steps
[Priority-ordered list based on stage and role]
```

**Stage Confidence — first match wins:** **FAIL** if critical gaps block
progress; else **CONCERNS** if the signals that were gathered are ambiguous —
they fit more than one stage, or the configured and observed stages disagree
(step 2); else **NOT ASSESSED** if a check the stage depends on did not run —
name it (unresolved code roots, an unreadable catalog, a stack that cannot be
read leave the source-file count or the Architecture row undecided); else
**PASS**. NOT ASSESSED outranks PASS — a stage nobody could check is not a
clearly detected one — and ranks below CONCERNS and FAIL, so a known problem is
never buried behind it.

### 5. Role-Filtered Recommendations (Optional)

If user provided a role argument (e.g., `/project-stage-detect engineer`):

**Engineer**:
- Focus on architecture docs, test coverage, missing ADRs, context boundaries
- Code-to-docs gaps; missing research notes

**Designer**:
- Focus on spec completeness, UX specs, `PRODUCT.md` / `DESIGN.md`, accessibility target
- Prototype and usability-test documentation

**Producer**:
- Focus on sprint plans, milestone tracking, roadmap, risk register
- Cross-team coordination docs

**Security**:
- Focus on threat models, tenant-isolation evidence, dependency scan, secrets handling

**Operations**:
- Focus on deploy bundles (hosted, self-hosted), runbooks, SLOs, observability, backups

**General** (no role):
- Holistic view of all gaps
- Highest-priority items across domains

### 6. Request Approval Before Writing

**Collaborative protocol**:
```
I've analyzed your project. Here's what I found:

[Show summary]

Gaps identified:
1. [Gap 1 + question]
2. [Gap 2 + question]

Recommended next steps:
- [Priority 1]
- [Priority 2]
- [Priority 3]

May I write the full stage analysis to production/project-stage-report.md?
```

Wait for user approval before creating the file.

---

## Example Usage

```bash
# General project analysis
/project-stage-detect

# Engineer-focused analysis
/project-stage-detect engineer

# Designer-focused analysis
/project-stage-detect designer
```

---

## Follow-Up Actions

**Checkpoint.** When the stage report was written (or the write declined), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/project-stage-detect — <detected stage>`, Next step = the first
follow-up below, plus Blocked on / Files in progress
(`production/project-stage-report.md`) / Open questions; append the Notes line. A
report-only run that wrote nothing may skip it.

After generating the report, suggest relevant next steps — **only for gaps the
resolved workflow tier surfaces** (step 3; engineering gaps are always
surfaced). Name only skills that are installed (Glob
`.claude/skills/<name>/SKILL.md`); for one that is not, say "(not installed yet)".
At `standard`/`minimal`, do not suggest authoring optional docs (e.g. don't
suggest `/reverse-document` for an absent spec at `minimal`, where code is the
expected next step):

- **Brief exists but no domain map?** → `/map-domains` to decompose into bounded contexts and features
- **Missing feature specs?** → `/reverse-document spec <feature>` against the code, or `/design-spec`
- **Missing architecture docs?** → `/architecture-decision` or `/create-architecture` (for a built product, `/reverse-document architecture` reconstructs it from the code)
- **Stack not configured, or stack reference missing/stale?** → `/setup-stack`
- **Sensitive feature without a threat model?** → `/threat-model`
- **Built feature without a research note?** → `/research` (for code that already exists, `/reverse-document research <context>`)
- **Prototypes need documentation?** → `/reverse-document concept prototypes/<name>`, or write a brief with `/brainstorm`
- **Code but no `design/product-brief.md`?** → `/brainstorm`, or `/reverse-document brief` to reconstruct it from the code
- **No sprint plan?** → `/sprint-plan` (not at `rigor: minimal`, where the brief's build order is the plan)
- **Approaching milestone?** → `/milestone-review`
- **Existing artifacts in an unknown format?** → `/adopt`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Question First**: Ask about gaps, don't assume
2. **Present Options**: "Should I create X, or is it tracked elsewhere?"
3. **User Decides**: Wait for direction
4. **Show Draft**: Display report summary
5. **Get Approval**: "May I write to production/project-stage-report.md?"

**Never** silently write files. **Always** show findings and ask before creating artifacts.
