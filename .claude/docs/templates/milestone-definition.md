# Milestone: [Name]

## Overview

- **Target Date**: [Date]
- **Type**: [Prototype | Vertical Slice | Private Beta | Public Beta | General Availability (GA) | Post-Launch]
- **Duration**: [N weeks]
- **Number of Sprints**: [N]
- **Audience**: [internal | design partners | paying customers | self-hosted early access]

## Milestone Goal

[2-3 sentences describing what this milestone achieves and why it matters. What
can we demonstrate or evaluate at the end of it, and who will use it?]

## Success Criteria

[Specific, measurable. The milestone is complete ONLY when all are met.]

- [ ] [Criterion 1 — specific and testable]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] All S1 and S2 bugs resolved
- [ ] All eight DoD gates met or waived in writing on every story shipped
- [ ] Performance within `perf-budgets.md` on the production-like environment
- [ ] Security: no open High/Critical findings; dependency scan clean
- [ ] Deployed build stable for [X] consecutive days

## Feature List

### Must Ship (Milestone Fails Without These)

| Feature | Spec | Owner | Sprint Target | Status |
|---------|------|-------|--------------|--------|

### Should Ship (Planned but Cuttable)

| Feature | Spec | Owner | Sprint Target | Cut Impact | Status |
|---------|------|-------|--------------|-----------|--------|

### Stretch Goals (Only if Ahead of Schedule)

| Feature | Spec | Owner | Value Add |
|---------|------|-------|----------|

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Availability SLO (critical journeys) | >= [99.x]% over [N] days | SLO dashboard |
| Error rate | < [X]% of requests | RED metrics |
| API latency | within `perf-budgets.md` (p95) | Load test / production metrics |
| Web vitals | LCP/INP/CLS within budget | Lighthouse CI + RUM |
| Mobile crash-free sessions | >= [X]% | Crash reporting |
| Critical bugs | 0 open S1 | Bug tracker |
| High-severity bugs | < [X] open S2 | Bug tracker |
| Security | 0 open High/Critical; cross-tenant tests green | `/security-audit`, CI |
| Test pass rate | 100% on main; coverage > [X]% on domain | CI report |
| Accessibility | meets WCAG target in `accessibility-requirements.md` | `/ux-review` + audit evidence |
| Backups & restore | last restore drill < [N] days old | Runbook log |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| [Payment provider account / sandbox → live] | | | |
| [Play Console / App Store review] | | | |
| [`saas-core` module release] | | | |
| [Legal: ToS, privacy policy, DPA] | | | |

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| [Week 2] | Early progress check | producer, product-director |
| [Midpoint] | Mid-milestone review | Full team |
| [Week N-1] | Pre-milestone review (`/milestone-review`) | Full team |
| [Target Date] | Milestone go/no-go | Full team |
