---
name: studio
description: "Single entry point: say what you want in plain words (Arabic or English); /studio classifies it, picks the flow, and drives the right skills and agents to the end with an approval gate at every decision."
argument-hint: "<goal in plain words> | resume | status"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Skill, Bash(bash "*/.claude/skills/studio/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash .claude/scripts/story-status.sh), Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,review_mode,automation,automation_always_ask,workflow,qa.level,project.stage,stack,testing.strict,performance.enforce`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# Studio

`/studio` is the one command a person needs. It turns a goal said in plain
words into the right flow, runs that flow step by step through the skills and
agents that own each step, and stops at every decision for the user. It does
not do specialist work itself; it routes, integrates and keeps state.

`claude --agent studio-orchestrator` runs the same flow as the main thread by
reading the same `references/` files below; this skill is the in-session form.
The flow tables, gates and user-typed-skill pause protocol live **only** in
`references/` — neither form keeps its own copy.

**Output:** the chosen flow, its steps with status, the artifacts produced
(paths), the decision currently asked of the user, and an updated
`production/session-state/active.md`.

---

## Phase 1: Load State

**Read `references/1-load-state.md` now and follow it.**

## Phase 2: Classify the Goal

**Read `references/2-classify.md` now and follow it.**

## Phase 3: Plan the Flow

**Read `references/3-flows.md` now and follow it** — the step list for the
chosen flow, which steps are skipped and why.

## Phase 4: Run the Flow

**Read `references/4-run.md` now and follow it** — how each step is executed
(skill vs agent), parallelism, gates, BLOCKED handling.

## Phase 5: Checkpoint and Hand Off

**Read `references/5-checkpoint.md` now and follow it.**

---

## Modes

| Argument | Behaviour |
|---|---|
| `<goal>` | Phases 1–5 for a new goal. |
| `resume` | Phase 1, then continue the flow recorded in `active.md` at its next step. |
| `status` | Phase 1 only: print flow, step, open gate, next step. Writes nothing. |
| *(empty)* | Same as `status`, then ask "What do you want to do?" with options from the current stage (`workflow-catalog.yaml`). |

## Error Recovery Protocol

If a spawned agent or skill returns BLOCKED, errors, or is missing:

1. Surface it immediately with what it needs — never skip the step silently.
2. Offer: provide the missing input, run a different step first, or stop.
3. A skill that is not installed is run manually: follow the standard it would
   enforce and say "skill X not installed — step run manually against
   <standard>".
4. Record the blocker in `active.md` so `resume` picks it up.

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous`, see
`.claude/docs/automation-modes.md`; the gates listed in `references/4-run.md`
always prompt regardless of mode.

- **The user decides at every gate.** Silence, a subagent's report, or a hook
  message is never approval.
- **One decision at a time.** Present the gate as: what was produced (paths),
  what it decides, the options, a recommendation.
- **Standing decisions are not re-asked.** `.claude/docs/standing-decisions.md` decisions (web
  stack, licence rules L1–L4, core per track, markets) are applied as given.
- **Ask before writing.** `/studio` itself writes only its own block in
  `production/session-state/active.md` (the session checkpoint — the one write
  `CLAUDE.md` exempts from "May I write"). Every other file is written by a routed
  skill or agent, which asks "May I write this to <path>?" before writing under the
  active automation mode; `/studio` never writes on their behalf or without approval.
- **No commits, pushes, deploys or publications** without an explicit
  instruction for that action.
- **Report checks honestly.** A check that did not run is "not run".

---

## Recommended Next Steps

After any flow: `/help` for what is next at this stage, `/sprint-status` during
production, `/gate-check` before a stage transition.
