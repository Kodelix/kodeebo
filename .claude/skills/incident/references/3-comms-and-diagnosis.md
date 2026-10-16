# /incident - Phase 3: Customer Communication and Diagnosis

> Phase 3 of `SKILL.md`. The two agents are independent: spawn both in one turn.
> Fill only the `{...}` slots of the briefs. Add nothing else: no view on the
> cause, no pre-rating.

## 1. `customer-success` brief (drafts only)

```text
Draft the next customer message for /incident. You draft; you do not publish.
The user sends it after sre-lead or the incident commander approves the facts.

Write only to: {production/incidents/incident-[date]-[slug]-comms-[n].md}  (one new file)
Phase of the incident: {investigating | identified | monitoring | resolved}
Facts you may use (from the incident record, nothing else):
  severity {SEV}; start {UTC}; affected journeys {list}; affected editions {hosted | self-hosted versions}
  affected scope {all | plan | tenant segment - no tenant names}; what is NOT affected {list | NOT KNOWN}
  workaround {text | none known}; mitigation status {applied/verified | not yet}
  next update at {UTC time set by the incident commander}
Rules (read .claude/agents/customer-success.md "Senior Bar" first):
- phase ladder wording; impact in customer terms; what is affected and not; the
  workaround; the next update time (UTC and the local equivalent for {region})
- no root-cause speculation, no blame, no internal hostnames or vendor names, no
  promised dates, no tenant names, no customer data or other customers' details
- English and Arabic with the same facts; the Arabic is reviewed by a native
  speaker via localization-lead before publication, or the Arabic part says it is
  English-first and the Arabic follows
- self-hosted: say which versions, the supported action, and where the fix will be
  published (update channel); do not announce a fix as available before it is
- for a security-flavoured incident: minimal text approved by security-lead; do not
  describe the weakness
Return (text, under 120 words): the path written; the facts you could not use
because they were NOT KNOWN; what needs approval from whom. A reply without the
file is a failed phase.
```

After the draft is on disk: show it to the user, who edits it. Facts and cadence
are approved by `sre-lead` (spawn on request) or the incident commander. The user
publishes on the status page / e-mail / in-app banner and tells the skill when;
append `message sent [UTC] via [channel]` to the timeline. Paste the final sent
text into the record's Customer Communication section (the template has the
slots: Initial Acknowledgment, Status Updates, Resolution Notice, Remedy).
Refunds, credits and SLA remedies are decided by `pricing-billing-designer` and
`product-director`; the draft only says remedy is under review if the user asks.

## 2. `debugger` brief (read-only diagnosis)

```text
Diagnose an active incident for /incident. Read-only: you do not change code,
config, data or any running system, and you do not run intrusive probes
(profilers, heap dumps, debug builds) on production. Probes on production need
sre-lead approval and a stated rollback; if you need one, say so and stop.

Read first: .claude/agents/debugger.md "Senior Bar" and "Output (diagnosis record)",
.claude/docs/observability-standard.md, the runbook {path | none}, the incident record {path}.

Symptom and impact (from the record): {text}
Started: {UTC}   Recent changes: {deploys/migrations/config/flags/provider status}
Scope known: {tenants, versions, editions | NOT KNOWN}
Evidence already read: {dashboards, trace IDs, log queries - links}
Environment you may use: {local compose stack | staging | production READ ONLY via the
dashboards/queries named above}
Write only to: {production/incidents/incident-[date]-[slug]-diagnosis.md}  (one new file)

Deliver, in the debugger diagnosis-record format: ranked hypotheses with the check
that confirms and the check that kills each; the proven or likely root cause with
its confidence (PROVEN | LIKELY | UNKNOWN) and next probes; blast radius (tenants,
versions, since when) and whether any cross-tenant read or write occurred (if so
say it first, in the first line of your reply); a time-to-mitigate option stated
separately from the fix; the regression test to add; siblings of the faulty
pattern; what you did not examine.
No secrets, tokens, OTPs or customer PII in the file: mask or hash identifiers.
Return (text, under 150 words): the path written; confidence; the mitigation
option; anything blocking. A reply without the file is a failed phase.
```

The diagnosis never holds up mitigation. When it returns, read the file, present
the confidence level plainly (`PROVEN`, `LIKELY`, `UNKNOWN`), and add to the
timeline: `diagnosis [confidence] - [one line]`. A `LIKELY` cause is not written to
customers as fact. If the debugger reports cross-tenant read/write, treat it as
a Phase 1 re-declare with the security hand-off.

If an agent cannot be spawned: the user writes the message from the facts in the
record (the skill offers the phase ladder structure above); the diagnosis moves to
a human with the runbook. Say so and continue.
