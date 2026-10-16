# User Journey Map: [Product Title]

> **Status**: Draft | In Review | Approved
> **Author**: [product-manager / ux-designer]
> **Last Updated**: [Date]
> **Links To**: `design/product-brief.md`, `design/product-principles.md`, `design/growth/` (activation metrics, lifecycle journeys)

---

## Journey Overview

[One paragraph capturing the full arc from first visit to long-term customer
(or to a clean exit). Describe it in terms of the customer's confidence and
outcomes, not the feature list: where they start (sceptical, busy, comparing
alternatives), what makes them trust the product, the moment it first saves
them real effort, and what keeps it embedded in their work afterward.

If this arc cannot be described in one paragraph, the product value is not yet
clear enough — resolve that before filling in the phases below.]

---

## Target Personas

[3–4 lines per persona describing their situation and mindset, not demographics:
role in the account (buyer / admin / member / end customer / self-hosted
operator), the tools they use today, how patient they are with setup, whether
they read docs or ask a colleague, languages (Arabic / English), devices (desktop
vs. phone), and what they are accountable for.]

| Persona | Role in account | Job to be done | Primary device / language | What they fear |
|---------|----------------|----------------|--------------------------|----------------|

---

## Journey Phases

> **Guidance**: The phases below are the standard template. Not every product
> has every phase. A self-serve tool may merge Evaluate and Sign-up; an
> enterprise self-hosted product adds Procurement and Install. Delete or merge
> phases that genuinely do not apply — do not fill them with placeholders.

---

### Phase 1: Discover & Evaluate (before sign-up)

**State on arrival**: [Comparing alternatives; has a problem and a deadline.]
**Primary question**: [e.g. "Does this solve my problem?", "What does it cost?", "Can I trust it with my data?"]
**Key experience the product must deliver**: [What the marketing site / listing / demo must make obvious within a minute: the outcome, the price, the trust signals (security, data location, support).]
**State on exit**: [e.g. "Starts a trial", "Books a demo", "Downloads the self-hosted evaluation bundle."]
**Risk if this phase fails**: [Bounces to a competitor; never registers.]
**Surfaces**: [marketing site (`site/`), store listing, docs, pricing page]

---

### Phase 2: Sign-up & First Value (0–10 minutes)

**State on arrival**: [Motivated but impatient; will abandon at the first friction.]
**Primary question**: [e.g. "Is this going to be a hassle?", "What do I do first?"]
**Key experience the product must deliver**: [The shortest path to the first moment of value — the "aha". Minimal form fields, no card for trial if that is the model, sample data or guided first action, clear empty states.]
**Activation event**: [The measurable event that defines "activated", e.g. "first invoice sent". Must match `tracking-plan.md`.]
**State on exit**: [Has done one real thing and seen the result.]
**Risk if this phase fails**: [Sign-up without activation; never returns.]

---

### Phase 3: Set-up & Adoption (first week)

**State on arrival**: [Wants to make it work for their team or data.]
**Primary question**: [e.g. "How do I get my data in?", "How do I invite my team?", "Is this configured right?"]
**Key experience the product must deliver**: [Import, integrations, invitations, roles and billing set-up that feel guided and reversible. Progress is saved; errors explain how to fix them; Arabic and English are equally complete.]
**State on exit**: [Team members active; real data present; first recurring use scheduled.]
**Risk if this phase fails**: [Stalls half-configured; trial expires unused.]

---

### Phase 4: Habitual Use (weeks 2–12)

**State on arrival**: [The product is part of a routine.]
**Primary question**: [e.g. "Can I do this faster?", "Can I trust the numbers?", "What am I missing?"]
**Key experience the product must deliver**: [Speed, reliability and consistency on the core workflow; shortcuts, saved views, notifications that matter; visible results (time saved, money recovered).]
**State on exit**: [Would be unhappy to lose it; mentions it to colleagues.]
**Risk if this phase fails**: [Quiet disengagement; churn at first renewal.]

---

### Phase 5: Expansion & Upgrade

**State on arrival**: [Hits a limit or sees a capability that others in the account want.]
**Primary question**: [e.g. "What does the next plan give me?", "What happens to my data if I upgrade?"]
**Key experience the product must deliver**: [Limits shown before they hurt; upgrade in two clicks with an honest proration preview; no loss of work; admins can add seats without contacting sales.]
**State on exit**: [Upgraded or added seats confidently.]
**Risk if this phase fails**: [Hard wall with no path forward; workaround via a second account; resentment of pricing.]

---

### Phase 6: Renewal & Retention

**State on arrival**: [Renewal is approaching; budget owner re-evaluates.]
**Primary question**: [e.g. "Did this earn its cost?", "Is there something cheaper?"]
**Key experience the product must deliver**: [Usage and value summaries; reminder before renewal with the amount; easy payment-method update; dunning that is firm but respectful.]
**State on exit**: [Renewed; or pauses with the door open.]
**Risk if this phase fails**: [Involuntary churn from failed payments; surprise charges and refunds.]

---

### Phase 7: Offboarding (cancel, export, delete)

**State on arrival**: [Leaving, or being asked to.]
**Primary question**: [e.g. "Can I get my data out?", "Will I be charged again?"]
**Key experience the product must deliver**: [Cancellation as easy as sign-up; full data export; clear retention period before deletion; confirmation; a re-activation path.]
**State on exit**: [Leaves with their data and a positive memory — the most likely source of a future return or referral.]
**Risk if this phase fails**: [Chargebacks, public complaints, regulatory exposure (PDPL/GDPR rights).]

---

## Critical Moments

> **Guidance**: Specific individual events — not phases — that must land with
> precision. A missed critical moment can derail the whole journey. Identify
> 8–15 across the journey.

| Moment | Phase | Target outcome | If It Fails |
|--------|-------|---------------|-------------|
| [Verification email arrives within seconds] | [Sign-up] | [Reaches the app in under a minute] | [Abandons; email never found] |
| [First successful import/action] | [First Value] | [Visible result — "it worked"] | [Cryptic error; support ticket or churn] |
| [Invite accepted by a teammate] | [Adoption] | [Team presence; shared data] | [Admin sole user; low stickiness] |
| [Limit reached / upgrade prompt] | [Expansion] | [Clear options, no data loss] | [Perceived extortion] |
| [Payment failure notice] | [Renewal] | [Fix in one step] | [Involuntary churn] |
| [Cancellation + export] | [Offboarding] | [Calm, complete exit] | [Anger, chargeback] |
| [Add moment] | [Phase] | [Target] | [Failure consequence] |

---

## Lifecycle Hooks (Retention & Re-engagement)

> **Guidance**: Mechanisms that bring a customer back or keep value visible.
> Map each to the feature, email or notification that delivers it — a hook with
> nothing behind it is an aspiration, not a design. Detailed journeys live in
> `design/growth/`.

| Hook Type | Hook Description | Delivered by |
|-----------|-----------------|--------------|
| **Session start** | [What greets a returning user — what changed, what needs attention] | [dashboard, inbox, notifications] |
| **Session end** | [What they leave with — saved state, scheduled next step] | [autosave, summary email] |
| **Weekly value** | [Reason to return this week — a digest, a due item, a report] | [digest email, reports] |
| **Long-term** | [Value that compounds — history, integrations, team data] | [data model, integrations] |
| **Win-back** | [What re-engages a dormant account without spam] | [lifecycle email with consent] |

---

## Perceived Progress

[Describe HOW the customer should experience their progress — not the feature
set, but the feeling of getting somewhere. Choose a primary feeling and describe
it concretely at the start, middle and end of the relationship.

- **Time saved**: "Work that took an afternoon takes ten minutes; the product shows the hours saved."
- **Control**: "The mess is organised; nothing slips through."
- **Confidence**: "The numbers are right and auditable; compliance questions have answers."
- **Team leverage**: "More people do more without asking the admin."
- **Growth**: "The product scales with the business without a migration."]

---

## Anti-Patterns to Avoid

> **Guidance**: Recurring mistakes that reliably break a SaaS journey. List the
> ones most relevant to this product and how the design guards against them.
> "Avoid bad UX" is a platitude, not an anti-pattern.

- **[Forced signup wall before any value]**: [e.g. "Sample workspace is available before registration."]
- **[Silent data loss or unrecoverable action]**: [e.g. "Destructive actions have undo or a confirm with consequences stated; deletion has a retention window."]
- **[Surprise charges]**: [e.g. "Every price change shows the amount and date before confirmation; renewal reminder 7 days before."]
- **[Dark patterns on cancel]**: [e.g. "Cancel is reachable from settings in two clicks; no retention maze."]
- **[Limits discovered by hitting a wall]**: [e.g. "Quota meters visible at 80%; upgrade path explained."]
- **[Blank states with no next step]**: [e.g. "Every empty state names the first action."]
- **[Arabic as an afterthought]**: [e.g. "RTL layouts and Arabic copy reviewed at design time, not translated at the end."]
- **[Add anti-pattern specific to this product's risks]**: [Description]

---

## Validation Questions

> **Guidance**: Questions a facilitator asks during or after a usability test to
> verify the journey works. Open-ended — they probe understanding and surface
> gaps between intent and experience. Structure the results with `/usability-report`.

**Discover & Evaluate**
- [ ] "In your own words, what does this product do and who is it for?"
- [ ] "What would you want to know before trusting it with your data?"

**Sign-up & First Value**
- [ ] "What do you expect to happen after you click this?"
- [ ] "How long did it take to get to something useful? Was anything unclear?"

**Set-up & Adoption**
- [ ] "What would you do to bring your team in? Show me."
- [ ] "Is there anything you expected to be able to import or connect that you could not?"

**Habitual Use**
- [ ] "Walk me through what you did the last time you used it. What was slow?"
- [ ] "What do you check first when you open it? Is it there?"

**Expansion & Renewal**
- [ ] "What would make you move to a higher plan? What would stop you?"
- [ ] "What would you do if a payment failed? Where would you look?"

**Offboarding**
- [ ] "If you wanted to leave, how would you do it? What would happen to your data?"

**General (any phase)**
- [ ] "What is the one thing that would make you stop using this?"
- [ ] "Is there anything you wanted to do and could not find how?"

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does the activation event reflect real value for non-technical admins?] | [product-manager] | [Date] | [Unresolved] |
| [Is the set-up phase completable without contacting support?] | [product-manager, ux-designer] | [Date] | [Unresolved] |
| [Add question] | [Owner] | [Date] | [Resolution] |
