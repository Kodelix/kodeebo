# /integration - Phase 8: Checks, Verdict, Report

> Phase 8 of `SKILL.md`. Each check is `met` / `not met` / `not applicable
> (reason)` / `not run (reason)`. Never "n/a" without a reason; never `met`
> without the evidence cited.

## Checks

| ID | Check | Evidence |
|---|---|---|
| I1 | Research note names the provider's **current API version** with the official URL and fetch date; auth, rate limits, webhook signature scheme, sandbox behaviour present or `NOT SOURCEABLE` | note path + finding numbers |
| I2 | Core-first decision recorded: `/core-use` module, or `no core module` with evidence, or a written reason for a product-local adapter | spec header |
| I3 | Integration spec: 13 sections, no placeholders, Last Verified = research date, Status per rules | spec path |
| I4 | Threat model exists for the triggered areas and `SL-THREAT-MODEL` verdict recorded, or `SL-THREAT-MODEL skipped — <mode> mode` recorded as skipped (never as APPROVE), or `no new boundary` with evidence on `--update` | model path + verdict |
| I5 | Port is provider-neutral; no provider type/code/field in `domain` or `app` (grep for the SDK package and provider names outside the adapter directory) | grep command + hits |
| I6 | Every operation: timeout, bounded retry on idempotent calls only, breaker, idempotency key where supported; ambiguous outcome → pending | spec §3, §6; T4-T7 |
| I7 | Closed domain error set; raw provider code not returned to clients | T2; mapping table |
| I8 | Sandbox/live secrets distinct; live key absent from dev/CI/fixtures/history; startup guard; gitleaks result | gitleaks output; T17 |
| I9 | Webhook handler order fixed; signature before parse; replay; unique-constraint dedupe; async; no secret in logs | T8-T12 |
| I10 | Outbox row in the same transaction; idempotent dispatcher; DLQ + alert + runbook link | T13 |
| I11 | Money: minor units, server catalogue, tampered amount ignored, no card data on our servers | T14; PAN scan |
| I12 | Money: reconciliation job with metric, alert, runbook, no unaudited auto-correction | T15 |
| I13 | Observability: span per call with `app.provider`, RED + breaker + webhook metrics, no payload bodies, alert + runbook | spec §10 |
| I14 | Contract tests T1-T18 (applicable ones) ran and passed against real output; output saved | evidence folder |
| I15 | Sandbox smoke run (dated) or `not run` with reason | smoke record |
| I16 | Self-hosted: works without our hosted infrastructure, provider choice is configuration, no phone-home; new SDK queued for `/dependency-audit` | spec §1, §2 |

A check whose input is absent is `not run`, not `not applicable`: an empty
code-root result makes I5-I14 `NOT ASSESSED — no source under <root>`.

## Verdict (first match wins)

1. **BLOCKED** — I4 gate REJECT or a model absent for a triggered integration;
   I5 not met; I6 non-idempotent call auto-retried; I8 live key found in
   dev/CI/fixtures/history (or rotation not done); I9 parse-before-verify;
   I11 card-data path; I12 not met for a money integration.
2. **NOT ASSESSED** — any of: I1 API version `NOT SOURCEABLE`; stack reference
   absent for the backend layer; I14 not run; I15 not run; I8 scan not run; I4
   gate agent could not run; a core-first check that could not reach the core.
   Name each cause and what closes it.
3. **COMPLETE WITH GAPS** — everything assessed, but I2/I3/I7/I10/I13/I16 not met
   or the spec still Draft because of open questions; each gap listed.
4. **COMPLETE** — all applicable checks met with evidence on disk.

`COMPLETE` is not the release approval: `SL-RELEASE-SECURITY` and
`SRE-OPERABILITY` (check 9, external providers' failure modes) run at release.

## Report

Present in conversation: scope (provider, capability class, API version with
date), checks table, verdict with causes, NOT ASSESSED list, files written, the
mitigation/test-to-story list when Phase 5 chose "write the stories", and
follow-ups. Include a **Not run / not checked** list; a skipped phase is named
(`Phase 6 skipped — user chose stories`).

Ask: "May I write the evidence to
`production/qa/evidence/integration-<provider>/` (contract-test output, gitleaks
result, smoke record) and the report to
`production/qa/integration-<provider>-[date].md`?" Name both paths. Write only
after approval. Never put a secret, payload, PII or card-like string in either.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/integration <provider> —
<verdict>`, Next step = the first Recommended Next Step in `SKILL.md`, plus
Blocked on / Files in progress / Open questions; append the Notes line. A
BLOCKED or NOT ASSESSED verdict, or a declined write, still updates the
checkpoint with the blocker.
