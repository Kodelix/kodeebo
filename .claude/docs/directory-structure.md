# Directory Structure

Two kinds of repository use this studio: a **product** repo (one SaaS product)
and the **core** repo (`saas-core`, shared capabilities every product consumes).
Both carry the same `.claude/` tree.

## Product repository

**Create one with the studio, never by hand:** `bash tools/new-product.sh <name>`
(in `~/saas-studio`) creates `~/saas-products/<name>` with the studio-owned files
(`.claude/`, `CLAUDE.md`, `.gitignore`, `docs/stack-reference/`), a template
`project.yaml`, and `.claude/STUDIO_VERSION` (the studio commit it came from).
Open it with `claude` from inside the folder and accept the trust dialog —
until then Claude Code ignores the project's `permissions.allow` rules.
**Take studio improvements later** with `bash tools/update-product.sh <dir>`
(dry run) then `--apply`: a three-way update that never overwrites a studio
file the product edited, and never reads or writes product-owned files.

```text
/
├── CLAUDE.md                    # Master configuration
├── project.yaml                 # Stack profile, modes, stage, core pin (source of truth)
├── .claude/                     # Agents, skills, hooks, rules, docs
├── backend/                     # API + workers (Go or Ktor) — see code roots below
├── web/                         # Product app: Vite + React SPA, built to static files
├── site/                        # Marketing site: Astro, static output (optional)
├── mobile/
│   ├── shared/                  # KMP shared module (when stack.mobile includes kmp)
│   ├── android/                 # Android app (Jetpack Compose)
│   └── ios/                     # iOS app (SwiftUI)
├── desktop/                     # Desktop client (when stack.desktop is set) — runtime, layout and owner per its ADR
├── contracts/                   # OpenAPI / protobuf — the single source of truth between clients and backend
├── deploy/
│   ├── hosted/                  # our infrastructure (compose, proxy, backups)
│   └── self-hosted/             # customer bundle + installer — licence rules in .claude/rules/deploy.md
├── design/
│   ├── product-brief.md         # What the product is, for whom, pricing model
│   ├── specs/                   # Feature specs (one per feature) + domain-map.md
│   ├── quick-specs/             # Lightweight specs for small changes (/quick-spec)
│   ├── registry/                # entities.yaml — plans, roles, permissions, quotas, events (/consistency-check)
│   ├── ux/                      # UX specs (impeccable's PRODUCT.md and DESIGN.md live at the repo root)
│   ├── growth/                  # Activation metrics, lifecycle journeys, experiments/<id>.md
│   └── localization/            # Locale list, glossary, key-naming and translation workflow
├── docs/
│   ├── architecture/            # ADRs, architecture doc, perf-budgets.md, slos.md
│   │   ├── threat-models/       # /threat-model
│   │   ├── migration-plans/     # /db-migration (template: templates/migration-plan.md)
│   │   ├── erd/                 # one Mermaid ERD per bounded context, updated by every /db-migration
│   │   ├── cache-designs/       # /cache-design
│   │   └── observability-plans/ # /observability-plan
│   ├── registry/                # architecture.yaml — architectural stances registry (/create-architecture, /architecture-review)
│   ├── research/                # Research notes — written BEFORE implementation
│   ├── stack-reference/         # Version-pinned stack references (per layer)
│   ├── runbooks/                # Operational runbooks, incident procedures
│   └── analytics/               # Event taxonomy and tracking plan (product-analytics-engineer)
├── business/                    # Business team outputs (business-research-protocol.md)
│   ├── market/                  # Market sizing, buyer research, macro data — sourced and dated
│   ├── competitors/             # One file per competitor + comparison matrix (verified captures)
│   │   └── notes/               # /business notes on competitor questions — dated, NOT verified captures; ignored by /competitor-analysis, /pricing-strategy, /gtm-plan
│   ├── pricing/                 # Pricing strategy, offers, price tests
│   ├── marketing/               # GTM and marketing plans, campaign results
│   ├── sales/                   # Sales playbook, proposals, deal terms
│   ├── brand/                   # Brand architecture, naming screens, counsel briefs (/brand-architecture)
│   └── cases/                   # Business cases and unit-economics models
├── tools/
│   ├── seed/                    # Seed / fixture data generators (/test-helpers, /test-setup)
│   ├── load/                    # Load-test scripts (/load-test)
│   ├── codegen/                 # Contract → client/server code generation
│   └── ci/                      # CI helpers
├── prototypes/                  # Throwaway spikes (outside every code root)
└── production/                  # Epics, stories, sprints, releases
    ├── epics/<epic>/            # EPIC.md + story-NNN-<slug>.md (/create-epics, /create-stories)
    ├── sprints/                 # sprint-NN.md (/sprint-plan, /sprint-status)
    ├── milestones/              # Milestone definitions and reviews (/milestone-review)
    ├── releases/                # Release checklists, notes, go/no-go records (/release-checklist, /team-release)
    ├── hotfixes/                # /hotfix records
    ├── gate-checks/             # /gate-check reports per stage boundary
    ├── retrospectives/          # /retrospective outputs
    ├── risk-register/           # Open risks and accepted-risk records
    ├── hardening/               # /team-hardening working files
    ├── core/proposals/          # /core-extract proposals before they go upstream
    ├── business/<slug>/         # Working drafts of /team-business (deliverables go to business/)
    ├── billing/<slug>/          # Working drafts of /team-billing
    ├── mobile/<slug>/           # Working drafts of /team-mobile
    ├── incidents/               # incident-<date>-<slug>.md, postmortem-<date>-<slug>.md (/incident, /postmortem)
    ├── qa/bugs/                 # BUG-NNNN.md (/bug-report, /bug-triage)
    ├── qa/cases/                # Test cases per story (qa-tester)
    ├── qa/evidence/             # Run-and-observe and test evidence per story
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)

Other `production/<area>/` folders (`api/`, `data/`, `features/`, `growth/`,
`localization/`, `security/`, `ui/`) hold working drafts of the team skill of
the same name; finished artifacts move to `design/` or `docs/`.
```

## Code roots

A product has **several** code roots. Hooks and skills that scan, count or
write source iterate all of them. They resolve through `resolve_code_root` in
`.claude/hooks/yaml-helper.sh`: `layout.code_roots` in `project.yaml` first,
then detection of the conventional directories that exist on disk.

**An empty result means the check did not run** — say so; never report it as clean.

| Layer | Code root | Source layout | Test location |
|---|---|---|---|
| Go backend | `backend/` | `cmd/<binary>/`, `internal/<context>/{domain,app,adapters}/` | `*_test.go` beside the code; integration tests behind the `integration` build tag |
| Ktor backend | `backend/` | `src/main/kotlin/<pkg>/<context>/{domain,app,adapters}/` | `src/test/kotlin/` (unit), `src/integrationTest/kotlin/` (Testcontainers) |
| Web app | `web/` | `src/features/<feature>/`, `src/shared/` | `*.test.ts(x)` beside the code; Playwright in `web/e2e/` |
| Marketing site | `site/` | Astro `src/pages/`, `src/components/` | Playwright smoke in `site/e2e/` |
| KMP shared | `mobile/shared/` | `src/commonMain/kotlin/`, `src/androidMain/`, `src/iosMain/` | `src/commonTest/kotlin/` |
| Android | `mobile/android/` | `app/src/main/kotlin/` | `app/src/test/` (unit), `app/src/androidTest/` (instrumented) |
| iOS | `mobile/ios/` | Xcode targets / Swift packages | Swift Testing / XCTest targets |
| Desktop client | `desktop/` | per the desktop ADR (`stack.desktop`) | per the desktop ADR |
| Contracts | `contracts/` | `openapi/*.yaml`, `proto/**/*.proto` | Contract tests run from each consumer |

The `{domain,app,adapters}` split is the clean-architecture rule
(`.claude/docs/clean-architecture.md`): dependencies point inward only.

## Core repositories (one per backend track)

There is a core per backend track — `saas-core-go` and `saas-core-kotlin` —
and a product uses the core of its track (`core.track` in `project.yaml`).
The cores are built **after** the studio is complete, using the studio.
Intended shape, finalised by ADR when they are built:

```text
saas-core-<track>/
├── <module>/                    # port interfaces + adapters + conformance tests per module
│                                # (identity, observability, otp, notify, storage, billing,
│                                #  licensing, tenancy, audit, ratelimit, ...)
├── clients/                     # client SDK pieces: KMP, Swift, web (TypeScript)
├── contracts/                   # OpenAPI/proto for anything exposed over the network
└── docs/                        # module ADRs, CHANGELOG per module, deprecation policy
```

Products pin a released core version in `project.yaml` (`core.version`) and
never edit core code in place. A fix or extension goes upstream into the core
repo and is released, then the product bumps its pin.
