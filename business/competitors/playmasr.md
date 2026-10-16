# PlayMasr (بلاي مصر)

URL: https://playmasr.com/landing/ (root https://playmasr.com/)   First captured: 2026-10-16   Last captured: 2026-10-16   Segment: management and cashier software for PlayStation / gaming lounges and cafés in Egypt (an Iraq-tagged blog post exists; no page states Iraq or GCC support)
Overall capture status: about 30 of 38 fields VERIFIED-ON-SITE; the rest THIRD-PARTY (tier 5 lead), NOT CAPTURED or NOT SOURCEABLE (counted by the researcher; approximate). Tooling note: WebFetch returns a model-summarised rendering, not raw HTML — re-read decision-critical items on the live page.
Horizon: 90 days (studio convention, not a sourced figure). Refresh due by 2027-01-14.
Capture environment: pages showed EGP and Arabic; no country selector seen, so other countries are NOT CAPTURED.
/terms/ and /privacy/ both say "last updated 14/10/2026" — two days before this capture; they may change again.

## Plans and prices (dated capture)
Capture 2026-10-16 - URL https://playmasr.com/landing/ (#pricing) and https://playmasr.com/ (same plan content) - archive: NOT CAPTURED (web.archive.org blocked for this tool; not evidence that no archive exists)

| Plan (as written) | Price as published | Period | Per | Tax shown | Limits (as written) | Mark |
|---|---|---|---|---|---|---|
| Free trial | Free, no credit card | 7 days | account | n/a | "all features" | VERIFIED-ON-SITE |
| الاشتراك الشهري (Monthly) | EGP 150 ("150ج.م / شهرياً"), shown with "بدلاً من 400 ج.م" (instead of EGP 400) | month | venue/account — not stated which | not stated | "تشغيل عدد (2) شاشات: شاشة المراقبة من الهاتف + جهاز الكاشير"; reports, alerts, support | VERIFIED-ON-SITE |
| الاشتراك السنوي (العرض الأقوى) (Annual) | EGP 1,500 ("1500ج.م / سنوياً"); "القيمة الأصلية: 4800 ج.م"; "توفير 300 ج.م سنوياً (خصم شهرين كاملين)" | year | venue/account — not stated | not stated | "تشغيل (2) شاشات بدون قيود"; free QR menu; priority 24/7 support; price locked for one year | VERIFIED-ON-SITE |

- **Screen limit contradiction:** the plan cards say 2 screens (phone monitoring + cashier device); the FAQ says the same prices cover "عدد لا محدود من الشاشات" (unlimited screens), PS5/Xbox, tables and VIP rooms; the page also says "no hidden fees or extra device charges". Which binds is NOT SOURCEABLE from public pages — needs a trial account or a written quote.
- Arithmetic (calc.py): 150 × 12 = 1,800; 1,800 − 1,500 = 300 (matches "saves 300"); 1,500 / 12 = 125 EGP/month effective; annual discount 16.67%. 400 × 12 = 4,800 matches the "original value". The EGP 400 reference is not explained elsewhere — treat it as a marketing anchor, not a historic price. Whether 400 is visually struck through could not be confirmed (text extraction only).
- Equivalents: none — no dated central-bank rate fetched in this run. Original EGP only.
- /subscription/: NOT CAPTURED — two fetches returned only the title (script-rendered or login-gated); no login used.
- Unverified lead: a web-search summary of the homepage (not a fetch) described it as "100% free" with "10,000+ stores". The fetched page shows paid plans. THIRD-PARTY tier 5 (search-engine summary, 2026-10-16) — a lead only.

## Billing options
- Monthly and annual | VERIFIED-ON-SITE (/landing/). /terms/ s.3: subscriptions "recurring, monthly or annual"; "features depend on the plan" | VERIFIED-ON-SITE.
- Annual discount: "saves 300" = 16.67% | VERIFIED-ON-SITE.
- Trial: 7 days, no card | VERIFIED-ON-SITE.
- "Cancel anytime" on /landing/; /terms/ states no cancellation procedure | VERIFIED-ON-SITE (absence in terms).
- Refund (/terms/ s.3): no refund for already-activated subscriptions except exceptional cases decided by the technical department | VERIFIED-ON-SITE.
- After expiry, access to the venue's data is restricted until renewal; retention/deletion period not stated | VERIFIED-ON-SITE (absence).

## Local payment methods
- Methods accepted for PlayMasr's own subscription | NOT CAPTURED — /subscription/ body unreadable; /privacy/ mentions unnamed "payment processors"; /terms/ lists none.
- For the venue's customers (as marketed): QR menu payment by InstaPay or e-wallets; shift reports separate cash from InstaPay/e-wallet | VERIFIED-ON-SITE (/landing/).
- Fawry, mada, Apple Pay | NOT SOURCEABLE (searched /landing/, /terms/, /privacy/, /about/, /blog/ index).

## Arabic / RTL support
- Site in Arabic (Egyptian dialect) with an "English" toggle in the header | VERIFIED-ON-SITE; English URL NOT CAPTURED.
- Docs / help centre: none; blog (238 articles claimed) and a landing-page FAQ only | VERIFIED-ON-SITE (absence).
- Product UI language and RTL | NOT CAPTURED — behind /login/, not entered.
- Support language: Arabic implied, not stated | NOT SOURCEABLE.
- Currency EGP | VERIFIED-ON-SITE.

## Self-hosted / on-prem offer
- None. /disclaimer/ calls the system "cloud-based" and dependent on hosting providers; no on-prem or self-hosted licence on any page | VERIFIED-ON-SITE.

## Data-residency claims
- Hosting provider named on /disclaimer/: "Firebase/Google Cloud" | VERIFIED-ON-SITE (vendor statement; a CLAIM).
- Storage region/country: not stated | VERIFIED-ON-SITE (absence).
- Security claims on /privacy/: SSL for all communications; sensitive financial data in encrypted databases behind firewalls; admits no storage is 100% secure | VERIFIED-ON-SITE (claims).
- Certifications: none named | VERIFIED-ON-SITE (absence).
- Governing law: Egyptian law and courts | VERIFIED-ON-SITE.
- Third parties named on /privacy/: Google AdSense (DART cookie), Google Analytics, WhatsApp (earnings reports). Controller named only as the brand; no registered legal entity on /terms/, /privacy/ or /about/ | VERIFIED-ON-SITE.
- Not legal advice; confirm PDPL implications with a qualified advisor.

## Reviews
| Site | Rating | Number of reviews | Date | Corroborated by (second source) |
|---|---|---|---|---|
| Web search "playmasr.com reviews / تقييم بلاي مصر" | none found | 0 | 2026-10-16 | n/a |
| Google Play / App Store | no listing found (delivered as a PWA/web app) | n/a | 2026-10-16 | n/a |

G2, Capterra, Trustpilot, Facebook ratings: NOT SOURCEABLE (no results; Facebook/Instagram not opened). No review evidence — do not rely on reviews. Owner testimonials on /landing/ (about 15, with city and venue) are vendor claims; names not recorded here.

## Customers
- Claims, unverified and mutually inconsistent: "10,000+ venues" (/landing/, /); "الشريك الأول لأكثر من 1,000 صاحب صالة" (/about/); "thousands" (/blog/iraq-gaming-lounge-setup/). None is a verified customer count.
- Other usage claims, unverified: "1M+ hours recorded" vs "1,000,000+ sessions" (unit inconsistent); 2,000+ orders/day; 99.9% stability.
- Logo-wall labels (GAMERS HUB, PLAY STATION, COFFEE CORNER, VR WORLD) are text labels, not confirmed client logos.
- Testimonials place venues in Cairo, Alexandria, Giza, Mansoura, Sohag, Aswan and Suez; one claims 3 branches. Claims only.
- Vendor's unsourced figure that venues without software "lose 15–25% of net profit" — no source; do not reuse.

## Product capabilities (as published)
Vendor's own pages unless stated. Claims, not tested behaviour.

| Capability | As published | Mark |
|---|---|---|
| Offline | /landing/ and /: "works fully offline", saves sessions and orders locally, syncs on reconnect. /disclaimer/ mentions local data that syncs later, and also calls the system cloud-based and internet-dependent; /terms/ s.4 disclaims outages from the customer's internet. No limits published (which functions, how long, conflicts); offline screen control not stated | VERIFIED-ON-SITE (claim); extent NOT SOURCEABLE |
| Owner remote view | Installable PWA on "any phone, computer or laptop"; live monitoring from outside via the same login link (/blog/guide-how-to-use-playmasr/, 2024-12-29); session and shift notifications; daily/monthly net-profit reports; reports via WhatsApp, Excel, PDF, email | VERIFIED-ON-SITE (claim); no native store listing found — NOT SOURCEABLE |
| Staff / shifts | Per-cashier sub-accounts with PIN; shift handover compares counted cash with recorded sales, reports shortage/surplus; owner notified at shift close (/blog/manage-employee-shifts-honestly/, 2026-05-20) | VERIFIED-ON-SITE |
| Attendance (time clock) | Not offered or mentioned; only shift handover | VERIFIED-ON-SITE (absence) |
| Cash drawer | Software reconciliation only; cash separated from InstaPay/e-wallet; no drawer hardware named | VERIFIED-ON-SITE |
| Activity / audit log | No feature named; claims that saved data "cannot be edited or deleted", "every action is reported", PIN restricts sensitive changes to the owner | VERIFIED-ON-SITE (claims); audit-log scope NOT SOURCEABLE |
| PC stations | "supports computers and laptops"; onboarding asks for PlayStation and PC counts; PC lock mechanism / client not stated | VERIFIED-ON-SITE (claim); mechanism NOT SOURCEABLE |
| Timing model | Per-second timing; Single/Multi modes; open sessions; VIP rooms | VERIFIED-ON-SITE |
| Screen control | PlayMasr TV app on Android/smart TVs (Samsung, LG, Tornado, Xiaomi) and an "official PlayMasr board"; lock/unlock in software, not by cutting power. Sonoff/Tuya mentioned only in a search summary, not on the fetched page | VERIFIED-ON-SITE (TV app); Sonoff/Tuya THIRD-PARTY tier 5, lead only |
| Printer | No model or protocol; one testimonial mentions printed invoices | NOT SOURCEABLE |
| Supported OS / Windows | Not given; /disclaimer/ makes the customer responsible for unpublished "technical requirements" | VERIFIED-ON-SITE (absence) |
| Café / kitchen | Tables, tabs, split/merge bills, move a table bill to a gaming room, kitchen/bar tickets, gram-level ingredient inventory with recipes, stock alerts | VERIFIED-ON-SITE |
| Customer QR menu | Order from room/table without an app; live time and bill; pay by InstaPay/e-wallet; public station-availability QR | VERIFIED-ON-SITE |
| Loyalty, offers, booking | Points for gifts or play time; bundles and automatic offers; online booking of devices/tables/VIP (blog posts 2026-05-12/13) | VERIFIED-ON-SITE |
| Multi-branch | Only in a testimonial (3 branches); no feature page | VERIFIED-ON-SITE (weak) |
| "AI analytics" | Profit forecasts, inventory risk, win-back suggestions claimed; /about/ calls AI a "future vision" — inconsistent | VERIFIED-ON-SITE (claim) |
| Onboarding | Self-serve: sign up by email or phone, add devices, start a session; "no technician needed"; no installer or Windows setup mentioned | VERIFIED-ON-SITE |
| Support | /support/: email, WhatsApp/phone and phone lines, Facebook, Instagram; phone "daily from 10 AM" (no close time) vs landing-page "24/7" — conflict. Contact numbers and individual-looking emails deliberately omitted | VERIFIED-ON-SITE |
| SLA | None; "99.9% stability" is marketing; /terms/ s.4 promises updates and support in official hours | VERIFIED-ON-SITE |
| Data export / backup | Excel and PDF reports; full export/backup not mentioned | VERIFIED-ON-SITE (absence) |

## Change log
| Capture date | Plan | Old price | New price | Note |
|---|---|---|---|---|
| 2026-10-16 | Monthly | — (first capture) | EGP 150/month ("instead of EGP 400") | Baseline; tax not shown |
| 2026-10-16 | Annual | — (first capture) | EGP 1,500/year ("original value" EGP 4,800) | Baseline; tax not shown. Spot re-check by /competitor-analysis the same day matched both prices and the screen-limit contradiction |

## NOT SOURCEABLE / NOT CAPTURED
| Field | Why | Searched |
|---|---|---|
| /subscription/ body incl. payment methods | NOT CAPTURED — title only (script-rendered or login-gated); no login | two WebFetch calls |
| Archive link | NOT CAPTURED — web.archive.org blocked for this tool | one attempt |
| VAT status of EGP 150 / 1,500 | NOT SOURCEABLE | /landing/, /, /terms/ |
| What the price is per (venue, branch, account) | NOT SOURCEABLE | /landing/, /, /terms/ |
| Screen limit (2 vs unlimited) | NOT SOURCEABLE — page contradicts itself | /landing/, / |
| Windows version, OS requirements, printer and drawer models | NOT SOURCEABLE | /landing/, /, blog guide, /terms/, /disclaimer/, /support/ |
| Attendance and activity-log features | NOT SOURCEABLE — absent from every page read | same |
| Offline limits (functions, duration, conflicts) | NOT SOURCEABLE | /landing/, /, /disclaimer/ |
| Data region and retention | NOT SOURCEABLE | /privacy/, /terms/, /disclaimer/ |
| Legal entity, address, tax ID | NOT SOURCEABLE | /about/, /terms/, /privacy/ |
| Independent reviews, store ratings | NOT SOURCEABLE | Arabic and English web searches; store queries |
| Product UI, RTL behaviour | NOT CAPTURED — behind /login/ | n/a |
| English-version URL | NOT CAPTURED — toggle seen, URL not shown | /landing/ |
| Prices for other countries/currencies | NOT CAPTURED — no selector; the Iraq post lists no price | /blog/iraq-gaming-lounge-setup/ |

Not run: a raw HTML read of the pricing section and a trial-account walkthrough; both would close several rows above.

## Sources
| # | URL | Tier | Date fetched |
|---|---|---|---|
| 1 | https://playmasr.com/landing/ | 2 | 2026-10-16 |
| 2 | https://playmasr.com/ | 2 | 2026-10-16 |
| 3 | https://playmasr.com/subscription/ (title only) | 2 | 2026-10-16 |
| 4 | https://playmasr.com/terms/ (page: updated 14/10/2026) | 2 | 2026-10-16 |
| 5 | https://playmasr.com/privacy/ (page: updated 14/10/2026) | 2 | 2026-10-16 |
| 6 | https://playmasr.com/about/ | 2 | 2026-10-16 |
| 7 | https://playmasr.com/disclaimer/ | 2 | 2026-10-16 |
| 8 | https://playmasr.com/support/ | 2 | 2026-10-16 |
| 9 | https://playmasr.com/blog/ (index) | 2 | 2026-10-16 |
| 10 | https://playmasr.com/blog/guide-how-to-use-playmasr/ (dated 2024-12-29) | 2 | 2026-10-16 |
| 11 | https://playmasr.com/blog/manage-employee-shifts-honestly/ (dated 2026-05-20) | 2 | 2026-10-16 |
| 12 | https://playmasr.com/blog/iraq-gaming-lounge-setup/ | 2 | 2026-10-16 |
| 13 | Web search "PlayMasr بلاي مصر نظام إدارة صالات بلايستيشن" (search summary, leads only) | 5 | 2026-10-16 |
| 14 | Web searches for reviews and store listings (no results) | 5 | 2026-10-16 |
