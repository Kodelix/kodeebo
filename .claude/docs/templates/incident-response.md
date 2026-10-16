# Incident Response: [Incident Title]

**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low]
**Status**: [Active / Mitigated / Resolved / Post-Mortem Complete]
**Detected**: [Date Time UTC]
**Resolved**: [Date Time UTC or ONGOING]
**Duration**: [Total time from detection to resolution]
**Incident Commander**: [Name/Role]
**Detected via**: [SLO burn-rate alert | cause alert | customer report | internal | provider notice]
**Data exposure?**: [No | Suspected | Confirmed] — if Suspected/Confirmed, start the Breach Notification section now

<!-- Severity guide: S1 = outage or data exposure/cross-tenant leak, billing or
     licensing broken for most customers. S2 = major journey degraded or one
     tenant segment down. S3 = minor degradation, workaround exists. S4 = cosmetic. -->

---

## Impact Summary

[2-3 sentences describing what customers experienced. Write from the customer
perspective, not the technical one.]

- **Tenants affected**: [count or percentage; named enterprise tenants]
- **Deployment affected**: [Hosted | Self-hosted version(s) | Both]
- **Surfaces affected**: [API / Web / Android / iOS / webhooks / jobs]
- **Journeys / SLOs breached**: [login, core action, payment, licence activation — with error budget consumed]
- **Data impact**: [none | delayed | lost | exposed — which records, which tenants]
- **Revenue impact**: [failed payments, refunds, churn risk — estimate]

---

## Timeline

| Time (UTC) | Event | Action Taken |
| ---- | ---- | ---- |
| [HH:MM] | Incident detected via [alert/report] | Incident commander assigned |
| [HH:MM] | Root cause identified | [Brief description] |
| [HH:MM] | Mitigation deployed | [What was done: rollback, flag off, scale, failover] |
| [HH:MM] | Service restored / fix confirmed | Monitoring for recurrence |
| [HH:MM] | All-clear declared | Post-mortem scheduled |

---

## Root Cause

### What Happened
[Technical description of the chain of events. Link the trace, dashboard and
commit/deploy that introduced it.]

### Why It Happened
[Systemic cause — why did tests, review, alerts or safeguards fail to prevent
this? More important than the technical cause.]

### Contributing Factors
- [e.g. "No load test for the new list endpoint"]
- [e.g. "Alert threshold too high / no runbook"]
- [e.g. "Migration locked a hot table"]

---

## Mitigation and Resolution

### Immediate Actions (during incident)
1. [Action taken to stop the bleeding]
2. [Action taken to restore service]
3. [Action taken to verify resolution — smoke check, SLI back in range]

### Follow-Up Actions (after resolution)
1. [Permanent fix if the immediate action was a workaround]
2. [Additional tests, monitoring or runbook added]
3. [Process changes to prevent recurrence]

---

## Customer Communication

### Initial Acknowledgment
*Sent: [Time] via [status page / email / in-app banner]*
> [Exact text of the first public message]

### Status Updates
*Sent: [Time] via [channel]*
> [Text of each subsequent update]

### Resolution Notice
*Sent: [Time] via [channel]*
> [Text announcing the fix and any remedy]

### Remedy (if applicable)
- **What**: [SLA credit, extended trial, refund, free month]
- **Who**: [all tenants / affected tenants only / per contract]
- **When**: [delivery date and method]
- **Rationale**: [why this is appropriate for the impact; SLA clause if any]

---

## Breach Notification (complete only if data exposure is Suspected/Confirmed)

- **What data / whose**: [categories, tenants, record counts]
- **Contained at**: [time]
- **Regulator notification**: [PDPL / GDPR — required? deadline, owner, sent at]
- **Customer notification**: [who, when, by whom]
- **Evidence preserved**: [logs, snapshots, audit log export — location]

---

## Prevention

### What We Are Changing

| Action Item | Owner | Deadline | Status |
| ---- | ---- | ---- | ---- |
| [Specific preventive measure] | [Role] | [Date] | [TODO/Done] |
| [Add alert / dashboard for X] | [Role] | [Date] | [TODO/Done] |
| [Add test coverage for Y] | [Role] | [Date] | [TODO/Done] |
| [Write/update runbook for Z] | [Role] | [Date] | [TODO/Done] |

### Process Improvements
- [Process, monitoring or testing improvement]

---

## Lessons Learned

### What Went Well
- [e.g. "Detection was fast thanks to the burn-rate alert"]

### What Went Poorly
- [e.g. "Took 20 minutes to find the right on-call person"]

### Where We Got Lucky
- [Factors that reduced impact by chance rather than design — hidden risks]

---

## Sign-Offs

- [ ] cto — Root cause accurate, prevention plan sufficient
- [ ] sre-lead — Detection, alerting and runbook gaps addressed
- [ ] security-lead — Required when data exposure is Suspected/Confirmed
- [ ] qa-lead — Test coverage gaps addressed
- [ ] producer — Timeline and communication reviewed
- [ ] customer-success — Customer communication reviewed

---

*Filed in `production/incidents/` and linked from the release notes for the fix
version. Blameless post-mortem: `.claude/docs/templates/post-mortem.md`.*
