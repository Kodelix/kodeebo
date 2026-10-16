# /architecture-review — Phase 9: Handoff

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 9: Handoff

After completing the review and writing approved files, present:

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer), and any `/threat-model` runs the
   threat-model coverage table asks for
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅ or ❌:
   - test scaffolding for each layer in `resolve_code_root` (`*_test.go`/`integration` tag, `src/test` + `src/integrationTest`, `web/e2e/`, `app/src/test`, `src/commonTest`) — if ❌: run `/test-setup`
   - the CI workflow running the suite on push and PR (`.github/workflows/`) — if ❌: run `/test-setup`
   - `docs/architecture/perf-budgets.md` — if ❌: run `/perf-profile` (creates it) or ask `performance-engineer`
   - `docs/architecture/threat-models/<feature>.md` for each `SENSITIVE` requirement — if ❌: run `/threat-model <feature>`
   - `design/ux/interaction-patterns.md` and the accessibility requirements document — if ❌: run `/ux-design` (only when the product has a UI)
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves, and after any pin change in `pins.yaml`"

**Checkpoint.** Before the question below, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/architecture-review <focus> — <PASS | CONCERNS | FAIL | NOT
ASSESSED>`, Next step = the first immediate action above (the top ADR to create,
or the first ❌ pre-gate step), plus Blocked on / Files in progress / Open
questions; append the Notes line. Still updated when the verdict is `NOT
ASSESSED` or the user declined the write (record nothing written and why).

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [title]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
    - [C] Close the next pre-gate gap — `/threat-model <feature>` if a sensitive requirement lacks one, else `/ux-design` if UX/accessibility files are ❌ (only show if either applies; when both do, name `/ux-design` in the prompt text as the step after)
    - [D] Stop here for this session
- If all pre-gate checklist items are ✅ and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/create-control-manifest`, then `/gate-check pre-production`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [title]`
    - [C] Stop here for this session

---
