# /architecture-review — Phase 7: Output the Review Report

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Output the Review Report

```
## Architecture Review Report
Date: [date]
Stack: [layers + pinned versions]
Distribution: [hosted / self-hosted / hybrid]
Specs Reviewed: [N]
ADRs Reviewed: [M]

[output of: Bash: bash .claude/scripts/review-receipts.sh hash docs/architecture/adr-*.md design/specs/*.md
 — one Reviewed-Content-Hash line per file reviewed; Phase 1a's freshness
 check reads these on the next run to skip or scope an unchanged re-review]

---

### Traceability Summary
Total requirements: [N]
✅ Covered: [X]
🟡 Covered (Proposed): [P]
⚠️ Partial: [Y]
❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
For each gap:
  ❌ TR-[id]: [spec] → [context] → [requirement]
     Suggested ADR: "/architecture-decision [suggested title]"
     Domain: [Identity/Tenancy/Billing/Data/API/Messaging/Caching/...]
     Stack Risk: [LOW/MEDIUM/HIGH/NOT SOURCEABLE]
     Critical ADR: [yes/no]

### Threat-Model Coverage
[Sensitive requirements and their threat-model status from Phase 3 — gaps name /threat-model <feature>]

### Cross-ADR Conflicts
[List all conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted implementation order from Phase 4 — dependency ordering section]
[Unresolved dependencies and cycles if any]

### Spec Revision Flags
[Spec assumptions that conflict with verified stack behaviour or licence rules — from Phase 5b]
[Or: "None — all spec assumptions consistent with verified stack behaviour"]

### Stack and Licence Issues
[Deprecated APIs, stale pins, post-cutoff conflicts, NOT SOURCEABLE layers, licence conflicts with customer bundles — from Phase 5]

### Architecture Document Coverage
[List missing contexts and orphaned architecture from Phase 6, or the named NOT ASSESSED line item]

### Checks Not Run
[Every phase or check that did not run, by name and reason: stack lead consultation skipped, licence check not applicable, deprecated-API check not assessed for <layer>, Phase 6 not assessed. "None" only if every check ran.]

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: All requirements covered by **Accepted** ADRs, no conflicts, stack consistent, no licence conflict, every sensitive requirement has a threat model
NOT ASSESSED: The review could not be performed over its stated scope — name why
CONCERNS: Some gaps, partial coverage, coverage resting on `Proposed` ADRs,
      deprecated-API references, stale pins or missing threat models on non-Foundation
      requirements, but no blocking conflicts
FAIL: Critical gaps (Foundation/Core layer requirements uncovered), blocking
      cross-ADR conflicts, a licence conflict with the customer bundle, a Foundation
      ADR resting on an API its stack reference lists as removed, or a sensitive
      Foundation requirement (auth, billing, licensing, tenancy) with no threat model

**`NOT ASSESSED` ranks above PASS and below CONCERNS and FAIL.** Emit it when:

- **No ADRs exist, or none could be read.** Zero requirements traced is not full
  coverage — it is an untraced architecture, and a matrix of `❌ Gap` rows at
  least says so while an empty matrix says nothing.
- **The requirement source is missing** — no `tr-registry.yaml` and no spec
  requirements to trace *from*. A review with no left-hand column cannot report
  coverage; it can only report that it had nothing to compare.
- **An ADR is unreadable or has no `## Status`**, so its rows are `❓` and their
  coverage is unknown rather than absent.
- **Phase 6 could not run** — no `docs/architecture/architecture.md`. It must
  appear as a named `NOT ASSESSED` **line item** in the report rather than as
  absent findings. ADR traceability can still be complete, so a CONCERNS or FAIL
  finding elsewhere still stands; but in `full` mode, whose scope includes
  Phase 6, the verdict cannot be PASS — a review that could not look at part of
  its scope has not shown that part is sound, so it is NOT ASSESSED.
- **No stack is configured, or a layer an ADR names has no stack reference**
  (`full` and `stack` modes) — Phase 5 has nothing pinned to audit those ADRs
  against, and the lead consultation was skipped. Record the
  `Stack validation: NOT ASSESSED` / `NOT SOURCEABLE` line item; like Phase 6
  above, it keeps the verdict from PASS.
- **`deprecated-apis.md` for a layer in use could not be read**, or
  `distribution.model` is unset so the licence check cannot say whether it applies.

Do not resolve any of these to PASS on the grounds that no gap was *found*. No
gap was looked for.

### Blocking Issues (must resolve before PASS)
[List items that must be resolved — FAIL verdict only]

### Required ADRs
[Prioritised list of ADRs to create, most foundational first, critical ones marked]
```

---
