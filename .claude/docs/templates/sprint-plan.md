# Sprint [N] — [Start Date] to [End Date]

## Sprint Goal

[One sentence: what does this sprint achieve toward the current milestone?]

## Milestone Context

- **Current Milestone**: [Name]
- **Milestone Deadline**: [Date]
- **Sprints Remaining**: [N]

## Capacity

- **Total days**: [X]
- **Buffer (20%)**: [Y days reserved for unplanned work, incident response and hotfixes]
- **Available**: [Z days]
- **On-call / support load this sprint**: [days]

## Tasks

<!-- Each task is a story: ID, story type (Logic / Integration / Contract /
     Security / Performance / UI / Config) and the stack lead who owns it. -->

### Must Have (Critical Path)

| ID | Task | Story Type | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-----------|-------------|-----------|-------------|-------------------|--------|
| S[N]-001 | | | | | None | | Not Started |
| S[N]-002 | | | | | S[N]-001 | | Not Started |

### Should Have

| ID | Task | Story Type | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-----------|-------------|-----------|-------------|-------------------|--------|
| S[N]-010 | | | | | | | Not Started |

### Nice to Have (Cut First)

| ID | Task | Story Type | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-----------|-------------|-----------|-------------|-------------------|--------|
| S[N]-020 | | | | | | | Not Started |

## Carryover from Sprint [N-1]

| Original ID | Task | Reason for Carryover | New Estimate | Priority Change |
|------------|------|---------------------|-------------|----------------|

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| [Provider sandbox access / API keys] | | | |
| [`saas-core` module release] | | | |
| [Store review / legal sign-off] | | | |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria, including negative and cross-tenant cases
- [ ] Every story has the eight DoD gates met or waived in writing (`/story-done`)
- [ ] Research note exists for every new feature/integration (`docs/research/<feature>.md`)
- [ ] QA plan exists (`production/qa/qa-plan-[sprint-slug]-[date].md`, from `/qa-plan sprint`)
- [ ] All Logic/Integration/Contract/Security stories have passing tests
- [ ] Performance stories: load-test result vs budget saved in `production/qa/evidence/`
- [ ] UI stories: retained screenshots (desktop + mobile, Arabic RTL + English) and `/impeccable audit` result
- [ ] Run-and-observe evidence retained for every user-visible or callable change
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Specs, contracts and ADRs updated for any deviations
- [ ] Code reviewed and merged; dependency and secrets scans clean
