# /postmortem - Phases 3-5: Gaps, Factors, Impact, Actions

## 1. Briefs for Phase 3 (fill only the `{...}` slots)

### `debugger` (only when confidence is LIKELY or UNKNOWN)

```text
Extend the diagnosis of a resolved incident for /postmortem. Read-only on
production; reproduce only on a local/staging stack. No code, config or data
changes.
Read first: .claude/agents/debugger.md "Senior Bar", the incident record {path},
the existing diagnosis {path | none}, the runbook {path | none}.
Write only to: {production/incidents/incident-[date]-[slug]-diagnosis-2.md} (one new file).
Open question: {what is LIKELY or UNKNOWN}
Evidence available: {commits, traces, logs, exports - links}
Deliver the debugger diagnosis-record format: ranked hypotheses with the check
that confirms and kills each and the outcome; root cause with confidence
(PROVEN | LIKELY | UNKNOWN); the regression test that would have caught it, with its
failing output on the unfixed commit if reproducible; siblings of the faulty
pattern; what you did not examine. No secrets, tokens or PII.
Return (text, under 150 words): the path; the confidence; blockers. A reply without
the file is a failed phase.
```

### `observability-engineer` (detection analysis)

```text
Analyse detection for a resolved incident for /postmortem. Read-only: do not edit
alert rules, dashboards or instrumentation; recommendations are actions for the
postmortem, not changes.
Read first: .claude/docs/observability-standard.md, docs/architecture/slos.md
{path | absent}, the incident record {path}, the runbook {path | none}.
Write only to: {production/incidents/incident-[date]-[slug]-detection.md} (one new file).
Question: from the signals that existed (traces, RED/USE metrics, structured logs
with trace_id, health endpoints, alerts), how was the failure observable, how soon,
and by what? Compare to what the observability standard requires: would an SLO
burn-rate alert have fired and when (state the rule and numbers from slos.md, or
write NOT SOURCEABLE); which signals were missing; was there a runbook link on the
alert that fired; was any telemetry misleading or high-cardinality; was PII logged.
Time to detect from EVIDENCED timestamps only: {list} - say NOT KNOWN where not
evidenced.
Return (text, under 150 words): the path; time to detect (or NOT KNOWN); the missing
signals; blockers. A reply without the file is a failed phase.
```

## 2. Contributing factors (by the safeguard that failed)

For each factor write: **safeguard that should have prevented or detected it**,
**why it did not**, **evidence** (cite), and the **layer**. Layers (use only those
the evidence supports; do not pad):

| Layer | Question |
|---|---|
| Requirements / spec | was the case missing from the spec or acceptance criteria? |
| Design / architecture | did the design allow the failure (no degraded mode, shared fate, no timeout)? |
| Review | was it visible in review, and did a rule or checklist exist? |
| Tests | which test would have caught it; why did none exist or fail to run (DoD gate 5/6, `testing-standards.md`)? |
| Rollout | migration, flag, canary, staged rollout, rollback readiness (`migrations.md`, `deploy.md`) |
| Detection | alert, SLO, health check, dashboard, or none |
| Response | runbook, on-call routing, escalation, access, tooling, communication |
| Mitigation tooling | was a fast, safe mitigation available (rollback, flag, scaling)? |
| Dependency | provider, library, platform, customer environment (self-hosted) |

Rules: **no factor is a person or an act of a person** ("an engineer pushed" is
not a cause; "the deploy had no automated check for X and review has no
checklist item for it" is). Prefer the systemic cause over the proximate one: ask
"why" until the answer is a missing or weak safeguard, stopping where evidence
stops (record `NOT KNOWN` rather than guessing the next why). Distinguish the
**trigger** (what set it off) from **causes** (what let it matter) and from
**aggravators** (what made it longer or worse).

**Where we got lucky** (template's Lessons Learned section): factors that limited
the impact by chance rather than design - a hidden risk until they are made
design.

## 3. What went well

Record with evidence, in the template's "What Went Well" structure (What / Why it
worked / How to repeat): detection by SLO alert, a runbook that was right, a
rollback that worked, fast communication, a safeguard that held. A postmortem
that records only failures teaches the wrong lesson.

## 4. Impact and SLO / error budget

From `docs/architecture/slos.md` (journey IDs, SLIs, targets, windows, budget
policy) and SLI readings the user supplies (dashboard exports, queries):

1. **Customer impact** in numbers with a source each: tenants affected (count; named
   enterprise tenants by internal ID), requests failed or users affected, duration
   of impact (EVIDENCED start and end), editions and versions, data impact
   (`none | delayed | lost | exposed`, with how it was established), revenue impact
   as an estimate with its basis or `NOT KNOWN`.
2. **Error budget consumed** for each breached SLO: bad events or bad minutes during
   the incident divided by the budget for that SLO's window (minutes or events, as
   `slos.md` defines it). Show the arithmetic and the two inputs with sources. If an
   input is missing: `NOT KNOWN - missing [input]`, and the budget row is `NOT
   ASSESSED`. Never estimate the SLI reading.
3. **Policy triggered**: quote the project's error-budget policy from `slos.md`
   verbatim (one short line) and state whether its threshold was crossed (freeze
   risky releases; reliability work first; exception needs `cto`). If `slos.md` is
   absent: `NOT ASSESSED - no SLOs defined` and an action to create them
   (`/observability-plan`).
4. **Customer-facing remedies** (credits, SLA) are decisions of
   `pricing-billing-designer` and `product-director`; record their decision, do not
   propose amounts.

## 5. Runbook updates

Compare the runbook that was used (or its absence) to what actually worked:

- missing symptom/alert mapping; a diagnosis step that did not discriminate; a
  mitigation that was wrong, unsafe or not possible; an escalation contact or
  command out of date; no rollback section; a DESTRUCTIVE step not marked.
- For each gap, write the **exact step** to add or fix. With approval (Phase 7),
  edit `docs/runbooks/<name>.md` (new runbooks from
  `.claude/docs/templates/runbook.md`). **Do not bump `Last verified`**: that date
  records an executed drill, not an edit; note "updated after [incident], not yet
  drilled" and schedule the drill as an action.
- No runbook existed: create the action "write runbook before the alert is
  (re)enabled"; an alert without a runbook is not merged.

## 6. Actions: owned, dated, tracked

Each action is a row:

| # | Action | Type | Owner (role; person if the user names one) | Due | Story | Closes factor |
|---|---|---|---|---|---|---|

- **Type** is `prevent` (stop it happening), `detect` (see it sooner) or `mitigate`
  (shrink the impact). Aim for the strongest control, in this order: remove the
  hazard, guard it automatically (test, lint, migration-lint, alert), then process
  or documentation. "Be more careful" and "add a review step" alone are not
  actions.
- Each action is **specific and verifiable** ("add a contract test for ...; CI
  fails when ...", "add the burn-rate alert for J3 with runbook ..."), small enough
  to be one story, and has an acceptance check.
- **Owner and due date are asked** (`AskUserQuestion` per batch of actions); the
  skill proposes the owning role from the roster (`go-lead`, `platform-lead`,
  `sre-lead`, `observability-engineer`, `qa-lead` ...) and never writes a named
  person or a date the user did not give. A row with no owner or no date is a gap and
  is listed as one.
- **Story**: hand the rows to `/create-stories`; when story IDs exist write them
  into the Story column. Until then the cell says `story pending`, which makes the
  verdict at best `COMPLETE WITH GAPS`.
- **Coverage**: every contributing factor maps to at least one action, or to an
  explicit **acceptance** recorded by the user with owner and expiry date (the
  skill never accepts risk). A factor with neither is a gap.
- Actions that need a decision before work (cost, trade-off) go to `cto` or
  `product-director` as a question with an owner; they are not silently dropped.
- Open actions are reviewed at the next reliability review (`sre-lead`); say when
  that is if the user knows.
