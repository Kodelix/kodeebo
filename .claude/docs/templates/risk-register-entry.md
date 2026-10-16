# Risk: [Short Title]

## Identification

- **ID**: RISK-[NNNN]
- **Identified By**: [Agent or person]
- **Date Identified**: [Date]
- **Category**: [Technical | Product | Security | Privacy/Legal | Schedule | Resource | External provider | Operational | Quality]

## Assessment

- **Probability**: [Very Low | Low | Medium | High | Very High]
- **Impact**: [Minimal | Minor | Moderate | Major | Critical]
- **Risk Score**: [Probability x Impact = Low / Medium / High / Critical]

## Description

[Detailed description of the risk. What could go wrong? Under what conditions?]

## Trigger Conditions

[What observable conditions (metric, alert, provider notice, audit finding) would indicate this risk is materialising?]

- [Condition 1]
- [Condition 2]

## Impact Analysis

### If This Risk Materialises

- **Schedule Impact**: [How many days/weeks of delay]
- **Quality Impact**: [What quality degradation]
- **Scope Impact**: [What features affected]
- **Customer / Revenue Impact**: [Tenants affected, churn, refunds, SLA credits]
- **Security / Privacy Impact**: [Data exposure, regulatory notification]
- **Cost Impact**: [Resource cost of dealing with it]

### Affected Features / Contexts

- [Feature or bounded context 1]
- [Feature or bounded context 2]

## Mitigation Strategy

### Prevention (reduce probability)

- [Action to prevent this risk from occurring]
- [Owner and deadline]

### Contingency (reduce impact if it occurs)

- [Action to take if this risk materialises; runbook link if one exists]
- [Owner responsible for contingency execution]

## Acceptance

<!-- A residual risk is accepted by a named person, never implicitly. -->

- **Accepted by**: [name/role, or "Not accepted — must mitigate"]
- **Date / review-by**: [date]
- **Linked threat model / ADR**: [path]

## Current Status

- **Status**: [Open | Mitigating | Occurred | Closed]
- **Last Reviewed**: [Date]
- **Trend**: [Increasing | Stable | Decreasing]
- **Notes**: [Any updates]
