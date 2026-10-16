# /incident - Phases 4, 6, 7: Timeline, Resolve, Hand Off

## 1. Timeline capture (Phase 4)

Every event goes into the record's **Timeline** table as it happens:

| Time (UTC) | Event | Action Taken |

- Time from `date -u +"%Y-%m-%d %H:%M"` when the user says "now", or the time the
  user states for something that already happened (marked `reported by user`).
  Never reconstruct a time from memory of the conversation: ask.
- One row per: detection, declaration, severity change, role assignment,
  mitigation applied (who, what, expected effect), mitigation verified or failed
  (with the SLI reading), diagnosis result (confidence), message sent (channel),
  escalation, provider contact, all-clear.
- Evidence by reference: trace ID, dashboard URL, log query, deploy/commit ID,
  runbook step. No payloads, secrets, tokens, OTPs or personal data; tenants by
  internal ID only.
- Keep **Impact Summary** current: tenants affected (count, `NOT KNOWN` if
  unknown), deployment affected, journeys/SLOs breached, data impact
  (`none | delayed | lost | exposed | NOT KNOWN`), revenue impact (estimate, marked
  as estimate, or `NOT KNOWN`).
- Append with `Edit`; do not rewrite earlier rows. A correction is a new row that
  says what it corrects.
- At each update interval set in Phase 1, ask: "Customer update due at [UTC]. Draft
  it now?"

## 2. Resolve (Phase 6)

An incident is `Resolved` only when all hold, each with evidence in the record:

| Criterion | Evidence |
|---|---|
| The SLI/error rate for the affected journey is back in range | the dashboard/query and the reading (UTC) |
| The affected journey works end to end | `/smoke-check` result, or a named manual run of the journey on the affected edition |
| The monitoring window passed with no recurrence | window length set by the user and `sre-lead` (not defaulted here), start and end UTC |
| Temporary mitigations are listed as open items with an owner and a date | e.g. flag still off, rollback not rolled forward, extra capacity |
| For data impact: scope established, affected tenants listed by ID, repair or restore done or planned | audit-log query / restore record |
| For a security incident: contained, evidence preserved, rotated, notification decisions recorded | the Breach Notification section |

If any criterion is not met, the status stays `Mitigated`. Record **Duration**
(detected -> resolved UTC), set **Resolved**, and write the all-clear message
through the Phase 3 draft path (`resolved`: what happened in customer terms, what is
fixed, what to do if still affected, no cause speculation). Remedy decisions
(credits, SLA) belong to `pricing-billing-designer` and `product-director` and are
recorded only as their decision.

## 3. Hand-off (Phase 7)

1. **Root cause and prevention** in the record: *What Happened*, *Why It
   Happened* (the systemic cause: which test, review, alert or safeguard was
   missing - systems, not people), *Contributing Factors*. Where the cause is not
   proven, write `LIKELY` or `UNKNOWN` as the debugger reported, never `PROVEN`.
2. **Postmortem decision** - asked, recorded, never skipped:
   - SEV1 or SEV2: required, within 5 working days (`sre-lead`).
   - SEV3 or SEV4: the user decides; write `postmortem: yes | no - reason`.
   - An incident that consumed a large share of an error budget may require one by
     `docs/architecture/slos.md`'s error-budget policy: read it and quote the rule.
   `sre-lead` does not close an incident without this decision, and neither does
   this skill.
3. **Sign-offs** in the template (cto, sre-lead, security-lead when data exposure
   was Suspected/Confirmed, qa-lead, producer, customer-success) are listed as
   pending; ticking them is the person's, not the skill's.
4. **Actions captured** as a list (action, owner role, deadline) in the template's
   *Prevention* table; owners and dates are asked, never filled by the skill. Those
   become stories after the postmortem (`/postmortem`, then `/create-stories`).
5. Set Status `Resolved`; on `/postmortem` completion it becomes `Post-Mortem
   Complete`. Update the `active.md` line.
6. Report: severity, duration, impact numbers (or `NOT KNOWN`), mitigation timeline,
   open items, the postmortem decision, and "Not captured": every field left
   `NOT KNOWN` and why.

Use `AskUserQuestion` for the next step: `[A] /postmortem now`, `[B] /hotfix for the
code fix`, `[C] /observability-plan for the missing alert or runbook`, `[D] Stop
here`.
