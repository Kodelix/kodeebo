---
paths:
  - "site/**"
---

# Marketing Site Rules (Astro, static output)

- `output: 'static'` — no server adapter in production unless an ADR says otherwise.
- Design through `/impeccable`; the site and the app share design tokens.
- Ship zero JS by default; hydrate islands only where interaction needs it (`client:visible` over `client:load`).
- SEO: unique title/description per page, canonical URLs, Open Graph, sitemap, `hreflang` for AR/EN, structured data for product and pricing.
- Pricing shown on the site is read from the same source as billing (generated at build time), never typed by hand.
- Forms post to the backend API with CSRF protection and rate limiting; no third-party form endpoints holding customer data without an ADR.
- Analytics are privacy-respecting and consent-gated; no tracking scripts before consent.
- Lighthouse budgets in CI: Performance, Accessibility, Best Practices, SEO all ≥ 95.
