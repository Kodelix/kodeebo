# Marketing plan layout and audit — `/marketing-plan`

Read in Phase 2; give to `marketing-lead` and `product-analytics-engineer`; use as
the Phase 4 audit. Output: `business/marketing/marketing-<product>-<period>.md`.

## Sections

1. **Header** — date, author agents, product, edition, market(s), period (dates), verdict, sources, stale-after.
2. **Recommendation** — channel mix and budget in one paragraph, and the cheapest test that would show it wrong.
3. **Targets in** — from `/gtm-plan` and `/business-case`: customers to acquire, payback months allowed, ARPA and gross margin used (cited by file and row).
4. **CAC target** — derived, never chosen:

   ```
   CAC ceiling (per channel and blended) = monthly ARPA x gross margin x payback months allowed
   Blended CAC = total acquisition spend / new paying customers in the same period
   ```
   Inputs come from `business/pricing/` and `business/cases/`; absent → `NOT ASSESSED`, no CAC number is stated.
5. **Channel mix** — one row per channel (SEO, content, LinkedIn, X, Facebook, Instagram, TikTok only where the audience is, paid search, partnerships, events, communities, email, WhatsApp-led referral):

   | Channel | Role in funnel | Audience size / search volume (source, date, country) | Cost model (CPC / CPM / CPL or time) with source or `ASSUMPTION` | Funnel step conversions (assumption or measured) | First test | Evidence tier |

   Benchmarks are sourced (platform's own published data, reputable industry report with methodology) with date and scope **or labelled `ASSUMPTION`**. A global benchmark is a labelled comparison, never a regional stand-in. Platform choices are justified by sourced usage per country; "LinkedIn for GCC B2B decision-makers" and "Facebook/WhatsApp-led discovery for Egyptian SMEs" are hypotheses until a source is attached.
6. **SEO plan** — keyword set per language with sourced volumes (tool and date) or `ASSUMPTION`, content clusters, technical requirements delegated to `astro-specialist` (hreflang, sitemap, structured data), success metric (non-brand organic signups), and an honest timeline.
7. **Paid plan** — test budget, daily cap, stop rule, minimum conversions before reading results, and each platform's account-level policy constraints taken from that platform's own current page (dated).
8. **Partnerships and events** — categories (accountants, integrators, associations, incubators), reason, offer, number of conversations targeted. No partner is named as agreed unless the user confirms a real agreement.
9. **Content calendar** — dated rows (week, language AR/EN, format, topic, channel, owner, asset, the claim it carries and its evidence). Arabic pieces are written natively; RTL and register reviewed with `localization-lead`. No invented case studies or testimonials.
10. **Budget** — local currency first, USD equivalent with rate, source and date, VAT status of media costs:

    | Channel | Phase | Amount (local; USD eq.) | Expected leads | Trials | Paid customers | CAC low / base / high | CAC vs ceiling |

    Expected numbers follow from the channel row's conversions by formula (run with `calc.py`). Budget sums to the user's ceiling or says by how much it exceeds it.
11. **Attribution and measurement** (with `product-analytics-engineer`) — UTM scheme and campaign naming; first-party event names in the tracking plan (`.claude/docs/templates/tracking-plan.md`); attribution model and its **blind spots** (dark social, WhatsApp referrals, offline, word of mouth); weekly funnel table (visits → signup → activation → paid) with sources; review cadence and the date of the first read-out.
12. **Consent and privacy** — cookie/analytics consent, email and WhatsApp opt-in, retargeting and lookalike use, data retention for leads; the legal facts come from `privacy-compliance-specialist` and the authority's text, with "confirm with a qualified advisor"; **no personal data of real prospects is stored in the repository**; self-hosted installs run no tracking unless the customer opted in.
13. **Risks, assumptions and gaps** — each with how to close it.
14. **Next steps** — action — owner (user-supplied) — date.

## Audit checklist (MET / NOT MET / NOT ASSESSED)

| # | Check | NOT ASSESSED when |
|---|---|---|
| M1 | CAC ceiling derived from ARPA × margin × payback, inputs cited | pricing or case file ABSENT |
| M2 | Each channel row: audience/volume source, cost source or `ASSUMPTION`, conversions labelled, first test | — |
| M3 | Platform choices tied to sourced usage per country, else flagged | — |
| M4 | Budget table complete, local currency first, FX sourced and dated, CAC low/base/high vs ceiling | M1 NOT ASSESSED |
| M5 | Paid plan has cap, stop rule, min conversions, platform-policy source and date | — (`N/A — not in scope`, stated, when no paid plan is in scope; counts as MET) |
| M6 | SEO plan with sourced volumes or assumptions; technical items delegated | — (`N/A — not in scope`, stated, when SEO is out of scope; counts as MET) |
| M7 | Calendar rows dated, bilingual, each claim evidenced | — |
| M8 | Attribution: UTM scheme, events named for the tracking plan, blind spots written | `product-analytics-engineer` not run → say so |
| M9 | Consent rules present; no prospect personal data stored; self-hosted telemetry off | privacy facts unreachable (consent part is `N/A — not in scope`, stated and counted as MET, when personal data in campaigns, email or WhatsApp opt-in, retargeting, consent, or tracking pixels is not planned) |
| M10 | Partners named only where the user confirmed; none invented | — |
| M11 | Owners user-supplied | owners not given → `UNASSIGNED`, counts as NOT MET |
| M12 | Number rows: E (defective) = 0 | — |
