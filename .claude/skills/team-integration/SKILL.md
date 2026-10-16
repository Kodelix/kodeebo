---
name: team-integration
description: "Orchestrate a provider integration end to end with security and QA — integrations-engineer builds through /integration, qa-tester and test-automation-engineer verify independently on a running stack (failure modes, duplicate and forged webhooks, cross-tenant routing), security-lead and appsec-engineer review money, webhook and PII paths."
argument-hint: "<provider | capability> [--update] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Bash(docker compose logs *), Agent, AskUserQuestion, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f deploy/compose.dev.yaml ps), Bash(docker compose -f deploy/compose.dev.yaml ps *), Bash(docker compose -f deploy/compose.dev.yaml logs *), Bash(docker compose logs), Bash(bash "*/.claude/skills/team-integration/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Integration

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-integration <provider | capability> [--update] [--review full|lean|solo]` — name the provider or capability to integrate (e.g., `paymob`, `sms-otp`, `s3-storage`) or, with `--update`, an existing integration being revised. Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the integration team through the `/integration` flow with the independent verification that a single builder cannot give itself: someone else breaks the adapter on a running stack, and the security lead looks at the paths that move money, accept callbacks or carry personal data.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. **Choosing the
provider, accepting a residual risk and any step that touches credentials are never
delegated to a mode.** See `.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,automation_always_ask,stack,distribution,tenancy`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow` and `qa.level` do not relax this pipeline.** An integration is
engineering: the research note, port/adapter split, resilience rules, webhook
order, contract tests and threat model apply at every tier (see `/integration`).
Tests never scale down: the provider rule's contract tests (success, 4xx, 5xx,
timeout, duplicate webhook, bad signature) and the security negative tests exist and
pass at every `qa.level`; `qa.level` changes only how much extra evidence is asked for.

`review_mode` sets director-gate depth. The gate in this pipeline is
**SL-THREAT-MODEL**, run by `/threat-model` inside `/integration` (Phase 2); it
follows the review mode there (`full` spawns it; `lean`/`solo` record
`SL-THREAT-MODEL skipped — [mode] mode`). A skipped gate waives the director's
opinion, never the evidence: the threat model document, the negative tests and the
QA execution are required at every mode. The pipeline's other phase gates are its
own decision points.

`automation` drives the Decision Points note above.

**`team.size`**: which agents are active (orthogonal to review_mode and workflow).
- **`individual`** (default): `integrations-engineer` (through `/integration`) + `qa-tester` (the independent verifier). `security-lead` is invoked at the sign-off phase gate only; `appsec-engineer` runs where `/integration` itself spawns it for webhook, money or PII review.
- **`small`**: + `appsec-engineer` throughout and `test-automation-engineer` for the coverage review and missing suites.
- **`studio`**: + `security-lead` throughout, `messaging-specialist` (outbox, DLQ), `cache-specialist` (idempotency-key storage), `pricing-billing-designer` when the integration moves money, and an adversarial verification pass: the reviewers are told "your job is not to confirm the adapter works — find the delivery order, replay or tenant mix where it breaks", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists**, whatever the `automation` mode.

**Announce the active set before Phase 1 — never let the collapse be silent.**
State in one line which agents this run will spawn and which the pipeline names
but will **not** spawn at the resolved `team.size`:

> `Active set (team.size: <resolved>): <agents for that size>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct; without saying so a reader cannot tell a collapsed run
from a broken one.

## Team Composition

- **integrations-engineer** — port, adapter, webhooks, outbox, reconciliation, test kit (owner of `/integration`)
- **researcher** — the provider research note, spawned by `/integration` (primary sources, current API version)
- **qa-tester** — failure-mode cases from the spec, executed on the running stack against a provider stub; evidence; bug reports
- **test-automation-engineer** (`small`+; at `individual` the **qa-tester** does this coverage review and writes `coverage-review.md`) — coverage review of the contract suite and port-conformance tests; fills gaps (per-tenant credentials, cache-down for idempotency storage, duplicate and out-of-order events)
- **appsec-engineer** — webhook, SSRF, secret and PII-in-logs review, negative tests
- **security-lead** — threat-model adequacy and sign-off on the money, webhook and PII paths
- **messaging-specialist**, **cache-specialist**, **pricing-billing-designer** — outbox/DLQ semantics, idempotency storage, catalogue and dunning rules (`studio`)

## How to Delegate

Use the `Agent` tool: `subagent_type: qa-tester` · `test-automation-engineer` · `appsec-engineer` · `security-lead` · `messaging-specialist` · `cache-specialist` · `pricing-billing-designer`. The builder and researcher are spawned by `/integration`.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline, never a path to a document you already read. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."

| Phase / agent | Writes to |
|---|---|
| 3 qa-tester (cases) | `production/qa/cases/integration-[provider]-cases.md` |
| 4 qa-tester (execution) | `production/qa/evidence/integration-[provider]/qa-execution.md` and the evidence files beside it |
| 4 test-automation-engineer | new test files at the paths the approved gap list named; summary `production/qa/evidence/integration-[provider]/coverage-review.md` |
| 4 appsec-engineer, security-lead, messaging-specialist, cache-specialist, pricing-billing-designer | `production/qa/evidence/integration-[provider]/review-[agent].md`, one each |

`/integration` writes the research note, spec, threat model, adapter and its own evidence under its protocol and asks before writing.

> **Why this does not violate the Collaboration Protocol.** A subagent spawned here writes **without** asking, a deliberate, bounded exception. It holds only when: (1) the path is one **you** named in the prompt; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

### Phase 1: Context and Decisions

Parse the argument (`<provider>` slug or capability; `--update`). Read and report each as FOUND or ABSENT: the feature spec(s) the integration serves, existing `docs/research/<provider>.md`, `docs/architecture/integrations/<provider>.md` and its threat model, the pricing model (money class), `contracts/` for the inbound webhook route, `deploy/` for secret wiring, and `stack`, `distribution.model`, `tenancy.model` from the resolved config (unset is asked, not assumed; self-hosted means the provider choice is configuration).

Classify the capability as `/integration` does (money, inbound webhooks, PII, side effects after commit, per-tenant credentials, user-supplied URL, file transfer) — the classes decide which Phase 4 reviewers matter. State: **sandbox credentials are loaded by the user from the secret store; this pipeline never asks for, reads or prints a key, and never calls a live provider endpoint.**

If a capability is named without a provider, the provider is **not chosen**: `/integration` compares options and the user decides with `cto` (technology) and `pricing-billing-designer` (fees and plans).

Report: "Integration cycle for [provider/capability] ([new | update]). Classes: [list]. Core module: [checked by /integration]. Sandbox credentials: [available | not yet]. Ready?"

### Phase 2: Research, Spec, Threat Model, Build — `/integration`

Run `/integration <provider> [--update]`. It performs the core-first check (a `saas-core-<track>` module that covers the capability redirects to `/core-use`), the research note from the provider's official documentation, the integration spec, the threat-model trigger (`/threat-model <provider>`, SL-THREAT-MODEL) and the adapter behind a port with its contract tests and checks I1–I16. Do not re-implement any of it.

**Sequencing with Track B.** When `/integration` reaches its Phase 5 — the spec and the threat model now exist — **before answering "implement now"**, launch Track B in the background:

- `qa-tester` (all sizes) writes failure-mode cases from the spec's failure table to `production/qa/cases/integration-[provider]-cases.md`: provider 4xx; 5xx and timeout with the retry policy; ambiguous outcome → pending; duplicate and out-of-order webhook; bad signature; stale timestamp; tampered amount or plan; an event for another tenant's object; stub stopped mid-flow (`docker compose stop`); a restart between persist and process; credentials absent at startup. Cases cite spec sections.

Answer `/integration`'s question **implement now** (the file set is approved there, under its File Write Protocol). **Gate (phase gate):** summarise the `/integration` verdict (COMPLETE / COMPLETE WITH GAPS / NOT ASSESSED / BLOCKED) with each cause. A `BLOCKED` (live key found, provider type in `domain`/`app`, parse-before-verify webhook, retry of a non-idempotent call, money with no reconciliation, card data path, SL-THREAT-MODEL REJECT) stops the pipeline: nothing downstream is a verification of a blocked build. `AskUserQuestion`: proceed to verification / fix and re-run `/integration --update` / stop.

### Phase 3: Review the Cases

Present the QA cases (Track B output) next to the spec. `AskUserQuestion` per group: approved / revise [case] / drop [case] with a reason. Cases are traced to the spec's failure table; a failure mode with no case is a gap named to the user.

### Phase 4: Independent Verification (parallel)

Bring the stack up as `.claude/docs/run-and-observe.md` says (`docker compose -f deploy/compose.dev.yaml up -d --wait`, seeded tenants, provider stub — WireMock/`httptest` — never the live provider; never `down -v`). `qa-tester` runs the induced-failure commands itself (`docker compose stop` on the provider stub, a restart between persist and process) and `appsec-engineer` (or `qa-tester` at `individual`) runs `gitleaks`; both have Bash — this skill grants neither, and only the bring-up, `ps`, `logs` and the helpers. Launch these together:

- **qa-tester** — executes the approved cases as each actor on the stack, **inducing** the failures rather than assuming them; records request/response (secrets redacted), the trace of one provider call (`app.provider` span), and the resulting database/outbox state. Reports pass/fail per case; files bugs via `/bug-report` (a cross-tenant event routing is S1: announced immediately).
- **test-automation-engineer** (`small`+; `qa-tester` at `individual`) — compares the suite `/integration` produced against `testing-standards.md` "Every provider integration" and the spec: success, 4xx, 5xx/timeout with retry, duplicate webhook (idempotency), invalid signature, plus per-tenant credential isolation, cache-down for the idempotency store, and port-conformance. Writes the missing tests at paths you approve first (`/automate-test` conventions: deterministic, Testcontainers, no sleeps).
- **appsec-engineer** (`small`+) — webhook order (signature on raw bytes before parse, timestamp tolerance, replay, dedupe), SSRF egress allowlist for user-supplied URLs, secrets and personal data in logs and traces (a grep of a real run saved to the evidence folder), the gitleaks result. Negative tests added where missing.
- At `studio`: **messaging-specialist** (outbox in the same transaction, idempotent dispatcher, DLQ), **cache-specialist** (idempotency-key store behaviour when the cache is down), **pricing-billing-designer** (catalogue read server-side, minor units, dunning and refund rules) for a money integration.

Run the layer's suites with `/test` and the **sandbox smoke** (one per release) with the sandbox credentials the user loaded; a smoke not run is `not run — [reason]`. At `studio`, the adversarial instruction applies.

**Gate (phase gate):** present the QA results, the coverage review, the security findings (by severity) and the checks that did not run. `AskUserQuestion`: fix the failures (route via `principal-engineer`; the owning lead writes after a file-set approval) / accept a listed item (the **user** accepts, with owner and expiry) / stop.

### Phase 5: Sign-off

`security-lead` (invoked here at every size) reviews the evidence for the paths in scope — webhook, money, PII, credentials — and returns, as text, one of **APPROVE / CONCERNS / REJECT** on the integration's security posture, citing files and numbers, or `NOT ASSESSED` naming the missing input. This is a review of this pipeline's evidence, not a release gate: `SL-RELEASE-SECURITY` still runs at the release.

**Integration status** (first match wins):
1. **BLOCKED** — a `/integration` BLOCKED cause, an S1 open, or a security REJECT.
2. **NOT ASSESSED** — nothing above, but contract tests, the QA execution, the sandbox smoke, the gitleaks run or the sign-off could not run, or the provider's API version is `NOT SOURCEABLE`.
3. **COMPLETE WITH GAPS** — everything ran; accepted items or listed gaps remain.
4. **COMPLETE**.

`NOT ASSESSED` outranks `COMPLETE` and ranks below `BLOCKED`. Ask: "May I write the team integration report to `production/qa/evidence/integration-[provider]/team-integration-report.md`?" Write only after a yes; take the report date from `date +%F`.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** Resume the agent
naming the unmet contract.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

Common blockers:
- A core module already covers the capability → `/core-use`; the pipeline stops unless the user records a written reason
- Provider API version or webhook scheme `NOT SOURCEABLE` → `/research`; no adapter code until it is sourced
- Live credentials found anywhere in dev, CI, fixtures or history → stop, rotate, `security-lead`
- Stack will not come up → that is the finding; capture `docker compose logs`, stop Phase 4

## Output

A summary covering: provider/capability and classes, active set, `/integration` verdict and checks, the QA cases and execution results with evidence paths, coverage-review additions, security findings and sign-off, the sandbox smoke status, accepted items, and the integration status.

Verdict: **COMPLETE** — the integration was built, verified independently and signed off.
Verdict: **COMPLETE WITH GAPS** — everything ran; accepted items or listed gaps remain (named).
Verdict: **COMPLETE — [smoke | QA execution | security review] NOT ASSESSED ([reason])** — the named check could not run.
Verdict: **BLOCKED** — a blocking cause halted the pipeline; partial report produced.
Verdict: **BLOCKED — write declined by user** — the report or a gap-list file set was declined; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-integration <provider> — <verdict>`, Next step = the first item below that applies, plus Blocked on / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED and a declined write.

- Money integrations: `/team-billing` (entitlements and licence enforcement on top)
- `/observability-plan` (dashboards, provider-outage runbook), `/db-migration` (webhook-event and outbox tables), `/dependency-audit` (the provider SDK), `/security-audit` before release
- `/create-stories` for any gap not fixed now; `/story-done` per story; `/release-checklist` picks up the per-release sandbox smoke
