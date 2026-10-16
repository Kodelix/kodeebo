---
name: team-billing
description: "Orchestrate the billing team — pricing-strategist business inputs, pricing-billing-designer's plans and entitlements as data, payment-provider integration, licence design for self-hosted, and QA — keeping one entitlement catalogue as the source of truth for both billing and licences. Uses /pricing-strategy, /pricing-check, /threat-model, /integration, /license-design."
argument-hint: "[billing change | plan or price change | new pricing model | self-hosted licensing] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(docker compose logs *), Agent, AskUserQuestion, Edit, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f deploy/compose.dev.yaml ps), Bash(docker compose -f deploy/compose.dev.yaml ps *), Bash(docker compose -f deploy/compose.dev.yaml logs *), Bash(docker compose logs), Bash(bash "*/.claude/skills/team-billing/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Billing

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-billing [billing change | plan or price change | new pricing model | self-hosted licensing] [--review full|lean|solo]` — describe the commercial change to deliver (e.g., `add an annual plan`, `usage-based API quota`, `self-hosted annual licence`, `first payment provider`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the billing team through a structured pipeline: business inputs, then a data-driven pricing and entitlement model, then the payment and licence mechanisms that enforce it, then proof that money and access behave.

**The rule that organises this pipeline:** an entitlement key exists **once**, in the plan and entitlement catalogue. Hosted billing and self-hosted licences are two *feeds* into the same entitlement port the use cases ask (`can(tenant, "feature.key")`); neither keeps its own list, and no code checks a plan name. Prices, limits and quotas are data, never constants in code (`coding-standards.md`).

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. **Prices, the
value metric, plan boundaries, the choice of payment provider and any residual risk
are the user's decisions and are never delegated to a mode.** See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,automation_always_ask,system_overrides,stack,distribution`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`workflow` sets how many spec sections the pricing model needs, not whether the
engineering applies: billing and licensing are security-sensitive areas, so the
threat models (Phase 4), the money-correctness tests and the ASVS Level 3
assurance apply at every tier (`security-baseline.md`). `system_overrides.billing`
may raise the tier for this one feature; the resolved block above carries it.

`review_mode` sets director-gate depth. This pipeline's gates: **SL-THREAT-MODEL**
(run by `/threat-model` in Phase 4) and **PD-SPEC-ALIGN** (Phase 3, spawned here
only at `review_mode: full`). At `lean` and `solo` record `[GATE-ID] skipped —
[mode] mode`; a skipped gate waives the director's opinion, never the evidence.

`automation` drives the Decision Points note above.

**`team.size`**: which agents this pipeline spawns directly (orthogonal to review_mode and workflow).
- **`individual`** (default): `pricing-billing-designer` + `qa-tester`. Business inputs are read from `business/pricing/` when present; when absent the pipeline names `/pricing-strategy` as the missing producer (it is not spawned here). The skills in Phases 4–5 spawn their own agents (`/threat-model`, `/integration`, `/license-design`).
- **`small`**: + `pricing-strategist` (through `/pricing-strategy`), `integrations-engineer` (payment provider), `licensing-specialist` (when `distribution.model` includes self-hosted), `test-automation-engineer`, and `security-lead` through the threat models.
- **`studio`**: + `appsec-engineer`, `privacy-compliance-specialist` (invoice and payment-record retention), `growth-lifecycle` (dunning journeys), `product-analytics-engineer` (revenue events), and an adversarial pass: the Phase 7 reviewers are told "your job is not to confirm the model works — find the plan change, coupon sequence, clock edge or licence state where it pays out or grants wrongly", and the report says the pass ran.
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

- **pricing-strategist** — value metric, packaging, regional price levels (EGP, SAR, AED, USD), licence economics, offers with guardrails, margin — every number sourced and dated (`business-research-protocol.md`); hands the decided model to the designer
- **pricing-billing-designer** — plan catalogue, entitlements and limits as data, metering, subscription / one-time licence / trial / coupon / proration / dunning rules, tax and invoice rules
- **integrations-engineer** — the payment provider as an adapter behind a port: hosted checkout or tokenisation (card data never touches our servers), signed webhooks, reconciliation
- **licensing-specialist** — Ed25519-signed licences, activation, offline grace, revocation, update eligibility, the entitlement port's licence feed
- **qa-tester**, **test-automation-engineer** — money-correctness and entitlement cases and automation
- **security-lead** (and `appsec-engineer` at `studio`) — threat models for billing and licensing; **product-director** — pricing-model spec alignment at `full`

## How to Delegate

Use the `Agent` tool: `subagent_type: pricing-billing-designer` · `pricing-strategist` (or `/pricing-strategy`) · `integrations-engineer` (via `/integration`) · `licensing-specialist` (via `/license-design`) · `qa-tester` · `test-automation-engineer` · `security-lead` · `appsec-engineer` · `privacy-compliance-specialist` · `growth-lifecycle` · `product-analytics-engineer` · `product-director` (the gate).

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline, never a path to a document you already read. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."

| Phase / agent | Writes to |
|---|---|
| 3 pricing-billing-designer | `production/billing/[slug]/pricing-model-draft.md` (the approved model is copied to `design/specs/pricing-model.md` only after the Phase 3 gate, with a "May I write" ask — it is an existing artifact if present) |
| 5 qa-tester | `production/qa/cases/billing-[slug]-cases.md` |
| 5 test-automation-engineer | summary `production/qa/evidence/billing-[slug]/automation-plan.md`; test files only at paths the approved gap list named |
| 6 pricing-billing-designer + licensing-specialist | `production/billing/[slug]/entitlement-parity.md` |
| 7 reviewers (appsec, privacy, growth, analytics) | `production/qa/evidence/billing-[slug]/review-[agent].md`, one each |

Sub-skills (`/pricing-strategy` → `business/pricing/`, `/threat-model`, `/integration`, `/license-design`, `/pricing-check`) write under their own protocols and ask before writing.

> **Why this does not violate the Collaboration Protocol.** A subagent spawned here writes **without** asking, a deliberate, bounded exception. It holds only when: (1) the path is one **you** named in the prompt; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

### Phase 1: Load Context

Read and report each as FOUND or ABSENT: `design/product-brief.md` (audience, pricing intent, distribution), `design/specs/pricing-model.md` — the canonical path (template `.claude/docs/templates/pricing-model.md`); if absent, `Glob design/**/pricing-model*.md` and name a non-canonical location — `business/pricing/` (strategy, offers, price tests) and `business/competitors/`, `design/registry/entities.yaml` (plans, roles, permissions, quotas — the existing catalogue), `docs/architecture/licence-model.md` (template `.claude/docs/templates/licence-model.md`), existing payment integration specs in `docs/architecture/integrations/`, billing/licensing threat models, `contracts/` operations that carry plans or entitlements, and the `saas-core-<track>` billing and licensing modules (core first — `/core-use` before a product-local mechanism).

From the resolved config: `distribution.model` decides whether the licence track (Phase 5B) exists; an **unset** value is asked, not assumed (self-hosted pricing and licensing are skipped only when the value is explicitly hosted-only). Tax and invoicing facts for Egypt, GCC or any market are **not written from memory**: a missing source is `NOT SOURCEABLE` and goes to `/research` under `business-research-protocol.md`.

Report: "Billing cycle for [change]. Distribution: [hosted | self-hosted | both | unset]. Pricing model: [present / absent]. Business inputs: [dated sources / none]. Catalogue: [present / absent]. Ready?"

### Phase 2: Business Inputs (pricing-strategist)

Run `/pricing-strategy` (or read its existing output under `business/pricing/`) for the decisions this change needs: value metric, packaging by edition, price levels per currency with the VAT-inclusive display rule, monthly vs annual, one-time licence and maintenance percentage, self-hosted annual licence and POC terms, offers and their guardrails, price tests, and gross margin per plan. Each number carries a source, a date and a stated assumption flag (`business-research-protocol.md`); an unsourced number is `ASSUMPTION` and listed. `pricing-strategist` hands the decided model to the designer as a data list.

**Gate (phase gate):** `AskUserQuestion` — the user, with `product-director`, decides the value metric and the plans: approve / adjust a number / reject. **The pipeline never sets a price.**

### Phase 3: Pricing Model and Entitlements (pricing-billing-designer)

Spawn `pricing-billing-designer` to draft the model from `.claude/docs/templates/pricing-model.md`: the plan catalogue and prices (minor units per currency); **entitlements as data keyed by plan** with evaluation order (plan defaults → add-ons → per-tenant overrides → licence claims); limits and quotas with hard/soft behaviour and the over-limit message; metering (billable events, aggregation windows, late events, idempotent ingestion, reconciliation); lifecycle (trial, coupon with abuse control, upgrade/downgrade proration with worked examples, cancellation, refund, grace); dunning schedule and reinstatement (journeys to `growth-lifecycle`); tax and invoice contents (sourced or `NOT SOURCEABLE`); acceptance criteria including negative cases. Each entitlement key is also recorded in `design/registry/entities.yaml` so `/consistency-check` can see it.

Then run `/pricing-check` on the draft (loopholes, margin, unreachable tiers, abuse paths) and `/consistency-check` for registry conflicts. At `review_mode: full`, spawn `product-director` for **PD-SPEC-ALIGN** (the `Agent` prompt tells it to read `.claude/docs/director-gates/pd-spec-align.md` first; pass the pricing-model path, the product brief and the principles).

**Gate (phase gate):** `AskUserQuestion`: approve the model / revise [section] / cancel. On approval ask "May I write the approved model to `design/specs/pricing-model.md`?" (a new file with `Write`; an existing model is changed in place with `Edit`, as a new catalogue version).

### Phase 4: Threat Models (security-lead)

Billing and licensing are threat-model triggers (`security-baseline.md`; ASVS Level 3 for both). Run `/threat-model billing` and, when the licence track applies, `/threat-model licensing` — client-sent prices, plan tampering, entitlement grant without a verified event, coupon stacking and trial farming, seat inflation, replayed or out-of-order webhooks, refund abuse, licence sharing, clock rollback, forged or downgraded signatures. **No billing or licensing implementation starts on a REJECT.** CONCERNS → `AskUserQuestion`: revise / accept with owner / discuss; residual risk is accepted by the user with owner and expiry.

### Phase 5: Mechanisms and Test Design (parallel)

Launch the background agents first, then run the skills in this session:

- **qa-tester** — cases from the approved model: plan change in both directions with the model's proration examples, trial start/expiry/abuse, coupon stacking and expiry, seat limit and the over-limit message, downgrade with usage above the new limit, failed payment through the dunning schedule and reinstatement, refund, currency and VAT display (EGP, SAR, AED, USD as the model defines), Arabic invoice/receipt copy in RTL, entitlement change reflected in the UI and API, cross-tenant plan reads.
- **test-automation-engineer** (`small`+) — the test plan and factories: money in minor units with rounding at the model's stated boundary, entitlement evaluation order, idempotent metering ingestion, duplicate and out-of-order webhook events, and the parity tests of Phase 6. Test files at paths you approve first.
- **In this session, serially:** **5A** `/integration <payment-provider>` (the provider is the user's choice via `cto` and `pricing-billing-designer`; hosted checkout or tokenisation only — **card data never touches our servers**; webhook-driven grants only on verified events; minor-unit amounts and server-side prices; scheduled reconciliation). **5B** `/license-design` when the licence track applies: the licence's claims are *derived from the Phase 3 catalogue's keys*, not a second list; Ed25519 signing key outside the repository and CI logs; activation, offline grace, revocation, update eligibility against the maintenance window.

### Phase 6: One Source of Truth — Entitlement Parity

`pricing-billing-designer` and `licensing-specialist` (when the licence track applies) produce `entitlement-parity.md`:

| Entitlement key | Catalogue row (plan/add-on) | Billing feed (plan → key) | Licence claim (self-hosted) | Enforced at (port/use case) | Test | Status |
|---|---|---|---|---|---|---|

Rules checked and reported: every key appears once in the catalogue; every billing grant and every licence claim maps to a catalogue key; **no key exists only in a licence or only in billing**; no code branch tests a plan name; no price, limit or quota is a constant in code (a `Grep` over the code roots from `bash .claude/hooks/yaml-helper.sh resolve_code_root`; unresolved roots → `NOT ASSESSED`, not zero hits); entitlement changes are idempotent and audited. A mismatch is a finding routed to the owner and a story for `/create-stories`; the stack leads implement through `/dev-story` after the user approves the file set. Entitlements are a hot read: a cache decision goes through `/cache-design`.

**Gate (phase gate):** `AskUserQuestion`: stories for the gaps / accept a listed gap / stop.

### Phase 7: Verify

Bring the stack up (`docker compose -f deploy/compose.dev.yaml up -d --wait` — granted here; every other shell command of this phase — suites, the parity grep over the code roots, sandbox calls — is run by `qa-tester`, `test-automation-engineer` or the owning lead through `Agent`, or by `/test` — seeded tenants, provider **sandbox** with the user's sandbox credentials — never live — and never `down -v`) and run:
- the automated suites with `/test` (money rounding, evaluation order, webhook idempotency, parity, licence tamper — a tampered/expired licence and a clock rollback inside the grace window);
- `qa-tester` executes the Phase 5 cases as each actor, including the negative paths, with evidence under `production/qa/evidence/billing-[slug]/`;
- `/pricing-check` again on the as-built catalogue; at `studio`, `appsec-engineer` reviews the webhook and entitlement paths, `privacy-compliance-specialist` the retention of invoice and payment records, `growth-lifecycle` the dunning journeys, `product-analytics-engineer` the revenue events.

**Billing status** (first match wins): **BLOCKED** — an open S1/S2, a threat-model REJECT, a live key found, card data on a path through our servers, or a key in the licence not in the catalogue; **NOT ASSESSED** — nothing above, but a test layer did not run, the sandbox smoke did not run, tax or invoice facts are `NOT SOURCEABLE`, a price rests on an `ASSUMPTION`, or the parity grep could not run; **COMPLETE WITH GAPS** — everything ran with accepted or listed gaps; **COMPLETE**. `NOT ASSESSED` outranks `COMPLETE` and ranks below `BLOCKED`.

Ask: "May I write the team billing report to `production/qa/evidence/billing-[slug]/team-billing-report.md`?" Write only after a yes; take the date from `date +%F`.

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
- Business inputs unsourced → proceed only with the numbers flagged `ASSUMPTION`; the status cannot reach COMPLETE
- Tax / e-invoicing requirements not sourceable → `/research`; the invoice section stays `NOT SOURCEABLE`
- A `saas-core` billing or licensing module covers the need → `/core-use` first; a product-local mechanism needs a written reason
- Conflict between a commercial request and an entitlement-parity rule → surface it; the catalogue stays the single source

## Output

A summary covering: the commercial change, active set, business inputs and their sources, the approved model and gate outcomes, threat-model verdicts, the payment integration and licence-design results, the parity table and findings, QA results with evidence paths, every `ASSUMPTION` and `NOT SOURCEABLE` item, and the billing status.

Verdict: **COMPLETE** — model, mechanisms and proof delivered with one entitlement source.
Verdict: **COMPLETE WITH GAPS** — everything ran; accepted or listed gaps (a parity finding with a story, an accepted risk) remain, each named.
Verdict: **COMPLETE — [tax facts | sandbox smoke | licence track] NOT ASSESSED ([reason])** — the named check could not run.
Verdict: **BLOCKED** — a blocking cause halted the pipeline; partial report produced.
Verdict: **BLOCKED — write declined by user** — the user declined the model, report or file-set write; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-billing <slug> — <verdict>`, Next step = the first item below (`/create-stories`), plus Blocked on / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED and a declined write.

- `/create-stories` for entitlement port, catalogue storage, metering and webhook-handler stories; `/dev-story`, `/code-review`, `/story-done` per story
- `/observability-plan` (revenue and dunning alerts, reconciliation runbook), `/db-migration` (catalogue and ledger tables), `/security-audit` before release
- `/team-growth` for the lifecycle journeys; `/release-checklist` for the per-release sandbox smoke
