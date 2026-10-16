# /adopt — Phase 3: Classify and Prioritise Gaps

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Classify and Prioritise Gaps

Organise every gap found across all audits into four severity tiers:

**BLOCKING** — Will cause studio skills to silently produce wrong results *right now*.
Examples: ADR missing Status field, domain-map status values with parentheticals,
stack not configured when ADRs or code exist, a `production/review-mode.txt`
that pins review depth over `modes.rigor` unnoticed.

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing Stack Compatibility, specs missing Acceptance Criteria
(stories can't be generated from them), `tr-registry.yaml` missing, a configured
layer with no stack reference, a sensitive feature (auth, billing, uploads, PII)
built with no threat model.

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: specs missing Non-Functional Requirements or Edge Cases, stories
missing TR-IDs or a story type, `sprint-status.yaml` missing, built features with
no research note, `perf-budgets.md` missing.

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: stories missing Manifest Version stamps, specs missing optional sections.

Count totals per tier. If zero BLOCKING and zero HIGH gaps: report that the project
is studio-compatible and only advisory improvements remain.

A check that did not run (an unresolved code root, a script that was missing)
is listed under its own **NOT ASSESSED** heading, with the reason. It is not a
gap and it is not compliance, and it never lowers a tier count.

---
