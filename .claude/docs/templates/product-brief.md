# Product Brief: [Working Title]

<!--
THE ONE-PAGE BRIEF. At the `minimal` workflow tier this is the ENTIRE product
design doc — it replaces the full concept, domain decomposition and per-feature
specs. Keep it to one screen. If a field needs a second paragraph, you are
writing a spec, not a brief. Fill every REQUIRED field; the RECOMMENDED lines are
cheap but optional. The stack is set separately (project.yaml / /setup-stack) —
list it here only as a one-line summary of the chosen profile.

At `standard` and `full`, this brief is followed by fuller sections (see the end
of this file): market and competitors, personas, pricing hypotheses, risks,
success metrics, and a roadmap. Add them when the tier requires them.
-->

**One-sentence pitch:** [What it is, for whom, and the outcome — "X helps Y do Z without W". If it takes two sentences, cut until it is one.]

## Problem
<!-- The painful, frequent, expensive problem — in the customer's words. Who has it, how they cope today, and what that costs them (time, money, risk). 2–4 lines. -->
-

## ICP — ideal customer profile
<!-- Segment, size, region, buyer vs. user, trigger event that makes them buy. Be narrow: "owner-run clinics in Egypt with 1–5 doctors", not "SMBs". -->
-

## Jobs-to-be-done
<!-- 3–5 jobs in "When [situation], I want to [motivation], so I can [outcome]". Each MVP feature traces to one. -->
1.

## Positioning
<!-- For [ICP] who [need], [product] is a [category] that [key benefit]. Unlike [alternative], we [differentiator]. Name the real alternatives, including spreadsheets and doing nothing. -->
-

## Pricing model
<!-- Choose and justify. Detail goes in pricing-model.md once past minimal. -->
- **Model**: [subscription (per seat / per usage / flat tiers) · one-time licence · hybrid (licence + maintenance) · self-hosted annual licence · free + paid]
- **Plans / price points (hypothesis)**: [e.g. Starter EGP 299/mo, Team EGP 899/mo, Enterprise custom]
- **Trial / free tier**: [length, limits, card required?]
- **Billing**: [provider; currencies; tax/VAT handled by]

## Distribution
<!-- How the product reaches and is delivered to customers. -->
- **Delivery**: [hosted multi-tenant · self-hosted enterprise bundle · both]
- **Channels**: [web app · Android · iOS · marketing site · direct sales · app stores]
- **Acquisition**: [how the first 10 customers are found]

## Stack (profile)
<!-- One line; the source of truth is project.yaml. -->
[backend: Go|Ktor · web: Vite+React · site: Astro · mobile: Compose/KMP/SwiftUI · data: Postgres/Mongo/Redis/Dragonfly · deploy: Docker Compose · tenancy: <model> · core: saas-core-<track>]

## MVP — what must exist to be the product
<!-- The ruthlessly short list of features without which this ISN'T the product yet. Each one becomes a story. Longer than ~7 and it's not an MVP. Mark the security-sensitive ones (auth, billing, uploads, PII) — they need a threat model. -->
-

## Out of scope — not building this
<!-- The list that saves the project. Be specific: "no SSO in v1", "no mobile app", "no self-hosted until 5 paying hosted customers". -->
-

## Success metric — what "working" looks like
<!-- One activation metric and one revenue/retention metric, with a number and a date. The field your stories' ACCEPTANCE CRITERIA and the tracking plan trace back to. -->
-

## Build order
<!-- The sequence to build the MVP. Riskiest thing (integration, performance, tenancy, billing) FIRST — prove it works before you polish. -->
1.

## Decision log
<!-- At `minimal` this REPLACES ADR files. One line per decision: date — decision — why — alternatives rejected. Foundation decisions (tenancy, identity, data store, API style, deployment, licensing) must appear here. -->
| Date | Decision | Why | Rejected alternatives |
|------|----------|-----|----------------------|

---
<!-- RECOMMENDED — one line each; delete a line only if truly N/A. -->
**Who it's for / what they feel:** [One line: the buyer and the feeling — e.g. "clinic owners who want to stop chasing paper records."]

**Brand & tone:** [One line of intent — feeds impeccable's PRODUCT.md/DESIGN.md.]

**Reference product:** [One shipped product this is closest to, and the ~10% of it the MVP keeps. Scoping against a real product is the fastest honest MVP check.]

**Compliance / data:** [PDPL/GDPR relevance, data residency, regulated data, payment handling (hosted checkout only)]

---

## Fuller sections (standard / full tiers — add below when required)

<!-- Add these as the tier requires; /brainstorm writes them at standard/full. -->

### Market & competitors
[Market size basis, 3–5 competitors with price, strengths, gaps; sources cited.]

### Personas
[Tenant admin, member, end customer, self-hosted operator — goals, context, devices, languages (AR/EN).]

### Pricing hypotheses & unit economics
[Cost per tenant (infra + support), target gross margin, willingness-to-pay evidence, link to `pricing-model.md`.]

### Risks & assumptions
[Riskiest assumptions with how each will be tested; link risk-register entries.]

### Success metrics & targets
[Activation, retention, expansion, support load; targets per milestone; link to `tracking-plan.md`.]

### Roadmap
[Milestones: vertical slice, private beta, GA; features per milestone.]

### Visual Identity Anchor
[Written by `/brainstorm` from the DD-CONCEPT-VISUAL gate or the user's own direction: the one-line visual rule and its supporting principles. When the gate was skipped and nothing was supplied, write "None yet — <reason>; set by `/impeccable`". Seeds `PRODUCT.md` / `DESIGN.md`.]

### Product principles
[Link to `design/product-principles.md`.]
