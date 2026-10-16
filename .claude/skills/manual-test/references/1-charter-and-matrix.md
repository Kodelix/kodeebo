# /manual-test — Phase 2: The Charter and the Coverage Matrix

> Part of `/manual-test`. `SKILL.md` names when to read this file; the settings
> it resolved and the rules under its headings still apply here.

## 1. Charter fields

`production/qa/evidence/[ID]/charter.md`:

```markdown
# Charter: [ID] — [date]
**Mission**: [one sentence: explore <area> with <resources> to discover <information>]
**Build / commit**: [hash] · **Environment**: [compose dev | named staging] · **Tester(s)**: [qa-tester + user]
**Time box**: [45 | 60] minutes · **Start/End (UTC)**: filled during the session
**Areas in scope**: [features, screens, endpoints, flows]
**Areas out of scope**: [and why]
**Risks driving the session** (ranked): [from changes in the diff, open bugs, the threat model,
  money/data-loss paths, last-minute changes, first-time-through code]
**Tooling**: [curl/httpie, Playwright, browser devtools, adb, simulator, trace UI]
**Heuristics to apply**: [named — see §3]
**Matrix**: [table — §2]
**Stop conditions**: [an S1; stack unhealthy; time box reached]
```

- Mission verbs are concrete ("explore invitation limits under the Starter plan
  with a second tenant to find authorization and quota gaps"); "test the
  feature" is not a mission.
- The time box is **45 to 60 minutes**. A larger area is split into several
  charters, one per session — not one long unbounded one.
- Risks come from sources the session can cite: the changed files
  (`git diff --stat <base>...HEAD`), `production/qa/bugs/`, the threat model in
  `docs/architecture/threat-models/`, the spec's Edge Cases, the pricing model's
  limits. A risk with no source is marked `hunch`.

## 2. The coverage matrix

Pick the cells deliberately — a full cross-product is rarely worth it. Each cell
is `actor × tenant × plan × locale/surface` with the intent in one line.

| Axis | Values to consider | Source |
|---|---|---|
| **Role** | anonymous, owner, admin, member, read-only, finance, support — whichever the product defines | the spec and `design/registry/entities.yaml` (roles, permissions); absent → ask, mark `roles: unspecified` |
| **Tenant** | tenant A (home), tenant B (other tenant: same resource ID used by A → expect 404/403, no data), a fresh empty tenant | seeded tenants in `tools/seed/` |
| **Plan / entitlement state** | free, trial (and trial-expired), paid, at limit, over limit, downgraded, suspended | `design/specs/pricing-model.md`; absent → ask |
| **Locale / direction** | English LTR and Arabic RTL (mirrored layout, truncation, numerals and dates, mixed-direction strings) | `design/localization/` |
| **Surface** | web 1440 px and 390 px; Android; iOS (macOS host only); API; self-hosted install/upgrade when the bundle is in scope | `stack` |
| **Data** | empty, one, many, boundary (limit, limit ± 1), maximum length, special characters, large page | the spec's numbers |
| **State** | new session, expired session, concurrent sessions, offline/partial, after a dependency stops | |

- **Every callable thing gets its negative cells:** anonymous, wrong role, other
  tenant, invalid/oversized/malformed input, duplicate submission (idempotency),
  expired session, and rate-limit exhaustion where the spec defines one.
- **Every user-visible thing gets both languages**; a UI cell without its Arabic
  pass is half a cell.
- Before the session, **check the seed**: each chosen role/tenant/plan has a
  seeded user. A missing one makes the cell `NOT COVERED — no seeded [role/plan]`
  and is passed to `dev-tooling-engineer` (seed data) in the notes; never create
  production-like users by hand.

Cell format:

| # | Actor | Tenant | Plan | Locale/surface | Intent | Assigned to | Result | Evidence |
|---|---|---|---|---|---|---|---|---|
| C1 | member | A | Starter, at seat limit | web 390, AR | invite a 6th member → upgrade prompt, no partial invite | qa-tester | | |

## 3. Heuristics — name those you apply, and those you skip

Roles and permissions · data (boundary, empty, huge, hostile characters) ·
interruptions (reload mid-submit, back button, expired session, two tabs) ·
locale and direction · time (clock edges, expiry, time zones, trial end) ·
concurrency (double click, two users on one record, a webhook racing a request) ·
failure (stopped dependency, slow response, offline) · accessibility (keyboard
only, focus order in RTL, screen-reader labels, reduced motion, text scaling) ·
money (minor units, rounding, currency display, VAT shown as the spec says) ·
privacy (what appears in URLs, logs, error messages).

The notes list the heuristics applied and the ones deliberately not applied, with
the reason.
