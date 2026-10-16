---
name: integration
description: "External provider integration (payments, SMS/OTP, email, storage, push, OAuth): research note with the provider's current API version, integration spec, threat model trigger, adapter behind a port with timeouts, retries, breaker, idempotency, signed webhooks, outbox and reconciliation, then contract tests and one sandbox smoke."
argument-hint: "<provider> [--update] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(gitleaks git *), Bash(gitleaks dir *), Bash(date *), Bash(bash "*/.claude/skills/integration/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **Choosing the provider,
accepting a residual risk and any step that touches credentials are never
delegated to a mode**: they always ask.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. An integration is engineering:
the research note, the port/adapter split, the resilience rules, the webhook
order, the contract tests and the threat model apply at `minimal`, `standard`
and `full` (`workflow-modes.md`). What a tier changes is whether the spec is
also recorded as an ADR.

# Integration

Every third-party provider is an adapter behind a port, so a provider outage, a
price change or a customer who brings their own provider never reaches the
domain (`.claude/rules/integrations.md`). This skill takes one provider from
"we need it" to a researched, specified, threat-modelled, tested adapter, with
the provider's **current API version taken from its official documentation,
never recalled**. Owner: `integrations-engineer`.

**Output**
- `docs/research/<provider>.md` (research note, from `templates/research-note.md`)
- `docs/architecture/integrations/<provider>.md` (from `templates/integration-spec.md`)
- `docs/architecture/threat-models/<provider>.md` through `/threat-model` (a new external integration is a threat-model trigger at every tier)
- the port, adapter and tests under the backend code root (only on the user's "implement now"); otherwise the story list for `/create-stories`
- `production/qa/evidence/integration-<provider>/` (contract-test output, gitleaks result, sandbox-smoke record)

**It never touches live credentials.** It does not ask for, read, print or store
a key value, and it never calls a live (production) provider endpoint. Sandbox
credentials come from the secret store, loaded by the user.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `NOT ASSESSED` outranks `COMPLETE` and ranks below `BLOCKED`: an
> API version that is `NOT SOURCEABLE`, contract tests that were not run, a
> sandbox smoke that was not run, a stack reference that is absent for the
> backend layer, or a threat model gate that could not run means part of the
> scope was never assessed (`.claude/rules/skill-authoring.md`). `BLOCKED`: a
> live key found in dev/CI/fixtures/history, a provider type in `domain` or
> `app`, a webhook handler that parses before it verifies, an automatic retry of
> a non-idempotent call, a money integration with no reconciliation, a card-data
> path through our servers, or `SL-THREAT-MODEL` = REJECT. Every cause is named
> in the report; `COMPLETE` is unreachable while any is open.

---

## Phase 1: Arguments, Trigger and Inputs

**Read `references/1-inputs-and-core-first.md` now and follow it.** It parses the
provider and mode, records every input as FOUND or ABSENT, and runs the
**core-first check**: if a `saas-core-<track>` module already covers the capability
(identity, OTP, notify, storage, billing, licensing), stop and hand to `/core-use`
unless the user records a written reason for a product-local adapter. Read it again
if the conversation was compacted or resumed during this phase.

## Phase 2: Research Note

**Read `references/2-research-note.md` now and follow it.** Spawn `researcher`
via `Agent` with the fixed brief in that file. The provider's current API
version, auth scheme, rate limits, webhook signature scheme and sandbox
behaviour come from the provider's **official documentation**, fetched with the
date; anything not found is `NOT SOURCEABLE`. If the provider is not yet chosen,
the note compares options and the **user** chooses (`AskUserQuestion`);
technology choice goes through `cto`, plans and prices through
`pricing-billing-designer`.

## Phase 3: Integration Spec

**Read `references/3-integration-spec.md` now and follow it.** It fills
`.claude/docs/templates/integration-spec.md` section by section from the
research note, with the user, and checks the spec's structure.

## Phase 4: Threat Model Trigger

A new external integration is a sensitive area (`security-baseline.md` "Threat
modelling"). State which of these the integration touches, with the evidence:
**webhooks**, **payments/billing**, **PII** (sent, stored, or in logs),
**credentials/OAuth**, **user-supplied callback URLs (SSRF)**, **file transfer**.

- New provider → run `/threat-model <provider>` (it runs `SL-THREAT-MODEL` per
  `review_mode`). Record the gate as it came back: APPROVE / CONCERNS / REJECT /
  NOT ASSESSED, or `SL-THREAT-MODEL skipped — <mode> mode` when `lean` or `solo` skipped it —
  a skipped gate is recorded as skipped (never as APPROVE) and listed in the report's
  Not run / not checked; the model's existence and the trigger rule above still apply.
  Webhooks, money and PII make the model's abuse cases mandatory: forged and
  replayed callbacks, duplicate delivery, tampered amounts, provider compromise
  and outage, secret leakage in logs, cross-tenant routing of an event.
- Extending an existing integration with an operation that adds no new boundary,
  data class or credential → cite the existing model's path and record
  `no new boundary` with the evidence. If any boundary changed, run
  `/threat-model <provider> --update`.
- No model for a triggered integration is a finding (REJECT-class), never a
  skipped step: the sensitive adapter code is not started until the model's
  gate is APPROVE or CONCERNS.

## Phase 5: Decide How It Is Built

Ask (`AskUserQuestion`): **implement now** (Phase 6 spawns the stack lead's
work through `integrations-engineer`) or **write the stories** (the skill ends
with a mitigation-and-test-to-story list for `/create-stories`; the adapter is
then built by `/dev-story`). Either way the research note and spec must already
exist: no adapter code is written before them.

## Phase 6: Adapter Behind a Port

**Read `references/4-adapter-and-resilience.md` now and follow it.** It lists
the port, adapter, error mapping, resilience, credential, webhook, outbox,
money and observability requirements exactly as the rule and the
`integrations-engineer` Senior Bar state them, and the destination paths per
code root. Only on "implement now": spawn `integrations-engineer` with the fixed
brief there; verify the files exist before reading the reply
(`.claude/docs/error-recovery-protocol.md`).

## Phase 7: Tests, Sandbox Smoke and Review

**Read `references/5-tests-and-sandbox.md` now and follow it.** Contract tests
against a stub for the cases the rule lists, port-conformance suite, gitleaks
on the integration, and **one sandbox smoke** per release with its date. In
parallel with the tests, for webhooks, money or PII spawn `appsec-engineer` for
the security review (independent of the test run). Real output only; a check
that did not run is `not run`.

## Phase 8: Checks, Report, Write

**Read `references/6-checks-and-report.md` now and follow it.** It runs checks
I1-I16, derives the verdict, and asks before writing the report and evidence.

---

## Error Recovery Protocol

**First, verify the artifact.** If `researcher`, `integrations-engineer` or
`appsec-engineer` returns, check the file it was told to write exists before
believing the reply; a fluent reply with no file is a failed phase. If a spawned
agent is BLOCKED or errors: surface it immediately, do not proceed past what it
blocks, produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`. A phase that could not run is
recorded `NOT ASSESSED — [what was missing]`.

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Never write a provider API, version, header, signature scheme, error code or limit from memory** — sourced from official documentation with the fetch date, or `NOT SOURCEABLE` routed to `/research`
- **The provider choice is the user's** (via `cto` / `pricing-billing-designer`), not the skill's
- **Credentials are never entered, read or printed here.** Live keys never exist in dev, CI, fixtures or evidence; the skill refuses a smoke run if the configured key is live per the documented marker
- **Core first** — a product-local adapter needs a written reason; extensions go upstream (`/core-extract`)
- **A check that did not run is reported as not run** — tests, scans, the sandbox smoke and gate verdicts alike
- **No payload bodies, secrets, PII or card-like data** in evidence, logs or the report
- Writes: ask "May I write…" naming every path; the adapter code writes only on "implement now"
- No commits unless the user asks

## Recommended Next Steps

- `/create-stories` for the stories listed (adapter, webhook handler, outbox, reconciliation, smoke) if built later
- `/observability-plan` for the dashboards, alerts and provider-outage runbook; `/db-migration` for the webhook-event and outbox tables; `/cache-design` for idempotency-key storage
- `/dependency-audit` after adding a provider SDK (CVEs and licence); `/security-audit` before release
- `/team-integration` to run this end to end with security and QA; `/release-checklist` picks up the per-release sandbox smoke
