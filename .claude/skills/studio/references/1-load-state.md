# /studio — Phase 1: Load State

> Part of `/studio`. `SKILL.md` names when to read this file.

1. **Checkpoint.** Read `production/session-state/active.md` if it exists: first
   the `<!-- CHECKPOINT -->` block's `Flow:` line (the part the session-start hook
   injects), then the `## Studio flow` block it points to (or
   `## Feature pipeline — <slug>` when `/team-feature` owns the flow).
   Extract: current flow, current step, open gate, blockers, artifacts so far.
   A `Flow:` line with no matching block, or a block the `Flow:` line does not
   mention, is reported as an inconsistent checkpoint — not silently trusted.
   A checkpoint describing an unfinished flow is surfaced before anything else:
   "Flow `<flow>` is at step `<step>` waiting on `<gate>`. Resume it, or start
   the new goal?" (unless the argument is `resume`).

2. **Configuration.** Use the resolved block above. Note any unset stack layer:
   a flow that needs it routes through `/setup-stack` first. Note the effective
   `workflow` tier — and, for a named feature, its `system_overrides` entry — it
   decides which documents the plan asks for (`3-flows.md`, section 0). If the
   block is missing, say so and use the defaults in `config-resolution.md`; never
   assume a tier.

3. **Where the product is.** Run
   `bash .claude/scripts/artifact-check.sh` (whole ladder) — or
   `--path minimal` when the effective workflow is `minimal` — and keep the
   output: it says which artifacts exist (`PRESENT`/`ABSENT`/`PATTERN_MISS`).
   It emits observations only; this skill decides what they mean.

4. **Standing decisions.** Read `docs/ROADMAP.md` (decisions tables) if it
   exists in this repo, and `design/product-brief.md` decision log if present.

5. **Status mode** stops here: print
   ```
   Stage: <project.stage>   Workflow: <tier>   Automation: <mode>
   Flow: <flow or none>     Step: <step>        Waiting on: <gate or nothing>
   Blockers: <list or none>
   Next: <one line>
   ```
