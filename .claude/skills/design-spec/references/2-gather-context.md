# /design-spec — Phase 2: Gather Context

> Part of `/design-spec`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Gather Context (Read Phase)

**In this file:**

- 2a: Required Reads
- 2b: Dependency Reads
- 2c: Optional Reads
- 2d: Present Context Summary
- 2e: Stack and Standards Pre-Check

Read all relevant context **before** asking the user anything. This is the skill's
primary advantage over ad-hoc design — it arrives informed.

### 2a: Required Reads

> **At `minimal`** (design-spec is voluntary at this tier): read
> `design/product-brief.md` and **skip the domain-map read** — `domain-map.md`
> does not exist at `minimal`. Author from the brief's relevant MVP feature, its
> jobs-to-be-done and the research note `docs/research/<feature>.md` if present.
>
> **This callout keys on the PROJECT tier, not this feature's effective tier.**
> The two differ whenever `workflow_overrides.system_overrides` bumps one feature
> above a `minimal` project — the configuration the override exists for ("bump
> one deep feature", for example billing). The domain map is absent because the
> *project* is `minimal`; raising *this feature* to `standard` or `full` does
> not create it. So on a `minimal` project, take this branch **even for an
> overridden feature**, and read the brief.
>
> The effective tier still governs everything downstream — the required section
> set (§1), the skeleton (§3), the section cycle (§4) and §5a. Only the
> required-*reads* branch here follows the project tier.
>
> **Then derive `Category`, `Layer`, `Priority` and `Bounded context` from the
> brief, once, here.** Later steps are keyed on the domain map you just
> skipped — §2e's stack layer, Section A's recommended options, §6 specialist
> routing, and §5-pre's Quick reference — and none of them has an absent-map
> branch. Derive from the brief instead:
>
> - **`Category`** — one of the eight in `templates/domain-map.md`
>   (`Platform · Core domain · Billing & Licensing · Integrations · Admin &
>   Support · Growth · Insights · Client surfaces`), chosen from what the brief
>   says the feature *does*.
> - **`Layer`** — `Foundation` if other features depend on it, else `Feature`.
> - **`Priority`** — `MVP` if the brief's build order lists it, else `Post-MVP`.
> - **`Bounded context`** — the single context the feature belongs to, named
>   from the brief's language.
>
> Carry all four for the rest of the run and treat them as the map's answer.
> **Mark them inferred** in §5-pre's Quick reference (*"Category: Billing &
> Licensing (inferred from the brief — no domain map at this tier)"*) so a later
> reader does not mistake a derivation for a mapped fact. Do **not** write a
> domain map to hold them: `/map-domains` owns that file (§5d).

- **Product brief**: Read `design/product-brief.md` — fail if missing:
  > "No product brief found. Run `/brainstorm` first."
- **Domain map**: Read `design/specs/domain-map.md` — fail if missing (project tier `standard`/`full`):
  > "No domain map found. Run `/map-domains` first to map your contexts and features."
- **Target feature**: Find the feature in the map. If not listed, warn:
  > "[feature-name] is not in the domain map. Would you like to add it, or
  > specify it as an off-map feature?"
- **Pricing and plan context**: if `design/specs/pricing-model.md` (the canonical path;
  else `Glob design/**/pricing-model*.md`, or the pricing model the brief links) exists, read the plans and entitlement keys the
  feature may reference. If none exists, say so — Section B will mark plan
  gating as provisional rather than invent plan names.
- **Research note**: Glob `docs/research/[feature-name].md`. Absent → say so by
  name: *"no research note for `[feature-name]` yet — DoD gate 1 requires one
  before implementation (`/research`); sections that need provider or standard
  facts will be marked `NOT SOURCEABLE` until it exists."* Do not fill provider
  limits, ASVS IDs or API behaviours from memory.
- **Entity registry**: If `design/registry/entities.yaml` exists, grep it for
  the entries this feature owns and the entries that reference it:
  ```
  Grep pattern="source: design/specs/[feature-name].md" path="design/registry/entities.yaml" output_mode="content" -A 6
  Grep pattern="design/specs/[feature-name].md" path="design/registry/entities.yaml" output_mode="content" -B 8
  ```
  `referenced_by:` is a block list (the key and its paths are on separate
  lines), so match the path with `-B 8` context to see the owning entry. Hold
  these in context as **known facts** — entities, entitlement keys, quotas and
  events that other specs have already established and this spec must not
  contradict.
- **Reflexion log**: Read `docs/consistency-failures.md` if it exists.
  Extract entries whose domain matches this feature's category. These are
  recurring conflict patterns — present them under "Past failure patterns"
  in the Phase 2d context summary.

### 2b: Dependency Reads

From the domain map, identify:
- **Upstream dependencies**: contexts and features this one depends on (decisions
  this feature must respect), including `saas-core` modules it consumes.
- **Downstream dependents**: features that depend on this one (expectations this
  feature must satisfy).

For each dependency spec that exists, read **only the four sections that carry the
cross-feature contract** — not the whole spec:
```
Grep pattern="^## ([0-9]+\. )?(Dependencies|Data & Contracts|Edge Cases|Non-Functional)" glob="design/specs/[dep].md" output_mode="content" -A 20
```
- Key interfaces and data flow (from Dependencies and Data & Contracts)
- Entitlement keys, quotas and events this feature consumes or must emit
- Failure modes that assume this feature's behaviour
- Permission and tenancy assumptions it makes

Much of this is already in `entities.yaml` (loaded in 2a) — the registry's
entity, entitlement and quota entries carry the owned values with their
`source:`. Use the registry first; the section grep fills what it does not hold.

### 2c: Optional Reads

- **Product principles**: Read `design/product-principles.md` if it exists
- **Existing spec**: Read `design/specs/[feature-name].md` if it exists (resume,
  don't restart from scratch)
- **UX spec**: Glob `design/ux/` for screens that mention this feature
- **Related features**: do **not** glob-and-read `design/specs/*.md` hunting for
  "thematically related" features — there is no deterministic proxy for that and
  it is the read the registry exists to replace. If a specific overlap is known,
  treat it as a dependency above and section-grep it; otherwise rely on the
  registry.

### 2d: Present Context Summary

Before starting design work, present a brief summary to the user:

> **Specifying: [Feature Name]** — effective tier: [tier] (source: [project value | system_overrides])
> - Priority: [from map] | Layer: [from map] | Context: [bounded context] | Category: [category]
> - Depends on: [list, noting which have specs vs. unspecified, and which are `saas-core` modules]
> - Depended on by: [list, noting which have specs vs. unspecified]
> - Existing decisions to respect: [key constraints from dependency specs]
> - Principle alignment: [which principle(s) this feature primarily serves]
> - Plan gate: [plan/entitlement from the pricing model, or "not yet defined"]
> - **Known cross-feature facts (from registry):**
>   - [entity_name]: owner=[context], tenant key=[field] (owned by [source spec])
>   - [entitlement/quota key]: [value source] (owned by [source spec])
>   - [event_name]: producer=[context], consumers=[list] (owned by [source spec])
>   *(These facts are locked — if this spec needs different ones, surface
>   the conflict before writing. Do not silently use different names or values.)*
>
> If no registry entries are relevant: omit the "Known cross-feature facts" section.

If any upstream dependencies are unspecified, warn:
> "[dependency] doesn't have a spec yet. We'll need to make assumptions about
> its interface. Consider specifying it first, or we can define the expected
> contract and flag it as provisional."

If a `saas-core` module the feature needs has no released version pinned
(`core.version` unset) or the module is not in the core repo, say so: the
dependency is `pending core` and is flagged in Section F.

### 2e: Stack and Standards Pre-Check

Before asking the user to begin, load the stack context and surface constraints
or knowledge gaps that will shape the spec.

**Step 1 — Determine the layers this feature touches:** from the feature's
`Category` and description: backend only, backend + web, backend + mobile,
marketing site, self-hosted bundle. Name the layers you read the reference for.

**Step 2 — Read stack context (if available):**
- Read `stack` from the resolved config and `docs/stack-reference/pins.yaml`. If
  the stack is not configured, say so: *"stack not configured — run
  `/setup-stack`; feasibility not checked against pinned versions"*.
- For each touched layer, read `docs/stack-reference/<layer>/VERSION.md` and
  grep `breaking-changes.md` / `deprecated-apis.md` for entries relevant to the
  feature. **If a layer's reference does not exist, say so by name** — *"no stack
  reference for `<layer>` under `docs/stack-reference/`; feasibility not checked
  against the pinned version"* — and carry that into §5-pre. A silent skip here is
  indistinguishable from a feasibility check that ran and found nothing wrong,
  which is the failure `.claude/rules/skill-authoring.md` obligation 3 exists to
  stop.
- Find constraining ADRs without reading every one — grep the Domain/Context
  field first, then read only the matches:
  ```
  Grep pattern="Domain|Context" glob="docs/architecture/adr-*.md" output_mode="content"
  ```
  Read only ADRs whose context matches this feature (`## Decision` section).
- Read `docs/architecture/perf-budgets.md` if it exists (needed by Section G);
  note its absence otherwise.
- Read `project.yaml` `tenancy.model` and `distribution.model`: they decide the
  isolation assumptions in Section C and whether the self-hosted edition needs a
  behaviour difference stated.

**Step 3 — Present the Feasibility Brief:**

```
## Stack Feasibility Brief: [Feature Name]
Stack: [resolved profile]  Tenancy: [model]  Distribution: [model]
Layers: [list]

### Known Capabilities (verified for pinned versions)
- [capability relevant to this feature]

### Constraints That Will Shape This Spec
- [constraint from stack reference, ADR or core module]

### Knowledge Gaps (verify before committing to these)
- [API or provider behaviour not covered by the stack reference — mark NOT SOURCEABLE]

### Existing ADRs That Constrain This Feature
- ADR-XXXX: [decision summary] — means [implication for this spec]
  (or "None yet")
```

If no stack reference exists, show a short note instead:
> "No stack configured yet — skipping the stack feasibility check. Run
> `/setup-stack` before moving to architecture if you haven't already."

**Step 4 — Ask before proceeding:**

Use `AskUserQuestion`:
- "Any constraints to add before we begin, or shall we proceed with these noted?"
  - Options: "Proceed with these noted", "Add a constraint first", "I need to check the stack docs — pause here"

---

Use `AskUserQuestion`:
- "Ready to start specifying [feature-name]?"
  - Options: "Yes, let's go", "Show me more context first", "Specify a dependency first"

---
