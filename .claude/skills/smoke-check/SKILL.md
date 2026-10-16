---
name: smoke-check
description: "Critical-path smoke gate before QA hand-off — brings the dev stack up, runs the automated suites per layer and the critical-journey checks. A failed check means the build is not QA-ready."
argument-hint: "[sprint | quick | --surface web|android|ios|self-hosted|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(command -v *), Bash(docker info), Bash(docker compose version), Bash(docker compose -f * config -q), Bash(docker compose -f * config -q *), Bash(docker compose -f * ps), Bash(docker compose -f * ps *), Bash(docker compose -f * logs *), Bash(docker compose -f * stop), Bash(docker compose -f * stop *), Bash(docker compose -f * start *), Bash(timeout 900 docker compose -f * up -d --wait), Bash(go version), Bash(java -version), Bash(node --version), Bash(./gradlew --version), Bash(./gradlew -p * --version), Bash(pnpm --version), Bash(adb devices), Bash(uname -s), Bash(xcodebuild -version), Bash(timeout 900 go -C * test *), Bash(timeout 900 pnpm -C * run *), Bash(timeout 900 ./gradlew -p * *), Bash(timeout 900 swift test *), Bash(stat -c *), Bash(curl * http://localhost:*), Bash(curl * http://127.0.0.1:*), Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(swift test)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,performance.enforce,stack`

# Smoke Check

This skill is the gate between "implementation done" and "ready for QA
hand-off". It brings the development stack up the way
`.claude/docs/run-and-observe.md` describes, runs the automated test suites of
every layer in scope, checks for test-evidence gaps, runs the critical-journey
checks against the running stack, batch-verifies the surfaces only a person can
judge, and produces a PASS/FAIL report.

The rule is simple: **a build that fails smoke check does not go to QA.**
Handing a broken build to QA wastes their time and erodes trust in the gate.

**A compile is not a run.** A green unit suite says nothing about whether the
stack starts, migrates, authenticates and isolates tenants — Part A of Phase 4
exercises exactly that, against real containers.

**Output:** `production/qa/smoke-[date].md` (+ transcripts in
`production/qa/evidence/smoke-[date]/`)

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`qa.level`** decides whether the gate exists at all: at `minimal`, smoke-check is
**optional** — if run, a FAIL is advisory and never blocks hand-off; at
`standard`, it is required before a phase transition; at `full`, before every
commit. It never waives the tests themselves: Logic, Integration, Contract and
Security tests exist and pass at every level (`coding-standards.md`), so a layer
in scope with no tests is NOT ASSESSED at `minimal` too (Phase 1 step 1). This
sits in front of the Phase 6 `testing.strict.config` resolution (which only
matters once a smoke run gates). Distinct axis from `workflow`.

**Who runs what.** Every shell command in the phases is run by this skill and is
granted in `allowed-tools`: the probes, `docker compose -f <file> up -d --wait`
(under `timeout 900`), the per-layer test runs (`go -C <root> test`,
`pnpm -C <root> run`, `./gradlew -p <root>`, `swift test`) and `curl` to the
local stack. Three things are never granted, so the user runs them and says so:
installing Playwright browsers (`pnpm exec playwright install --with-deps`),
Xcode builds (`xcodebuild`) and `docker compose down`. When a command is not
granted, say which one and ask the user to run it; do not look for a way around.

**Environment boundary.** Smoke-check touches the **local development stack and
the seeded test tenant only** (`tools/seed/`). Never a shared, staging or
production environment, never real customer data or credentials, and never a
command that deletes volumes: **no `docker compose down -v`, no
`docker volume rm`, no `docker system prune`** — a clean slate is something the
user asks for (`run-and-observe.md` §5).

## Parse Arguments

Arguments can be combined: `/smoke-check sprint --surface web`

**Base mode** (first argument, default: `sprint`):
- `sprint` — full smoke check against the current sprint's stories
- `quick` — skip the coverage scan (Phase 3) and Batch 3; use for rapid re-checks

**Surface flag** (`--surface`, default: none):
- `--surface web` — add web checks (1440 px and 390 px, English and Arabic RTL, keyboard-only path)
- `--surface android` — add Android checks (rotation, background/foreground and process death, offline, RTL, small screen)
- `--surface ios` — add iOS checks (Dynamic Type large, background/foreground, offline, RTL)
- `--surface self-hosted` — add customer-bundle checks (install from the signed bundle on a clean host, upgrade from the prior version, restore from backup, telemetry off, licence activation)
- `--surface all` — add every surface; output a per-surface verdict table

If `--surface` is provided, Phase 4 adds surface batches and Phase 5 outputs a
per-surface verdict table in addition to the overall verdict.

---

## Phase 1: Detect Test Setup

**Read `references/1-detect-setup.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Run Automated Tests

**Read `references/2-run-tests.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Check Test Coverage

**Read `references/3-coverage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Run Critical-Journey and Manual Smoke Checks

**Read `references/4-manual-checks.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Generate Report

**Read `references/5-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Write and Gate

**Read `references/6-write-gate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never treat NOT RUN as automatic FAIL** — record it as NOT RUN and let
  the developer confirm status manually. Unconfirmed NOT RUN yields **NOT
  ASSESSED**, not FAIL — and not a pass verdict either.
- **Never auto-fix failures** — report them and state what must be resolved.
  Do not attempt to edit source code, test files, compose files or CI
  configuration; route a defect to `qa-lead`.
- **Never write a command, flag or version from memory** — test commands and
  tool versions come from the product's own scripts and CI, `docs/stack-reference/`
  and `pins.yaml`. Where none covers it, the layer is `NOT RUN — command not
  sourced` and the verdict follows (Phase 5), with `/research` as the next step.
- **PASS WITH WARNINGS does not block QA hand-off** — it records advisory
  gaps for `/story-done` to follow up on.
- **A suspected cross-tenant exposure is S1** (`qa-lead` severity rule): report
  it immediately in conversation, do not batch it into the end-of-run report.
- **`quick` argument** skips Phase 3 (coverage scan) and Phase 4 Batch 3.
  Use it for rapid re-checks after fixing a specific failure.
- Use `AskUserQuestion` for all manual smoke check verification.
- **Never write the report or the evidence transcripts without asking** — Phase 6
  requires explicit approval before any file is created. A declined write ends
  with `BLOCKED — write declined by user`; the report stays in conversation and
  no gate outcome (PASS or otherwise) is announced as recorded.
