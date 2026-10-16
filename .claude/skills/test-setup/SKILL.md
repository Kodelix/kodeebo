---
name: test-setup
description: "Scaffold test frameworks and CI per configured layer — Go, Ktor/Kotlin, web (Vitest, Playwright), Android, iOS, contract tests — plus the QA directories and a GitHub Actions workflow with SHA-pinned actions. Once, before the first sprint."
argument-hint: "[layer ...|all] [force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, WebFetch, Bash(git ls-remote *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Setup

This skill scaffolds the automated testing infrastructure for the product. It
reads the configured stack, creates the test locations each layer uses
(`.claude/docs/directory-structure.md` → Code roots), writes the framework
configuration whose versions and keys are sourced, wires a GitHub Actions
workflow so tests run on every push and pull request, and seeds the smoke list
`/smoke-check` reads.

Run this once, before the first implementation story. A test framework
installed at sprint start costs 30 minutes. A test framework installed at
sprint four costs three sprints.

**Layers** (the argument selects some, default is every layer the `stack` line
configures): `backend` (Go or Ktor), `web`, `site`, `android`, `kmp`, `ios`,
`contracts`.

**Output:** the per-layer test locations and framework config, `production/qa/`
scaffolding (`README.md`, `smoke-tests.md`, `evidence/`, `cases/`), and
`.github/workflows/tests.yml`.

**Test frameworks and versions are never written from memory.** Versions come
from `docs/stack-reference/pins.yaml`; APIs and config keys come from
`docs/stack-reference/<layer>/best-practices.md` or from the research note
`docs/research/test-infrastructure.md`. Anything neither covers is written as
`PENDING — NOT SOURCEABLE` (the file is not created, the item is listed in the
summary), and the verdict is **PARTIAL**, not COMPLETE.

---

## Phase 1: Detect Stack and Existing State

**Read `references/1-detect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Present Plan

**Read `references/2-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Create Directory Structure and Layer Scaffolds

**Read `references/3-directories.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Create CI/CD Workflow

**Read `references/4-ci.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Create Smoke Test Seed

**Read `references/5-smoke-seed.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Post-Setup Summary

**Read `references/6-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

- **Never overwrite existing test files or configs** — only create files that are
  missing. If a test runner config exists, leave it as-is and report any
  difference from the pins.
- **Always ask before creating files** — Phase 2 requires explicit approval.
- **Stack detection is non-negotiable** — if no layer is configured, stop and
  redirect to `/setup-stack`. Do not guess.
- **`force` flag skips the "already exists" early-exit but never overwrites.**
  It means "create any missing files even if the directory already exists."
- **Never invent a version.** A version not in `pins.yaml` or the stack reference
  is `NOT SOURCEABLE`: name it, point at `/research test-infrastructure`, and do
  not pin a guess. Same for action versions in CI (Phase 4 resolves them from the
  action's own repository, with the user choosing the release).
- **CI secrets are the user's** — the workflow needs none to run tests. Do not
  create, read or request tokens, keys or signing credentials; the macOS and
  emulator jobs that would need runner setup are listed, not guessed.
- **Run nothing that installs.** `go get`, `pnpm add`, `pnpm install` and
  `pnpm exec playwright install --with-deps` are not pre-approved: print the exact
  command and let the user run it. Files are created with `Write`; `Edit` is used
  only on the build files below, after the user approved the exact change.
- **Edit nothing outside the test locations, `production/qa/`, and the new
  workflow file.** Build scripts (`build.gradle.kts`, `package.json`,
  `go.mod`, Xcode projects) belong to the stack leads: propose the exact change
  and ask; never edit them unprompted.
