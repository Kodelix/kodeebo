# /create-architecture — Phase 9: Handoff

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 9: Handoff

**Step 1 — Update session state**: Update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/create-architecture — <verdict>`, Next step = the first ADR in "Run These ADRs Next" below (a concrete `/architecture-decision "[Title]"`), Blocked on / Files in progress / Open questions; leave the `Flow` line and any `/studio` block alone. Put the rest of the summary in the Notes line: artifact written, CTO/PE sign-off verdicts, any blockers, required ADRs remaining, threat-model candidates. Still updated when the run ended early (`BLOCKED` / `NOT ASSESSED`) or the user declined the write: record the blocker or that nothing was written.

**Step 2 — Output the handoff** using exactly this template (no freeform prose, no rephrasing of section titles):

---

## Architecture Complete

`docs/architecture/architecture.md` v[N] — [CTO-ARCHITECTURE: APPROVE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after REJECT / NOT ASSESSED / skipped — [mode] mode]. [One sentence on what the architecture covers.]

---

## Run These ADRs Next

**1. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence: what it defines and what it unblocks.]

**2. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

**3. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

**Then:** `/architecture-review`, and `/create-control-manifest` once it passes and those ADRs are Accepted — it turns them into the layer rules manifest.

List top 3 from Phase 7 in priority order, Foundation and critical first. If fewer than 3 remain, list only what's outstanding.

---

## Gate-Check Readiness

> **Required before `/gate-check pre-production`:**
> - [ ] Accept ADRs: [list Proposed ADR IDs that must be Accepted]
> - [ ] Write ADRs: [list ADR IDs that must still be written]
> - [ ] Run `/architecture-review` — writes the review report and the traceability index (`docs/architecture/requirements-traceability.md`) the gate reads
> - [ ] Run `/threat-model` for: [sensitive features listed in the document, or "none flagged"]
> - [ ] Run `/test-setup` — scaffolds the per-layer test frameworks, Testcontainers and CI
> - [ ] Create `docs/architecture/perf-budgets.md` if missing (`performance-engineer`)
>
> Run `/gate-check pre-production` when all boxes are checked.

If nothing is blocking, write instead:
> No blockers — run `/gate-check pre-production` now.

---

## Open Questions to Watch

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-XX | [short description] | High / Medium / Low | [ADR or context that resolves it] |

Omit this section entirely if there are no open QQs.

---

(End of handoff. Do not add trailing commentary after the closing rule.)

---
