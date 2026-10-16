---
name: team-growth
description: "Orchestrate the growth team — growth-lifecycle, pricing-billing-designer, product-analytics-engineer, customer-success — to plan an activation, onboarding, retention, churn-save or dunning initiative, with business-director inputs when pricing or offers change."
argument-hint: "[growth initiative or lifecycle journey description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Skill, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash "*/.claude/skills/team-growth/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Growth

**Argument check:** If no initiative or journey description is provided, output:
> "Usage: `/team-growth [growth initiative or lifecycle journey description] [--review full|lean|solo]` — Provide the initiative to plan (e.g., `trial-to-paid journey`, `failed-payment dunning`, `onboarding checklist experiment`, `annual-plan offer`)."
Then stop immediately without spawning any subagents or reading any files.

When this skill is invoked with a valid argument, orchestrate the growth team through a structured planning pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns a PD-, CTO-, PR- or DD-PHASE-GATE, at any `review_mode`.
Its phase gates are the pipeline's own decision points (defined under
`team.size` below), and the agents that work at them are team members, not
director gates. A plan that changes prices, plans or entitlements is a product
decision: `product-director` signs off plan/pricing strategy (Phase 7) — that is
an approval request to the user, not a gate spawn.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behaviour.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `growth-lifecycle` + `pricing-billing-designer`. Other agents consulted via these two, not spawned separately.
- **`small`**: + `product-analytics-engineer` + `customer-success`.
- **`studio`**: + `ux-designer` (journey microcopy, Arabic and English) + `localization-lead` + `privacy-compliance-specialist` (the full pipeline as documented).
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode.** `guided` and `autonomous` change how a gate is passed (it auto-advances, or is recorded with `log_decision`), not whether it is one, so bounded-exception condition (3) below holds at it in every mode. An agent restricted to "phase gates only" is spawned at those points and no others. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Business inputs are not a team member.** `business-director` is consulted in
Phase 2 only when the initiative changes prices, plans, trials, discounts or
offers, at any `team.size`. See Phase 2.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is two agents. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever. Without saying so, a reader cannot distinguish
a correctly-collapsed run from a broken pipeline, and the per-agent "routes
through the nearest core agent with an informational note" rule fires at routing
time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a
constraint that is enforced but never surfaced is indistinguishable, to the
person reading the output, from one that was never enforced.**

## Team Composition
- **growth-lifecycle** — Activation definition, onboarding and lifecycle journeys, trial-to-paid path, dunning and churn-save journeys, experiment design, copy rules
- **pricing-billing-designer** — Plans, entitlements, trials, coupons, dunning rules, tax/VAT presentation, revenue and abuse checks (the economics of the initiative)
- **product-analytics-engineer** — Success metrics, funnels, experiment instrumentation, event taxonomy, dashboards, privacy-safe tracking
- **customer-success** — Customer communication, support readiness, release notes for lifecycle changes, feedback synthesis
- **ux-designer** *(studio)* — Journey microcopy and in-product message placement, English and Arabic intent
- **localization-lead** *(studio)* — Arabic/English message quality, RTL, formats (EGP, SAR, AED)
- **privacy-compliance-specialist** *(studio)* — Consent, lawful basis, retention and opt-out for the messaging and tracking in the plan
- **business-director** *(conditional, Phase 2)* — Sourced market, price and offer inputs under `.claude/docs/business-research-protocol.md`

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: growth-lifecycle` — Journeys, activation, experiments, copy rules
- `subagent_type: pricing-billing-designer` — Plans, trials, coupons, dunning and revenue economics
- `subagent_type: product-analytics-engineer` — Success metrics and instrumentation
- `subagent_type: customer-success` — Customer communication and support readiness
- `subagent_type: ux-designer` — Journey microcopy (studio)
- `subagent_type: localization-lead` — Arabic/English review (studio)
- `subagent_type: privacy-compliance-specialist` — Consent and privacy review (studio)
- `subagent_type: business-director` — Sourced business inputs when pricing/offers change (Phase 2)

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**Substitute a real path for `[path]`.** Working artifacts go under
`production/growth/[initiative-slug]/`, where `[initiative-slug]` is the argument
as a slug — lowercase, spaces → hyphens. One file per agent, so the parallel
phases never share one:

| Phase / agent | Writes to |
|---|---|
| 1 growth-lifecycle | `production/growth/[initiative-slug]/brief.md` |
| 2 business-director | `production/growth/[initiative-slug]/business-inputs.md` |
| 3 pricing-billing-designer | `production/growth/[initiative-slug]/economics.md` |
| 4 product-analytics-engineer | `production/growth/[initiative-slug]/analytics.md` |
| 5 growth-lifecycle | `production/growth/[initiative-slug]/journeys.md` |
| 5 ux-designer | `production/growth/[initiative-slug]/microcopy.md` |
| 5 localization-lead | `production/growth/[initiative-slug]/localization-review.md` |
| 6 customer-success | `production/growth/[initiative-slug]/comms.md` |
| 7 privacy-compliance-specialist | `production/growth/[initiative-slug]/privacy-review.md` |

These are working drafts; the final documents under `design/growth/` are compiled
from them (Output Documents).

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (Phases 3 and 4 can run simultaneously) — issue every independent `Agent` call before waiting for any result, collect all results, and surface any BLOCKED agent immediately (`.claude/docs/coordination-rules.md`, Parallel Task Protocol).

**Rules that hold for every phase.** Never state a benchmark, conversion rate,
price, tax rate, legal rule or provider behaviour from memory: the research note,
the analytics data, the billing source of truth and the owner win; a figure with
no source is written `NOT SOURCEABLE — [what] is not covered by [path]`.
Self-hosted editions: telemetry is off by default and no lifecycle message,
experiment or tracking runs in a customer-hosted install unless the customer
opted in — say which editions the initiative applies to (hosted / self-hosted /
mobile) and name the ones it does not.

## Pipeline

### Phase 1: Initiative Scoping
Delegate to **growth-lifecycle**:
- Read `design/product-brief.md` (value metric, pricing model), `design/growth/` (existing activation definition, journeys and experiments), the relevant `design/specs/`, `docs/analytics/tracking-plan.md` if it exists, and `PRODUCT.md` for audience and voice
- Define the initiative: type (activation/onboarding, trial-to-paid, expansion, retention, churn-save, dunning, win-back, offer), the segment, the funnel stage, the hypothesis and the single primary metric
- Confirm or propose the **activation definition** (event or sequence, window, unit tenant or user) — if none is committed, say so and propose one, flagged as unconfirmed
- Outline the journey list and channels (in-product, email, push, SMS, support-assisted) and which editions are in scope
- Flag whether the initiative **changes prices, plans, trials, discounts or offers** — that flag decides whether Phase 2 runs
- Identify the resource budget: engineering effort (stories), copy volume, support load
- Output: initiative brief with scope, hypothesis, segment, journey list and the pricing/offer-change flag

### Phase 2: Business Inputs (conditional)
Runs **only if** the Phase 1 brief flags a price, plan, trial, discount or offer change. Otherwise record `Business inputs: not run — no pricing/offer change` and continue.

Delegate to **business-director** (which routes to `pricing-strategist` and `market-researcher`; this is an input source, not a gate):
- Under `.claude/docs/business-research-protocol.md`: every number carries value + unit + currency, source and tier, date, and scope; markets in scope are Egypt and GCC/MENA; EGP, SAR and AED prices are stated per market; VAT inclusive/exclusive is explicit
- Answer the specific questions in the brief: competitor and market price levels, willingness-to-pay evidence, discount/offer norms and how comparable products handle trials, annual-vs-monthly and one-time vs subscription (including self-hosted licence economics)
- A number it cannot source is returned as `NOT SOURCEABLE`, never estimated
- Output: sourced business inputs with a recommendation for the pricing model, which `pricing-billing-designer` then receives

If `business-director` cannot run, or returns only unsourced figures, the pricing and offer elements of the plan are **NOT ASSESSED** and are not carried into the final plan as decided; the report says so by name. A pricing change is also a `product-director` decision: it needs the user's explicit approval in Phase 7.

### Phase 3: Economics and Billing Rules (parallel with Phase 4)
Delegate to **pricing-billing-designer**:
- Read the Phase 1 brief, the Phase 2 inputs (if any), `design/specs/pricing-model.md` / `business/pricing/` if they exist, and `design/registry/entities.yaml` (plans, entitlements, quotas)
- Design the mechanics the initiative needs: trial length and conversion rules, coupon/offer terms, annual/monthly switching, proration, upgrade/downgrade, **dunning schedule and grace periods**, cancellation and reactivation, entitlement behaviour in each billing state, tax/VAT presentation (rates and rules sourced from the official source, never recalled)
- Currencies and rounding for EGP, SAR and AED; prices and limits are config/data, never hard-coded
- Check revenue impact and margin on the segment, plus **abuse paths** (trial farming, coupon stacking, downgrade-after-use, tenant creation loops) — the orchestrator then runs `/pricing-check` (through `Skill`) on the designer's proposed change and passes the result back
- State what the billing system and integrations can and cannot do today, as stories for `integrations-engineer` and the stack lead; anything unsupported is flagged, not assumed
- Verify the customer is never charged or locked out without notice, and that nothing about renewal, cancellation or price is hidden or confusing
- Output: economics doc with plan/entitlement changes, billing-state table, dunning/trial rules, revenue and abuse check, and the list of engineering stories needed

### Phase 4: Analytics and Success Metrics (parallel with Phase 3)
Delegate to **product-analytics-engineer**:
- Read the Phase 1 brief and `docs/analytics/tracking-plan.md` if it exists
- Define success metrics: activation rate within the window, trial-to-paid, retention at defined intervals, recovered revenue (dunning), churn-save rate — each with numerator, denominator, window, segment and source events
- Design experiments: hypothesis, unit of randomisation (tenant, not user, for B2B), sample size and duration **from the real baseline** (a missing baseline is `NOT SOURCEABLE`, not a guess), guardrail metrics (support volume, refunds, cancellations), stopping rule
- Specify the events needed (object_action, snake_case, past tense), server-side for anything money- or entitlement-related; client events carry **no PII** and respect consent; self-hosted off by default
- Output: analytics plan with success criteria, experiment design and instrumentation requirements

### Phase 5: Journeys and Message Content (parallel)
Start only after both Phase 3 and Phase 4 results are collected. Delegate in parallel:
- **growth-lifecycle**: Write the lifecycle journeys — trigger, audience, channel, cadence, copy intent, exit condition and **suppression rules** (do not message a customer who already converted, who is in a support escalation, or who opted out), aligned to the economics and metrics
- **ux-designer** *(studio; otherwise growth-lifecycle drafts and flags it unreviewed)*: Microcopy for the in-product moments (checklists, empty states, upgrade prompts, banners), with English and Arabic intent
- **localization-lead** *(studio)*: Review the Arabic and English message text — natural Arabic, plurals, RTL, numerals, and amounts in EGP/SAR/AED formatted correctly. Without it, all Arabic is marked **draft pending native review**
- All should read the economics and analytics outputs. Messaging copy states prices and dates from the billing source of truth, never typed by hand

### Phase 6: Customer Communication Plan
Delegate to **customer-success**:
- Read the brief, economics and journeys
- Draft the customer communication for any change customers will notice: announcement (email, in-app, help centre), what changes for whom and from when (affected plans, effective date, what to do), FAQ and support macros, and the escalation path
- Plan the cadence: advance notice for any price or plan change (the notice period comes from the contract/terms and the owner, not from memory), launch message, follow-up, and a known-issues placeholder
- Prepare support readiness: expected question volume and who is on cover, including Arabic-speaking support
- Output: communication calendar with draft copy in English and Arabic for each touchpoint

### Phase 7: Review and Sign-off
Collect outputs from all phases and present a consolidated growth plan:
- Initiative brief (Phase 1)
- Business inputs, if run (Phase 2)
- Economics and billing rules (Phase 3)
- Analytics plan and experiment design (Phase 4)
- Journeys and message content (Phase 5)
- Communication calendar (Phase 6)

Present a summary to the user with:
- **Scope**: what is being created, for which editions and segments
- **Economics check**: revenue and margin impact, abuse paths, and what the billing system cannot yet do
- **Analytics readiness**: are success criteria, baselines and guardrails defined and instrumented?
- **Privacy and consent check** *(studio: `privacy-compliance-specialist`)*: every message and tracking item has a lawful basis/consent, an opt-out and a retention note. Without that agent, record `Privacy review: not run (team.size: [size])` — consent is an open item the user must confirm, never a pass
- **Ethics review**: check the plan against `design/growth/ethics-policy.md`
  - If the file does not exist: the review is **NOT ASSESSED**, not skipped silently. Flag "ETHICS REVIEW NOT ASSESSED: `design/growth/ethics-policy.md` not found. The plan was not reviewed against a written ethics policy." and carry it into the output document. Still apply the baseline checks below and report their results. Add to next steps: create `design/growth/ethics-policy.md`.
  - Baseline checks (run in every case): no fake urgency or scarcity; no hidden, pre-ticked or hard-to-find cancellation, opt-out or renewal terms; no charge or auto-renewal the customer was not clearly told about; dunning does not threaten, shame or lock out customers' own data; trial-to-paid and win-back copy is truthful about price, limits and dates; no dark patterns around data export or account deletion; no messaging to customers who opted out
  - If a policy or baseline violation is found: flag "ETHICS FLAG: [element] violates [policy rule / baseline check]. Approval is blocked until this is resolved." Do NOT issue a COMPLETE verdict or write output documents. Use `AskUserQuestion` with options: revise the plan / override with documented rationale / cancel. If the user chooses to revise: re-spawn the owning agent to produce a corrected design, then return to Phase 7 review. If the user selects Cancel: end with Verdict: BLOCKED — "Growth plan cancelled due to unresolved ethics violation. Resolve the flagged issues and re-run /team-growth."
- **Pricing/offer sign-off**: if the plan changes prices, plans or offers, `product-director` approval is requested from the user (strategy sign-off) and the business inputs are cited; otherwise unneeded
- **Open questions**: decisions still needed before production begins

Ask the user to approve the growth plan before delegating to the production teams. Issue the COMPLETE verdict only after the user approves and no unresolved ethics violations remain. If an ethics violation is unresolved, end with Verdict: **BLOCKED**.

## Output Documents

All final documents save under `design/growth/` — **but the orchestrator asks
before writing them.** `design/` is NOT one of the three directories the bounded
write exception covers (`production/`, `docs/`, test directories), so a sub-agent
handed one of these paths must prompt. Do not widen the exception to silence that.
Sub-agents write their working artifacts under `production/growth/`, where the
exception does reach them; **you** compile the final documents and ask via
`AskUserQuestion` — "May I write the growth plan to `design/growth/…`?" — writing
them only on approval.

Paths:
- `design/growth/[initiative-slug].md` — Growth plan: brief, journeys, economics summary (from Phases 1–3 and 5)
- `design/growth/experiments/[experiment-id].md` — One file per experiment (hypothesis, unit, sample, guardrails, stopping rule — from Phase 4)
- `design/growth/[initiative-slug]-comms.md` — Communication calendar (from Phase 6)
- Tracking-plan changes are proposed in `production/growth/[initiative-slug]/analytics.md`; applying them to `docs/analytics/tracking-plan.md` is an edit to an existing file and needs its own approval
- Plan, entitlement or price changes are **not** applied here: they become stories (`/create-stories`) and, for pricing, go through `/pricing-check` and the owner's decision

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is usually still
there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap — never fill it with content of your own. Full procedure: `.claude/docs/error-recovery-protocol.md`.

If a BLOCKED state is unresolvable, end with Verdict: **BLOCKED** instead of COMPLETE.

## File Write Protocol

Sub-agents write their working artifacts under `production/`, following the
**bounded exception** documented above under "Why this does not violate the
Collaboration Protocol" — the path is one you named, the artifact is new under
`production/`, `docs/` or a test directory, and the phase is gated by an
`AskUserQuestion`. A sub-agent does **not** prompt per write inside those bounds;
outside them it must ask. The **final documents under `design/growth/`** are the
exception: the orchestrator compiles and writes them itself after its own "May I
write …?" prompt (Output Documents above). Nothing here sends a message to a
customer, changes a price or plan, or starts an experiment — those are separate,
explicit decisions after the plan is approved.

## Output

A summary covering: initiative scope and editions, economics highlights (with business inputs sourced or NOT ASSESSED), success metrics and experiment design, journeys and content inventory, communication plan, privacy and ethics review status, and any open decisions needing user input before production.

Verdict: **COMPLETE** — growth plan produced and handed off for production.

If the ethics review (no `design/growth/ethics-policy.md`), the privacy review (agent not active) or the pricing inputs (no sourced business inputs) were NOT ASSESSED, the verdict names each one — never a plain COMPLETE:

Verdict: **COMPLETE — [ethics review | privacy review | pricing inputs] NOT ASSESSED ([reason])** — plan produced; the named check could not run.

Verdict: **BLOCKED** — an unresolved ethics violation, a cancelled plan, or an unresolvable blocker.

Verdict: **BLOCKED — write declined by user** — the user declined the final-document write; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-growth <initiative> — <verdict>`, Next step = the first item below that applies (the ethics-flag revision when BLOCKED), plus Blocked on / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED, NOT ASSESSED and a declined write.

- Run `/spec-review` or `/quick-spec` on the feature changes the plan requires, then `/create-stories` for the billing, journey and instrumentation work.
- Run `/pricing-check` on any plan, entitlement or price change before it is built.
- Run `/sprint-plan` to schedule the work (at `workflow: minimal`, which has no sprints, add it to the product brief's build order instead).
- Run `/team-billing` for billing mechanics and `/team-release` when the work is ready to deploy; announce through `/release-notes`.
- If the run ended **BLOCKED** on an ethics flag: revise the plan against `design/growth/ethics-policy.md` and the baseline checks and re-run `/team-growth`; the steps above wait for a COMPLETE plan.
- If the ethics review was NOT ASSESSED: create `design/growth/ethics-policy.md` before production begins.
