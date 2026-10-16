# /review-all-specs — Phase 7: Handoff

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Handoff

After all file writes are complete, use `AskUserQuestion` for a closing widget.

Before building options, check project state:
- Are there any Warning-level items that are simple edits (flagged with "30-second edit", "brief addition", or similar)? → offer inline quick-fix option
- Are any specs in the "Flagged for Revision" table? → offer /spec-review option for each
- Did Phase 3b record core extract-candidates? → offer `/core-extract` (only when the cores are in use; otherwise note them in the report)
- Did a permission/quota change touch a spec already in stories or ADRs? → offer `/propagate-spec-change`
- Read `domain-map.md` for the next feature with Status: Not Started → offer /design-spec option
- Is the verdict PASS or CONCERNS? → offer /gate-check or /create-architecture

Build the option list dynamically — only include options that apply:

**Option pool:**
- `[_] Apply quick fix: [W-XX description] in [spec-name].md — [effort estimate]` (one option per simple-edit warning; only for Warning-level, not Blocking)
- `[_] Run /spec-review [flagged-spec-path] — address flagged warnings` (one per flagged spec, if any)
- `[_] Run /propagate-spec-change [spec] — a revised rule affects existing ADRs or stories`
- `[_] Run /design-spec [next-feature] — next in specification order` (always include, name the actual feature)
- `[_] Run /create-architecture — begin architecture (verdict is PASS/CONCERNS)` (include only if the verdict is PASS or CONCERNS — never on FAIL or NOT ASSESSED)
- `[_] Run /gate-check — validate the Product Design phase gate` (include if verdict is PASS)
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

In collaborative and guided modes, never end the skill with plain text — always
close with this widget. In autonomous mode, print the verdict and recommended
next step, then record via `log_decision` (no widget).

---
