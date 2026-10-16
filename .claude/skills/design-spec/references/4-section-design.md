# /design-spec — Phase 4: Section-by-Section Design

> Part of `/design-spec`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Section-by-Section Design

**In this file:**

- The Section Cycle
- Section-Specific Guidance
- Section A: Overview
- Section B: User Value
- Section C: Detailed Behaviour (Core Rules, Permissions, States, Interactions)
- Section D: Data & Contracts (incl. Formulas and Rules)
- Section E: Edge Cases & Failure Modes
- Section F: Dependencies
- Section G: Non-Functional Requirements (Security, Performance, Caching, Observability, Accessibility, Localization, Configuration)
- Section H: Acceptance Criteria
- Optional Sections: Cross-References, Open Questions

**Author only the sections required at the resolved tier** (§1). At `standard`,
the walk covers A (Overview), C (Detailed Behaviour), D (Data & Contracts),
G (Non-Functional Requirements), H (Acceptance Criteria) — plus E (Edge Cases &
Failure Modes) when the feature calls an external provider, moves money, changes
entitlements or runs asynchronously (or `edge_cases` is forced); skip B (User
Value) and F (Dependencies) unless the user asks for them. G's Configuration
subsection is added when `workflow_overrides.tuning_knobs: true` or the feature
has tunable values. At `full`, walk all eight (A–H). At `minimal`, the spec is
optional — if authoring voluntarily, walk the standard set. Any
`system_overrides.<feature>` tier was already folded into the resolved tier in §1.

Walk through each required section in order. For **each section**, follow this cycle:

### The Section Cycle

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain, and surface any relevant
   decisions from dependency specs that constrain it.

2. **Questions**: Ask clarifying questions specific to this section. Use
   `AskUserQuestion` for constrained questions, conversational text for open-ended
   exploration.

3. **Options**: Where the section involves design choices (not just documentation),
   present 2-4 approaches with pros/cons. Explain reasoning in conversation text,
   then use `AskUserQuestion` to capture the decision.

4. **Decision**: User picks an approach or provides custom direction.

5. **Draft**: Write the section content in conversation text for review. Flag any
   provisional assumptions about unspecified dependencies.

6. **Approval**: Per the resolved `modes.automation` mode
   (`.claude/docs/automation-modes.md`):

   **In `collaborative` mode**: Immediately after the draft — in the SAME
   response — use `AskUserQuestion`. **NEVER use plain text. NEVER skip
   this step.**
   - Prompt: "Approve the [Section Name] section?"
   - Options: `[A] Approve — write it to file` / `[B] Make changes — describe what to fix` / `[C] Start over`

   **The draft and the approval widget MUST appear together in one response.
   If the draft appears without the widget, the user is left at a blank prompt
   with no path forward — this is a protocol violation in collaborative mode.**

   **In `guided` mode**: Write the section immediately after the draft with
   a brief one-line summary of what was decided. Skip the per-section widget;
   the multi-section authoring rule (no per-section confirmation) applies.

   **In `autonomous` mode**: Write the section directly and call
   `log_decision` with `Decision point: Approve [Section Name] section`,
   `Chosen: [A] Approve`, `Category: minor`.

7. **Write**: Use the Edit tool to replace the placeholder with the approved content.
   **CRITICAL**: Always include the section heading in the `old_string` to ensure
   uniqueness — never match `[To be designed]` alone, as multiple sections use the
   same placeholder and the Edit tool requires a unique match. Use this pattern:
   ```
   old_string: "## [Section Name]\n\n[To be designed]"
   new_string: "## [Section Name]\n\n[approved content]"
   ```
   For sub-headed sections (3, 4, 7) include the `###` sub-heading in `old_string`.
   Confirm the write.

8. **Registry conflict check** (Sections C and D only — Detailed Behaviour and Data & Contracts):
   After writing, scan the section content for entity names, entitlement keys,
   quota names, event names and permission names that appear in the registry. For each match:
   - Compare the value just written against the registry entry.
   - If they differ: **surface the conflict immediately** before starting the next
     section. Do not continue silently.
     > "Registry conflict: [name] is registered in [source spec] as [registry_value].
     > This section just wrote [new_value]. Which is correct?"
   - If new (not in registry): flag it as a candidate for registry registration
     (will be handled in Phase 5).

After writing each section, update `production/session-state/active.md` with the
completed section name. Use Glob to check if the file exists — use Write to create
it if absent, Edit to update it if present.

### Section-Specific Guidance

Each section has unique considerations and may benefit from specialist agents
(routing table in `SKILL.md` §6):

**Every skipped spawn is announced.** When a section's review-mode check below
skips its specialist — in `lean` as well as `solo` — print that section's note
with the mode it ran in, e.g. "`security-lead` not consulted — Lean mode.
Review manually before implementation." A section drafted without its
specialist must say so in the output, whichever mode skipped it.

**Solo skips review, never the standards.** Skipping a specialist waives their
opinion, not the Definition of Done: the security, performance, caching and
observability prompts in Section G are asked in every review mode.

---

### Section A: Overview

**Goal**: One paragraph a stranger could read and understand.

**Derive recommended options before building the widget**: Read the feature's category and layer from the domain map (already in context from Phase 2), then determine the recommended option for each tab:
- **Audience tab**: keyed on the `Category` column. `Core domain`, `Client surfaces`, `Growth` → `[A] End users and tenant members` recommended. `Platform`, `Admin & Support`, `Insights`, `Integrations` → `[B] Tenant admins / operators` recommended. `Billing & Licensing` → `[C] Both` recommended. **Tiebreak when Layer and Category disagree** (a `Foundation`-layer `Core domain` feature is the common case): **Category wins** — the audience describes who the section is *about*.
- **Plan gate tab**: if the pricing model exists and lists an entitlement for this feature → `[A] Gated by an entitlement` recommended; otherwise `[B] Included in all plans` recommended and noted as provisional.
- **Research tab**: Glob `docs/research/[feature-name].md`. Found → `[A] Yes — cite the note` recommended. Not found → `[B] No — write it later` recommended, with the DoD gate 1 reminder.

Append `(Recommended)` to the appropriate option text in each tab.

**Framing questions (ask BEFORE drafting)**: Use `AskUserQuestion` with a multi-tab widget:
- Tab "Audience" — "Who is this feature primarily for?" Options: `[A] End users and tenant members` / `[B] Tenant admins / self-hosted operators` / `[C] Both — describe each audience's part`
- Tab "Plan gate" — "How is this feature gated by plan?" Options: `[A] Gated by an entitlement or quota` / `[B] Included in all plans` / `[C] Add-on or separate licence claim`
- Tab "Research" — "Should the overview cite the research note?" Options: `[A] Yes — cite docs/research/[feature-name].md` / `[B] No — write it later`

Use the answers to shape the draft. **In `collaborative` mode, do NOT answer
these questions yourself and auto-draft** — the widget must appear. In `guided`
and `autonomous`, this is a MINOR framing decision: select the recommended
option derived above, state it in one line, and proceed. Applies to every "ask
BEFORE drafting" widget in this section walk, not just this one.

**Questions to ask**:
- What is this feature in one sentence?
- Who uses it, and in which role (owner / admin / member / viewer / end customer / operator)?
- Why does it exist — what would the product lose without it?

**Cross-reference**: Check that the description aligns with how the domain map
describes it. Flag discrepancies.

**Design vs. implementation boundary**: Overview questions must stay at the behaviour
level — what the feature *does*, not *how it is built*. If implementation questions
arise (e.g., "Should this be a background job or inline?"), note them as
"→ becomes an ADR (at `modes.workflow: minimal`, a decision-log entry in the brief)" and move on. Implementation patterns belong in
`/architecture-decision`, not the spec. The spec describes behaviour; the ADR
describes the technical approach used to achieve it.

---

### Section B: User Value

**Goal**: Who needs the feature, the job it does, and what it does to plans and pricing.

**Derive recommended option before building the widget**: Read the feature's category from Phase 2 context:
- Customer-facing — `Core domain`, `Client surfaces`, `Growth` → `[A] Direct` recommended
- Internal/operator — `Platform`, `Admin & Support`, `Insights`, `Integrations` → `[B] Indirect` recommended
- Mixed — `Billing & Licensing` → `[C] Both` recommended

**When Layer and Category disagree, Category wins** — same tiebreak as Section A.

Append `(Recommended)` to the appropriate option text.

**Framing question (ask BEFORE drafting)**: Use `AskUserQuestion`:
- Prompt: "Does a customer use this feature directly, or do they only feel its effects?"
- Options: `[A] Direct — a role actively uses it` / `[B] Indirect — customers experience the effects, not the feature` / `[C] Both — it has a direct surface and infrastructure beneath it`

Use the answer to frame the section. Do NOT assume the answer.

**Questions to ask**:
- For each role: what job (JTBD form: "When…, I want to…, so I can…") does this serve?
- What does success look like for them? How would we notice it is working?
- What happens if the feature is missing — a workaround, churn, a support ticket?
- Which plan includes it, which entitlement key or quota gates it, is it an add-on, does it need a self-hosted licence claim?

**Cross-reference**: Must align with the product principles and the brief's ICP and
positioning. If the feature serves a principle, quote the relevant principle text.
Plan and pricing effects **link to the pricing model** (entitlement keys, plan
names); never write a price or a quota number here (`.claude/rules/specs.md`).

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`pricing-billing-designer` not consulted — Solo mode. Review manually before implementation."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D, G and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY at `full`)**: After the framing answer is given but
before drafting, spawn `pricing-billing-designer` via `Agent` when the feature has a plan gate, quota or add-on, else `product-manager`:
- Provide: feature name, framing answer, principles, ICP and pricing hypothesis from the brief, any entitlement keys already in the registry
- Ask: "Shape the User Value and Plan/pricing impact for this feature. Which entitlement or quota gates it? What would an upgrade trigger look like? Which jobs does it serve for which role? Give me 2-3 candidate framings."
- Present the candidate framings to the user alongside the draft.

---

### Section C: Detailed Behaviour (Core Rules, Permissions, States, Interactions)

**Goal**: Unambiguous specification an engineer could implement without questions.

This is usually the largest section. Break it into sub-sections:

1. **Core Rules**: The fundamental behaviour. Use numbered rules for sequential
   processes, bullets for properties. Every "should" becomes a "must" or is removed.
2. **Permissions per Role**: the matrix from the template — every action has a row,
   every role a cell (Owner / Admin / Member / Viewer / Anonymous / Other tenant).
   Cross-tenant access answers `404`, anonymous `401` (`.claude/docs/api-standards.md`).
   Where a **plan** changes what a role can do (a feature visible on Team but not
   Starter), add a plan column or a second table — permissions are stated per role
   **and** per plan.
3. **States and Transitions**: If the feature has states (invited → accepted →
   revoked), map every state and every valid transition. Use a table.
4. **Interactions with Other Contexts**: For each dependency (upstream and downstream),
   specify what data flows in, what flows out, who owns the interface, and whether it
   is a synchronous call or an event.

**Questions to ask**:
- Walk me through a typical use of this feature, step by step, for each role
- What are the decision points the user faces?
- What can each role NOT do? (Constraints are as important as capabilities)
- What differs between the hosted and the self-hosted edition (licence checks, offline behaviour, no outbound calls)?

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note naming them: "`[the §6 routing table's Primary and Supporting Agents for this feature type]` not consulted — Solo mode. Review manually before implementation."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D, G and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY at `full`)**: Before drafting Section C, spawn specialist agents via `Agent` in parallel:
- Look up the feature type in the routing table (`SKILL.md` §6)
- Spawn the Primary Agent AND Supporting Agent(s) listed for this type
- Provide each agent: feature name, product brief summary, principles, dependency spec excerpts, the specific section being worked on
- Collect their findings before drafting
- Surface any disagreements between agents to the user via `AskUserQuestion`
- Draft only after receiving specialist input

**Do NOT draft Section C without first consulting the appropriate specialists
(at `full`).** A `domain-architect` reviewing rules and invariants will catch gaps
the main session cannot.

**Cross-reference**: For each interaction listed, verify it matches what the
dependency spec specifies. If a dependency defines a value or rule and this
feature expects something different, flag the conflict.

---

### Section D: Data & Contracts

**Goal**: The entities, API surface, events and numeric rules, precise enough to write the contract first.

Sub-sections (all from the template):

1. **Entities** — owner (bounded context), key fields, **tenant key**, retention/deletion, PII flag. A table or collection has exactly one owner; if the registry or domain map says another context owns an entity this feature touches, reference it through that owner's port, do not redefine it.
2. **API Endpoints** — method + path, purpose, auth/policy, idempotent?, success, errors (problem `code`). The contract lands in `contracts/` first; reference it. Follow `.claude/docs/api-standards.md`: versioned paths, `Idempotency-Key` on repeatable writes, RFC 9457 errors, pagination limits.
3. **Events and Webhooks** — producer, consumers, payload link, delivery guarantee (at-least-once with idempotent consumers is the default).
4. **Formulas and Rules** — only if the feature defines numeric rules (see §1). Use the structure below.

**Completion Steering — always begin each formula with this exact structure:**

```
The [formula_name] rule is defined as:

`[formula_name] = [expression]`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| [name] | int (minor units) / float / duration | [min–max] | plan config / DB / constant | [what it represents] |

**Output Range:** [min] to [max] under normal use; [behaviour at extremes]
**Rounding:** [half-even in minor units / floor / ...]
**Example:** [worked example with real numbers]
```

Do NOT write `[Formula TBD]` or describe a rule in prose without the variable
table. Money is integer minor units; durations carry units; the `Source` column
carries the coding-standards rule *"no hardcoded business values"* — a variable
marked `plan config` or `DB` is configuration, one marked `constant` is a
deliberate exception.

**Questions to ask**:
- Which entities does this feature create, and which does it only read?
- Which contexts own the data it reads? Through which port?
- Which endpoints do clients need, and which operations can a client or webhook repeat?
- Which events do other features need? Is delivery ordering required?
- What are the retention and deletion rules? Which fields are PII?

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialists. Add a note: "`domain-architect` / `api-designer` not consulted — Solo mode. Review manually before implementation."
- `lean` → spawn (HIGH implementation risk section).
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Before proposing entities and endpoints, spawn in parallel via `Agent`:
- **`domain-architect`**: entities, ownership, invariants, tenant keys. Provide Section C's Core Rules and the domain map's ownership table.
- **`api-designer`**: endpoint shapes, errors, idempotency, pagination. Provide the entities and Section C's permission matrix.
- **For money, quotas or proration**: also `pricing-billing-designer` to validate the formulas and rounding.
- **For PII entities**: also `privacy-compliance-specialist` for retention/deletion/export rules.
- Present the specialists' proposals to the user for review via `AskUserQuestion`; the user decides; the main session writes to file.
- **Do NOT invent rates, prorations or limits without specialist input.** A reader cannot evaluate raw numbers without the reasoning.

**Cross-reference**: If a dependency spec defines an entity or rule whose output feeds
into this feature, reference it explicitly. Don't redefine — connect.

---

### Section E: Edge Cases & Failure Modes

**Goal**: Explicitly handle unusual situations so they don't become incidents.

**Completion Steering — format each edge case as:**
- **If [condition]**: [exact outcome]. [rationale if non-obvious]

Example (adapt to the feature's domain):
- **If a webhook from the payment provider is delivered twice**: the second delivery is a no-op keyed by provider event id; both return 200.
- **If the tenant is downgraded while an export job is running**: the job completes; no new job can be started above the new quota.

Do NOT write vague entries like "handle appropriately" — each must name the exact
condition and the exact resolution. An edge case without a resolution is an open
question, not a specification.

Walk the template's scenario table and answer each row or mark it `n/a — <reason>`:
invalid or oversized input · concurrent or repeated request (double submit,
webhook replay) · provider outage, timeout or partial failure · cache or queue
down · quota exceeded or plan downgraded mid-flow · user deleted, tenant
suspended or trial expired · abuse (enumeration, scraping, coupon stacking, seat
inflation) · clock skew, time zone, DST.

**Questions to ask**:
- What happens at zero? At the quota limit? At out-of-range values?
- What happens when two requests change the same resource at once?
- What happens when the provider is down, slow, or returns a partial success? Which side is the source of truth?
- What happens to in-flight work when the tenant is suspended, the plan changes, or the user is deleted?
- What would an attacker try with this feature (enumeration, replay, IDOR, abuse of a free tier)?

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`appsec-engineer` not consulted — Solo mode. Review manually before implementation."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D, G and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY at `full`)**: Spawn `domain-architect` (consistency, concurrency, partial failure) and `appsec-engineer` (abuse cases) via `Agent` in parallel before finalising edge cases. Provide: the completed Sections C and D. Ask them to identify cases the main session may have missed. For features that call a provider, also `integrations-engineer`. Present their findings and ask the user which to include.

**Cross-reference**: Check edge cases against dependency specs. If a dependency
defines a limit, cap or resolution rule that this feature could violate, flag it.

---

### Section F: Dependencies

**Goal**: Map every connection with direction and nature.

This section is partially pre-filled from the context gathering phase. Present the
known dependencies from the domain map and ask:
- Are there dependencies I'm missing?
- For each dependency, what is the specific interface (port, event, endpoint)?
- Which dependencies are hard (cannot function without it) vs. soft (enhanced by it but works without it)?

The table's `Kind` column distinguishes **context**, **core module**, **provider**
and **flag**. For each **core module** (identity, billing, licensing, notify,
storage, tenancy, audit, ratelimit, otp, observability): state whether the
module covers the need as-is, needs an extension (→ `/core-extract` or an
upstream change, not an in-product reimplementation), or is `pending core`.
For each **provider**: link its research note; a provider without one is
`NOT SOURCEABLE` until `/research` writes it. List feature flags with default,
rollout plan and removal date.

**Cross-reference**: This section must be bidirectionally consistent. If this
feature lists "depends on Billing", then the Billing spec should list "depended on
by [this feature]". Flag any one-directional dependencies for correction.

---

### Section G: Non-Functional Requirements

**Goal**: Every non-functional commitment stated once, in the spec, so no story invents its own. **All seven sub-sections are prompted at every tier and every review mode** — NFRs map to DoD gates 4–7, which `modes.workflow` never relaxes (a `minimal` voluntary spec still answers them; `.claude/rules/specs.md`).

Walk the sub-sections in order. For each, ask the questions, present options where there is a choice, and draft.

**G1 Security.**
- **Sensitive area?** Run the threat-model trigger test from `.claude/docs/security-baseline.md`: does the feature touch **authentication, the authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, or a new external integration?** Ask as a checklist via `AskUserQuestion` (multi-select), not by impression. Any yes → a threat model is **required**: record `docs/architecture/threat-models/[feature-name].md` as the link and note "run `/threat-model [feature-name]` before implementation". None → record `not required: <reason>`.
- **Standards mapping**: OWASP ASVS 5.0 chapter/requirement IDs (web/backend), MASVS (mobile only), API Top 10 items. **IDs are looked up in the official documents at mapping time, never recalled from memory** (`security-baseline.md`). If you cannot look them up this session, write the chapter names only and mark the IDs `NOT SOURCEABLE — ASVS 5.0 text not read this session`; do not guess numbers.
- **Tenant isolation**: app-layer scoping plus the `tenancy.model` mechanism (RLS / per-tenant store), and how the cross-tenant case is tested.
- **Data classification** (public / internal / confidential / PII) and the logging rule (no PII or secrets in telemetry).
- **Abuse limits**: rate limits per tenant/actor/route and quotas — as named configuration.

**G2 Performance Budget.** Read `docs/architecture/perf-budgets.md` (Phase 2e). Fill the template table: endpoint p95, queries per request (no N+1), payload size, background job max runtime, web LCP/INP/CLS or mobile cold start where this feature has a surface. If `perf-budgets.md` is absent say so and write the feature's own proposed budget marked `proposed — no project budget exists`; do not invent the project's.

**G3 Caching Decision.** Follow `.claude/docs/caching-standard.md`: a written decision — what is cached, pattern, key schema (tenant-scoped), TTL with jitter, invalidation, stampede protection, failure mode, expected hit ratio — **or a written reason for no cache** ("no cache" is valid). Offer `/cache-design` when the decision is non-trivial.

**G4 Observability.** Follow `.claude/docs/observability-standard.md`: the spans (use case + external calls), RED metrics on every endpoint plus the business metrics (for example `invitations_sent`), outcome log events without PII, alerts/SLO (burn-rate alert on the journey), and the runbook link. Offer `/observability-plan` for journeys that need an SLO.

**G5 Accessibility.** Target from `accessibility-requirements.md` if it exists (default WCAG 2.2 AA); keyboard path, focus order, labels, contrast, reduced motion, announcements for dynamic content; link the UX spec `design/ux/<screen>.md` or note it is still to be written (`/ux-design`). A feature with no UI states `n/a — no user-facing surface` and says which surface consumes its API.

**G6 Localization.** Arabic (RTL) and English: every user-visible string externalised (no hardcoded copy), plural/gender forms, number/date/currency formatting per locale, mirrored layout and icons, emails and error messages translated. Record the strings added or changed (keys or a count).

**G7 Configuration** (add when `workflow_overrides.tuning_knobs: true` or the feature has tunable values): every value that must change without a deploy — default, safe range, where it is configured (env / DB / plan data), effect of increase and decrease. Reference the Formulas `Source` column; do not create duplicate knobs — point to the source of truth.

**Review mode check** (apply before spawning):
- `solo` → skip the agent spawns. Draft every sub-section yourself from the standards docs. Add a note: "`security-lead` / `performance-engineer` / `observability-engineer` / `accessibility-specialist` / `localization-lead` not consulted — Solo mode. Review manually before implementation."
- `lean` → spawn `security-lead` only when G1 found a sensitive area; other sub-sections without agents.
- `full` → spawn as described below.

**Agent delegation (MANDATORY at `full`)**: Spawn in parallel via `Agent`, each given the completed Sections C and D:
- `security-lead` — G1 (threat-model trigger confirmation, standards mapping, abuse limits)
- `performance-engineer` — G2 (budget fit, query shape)
- `cache-specialist` — G3 (when a cache is proposed)
- `observability-engineer` — G4
- `accessibility-specialist` — G5 (when the feature has a UI surface)
- `localization-lead` — G6 (when the feature has user-visible strings)
Present findings per sub-section and let the user decide; the main session writes.

**Cross-reference**: If a dependency spec states a limit, TTL or SLO that affects this feature, reference it. Don't create duplicate values.

---

### Section H: Acceptance Criteria

**Goal**: Testable conditions that prove the feature works as specified.

**Completion Steering — format each criterion as Given-When-Then, tagged with the story type that proves it** (Logic / Integration / Contract / Security / Performance / UI / Config — `.claude/docs/coding-standards.md`):
- **GIVEN** [initial state], **WHEN** [action or trigger], **THEN** [measurable outcome] — *[story type]*

Example (adapt to the feature's domain):
- **GIVEN** a Starter-plan tenant at its seat limit, **WHEN** an admin invites another member, **THEN** the API returns 422 with problem code `plan_limit_reached` and no invitation row exists. — *Logic + Contract*

Include at least: one criterion per core rule from Section C, one per formula
from Section D, and the **Negative / authorization** block from the template:
anonymous → 401 on every endpoint; a role without permission → 403 and nothing
changes; **a user in tenant B requesting tenant A's resource → 404 (no existence
leak)**; invalid input → 422 with problem `code`, malformed → 400; repeating a
request with the same `Idempotency-Key` has no second effect; **plan/permission
matrix** rows (each plan × role cell that differs) and over-quota behaviour.
Add the **Non-functional** block: meets the performance budget (load-test
evidence), emits spans/RED metrics/outcome logs with no PII, security mapping
complete and dependency scan clean, Arabic (RTL) and English verified and the
accessibility target met, no hardcoded business values. Do NOT write "the
feature works as specified" — every criterion must be independently verifiable
by a tester without reading the spec.

> **When Formulas was not authored** (optional at this tier because the
> feature defines no numeric rule), there are no formulas to cover and the
> criteria come from Section C alone — say so in one line rather than silently
> writing fewer criteria. **If Formulas was skipped but Section C states a
> quantity** — a rate, threshold, cost or period — that is the §1 test being met
> after the fact: stop, tell the user the Formulas sub-block is required for this
> feature, and author it before finalising the criteria. A criterion cannot
> verify a number the spec never defines.
>
> **That escalation applies at `standard` only.** At `minimal` the conditional
> does not re-apply: state the value inline in Core Rules (as named configuration)
> so it stays implementable, and move on. At `full`, the sub-block is part of a
> required section, so the case cannot arise.

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`qa-lead` not consulted — Solo mode. Review manually before implementation."
- `lean` → spawn (HIGH implementation risk section).
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Spawn `qa-lead` via `Agent` before finalising acceptance criteria. Provide: the completed spec sections C, D, E and G, and ask them to validate that the criteria are independently testable, cover all core rules, formulas, the negative and cross-tenant cases, and map each to a story type. Surface any gaps or untestable criteria to the user.

**Questions to ask**:
- What's the minimum set of tests that prove this works?
- Which criteria need a running stack (run-and-observe) rather than a unit test?
- What would a tester check first?

**Cross-reference**: Include criteria that verify cross-feature interactions work,
not just this feature in isolation.

---

### Optional Sections: Cross-References, Open Questions

These two are template sections that are **not** among §1's eight. They are
governed here, not by the tier: §1's per-tier lists decide the *required* set,
and this block decides the rest independently.

**Cross-References is REQUIRED whenever the Dependencies section or any rule
names another spec.** The rule is derived, not category-keyed: if this document
references another feature's behaviour, value or rule anywhere, that reference
belongs in the table (specific element referenced and Nature: Data dependency /
State trigger / Rule dependency / Ownership handoff). Where nothing is named,
write *"None — this feature references no other spec"* rather than leaving the
placeholder. `/review-all-specs` reads this table when it exists. At `minimal`
(voluntary spec) it is optional like the rest.

**Open Questions**: capture anything that came up during specification that wasn't
fully resolved. Each question has an owner and a target resolution date. Provisional
assumptions about unspecified dependencies belong here.

Use `AskUserQuestion`:
- "The required sections for this workflow tier are complete. Which of the
  remaining template sections do you want to define?"
  - Options: "Cross-References and Open Questions", "Also User Value / Dependencies (optional at this tier)", "Skip — I'll add these later"
  - List only those still outstanding, **minus** any this rule already made mandatory (offering to skip a mandatory section is how it gets skipped).
  - **Recommended option**: "Cross-References and Open Questions" when the feature has any dependency; "Skip" otherwise. `autonomous` needs a marked recommendation to pick.

  Do **not** state a section count here. The required set is tier-dependent
  (§1: 8 at `full`, 5 + conditional Edge Cases at `standard`, 5 at a voluntary
  `minimal`).

For a section that implies another artifact, output the pointer once it has real content:

> **UX Flag — [Feature Name]**: This feature has a user-facing surface. Before
> epics, run `/ux-design` for each screen it touches; stories that reference UI
> should cite `design/ux/[screen].md`.

> **Threat-model Flag — [Feature Name]**: Section G1 marked a sensitive area.
> Run `/threat-model [feature-name]` before `/story-readiness`.

---
