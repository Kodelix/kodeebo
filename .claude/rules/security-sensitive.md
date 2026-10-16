---
paths:
  - "**/auth/**"
  - "**/identity/**"
  - "**/billing/**"
  - "**/licensing/**"
  - "**/tenancy/**"
  - "**/admin/**"
---

# Security-Sensitive Code Rules

Standard: `.claude/docs/security-baseline.md` (ASVS 5.0 Level 3 for these modules). A threat model must exist for the feature (`docs/architecture/threat-models/`).

- Changes here are reviewed by `appsec-engineer` in addition to the normal review.
- Use vetted libraries for crypto, JWT/JOSE, password hashing, SAML/OIDC; no hand-rolled primitives or token formats.
- Constant-time comparisons for secrets, tokens and OTPs.
- Authorization checked in the use case before any side effect; object-level checks on every resource; tenant from the authenticated context, never from the request body.
- Admin and impersonation actions require re-authentication or step-up, are time-boxed, and are written to the audit log with actor, target, reason.
- Billing: prices, plans and entitlements come from the server-side catalogue; client input is an intent, not an amount. Entitlement changes are idempotent and event-sourced or audited.
- Licensing: licences are signed (Ed25519) server-side; the product verifies with an embedded public key; activation/offline grace rules are in the spec; the signing key never enters this repository.
- Every security event is audited; every audit write is append-only.
- Negative tests are mandatory: bypass attempts, cross-tenant access, replay, brute force/rate limit, expired/forged tokens.
