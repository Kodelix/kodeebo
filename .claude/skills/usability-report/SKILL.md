---
name: usability-report
description: "Structured usability-test report template, or turn raw usability-test notes into findings (severity, frequency, evidence), recommendations and owners."
argument-hint: "[new|analyze path-to-notes] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash "*/.claude/skills/usability-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Usability Report

Turns what was observed in usability sessions (moderated or unmoderated, remote or
in person) into evidence the team can act on: findings with **severity**,
**frequency** and **evidence**, recommendations, and an **owner** for each. It
separates observation from interpretation, and a one-off from a pattern.

## Phase 1: Parse Arguments

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Determine the mode:

- `new` → generate a blank usability report template. This mode ends after
  Phase 2A: a blank template has nothing to route, review or save.
- `analyze [path]` → read raw notes and fill in the template with structured findings
- No argument → ask via `AskUserQuestion`: `[A] New blank template` /
  `[B] Analyze notes — I'll give you the path`

**Participant privacy.** Reports use participant IDs (`P1`, `P2`…), never names,
emails or tenant names. Notes that contain personal data are summarized, not
copied; recordings and raw transcripts stay out of the repository. If the notes
contain personal data, say so in the report's Session Info (`PII in source notes:
yes — not reproduced`).

---

## Phase 2A: New Template Mode

Generate this template and output it to the user:

```markdown
# Usability Report

## Study Info
- **Date(s)**: [Date range]
- **Build / environment**: [Version, commit or staging URL]
- **Method**: [Moderated / unmoderated · remote / in person · think-aloud Y/N]
- **Facilitator / note-taker**: [Names or IDs]
- **Participants**: [N completed of N recruited]
- **Surfaces tested**: [Web desktop / mobile web / Android / iOS / self-hosted admin]
- **Language / direction**: [Arabic RTL / English LTR — per participant]
- **Assistive technology used**: [None / screen reader / zoom / keyboard-only — per participant]
- **PII in source notes**: [Yes — not reproduced / No]

## Hypothesis and Scope
- **Hypothesis**: [What we expected to be true — e.g. "A new admin can invite a teammate without help in under 2 minutes"]
- **Flow / screens tested**: [UX specs under test, e.g. `design/ux/invite-member.md`]
- **Success definition**: [Task success rate, time, error count that would confirm the hypothesis]
- **Journey phase**: [From `design/user-journey.md`]

## Participants
| ID | Role | Plan / edition | Segment vs ICP | Experience with similar tools | Device / locale |
|----|------|---------------|----------------|-------------------------------|-----------------|
| P1 | | | [Matches / Partial / Outside ICP] | | |

## Task Results
| Task | P1 | P2 | P3 | ... | Success | Median time | Errors / wrong turns |
|------|----|----|----|-----|---------|-------------|----------------------|
| [T1: task as given to the participant] | [Done / Assisted / Failed / Abandoned] | | | | [n/N] | | |

## First Impressions (first 5 minutes)
- **Understood what the product / screen is for?** [Yes/No/Partially — n/N]
- **Found the primary action?** [Yes/No/Partially — n/N]
- **Emotional response**: [Confident / Confused / Anxious / Frustrated / Delighted]
- **Notes**: [Observations]

## Findings
Severity: **Blocker** (task cannot be completed / data or money at risk) · **Major** (task completed with significant difficulty or workaround) · **Minor** (friction, recovered quickly) · **Cosmetic** (noticed, no effect on the task).
Frequency: participants affected / total.

| # | Finding (observation, not opinion) | Severity | Frequency | Evidence (participant, task, quote / timestamp) | Class | Screen / spec |
|---|------------------------------------|----------|-----------|--------------------------------------------------|-------|---------------|
| F1 | | | n/N | P2 T3 "…" | [Systematic / One-off] | |

### What worked well
- [Observation — with participants and evidence]

### Confusion points
- [Where users were confused and why — with evidence]

### Moments of delight
- [What surprised or pleased users]

## Accessibility and Localization Observations
- [Keyboard / screen reader / zoom issues; RTL mirroring or mixed-direction issues; text overflow — each with participant and evidence, or "not tested" with the reason]

## Defects Encountered
| # | Description | Severity | Reproducible | Participants |
|---|-------------|----------|--------------|--------------|

## Quantitative Data (if available)
- **Task success rate**: [per task]
- **Time on task**: [median per task]
- **Errors / wrong turns**: [per task]
- **Self-reported ease (SEQ, 1–7) / SUS**: [scores, N]
- **Drop-off point in funnel**: [step, n/N]

## Hypothesis Result
- **Result**: [Confirmed / Partially confirmed / Rejected / Inconclusive — and why]
- **Confidence**: [Low / Medium / High — N, ICP match, method limits]

## Recommendations
| # | Recommendation | Addresses | Priority | Owner | Route |
|---|----------------|-----------|----------|-------|-------|
| R1 | | F1 | P1 / P2 / P3 | [product-manager / ux-designer / design-director / ...] | [skill or artifact] |

## Top 3 Priorities from this study
1. [Most important finding]
2. [Second priority]
3. [Third priority]

## Limitations
- [Sample size, participants outside the ICP, prototype vs production build, tasks not tested, surfaces not covered]
```

In `new` mode, stop here with: Verdict: **COMPLETE** — blank template output; nothing saved.

---

## Phase 2B: Analyze Mode

Read the raw notes at the provided path. If the path cannot be read, or the notes
contain no participant-level observations at all, stop with Verdict:
**NOT ASSESSED — no usable notes** and say which; do not fill the template from
imagination.

Cross-reference with the design documents the study tested: the UX spec(s)
(`design/ux/`), the feature spec(s) (`design/specs/`), the user journey
(`design/user-journey.md`) and the product brief (`design/product-brief.md`) for
the ICP and principles. Fill in the template above with structured findings.

**Rules for the analysis:**

1. **Observation before interpretation.** Each finding states what the participant
   did or said, with evidence (participant ID, task, quote or timestamp). The
   interpretation ("the label is ambiguous") is separate and marked as such.
2. **Frequency is a count, never "some users".** `n/N` participants. If the notes do
   not allow a count, write `not recorded` — do not estimate. A finding seen once
   is listed as One-off; the same failure across **three or more participants**, or
   the same step abandoned, is **Systematic**.
3. **Severity is judged on the task, not on the noise.** Blocker / Major / Minor /
   Cosmetic as defined in the template. Anything touching money, irreversible
   deletion, another tenant's data or security (a participant reveals or shares a
   secret by accident, cannot tell which workspace they are in) is at least Major
   and is routed to `security-lead` as well.
4. **Participants versus the ICP.** Compare each participant with the ICP in the
   product brief. A mismatch is stated and its effect on the findings judged;
   findings from outside-ICP participants are marked as such.
5. **A hypothesis is required.** If the notes state none, write
   `Hypothesis: not stated in the notes` and flag it — the report can still list
   findings but the Hypothesis Result is **Inconclusive** by construction.
6. **A dimension not tested is reported as not tested.** Accessibility,
   Arabic/RTL, mobile surfaces, non-admin roles, plan-limit and error states: if
   the study did not cover one, the Limitations section names it. Silence on RTL
   is not evidence that RTL works.
7. **Defects are not pain points.** An observation that describes a defect — a
   crash, a failed request, a broken layout, a state that plainly breaks rather
   than confuses — goes in the **Defects Encountered** table and is routed as a
   bug in Phase 3. Findings are for how the product feels to use.
8. Flag any observation that **conflicts with design intent** — a UX spec that
   says one thing and a participant who did another, or a principle in the brief
   the flow violates.

---

## Phase 3: Action Routing

Categorize all findings into these buckets, each with an **owner**:

- **UX / interaction changes** (flow, labels, hierarchy, missing states) — owner `ux-designer`; visual and register issues — `design-director` / `ui-designer`. "Run `/ux-design [screen]` to revise the spec, then `/ux-review`."
- **Feature / scope changes** (the job the feature does is wrong, a capability is missing) — owner `product-manager`; anything that changes scope is flagged for `product-director`. "Run `/propagate-spec-change [path]` on the affected spec to find downstream impacts before making changes."
- **Pricing / plan comprehension** (users misread plans, limits, trials, upgrade prompts, invoices) — owner `pricing-billing-designer`. "Run `/pricing-check` once the model changes."
- **Accessibility** — owner `accessibility-specialist`; **Localization / RTL** — owner `localization-lead`.
- **Copy and help content** (labels, error messages, empty states, docs) — owner `ux-designer` for microcopy, `technical-writer` for docs.
- **Onboarding / activation** (drop-off in the first-value path) — owner `growth-lifecycle`, with `product-analytics-engineer` for the funnel events.
- **Defects** — "Use `/bug-report` to formally track these." Security-relevant defects also go to `security-lead`.
- **Polish items** — not blocking, add to the polish backlog in `production/` for the hardening phase.

Present the categorized list with severity and frequency, then the routes. Every
finding has a proposed action and an owner; a finding without one is incomplete.

---

## Phase 3b: Product Director Experience Review

**Review mode check** — apply before spawning PD-USABILITY:
- `solo` → skip. Note: "PD-USABILITY skipped — Solo mode." Proceed to Phase 4 (save the report).
- `lean` → skip (not a PHASE-GATE). Note: "PD-USABILITY skipped — Lean mode." Proceed to Phase 4 (save the report).
- `full` → spawn as normal.

After categorising findings, spawn `product-director` via `Agent` using gate **PD-USABILITY** (`.claude/docs/director-gates/pd-usability.md`).

Pass: the structured report content **inline** (the report is not saved yet), the
product principles and core value (from `design/product-brief.md`), the specific
hypothesis being tested, and the participant profile with the ICP. **If
`design/product-brief.md` does not exist or has no principles section**, say so in
the prompt: *"No principles available — assess against the hypothesis alone."* A
director gate handed silence about principles will invent them.

Present the product director's assessment before saving the report. If CONCERNS or REJECT, add a `## Product Director Assessment` section to the report capturing the verdict and feedback. If APPROVE, note the approval in the report. If NOT ASSESSED (the director lacked an input — `.claude/docs/director-gates.md`), add the same section naming what was missing; it is not an approval.

---

## Phase 4: Save Report

Ask: "May I write this usability report to `production/qa/usability/usability-[date]-[study-slug].md`?"

If yes, write the file, creating the directory if needed. The saved report
contains participant IDs only and no personal data.
If no, write nothing and go to Phase 5 with the verdict `BLOCKED — write declined by user`.

---

## Phase 5: Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/usability-report <study> — <verdict>`, Next step = the first action below (the highest-severity finding), plus Blocked on (a declined write, a PD-USABILITY REJECT) / Files in progress (the saved report) / Open questions; append the Notes line. Still updated for BLOCKED and NOT ASSESSED.

End with exactly one verdict (first match wins):

- Verdict: **BLOCKED — write declined by user** — the Phase 4 write was declined;
  nothing is reported as COMPLETE. (Also **BLOCKED — PD-USABILITY REJECT** when the
  gate rejected the findings and the user has not chosen to proceed anyway.)
- Verdict: **NOT ASSESSED — [reason]** — notes unusable (Phase 2B), or the report
  was produced but PD-USABILITY returned NOT ASSESSED: state `PD-USABILITY: NOT
  ASSESSED — [input]` in the verdict line.
- Verdict: **COMPLETE WITH GAPS** — the report was saved but PD-USABILITY returned
  CONCERNS (or REJECT, with the user choosing to proceed): name the verdict and the
  concerns in the verdict line.
- Verdict: **COMPLETE** — usability report generated and saved, and PD-USABILITY
  returned APPROVE or was skipped for the review mode (named, `skipped — Lean mode`).

- Act on the highest-severity, highest-frequency finding first (Blocker and Systematic before everything else).
- After revising UX specs: re-run `/ux-review` on the updated spec, then retest the changed flow with fresh participants.
- After fixing defects: re-run `/bug-triage` to update priorities.
- After a spec or pricing change: `/propagate-spec-change` and `/pricing-check` as routed above.
