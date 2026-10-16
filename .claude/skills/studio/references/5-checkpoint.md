# /studio — Phase 5: Checkpoint and Hand Off

> Part of `/studio`.

After **every** gate and at the end of the run, update
`production/session-state/active.md` (the session checkpoint). `CLAUDE.md` and
`.claude/rules/agent-memory.md` exempt updates to a skill's **own block** in
that file from the "May I write" prompt: here, the CHECKPOINT block and the
`## Studio flow` block — never another skill's block or the rest of the file.
Keep it bounded: replace your own block, never append history. The update
follows `.claude/docs/checkpoint-handoff.md`; `/studio` is the skill that owns the
`Flow:` line, and it overwrites `Current task` and `Next step` after the gate so
they agree with the flow's next step.

**Two writes, because two regions are read by different consumers:**

1. **The `<!-- CHECKPOINT -->` block** (what the session-start hook shows after a
   restart or `/compact`): overwrite its `Flow:`, `Current task:`, `Next step:`,
   `Blocked on:` and `Open questions:` lines — `Flow:` reads
   `/studio <flow> — step <n>/<total> — waiting on <gate or nothing>`. Schema:
   `.claude/docs/templates/session-state.md`. If `active.md` has no markers, insert
   the template's STATUS and CHECKPOINT blocks at the top and leave the rest alone.
2. **The `## Studio flow` block** in the Notes region (the detail below). Replace it
   in place; do not append history. Its heading is `/studio`'s alone —
   `/team-feature` keeps `## Feature pipeline — <slug>`, so neither overwrites the
   other. When `/studio` runs `/team-feature`, it records that block's path under
   `Artifacts:` and leaves the block to `/team-feature`.

```markdown
## Studio flow
**Goal:** <one sentence>
**Flow:** <flow>   **Tier:** <minimal|standard|full>   **Started:** <date>
**Step:** <n>/<total> — <step name>   **Waiting on:** <gate or nothing>
**Artifacts:** <paths, newest first>
**Skipped:** <step — `tier` or `trigger absent` — reason>
**Blockers:** <list or none>
**Next:** <exact command, e.g. `/dev-story production/epics/billing/story-003.md`>
```

End the run with:

1. What was done (artifacts with paths).
2. What was not done and why (skipped, blocked, not run).
3. Which DoD gates are evidenced so far for any story touched.
4. The next command — one line the user can run, or `/studio resume`.
