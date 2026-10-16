# /ux-design — Sections 5 and 5b: Cross-Reference Check and Handoff

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Cross-Reference Check

Before marking the spec as ready for review, run these checks. Each reports a
result or **not run (reason)** — a check whose input was absent says so by name.

**1. Feature-spec requirement coverage**: Does every UI requirement from the
feature spec(s) that references this screen (Detailed Behaviour, Data & Contracts,
Acceptance Criteria) have a corresponding element in this spec? Present any gaps.
Include the **negative cases** the spec lists (wrong role, other tenant, over
quota, provider down) — each must have a state in Section 6.

**2. Pattern library alignment**: Are all interaction patterns used in this spec
referenced by name? If a new pattern was invented during this spec session, flag
it for addition to the pattern library:
Use `AskUserQuestion`:
- "This spec uses [pattern name], which isn't in the pattern library yet. What should we do?"
- Options: "Add it to the pattern library now", "Flag it as a gap and continue", "Skip — this pattern is one-off"

**3. Navigation consistency**: Do the entry/exit points in this spec match the
navigation map in `app-shell.md` and any related specs? Flag mismatches.

**4. Accessibility coverage**: Does the spec address the conformance target
committed to in `design/accessibility-requirements.md` (focus order, announcements,
contrast table, forms, cognitive load)? If not, flag open questions.

**5. State completeness**: Every data-dependent element has loading, empty (first
use), empty (no results), error and populated defined; every gated element has
its **forbidden**, **plan-limit reached** and **read-only (past due / trial
ended)** variant defined, or an explicit "not gated" statement.

**6. Direction and locale**: every text element has an expansion budget and RTL
behaviour; direction-implying icons are listed for mirroring; no text in images.

**7. Entitlements and contracts**: every plan gate cites an entitlement key from
the pricing model (never a literal limit or price); every action in Section 9
names an operation that exists in `contracts/` or is flagged "contract needed"
for `api-designer`. If `contracts/` or the pricing model does not exist, say
"not run — [artifact] absent".

Present the check results:
> **Cross-Reference Check: [Screen Name]**
> - Feature-spec requirements: [N of M covered / all covered / not run (no spec)]
> - New patterns to add to library: [list or "none"]
> - Navigation mismatches: [list or "none" / not run (no app shell)]
> - Accessibility gaps: [list or "none"]
> - Missing states: [list or "none"]
> - Direction/locale gaps: [list or "none"]
> - Entitlement / contract gaps: [list or "none" / not run (artifact absent)]

---

## 5b. Handoff

When all sections are approved and written:

### Update Session State

Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md` (Current task `/ux-design <screen> — <verdict>`,
Next step = the recommended option below — `/ux-review [filename]` unless the
user chose otherwise —, plus Blocked on / Files in progress / Open questions;
append the Notes line; leave the `Flow:` line and other blocks alone), recording
also:
- Task: [screen-name] UX spec
- Status: Complete (or In Review)
- File: design/ux/[filename].md
- Sections: All written
- Next: [suggestion]

### Suggest Next Step

Before presenting options, state clearly:

> "This spec should be validated with `/ux-review` before it enters the
> implementation pipeline. Phase gates require key screen specs to have passed
> `/ux-review` at `workflow: full` (recommended at `standard`). Visual design
> continues in `/impeccable` against `PRODUCT.md` and `DESIGN.md`."

Then use `AskUserQuestion`:
- "Run `/ux-review [filename]` now, or do something else first?"
  - Options:
    - "Run `/ux-review` now — validate this spec"
    - "Design another screen first, then review all specs together"
    - "Update the interaction pattern library with new patterns from this spec"
    - "Stop here for this session"

If the user picks "Design another screen first", add a note: "Reminder: run
`/ux-review` on all completed specs before running `/gate-check`."

### Cross-Link Related Specs

If other UX specs link to or from this screen, note which ones should reference
this spec. Do not edit those files without asking — just name them.

---
