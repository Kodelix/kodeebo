# Runbook: [Alert or Failure Mode Name]

> **Path**: `docs/runbooks/<name>.md` · **Owner**: [team/role] · **Last verified**: [YYYY-MM-DD — by executing the steps in staging or a drill] · **Next drill**: [date]
> **Linked alerts**: [alert names — every alert links here; an alert without a runbook is not merged]
> **Linked SLO / journey**: [`docs/architecture/slos.md` — J#] · **Severity guide**: [S1–S4 per `incident-response.md`]
> **Applies to**: [Hosted | Self-hosted | Both] · **Services**: [api, worker, db, cache, proxy ...]

<!-- Write for someone paged at 3 a.m. who did not build this. Imperative steps, exact commands, expected output, a decision at the end of each branch.
     Never put secrets, customer data or tokens in this file; refer to the secret store path.
     Destructive commands (anything with `-v`, DROP, FLUSHALL, force-push, deleting volumes) are marked DESTRUCTIVE and need explicit confirmation. -->

## 1. Symptoms

<!-- What the on-call sees: alert text, user reports, dashboard shapes. Include what this is NOT (look-alikes with other runbooks). -->

- Alert: [name and threshold]
- User-visible: [e.g. "payments fail with 503", "login slow"]
- Looks like but is not: [other runbook link]

## 2. Impact & First Questions (2 minutes)

- [ ] Who is affected? (all tenants / one tenant / one region / self-hosted only)
- [ ] Since when? (alert time vs. last deploy/migration/config change/provider status)
- [ ] Is data at risk (loss, corruption, exposure)? **If exposure is suspected -> declare S1 and follow `incident-response.md` "Breach Notification".**
- [ ] Is a deploy in flight or recently done? If yes and plausible -> go to Mitigation A (roll back).

## 3. Dashboards & Telemetry

| What | Where | What "bad" looks like |
|------|-------|----------------------|
| SLO / burn-rate | [link] | |
| RED for [endpoint] | [link] | |
| DB pool / slow queries | [link] | |
| Cache hit ratio / latency | [link] | |
| Queue depth / consumer lag | [link] | |
| Traces for a failing request | [link, filter by `status=ERROR` and `app.feature`] | |
| Logs | [query, filter by `trace_id` or `service`] | |
| Provider status page | [link] | |

## 4. Diagnosis

<!-- Decision tree. Each step: command or query -> expected result -> next step. -->

1. **Check the service is up and ready**
   ```
   [command, e.g. curl -fsS https://<host>/readyz]
   ```
   Expected: [200]. If not -> [step N].
2. **Check recent changes** — deploys, migrations, config/flag changes, certificate expiry.
   ```
   [command]
   ```
3. **Check dependencies** — DB (connections, locks, replication), cache, queue, outbound provider.
   ```
   [command / SQL, read-only]
   ```
4. **Narrow the blast radius** — one tenant? one endpoint? one version? (use `app.tenant_id`, route, `version` attributes)
5. **Find the cause** — [common causes and how to recognise each]:
   | Cause | How to recognise | Go to |
   |-------|------------------|-------|
   | [Bad deploy] | errors start at deploy time | Mitigation A |
   | [DB saturation / lock] | pool wait high, long-running queries | Mitigation B |
   | [Provider outage] | provider status + timeouts on outbound spans | Mitigation C |
   | [Cache failure] | hit ratio collapse, latency spike | Mitigation D |
   | [Resource exhaustion] | disk/memory/CPU | Mitigation E |

## 5. Mitigation

<!-- Prefer the least destructive, most reversible action first. State the expected effect and how long it takes. -->

### Mitigation A — Roll back
1. [Command or procedure]
2. Expected effect: [...] within [N] min
3. Data/migration note: [forward-only migrations — is rollback safe? see release notes]

### Mitigation B — [Relieve the database]
1. [Steps: kill runaway query (name the safe command), enable read-only mode, scale pool, ...]
2. DESTRUCTIVE actions require confirmation from [role].

### Mitigation C — [Provider outage]
1. [Enable degraded mode / flag; queue and retry; communicate]
2. [Circuit breaker state to verify]

### Mitigation D — [Cache]
1. [Bypass cache via config; confirm the system stays correct; do not FLUSHALL on shared instances]

### Mitigation E — [Capacity]
1. [Scale up / free disk / rotate logs; steps]

## 6. Escalation

| When | Escalate to | How | Expected response |
|------|------------|-----|-------------------|
| No improvement after [15] min or severity >= S2 | [sre-lead / on-call secondary] | [pager / channel] | [5 min] |
| Data exposure suspected | security-lead | [pager] | immediately |
| Provider-side issue | [provider support / account manager] | [portal, contract SLA] | [per contract] |
| Customer communication needed | customer-success / producer | [channel] | |
| Need a code fix | principal-engineer + stack lead | [hotfix path `/hotfix`] | |

## 7. Verification (it is fixed)

- [ ] SLI back within SLO; burn-rate alert cleared
- [ ] `/readyz` OK on all instances; error rate and latency back to baseline for [15] min
- [ ] Synthetic probe / smoke check for the journey passes (`/smoke-check`)
- [ ] Queues drained / reconciliation job caught up
- [ ] Status page updated; customers notified if they were told of the incident

## 8. Aftercare

- [ ] Record timeline in `incident-response.md` (S1/S2) or an issue (S3/S4)
- [ ] Open follow-up stories: root cause fix, new alert/dashboard, test coverage
- [ ] Update this runbook with anything the steps got wrong
- [ ] Schedule post-mortem if budget consumed > threshold (`post-mortem.md`)

## 9. Self-Hosted Variant

<!-- If customers run this: what they can do themselves, what logs/diagnostics to collect for support (diagnostic bundle command), and what must not be shared. -->

## 10. History

| Date | Change / incident that used it | Author |
|------|-------------------------------|--------|
