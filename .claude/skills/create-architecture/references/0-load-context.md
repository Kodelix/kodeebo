# /create-architecture — Phase 0: Load All Context

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 0: Load All Context

**In this file:**

- 0a. Stack Context (Critical)
- 0b. Product Context + Technical Requirements Extraction
- 0c. Existing Architecture Decisions
- 0d. Generate Stack-Risk Inventory
- 0e. Existing Architecture Document

Before anything else, load the full project context in this order:

### 0a. Stack Context (Critical)

The stack is resolved from the config block above (`stack`, `deploy`,
`distribution`, `tenancy`) and `project.yaml` (`core.*`, `layout.code_roots`).
Never assume a layer that is not configured.

If the block shows no stack, or `distribution` / `tenancy` is empty, stop and prompt:
> "The stack is not configured. Run `/setup-stack` first. Architecture cannot be
> written without knowing the backend track, data stores, tenancy model and
> distribution model you are targeting."

For **each configured layer** (backend, web, site, mobile, each data store,
messaging, deploy) read, in full — they are small and every part is used:

1. `docs/stack-reference/<layer>/VERSION.md` → pinned version, sources, risk level, licence notes
2. `docs/stack-reference/<layer>/breaking-changes.md` → every HIGH and MEDIUM risk change
3. `docs/stack-reference/<layer>/deprecated-apis.md` → APIs and patterns to avoid
4. `docs/stack-reference/<layer>/best-practices.md` → the sections matching the concerns this architecture decides (for example portability for a cache, RLS for Postgres, supply-chain settings for the SPA)

Then read `docs/stack-reference/pins.yaml` — the machine-readable minimums.
Every version the architecture names must agree with it, or the divergence is
recorded as a finding.

**A layer with no reference directory** (for example `messaging` chosen as `nats`
with nothing under `docs/stack-reference/`) is `NOT SOURCEABLE — <layer> is not
covered by docs/stack-reference/`. Do not fill it from memory. Record it as a
stack-risk finding for Phase 0d and as a research item (`/research`) that must
finish before the ADR for that layer is Accepted.

Also read, once: `.claude/docs/clean-architecture.md`, `.claude/docs/api-standards.md`,
`.claude/docs/security-baseline.md`, `.claude/docs/caching-standard.md`,
`.claude/docs/observability-standard.md`, `.claude/docs/performance-standard.md`,
`.claude/rules/deploy.md` and, if the core is used, `core.track`, `core.modules`
and `core.version` from `project.yaml`. Licence decisions (cache, Mongo,
observability in customer bundles) are in `.claude/docs/standing-decisions.md`.

### 0b. Product Context + Technical Requirements Extraction

Load the approved product documents and extract technical requirements from each:

1. `design/product-brief.md` — ICP, pricing model, distribution, build order
2. `design/specs/domain-map.md` — all bounded contexts and features, dependencies, priority tiers

**Check both exist before reading either. Neither is optional at `standard`/`full`,
and both need an absence branch:**

- **`domain-map.md` absent** — stop:
  > "No domain map found. Run `/map-domains` first. An architecture written
  > without it invents contexts nobody mapped, and every ADR, epic and
  > story downstream inherits that invention."
  At `minimal` the map is not required — say so and proceed from the brief instead.
- **`product-brief.md` absent** — stop and point at `/brainstorm`. There is no
  product record to architect against.
- **Either present but empty or still template placeholders** — treat as absent.
  Present-but-empty is the case that most looks like present.

Do not proceed on a partial read and note it later. This phase is where product
assumptions get baked into ADRs, and an assumption made here is re-derived by
everything downstream rather than re-checked.

3. Project config — `stack`, `deploy`, `distribution`, `tenancy`, `core`,
   `performance.enforce`, `accessibility.target`
4. **Every feature spec in `design/specs/`** — extract technical requirements
   from the sections that carry them, **not from whole files**. Establish the
   denominator first (glob `design/specs/*.md` excluding `domain-map.md`, count
   **N**), then:
   ```
   Grep pattern="^## (Detailed Behaviour|Data & Contracts|Edge Cases|Dependencies|Non-Functional|Acceptance Criteria)" glob="design/specs/*.md" output_mode="content" -A 40
   ```
   Overview and User Value are narrative and imply little architecture; the
   scanned set is where rules, entities, contracts, budgets and cross-context
   dependencies live.

   Full-read a spec when it matched **zero** sections (it predates the template —
   a zero-match means "unstructured", never "no requirements") or when a scanned
   section refers to material outside itself. **Never treat an absent section as
   an absent requirement**: report any spec that contributed nothing, rather than
   letting it drop silently out of the baseline below.

   For each, extract:
   - Entities and ownership the rules imply (which context owns which data)
   - Tenancy and permission rules (who may see or change what, per role and plan)
   - Performance constraints stated or implied (budgets from `docs/architecture/perf-budgets.md`)
   - Cross-context communication (what calls what, sync or async)
   - External providers (payments, SMS, email, storage, push, OAuth) and their failure modes
   - State that must persist, retention, export and delete rules (PII)
   - Async work: jobs, schedules, webhooks in and out, retries
   - Security-sensitive areas (auth, billing, licensing, upload, webhooks, PII, admin) — each needs a threat-model path
   - Distribution constraints: features that must work offline, air-gapped or in the self-hosted edition
   - Clients affected: web, Android, iOS, KMP, public API

Build a **Technical Requirements Baseline** — a flat list of all extracted
requirements across all specs, numbered `TR-[feature]-NNN`, the TR registry's
ID format (`docs/architecture/tr-registry.yaml`, read it if present so existing IDs
are reused, not renumbered). This is the complete set of what the architecture
must cover. Present it as:

```
## Technical Requirements Baseline
Extracted from [N] specs | [X] total requirements

| Req ID | Spec | Context | Requirement | Domain |
|--------|------|---------|-------------|--------|
| TR-billing-001 | billing.md | Billing | Subscription state machine with dunning | Billing |
| TR-team-invitations-001 | team-invitations.md | Identity | Single-use invite tokens, 7-day TTL | Identity |
| TR-reports-002 | reports.md | Reporting | Export 100k rows async | Messaging |
```

At `minimal` there are no specs: derive the baseline from the brief's MVP list
and mark each row `source: brief`.

This baseline feeds into every subsequent phase. No requirement should be left
without an architectural decision to support it by the end of this session.

### 0c. Existing Architecture Decisions

To learn **what has already been decided and in which domain**, scan the ADR
headers — do not full-read every ADR to produce a list of numbers and domains:
```
Grep pattern="^## (Status|Summary)" glob="docs/architecture/adr-*.md" output_mode="content" -A 4
Grep pattern="\*\*Domain\*\*|\*\*Layer\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
```
`## Summary` (a 2-sentence what-and-why) plus `## Status` and the Stack
Compatibility `Domain` and `Layer` fields are exactly "what was decided and its
domain". List the ADRs found, their status, and their domains from the scan.
Full-read a specific ADR only when a new decision this session would collide
with it and you need its reasoning — not to build the inventory.

### 0d. Generate Stack-Risk Inventory

Before proceeding, display a structured summary:

```
## Stack-Risk Inventory
Stack: [layers and pinned versions, from pins.yaml]
Model knowledge lags: [layers whose pinned version is past what the model reliably knows]

### HIGH RISK (must verify against docs/stack-reference/ before deciding)
- [Layer / feature]: [Key changes, breaking change, security floor]

### MEDIUM RISK (verify key APIs)
- [Layer / feature]: [...]

### LOW RISK (long-stable, in training data)
- [Layer / feature]: [no significant recent change]

### NOT SOURCEABLE (no reference for this layer)
- [Layer]: not covered by docs/stack-reference/ — research required before its ADR is Accepted

### Requirements that touch HIGH/MEDIUM risk layers:
- [TR-id or context] → [layer] → [risk level]
```

Use `AskUserQuestion`:
- Prompt: "One or more stack layers are HIGH RISK or NOT SOURCEABLE — the model's knowledge may be unreliable there. Architectural recommendations in these areas should be cross-referenced with the stack reference before being acted on. How would you like to proceed?"
- Options:
  - `[A] Proceed — flag HIGH RISK and NOT SOURCEABLE items throughout the output`
  - `[B] Let me check the stack reference first — pause here`
  - `[C] Show me which layers are HIGH RISK and why`

If the stack-risk inventory touches an API or feature beyond the stack reference,
that item is a `CTO-STACK-RISK` candidate for the ADR that decides it (recorded
here, spawned by `/architecture-decision`).

### 0e. Existing Architecture Document

Glob `docs/architecture/architecture.md`. If it exists, this run updates it —
it never replaces it unasked. Read its `## Document Status` block and its `##`
headings, then use `AskUserQuestion`:
- Prompt: "An architecture document already exists (v[N], [last updated]). What should this run do?"
- Options: `[A] Update chosen sections in place` / `[B] Rewrite the whole document — replaces the existing file` / `[C] Stop`

On `[A]`, ask which sections. Phases 1–7 author only those and say which they
skipped; Phase 8 replaces just those sections and raises `Version` to N+1,
leaving every other section as it is. `[B]` runs the full walkthrough, and
Phase 8's ask says it replaces the existing file.

A focus-area argument (`contexts`, `data-tenancy`, `data-flow`, `api-boundaries`,
`deployment`, `adr-audit`) is `[A]` with that one section chosen: it runs only
its phase (1, 2, 3, 4, 5 or 6), and Phase 8 writes that section. Phase 8b still
runs on the updated document — an update is reviewed like a first draft, at the
review modes that review one. With no existing document there is nothing to
update — say so, and offer the full walkthrough instead.

---
