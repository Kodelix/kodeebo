# /story-done — Phase 5: Code Review Gate

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Code Review Gate

**First, look for an existing review.** Read the story header for a
`Principal Engineer Review (PE-CODE-REVIEW)` line, and Glob
`production/qa/evidence/<STORY-ID>/code-review.md` (written by `/code-review`).
- A review dated **at or after** the last change to the implementation files
  (by the **Dating rule** in `2-read-story.md`: commit date for tracked, clean
  files; `git status --porcelain` + file mtime for files with uncommitted edits;
  the review's own date line otherwise — and name the `freshness source:`) with
  verdict `APPROVED` or `CONCERNS (accepted)` → use it; do not re-run. Quote its
  verdict and date. If the files changed after the review and the order cannot
  be established, the review is stale.
- A review with verdict `REJECTED` that is not followed by a newer review →
  **BLOCKED**: the issues must be resolved, then `/code-review` re-run.
- A review older than the code → stale; treat as none.
- None → continue below.

**Review mode check** — apply before spawning PE-CODE-REVIEW:
- `solo` → skip. Note: "PE-CODE-REVIEW skipped — Solo mode." Proceed to Phase 6 (the code-level checks the review would have done are still partly covered by Phase 3 and Phase 4 greps, and gates 2 and 7 in Phase 6 are checked from evidence).
- `lean` → use `AskUserQuestion` before proceeding:
  - Prompt: "Code review is skipped in lean mode. Did you run `/code-review` on the implemented files?"
  - Options:
    - `Yes — /code-review passed or was approved with suggestions`
    - `No — skipping code review for this story`
    - `No — I'll run /code-review before the sprint close-out`
  - Record the answer in the completion notes (Phase 8). All three options proceed to Phase 6.
- `full` → spawn as normal.

Spawn `principal-engineer` via `Agent` using gate **PE-CODE-REVIEW** (`.claude/docs/director-gates/pe-code-review.md`).

Pass: implementation file paths per code root, the story file path, the relevant spec section, the governing ADR(s) and control manifest, the test paths and the evidence directory.

If the story touches security-sensitive paths (`.claude/rules/security-sensitive.md`: `**/auth/**`, `**/identity/**`, `**/billing/**`, `**/licensing/**`, `**/tenancy/**`, `**/admin/**`) and no `appsec-engineer` review is recorded in the story header or `code-review.md`, say so and recommend `/code-review` (which spawns `appsec-engineer` for those paths) before closing. A missing security review on a sensitive story is flagged ADVISORY here and feeds DoD gate 7 in Phase 6.

Present the verdict to the user. If CONCERNS, surface them via `AskUserQuestion`:
- Options: `Revise flagged issues` / `Accept and proceed` / `Discuss further`

If REJECT, do not proceed to the Phase 7 verdict until the issues are resolved —
the story is BLOCKED.
If NOT ASSESSED, name the input the gate said was missing and never treat it as
APPROVE: supply it and re-run the gate, or carry it to Phase 7, where it keeps
the verdict at best NOT ASSESSED.

If the story has no implementation files yet (verdict is being run before coding
is done), skip this phase and note: "PE-CODE-REVIEW skipped — no implementation
files found. Run after implementation is complete." A story with no implementation
files and a code story type cannot be COMPLETE — Phase 3's file-existence checks
fail.

---
