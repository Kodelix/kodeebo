# Project Stage Analysis Report

**Generated**: [DATE]
**Stage**: [Discovery | Product Design | Architecture | Pre-Production | Production | Hardening | Release | Live]
**Stage Confidence**: [PASS / CONCERNS / NOT ASSESSED / FAIL — reason]
**Workflow tier**: [minimal | standard | full] (`modes.workflow`; per-feature overrides noted)
**Analysis Scope**: [Full project | Specific role: engineer/designer/producer]

---

## Executive Summary

[1-2 paragraph overview of project state, primary gaps, and recommended priority]

**Current Focus**: [What the project is actively working on]
**Blocking Issues**: [Critical gaps preventing progress]
**Estimated Time to Next Stage**: [If applicable]

---

## Completeness Overview

### Product Design Documentation
- **Status**: [X%] complete at the effective tier
- **Files Found**: [N] documents in `design/`
  - Product brief: [Exists | Missing] (`design/product-brief.md`)
  - Domain map: [Exists | Missing] (`design/specs/domain-map.md`)
  - Feature specs: [N] files in `design/specs/` — [N] with all required sections for their tier
  - UX specs: [N] files in `design/ux/`
- **Key Gaps**:
  - [ ] [Missing doc 1 + why it matters]
  - [ ] [Missing doc 2 + why it matters]

### Source Code
- **Status**: [X%] complete
- **Code roots found** (from `resolve_code_root`; empty result = check did not run): `backend/` [N files], `web/` [N], `site/` [N], `mobile/` [N], `contracts/` [N]
- **Bounded contexts identified**:
  - [OK] [Context 1] (`backend/internal/<ctx>/`) — [brief status]
  - [OK] [Context 2] — [brief status]
  - [Partial] [Context 3] — [issue or incomplete]
- **Key Gaps**:
  - [ ] [Missing context/feature 1 + impact]

### Architecture Documentation
- **Status**: [X%] complete
- **ADRs Found**: [N] decisions in `docs/architecture/` ([N] critical required at this tier)
- **Coverage**:
  - [OK] [Decision area 1] — documented
  - [Partial] [Decision area 2] — undocumented but implemented
  - [Gap] [Decision area 3] — neither documented nor decided
- **Threat models**: [N] in `docs/architecture/threat-models/` vs [N] sensitive features
- **Perf budgets / SLOs**: [Exist | Missing]
- **Key Gaps**:
  - [ ] [Missing ADR / threat model + why it is needed]

### Research Notes
- **Notes**: [N] in `docs/research/`; features built without a note: [list]
- **Stale notes** (older than the pinned version they cite): [list]

### Production Management
- **Status**: [X%] complete
- **Found**: sprint plans [N], milestones [N], epics [N], stories [N] (`production/`)
- **Key Gaps**:
  - [ ] [Missing production artifact + impact]

### Testing & Evidence
- **Status**: [X%] of closed stories have evidence for their type
- **Test locations scanned**: [per code root]
- **Coverage by bounded context**:
  - [Context 1]: [X%] (estimated) — Logic / Integration / Contract / Security
  - [Context 2]: [X%]
- **Evidence in `production/qa/evidence/`**: [N] story folders; stories closed without run-and-observe: [list]
- **Key Gaps**:
  - [ ] [Missing test area + risk — e.g. no cross-tenant negative tests on X]

### Operations
- **Deploy**: hosted [Exists | Missing], self-hosted bundle [Exists | Missing | N/A]
- **Observability**: spans/RED/logs on [N of N] endpoints; SLOs [Defined | Missing]; runbooks [N]
- **Backups / restore drill**: [Verified | Unverified]

### Prototypes
- **Active Prototypes**: [N] in `prototypes/`
  - [OK] [Prototype 1] — documented with REPORT.md
  - [Partial] [Prototype 2] — no README, unclear status
- **Key Gaps**:
  - [ ] [Undocumented prototype + why it matters]

---

## Stage Classification Rationale

**Why [Stage]?**

[Explain why the project is classified at this stage based on indicators found]

**Indicators for this stage**:
- [Indicator 1]
- [Indicator 2]

**Next stage requirements**:
- [ ] [Requirement 1 to reach next stage]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

---

## Gaps Identified (with Clarifying Questions)

### Critical Gaps (block progress)

1. **[Gap Name]**
   - **Impact**: [Why this blocks progress]
   - **Question**: [Clarifying question before assuming a solution]
   - **Suggested Action**: [What could be done, pending clarification]

### Important Gaps (affect quality/velocity)

2. **[Gap Name]**
   - **Impact**: [Why this matters]
   - **Question**: [Clarifying question]
   - **Suggested Action**: [Proposed solution]

### Nice-to-Have Gaps (best practices)

3. **[Gap Name]**
   - **Impact**: [Minor but valuable]
   - **Question**: [Clarifying question]
   - **Suggested Action**: [Optional improvement]

---

## Recommended Next Steps

### Immediate Priority (Do First)
1. **[Action 1]** — [Why it is priority 1]
   - Suggested skill: `/[skill-name]` or manual work
   - Estimated effort: [S/M/L]

2. **[Action 2]** — [Why it is priority 2]
   - Suggested skill: `/[skill-name]`
   - Estimated effort: [S/M/L]

### Short-Term (This Sprint/Week)
3. **[Action 3]** — [Why it is important soon]
4. **[Action 4]** — [Why it is important soon]

### Medium-Term (Next Milestone)
5. **[Action 5]** — [Future need]

---

## Role-Specific Recommendations

[If a role filter was used, provide role-specific guidance]

### For [Role]:
- **Focus areas**: [What this role should prioritise]
- **Blockers**: [What is blocking this role's work]
- **Next tasks**:
  1. [Task 1]
  2. [Task 2]

---

## Follow-Up Skills to Run

Based on gaps identified, consider running:

- `/reverse-document <brief | research <context> | spec <feature> | architecture | concept <prototype-dir>>` — [For which gap]
- `/architecture-decision` — [For which gap]
- `/threat-model` — [For which sensitive feature]
- `/sprint-plan` — [If production planning is missing]
- `/milestone-review` — [If approaching a deadline]
- `/onboard [role]` — [If a new contributor is joining]

---

## Appendix: File Counts by Directory

```
design/
  specs/         [N] files
  ux/            [N] files

backend/ web/ site/ mobile/ contracts/   (code roots that exist)
  [per root]     [N] files

docs/
  architecture/  [N] ADRs, [N] threat models
  research/      [N] notes
  runbooks/      [N] runbooks

production/
  sprints/       [N] plans
  milestones/    [N] definitions
  qa/evidence/   [N] story folders

prototypes/      [N] directories
```

---

**End of Report**

*Generated by `/project-stage-detect` skill*
