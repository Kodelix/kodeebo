---
paths:
  - ".claude/agent-memory/**"
---

# Agent Memory Rules

**Agent memory is one of three writes that need no "May I write?"** The other two
are named in `CLAUDE.md`:

- **Updates to the skill's own block in `production/session-state/active.md`**
  — the session checkpoint the hooks and the next session rely on. A skill
  appends its block, or replaces the block it owns (`## Studio flow`,
  `## <Team> pipeline — <slug>`, the CHECKPOINT region); it never rewrites
  another skill's block or the rest of the file.
- **A subagent's new file at a path named by the orchestrating skill or
  `studio-orchestrator`.** Only a file that does not exist yet, under `docs/`,
  `design/`, `business/`, `production/` or a test directory, only at a path the
  skill's or orchestrator's prompt names (never one you chose), and only inside a
  phase the user approved. It never covers an edit to an existing file — spec,
  doc, source or config — nor the main session running a skill: those writes
  follow the automation mode (`.claude/docs/automation-modes.md`). A folder
  alone never exempts a file.

`.claude/agent-memory/` is gitignored, per-agent, and never ships. Its exemption
exists because the memory is the agent's own working notes about how to do its
job, not a project artifact.

None of the three extends anywhere else. The Collaboration Protocol still governs
every other write — all existing source and config, and any file whose path no
skill or orchestrator named: ask first, naming the path.
Writing a memory is never a substitute for asking, and a memory must never be
used to record something the user declined to have written.

## Never record a temporary absence as a durable fact

This is the failure this file exists to prevent, and this repo is unusually
exposed to it.

**SaaS Studio ships as a template the user clones *as their product*.** So on day one every
agent observes the same things — no product code, no specs, no stack configured, no
`tests/performance/` — and every one of those observations is **guaranteed to
stop being true**. A memory reading *"this repo is the framework, not a product;
perf requests have no target"* is accurate when written and actively harmful two
weeks later, when it tells a future run to return BLOCKED on a project that now
has a build. The agent will not re-derive it; that is what memory is for.

So:

- **Prefer recording a method over a state.** "Confirm a running stack and a
  captured profile exist before profiling; return BLOCKED naming what is missing
  rather than estimating" is durable. "There is no product here" is a timestamp.
- **If you must record a state, state what invalidates it**, on the same line:
  `INVALIDATED WHEN: project.yaml declares a stack, or any code root (backend/, web/, mobile/...) contains product code.`
  A reader with no other context must be able to tell whether the note still
  holds.
- **Never record absence of a product, of assets, of tests or of config as a
  settled property of the project.** Those are the states CCGS exists to move a
  user out of.

## Disclose the write

Say in your response that you recorded a memory and where. An unmentioned write
is indistinguishable from no write, and the user cannot correct a note they do
not know exists — the same reason a skipped check has to announce itself
(`.claude/rules/skill-authoring.md`, obligation 3).

## Verify before you trust

A recalled memory reflects what was true when it was written. If it names a file,
a path, a setting or a count, **check that it still holds before acting on it**.
Memory is a starting point for investigation, never evidence.
