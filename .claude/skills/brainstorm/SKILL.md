---
name: brainstorm
description: "Guided SaaS product ideation: ICP, jobs-to-be-done, problem severity, alternatives, positioning, pricing model, distribution, riskiest assumptions. Writes the product brief."
argument-hint: "[market, problem or idea hint, or 'open'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, Agent, AskUserQuestion, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash "*/.claude/skills/brainstorm/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,docs.density,workflow,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# Brainstorm

`--review` overrides `review_mode`; store it for all gate spawns this run. See
`.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = principle bullets + brief bullets;
`balanced` = principles + brief with short rationale (`rigor: standard`); `thorough` =
principles + brief + extensive rationale + alternatives considered. Apply it to every section
you author.

**This skill designs a product, not a codebase.** It never picks the stack, a
framework or an API. Stack and tenancy are `/setup-stack`'s decision; this skill
records the *product-level* choices that constrain them (delivery model, pricing
model, compliance).

---

## Tier branch — check `workflow` FIRST

The `workflow` tier resolved above governs this skill's output:

- **`standard` / `full`** → run the full flow ("When this skill is invoked" through
  Phase 6 and the document generation). Output is `design/product-brief.md` with
  the fuller sections filled in, plus `design/product-principles.md`.
- **`minimal`** → run the **Lean Brief flow** immediately below and **STOP** — skip
  Phases 1–6, the director gates (PD-PRODUCT-PRINCIPLES / DD-CONCEPT-VISUAL /
  CTO-FEASIBILITY / PR-SCOPE), and the fuller sections entirely. Output is the
  one-page `design/product-brief.md`.

> **Minimal skips documents, never the riskiest-assumption question.** Even the
> lean brief records the one assumption that would kill the product and how it
> will be tested first (it becomes the first item of the build order).

### Lean Brief flow (`workflow: minimal` only)

A small-scope session: capture the load-bearing thinking in one page, then get
to code. Keep prompting light — a few exchanges, not fifteen. Author from the
one-page template `.claude/docs/templates/product-brief.md` (required fields
plus the recommended one-liners). If `design/product-brief.md` already exists,
read it and resume/refine rather than restart.

1. **Concept** — from the argument hint (or one quick open question if none), propose
   **2–3 one-line product concepts** (problem-first or mashup, per Phase 2's
   techniques). One `AskUserQuestion` to pick or combine — the only guaranteed
   creative prompt.
2. **Fill the brief fields** conversationally (not one prompt each):
   - **One-sentence pitch** — "X helps Y do Z without W".
   - **Problem** — the painful, frequent problem in the customer's words, and how they cope today.
   - **ICP** — one narrow segment and the trigger event that makes them buy.
   - **Jobs-to-be-done** — 3–5 jobs ("When…, I want to…, so I can…").
   - **Positioning** — name the real alternatives, including spreadsheets and doing nothing.
   - **Pricing model** — subscription / one-time licence / self-hosted annual licence / hybrid, with a price-point hypothesis and trial rule.
   - **Distribution** — hosted, self-hosted or both; channels; how the first 10 customers are found.
   - **MVP** — the ruthlessly short feature list (each becomes a story downstream). If it runs past ~7, push back on scope. Mark security-sensitive items (auth, billing, uploads, PII) — they need a threat model.
   - **Out of scope** — what is deliberately NOT being built.
   - **Success metric** — one activation metric and one revenue/retention metric, each with a number and a date.
   - **Build order** — risky / foundational thing first (integration, tenancy, billing, performance).
   - **Who it's for / what they feel**, **Brand & tone**, **Reference product**, **Compliance / data** — one line each (offer, don't force).
   Present the filled brief back in full for a single confirmation.
3. **Write approval** — `AskUserQuestion`: "Brief is ready. May I write it to
   `design/product-brief.md`?" → `[A] Yes — write it` / `[B] Revise a field first`. On
   [B], revise the named field, show before/after, re-ask; repeat until [A]. Then
   write `design/product-brief.md` from the template, creating directories as needed.
   Honor `modes.automation` for this write as elsewhere in the framework.
4. **Next steps** (short — this is the point). **Read the resolved `stack` line
   first and list `/setup-stack` only if it is absent, empty or `unset`:**
   1. *(only when the stack is not configured)* "`/setup-stack` — configure the stack, delivery model and tenancy (required before code)"
   2. "`/research [first-feature]` — write the research note before the first feature's code (DoD gate 1)"
   3. "`/create-stories` — turn the brief's MVP list into implementable stories. The
      epic is implicit at `minimal`; there is no separate `/create-epics` or
      `/sprint-plan` — the brief's build order is the plan."
   4. "`/dev-story` — first line of product code"

   > **Why the condition.** `/start`'s `minimal` path runs `/setup-stack`
   > *before* `/brainstorm`. Listing stack setup unconditionally tells a user who
   > just followed that path to go back and redo step one.
   Then output a one-line summary (pitch + MVP feature count + `design/product-brief.md`).

Verdict: **COMPLETE** — product brief created; next stop is code. Do NOT run Phases 1–6,
spawn any director gate, or write the fuller sections at this tier.

---

When this skill is invoked (`standard` / `full` tier — `minimal` uses the Lean Brief
flow above):

1. **Parse the argument** for an optional market/problem hint (e.g., `clinic
   scheduling`, `invoice reconciliation`, `field-service apps`). If `open` or no
   argument, start from scratch.

2. **Check for existing product work**:
   - Read `design/product-brief.md` if it exists (resume, don't restart)
   - Read `design/product-principles.md` if it exists (build on established principles)
   - Glob `docs/research/` for market or competitor notes already gathered

3. **Run through ideation phases** interactively, asking the user questions at
   each phase. Do NOT generate everything silently — the goal is **collaborative
   exploration** where the AI acts as a product-discovery facilitator, not a
   replacement for the founder's insight into the customer.

   **Use `AskUserQuestion`** at key decision points throughout brainstorming:
   - Constrained questions (segment, delivery model, team size, runway)
   - Concept selection ("Which 2-3 concepts resonate?") after presenting options
   - Direction choices ("Develop further, explore more, or run a discovery test?")
   - Principle ranking after concepts are refined
   Write full analysis in conversation text first, then use
   `AskUserQuestion` to capture the decision with concise labels.

   Discovery principles to follow:
   - Withhold judgment — no idea is bad during exploration
   - Start from a customer's problem, not from a technology or feature
   - Build on each other — "yes, and..." responses, not "but..."
   - Use constraints as fuel — a solo founder, a runway, a regulated market narrow the search usefully
   - Time-box each phase — keep momentum, don't over-deliberate early
   - Separate what the user *knows* (talked to customers) from what they *believe* — label each

---

### Phase 1: Founder and Market Discovery

Start by understanding the person and the problem space, not the product. Ask
these conversationally (not as a checklist):

**Problem anchors**:
- What is a painful, repeated workflow you have personally watched someone struggle with — or struggled with yourself? What did it cost them (hours, money, errors, risk)?
- Who pays today to solve it — with a tool, a person, or a spreadsheet?

**Evidence profile** *(ask as plain text — the user must be able to type specifics freely; do NOT put this in an `AskUserQuestion` with preset options)*:
- Which people have you actually spoken to about this problem? What did they say, in their words?
- Which 3 products do those people use today? What do they complain about?

**Practical constraints** (shape the sandbox before brainstorming).
Bundle these into a single multi-tab `AskUserQuestion` with these exact tab labels:
- Tab "Customer" — "Who is the likeliest buyer?" (Small business owner / Team lead inside a company / Enterprise IT or procurement / Individual professional)
- Tab "Runway" — "What is your realistic time to first paying customer?" (Weeks / Months / 6-12 months / Longer)
- Tab "Team" — "Who builds and runs this?" (Solo founder / Small team / Funded team with sales)

Use exactly these tab names — do not rename or duplicate them.

**Synthesize** the answers into a **Discovery Brief** — a 3-5 sentence
summary of the problem space, the evidence the user already has, and the
constraints. Read it back and confirm it captures their intent.

---

### Phase 2: Concept Generation

Using the discovery brief as a foundation, generate **3 distinct concepts**
that each take a different direction. Use these techniques:

**Technique 1: Job-First (Jobs-to-be-Done)**
Start from the job a customer "hires" a product for: "When [situation], I want
to [motivation], so I can [outcome]." The job IS the product. Ask what they hire
today, what they fire, and what triggers the switch.

**Technique 2: Wedge and Expand**
Find the narrow, painful, frequent task that gets a foot in the door, then the
adjacent jobs the same buyer will pay for next. A wedge that is small, urgent
and sold to one person beats a platform pitch.

**Technique 3: Mashup Method**
Combine an underserved segment with a proven category: [Vertical or region] +
[Known SaaS pattern]. The tension creates the hook (e.g. "owner-run clinics in
Egypt" + "appointment reminders with deposits").

**Technique 4: Opportunity-Solution Tree**
Start from the outcome the customer wants, branch into opportunities (unmet
needs, pains), then into candidate solutions per opportunity. Choose the
opportunity first; solutions come second.

For each concept, present:
- **Working Name**
- **Elevator Pitch** (1-2 sentences — must pass the "10-second test")
- **ICP** (one narrow segment) and the **trigger event** that makes them buy
- **Core Job** (the single most important job-to-be-done)
- **Alternatives they use today** (including spreadsheets and doing nothing) and the **switching cost**
- **Unique Hook** (passes the "and also" test: "Like X, AND ALSO Y")
- **Problem severity and frequency** (high/medium/low each, with the reason)
- **Estimated Scope** (small / medium / large)
- **Biggest Risk** (1 sentence on the hardest unanswered question)

Present all three. Then use `AskUserQuestion` to capture the selection.

**This decision asks regardless of `modes.automation`.** Concept selection
is the creative heart of `/brainstorm` and has no defensible autonomous
default — there is no algorithmic way to pick which product direction
resonates with the founder. Per `.claude/docs/automation-modes.md`, treat
this site as exempt (it overrides the mode the same way
`automation_always_ask` categories do).

**CRITICAL**: This MUST be a plain list call — no tabs, no form fields, and
exactly four options (the tool rejects a fifth). Use exactly this structure:

```
AskUserQuestion(
  prompt: "Which concept resonates with you? Pick one or combine elements — or type 'fresh directions' under Other for new angles.",
  options: [
    "Concept 1 — [Name]",
    "Concept 2 — [Name]",
    "Concept 3 — [Name]",
    "Combine elements across concepts"
  ]
)
```

"Generate fresh directions" is not an option: the tool's automatic **Other**
field carries it. If the answer under Other asks for new angles, return to the
techniques above and generate three new concepts.

Do NOT use a `tabs` field here. The `tabs` form is for multi-field input only — using it here causes an "Invalid tool parameters" error. This is a plain `prompt` + `options` call.

Never pressure toward a choice — let them sit with it.

---

### Phase 3: Problem, Jobs and Value

For the chosen concept, use structured questioning to test whether the problem
is worth a product. If the problem is not painful or frequent, no amount of
features will save it.

Ask these as `AskUserQuestion` calls — derive the options from the chosen concept, don't hardcode them:

1. **Trigger and frequency** — prompt: "How often does the customer hit this problem?" Generate 3-4 options that fit the concept (daily / weekly / monthly / once a year), plus a free-text escape (`I'll describe it`).
2. **Cost of the status quo** — identify the dominant cost (time, money, compliance risk, lost revenue) for this concept and ask about it. Always include a free-text escape.

Then work through, conversationally:

**Jobs-to-be-done** — write 3-5 jobs as "When [situation], I want to [motivation],
so I can [outcome]." Mark the *core* job; the rest are supporting. Each MVP
feature must trace to one.

**Kano pass** — sort the candidate capabilities: *must-haves* (absent, they leave
the product unusable), *performance* (more is better), *delighters* (unexpected
value). The MVP is the must-haves plus at most one delighter.

**Alternatives and switching cost** — for each real alternative (incumbent tool,
spreadsheet, agency, doing nothing): what it does well, where it fails the core
job, and what it costs to leave it (data migration, retraining, contracts).
The product must beat the *switching cost*, not just the feature list.

**Value-vs-effort** — place the candidate features on a 2x2 (customer value vs
build effort + risk). Quick wins and big bets go in the MVP candidates; the
low-value/high-effort quadrant goes to "Out of scope".

**Product motivation check** (does the product earn a recurring payment?):
- **Frequency**: how often will the buyer open it?
- **Outcome**: what measurable outcome does the buyer see (hours saved, money recovered, risk avoided)?
- **Stickiness**: what data, workflow or integration makes it painful to leave?

---

### Phase 4: Principles and Boundaries

Product principles keep a team (and its agents) making decisions that all point
the same way. Even for a solo founder, principles prevent scope creep and keep
the product coherent.

Collaboratively define **3-5 principles**:
- Each principle has a **name** and **one-sentence definition**
- Each principle has a **design test**: "If we're debating between X and Y,
  this principle says we choose __"
- Principles should feel like they create tension with each other — if all
  principles point the same way, they're not doing enough work
- A principle every competitor would also claim ("simple", "secure", "fast") must carry a measurable form

Then define **3+ anti-principles** (what this product is NOT):
- Anti-principles prevent the most common form of scope creep: "wouldn't it
  be nice if..." requests that don't serve the core value
- Frame as: "We will NOT do [thing] because it would compromise [principle]"

**Principle confirmation**: After presenting the full set, use `AskUserQuestion`:
- Prompt: "Do these principles feel right for your product?"
- Options: `[A] Lock these in` / `[B] Rename or reframe one` / `[C] Swap a principle out` / `[D] Something else`

If the user selects B, C, or D, make the revision, then use `AskUserQuestion` again:
- Prompt: "Principles updated. Ready to lock these in?"
- Options: `[A] Lock these in` / `[B] Revise another principle` / `[C] Something else`

**At `collaborative`** — repeat until the user selects [A] Lock these in.
**At `guided`** — principles are a major decision, so ask once; apply the chosen
revision and lock them in without a second confirmation round.
**At `autonomous`** — do not ask. Lock in the drafted principles and record them via
`log_decision` with the alternatives considered.

> An `autonomous` run never issues the question, so "repeat until [A]" has no
> exit condition (`automation-modes.md`).

**Review mode check** — apply before spawning PD-PRODUCT-PRINCIPLES and DD-CONCEPT-VISUAL:
- `solo` → skip both. Note: "PD-PRODUCT-PRINCIPLES skipped — Solo mode. DD-CONCEPT-VISUAL skipped — Solo mode." Proceed to Phase 5.
- `lean` → skip both (not PHASE-GATEs). Note: "PD-PRODUCT-PRINCIPLES skipped — Lean mode. DD-CONCEPT-VISUAL skipped — Lean mode." Proceed to Phase 5.
- `full` → spawn as normal.

**After principles and anti-principles are agreed, spawn BOTH `product-director` AND `design-director` via `Agent` in parallel before moving to Phase 5. Issue both `Agent` calls simultaneously — do not wait for one before starting the other.**

- **`product-director`** — gate **PD-PRODUCT-PRINCIPLES** (`.claude/docs/director-gates/pd-product-principles.md`)
  Pass: the full principle set with design tests, anti-principles, core value statement (ICP, core job, outcome), positioning and closest alternatives.

- **`design-director`** — gate **DD-CONCEPT-VISUAL** (`.claude/docs/director-gates/dd-concept-visual.md`)
  Pass: the product elevator pitch, ICP, full principle set with design tests, target platforms (from the resolved `stack` line, if known), locales (Arabic and English, RTL), and any reference products or visual touchstones the user mentioned.

Collect both verdicts. When PD-PRODUCT-PRINCIPLES returns APPROVE, present them together using a two-tab `AskUserQuestion`:
- Tab **"Principles"**: present product-director feedback. Options mirror the standard handling — `Lock in as-is` / `Revise [specific principle]` / `Discuss further`.
- Tab **"Visual anchor"**: present the design-director's 2-3 named visual direction options. Options: each named direction (one per option, at most three) + `Combine elements across directions`; the user describes their own direction under the tool's automatic **Other** field (four options is the tool's limit). On **STRONG**, mark the dominant direction `(Recommended)`. On **CONCERNS** (the principles do not yet differentiate a visual identity), show the design-director's reason instead of directions and offer `Revise principles` / `Describe my own direction`.

The user's selected visual anchor is stored as the **Visual Identity Anchor** — it is written into the brief and seeds `/impeccable` (`PRODUCT.md`, `DESIGN.md`).

If PD-PRODUCT-PRINCIPLES returns CONCERNS or REJECT, resolve principle issues before asking for the visual anchor selection — visual direction should flow from confirmed principles. Ask the Principles question on its own first (same options, no Visual anchor tab); once resolved, ask the Visual anchor question on its own. **NOT ASSESSED** from either gate (it lacked an input — `.claude/docs/director-gates.md`) is not an approval: name what was missing, supply it and re-run that gate; failing that, treat a PD-PRODUCT-PRINCIPLES NOT ASSESSED like CONCERNS, and with no design-director directions offer only `Describe my own direction`.

---

### Phase 5: Customer and Market Validation

Using jobs-to-be-done and willingness-to-pay evidence, validate who this
product is actually for:

- **Primary ICP**: Who will LOVE this product? Segment, size, region, buyer vs. user, trigger event.
- **Secondary buyer/user**: Who else touches it (admin, member, end customer, self-hosted operator)?
- **Who is this NOT for**: Being clear about who will not buy is as important as knowing who will.
- **Market validation**: Which competitors serve this segment? Their price points, strengths and gaps. Use `WebSearch` only for facts the user asks to verify, and cite the source in the brief; mark anything unsourced as **an assumption**, never as a finding.
- **Willingness to pay**: What evidence exists (quotes, current spend, a pre-sale)? Opinions are not evidence.

---

### Phase 6: Pricing, Distribution, Scope and Feasibility

Ground the concept in reality:

- **Pricing model**: Use `AskUserQuestion` — "How will the product charge?"
  Options: `Annual / monthly subscription (per seat, usage or flat tier)` / `One-time licence (+ optional maintenance)` / `Self-hosted enterprise annual licence` / `Hybrid — decide below`
  Record the choice and a price-point hypothesis, trial rule and billing currency. Detail is `/design-spec`'s and the `pricing-billing-designer`'s job (`.claude/docs/templates/pricing-model.md`); the brief carries only the hypothesis.
- **Distribution**: Use `AskUserQuestion` — "How is it delivered?"
  Options: `Hosted multi-tenant only` / `Self-hosted bundle only` / `Both (hybrid)` / `Not sure yet`
  - **This decision always prompts regardless of `modes.automation` —
    including `autonomous` mode.** Hosted versus self-hosted decides tenancy,
    licensing, the update channel and the support model, and downstream tooling
    depends on it. It is NOT left to the configurable `automation_always_ask`
    list. The model must NOT silently pick a delivery model.
  - If they pick a model → record it and move on. Do NOT second-guess it. `/setup-stack` writes it into `project.yaml`.
  - If "Not sure yet" → say: "Run `/setup-stack` after this session — it walks the decision with your pricing model and buyer in mind." Do not recommend here.
- **Channels**: web app, Android, iOS, marketing site, direct sales. Note what each implies (store review times, sales cycle).
- **Content/feature scope**: number of core features, roles, integrations, locales (Arabic and English by default).
- **MVP definition**: What is the absolute minimum build that tests "will the target customer pay for this job?"
- **Riskiest assumptions**: Use the table below. List every assumption the product depends on, rank by *impact if wrong x uncertainty*, and write a cheapest-test for the top three. Do not leave the list at "it might not sell".

  | Assumption | Type (desirability / viability / feasibility / compliance) | Impact if wrong | Evidence today | Cheapest test | Pass signal |
  |---|---|---|---|---|---|

  Test ideas: 5-8 customer interviews, a landing page with a pre-sale or waitlist, a concierge/manual MVP, a clickable prototype (`/prototype`), a technical spike for the one integration or performance claim the product stands on.
- **Compliance and data**: PDPL / GDPR relevance, regulated data, payment handling (hosted checkout only), data residency.
- **Scope tiers**: What is the full vision vs. what ships if time runs out?

**Review mode check** — apply before spawning CTO-FEASIBILITY:
- `solo` → skip. Note: "CTO-FEASIBILITY skipped — Solo mode." Proceed directly to scope tier definition.
- `lean` → skip (not a PHASE-GATE). Note: "CTO-FEASIBILITY skipped — Lean mode." Proceed directly to scope tier definition.
- `full` → spawn as normal.

**After identifying the biggest technical risks, spawn `cto` via `Agent` using gate CTO-FEASIBILITY (`.claude/docs/director-gates/cto-feasibility.md`) before scope tiers are defined.**

Pass: the core journey, distribution model, stack profile (or "undecided"), and the list of identified technical risks.

Present the assessment to the user. If HIGH RISK, offer to revisit scope before finalising. If CONCERNS, note them and continue. If NOT ASSESSED, name the missing input and record feasibility as not assessed in the brief's risks — never as VIABLE.

**Review mode check** — apply before spawning PR-SCOPE:
- `solo` → skip. Note: "PR-SCOPE skipped — Solo mode." Proceed to document generation.
- `lean` → skip (not a PHASE-GATE). Note: "PR-SCOPE skipped — Lean mode." Proceed to document generation.
- `full` → spawn as normal.

**After scope tiers are defined, spawn `producer` via `Agent` using gate PR-SCOPE (`.claude/docs/director-gates/pr-scope.md`).**

Pass: full vision scope, MVP definition, the scope tiers (what ships if time runs out), timeline estimate, team size.

Present the assessment to the user. PR-SCOPE answers REALISTIC / OPTIMISTIC /
UNREALISTIC. If UNREALISTIC, ask via `AskUserQuestion` whether to adjust the MVP
definition or scope tiers before writing the document or keep them — the user
decides; the concept is never rejected for it. If OPTIMISTIC, show the
producer's suggested adjustments and ask whether to apply them before writing. If NOT ASSESSED, name
the missing input (a timeline or team size, say) and ask for it and re-run the
gate, or record scope as not assessed — never as REALISTIC.

---

4. **Generate the documents** from the templates:
   - `design/product-brief.md` from `.claude/docs/templates/product-brief.md`, with the one-page fields AND the "Fuller sections" (market and competitors, personas, pricing hypotheses and unit economics, risks and assumptions, success metrics and targets, roadmap) filled from the conversation.
   - `design/product-principles.md` from `.claude/docs/templates/product-principles.md`.

   **Include a Visual Identity Anchor** in the brief (when DD-CONCEPT-VISUAL ran or the user supplied one) with:
   - The selected visual direction name
   - The one-line visual rule
   - The 2-3 supporting visual principles with their design tests
   - The colour philosophy summary

   It is the seed for `/impeccable` (`PRODUCT.md`, `DESIGN.md`); it does not replace them.

   **Decision log**: record the foundation choices made here (delivery model, pricing model, compliance posture) in the brief's decision log with date, reason and rejected alternatives.

5. Use `AskUserQuestion` for write approval:
- Prompt: "Product brief is ready. May I write it to `design/product-brief.md` and the principles to `design/product-principles.md`?"
- Options: `[A] Yes — write it` / `[B] Not yet — revise a section first`

If [B]: ask which part to revise using `AskUserQuestion` with four grouped options (the tool's limit): `Product & customer — pitch, problem, ICP, jobs, positioning, alternatives` / `Pricing & distribution` / `Principles` / `Scope & risk — MVP, scope tiers, risks and assumptions`. Anything else goes under the automatic **Other** field. When a group holds several sections, ask in plain text which one.

After revising, show the updated section as a diff or clear before/after, then use `AskUserQuestion` — "Ready to write the updated brief?"
Options: `[A] Yes — write it` / `[B] Revise another section`
**At `collaborative`** — repeat until the user selects [A].
**At `guided`** — ask once; apply the requested revision and write the documents
without a further confirmation round.
**At `autonomous`** — do not ask; write the documents and record the decision via
`log_decision`.

> Same exit-condition problem as the principles loop above (`automation-modes.md`).

If yes, write the files, creating directories as needed. If the user declines
the write (including a final decline after `[B]` revisions), write nothing and end
with `Verdict: **BLOCKED** — write declined by user`; the summary below is not
produced as a completed brief.

**Scope consistency rule**: The scope estimate in the brief must match the
full-vision timeline from the scope tiers — not just say "Large". Write it as
"Large (X–Y months, solo)" or "Large (X–Y months, team of N)" so the summary is accurate.

6. **Suggest next steps** (in this order). List ALL steps — do not abbreviate or truncate:

**Path A — Design-First** (recommended if the problem and ICP are well-evidenced):
   1. "Run `/setup-stack` to configure stack, delivery model and tenancy, and populate version-pinned reference docs"
   2. "Run `/impeccable init` to write `PRODUCT.md` (product truth: users, brand, voice, constraints) — do this BEFORE UX specs; the Visual Identity Anchor seeds it. `DESIGN.md` (the visual system) is not written by init: it is created with the first screen's visual work (`/ux-design`, `/team-ui` → impeccable new work) or by `/impeccable document` from existing UI"
   3. "Check the brief against `.claude/docs/templates/product-brief.md` before going downstream — every `[...]` placeholder filled or marked an assumption (`/spec-review` reviews feature specs, not the brief; it applies once `/design-spec` has produced one)"
   4. "Decompose the product into bounded contexts and features with `/map-domains` — maps dependencies, assigns priorities, flags `saas-core` module candidates, and creates the domain map"
   5. "Author per-feature specs with `/design-spec` — guided, section-by-section spec writing for each feature identified in step 4"
   6. "Plan the technical architecture with `/create-architecture` — contexts, ports, data stores, tenancy, deployment, and the Required ADR list"
   7. "Record key architectural decisions with `/architecture-decision (×N)` — one ADR per decision in the Required ADR list (critical ones only at `standard`; at `minimal` an entry in the brief's decision log instead)"
   8. "Run `/architecture-review` — traceability from spec requirements to ADRs (required before the Pre-Production gate)"
   9. "Validate readiness to advance with `/gate-check` — phase gate before committing to production"

**Path B — Test-First** (use if a riskiest assumption is technical or the core experience is unproven):
   1. "Run `/setup-stack` to configure the stack"
   2. "Run `/prototype [riskiest-assumption]` — a throwaway spike that answers the one question (1–3 days)"
   3. "If the prototype PROCEEDS: continue with Path A from step 2, using the learnings in your specs"
   4. "If it PIVOTS: return to `/brainstorm` with the learnings and reshape the concept"
   5. "After design and architecture, build the `/vertical-slice` to prove the architecture end to end before committing to sprints"

**Path C — Customer-First** (use if desirability, not feasibility, is the riskiest assumption):
   1. "Run the cheapest test from the assumptions table (interviews, landing page, pre-sale) before any design work"
   2. "Return to `/brainstorm` with the evidence and tighten the ICP, pricing hypothesis and MVP"

7. **Checkpoint.** Update `production/session-state/active.md` per
   `.claude/docs/checkpoint-handoff.md`: Current task `/brainstorm <idea> —
   COMPLETE` (or the blocker), Next step = the chosen path's first step, plus
   Blocked on / Files in progress / Open questions; append the Notes line, and
   put the chosen path (A / B / C) with its ordered steps there in a few lines.
   Still updated when the user declines the brief write (record nothing written
   and why) or a gate returns NOT ASSESSED.
8. **Output a summary** with the chosen concept's elevator pitch, ICP, core job, principles, pricing model, delivery model, biggest risk and its cheapest test, and the file paths.

Verdict: **COMPLETE** — product brief created and handed off for next steps.

---

## Context Window Awareness

This is a multi-phase skill. If context reaches or exceeds 70% during any phase,
append this notice to the current response before continuing:

> **Context is approaching the limit (≥70%).** The product brief is saved
> to `design/product-brief.md`. Open a fresh Claude Code session to continue
> if needed — progress is not lost.

---

## Collaborative Protocol

This skill is facilitation, not authorship. The user owns the customer insight;
the skill structures it, challenges it and writes it down.

- Question → Options → Decision → Draft → Approval at every phase.
- Never invent customer evidence, market sizes or competitor prices. Anything
  not provided by the user or sourced via `WebSearch` is labelled
  **assumption**. A gap that cannot be sourced is written as
  `NOT SOURCEABLE — <what>` and carried into the risks table, not filled from memory.
- A director gate that was skipped (solo/lean) or returned NOT ASSESSED is
  reported as such in the summary, never as approved.
- Ask "May I write this to [filepath]?" before every write; show the full draft first.
- A skipped or dismissed question is not an answer: re-ask in plain text and wait.

## Recommended Next Steps

After the brief is written, follow the pipeline in order:
1. `/setup-stack` — configure stack, delivery model, tenancy and version pins
2. `/impeccable` — establish `PRODUCT.md` / `DESIGN.md` before any UX spec
3. `/map-domains` — decompose the product into bounded contexts and features
4. `/design-spec [first-feature]` — author per-feature specs in dependency order
5. `/create-architecture` — produce the architecture blueprint
6. `/architecture-review` — traceability from specs to ADRs
7. `/gate-check` — validate readiness for the next phase
