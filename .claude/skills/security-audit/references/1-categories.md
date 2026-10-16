# /security-audit — Audit Categories

> Phase 3 of `SKILL.md`. These are the checks the `appsec-engineer` runs for the
> scope. Each category states what must be true, how to look, and what a
> **zero-hit probe** means. Probes are **starting points, not complete sets**: a
> probe that finds nothing is reported with its denominator
> (`scanned [N] files under [roots], [M] hits`) — never as a bare "none".

## How to look (all categories)

1. **Find the mechanism first, then test it.** Read the code to locate the
   authorization policy layer, the tenant-scoped repository base, the egress
   client, the upload handler, the webhook verifier, the licence verifier. A
   grep cannot tell you a control exists; reading the mechanism and then
   finding the call sites that bypass it can.
2. **Layers come from `resolve_code_root`** (`bash .claude/hooks/yaml-helper.sh
   resolve_code_root`). Empty result → every code category is
   `NOT ASSESSED — code roots unresolved`. A root with no source files →
   `NOT ASSESSED — no source under <root>`.
3. **Stack idioms come from `docs/stack-reference/<layer>/`** and
   `.claude/rules/*.md`. A layer whose stack value is unset, or whose reference
   does not cover an item, makes that item `NOT ASSESSED — not sourced for
   <layer>`; **never fill an API name, flag or control from memory.**
4. **Requirement IDs** (ASVS 5.0.0, MASVS 2.1.0, API Top 10 2023, Top 10:2025)
   are looked up in the official OWASP documents in Phase 4 of `SKILL.md`, not
   written here and not recalled.
5. **Tests are evidence.** For authorization and tenancy, "the control exists"
   is not enough: the negative test must exist and, when it can be run, pass.

## Known gaps in the stack reference (force `NOT ASSESSED` for the item)

These are recorded in `docs/stack-reference/` as `NOT SOURCEABLE`. They make the
named check `NOT ASSESSED` until `/research` closes them — they are not
skippable and not to be filled from memory.

| Check | Gap | Where recorded |
|---|---|---|
| MASVS control IDs for Android | "mapping to MASVS controls is NOT SOURCEABLE" | `docs/stack-reference/compose/best-practices.md` §4 |
| Android backup / data-extraction rules (`allowBackup`) | NOT SOURCEABLE | same, §4 |
| Replacement for deprecated `EncryptedSharedPreferences` | NOT SOURCEABLE | same, §4 |
| iOS Keychain item attributes / access-control flags | NOT SOURCEABLE | `docs/stack-reference/swiftui/best-practices.md` §5 |
| iOS required-reason API categories and reason codes | NOT SOURCEABLE | same, §5 |
| ATS per-domain exception subkeys | NOT SOURCEABLE | same, §5 |
| In-memory access tokens / refresh-token rotation guidance for the SPA | NOT SOURCEABLE from a primary source | `docs/stack-reference/vite-react/best-practices.md` §2 |
| Full CSP directive list (`frame-ancestors`, `connect-src`, `report-to`) | NOT SOURCEABLE | same, §3 |
| OSV-Scanner on `pnpm-lock.yaml` and SwiftPM `Package.resolved` | not in the sourced supported-lockfile table → **unscanned** | `docs/stack-reference/tooling/best-practices.md` |

Check that these are still gaps: re-read the cited section before relying on the
table (the reference may have been updated since this skill was written).

---

## Category 1 — Authentication and sessions

Must be true: Argon2id for passwords with breached-password check; MFA available
for all and enforced for admins; OTP ≥ 6 digits, short TTL, single-use, stored
hashed, attempt-limited per identifier **and** per IP, constant-time compare, no
enumeration; short-lived access tokens + rotating refresh tokens with reuse
detection; web sessions in `HttpOnly; Secure; SameSite` cookies, no tokens in
`localStorage`/`sessionStorage`; JWT/OIDC/SAML validation of issuer, audience,
signature, algorithm, expiry, nonce/state through vetted libraries only
(`security-baseline.md`).

Probes: `localStorage`, `sessionStorage` near `token|jwt|session` (web); custom
hashing or token code (`sha256` of a password, hand-rolled JWT); OTP generation
and comparison sites (`==` on secrets instead of constant-time compare); login,
OTP and reset handlers for rate-limit middleware; the login/OTP/reset response
bodies for account enumeration.

Tests expected: lockout / rate limit, refresh-token reuse, expired/forged token,
OTP brute force.

## Category 2 — Authorization and API abuse

Must be true: deny by default (a route with no declared policy is a finding);
object-level check on every resource access (load → check tenant + ownership/role
→ act) inside the use case; explicit request DTOs (no mass assignment); rate
limits and quotas per tenant/actor/route, stricter on auth, OTP and expensive
endpoints; server-side pagination caps, body-size limits and handler timeouts.

How: enumerate routes from `contracts/openapi/*.yaml` and the router; for each,
find its policy; list routes with none. Read each handler that takes an ID and
confirm the tenant/owner check. Check DTOs for fields like `role`, `tenant_id`,
`plan`, `price`.

Tests expected per endpoint: anonymous, wrong role, wrong tenant (returns 404),
mass-assignment attempt, oversized body, rate-limit exhaustion with `429` +
`Retry-After`.

## Category 3 — Tenant isolation

Read `tenancy.model` from the resolved config. **Unset → the category is
`NOT ASSESSED — tenancy.model unset`** (not "not applicable"). For `single-tenant`
record `not applicable — single-tenant` with the reason; do not skip silently.

Must be true (`shared-schema-rls`): every table carrying `tenant_id` has RLS
**enabled and forced** with a policy keyed on the tenant, the application
connects as a **non-owner, NOBYPASSRLS** role, and the tenant is set per
request/transaction; **and** every query in app code is tenant-scoped through the
repository (defence in depth — RLS alone is a finding). For `schema-per-tenant` /
`db-per-tenant`: provisioning and connection routing shown. MongoDB queries are
filtered by `tenant_id` through the repository, no `$where`/operator injection.
Cache keys, queue messages, outbox events, background jobs, object/file keys,
search indexes and exports are tenant-scoped. The tenant comes from the
authenticated context, never the body, path or a client header.

How: list `**/migrations/**` for tenant-owned tables and check each for RLS
enable + force + policy; grep repositories for queries lacking the tenant
predicate (list each with `file:line` and its scope); list cache-key builders.

Evidence required: a **cross-tenant negative test per repository** (tenant A's
row invisible to tenant B) running against a real database, plus a
database-layer test as the non-owner role. A test that exists but was not run
here is `exists — not run`, never `passing`.

## Category 4 — Injection and output encoding

Must be true: parameterized queries only; no string-built SQL or Mongo query
objects from user input; framework output encoding; `dangerouslySetInnerHTML`
only with a vetted sanitiser and review; header, log and path injection blocked.

Probes: SQL keywords adjacent to string concatenation or formatting
(`SELECT`/`INSERT`/`UPDATE`/`DELETE` with `+`, `fmt.Sprintf`, string templates);
`$where`, `$function` and user-supplied operator keys (`$ne`, `$gt`) in Mongo
paths; `dangerouslySetInnerHTML`; `innerHTML`; unescaped template rendering in
`site/`; `exec`/shell invocation with request data; `filepath`/path joins with
request data.

## Category 5 — SSRF

Must be true: every outbound request to a user-supplied URL goes through the
allowlisting egress client that blocks private, loopback, link-local and cloud
metadata ranges, DNS rebinding and redirects to them.

How: find the egress client; find every HTTP client construction and call; list
those that bypass it (also `http.DefaultClient`, which `backend-go.md` forbids).
Fields that accept a URL: webhooks out, avatar/logo URL, import-from-URL, SSO
metadata URL.

Tests expected: private/loopback/link-local/metadata addresses, redirect and
rebinding blocked.

## Category 6 — File upload
Must be true: type sniffing (not extension), size limits, random storage keys,
stored outside the web root, served with `Content-Disposition` from a separate
origin, images re-encoded, AV scan for enterprise tiers, tenant-prefixed keys,
scoped signed URLs.

How: find upload handlers (multipart parsing, presigned URL issuance) and read
them against the list. Tests expected: polyglot, oversized, wrong-extension,
path-traversal filename, decompression bomb.

## Category 7 — Webhooks, payments and business-flow abuse

Must be true: signature verified on the **raw bytes** before parsing, timestamp
tolerance, replay and duplicate rejection (dedupe by event ID), asynchronous
processing; prices, plans and entitlements come from the server-side catalogue
(client input is an intent, not an amount); entitlement changes idempotent and
audited; card data never touches our servers (hosted checkout/tokenisation only
— PCI DSS out of scope by design). Business-flow abuse cases (trial farming,
coupon stacking, seat inflation, quota evasion) are in the threat model and have
a detection or limit.

How: find webhook endpoints and read the verification order; compare against the
integration spec; check the billing module's input DTOs for client-supplied
amounts.

## Category 8 — Secrets

Must be true: no secret in code, logs, URLs, images (layers, build args) or
client bundles/mobile binaries; `.env` not committed, `.env.example` lists names
without values; secrets from environment or secret store; a rotation runbook
exists; the Ed25519 licence signing key lives outside the repository and CI logs.

Run **gitleaks** (`references/2-scanners.md`) on the repo and the release range.
Add targeted probes: `BEGIN PRIVATE KEY`, `sk_live`, `api[_-]?key`, `secret`,
`password`, `token` assignments in non-test source; secrets in `deploy/` compose
files and Dockerfiles (`ARG`/`ENV` with values); `.env*` tracked by git
(`git ls-files`). **Never print a secret value** in the report — location and
rule ID only; scanners run with `--redact`.

## Category 9 — Dependencies and supply chain

Run **govulncheck**, **OSV-Scanner** and a **container image scan**
(`references/2-scanners.md`). Check: lockfiles committed; pnpm settings from
`vite-react/best-practices.md` §11 present (`strictDepBuilds`, explicit
`allowBuilds`, `minimumReleaseAge`, `trustPolicy: no-downgrade`,
`blockExoticSubdeps`; never `dangerouslyAllowAllBuilds`); no `react-server-dom-*`
package in the SPA lockfile; `react` at or above the floor in
`vite-react/VERSION.md`; third-party CI actions pinned by commit SHA; base image
digests pinned; CycloneDX SBOM generated per release; self-hosted bundle signed.
Triage is **reachability-first** (govulncheck): not-reachable findings are
recorded as such, with the evidence, and re-checked on upgrade.

Output also the **dependency inventory** (name, version, ecosystem, advisory
status) at the level the scanners returned — and the list of lockfiles **not
scanned** (see the gap table: `pnpm-lock.yaml`, `Package.resolved`).

## Category 10 — Web hardening: headers, CSP, CORS, CSRF

*Skip with a named reason only when `stack.web` and `stack.site` are both `none`; **unset is not `none`**.*

Must be true on the **built release, not the source**: strict CSP without
`unsafe-inline`/`unsafe-eval` (nonce/hash only if unavoidable),
`frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`,
`Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`, HSTS;
CORS explicit origin allowlist, never `*` with credentials; CSRF defence
(`SameSite` + token or custom-header check) on state-changing requests; source
maps not served publicly.

How: read the proxy config in `deploy/` (Caddy/Traefik) and the CSP source; if a
built bundle is available, inspect it. Response headers of a **running** stack
are fetched with `curl -I` against the dev stack (`.claude/docs/run-and-observe.md`)
— if no stack was run, header checks read config only and the report says so.
CSP directive details beyond what the reference sources: `NOT ASSESSED — not
sourced` for those directives.

## Category 11 — Mobile storage and transport (MASVS 2.1.0)

*Skip with a named reason only when `stack.mobile` is `none`; **unset is not `none`**.*

Must be true: no secrets in the binary; tokens in Keystore (Android) / Keychain
(iOS); sensitive screens block screenshots; backups excluded for sensitive
storage; HTTPS only (ATS exceptions justified); certificate pinning only with a
rotation plan; deep links and intents validated, `android:exported` explicit,
WebViews locked down (JavaScript off unless required, `addJavaScriptInterface`
only for trusted content); no PII in logs; privacy manifest
(`PrivacyInfo.xcprivacy`) complete including SDKs.

How: read `mobile/android/` manifests and storage code, `mobile/ios/` Info.plist,
entitlements and manifest, `mobile/shared/` for KMP storage. The items in the
gap table above are `NOT ASSESSED` regardless of what the code shows. iOS code
cannot be built or run on a Linux host (`swiftui/VERSION.md`): a run-time check
there is `not run — requires macOS`.

## Category 12 — Licence verification and customer bundle (self-hosted)

*Skip with a named reason only when `distribution.model` is `hosted`; **unset is not `hosted`**.*

Must be true: licences signed (Ed25519) server-side; the product verifies with
an embedded public key; the signing key never enters the repository or CI logs;
tampered, expired-within-grace, expired, revoked, replayed and clock-rolled-back
licences are handled per the spec; no downgrade of the signature algorithm;
entitlement checks cannot be bypassed by editing config; the update channel
verifies signatures before applying; bundle contents obey `deploy.md` and ROADMAP
decisions L1–L4: **Valkey only** for cache (no Redis ≥ 7.4, no Dragonfly), the
official MongoDB image **referenced** (never a binary or a derived image), **OTel
Collector only** with exporters off, telemetry off by default; no default
credentials; secrets generated at install; TLS configured.

How: read `licensing/` code and the licence spec; read `deploy/self-hosted/`
compose files and installer; run `bash .claude/scripts/project-coherence.sh` and
quote its `LICENCE` lines verbatim. Dynamic licence-bypass testing is a
`/pentest` item (`licensing-specialist` receives the results).

## Category 13 — Logging, audit and PII

Must be true: no passwords, tokens, OTPs, API keys, card data, national IDs,
clear phone numbers/emails or full request/response bodies in logs/telemetry; no
stack traces, SQL or internal hostnames in client errors (RFC 9457 with generic
detail); fail closed; security events (login success/failure, MFA changes, role
changes, API-key creation, licence activation, impersonation) written to an
append-only per-tenant audit log, with a test per event; admin/impersonation is
step-up, time-boxed and audited.

How: grep the logger call sites near auth/billing/identity for token and body
logging; if a running stack was brought up, **grep a real run's logs and a
telemetry sample** for PII and secrets and save the command and result — a
by-reading check is reported as `by reading only`. Check error-mapping code for
internals leakage.
