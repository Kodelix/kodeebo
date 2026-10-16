---
name: setup-stack
description: "Configure stack, deploy target, distribution and tenancy in project.yaml; verify the stack reference is present and fresh for every layer; run the coherence check."
argument-hint: "[layer=value ...] | verify | refresh [layer] | no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-stack/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh validate_enum_value *), Bash(bash .claude/hooks/yaml-helper.sh validate_yaml_enum *), Bash(date *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(git diff --stat -- docs/stack-reference/), Bash(git diff --stat -- docs/stack-reference/*), Bash(go version), Bash(java -version), Bash(gradle --version), Bash(node --version), Bash(pnpm --version), Bash(docker compose version), Bash(xcodebuild -version)
model: sonnet
---

# Stack Setup

When this skill is invoked:

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,stack`

**Always collaborative.** `/setup-stack` is a one-time, project-shaping choice
(backend track, tenancy model, distribution model) that every later skill routes
on and that is expensive to reverse once data exists. It ignores
`modes.automation`: every question is asked and every write is approved, in
every mode, as `.claude/docs/automation-modes.md` describes for exempt skills.

**What this skill owns.** It writes only these `project.yaml` keys, each
validated against the enum list in `.claude/hooks/yaml-helper.sh`
(`_yaml_helper_enums`): `stack.backend`, `stack.web`, `stack.site`,
`stack.mobile`, `stack.desktop`, `stack.data`, `stack.messaging`, `deploy.target`,
`distribution.model`, `tenancy.model`, `layout.code_roots`, `core.track` (and
`core.repo` / `core.version` / `core.modules` when the user supplies them). It
never writes `modes.*`, `docs.density`, `qa.level` or `team.size`, and it never
edits `CLAUDE.md`: the stack references under `docs/stack-reference/` are read
on demand by the agents, not imported into the session.

**Never write a version from memory.** The stack's versions live in
`docs/stack-reference/<layer>/VERSION.md` and `docs/stack-reference/pins.yaml`,
sourced from pages fetched in a research run. This skill reads them and reports
on them. A version that must change is changed by the `researcher` agent from
fetched sources (Phase 5), never typed in here.

**Tier awareness.** The `workflow` tier resolved above governs the finish path in
Phase 7: `minimal` goes `/brainstorm` → `/create-stories` → `/dev-story` (the stack
is step 1 of 4 and a missing product brief is normal here); `standard` / `full`
continue the full pipeline. If the block did not render (shell preprocessing
disabled), assume `minimal` (the default). The tier never changes what this skill
validates.

## 1. Parse Arguments

Four modes:

- **Guided**: `/setup-stack` — no arguments; evidence scan, then one question per unset layer (Phase 2)
- **Direct**: `/setup-stack backend=go web=vite-react tenancy=shared-schema-rls` — `key=value` pairs, where key is one of `backend`, `web`, `site`, `mobile`, `desktop`, `data`, `messaging`, `deploy`, `distribution`, `tenancy`, `track`, `roots`. Anything not given stays as it is in `project.yaml`; nothing is guessed to fill it in. `data` and `roots` take a comma list (`data=postgres,redis`).
- **Verify**: `/setup-stack verify` — change nothing in `project.yaml`; run Phases 3 (validation of what is already there), 5 (stack reference) and 6 (coherence) and report
- **Refresh**: `/setup-stack refresh [layer]` — re-verify one layer's stack reference (or every configured layer) through the `researcher` agent (Phase 5)

An unrecognised key or a malformed pair: print the usage line and stop. Do not
write anything on a guess.

---

## 2. Choose the Stack (Guided and Direct)

**Read `references/2-choose-stack.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Validate the Profile

**Read `references/3-validate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Write `project.yaml`

**Read `references/4-write-config.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Verify the Stack Reference

**Read `references/5-stack-reference.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Run the Coherence Check

**Read `references/6-coherence.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7. Output Summary

**Read `references/7-output-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Guardrails

- NEVER guess a stack layer, a version or a tenancy model — evidence from the repository, an explicit user answer, or the layer stays unset.
- NEVER write a version, release date or support claim from memory. A gap is written down as `NOT SOURCEABLE — <what>, not covered by <path>`.
- NEVER overwrite a configured value without showing the old and new value and asking. Re-running the skill on a configured project is a review, not a reset.
- Every value is validated against `_yaml_helper_enums` (and the `stack.data` members) before the approval prompt, not after the write.
- A stack reference that is missing, unparseable or older than 90 days is reported by name. The summary never reads COMPLETE while one is outstanding, and never reads COMPLETE if the coherence check did not run.
- Do not edit `CLAUDE.md`, `docs/stack-reference/**` or `docs/stack-reference/pins.yaml` from this skill directly. Reference changes go through the `researcher` agent after the user approves.
- Do not scaffold a product. Creating `backend/`, `web/`, a Gradle or Xcode project is a story (`/dev-story` or `/vertical-slice`), not part of stack selection; this skill records `layout.code_roots` for directories that already exist.
