# /adopt — Phase 7: Offer First Action

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Offer First Action

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/adopt <audit mode> —
<plan written | cancelled, nothing written>`, Next step = the first plan step
(the single highest-priority gap offered below, as a concrete command), plus
Blocked on / Files in progress (`docs/adoption-plan-[date].md`) / Open questions;
append the Notes line. If the user cancelled in Phase 5, run this step there
instead and record that nothing was written.

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`. Choose the first
branch that applies:

**If the stack is not configured (and ADRs, stories or code exist):** every other
fix reads `project.yaml`'s stack and the stack reference, so it comes first.
Use `AskUserQuestion`:
- "The most urgent fix is the stack: `project.yaml` has no `stack.*` values, so
  ADR checks and stack-version risk checks have nothing to compare against. Run
  `/setup-stack` now? It reads your manifests and asks before it writes anything."
  - "Yes — start `/setup-stack`"
  - "I'll configure it myself"
  - "Done — leave me with the plan"

**If there are parenthetical status values in `domain-map.md`:**
Use `AskUserQuestion`:
- "The most urgent fix is `domain-map.md` — [N] rows have parenthetical status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories, and /architecture-review right now. I can fix these in-place."
  - "Fix it now — edit domain-map.md"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

**If ADRs are missing `## Status` (and no parenthetical issue):**
Use `AskUserQuestion`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**If specs are missing Acceptance Criteria (and no blocking issues above):**
Use `AskUserQuestion`:
- "The most urgent gap is missing Acceptance Criteria in [N] spec(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority spec filename]?"
  - "Yes — add Acceptance Criteria to [spec filename] now"
  - "Do all [N] specs one by one"
  - "I'll handle specs myself"

**Otherwise, if any BLOCKING or HIGH gap remains** (one no branch above names —
e.g. a missing TR registry or a sensitive feature with no threat model):
Use `AskUserQuestion`:
- "The most urgent remaining gap is [first BLOCKING or HIGH item in the plan] —
  [one line on what it breaks]. Start on it now?"
  - "Yes — start on [item]"
  - "Show me that plan item first"
  - "Done — leave me with the plan"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion`:
- "No blocking gaps — this project is studio-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Done — I'll work through the plan at my own pace"

> **Adoption plan saved to `docs/adoption-plan-[date].md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

---
