# /review-all-specs — Phase 6: Write Report and Flag Specs

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Write Report and Flag Specs

Use `AskUserQuestion` for write permission:
- Prompt: "May I write this review to `design/specs/spec-cross-review-[date].md`?"
- Options: `[A] Yes — write the report` / `[B] No — skip`

> **`[date]` here means ISO 8601 — `YYYY-MM-DD`, e.g.
> `spec-cross-review-2026-08-19.md`. This is not a style preference.**
> `.claude/scripts/review-scope.sh` picks the prior review with
> `sort | tail -1`, so lexical order IS chronological order only for ISO dates.
> Written as `aug-19-2026` or `19-08-2026`, the wrong file is chosen as the
> baseline, the changed-set is computed from it, and specs modified since the
> real last review silently escape the next one. That is the same
> quiet-escape failure the fixes documented at the top of that script exist to
> prevent.

If any specs are flagged for revision, use a second `AskUserQuestion`:
- Prompt: "Should I update the domain map to mark these specs as needing revision? ([list of flagged specs])"
- Options: `[A] Yes — update domain map` / `[B] No — leave as-is`
- If yes: update each flagged spec's Status field in `domain-map.md` to "Needs Revision".
  (Do NOT append parentheticals to the status value — other skills match "Needs Revision"
  as an exact string and parentheticals break that match.)
- If `domain-map.md` is absent, say so and skip — do not create it (`/map-domains` owns it).

### Session State Update

After writing the report (and updating the domain map if approved), silently
append to `production/session-state/active.md`:

    ## Session Extract — /review-all-specs [date]
    - Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
    - Specs reviewed: [N of M present]
    - Phases / checks not run: [names, or "None"]
    - Flagged for revision: [comma-separated list, or "None"]
    - Blocking issues: [N — brief one-line descriptions, or "None"]
    - Recommended next: [the Phase 7 handoff action, condensed to one line]
    - Report: design/specs/spec-cross-review-[date].md   ← only if user approved the write
    - Report: (not written — user declined at [date])  ← only if user declined the write

Use the appropriate line based on the user's response to the write-permission widget in Phase 6.

Also update the CHECKPOINT block per `.claude/docs/checkpoint-handoff.md`:
Current task `/review-all-specs — <verdict>`, Next step = the Phase 7 recommended
action, plus Blocked on / Files in progress / Open questions. A NOT ASSESSED or
FAIL verdict, or a declined report write, still updates it with the blocker.

If `active.md` does not exist, create it from `.claude/docs/templates/session-state.md`
and put this block in its Notes region.
Confirm in conversation: "Session state updated."

---
