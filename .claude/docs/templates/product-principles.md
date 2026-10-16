# Product Principles: [Product Title]

## Document Status
- **Version**: 1.0
- **Last Updated**: [Date]
- **Approved By**: product-director
- **Status**: [Draft / Under Review / Approved]

---

## What Are Product Principles?

Principles are the 3–5 non-negotiable commitments that define this product's
identity. Every product, design, engineering, security and pricing decision must
serve at least one principle. If a feature does not serve a principle, it does
not belong in the product.

**Why principles matter**: Over a product's life the team makes thousands of
small decisions. Principles make them push the same way, creating a coherent
customer experience rather than a collection of features.

### What Makes a Good Principle

A good principle is:
- **Falsifiable**: "Easy to use" is not a principle. "Every task is reachable in
  three clicks from the dashboard" is — it makes a testable claim.
- **Constraining**: If a principle never forces you to say no, it is too vague.
- **Cross-functional**: It shapes product, design, engineering, security, pricing
  and support — not just one of them.
- **Memorable**: The team can recite them from memory.

### Illustrative Examples (invented, to show specificity)

| Principle | Why it works |
| ---- | ---- |
| "Zero-training first run: a new admin reaches value without reading docs" | Constrains onboarding, copy, defaults, empty states, and what ships in the MVP. |
| "Your data is yours: export everything, delete everything, any time" | Constrains schema design, backups, API coverage, pricing (no export paywall) and support playbooks. |
| "Boring technology, loud reliability" | Constrains stack choices, release cadence, SLOs, and rules out risky dependencies. |
| "Offline-tolerant by default" | Constrains mobile architecture, sync, conflict handling and what the UI promises. |
| "One price, no surprises" | Constrains plan design, metering, billing communications, and tax display. |

---

## Core Promise

> [What outcome does the customer get from this product that they cannot get as
> easily elsewhere? The core promise is the answer to "why would someone choose
> THIS product?" — concrete and outcome-based.
>
> Examples:
> - "Clinic owners stop chasing paper records and know tomorrow's schedule tonight."
> - "Small finance teams close the month in one day with an auditable trail."
> - "IT teams run the platform on their own servers with the same experience as the cloud."]

---

## Value Alignment

[Rank what the customer values most. Your principles should collectively deliver
the top two or three.]

| Rank | Customer value | How the product delivers it |
| ---- | ---- | ---- |
| 1 | [e.g. Time saved] | [Specific mechanism] |
| 2 | [e.g. Trust / control over data] | [Specific mechanism] |
| 3 | [e.g. Cost predictability] | [Specific mechanism] |
| N/A | [Values not targeted] | [Why this is not a priority] |

**Reference values**: Outcome (time/money/risk), Effort (ease, speed), Trust (security, reliability, privacy), Control (flexibility, ownership), Cost (price, predictability), Belonging (team, community).

---

## The Principles

### Principle 1: [Name]

**One-Sentence Definition**: [A clear, falsifiable statement. Specific enough that two people would reach the same conclusion applying it to a question.]

**Customer Values Served**: [Which values from the ranking above this delivers.]

**Decision Test**: [A concrete decision this principle resolves. "If we are debating X vs. Y, this principle says we choose __."]

#### What This Means for Each Function

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | [How this constrains and inspires scope and features] | [Concrete example] |
| **Design / UX** | [Interaction, content and visual consequences] | [Concrete example] |
| **Engineering** | [Architecture, performance, reliability consequences] | [Concrete example] |
| **Security & Privacy** | [Data handling, access, compliance consequences] | [Concrete example] |
| **Pricing & Growth** | [Plans, trials, communications consequences] | [Concrete example] |
| **Support & Success** | [Playbooks, tone, escalation consequences] | [Concrete example] |

#### Serving This Principle
- [Concrete example of a feature/decision that embodies it]
- [Another example]

#### Violating This Principle
- [Concrete example of what would betray it — things we must never do]
- [Another example]

---

### Principle 2: [Name]

**One-Sentence Definition**: [Specific, falsifiable statement]

**Customer Values Served**: [Values]

**Decision Test**: [Concrete decision it resolves]

#### What This Means for Each Function

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | [Constraint/inspiration] | [Example] |
| **Design / UX** | [Constraint/inspiration] | [Example] |
| **Engineering** | [Constraint/inspiration] | [Example] |
| **Security & Privacy** | [Constraint/inspiration] | [Example] |
| **Pricing & Growth** | [Constraint/inspiration] | [Example] |
| **Support & Success** | [Constraint/inspiration] | [Example] |

#### Serving This Principle
- [Example]

#### Violating This Principle
- [Example]

---

### Principle 3: [Name]

[Same structure as Principles 1–2]

### Principle 4: [Name] (Optional)

[Same structure]

### Principle 5: [Name] (Optional)

[Same structure]

---

## Anti-Principles (What This Product Is NOT)

Anti-principles are as important as principles — they prevent scope creep. Every
"no" protects the "yes."

Good anti-principles are things the team might actually want to do. "NOT a game"
is useless. "NOT a customisable platform with a plugin marketplace" is useful if
the product could plausibly drift there.

- **NOT [thing]**: [Why excluded, which principle it would compromise, what it would cost in focus]
- **NOT [thing]**: [Why excluded]
- **NOT [thing]**: [Why excluded]

---

## Principle Conflict Resolution

When two principles conflict (they will), use this priority order.

| Priority | Principle | Rationale |
| ---- | ---- | ---- |
| 1 | [Highest priority principle] | [Why it wins when it conflicts with others] |
| 2 | [Second priority] | [Why] |
| 3 | [Third priority] | [Why] |

**Resolution Process**:
1. Identify which principles are in tension
2. Consult the priority ranking above
3. If the lower-priority principle can be served partially without compromising the higher one, do so
4. If not, the higher-priority principle wins
5. Record the decision and rationale in the relevant spec or ADR (or the brief's decision log at minimal)
6. If the conflict is fundamental, escalate to `product-director` to consider revising the principles

---

## Trust Alignment

[Verify the principles collectively earn the trust that B2B buyers require.]

| Trust dimension | Which principle serves it | How |
| ---- | ---- | ---- |
| **Security & tenant isolation** | [Principle] | [How] |
| **Reliability & transparency** (SLOs, status page, honest incident comms) | [Principle] | [How] |
| **Privacy & data ownership** (PDPL/GDPR, export, deletion) | [Principle] | [How] |
| **Commercial fairness** (clear pricing, easy cancellation) | [Principle] | [How] |

**Gap check**: if any dimension is served by no principle, decide whether the set
is complete or whether that dimension is deliberately not a differentiator.

---

## Experience Arc

[Map the intended arc of the customer relationship. Deliberate, not accidental.]

### First-Session Arc

| Phase | Duration | Target feeling | Principle(s) driving it | Product mechanics delivering it |
| ---- | ---- | ---- | ---- | ---- |
| Arrival | [0–2 min] | [Clarity, confidence] | [Which principle] | [What the user does] |
| First value | [2–10 min] | [Relief — "it works"] | [Which principle] | [What the user does] |
| Set-up | [10–30 min] | [Control] | [Which principle] | [What the user does] |
| Hook | [End of session] | [Reason to return] | [Which principle] | [What brings them back] |

### Long-Term Progression

[How does the relationship evolve — first week, first month, first renewal,
expansion? Each should feel distinct. Link `user-journey.md`.]

---

## Reference Products

| Reference | What We Take From It | What We Do Differently | Which Principle It Validates |
| ---- | ---- | ---- | ---- |
| [Product 1] | [Specific behaviour or approach] | [Our twist] | [Principle name] |
| [Product 2] | [What we learn] | [Our twist] | [Principle name] |
| [Product 3] | [What we learn] | [Our twist] | [Principle name] |

**Non-software inspirations**: [Service experiences, trades, institutions whose tone or reliability informs the product.]

---

## Principle Validation Checklist

Before finalising, verify:

- [ ] **Count**: 3–5 principles
- [ ] **Falsifiable**: each makes a claim that could be wrong
- [ ] **Constraining**: each forces saying "no" to plausible ideas
- [ ] **Cross-functional**: each has implications for product, design, engineering, security, pricing and support
- [ ] **Decision-tested**: each has a concrete decision test against a real upcoming choice
- [ ] **Anti-principles defined**: at least 3 explicit "this product is NOT" statements
- [ ] **Priority-ranked**: clear order for resolving conflicts
- [ ] **Value-aligned**: principles collectively deliver the top-ranked customer values
- [ ] **Trust-covered**: security, reliability, privacy and fairness each have an owner principle or a recorded reason
- [ ] **Memorable**: the team can recite them
- [ ] **Core promise served**: every principle traces back to the core promise

---

## Next Steps

- [ ] Get approval from product-director
- [ ] Distribute to function leads for sign-off
- [ ] Create decision tests for each principle using real upcoming decisions
- [ ] Schedule first principle review (after 2 sprints)
- [ ] Link principles from `design/product-brief.md` and `PRODUCT.md`

---

*This document is the product north star. It lives in `design/product-principles.md`
and is referenced by every spec, UX, architecture and pricing document.
Review quarterly or after major pivots.*
