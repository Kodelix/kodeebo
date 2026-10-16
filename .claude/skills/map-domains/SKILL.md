---
name: map-domains
description: "Decompose the product into bounded contexts and features, map dependencies, flag saas-core module candidates, prioritise specification order, create the domain map."
argument-hint: "[next | feature-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Agent, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash "*/.claude/skills/map-domains/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,project.stage,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Map Domains

When this skill is invoked:

## Parse Arguments

Two modes:

- **No argument**: `/map-domains` — Run the full decomposition workflow (Phases 1-5)
  to create or update the domain map.
- **`next`**: `/map-domains next` — Pick the highest-priority unspecified feature
  from the map and hand off to `/design-spec` (Phase 6).
- **`<feature-name>`**: `/map-domains <feature-name>` — Find that feature in the
  map and hand off to `/design-spec` (Phase 6).

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). In collaborative mode the
context list, dependency, priority and write approvals are separate questions:
each waits for its answer before the next step runs.

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = one-line context and feature descriptions;
`balanced` = a brief paragraph per context + dependency notes (`rigor: standard`);
`thorough` = full context-by-context rationale + relationship analysis. Apply it to
every section you author.

> **Where the per-context prose goes.** `templates/domain-map.md`'s
> "Features by Context" table is a fixed-column table with no description
> column, so at `balanced` and `thorough` the prose belongs in `## Overview` —
> one short paragraph per bounded context at `balanced`, plus relationship
> analysis at `thorough` — and in the `## Dependency Map` layer notes. **Do not
> add a column to the tables** — they are a fixed contract in
> `.claude/docs/templates/domain-map.md`; its consumers (`/design-spec`,
> `/create-epics`, `/create-architecture`, `/review-all-specs`) are written against
> the columns it defines. The consumers key on the **`Category`** column of
> "Features by Context" by name, so that column must never be renamed or
> dropped. At `terse`, the tables plus a one-paragraph `## Overview` is the
> whole output.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` / `standard` — required before `/design-spec` (contexts must be mapped
  before per-feature specs are authored).
- `minimal` — not required (the product brief's MVP list and build order replace
  the domain map). Can still be run voluntarily.

---

## Phase 1: Read the Brief (Required Context)

Read the product brief and any existing design work. This provides the raw
material for decomposition.

**Required:**
- Read `design/product-brief.md` — **fail with a clear message if it is not found**:
  > "No product brief found. Run `/brainstorm` first to create one, then come back
  > to decompose it into bounded contexts and features."

**Optional (read if they exist):**
- Read `design/product-principles.md` — principles constrain priority and scope
- Read `design/specs/domain-map.md` — if it exists, **resume** from where it left off
  (update, don't recreate from scratch)
- Glob `design/specs/*.md` — check which feature specs already exist
- Read `docs/stack-reference/pins.yaml` and `project.yaml` (`tenancy`, `distribution`, `core.track`, `stack`) — the tenancy model and delivery model decide which contexts are tenant-scoped, global, or self-hosted-only. If the file or key is absent, say so in the map's Overview ("tenancy: not configured — run `/setup-stack`") rather than assuming a model.
- Glob `docs/architecture/` for ADRs that already fixed a context boundary.

**If the domain map already exists:**
- Read it and present current status to the user
- Use `AskUserQuestion` to ask:
  "The domain map already exists with [N] contexts and [M] features ([K] specified, [J] not started).
  What would you like to do?"
  - Options: "Update the map with new contexts or features", "Specify the next unspecified feature", "Review and revise priorities"

---

## Phase 2: Enumeration (Collaborative)

Extract and identify every bounded context and feature the product needs. This
is the creative core of the skill — it requires human judgment because briefs
rarely enumerate every capability explicitly.

### Step 2a: Extract Explicit Features

Scan the brief for directly mentioned capabilities:
- MVP section (required features = required specs)
- Jobs-to-be-done (each job needs a feature that completes it)
- Pricing model and plans (entitlements and billing are features)
- Distribution (self-hosted implies licensing, installer, update channel)
- Compliance/data (export, delete, retention, audit)

### Step 2b: Identify Implicit Capabilities

For each explicit feature, identify the **hidden capabilities** it implies. A SaaS
product always needs more than the brief mentions. Use this inference pattern:

- "Team workspace" implies: tenancy, user invitations, roles and permissions,
  member removal, ownership transfer, seat limits, audit log
- "Paid plans" implies: plan and entitlement catalogue, checkout, subscription
  lifecycle (trial, upgrade, downgrade, cancel, dunning), invoices and tax/VAT,
  quota enforcement, billing admin UI, webhooks from the payment provider
- "Self-hosted edition" implies: signed licence issue and activation, offline
  grace, installer and upgrade path, customer-run backups, update channel,
  support bundle
- "File uploads" implies: storage, virus/type scanning, size and quota limits,
  signed URLs, retention and deletion, preview
- "Notifications" implies: channel preferences, templates (AR/EN), delivery
  tracking, unsubscribe, rate limits
- "Public API" implies: API keys or OAuth, rate limiting, versioning, webhooks,
  docs, usage metering
- "Mobile app" implies: sign-in and token storage, push, offline sync, app-store
  requirements, deep links, forced-update policy
- "Reporting" implies: aggregation jobs, export (CSV/PDF), scheduled delivery,
  data retention, caching of heavy queries
- Any signed-in surface implies: account settings, profile, session management,
  language (Arabic/English, RTL), data export and account deletion (PDPL/GDPR)

Explain in conversation text why each implicit capability is needed (with examples).

### Step 2c: Group into Bounded Contexts

Group features into **bounded contexts**: each owns its data and its language and
talks to the others through ports, contracts or events. Heuristics:
- One context = one reason to change. If two features change for different reasons (pricing rules vs invoice rendering), they are probably different contexts.
- A table or collection has exactly one owning context; others read it through the owner's port, never its tables.
- Name the ubiquitous-language terms each context owns (for example "Subscription" belongs to Billing, "Membership" to Identity & Access).
- Classify each context's **kind**: *Product-specific* (the core domain the customer pays for), *Generic* (needed but not a differentiator), or *Core module* (provided by `saas-core`).

### Step 2d: Flag `saas-core` Candidates

For each context, decide whether it is a candidate for a shared `saas-core-<track>`
module rather than product code. Typical candidates: identity (users, sessions,
MFA, SSO), OTP, notifications (email/SMS/push), storage, billing, licensing,
tenancy, audit, rate limiting, observability.

Mark each as one of:
- **Consume** — a released core module already covers it; the product depends on it (record the module name and the core version expectation).
- **Extract-candidate** — product code today that should live in core because a second product will need it; note it for `/core-extract`.
- **Product-only** — specific to this product; stays in the product repo.

Re-implementing a core capability inside a product is a review failure
(`coding-standards.md`): if a context looks like a core module but is planned as
product code, say so explicitly and ask the user. If the cores are not yet built
(`core.track` unset or no released version), record the context as
`Consume (pending core)` and list it as a dependency risk rather than silently
planning the work as product code.

### Step 2e: User Review

Present the enumeration organised by bounded context. For each context and
feature, show:
- Name
- Category (Platform / Core domain / Billing & Licensing / Integrations / Admin & Support / Growth / Insights / Client surfaces)
- Brief description (1 sentence)
- Whether it was explicit (from the brief) or implicit (inferred)
- Core-module status (Consume / Extract-candidate / Product-only)

Then use `AskUserQuestion` to capture feedback:
- "Are there contexts or features missing from this list?"
- "Should any of these be combined or split?"
- "Are there items listed that this product does NOT need (out of scope in the brief)?"

**At `collaborative`** — iterate until the user approves the enumeration.
**At `guided`** — ask once, apply the answer, and proceed; do not loop.
**At `autonomous`** — do not ask. Record the enumeration and its inferred items
via `log_decision` and proceed.

> A loop that terminates on "the user approves" has no exit under
> `autonomous` (`automation-modes.md`), which issues no `AskUserQuestion`.

---

## Phase 3: Dependency Mapping (Collaborative)

For each context and feature, determine what it depends on. A feature "depends
on" another if it cannot function without that other existing first.

### Step 3a: Map Dependencies

List dependencies using these heuristics:
- **Data dependencies**: A produces data B needs (plan entitlements → feature gating)
- **Structural dependencies**: A provides the framework B plugs into (tenancy, identity → everything tenant-scoped)
- **Event dependencies**: A's state change triggers B (subscription cancelled → access downgrade, data-export window)
- **Presentation dependencies**: every screen depends on the feature it exposes, but screens are specified after the feature
- **Provider dependencies**: a payment, SMS, email or storage provider the feature calls

### Step 3b: Sort by Dependency Order

Arrange into layers:
1. **Foundation**: tenancy, identity, authorization model, audit log, configuration
2. **Core**: the product's primary domain entities and workflows, plan/entitlement catalogue
3. **Feature**: capabilities built on the core domain (invitations, reporting, integrations, billing flows)
4. **Presentation**: app shell, dashboards, mobile surfaces, marketing site
5. **Hardening**: observability dashboards, admin/support tooling, data export/delete, analytics

### Step 3c: Detect Circular Dependencies

Check for cycles in the dependency graph. If found:
- Highlight them to the user
- Propose resolutions: an event or port at the boundary, merging the two features into one spec, or splitting a context

### Step 3d: Ownership and Data Boundaries

Fill the "Ownership & Data Boundaries" table: for each major entity or
capability, the single owning context, which contexts read it, and the access
path (API, event, read model). Flag:
- an entity claimed by two contexts (resolve now — it is a tenancy and consistency bug later);
- a cross-context read that would go through the owner's tables instead of its port;
- which contexts are **tenant-scoped** and which are **global** (plans, licences, platform admin), with how the tenant context reaches each.

### Step 3e: Present to User

Show the dependency map as a layered list. Highlight:
- Any circular dependencies
- Any "bottleneck" contexts or features (many others depend on them — high risk)
- Any features with no dependents (leaf nodes — lower risk, can be specified late)
- Any context that owns more than one reason to change (God-context risk)

Use `AskUserQuestion` to ask: "Does this dependency ordering look right? Any
dependencies I'm missing or that should be removed?"

**Review mode check** — apply before spawning CTO-CONTEXT-BOUNDARY:
- `solo` → skip. Note: "CTO-CONTEXT-BOUNDARY skipped — Solo mode." Proceed to priority assignment.
- `lean` → skip (not a PHASE-GATE). Note: "CTO-CONTEXT-BOUNDARY skipped — Lean mode." Proceed to priority assignment.
- `full` → spawn as normal.

**After dependency mapping is approved, spawn `cto` via `Agent` using gate CTO-CONTEXT-BOUNDARY (`.claude/docs/director-gates/cto-context-boundary.md`) before proceeding to priority assignment.**

Pass: the dependency graph (each context/feature → what it depends on), layer assignments, bottleneck items, any circular dependencies with their proposed resolutions, the data ownership table, and `tenancy.model` from `project.yaml` (or "not configured").

Present the assessment. If REJECT, revise the context boundaries with the user, show the revised dependency map, and only then move to priority assignment. If CONCERNS, note them inline in the domain map and continue. If NOT ASSESSED [missing input], it is not an APPROVE: name what was missing, then supply it and re-run the gate, or continue with `CTO-CONTEXT-BOUNDARY: NOT ASSESSED — [input]` noted in the map draft.

---

## Phase 4: Priority Assignment (Collaborative)

Assign each feature to a priority tier based on what milestone it is needed for.

### Step 4a: Auto-Assign Based on the Brief

Use these heuristics for initial assignment:
- **MVP**: Features in the brief's MVP list, plus their Foundation-layer dependencies (tenancy, identity, plan enforcement are almost always MVP if the product is multi-tenant and paid)
- **Vertical Slice**: Features needed to prove the architecture end to end for one journey (DB → API → web/mobile → deploy)
- **Beta**: All remaining functional scope
- **Full Vision**: Polish, edge cases, nice-to-have and growth features

### Step 4b: User Review

Present the priority assignments in a table. For each tier, explain why features
were placed there.

Use `AskUserQuestion` to ask: "Do these priority assignments match your plan?
Which features should be higher or lower priority?"

Explain reasoning in conversation: "I placed [feature] in MVP because the core
journey requires it — without [feature], [job-to-be-done] cannot complete."

**How to phrase the reasoning** — this governs what you *say*, not a column you
write. Neither table has a `Why` column. The rationale lives in the conversation
above and, for anything the user should still see after the session, in the
map's `## Overview` paragraph. Do not invent a column for it.

Mix technical necessity with customer-value reasoning, and cite the principle or
job it serves. Good reasoning names both:
- "Required for [core job] — without it the customer's main task has no outcome (Principle [N]: [principle name])"
- "Foundation for every plan decision — entitlements must exist before any feature can be gated"
- "Needed to sell: no way to charge means no revenue test of [pricing hypothesis]"

> **Fill the brackets from *this* product.** Worked examples from another
> product get reproduced verbatim by a run against a different one, which then
> carries that product's vocabulary instead of its own.

**Review mode check** — apply before spawning PR-SCOPE:
- `solo` → skip. Note: "PR-SCOPE skipped — Solo mode." Proceed to Step 4c.
- `lean` → skip (not a PHASE-GATE). Note: "PR-SCOPE skipped — Lean mode." Proceed to Step 4c.
- `full` → spawn as normal.

**After priorities are approved, spawn `producer` via `Agent` using gate PR-SCOPE (`.claude/docs/director-gates/pr-scope.md`) before writing the map.**

Pass the gate's fields from the map: the full vision scope (every feature), the MVP definition (the MVP tier's features), the scope tiers (feature count per tier, with estimated implementation volume — feature count × average complexity), the stated timeline as the timeline estimate, and team size.

Present the assessment. PR-SCOPE answers REALISTIC / OPTIMISTIC / UNREALISTIC.
If UNREALISTIC, offer to revise priority tier assignments before writing the
map. If OPTIMISTIC, show the producer's suggested adjustments and ask whether to
apply them to the tiers before writing; if the user declines, note them and
continue. If NOT ASSESSED [missing input] — often team size or timeline — it
is not a REALISTIC: name what was missing, then supply it and re-run the gate, or
continue with `PR-SCOPE: NOT ASSESSED — [input]` noted in the map draft.

### Step 4c: Determine Specification Order

Combine dependency sort + priority tier to produce the final order:
1. MVP Foundation features first
2. MVP Core features second
3. MVP Feature-layer features third
4. Vertical Slice Foundation/Core features
5. ...and so on

This is the order the team should write specs in.

### Step 4d: Mark Sensitive and High-Risk Features

For each feature, mark whether it touches an area that requires a threat model
(from `.claude/docs/security-baseline.md`): authentication, authorization model,
billing, licensing, file upload, webhooks, PII export/delete, admin or
impersonation, a new external integration. Fill "Features needing a threat model"
in the progress tracker and list technically unproven or provider-dependent items
under "High-Risk Areas" with a mitigation (research note, prototype, threat model,
scope fallback).

---

## Phase 5: Create the Domain Map (Write)

### Step 5a: Draft the Document

Using the template at `.claude/docs/templates/domain-map.md`, populate the map
with all data from Phases 2-4:
- Fill "Bounded Contexts" (including the Core module column)
- Fill "Features by Context" (every feature gets a spec path `design/specs/<feature>.md` to be written, or "—" when no spec is required at the tier)
- Fill the dependency map, ownership and data boundaries
- Fill the recommended specification order
- Fill the high-risk areas
- Fill the progress tracker (all features "Not Started" initially, unless specs already exist)

### Step 5b: Approval

Present a summary of the document:
- Total contexts and features by category
- MVP feature count
- Core-module consumers and extract-candidates
- First 3 features in the specification order
- Any high-risk items and features that need a threat model

**At `automation: collaborative`** — ask: "May I write the domain map to
`design/specs/domain-map.md`?" Wait for approval. Write the file only after
"yes."

**At `automation: guided`** — a **new** map gets the same "May I write …?"
question, because `.claude/docs/automation-modes.md` has `guided` ask "May I
write?" for new files. When the map already exists, present the summary above,
name the destination (`design/specs/domain-map.md`), and write the update without
waiting for an explicit "yes". Say what you wrote afterwards.

**At `automation: autonomous`** — write directly and record the decision via
`log_decision` (a domain-map append is `minor`).

**Review mode check** — apply before spawning PD-FEATURES:
- `solo` → skip. Note: "PD-FEATURES skipped — Solo mode." Proceed to Step 5c.
- `lean` → skip (not a PHASE-GATE). Note: "PD-FEATURES skipped — Lean mode." Proceed to Step 5c.
- `full` → spawn as normal.

**After the domain map is written, spawn `product-director` via `Agent` using gate PD-FEATURES (`.claude/docs/director-gates/pd-features.md`).**

Pass: domain map path; product principles, ICP and core value from `design/product-brief.md` (and `design/product-principles.md` if present); the priority tier assignments for every tier (MVP / Vertical Slice / Beta / Full Vision); and the high-risk and bottleneck items from the dependency map.

Present the assessment. If REJECT, revise the feature set with the user before spec authoring begins. If CONCERNS, show them and use `AskUserQuestion`: `Revise the feature set` / `Accept — record them in the map` / `Discuss further`. On *Revise*, rework the affected items with the user and ask again before re-writing the map. On *Accept* — the option names the edit, so choosing it is the ask — record them in the domain map as a `> **Product Director Note**` placed **directly beneath the `## Priority Tiers` table**, naming the tier each concern applies to — e.g. `> **Product Director Note** (MVP): …`. If NOT ASSESSED [missing input], it is not an APPROVE (`.claude/docs/director-gates.md`): name what was missing, then supply it and re-run the gate, or ask before recording `> **Product Director Note**: PD-FEATURES NOT ASSESSED — [input]` in the same place.

### Step 5c: Update Session State

After writing, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md` (create it from the template if it does not
exist): Current task `/map-domains — domain map created`, Next step = the first
Recommended Next Step (`/design-spec` for the first feature in the map's order),
Files in progress `design/specs/domain-map.md`, plus Blocked on / Open questions;
append the Notes line. A declined write still updates the checkpoint with the
blocker.

**Verdict: COMPLETE** — domain map written to `design/specs/domain-map.md`.
If the user declined: **Verdict: BLOCKED — write declined by user.**

---

## Phase 6: Specify Individual Features (Handoff to /design-spec)

This phase is entered when:
- The user says "yes" to specifying features after creating the map
- The user invokes `/map-domains <feature-name>`
- The user invokes `/map-domains next`

### Step 6a: Select the Feature

- If a feature name was provided, find it in the domain map
- If `next` was used, pick the highest-priority unspecified feature (by specification order)
- If the user just finished the map, ask:
  "Would you like to start specifying individual features now? The first feature in
  the order is [name]. Or would you prefer to stop here and come back later?"

Use `AskUserQuestion` for: "Start specifying [feature-name] now, pick a different
feature, or stop here?"

### Step 6b: Hand Off to /design-spec

Once a feature is selected, invoke the `/design-spec [feature-name]` skill.

The `/design-spec` skill handles the full spec authoring process:
- Gathers context from the product brief, domain map, and dependency specs
- Creates a file skeleton immediately
- Walks through the sections required at the effective tier, one at a time (collaborative, incremental)
- Cross-references existing docs to prevent contradictions
- Routes to specialist agents for domain expertise
- Writes each section to file as soon as it is approved
- Runs `/spec-review` when complete
- Updates the domain map

**Do not duplicate the /design-spec workflow here.** This skill owns the domain
*map*; `/design-spec` owns individual feature *specs*.

### Step 6c: Loop or Stop

After `/design-spec` completes, use `AskUserQuestion`:
- "Continue to the next feature ([next feature name])?"
- "Pick a different feature?"
- "Stop here for this session?"

If continuing, return to Step 6a.

---

## Phase 7: Suggest Next Steps

After the domain map is created (or after specifying some features), present next actions using `AskUserQuestion`:

- "Domain map is written. What would you like to do next?"
  - [A] Start specifying — run `/design-spec [first-feature-in-order]`
  - [B] Run `/threat-model [feature]` for the sensitive features flagged in the map before they are specified
  - [C] Run `/gate-check` — the Product Design → Architecture gate, once the MVP specs exist
  - [D] Stop here for this session

CTO-CONTEXT-BOUNDARY and PD-FEATURES are this skill's own gates — they run here
in `full` review mode, not in `/gate-check`.

After any individual spec is completed:
- "Run `/spec-review design/specs/[feature].md` in a fresh session to validate quality"
- "Run `/review-all-specs` when all MVP specs are complete"
- "Run `/create-architecture` once the specs and domain map are approved"

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behaviour.

This skill follows the collaborative design principle at every phase:

1. **Question -> Options -> Decision -> Draft -> Approval** at every step
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Missing items? Combine or split? Core-module status right?"
   - Phase 3: "Dependency ordering and data ownership correct?"
   - Phase 4: "Priority assignments match your plan?"
   - Phase 5: "May I write the domain map?"
   - Phase 6: "Start specifying, pick different, or stop?" then hand off to `/design-spec`
3. **"May I write to [filepath]?"** before every file write
4. **Incremental writing**: Update the map after each feature is specified
5. **Handoff**: Individual spec authoring is owned by `/design-spec`
6. **Session state updates**: Write to `production/session-state/active.md` after
   each milestone (map created, feature specified, priorities changed)
7. **A check that did not run is reported as not run**: a skipped or
   NOT ASSESSED gate, an unread input (`pins.yaml`, tenancy not configured) and a
   core module whose release could not be confirmed are each named in the map's
   Overview, never silently omitted.

**Never** auto-generate the full list and write it without review.
**Never** start specifying a feature without user confirmation.
**Always** show the enumeration, dependencies, ownership and priorities for user validation.

## Context Window Awareness

If context reaches or exceeds 70% at any point, append this notice:

> **Context is approaching the limit (≥70%).** The domain map is saved to
> `design/specs/domain-map.md`. Open a fresh Claude Code session to continue
> specifying individual features — run `/map-domains next` to pick up where you left off.

---

## Recommended Next Steps

- Run `/design-spec [first-feature-in-order]` to author the first spec (use the order from the map)
- Run `/map-domains next` to always pick the highest-priority unspecified feature automatically
- Run `/threat-model [feature]` for each feature the map marks as needing one
- Run `/spec-review design/specs/[feature].md` in a fresh session after each spec is authored
- Run `/review-all-specs` when all MVP specs are authored and reviewed
