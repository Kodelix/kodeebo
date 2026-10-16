# Checkpoint Handoff — the last step of every skill that changes something

`production/session-state/active.md` is the session's memory: the next session
(and `/studio resume`) starts from its CHECKPOINT block, not from the chat. A
skill that finishes without updating it leaves the next session guessing — seen
in the Wave 7 dogfood, where `/studio` had to search old transcripts for the
path `/brainstorm` had recommended.

## When

At the end of every run that **wrote or changed an artifact** (any file under
`design/`, `docs/`, `business/`, `production/`, a code root, `project.yaml`),
**or** ended in a verdict that changes what happens next (BLOCKED, NOT ASSESSED,
a gate decision). Also when the user declines a write: record that nothing was
written and why. A run that only read and reported, and changed nothing, may
skip it.

## How

1. Read `production/session-state/active.md`. If it does not exist, create it
   from `.claude/docs/templates/session-state.md` (the schema hooks depend on).
2. In the `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` region, **overwrite**:
   - `**Updated:**` — today's date
   - `**Current task:**` — `/<skill> <target> — <verdict>` in one line
   - `**Next step:**` — the first item of this run's recommended next steps,
     as a concrete command (`/setup-stack`, `/design-spec menu-management`),
     concrete enough to resume cold
   - `**Blocked on:**` — the blocker and what clears it, or `nothing`
   - `**Files in progress:**` — the artifacts this run wrote, or `none`
   - `**Open questions:**` — the questions this run left open, or `none`
3. **Leave alone** what this skill does not own: the `**Flow:**` line and any
   `## Studio flow` / `## <Team> pipeline — <slug>` block belong to `/studio`
   and the team skills; `**Run result:**` belongs to `/dev-story`. Never delete
   the narrative below `<!-- /CHECKPOINT -->`.
4. Append one line to the Notes region:
   `- <date> /<skill> <target> — <verdict>; wrote <paths or "nothing">; next: <step>`.
   When the run chose between paths (e.g. `/brainstorm` recommending a build
   path), name the chosen path and its ordered steps here in a few lines.
5. Keep the CHECKPOINT region under ~25 lines (session-start shows it verbatim).

This write needs no "May I write" (CLAUDE.md: updates to the skill's own block of
the checkpoint are exempt). The exemption is this block only — every other file
the skill edits, under `design/` or anywhere else, asks as the automation mode
says. Use Edit on an existing file, Write only to create it.

## Under `/studio`

When `/studio` (or a team skill) is driving, it writes the checkpoint after each
step as well (`studio/references/5-checkpoint.md`). The skill still updates
`Current task` and `Next step` — the two agree, because `/studio`'s next step is
the flow's next step and it overwrites them after the gate.
