# /dev-story — Phase 8: Update Session State

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Update Session State

Silently update the checkpoint in `production/session-state/active.md` —
**overwrite the `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` block, never
append** (rule: `.claude/docs/checkpoint-handoff.md`; schema:
`.claude/docs/templates/session-state.md`). `session-start.sh`
shows exactly that block when the next session opens, so it is what a cold
resume starts from:

```
<!-- CHECKPOINT -->
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /dev-story — [story-path] ([story title])
**Flow:** [keep the existing `Flow:` line unchanged — it belongs to `/studio` or `/team-feature` — or `none` if there was none]
**Next step:** /code-review [files], then /story-done [story-path]
**Blocked on:** [nothing, or the blocker]
**Files in progress:** [files changed, comma-separated; test files included]
**Run result:** [the Phase 6 `Run result:` line, verbatim — `/story-done` reads it here]
**Open questions:** [none, or one line each — include checks listed under "Not run"]
<!-- /CHECKPOINT -->
```

**Next step** follows the Phase 7 result — the line above is the Implementation
Complete one. On **INCOMPLETE** or **Needs Attention** write
`**Next step:** /dev-story [story-path] — resume: [the breakage or failing command Phase 6 named]`.
On **BLOCKED** (Phase 2) write the unblocking action instead —
`/research [feature]`, `/threat-model [feature]`, the contract story to finish,
`/setup-stack`, `/architecture-decision accept ADR-NNNN`, the dependency story to
finish, the manifest diff to review — and fill **Blocked on**. `/help` reads this
line: a checkpoint that says `/story-done` tells it the work is written.

Also append the Notes line the handoff rule asks for
(`- <date> /dev-story <story-path> — <result>; wrote <files>; next: <step>`).

If `active.md` does not exist, create it from the template. If it exists with no
markers (a file from before the schema), insert the template's STATUS and
CHECKPOINT blocks at the top and leave the rest untouched. Confirm: "Session
state updated."

---
