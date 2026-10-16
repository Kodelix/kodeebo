# /observability-plan - Mode `runbooks`

> One runbook per alert at `docs/runbooks/<name>.md`, from
> `.claude/docs/templates/runbook.md` (headings unchanged). An alert without a
> runbook is not merged (`observability-standard.md`).

## 1. Which runbooks

- `runbooks <alert>`: the named alert from `docs/architecture/slos.md` or the
  alert rule files.
- `runbooks all`: derive the set from the alerts that exist - every burn-rate
  alert and every cause alert in `slos.md` (and in the rule files under
  `deploy/hosted/`, `deploy/self-hosted/` when they exist). A derived set, not a
  list in this skill: an alert added later is covered because it is read from the
  document. An alert with no runbook file is listed `MISSING`.
- No `slos.md` and no alerts: `NOT ASSESSED - no alerts defined`; run
  `/observability-plan slos` first. Never invent alerts to have something to
  document.

Existing runbooks: read; update rather than duplicate; keep the History section.

## 2. What each runbook must contain

The template's sections, written for someone paged at 3 a.m. who did not build
the system: imperative steps, exact commands, the expected output and a decision
at the end of each branch.

- **Symptoms:** the alert name and threshold, what users see, and the look-alike
  runbooks it is not.
- **Impact and first questions:** who is affected, since when, is data at risk
  (exposure suspected = S1 and `incident-response.md`), is a deploy or migration
  in flight.
- **Dashboards and telemetry:** where to look and what "bad" looks like; trace
  filters by `status=ERROR` and `app.feature`; log queries by `trace_id`.
- **Diagnosis:** a decision tree.
- **Mitigation:** the least destructive, most reversible action first; rollback
  with the forward-only migration note; **DESTRUCTIVE** steps marked and needing
  confirmation from a named role. Never `docker compose down -v`, never `FLUSHALL`
  on a shared instance (`rules/deploy.md`; `caching-standard.md`).
- **Escalation:** who, how, expected response; data exposure -> `security-lead`
  immediately.
- **Verification** that it is fixed (SLI back in SLO, `/readyz`, smoke check).
- **Aftercare** and **Self-hosted variant** (what the customer can do, what
  diagnostics to collect, what must not be shared).
- **Owner** and **Last verified**.

## 3. Where commands come from

Every command, query and path is taken from one of: the stack reference (for
example PostgreSQL monitoring views and queries in
`docs/stack-reference/postgres/best-practices.md` section 5, Redis `INFO` fields
and `SLOWLOG` in `redis/best-practices.md` section 8, Dragonfly equivalents in
`dragonfly/best-practices.md` section 8, Compose healthchecks in
`docker-compose/best-practices.md`), or the repository's own scripts and
`deploy/` files (cite the path). Anything else is written as
`[command to be supplied by <owner> - NOT SOURCEABLE]` with the owner named.
Commands are **read-only** unless marked DESTRUCTIVE; no secret, token, customer
data or connection string appears (refer to the secret store path).

## 4. Verification honesty

The template's **Last verified** means "by executing the steps in staging or a
drill". This skill executes nothing, so a written runbook is
`Last verified: NOT VERIFIED - not executed` and `Next drill: <owner to schedule>`.
The report counts runbooks by state: written, executed, never executed. A
runbook for a backup-failed alert additionally depends on the restore drill
evidence in `production/qa/evidence/` (`sre-lead` Senior Bar): if none exists, say
so.

## 5. Agents

Spawn `sre-lead` (owner; drafts) and, in parallel for independent alerts,
`observability-engineer` for the telemetry sections (dashboards, queries, trace
and log filters) and `infra-engineer` for the Compose, backup and self-hosted
variant sections. Brief: the runbook list, the template path, the command-source
rule above, "return each runbook as text, write no file". Check each against the
template headings and the three rules: commands sourced or owed; DESTRUCTIVE
marked; no secrets. Then `4-checks-gate-and-write.md`.
