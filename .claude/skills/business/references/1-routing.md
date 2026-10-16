# Routing table — `/business`

Read this in Phase 2. Re-read it if the conversation was compacted.

## Classification

Classify the question on first read, in the user's language (Arabic or
English). A question can carry more than one class; list all of them.

| Class | The question sounds like | Specialist that owns the facts | Deeper skill for a saved artifact |
|---|---|---|---|
| `market` | "how many clinics in Egypt could buy this", "is KSA bigger than UAE for us", buyer behaviour, payment habits, VAT/e-invoicing facts | `market-researcher` | `/market-research` |
| `competitors` | "what do X and Y charge", "who else sells to this segment" | `market-researcher` | `/competitor-analysis` |
| `pricing` | value metric, plans, price per currency, annual vs monthly, one-time licence, self-hosted price, margin | `pricing-strategist` | `/pricing-strategy` |
| `offer` | launch deal, discount, coupon, bundle, trial, referral | `pricing-strategist` (+ `marketing-lead` for launch deals) | `/offer-design` |
| `gtm` | how do we launch, which segment first, positioning, messaging | `marketing-lead` | `/gtm-plan` |
| `marketing` | channels, budget, content, CAC target, attribution | `marketing-lead` | `/marketing-plan` |
| `sales` | sales motion, qualification, enterprise terms, resellers, objections, proposal | `sales-lead` | `/sales-playbook` |
| `case` | CAC, LTV, churn, payback, break-even, "does this make money" | `business-director` (inputs from the others) | `/business-case` |
| `entry` | Egypt vs Saudi Arabia vs UAE for a product (always `market` + `pricing` + one of `marketing`/`sales`) | several | `/team-business` |

## Not answered here — route and stop

| The question is really about | Route to | What this skill does |
|---|---|---|
| Changing what the product is: scope, edition, ICP of record, positioning of record | `product-director` | State the business evidence that bears on it, then say "decision belongs to `product-director`" |
| Implementing a decided price: plans, entitlements, coupons in the catalogue, tax display, billing code | `pricing-billing-designer` (after `product-director` sign-off) | Point at `business/pricing/` handoff, `/pricing-check` |
| A legal, tax, accounting or contract-law conclusion | A qualified advisor | Quote the official rule with its date; draw no conclusion |
| A brand architecture choice, a product name, or "can we use this name" (trademark, domain, handle, Arabic meaning) | `/brand-architecture` (owner `marketing-lead`; legal parts need counsel) | State any sourced market fact, then route; never call a name clear or available, never assert an Arabic or dialect meaning from memory |
| Technical facts (library, API, infra cost drivers) | `/research` | Name the missing input |
| Contacting a customer, competitor or partner; publishing; committing spend | The user | Produce the draft only |

When the **whole** question is out of scope the outcome is `ROUTED` — no
verdict, no numbers, one paragraph naming the owner and why.

## Specialist waves (dependencies)

| Needs | Because | So run |
|---|---|---|
| `market-researcher` | everything else cites its counts, corridors and regulatory facts | wave 1 |
| `pricing-strategist` | CAC targets, discount floors and ACV come from its prices | wave 2 (after wave 1) |
| `marketing-lead`, `sales-lead` | both need prices and the ICP; neither needs the other | wave 3, **in parallel** |
| `business-director` | consolidates, cross-checks, states sensitivity and the cheapest disproving test | last, always |

Independent specialists in the **same** wave are spawned in one block of
`Agent` calls (`.claude/docs/coordination-rules.md`, Parallel Task
Protocol). A question needing three or more specialists is a `/team-business`
question: say so and offer to switch; do not run a hidden four-agent pipeline
inside an answer-only skill.

## Where a saved answer goes

| Dominant class | Path (new file, dated) |
|---|---|
| `market`, `entry` | `business/market/<slug>-<date>.md` |
| `competitors` | `business/competitors/notes/<topic>-<date>.md` — a dated **/business note**, not a competitor capture (see below). A full verified capture is `/competitor-analysis` |
| `pricing`, `offer` | `business/pricing/<slug>-<date>.md` |
| `gtm`, `marketing` | `business/marketing/<slug>-<date>.md` |
| `sales` | `business/sales/<slug>-<date>.md` |
| `case`, mixed | `business/cases/<slug>-<date>.md` |

**Competitor-dominant answers.** `/business` may save one, after "May I write", as
`business/competitors/notes/<topic>-<date>.md` (`<topic>` is a slug of the question).
The header's first line states `Type: /business note - not a competitor capture` and
`Verification: NOT VERIFIED-ON-SITE`; prices in it keep their source, tier and date but are
never marked `VERIFIED-ON-SITE`. The file is **not** a competitor file: it lives in `notes/`,
is never written as `business/competitors/<slug>.md` or `comparison-matrix.md`, and does not
satisfy `/competitor-analysis`'s verified-capture rule or `/pricing-strategy`'s three-capture
corridor (those skills ignore `notes/`). The save offer always adds: "For a full verified
capture of these competitors run `/competitor-analysis`." The verdict is the answer's own
(Phase 4); saving does not change it. Declined write: nothing saved, the answer stands, the
report says "not saved".

Every saved file starts with: date, author agent(s), question, language, source
list. It is never written without the user's yes.
