# Waqtak / وقتك (cashier + PC control + web dashboard + Android app)

URL: https://waqtak.app/   First captured: 2026-10-16   Last captured: 2026-10-16   Segment: POS / management software for PlayStation and gaming lounges, internet cafés and cafés (PC, PS4/PS5, Xbox, billiards, custom devices); Egypt (the page also targets Syria — out of scope, noted only)
Overall capture status: about 41 of 52 fields VERIFIED-ON-SITE, 4 NOT CAPTURED, 6 NOT SOURCEABLE, 1 THIRD-PARTY (counted by the researcher from the lines below; approximate). Tooling note: WebFetch returns a model-summarised rendering of each page, not raw HTML; Arabic quotes are short phrases as the extractor returned them.
Horizon: 90 days (studio convention, not a sourced figure). Refresh due by 2027-01-14.
Do not confuse with waqtak.io — an unrelated queue-management product that a web search returned for the same name.

## Plans and prices (dated capture)
Capture 2026-10-16 - URL https://waqtak.app/ (section #pricing; the anchor returns the same single-page site) - archive: none found (Wayback availability API, 2026-10-16: no snapshot)
Page state: the page says prices show in EGP (ج.م) inside Egypt and in USD outside Egypt. The fetch ran from outside Egypt, so the displayed state is not known; the EGP list below is from the page's own text, including its comparison table, which names EGP ("200 ج.م شهرياً للمحل بالكامل"). USD amounts for non-Egypt visitors are NOT CAPTURED.

| Plan (as written) | Price as published | Period | Per | Tax shown | Limits (as written) | Mark |
|---|---|---|---|---|---|---|
| شهري (Monthly) | EGP 200 | month | shop (not per device) | not stated | "أجهزة بلا حد" — unlimited devices; cancel anytime | VERIFIED-ON-SITE |
| ربع سنوي (Quarterly) | EGP 500 | 3 months | shop | not stated | same; labelled most popular; "توفير 17%" | VERIFIED-ON-SITE |
| سنوي (Annual) | EGP 1,500 | year | shop | not stated | same; "توفير 37%" | VERIFIED-ON-SITE |
| 3 سنوات (3 Years) | EGP 3,000 | 3 years | shop | not stated | same; "توفير 58%" | VERIFIED-ON-SITE |

Plan structure (VERIFIED-ON-SITE): the four plans are billing periods of one product — no feature tiers, no per-device fee ("دون رسوم لكل جهاز"), no paid modules, no installation fee. The Sonoff smart switch is hardware bought separately.
Included in every plan (VERIFIED-ON-SITE): unlimited devices, the Android app, the cloud web dashboard, offline operation up to 5 days, automatic backups, free updates, Arabic support via WhatsApp.
Subscription binding (VERIFIED-ON-SITE, FAQ and terms): the subscription is tied to one cashier device fingerprint ("مرتبط ببصمة جهاز واحد هو جهاز الكاشير"); customer PCs need only the free control program; running one licence on several machines may lead to suspension.

Derived values (calc.py, 2026-10-16; arithmetic on the published EGP prices, not new data):

| Plan | EGP per month equivalent | Discount vs monthly × period | Page claims |
|---|---|---|---|
| Monthly | 200 | — | — |
| Quarterly | 166.67 | 16.7% | 17% (consistent) |
| Annual | 125.00 | 37.5% | 37% (consistent) |
| 3 Years | 83.33 | 58.3% | 58% (consistent) |

Monthly × 12 = EGP 2,400; 3-year plan per year = EGP 1,000.
Equivalents: none. No dated, sourced USD/EGP rate was captured — the Central Bank of Egypt exchange-rate page returned "Request Rejected" on 2026-10-16 (not bypassed). Whether this capture precedes or follows a major EGP rate move: not assessed.

Trial (VERIFIED-ON-SITE): 14 days, all features, no card, no activation key, started in one click from inside the program ("جرّب كل شيء 14 يوماً قبل أن تقرّر"). Terms: one trial per device and phone number; shop data stays on the device if the customer does not subscribe.

## Billing options
- Monthly, quarterly, annual and 3-year cycles at the prices above | VERIFIED-ON-SITE. The terms page lists only "monthly, quarterly, or yearly" — the 3-year plan is missing there; inconsistency noted, not resolved.
- Auto-renewal; cancel any time from the dashboard or via support; service stays active to the end of the paid cycle | VERIFIED-ON-SITE (terms.html, page says last updated 2026-05-20).
- Failed payment: short grace period, then pause | VERIFIED-ON-SITE (terms.html).
- Refunds: fees "generally non-refundable" unless law requires or the fault is Waqtak's | VERIFIED-ON-SITE (terms.html).
- Upgrade/downgrade between plans from the dashboard | VERIFIED-ON-SITE (terms.html).
- Free tier: none; trial only | VERIFIED-ON-SITE.

## Local payment methods
- E-wallet transfer, paid through the web dashboard or the cashier app; activates when the transfer arrives | VERIFIED-ON-SITE. Which wallets: NOT CAPTURED (not named on the page).
- Google Play subscription from the Android app (auto-renewing, cancellable in Google Play) | VERIFIED-ON-SITE.
- Fawry, InstaPay, cards, bank transfer | NOT SOURCEABLE (not mentioned on homepage, terms or privacy).

## Arabic / RTL support
- Product UI "Arabic-native" with full right-to-left ("عربية بالأصل") | VERIFIED-ON-SITE (claim; product UI not opened).
- Website and web dashboard in Arabic and English | VERIFIED-ON-SITE.
- Support in Arabic via WhatsApp, plus phone, email and remote help | VERIFIED-ON-SITE.
- Docs: no help centre; the homepage FAQ (21 questions) serves as help; the sitemap lists only 3 URLs | VERIFIED-ON-SITE (absence).
- Currency/locale: EGP in Egypt, USD elsewhere, SYP when Syria is selected | VERIFIED-ON-SITE. Egyptian VAT / ETA e-invoicing: not mentioned | NOT SOURCEABLE.

## Self-hosted / on-prem offer
- None. The cashier is a Windows desktop program with a local database that syncs to Waqtak's cloud; no on-prem server or licence-key edition is offered or priced | VERIFIED-ON-SITE (absence on homepage, terms, privacy, sitemap).

## Data-residency claims
- Cloud servers hold a full copy of the shop database; no country or region named; AWS or Hetzner given only as examples of infrastructure providers | VERIFIED-ON-SITE (privacy.html, page says last updated 2026-05-19). The footer "القاهرة، مصر" is the company location, not a stated hosting location. A CLAIM, not a verified fact.
- Encryption claim: "encrypted in transit (HTTPS) and at rest"; no detail | VERIFIED-ON-SITE (claim).
- Certifications: none named | VERIFIED-ON-SITE (absence).
- Retention: privacy.html says account life + 1 year after cancellation; terms.html says the cloud copy is deleted within 30 days after cancellation unless longer retention is requested — the pages conflict | VERIFIED-ON-SITE (both).
- Deletion on request within 30 days; data export as CSV/JSON before cancelling; "your data remains yours" | VERIFIED-ON-SITE.
- No third-party trackers; data not sold (claim) | VERIFIED-ON-SITE.
- Governing law Egypt, Cairo courts; liability capped at fees paid in the previous 12 months; service "as is", no SLA | VERIFIED-ON-SITE (terms.html). Not legal advice.

## Product capabilities (as published)
All from https://waqtak.app/ unless stated, captured 2026-10-16. Vendor claims; the product was not run.

| Capability | As published | Mark |
|---|---|---|
| Offline | Local database on the cashier; sales, invoices and shifts continue without internet ("ولا يتأثر بانقطاع الإنترنت") | VERIFIED-ON-SITE (claim) |
| Offline duration | "حتى 5 أيام كاملة" — up to 5 days; after that one short connection is needed to verify the subscription | VERIFIED-ON-SITE (claim) |
| Sync | Automatic on reconnect; dashboard shows a "في انتظار الإرسال" (pending) queue | VERIFIED-ON-SITE (claim) |
| Conflict handling, multi-cashier offline merge | Not described | NOT SOURCEABLE |
| Owner remote view | Web dashboard (manager.waqtak.app, not opened); Android app on Google Play, marked new: live revenue, open invoices, active devices, shift performance; staff can sign in | VERIFIED-ON-SITE (claim) |
| iOS app | Not mentioned | VERIFIED-ON-SITE (absence) |
| Notifications | Email on shift open/close and low stock | VERIFIED-ON-SITE |
| Roles and permissions | Owner, manager, cashier; configurable permissions (discounts, invoice cancellation, opening the drawer, viewing figures); optional two-factor | VERIFIED-ON-SITE (claim) |
| Staff pay | Fixed, hourly or commission pay; overtime and lateness rules; per-employee advances; shift schedules | VERIFIED-ON-SITE (claim) |
| Attendance (clock in/out) | Not named as a feature; lateness rules imply some time tracking | NOT SOURCEABLE |
| Shifts and cash drawer (software) | Shift opens with a cash count, closes with reconciliation by category, expenses and cash difference; "فتح الدرج" permission | VERIFIED-ON-SITE (claim) |
| Activity / audit log | Not stated as a feature; only a stock and supplier movement log ("سجل قابل للمراجعة") | NOT SOURCEABLE (audit log); stock log VERIFIED-ON-SITE |
| PC stations | Free client on each customer PC locks/unlocks the screen, runs the timer, warns before the end, re-locks on invoice close; prepaid hour packages | VERIFIED-ON-SITE (claim) |
| Console / billiards | Single, double, match and prepaid modes, each with its own price list; start, pause, move, close | VERIFIED-ON-SITE (claim) |
| Screen power | Optional Sonoff smart switch | VERIFIED-ON-SITE (claim) |
| Other | Scheduled offers (happy hour, Ramadan); recipe inventory with low-stock alerts; memberships (Silver −10%, Gold −20%, VIP); open tabs; supplier invoices; Mikrotik WiFi cards printed on the receipt; QR menu; reports with export | VERIFIED-ON-SITE (claim) |
| Printer | "طابعة الفواتير" mentioned; no model or ESC/POS statement | VERIFIED-ON-SITE (mention); compatibility NOT SOURCEABLE |
| Cash-drawer hardware, barcode scanner, PC minimum spec | Not stated | NOT SOURCEABLE |
| Cashier OS | Windows, via Microsoft Store and direct download; minimum version not stated | VERIFIED-ON-SITE (Windows); version NOT SOURCEABLE |
| PC-control client OS | "يعمل على ويندوز 10 و11" | VERIFIED-ON-SITE (claim) |
| Installer | Direct installer may show "Windows protected your PC / Unknown publisher"; page gives "Run anyway" steps and points to the Store build | VERIFIED-ON-SITE |
| Onboarding | Install on the front-desk PC, start the trial in-app; remote installation help during the trial; no installation fee; moving to a new PC needs unbinding via support or dashboard | VERIFIED-ON-SITE |

## Reviews
| Site | Rating | Number of reviews | Date | Corroborated by (second source) |
|---|---|---|---|---|
| Google Play (com.waqtak.app) | NOT CAPTURED (script-rendered) | NOT CAPTURED | 2026-10-16 | none |
| Microsoft Store (9N7ZP5FM01QL) | NOT CAPTURED (script-rendered) | NOT CAPTURED | 2026-10-16 | none |
| G2 / Capterra / Trustpilot / forums | NOT SOURCEABLE | — | 2026-10-16 | one web search found no coverage of waqtak.app |

No rating is relied on. The vendor page shows no ratings or testimonials.

## Customers
No logo wall, named customers or customer count on the homepage | VERIFIED-ON-SITE (absence).
The page's comparison table against "imported programs" is the vendor's own characterisation of competitors — not competitor data.

## Company facts
- Footer: "القاهرة، مصر"; site version "v8.1"; © 2026 | VERIFIED-ON-SITE.
- Legal entity, registration, tax ID | NOT SOURCEABLE (footer, terms, privacy; registries not searched).

## Change log
| Capture date | Plan | Old price | New price | Note |
|---|---|---|---|---|
| 2026-10-16 | Monthly / Quarterly / Annual / 3 Years | — | EGP 200 / 500 / 1,500 / 3,000 | First capture; spot re-check by /competitor-analysis the same day matched all four prices, the 14-day trial and the 5-day offline claim |

## NOT SOURCEABLE / NOT CAPTURED
| Field | Why | Searched |
|---|---|---|
| USD price list (outside Egypt) | NOT CAPTURED — page shows USD outside Egypt; selector state could not be varied | homepage pricing |
| USD / other conversion | NOT CAPTURED — CBE rate page blocked ("Request Rejected"), not bypassed | cbe.org.eg exchange-rates |
| Google Play rating / installs / version | NOT CAPTURED — script-rendered | play.google.com listing |
| Microsoft Store rating / requirements | NOT CAPTURED — script-rendered | apps.microsoft.com listing |
| Named e-wallets; Fawry / InstaPay / cards | NOT SOURCEABLE — checkout behind login not opened | homepage, terms, privacy |
| Attendance; audit log; drawer hardware; printer models; scanner; PC spec; cashier Windows version | NOT SOURCEABLE — not stated | homepage + FAQ, terms, privacy, sitemap |
| Android app offline behaviour | NOT SOURCEABLE | homepage |
| Reviews | NOT SOURCEABLE | one Arabic + English web search |
| Legal entity, hosting country | NOT SOURCEABLE | footer, terms, privacy |
| Docs / help centre / trust page | NOT SOURCEABLE — none linked; sitemap has 3 URLs | sitemap.xml, robots.txt |
| Archive link | none found | Wayback availability API |

## Sources
| # | URL | Tier | Date fetched |
|---|---|---|---|
| 1 | https://waqtak.app/ (also #pricing) | 2 | 2026-10-16 |
| 2 | https://waqtak.app/terms.html (page: last updated 2026-05-20) | 2 | 2026-10-16 |
| 3 | https://waqtak.app/privacy.html (page: last updated 2026-05-19) | 2 | 2026-10-16 |
| 4 | https://waqtak.app/robots.txt, https://waqtak.app/sitemap.xml | 2 | 2026-10-16 |
| 5 | https://archive.org/wayback/available?url=waqtak.app (no snapshot) | 5 (tooling check) | 2026-10-16 |
| 6 | Web search "Waqtak وقتك برنامج إدارة صالات بلاي ستيشن كافيه" — no coverage of waqtak.app (negative result) | 5 | 2026-10-16 |
| 7 | https://play.google.com/store/apps/details?id=com.waqtak.app — NOT CAPTURED | — | 2026-10-16 |
| 8 | https://apps.microsoft.com/detail/9N7ZP5FM01QL — NOT CAPTURED | — | 2026-10-16 |
| 9 | https://www.cbe.org.eg/en/economic-research/statistics/exchange-rates — blocked | — | 2026-10-16 |
