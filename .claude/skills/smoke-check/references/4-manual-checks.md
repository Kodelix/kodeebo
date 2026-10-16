# /smoke-check — Phase 4: Run Critical-Journey and Manual Smoke Checks

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Run Critical-Journey and Manual Smoke Checks

**In this file:**

- Checklist source: name it in the report
- Part A — Critical-journey checks the skill runs
- Part B — Batches for the developer
  - Batch 1 — Core stability
  - Batch 2 — Sprint changes and regression
  - Batch 3 — Data integrity and performance
  - Surface batches: web, Android, iOS, self-hosted
- Stack teardown

Draw the smoke test checklist from, in priority order (and name the one you used in the report):
1. The QA plan's "Smoke Test Scope" section (if a QA plan was found in Phase 1)
2. `production/qa/smoke-tests.md` (if it exists)
3. The standard fallback list in Part A below (used only when none of the above exist)

**Name the source you used in the report**, on its own line — *"Checklist source:
`production/qa/smoke-tests.md`"*, or *"Checklist source: standard fallback list —
no QA plan scope and no `production/qa/smoke-tests.md`."* The fallback is a real
fallback, so nothing is silently skipped here; what was missing is that a report
drawn from the generic list and one drawn from this product's own smoke
definitions were indistinguishable, and `/gate-check` cannot weigh a smoke
report without knowing what the checklist was drawn from.

Tailor the sprint-specific checks to the actual features identified from the
sprint or QA plan. Replace bracketed placeholders with real endpoint, screen and
feature names from the current sprint's stories.

## Part A — Critical-journey checks the skill runs

These run against the stack brought up in Phase 2, as the **seeded test tenant**
(`tools/seed/`), with `curl` against `http://localhost:<port>` or `http://127.0.0.1:<port>` only
(the grant is scoped to those hosts; a request to any other host is not made).
They are observations the
skill makes itself, so they do not go through `AskUserQuestion`. Evidence for
each is a request/response transcript (status, headers, body with tokens, OTP
codes and personal data redacted) kept in memory until Phase 6 writes it to
`production/qa/evidence/smoke-[date]/api-<check>.md`.

Endpoints come from `contracts/openapi/*.yaml` and the QA plan's smoke scope —
**do not invent a path**. A check whose endpoint the contract and plan do not
define is `NOT RUN — endpoint not defined`.

| # | Check | Pass condition |
|---|---|---|
| A1 | Stack healthy | `up -d --wait` exited 0; every service healthy; migration one-shot completed |
| A2 | Readiness | the readiness endpoint answers 200 (`/readyz` unless the contract names another) |
| A3 | Sign-in and token refresh | the seeded owner signs in; a refresh returns a new access token; the refresh token rotates |
| A4 | Primary journey of this sprint | [the endpoint(s) the sprint introduced or changed] answer with the contract's status and shape for the owner |
| A5 | Negative: anonymous | a protected endpoint returns 401 to a request without a token, with a problem-details body that leaks nothing |
| A6 | Negative: wrong role | a member-level token on an owner-only endpoint returns 403 |
| A7 | **Tenant isolation spot-check** | tenant A's token requesting a resource ID that belongs to tenant B returns 404 and the body contains no tenant-B data |
| A8 | Regression | [one endpoint of each previous sprint's critical journey touched by this sprint's changes] still answers as before |
| A9 | Billing / entitlement / licence | if the sprint touched billing or licensing: the provider-sandbox path completes and the entitlement changes once (idempotent on repeat). Needs a sandbox credential — absent → `NOT RUN — no provider sandbox` |
| A10 | Telemetry (`qa.level: full`) | one request's trace shows handler → use case → DB/cache spans in the local collector |

The standard fallback list is A1 – A3, A5 and A7 plus the sprint's primary
journey. A7 is never dropped.

**A failed A7 is an S1 (cross-tenant exposure).** Stop, tell the user
immediately in conversation — do not hold it for the end-of-run report — and
route it to `qa-lead` (and `security-lead` through `qa-lead`). Do not describe it
in any public place.

**Failure-path probe (optional, `qa.level: full`).** Stop one dependency
(`docker compose -f <file> stop <service>`), call a journey endpoint, record the
user-visible response (a cache that is down must degrade to the source, not fail),
and start it again (`start <service>`). Never `down -v`.

If Part A could not run (no Docker, no compose file, stack unhealthy), record
each check as `NOT RUN — [reason]` and say that Batch 1 in Part B then carries
the "did anything run?" question.

## Part B — Batches for the developer

Use `AskUserQuestion` to batch-verify what only a person can judge. Keep to at
most 3 calls (plus the surface batches when `--surface` was passed).

**Batch 1 — Core stability (always run):** one call, two questions — an empty
failure list means nothing unless somebody opened the current build.
```
question: "Did you open the current build (web app, device build, or the running stack) this session?"
multiSelect: false
options:
  - "Yes — I opened it and checked the items below"
  - "No — I have not opened the current build this session"

question: "Core stability — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "App shell does not load, or crashes before the sign-in screen"
  - "Sign-in fails for the seeded test user"
  - "Main navigation does not respond"
  - "Error or crash observed during basic navigation"
```

For any selected item, ask the user to briefly describe what failed before generating the report.

If the build was **not opened** and Part A did not run, the Batch 1 checks could
not be executed: record them as `NOT RUN — build not opened this session`, skip
Batches 2 and 3 and any surface batch (say so — they need a running build), and
ignore the unselected failure list. The verdict is then NOT ASSESSED unless
something else FAILED. If Part A ran and passed, A1 – A3 stand as the observed
core stability, and the answer "No" only skips the UI-facing questions (record
them `NOT RUN — UI not opened`).

**Batch 2 — Sprint changes and regression (always run):**
```
question: "Sprint changes and regression — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "[Primary feature this sprint] — FAILED"
  - "[Second notable change this sprint, if any] — FAILED"
  - "Regression in a previous sprint's feature — FAILED"
  - "Other unexpected breakage observed — FAILED"
```

For any selected item, ask the user to briefly describe what broke before generating the report.

**Batch 3 — Data integrity and performance (run unless `quick` argument):**
```
question: "Data integrity and performance — select any items that FAILED or were skipped (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Migration or existing tenant data — FAILED (data loss, corruption or a locked table observed)"
  - "Migrations — N/A (no schema change this sprint)"
  - "A hot endpoint or screen is visibly slow against its budget — FAILED"
  - "Performance not checked this session"
```

For any FAILED item selected, ask the user to describe what broke before generating the report.

Record each response verbatim for the Phase 5 report.

**Surface Batches** *(run only if `--surface` was provided)*:

**Web** (`--surface web` or `--surface all`):
```
question: "Web — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Layout broken at 1440 px or at 390 px — FAILED (describe issue after)"
  - "Arabic (RTL) mirrored layout or mixed-direction text — FAILED (describe issue after)"
  - "Keyboard-only path, visible focus or labels — FAILED (describe issue after)"
  - "Console errors, or a CSP / CORS error, on a touched screen — FAILED (describe after)"
```

**Android** (`--surface android` or `--surface all`):
```
question: "Android — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Rotation or small-screen layout — FAILED (describe what breaks after)"
  - "Background / foreground transition or process death loses state — FAILED (describe after)"
  - "Offline behaviour or error state — FAILED (describe after)"
  - "RTL layout or large font scale — FAILED (describe after)"
```

**iOS** (`--surface ios` or `--surface all`):
```
question: "iOS — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Dynamic Type large — truncation or overlap — FAILED (describe after)"
  - "Background / foreground transition loses state — FAILED (describe after)"
  - "Offline behaviour or error state — FAILED (describe after)"
  - "RTL layout — FAILED (describe after)"
```

**Self-hosted** (`--surface self-hosted` or `--surface all`):
```
question: "Self-hosted bundle — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Install from the signed bundle on a clean host — FAILED (describe after)"
  - "Upgrade from the previous supported version, or restore from backup — FAILED (describe after)"
  - "Licence activation or offline grace — FAILED (describe after)"
  - "Telemetry is not off by default, or a hosted-only engine is in the bundle — FAILED (describe after)"
```

For any selected item, ask the user to briefly describe what failed before generating the report. A surface batch whose environment is unavailable (no device, no clean host, no macOS) is recorded `NOT RUN — [reason]`, and that surface is not part of a PASS.

## Stack teardown

If this run started the stack, stop it when the checks are done:
```bash
docker compose -f deploy/compose.dev.yaml stop
```
`stop` halts the containers and keeps them and their volumes; `down` is not
granted, and **`down -v`** (it deletes volumes) is only ever something the user
asks for as a clean slate. If the user wants the containers removed, print the
command for them to run. If the stack was already running when the skill
started, leave it running.

---
