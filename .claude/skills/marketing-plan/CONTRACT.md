# /marketing-plan — Handoff Contract

## Role in Pipeline
The operating plan under a GTM: which channels, how much money, what content on
which dates, what each customer may cost, and how it will be measured. Work is done
by `marketing-lead`, with `product-analytics-engineer` (attribution, events),
`privacy-compliance-specialist` (consent facts) and `localization-lead` (Arabic
calendar rows). Follows `/gtm-plan`, `/pricing-strategy` and `/business-case`;
reached from `/business` (classes `marketing`, `gtm`) and `/team-business`. Feeds
the tracking plan, instrumentation stories and weekly read-outs.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md`, `PRODUCT.md` | audience, brand, tone | stated ABSENT |
| `business/marketing/gtm-*.md` | segment, positioning, messages, targets | the user is asked for segment and messages or routed to `/gtm-plan`; with neither → `INSUFFICIENT DATA — no segment or message basis` |
| `business/pricing/*` | ARPA inputs | CAC ceiling `NOT ASSESSED` (M1, M4); no CAC target number stated |
| `business/cases/*` | gross margin, payback limit, CAC | same as above |
| `business/market/*`, `business/competitors/*` | channel and platform data, payment methods | brief says "none"; every benchmark is sourced with a date or `ASSUMPTION` |
| `docs/**/tracking-plan*.md` (template `.claude/docs/templates/tracking-plan.md`) | event names and UTM scheme | stated ABSENT; events are proposed for it |
| `docs/stack-reference/astro/best-practices.md` (`site/` constraints) | SEO technical items | stated ABSENT; technical SEO delegated to `astro-specialist` / `web-lead` |

### Preconditions
- A product is named; none → the skill asks and stops
- Period, market(s), budget ceiling (local currency), channels already in use with measured results, and owners come from the user; a skipped answer is re-asked in plain text; no data or owners are invented (owners absent → `UNASSIGNED`)
- `marketing-lead` is spawned first; then in one parallel block `product-analytics-engineer`, `privacy-compliance-specialist` (when personal data in campaigns, email or WhatsApp opt-in, retargeting, consent, or tracking pixels is in scope) and `localization-lead`, with the channel and budget tables pasted in; any not spawned is named with its checks listed "not run"

## Verdicts Emitted
`PLAN READY` / `PLAN READY WITH CONDITIONS` / `PLAN NOT READY` / `INSUFFICIENT DATA`.
Precedence, first match wins: `PLAN NOT READY`, `INSUFFICIENT DATA`,
`PLAN READY WITH CONDITIONS`, `PLAN READY`. Checks M1–M12: MET / NOT MET / NOT ASSESSED; a check whose subject is out of scope (M5 no paid plan, M6 no SEO, M9's consent part) is `N/A — not in scope (stated)` and counts as MET.
- `PLAN NOT READY`: blended base-case CAC above the derived ceiling (only when M1 was assessed); budget above the user's ceiling unflagged; paid spend with no cap or stop rule; no consent rules where email/retargeting is planned.
- `INSUFFICIENT DATA`: no segment/message basis, or no data to choose channels even as hypotheses.
- `PLAN READY WITH CONDITIONS`: any check NOT ASSESSED or NOT MET for a stated reason, channel conversions that are assumptions, or M1 `NOT ASSESSED` (Phase 1 cap: no better than this; the other `PLAN NOT READY` triggers still apply).
- `PLAN READY`: M1–M12 MET (`N/A — not in scope` counts as MET) and the base case clears the CAC ceiling with benchmark rows at tier 1–3 or measured.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/marketing/marketing-<product>-<period>.md` | header (date, author agents, product, edition, market(s), period, verdict, sources, stale-after); recommendation with the cheapest test that would show it wrong; targets in (cited by file and row); CAC target (derived); channel mix rows; SEO plan; paid plan; partnerships and events; content calendar (dated, AR/EN); budget table; attribution and measurement; consent and privacy; risks, assumptions and gaps; next steps |

The M1–M12 table is shown in the conversation; the layout does not list it as a
section of the file.

### Output Guarantees
- CAC ceiling = monthly ARPA x gross margin x payback months allowed, inputs cited; blended CAC = acquisition spend / new paying customers; never chosen. No inputs, no target
- Every benchmark (CPC, CPM, audience size, search volume, platform policy) is sourced with URL, tier, date and country scope, or labelled `ASSUMPTION`; a global benchmark is a labelled comparison, never a regional stand-in
- Budget, funnel and CAC arithmetic is run with `calc.py`; the budget sums to the user's ceiling or says by how much it exceeds it
- Money is local currency first with USD, rate, source and date; VAT status of media costs stated
- Paid plan has daily cap, stop rule and minimum conversions; platform policy taken from that platform's own dated page
- Attribution lists its blind spots; the first read-out date is written; self-hosted installs run no tracking by default
- A specialist that did not run, or a platform page that was unreachable, is reported as not run, never MET
- Number rows A/B/C/D/E counted as in `/business` Phase 4; E = 0
- The header date comes from `date +%F`; leftover placeholders are searched for

## Immutability Rules
- WRITES only the one file above under `business/marketing/`, only after "May I write ...?" (autonomous mode: writes and records `log_decision`). A declined write writes nothing: the presented verdict stands and the report says "not saved" (accepted business-skill exception)
- Never edits the GTM plan, product brief, specs or code; weekly read-outs are separate dated files added later, not by this skill

## Hard Constraints (Never Violate)
- No benchmark, CPC, audience size or platform policy from memory
- No fabricated testimonials, case studies, results or partner agreements; partners named only if the user confirmed them
- No personal data of real prospects in the repository
- No legal, tax or accounting conclusion; consent facts come from the authority's text with the advisor caveat
- Spending, posting, emailing and contacting are the user's actions; nothing is published, bought or sent

## Downstream Skill Expects
`product-analytics-engineer` takes the events and UTM scheme into the tracking plan (instrumentation via `/create-stories`); `astro-specialist` / `web-lead` take SEO technical items; `localization-lead` takes Arabic copy; `privacy-compliance-specialist` takes product consent flows. `ASSUMPTION` conversions stay assumptions until measured and the plan is revised from measured results.

## Known Fragile Points
- Channel conversions are assumptions at first, so `PLAN READY` needs measured results or tier 1-3 rows
- M5, M6 and M9's consent part are `N/A — not in scope` (counted as MET) only when the scope statement says so; the scope statement is required
- A platform page behind a login or bot-check is unreachable: the row is `ASSUMPTION` and the check is not run
