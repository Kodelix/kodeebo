# Hotfix record template

Written to `production/hotfixes/hotfix-[date]-[short-name].md`. The record is
the audit trail: every decision, approval, timestamp and verification is added
to it as it happens, not reconstructed afterwards. Times are UTC.

```markdown
## Hotfix: [Short Description]
Date: [Date]
Severity: [S1/S2]
Reporter: [Who found it / how detected: SLO alert | customer report | internal | provider notice]
Status: IN PROGRESS
Security-related: [No | Yes — embargo applies: handle on a private branch, no public wording before fix is available to all editions]
Data exposure: [No | Suspected | Confirmed] (Suspected/Confirmed -> also complete the Breach Notification section of incident-response.md now)

### Problem
[What is broken, in customer terms]

### Blast radius
- Editions affected: [hosted | self-hosted versions X.Y.Z–… | Android build N | iOS build N | web]
- Tenants affected: [all | plan | named tenants | unknown]
- Journeys / SLOs affected: [login, core action, billing, licence activation, ...]

### Mitigation (taken or declined)
[Rollback of the last deploy | feature flag/kill switch off | rate-limit/WAF rule | none — and why a code fix is the right tool]

### Root Cause
[Filled during investigation — proven, with the trace/log/commit that shows it]

### Fix
[Minimal change: files, behaviour, and what it deliberately leaves alone]

### Regression test
[Test name and location. Written first; failed before the fix: yes/no (evidence); passes after: yes/no]

### Testing
[Targeted suites run, with the exact commands taken from the product's scripts/CI. Or `Tests: NOT RUN — [reason]`]

### Approvals
- [ ] Fix reviewed by principal-engineer (and the stack lead for the layer)
- [ ] Security review by appsec-engineer (required for any security fix; security-lead for cross-tenant, credential, billing or licence issues)
- [ ] Regression test passed (qa-tester)
- [ ] QA scope decided (qa-lead): [smoke | targeted team-qa | full]
- [ ] Deploy plan reviewed (platform-lead; sre-lead for S1)
- [ ] Release approved (producer)
- [ ] Customer communication reviewed (customer-success)

### Rollback Plan
- Hosted: [previous image digests / tag, how to redeploy, migration expand-only and old-app compatible (forward-only in production)]
- Self-hosted: [rollback supported? backup/restore step; what customers do if the patch fails]
- Mobile: [staged-rollout halt; previous build stays live; server-side mitigation]

### Release plan (per edition)
| Edition | Version/tag | Artifact | Deployed/published | Verified by | Time (UTC) |
| ---- | ---- | ---- | ---- | ---- | ---- |

### Backport
| Branch/tag | Contains fix? | Evidence (commit / `git branch --contains`) |
| ---- | ---- | ---- |

### Audit log
| Time (UTC) | Who | Decision / action |
| ---- | ---- | ---- |
```
