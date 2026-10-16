# /review-all-specs — Phase 5: Output the Review Report

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Output the Review Report

**In this file:**

- The report template
- `NOT ASSESSED` and where it ranks

```
## Cross-Spec Review Report
Date: [date]
Specs Reviewed: [N] of [M] present
Not read: [each spec that could not be read or is present but empty, by file name — or "none"]
Features Covered: [list]
Inputs not available: [pricing model / registry / tenancy model / core pin / principles — each absent one, or "none"]
Checks not run: [any 2a–2g / 3a–3g check that could not run, with the reason, or "none"]

---

### Consistency Issues

#### Blocking (must resolve before architecture begins)
🔴 [Issue title]
[What specs are involved, what the contradiction is, what needs to change]

#### Warnings (should resolve, but won't block)
⚠️  [Issue title]
[What specs are involved, what the concern is]

---

### Product Issues

#### Blocking
🔴 [Issue title]
[What the problem is, which specs are involved, recommendation]

#### Warnings
⚠️  [Issue title]
[What the concern is, which specs are affected, recommendation]

#### Core extract-candidates (not defects)
ℹ️  [Capability] — specified in [specs]; candidate for `/core-extract`

---

### Cross-Feature Scenario Issues

Scenarios walked: [N]
[List scenario names]

#### Blockers
🔴 [Scenario name] — [Features involved]
[Step where failure occurs, nature of the failure mode, what must be resolved]

#### Warnings
⚠️  [Scenario name] — [Features involved]
[What the unintended outcome is, recommendation]

#### Info
ℹ️  [Scenario name] — [Features involved]
[Minor ordering ambiguity or note]

---

### Specs Flagged for Revision

| Spec | Reason | Type | Priority |
|------|--------|------|----------|
| [feature-a].md | Rule contradiction with [feature-b].md | Consistency | Blocking |
| [feature-b].md | Rule contradiction with [feature-a].md | Consistency | Blocking |
| [feature-c].md | Quota defined twice with different sizes | Consistency | Blocking |
| [feature-d].md | Serves no principle | Product | Warning |

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: No blocking issues and no warnings, and every phase and input was covered.
NOT ASSESSED: One or more review phases or required inputs could not run — named below.
CONCERNS: Warnings present that should be resolved, but nothing blocking.
FAIL: One or more blocking issues must be resolved before architecture begins.

### If NOT ASSESSED — what could not be reviewed, and why:
[Name each phase or check that did not run and the input it needed, and each spec that could not be read or is present but empty, by file name]

### If FAIL — required actions before re-running:
[Specific list of what must change in which spec]
```

**`NOT ASSESSED` — a cross-review is only as wide as what it could read.** Rank:
**above PASS**, **below CONCERNS and FAIL**. This skill's whole value is
comparing features *against each other*, so it is unusually easy for it to look
thorough while covering a fraction of the surface. Emit it when any of:

- **Fewer than two specs were readable.** Contradiction-hunting across one
  document is not a cross-review; a clean result there means only that nothing was
  compared. This is the single most important trigger in this skill.
- **A whole review phase did not run** — consistency, product holism, scenarios.
  A parallel phase that returned nothing has to be distinguished from one that
  returned no findings; if a spawned agent produced no report, that phase is NOT
  ASSESSED, not clean — an agent can return a fluent sentence, write nothing, and
  consume a phase.
- **A check's reference input is absent**, so the check has nothing to compare
  against — and that check alone becomes NOT ASSESSED while the rest proceed:
  no pricing model (3a, 3c, 3g cannot test plans against specs), no product
  principles (3f), no `tenancy.model` (the model half of 2d), no `core.version`
  (the "already in core" half of 3b). Name each one.
- **A spec is present but empty** (headings only, or all placeholders), **or
  could not be read**. Present is not the same as reviewable, and a stub
  contradicts nothing.
- **`spec-structure-check.sh` or `review-scope.sh` could not run**, so section
  presence or the incremental scope was not observed.

Report the covered set explicitly either way: `Specs reviewed: [N] of [M] present`
(`[M]` counts the feature specs present — the Phase 1c set, not `domain-map.md`,
`product-brief.md`, the pricing model or an earlier `spec-cross-review-*.md`),
and the `Not read:` line naming every spec that could not be read or is present but
empty, whatever the verdict — a FAIL found in the specs that were read does not
make the unread ones reviewed.
A cross-review that silently skipped half the features is indistinguishable from
one that found them consistent.

---
