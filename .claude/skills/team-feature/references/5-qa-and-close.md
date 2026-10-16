# /team-feature — Phases 8–9: QA, Close, Checkpoint

> Part of `/team-feature`. Read again if the conversation was compacted.

## 1. Phase 8 — QA

1. `/smoke-check` first (build stability: stack up, migrations run, health
   checks). Its `FAIL` stops the phase; `NOT ASSESSED` or `UNKNOWN` is carried into
   the QA call below as a warning, never as a pass.
2. `/team-qa feature: <context-or-slug>` via the `Skill` tool. It resolves the
   scope from the story files, writes the QA plan and cases, runs the automated
   suites and manual passes (English and Arabic/RTL for UI), files bugs, and
   returns a sign-off verdict: `NOT ASSESSED` / `APPROVED` / `APPROVED WITH
   CONDITIONS` / `NOT APPROVED`. At `studio` size spawn `qa-lead` directly for the
   strategy first.
3. Map: `APPROVED` → continue; `APPROVED WITH CONDITIONS` → the conditions are
   carried as gaps; `NOT APPROVED` → this feature's verdict is **BLOCKED**, the
   failed stories go back to Phase 7; `NOT ASSESSED` → the feature's verdict is
   **NOT ASSESSED** with the missing evidence named. The user may override past
   a non-APPROVED sign-off; record the verdict, the open concerns and that the user
   chose to proceed.

## 2. Phase 9a — Release notes (user-visible only)

If the feature changes anything a customer or a self-hosted operator sees:
`/release-notes` (and `/changelog` for the entry). Pricing/plan changes need the
`pricing-billing-designer`'s statement. Not user-visible → `skipped — not
user-visible`.

## 3. Phase 9b — The `/story-done` hand-off

`/story-done` is user-run. For every story print, in wave order:

```
/story-done production/epics/<context>/<story-file>.md
   evidence: production/qa/evidence/<STORY-ID>/   (present | ABSENT)
   code review: <verdict | skipped — mode>   QA: <PASS | PASS WITH NOTES | n/a>
   DoD gates evidenced so far: <n>/8 — missing: <gate names>
```

**Gate — each story's Done** is `/story-done`'s, decided by the user there. This
skill does not mark a story Complete, and says "ready for `/story-done`" only for
a story whose evidence folder exists and whose checks were not `FAILED`.

## 4. Report and checkpoint

Ask: "May I write the feature report to
`production/features/<slug>/feature-report.md`?" Contents as listed in the
skill's Output section.

Update `production/session-state/active.md` after **every** gate and at the end,
per `.claude/docs/checkpoint-handoff.md` —
the checkpoint, exempt from the "May I write" prompt. Two writes: overwrite the
`Flow:`, `Current task:`, `Next step:` and `Blocked on:` lines of the
`<!-- CHECKPOINT -->` block (the part the session-start hook shows;
`/team-feature <slug> — step <n>/<total> — waiting on <gate or nothing>`), and
replace this pipeline's own block in the Notes region — do not append history. The
heading is this skill's alone (`/studio` keeps `## Studio flow`), so the two
cannot overwrite each other:

```markdown
## Feature pipeline — <slug>
**Goal:** <one sentence>
**Flow:** feature (team-feature)   **Started:** <date>
**Step:** <n>/<total> — <step name>   **Waiting on:** <gate or nothing>
**Artifacts:** <paths, newest first>
**Skipped:** <step — reason>
**Blockers:** <list or none>
**Next:** <exact command, e.g. `/story-done production/epics/billing/story-003.md`>
```

End the run with: what was done (artifacts with paths); what was not done and why
(skipped, blocked, not run); which DoD gates are evidenced for each story; the
next command — one line the user can run, or `/studio resume`.
