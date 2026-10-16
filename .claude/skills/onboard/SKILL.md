---
name: onboard
description: "Onboarding doc for a new engineer or agent — product state, conventions, priorities relevant to the specified role."
argument-hint: "[role|area]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(git log *), Bash(bash "*/.claude/skills/onboard/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Onboard

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — a security audit returning CLEAN on a repository with no
code and no threat models, or a performance profile reporting ample headroom
against a p95 budget with zero load-test data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 1: Load Project Context

Read CLAUDE.md for project overview and standards, and `.claude/docs/coding-standards.md`
for the eight Definition of Done gates.

Read the relevant agent definition from `.claude/agents/` if a specific role is
specified. Role → agent: backend → `go-lead` or `ktor-lead` (per `stack.backend`
in the config block above — never guess which), web → `web-lead`, Android →
`android-lead`, iOS → `ios-lead`, shared mobile → `kmp-specialist`, data →
`data-lead`, API → `api-designer`, security → `security-lead`, operations →
`sre-lead` and `platform-lead`, QA → `qa-lead`, product → `product-manager`,
design → `design-director`, production → `producer`. A role with no mapping: say
so and onboard to the area instead.

`CLAUDE.md` and `.claude/agents/` ship with the framework — no skill creates them. If either is missing, report it as missing from the install.

---

## Phase 2: Scan Relevant Area

- For engineers: scan the code roots (`layout.code_roots` in `project.yaml`, else the conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist — the resolution `resolve_code_root` performs in `.claude/hooks/yaml-helper.sh`) for architecture, patterns, key files. An unresolved root means the scan did not run: the sections it feeds read `NOT ASSESSED — code roots unresolved`, never a guess at `backend/`. Read the stack reference for each layer the role touches (`docs/stack-reference/<layer>/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`) and its `.claude/rules/` file
- For designers: scan `design/` (brief, specs, `design/ux/`), plus `PRODUCT.md` and `DESIGN.md` at the repo root
- For product: scan `design/product-brief.md`, `design/specs/domain-map.md`, `design/specs/`
- For QA: scan the test locations of each code root (`.claude/docs/directory-structure.md` "Code roots") and `production/qa/` (`/test-setup` creates the frameworks)
- For security: scan `docs/architecture/threat-models/` and `.claude/docs/security-baseline.md`
- For operations: scan `deploy/`, `docs/runbooks/`, `docs/architecture/perf-budgets.md`
- For production: scan `production/` for current sprint and milestone
- **No role or area given**: a general orientation — list the top level of `design/`,
  `docs/architecture/`, `production/` and the code roots, read
  `production/session-state/active.md` if it exists, and say that a role would
  focus the next pass (e.g. `/onboard backend`)

Read recent changes (git log if available) to understand current momentum.

---

## Phase 3: Generate Onboarding Document

```markdown
# Onboarding: [Role/Area]

## Product Summary
[2-3 sentence summary of what this product is, who it is for, and its current state
(stage, stack, distribution model, tenancy model)]

## Your Role
[What this role does on this product, key responsibilities, who you report to]

## Project Architecture
[Relevant architectural overview for this role: bounded contexts, layers,
tenancy model, what comes from `saas-core` versus what the product owns]

### Key Directories
| Directory | Contents | Your Interaction |
|-----------|----------|-----------------|

### Key Files
| File | Purpose | Read Priority |
|------|---------|--------------|

## Current Standards and Conventions
[Summary of conventions relevant to this role from CLAUDE.md, the agent
definition and the path-scoped rules. Always include: the eight Definition of
Done gates, research before implementation (`docs/research/<feature>.md`),
every query tenant-scoped, no secrets in code or logs, shared capabilities from
`saas-core`, Conventional Commits with a story ID in the body]

## Current State of Your Area
[What has been built, what is in progress, what is planned next. Name what
Phase 2 found by path — for a designer or product role, each existing spec and
design doc; for an engineer, each bounded context — or say it found none]

## Current Sprint Context
[What the team is working on now and what is expected of this role]

## Key Dependencies
[What other roles/contexts this role interacts with most]

## Common Pitfalls
[Things that trip up new contributors in this area — drawn from the rules files
and ADRs actually present, not generic advice]

## First Tasks
[Suggested first tasks to get oriented and productive]

1. [Read these documents first]
2. [Run the stack locally and look at the running product]
3. [Start with this small task]

## Questions to Ask
[Questions the new contributor should ask to get fully oriented]
```

---

## Phase 4: Save Document

Present the onboarding document to the user.

Ask: "May I write this to `production/onboarding/onboard-[role]-[date].md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 5: Next Steps

**Checkpoint.** When a document was written (or the write was declined), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/onboard <role> — <verdict>`, Next step = the first next step below,
plus Blocked on / Files in progress / Open questions; append the Notes line. A
read-only run that wrote nothing may skip it.

Verdict: **COMPLETE** — onboarding document generated.

- Share the onboarding doc with the new contributor before their first session.
- Run `/sprint-status` to show the new contributor current progress.
- Run `/help` if the contributor needs guidance on what to work on next.
