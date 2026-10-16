# /prototype — Phase 8: Product Director Review

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Product Director Review

**Review mode check:**
- `solo` → skip. Note: "PD-USABILITY skipped — Solo mode."
- `lean` → skip. Note: "PD-USABILITY skipped — Lean mode."
- `full` → spawn `product-director` via `Agent` using gate **PD-USABILITY**
  (`.claude/docs/director-gates/pd-usability.md`) if `design/product-brief.md`
  exists (the principles and core value stand in). If it does not, note:
  "PD-USABILITY skipped — product brief not yet written at concept prototype stage."
  For a **feasibility-only** spike (no users involved), spawn `cto` via gate
  **CTO-FEASIBILITY** (`.claude/docs/director-gates/cto-feasibility.md`) instead,
  passing the measured result and the stack choice, and note the substitution.

Pass: the full REPORT.md content, the original hypothesis, the participant
profile versus the ICP, and the product principles / core value from
`design/product-brief.md`.

The director evaluates the result against the product vision and returns one of the
gate's verdicts — APPROVE, CONCERNS or REJECT (CTO-FEASIBILITY: VIABLE, CONCERNS,
HIGH RISK) — or NOT ASSESSED when it could not judge. Apply it to the recommendation:

- **APPROVE / VIABLE** → the recommendation stands.
- **CONCERNS** → show the concerns alongside the recommendation, then use `AskUserQuestion`: `Revise the recommendation` / `Accept with noted concerns` / `Discuss further`. The user decides; the director does not.
- **REJECT / HIGH RISK** (the core value is not present, or the idea is infeasible as described) → a PROCEED recommendation cannot stand. Use `AskUserQuestion` to ask the user to choose `PIVOT` or `KILL`, and run Phase 9 for that choice. A PIVOT or KILL recommendation stands.
- **NOT ASSESSED** (the director lacked an input — `.claude/docs/director-gates.md`) → not an approval. Name what was missing; supply it and re-run the gate, or record the review as NOT ASSESSED and let the user decide whether the recommendation stands unreviewed.

When the director returned CONCERNS, REJECT or NOT ASSESSED, ask "May I update
`prototypes/[name]/REPORT.md` and its `prototypes/index.md` row?", then record the
director's verdict and reason in REPORT.md, and the final recommendation in both if
it changed.

---
