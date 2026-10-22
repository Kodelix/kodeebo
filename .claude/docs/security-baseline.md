# Security Baseline

DoD gate 7. Security is a property of every story, not a phase. Owned by
`security-lead`; enforced by `appsec-engineer` in review and by `/security-audit`.

## Standards in force (verified 2026-10-10)

| Standard | Version | Applies to |
|---|---|---|
| OWASP ASVS | **5.0.0** (May 2025; IDs renumbered vs 4.0.3) | backend, web — verification target **Level 2** for all products, **Level 3** for auth, billing and licensing modules |
| OWASP Top 10 | **2025** (final Jan 2026) | awareness / review checklist |
| OWASP API Security Top 10 | **2023** | every HTTP/gRPC API |
| OWASP MASVS | **2.1.0** (incl. MASVS-PRIVACY), tested via MASTG | Android, iOS, KMP |
| Privacy law | Egypt PDPL (Law 151/2020); GDPR where EU users are served | all personal data |
| PCI DSS | **reduced scope by design**: card data never touches our servers — hosted checkout / tokenisation only. Hosted checkout still carries a self-assessment (typically SAQ A, or A-EP for embedded payment fields); the applicable SAQ is **confirmed with the acquirer or a QSA**, never concluded by an agent | billing |

Requirement IDs are looked up in the official ASVS 5.0 / MASVS documents at
mapping time — never recalled from memory (see `research-protocol.md`).

## Non-negotiables

### Access control (Top 10 A01, API1/API3/API5)
- Deny by default. Every endpoint declares its policy; a route with no policy fails the build/test.
- **Object-level authorization on every resource access** (the #1 API bug): load → check tenant + ownership/role → act.
- **Tenant isolation in depth**: app-layer scoping in every query **and** Postgres Row-Level Security (or schema/DB isolation per `tenancy.model`); Mongo queries always filtered by `tenant_id` through the repository, never ad-hoc.
- Mass assignment blocked: explicit request DTOs, never bind into domain/DB models.
- SSRF: outbound requests to user-supplied URLs only through an allowlisting egress client that blocks private/link-local/metadata ranges.

### Server authority — the client is never trusted
Every client — web SPA, mobile app, desktop or counter client, partner integration, webhook sender — runs on hardware we do not control. What it sends is a claim.
- Every rule, permission check and validation runs on the server. Client-side checks are UX only: a request the server would refuse is refused (RFC 9457) whatever the client showed.
- The server takes from a client only **raw facts and intents**: what the actor chose (ids, quantities, options), the version of the server data it chose from, and — for an offline client — device time, a sequence number and observations only a person on site can make (a counted quantity, waste, a quantity received). Each of these is still checked.
- **Every derived value is recomputed on the server** from its own versioned data: prices, discounts, taxes and fees, totals, time-based amounts, entitlements, stock effects, differences. A client-sent derived value is never stored or acted on as authoritative; at most it is kept beside the server's value as a claim to compare.
- **Offline clients** run the same rules (one shared kernel and test-vector suite) so they work without a network; their results stay claims. Where the product rule is that a recorded fact is never rejected (money already taken), the server records the fact, recomputes, and flags every difference for review: never a silent rejection, never silent trust. Server data an offline client may have used is versioned, so the server recomputes at the version the client used.
- Every command from a device is checked for enrolment and revocation, licence or lease, the actor's permission and limits **at the time of the act** (from a versioned authority record), that the claimed data version existed then, clock plausibility, and idempotency.
- Tenant, branch or location, and actor come from the authenticated credential or session, never from the payload.
- Evidence: every story that accepts client input carries a negative test that a tampered value (price, total, derived quantity, foreign id, version) is refused or flagged.

### Authentication & sessions (A07)
- Passwords: Argon2id (parameters from current OWASP guidance at implementation time); breached-password check; no composition rules theatre.
- MFA available for all, enforced for admins; WebAuthn/passkeys preferred over SMS OTP.
- OTP: ≥ 6 digits, short TTL, single use, stored as an **HMAC with a server-side key** (a plain hash of a 6-digit code is trivially reversible), attempt-limited per identifier **and** per IP, constant-time compare, no enumeration in responses.
- Tokens: short-lived access tokens + rotating refresh tokens with reuse detection; web sessions in `HttpOnly; Secure; SameSite` cookies — no tokens in `localStorage`.
- Enterprise SSO (OIDC/SAML) through vetted libraries only; validate issuer, audience, signature, expiry, and nonce/state.

### Input, output, injection (A05)
- Parameterized queries only; no string-built SQL or Mongo query objects from user input (block `$where`, operator injection).
- Output encoding by the framework; React `dangerouslySetInnerHTML` banned unless sanitized with a vetted sanitizer and reviewed.
- File upload: type sniffing (not extension), size limits, stored outside web root with random keys, served with `Content-Disposition` and a separate origin; images re-encoded; AV scan for enterprise tiers.

### Cryptography (A04)
- TLS everywhere (Caddy/Traefik auto-TLS), HSTS on.
- At-rest encryption for secrets and sensitive columns (envelope encryption, keys outside the DB).
- Licence keys signed with Ed25519; signing key offline / in a KMS, never in the product repo or CI logs.
- No custom crypto; libraries from the standard library or a vetted package listed in the stack reference.

### Supply chain (A03, A08)
- Lockfiles committed; dependency updates via reviewed PRs (Renovate/Dependabot).
- Scans on every PR: `govulncheck`, OSV-Scanner on the lockfiles it is documented to cover (`go.mod`, Gradle lockfiles, `package-lock.json` — `docs/stack-reference/tooling/best-practices.md`), container image scan. `pnpm-lock.yaml` and SwiftPM `Package.resolved` are reported **unscanned** until `/research` confirms a scanner.
- npm: `pnpm` (version in `docs/stack-reference/pins.yaml`) with the supply-chain settings in `pnpm-workspace.yaml` verified in `docs/stack-reference/vite-react/best-practices.md` §11: `strictDepBuilds: true` + an explicit `allowBuilds` allowlist (dependency build scripts do not run otherwise), `minimumReleaseAge` ≥ 1440 minutes, `trustPolicy: no-downgrade`, `blockExoticSubdeps: true`. Never `dangerouslyAllowAllBuilds`.
- React: no `react-server-dom-*` package in the SPA's lockfile (the RSC CVE class); `react` at or above the floor in `vite-react/VERSION.md`.
- CI pins third-party actions by commit SHA; least-privilege tokens; SBOM (CycloneDX) generated per release.
- Self-hosted bundles and update manifests are signed with a **release-signing key that is distinct from the licence-signing key**; both are held offline or in a KMS/HSM, never in the repo or CI variables. The installer verifies the signature over the exact downloaded bytes before extracting or applying anything, rejects downgrades to a lower release sequence, and fails closed. Tooling and algorithm are an ADR backed by `/research`; key rotation and compromise have a runbook in `docs/runbooks/`.

### Web hardening (SPA served statically)
- Strict CSP (no `unsafe-inline`, no `unsafe-eval`; nonce/hash only if unavoidable), `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
- CSRF: `SameSite` cookies + CSRF token or custom-header check on state-changing requests.
- CORS: explicit origin allowlist; never `*` with credentials.

### API (API4, API6, API8)
- Rate limits and quotas per tenant, per actor, per route; stricter on auth, OTP and expensive endpoints.
- Pagination limits enforced server-side; request body size limits; timeouts on every handler.
- Business-flow abuse cases (trial abuse, coupon stacking, seat inflation) listed in the threat model.

### Mobile (MASVS)
- Secrets never shipped in the app; tokens in Keystore / Keychain; certificate pinning only with a rotation plan.
- No sensitive data in logs, screenshots of sensitive screens blocked, backups excluded for sensitive storage.
- Deep links and intents validated; WebViews locked down.

### Errors & logging (A09, A10)
- Fail closed. Exceptions never leak stack traces, SQL, or internal hostnames to clients (RFC 9457 with generic detail).
- Security events logged (login success/failure, MFA changes, role changes, API key creation, licence activation) to an append-only audit log per tenant.

### Secrets
- From environment / secret store only; `.env` never committed; gitleaks on every commit; rotate on any suspected exposure.

## Vulnerability SLAs

Defaults, changed only by ADR (owner `security-lead`): **critical** fixed or mitigated within 48 h, **high** 7 days, **medium** 30 days, **low** 90 days from triage. Reachable-in-our-code findings are triaged before merely present ones. Every exception has an owner and an expiry date. Self-hosted customers are notified per the release policy for critical and high findings that affect shipped versions.

## Threat modelling

Required for any story touching: authentication, authorization model, billing,
licensing, file upload, webhooks, PII export/delete, admin/impersonation, or
a new external integration. Use `/threat-model` (STRIDE + abuse cases), output
to `docs/architecture/threat-models/<feature>.md`, and link the mitigations to
stories and tests.

## Story security evidence

A story closes with: the ASVS/MASVS requirement IDs it satisfies, the negative
tests that prove them (authz, cross-tenant, injection, rate limit), and a clean
dependency scan. Missing evidence on a security-sensitive story is **BLOCKING**.
