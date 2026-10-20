# /launch-checklist — Checklist Sections

> Phase 4 of `SKILL.md`. Eleven function sections. Item legend:
> `- [ ]` work remains · `- [x]` done on evidence or confirmed by the user ·
> `- [?]` not assessed — the input to this check was absent ·
> `- N/A — [item]` does not apply (with the config value or reason).
> Include the legend wherever a `[?]` appears: `[?] = not assessed — the input to this check was absent`.
>
> **Legal, tax and accounting rules are never concluded here.** Items cite the
> official rule from a research note (`docs/research/`, `business/`) and are
> confirmed by a qualified advisor or counsel; an unsourced rule is
> `NOT SOURCEABLE — [what was searched]` and the item is `[?]`
> (`.claude/docs/business-research-protocol.md`, `research-protocol.md`).
> Markets in scope: Egypt and GCC/MENA unless the product brief says otherwise.

Scope rules: omit a section's conditional items with a one-line
`omitted — [config value]` (e.g. `distribution is hosted`, `stack.mobile is none`,
`stack.site is none`); **an unset value is a question, not an omission** — ask.

---

## 1. Product and Engineering Readiness

### Build health
- [ ] Release candidate built from a tagged commit; CI green; no skipped or quarantined tests added for launch
- [ ] Clean build for every layer in scope; zero-warning policy per the product's lint config
- [ ] All unit, integration and contract suites passing (cite the CI run); critical journeys signed off (`/smoke-check`)
- [ ] Per-release checklist for the launch version exists and is READY or CONCERNS-accepted: `production/releases/[product]-[version].md` (`/release-checklist`)

### Code quality (denominators required — see Phase 3)
- [ ] TODO count: `scanned [N] files: [M]` (zero required for launch or documented exceptions)
- [ ] FIXME count: `[M]` (zero required) · HACK count: `[M]` (each with documented justification)
- [ ] No debug output, test endpoints, sample credentials or verbose logging in release config
- [ ] No hardcoded dev/test values (`localhost`, test keys, placeholder tenants) in release-facing code or `deploy/` config
- [ ] All feature flags at production values; flag owners and removal dates named
- [ ] Error handling covers critical paths; every error response is RFC 9457 with generic detail

### Security sign-off — SL-RELEASE-SECURITY
- [ ] `/security-audit` (scope `full`) report exists for the launch commit with no open CRITICAL/HIGH (or each accepted by the user with owner and expiry)
- [ ] Cross-tenant and authz negative tests green; SL-TENANT-ISOLATION verdict recorded
- [ ] Scans on the launch commit: gitleaks, `govulncheck`, OSV-Scanner, image scan, SBOM — real output cited, none "not run"
- [ ] Threat models current for auth, billing, licensing, file upload, webhooks, PII flows in the product
- [ ] Web hardening verified on the deployed origin (CSP, HSTS, CORS allowlist, no tokens in `localStorage`); mobile: no secrets in the binary, tokens in Keystore/Keychain
- [ ] Secrets rotation procedure exists; the licence signing key is outside the repository and CI logs
- [ ] SL-RELEASE-SECURITY verdict: `[READY / CONCERNS / NOT READY / NOT ASSESSED / skipped — [mode] mode]`

### Operability — SRE-OPERABILITY
- [ ] `/livez` and `/readyz` on every service; one retained trace per critical journey (handler → use case → DB/cache)
- [ ] Backups automated, encrypted, off-host, RPO/RTO documented; **restore drill** dated `[date]` with measured RTO — never restored = untested
- [ ] Capacity: load test vs `docs/architecture/perf-budgets.md` on production-like data; resource limits, bounded pools, 30 % memory headroom
- [ ] Rehearsed rollback; zero-downtime deploy; migrations expand → migrate → contract
- [ ] SRE-OPERABILITY verdict: `[READY / CONCERNS / NOT READY / NOT ASSESSED / skipped — [mode] mode]`

### Quality
- [ ] Zero open S1 bugs; zero open S2 (or written exceptions with a named approver — none at `workflow: full`); S3 only with owner, ticket and target release (zero at `full`)
- [ ] Full regression passed; accessibility target (`accessibility.target`) met on the launch journeys
- [ ] Localization: all strings externalised; Arabic and English complete and proofread; RTL layouts checked
- [ ] Usability test on the onboarding / first-value journey done (`/usability-report`) — or `[?]`

---

## 2. Legal and Privacy

*Counsel and the user decide; the checklist records that it is done, by whom, and when.*

- [ ] **Terms of Service** finalised and approved by counsel; acceptance recorded at sign-up with a timestamp and version
- [ ] **Privacy Policy** published, linked in the app, site, store listings and sign-up flow; matches the data inventory
- [ ] **Data inventory, retention schedule and DSAR export/delete** exist for every personal-data field (`privacy-compliance-specialist`); deletion reaches backups per the stated retention
- [ ] **Egypt PDPL (Law 151/2020)** obligations reviewed from the official text — research note `[path]` or `NOT SOURCEABLE`; confirmed by counsel `[name, date]`
- [ ] **GDPR** applicability decided (are EU users served?): `[yes / no]`; if yes, lawful bases, records of processing, transfer notes and representative/DPO decision documented
- [ ] Cross-border transfer and **data residency** statements match where data is actually stored (hosted region) and what the contracts promise
- [ ] **DPA** template ready for enterprise customers (security-measures annex from `.claude/docs/security-baseline.md`, sub-processor list and approval, breach-notice timing, return/deletion) — **template, counsel approves**
- [ ] **Sub-processor list** published and current (hosting, email/SMS, payment, analytics, error tracking)
- [ ] **Breach notification** procedure written and linked to `incident-response.md` (who decides, who notifies regulators and customers, timing from the official rule — counsel confirms)
- [ ] Cookie/consent text and the **analytics consent** flow match section 9; marketing-email consent and unsubscribe work
- [ ] Third-party licence notices and attributions complete; bundle redistribution licences reviewed (L1–L4 in `.claude/docs/standing-decisions.md`) — self-hosted only
- [ ] For self-hosted: licence agreement / EULA covers activation, grace period, update eligibility, audit rights — counsel approved
- [ ] Trademark / name clearance and domain ownership confirmed
- [ ] Refund, cancellation and acceptable-use policies published and consistent with `pricing-model.md`

---

## 3. Billing, Tax and Finance

*Provider state (live mode) cannot be read from the repository — these are asked in Phase 4b.*

- [ ] Plans, prices, limits and entitlements in the **server-side catalogue** match `pricing-model.md` and the public pricing page; no price or entitlement is client-supplied
- [ ] Payment provider account verified for live mode (business verification complete); **live keys** configured in the secret store only — never in the repository, images or client bundles; test-mode keys absent from production config
- [ ] Products/prices created in **live mode**; **webhook endpoints and signing secrets** configured for live mode; signature verification, replay protection and idempotent handling verified against the provider's sandbox/test events
- [ ] A **live end-to-end payment, refund and cancellation** performed by the user on a real instrument, with the result recorded (this skill never makes a payment)
- [ ] Card data never touches our servers (hosted checkout / tokenisation) — PCI scope confirmed out by design
- [ ] **Tax / VAT**: tax determination inputs defined (country, B2B/B2C, tax ID); tax-inclusive/exclusive display rule; rates and rules sourced from the official authority in research note `[path]` or `NOT SOURCEABLE`; confirmed by an accountant `[name, date]`
- [ ] **Invoices / e-invoicing**: invoice contents and numbering; Egypt (ETA) and/or Saudi (ZATCA) e-invoicing obligations — official rule cited from research or `NOT SOURCEABLE`; registration/onboarding status `[done / not required / pending — owner]`
- [ ] Currencies and payment methods offered match the market plan (`business/pricing/`); local-method availability and fees from the provider's own pages, dated
- [ ] Trials, coupons, proration, dunning (failed-payment retries and emails) and downgrade/cancel flows tested; abuse cases (trial farming, coupon stacking, seat inflation) have a limit or detection
- [ ] Licence issuance for one-time licences: key signing, delivery email, activation limits tested (self-hosted)
- [ ] Revenue reporting / reconciliation: payments reconcile to provider payouts; finance owner named

---

## 4. Support and Customer Success

- [ ] Support channels live and monitored (email/helpdesk/chat); a named owner and **response-time targets** per plan, with Arabic and English coverage hours stated
- [ ] Help centre / docs published for sign-up, first value, billing, data export, account deletion; recurring-question answers drafted (`technical-writer`)
- [ ] Support-to-engineering path: reports arrive in `/bug-report` format with proposed severity; security reports route to `security-lead`
- [ ] Support access to a tenant's data happens only through the audited, customer-consented flow defined by `security-lead` — and the support team has been told
- [ ] Known-issues page and canned responses ready; escalation contacts and out-of-hours rule written
- [ ] Enterprise onboarding checklist and templates exist (records live in the support/CRM tool, not the repository)
- [ ] Self-hosted: support entitlement, version-support policy and the diagnostics a customer can send (version, masked logs, telemetry-off bundle) documented

---

## 5. Status Page and Incident Communication

- [ ] Public **status page** live, on infrastructure independent of the product's own hosting
- [ ] Components map to the critical journeys / SLOs (login, core action, payment, licence activation); subscribe channels (email/RSS/webhook) work
- [ ] Incident severity guide and message templates ready (`.claude/docs/templates/incident-response.md`); drafted by `customer-success`, **posted by the user**; who posts, where and how fast is written
- [ ] Maintenance-window and customer-notice procedure for planned downtime and price/terms changes
- [ ] Contact for security reports published (security.txt / security page) with a response commitment

---

## 6. Monitoring, Alerting and On-Call

- [ ] **SLOs** defined for the critical journeys (`docs/architecture/slos.md`) — required at `workflow: full`; below `full` record `slos.md not required at workflow: [tier]` and state which alerts exist instead
- [ ] **Burn-rate alerts** on the SLOs plus cause alerts: DB down, disk > 85 %, certificate expiring, backup failed; **every alert links a runbook** in `docs/runbooks/`; a test page reached the on-call person
- [ ] Dashboards for RED per endpoint, USE per resource, pool wait, cache hit ratio, queue lag, business metrics (signups, activations, payments, licence activations)
- [ ] Crash/error reporting live on web and mobile with release identifiers and symbolication; alert thresholds set
- [ ] Synthetic check on sign-up → first value and on the payment path (user-run or monitoring-tool)
- [ ] **On-call schedule** set for the first 72 hours with escalation contacts verified; incident command roles named; `/incident` path known; secrets-rotation drill
- [ ] Rollback plan documented and rehearsed; **hotfix path** (`/hotfix`) tested — an emergency fix can ship within the agreed time
- [ ] Capacity headroom for a launch spike: expected signups/req-per-second vs load-tested capacity; autoscaling or manual scale-up plan with the first resource to saturate named

---

## 7. Infrastructure and Delivery

- [ ] Production environment provisioned from `deploy/hosted/` (Docker Compose on VPS); DNS, TLS (auto-TLS), HSTS and security headers live; databases not published on host ports
- [ ] Reverse proxy rate limits set for auth/OTP/expensive endpoints; DDoS/WAF posture decided
- [ ] Transactional **email deliverability** set up for the sending domain (SPF, DKIM, DMARC) and tested into major inboxes; OTP/SMS provider live with sender registration done where the market requires it — `[owner]`
- [ ] Object storage, CDN and cache headers (hashed assets immutable, HTML revalidated); cost alerts configured
- [ ] Secrets in the secret store with `0600`/provider access control; nothing in images; rotation owner named
- [ ] Self-hosted only: signed bundle published to the release channel, customer download/licence-delivery path works, upgrade-path matrix published (`/release-checklist` track 2)

---

## 8. Marketing Site and Go-to-Market

*Omit with `omitted — stack.site is none` when there is no marketing site; unset → ask.*

- [ ] Marketing site deployed from `site/`; Arabic and English with correct RTL; pricing page matches the live catalogue and shows VAT treatment
- [ ] Legal pages (Terms, Privacy, DPA, sub-processors, refund) linked in the footer and sign-up flow
- [ ] Sign-up, trial start and checkout tested end-to-end **from the marketing site**, on desktop and mobile
- [ ] SEO basics (titles, descriptions, canonical, sitemap, robots), social cards, Lighthouse report within budget
- [ ] GTM and marketing plans exist (`business/marketing/`) with channels, owners, dates and budget; launch announcement, social posts and customer emails **drafted — sent by the user**
- [ ] Sales playbook / proposal and demo-tenant ready if sales-led (`business/sales/`); demo data is synthetic
- [ ] Press / partner / community outreach list prepared (companies and public contacts only)
- [ ] App store listings approved and live where mobile ships (`/release-checklist` track 3)

---

## 9. Analytics and Consent

- [ ] Events in `docs/analytics/` tracking plan are implemented, receiving data, and match `.claude/docs/templates/tracking-plan.md`; the activation metric and funnel are defined and visible
- [ ] **Consent** respected: analytics and marketing trackers load only after consent where required; the default is decline; consent choices persist and can be withdrawn; no tracking before consent in web or mobile
- [ ] No PII in event payloads or telemetry (verified by grep of a real run); user identifiers hashed or pseudonymous
- [ ] Self-hosted: telemetry **off by default**, no phone-home without explicit opt-in; the collector config ships so the customer can point it at their own backend
- [ ] Retention for analytics data matches the privacy policy

---

## 10. Operations and Launch Day

- [ ] Launch-day plan: sequence (migrate → deploy → verify → announce), owners, time, abort criteria and who decides
- [ ] War-room channel and the launch dashboard bookmarked by all leads
- [ ] Communication plan for launch issues: who posts, where (status page, in-app, email), how fast
- [ ] First-week plan: daily metrics review (signups, activation, errors, payments, support volume), triage cadence (`/bug-triage`), and `/post-release-fix` capacity reserved
- [ ] Rollback or "stop signups" switch exists for a bad launch (feature flag or maintenance mode) and is tested

---

## 11. Go / No-Go and Sign-Offs

Verdict rules are in `references/2-verdict.md`. Sign-offs are recorded by the
user, never by this skill:

- [ ] `product-director` — product scope, positioning and pricing
- [ ] `cto` — technical health and stability
- [ ] `qa-lead` — quality and test coverage
- [ ] `security-lead` — security sign-off (SL-RELEASE-SECURITY)
- [ ] `sre-lead` — operability (SRE-OPERABILITY)
- [ ] `producer` — schedule and overall readiness
- [ ] `release-manager` — build and deployment readiness
- [ ] Counsel / accountant — legal, privacy, tax items (external; names and dates)
