# Agent Roster

68 studio agents + 4 vendored impeccable agents. This file is the single
source for names, tiers, models, tools and reporting lines; agent files must
match it. Template: `.claude/docs/agent-template.md`.

**Model column:** `opus` = pinned (directors); `inherit` = session model
(everyone who designs or writes production code — the senior bar needs the
strongest model available); `sonnet` = pinned for well-bounded specialist or
support work. See `model-tiers.md`.

**Tools shorthand:** `impl` = Read, Glob, Grep, Write, Edit, Bash ·
`design` = Read, Glob, Grep, Write, Edit, WebSearch, WebFetch ·
`research` = Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Bash ·
`review` = Read, Glob, Grep, Bash (read-only reviewers that write only reports via Write).
`Agent(...)` lists the subagents an agent is **intended** to spawn. Claude Code
enforces that type allowlist only when the agent runs as the main thread
(`claude --agent <name>`); inside a subagent, `Agent` permits spawning up to
`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (default 3, set to `"3"` in
`settings.json`) and ignores the parenthesised types. The lists below are the
delegation graph and are advisory when running as a subagent — agents follow
them anyway (`coordination-rules.md`).

## Tier 0 — Orchestrator

| Agent | Model | Tools | Purpose |
|---|---|---|---|
| `studio-orchestrator` | inherit | impl + WebSearch + Skill + AskUserQuestion + Agent(product-director, cto, producer, principal-engineer, product-manager, domain-architect, pricing-billing-designer, design-director, qa-lead, security-lead, platform-lead, sre-lead, release-manager, researcher, business-director, customer-success, integrations-engineer, licensing-specialist, auth-identity-specialist, uat-coordinator, debugger, qa-tester) | Main-thread agent (`claude --agent studio-orchestrator`). Runs the `/studio` flow from `.claude/skills/studio/references/` (tier-aware), stopping at approval gates. |

## Tier 1 — Directors

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `product-director` | opus | design | user | Product vision, positioning, plan/pricing strategy sign-off, scope arbitration; escalation point for product conflicts. |
| `cto` | opus | design + Bash | user | Architecture, technology choices, technical risk, ADR sign-off; escalation point for technical conflicts. |
| `producer` | opus | design + Bash | user | Roadmap, milestones, sprints, risk register, cross-team coordination, change propagation. |

## Tier 2 — Leads

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `principal-engineer` | inherit | impl + Agent(go-lead, ktor-lead, web-lead, android-lead, ios-lead, kmp-specialist, data-lead, api-designer, debugger) | cto | Code-level architecture, clean architecture enforcement, code review, standards, refactoring strategy, routes implementation to stack leads. |
| `product-manager` | inherit | design | product-director | Feature specs, acceptance criteria, prioritisation, scope per release. |
| `domain-architect` | inherit | design | cto | DDD: bounded contexts, domain map, aggregates, invariants, context integration. |
| `pricing-billing-designer` | inherit | design | product-director | Plans, entitlements, metering, subscriptions vs one-time licences, trials, coupons, tax/VAT, dunning rules. |
| `design-director` | inherit | design + Bash + Agent(ui-designer, ux-designer) | product-director | Visual identity, design system, owner of the impeccable workflow and `PRODUCT.md` (project root — impeccable's location). |
| `qa-lead` | inherit | impl + Agent(qa-tester, test-automation-engineer, uat-coordinator) | producer | Test strategy, test plans, release quality gates, bug severity. |
| `security-lead` | inherit | impl + WebSearch + WebFetch + Agent(appsec-engineer, privacy-compliance-specialist) | cto | Security baseline, threat models, ASVS/MASVS mapping, security sign-off. |
| `platform-lead` | inherit | impl + Agent(infra-engineer, dev-tooling-engineer) | cto | CI/CD, environments, build/release pipeline, developer platform. |
| `sre-lead` | inherit | impl + Agent(observability-engineer, performance-engineer) | cto | SLOs, alerting, incident response, capacity, reliability reviews. |
| `release-manager` | sonnet | impl | producer | Versioning, release checklists, store submissions (Play/App Store), self-hosted release channel, changelog. |

## Backend

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `go-lead` | inherit | impl + Agent(go-concurrency-specialist, go-api-specialist) | principal-engineer | Authority on Go backends: layout, idioms, stdlib-first, pgx, testing. |
| `go-concurrency-specialist` | sonnet | impl | go-lead | Goroutines, channels, errgroup, worker pools, cancellation, race-freedom, profiling. |
| `go-api-specialist` | sonnet | impl | go-lead | net/http routing and middleware, request validation, RFC 9457 mapping, gRPC when chosen. |
| `ktor-lead` | inherit | impl + Agent(kotlin-coroutines-specialist, kotlin-persistence-specialist) | principal-engineer | Authority on Ktor backends: plugins, DI, serialization, testing. |
| `kotlin-coroutines-specialist` | sonnet | impl | ktor-lead | Structured concurrency, dispatchers, cancellation, Flow, blocking-I/O isolation. |
| `kotlin-persistence-specialist` | sonnet | impl | ktor-lead | Exposed/jOOQ, HikariCP, transactions, mapping, query performance on the JVM. |
| `api-designer` | inherit | design + Bash | principal-engineer | OpenAPI contracts, versioning, pagination, errors, idempotency, client generation. |
| `auth-identity-specialist` | inherit | impl + WebSearch | security-lead | Authentication, sessions/tokens, MFA/passkeys, OIDC/SAML SSO, RBAC/ABAC. |
| `multitenancy-specialist` | inherit | impl | domain-architect | Tenant model, isolation (RLS/schema/db), tenant context propagation, noisy-neighbour controls. |

## Data

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `data-lead` | inherit | impl + Agent(postgres-specialist, mongo-specialist, cache-specialist, messaging-specialist, migration-specialist) | principal-engineer | Data store choices per context, data modelling review, consistency and retention. |
| `postgres-specialist` | sonnet | impl | data-lead | Schema, indexes, query plans, RLS, partitioning, backups/PITR. |
| `mongo-specialist` | sonnet | impl | data-lead | Document modelling, validation, indexes, aggregation, write concerns. |
| `cache-specialist` | sonnet | impl | data-lead | Redis/Valkey/Dragonfly patterns, key design, TTL, stampede, rate limiting, portability. |
| `messaging-specialist` | sonnet | impl | data-lead | Outbox, queues/streams, delivery semantics, retries, DLQ, idempotent consumers. |
| `migration-specialist` | sonnet | impl | data-lead | Expand→migrate→contract, backfills, zero-downtime and multi-version self-hosted upgrades. |

## Web

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `web-lead` | inherit | impl + Agent(react-specialist, astro-specialist) | principal-engineer | Authority on the static SPA and marketing site: architecture, security headers, performance budgets. |
| `react-specialist` | sonnet | impl | web-lead | React + Vite + TanStack Router/Query, TypeScript strictness, component architecture, testing. |
| `astro-specialist` | sonnet | impl | web-lead | Astro static site, islands, content collections, SEO, i18n routing. |

## Mobile

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `android-lead` | inherit | impl + Agent(compose-ui-specialist, android-platform-specialist) | principal-engineer | Authority on Android: architecture, Compose, Play requirements, performance. |
| `compose-ui-specialist` | sonnet | impl | android-lead | Compose UI, state, stability/recomposition, theming, accessibility. |
| `android-platform-specialist` | sonnet | impl | android-lead | WorkManager, notifications/FCM, permissions, Keystore, Credential Manager, baseline profiles, R8. |
| `kmp-specialist` | inherit | impl | principal-engineer | Kotlin Multiplatform shared module: domain, Ktor client, persistence, Swift interop. |
| `ios-lead` | inherit | impl + Agent(swiftui-specialist, swift-concurrency-specialist) | principal-engineer | Authority on iOS: architecture, SwiftUI, App Store requirements, performance. |
| `swiftui-specialist` | sonnet | impl | ios-lead | SwiftUI views, navigation, Observation, accessibility, Dynamic Type. |
| `swift-concurrency-specialist` | sonnet | impl | ios-lead | Swift 6 strict concurrency, actors, Sendable, tasks, isolation. |
| `offline-sync-specialist` | sonnet | impl | kmp-specialist | Offline-first storage, sync protocols, conflict resolution, retry/backoff on mobile. |

## Cross-cutting engineering

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `researcher` | sonnet | research | studio-orchestrator / any lead | DoD gate 1: research notes from primary sources before implementation. |
| `integrations-engineer` | inherit | impl + WebSearch | principal-engineer | Payments, SMS/OTP, email, storage, push, OAuth providers, webhooks — as adapters behind ports. |
| `observability-engineer` | sonnet | impl | sre-lead | OTel instrumentation, dashboards, alerts, log pipelines, SLO burn-rate rules. |
| `performance-engineer` | inherit | impl | sre-lead | Profiling, load tests (k6), budgets, query and allocation optimisation. |
| `infra-engineer` | sonnet | impl | platform-lead | Docker Compose (hosted + self-hosted bundle), reverse proxy, backups, installer. |
| `appsec-engineer` | inherit | impl + WebSearch + WebFetch | security-lead | Secure code review, SAST/dependency scans, negative tests, vulnerability triage. |
| `privacy-compliance-specialist` | sonnet | design | security-lead | Egypt PDPL / GDPR, data inventory, retention, DSAR/export/delete, consent. |
| `licensing-specialist` | inherit | impl | security-lead | Signed licences (Ed25519), activation, offline grace, entitlement enforcement, self-hosted update channel. |
| `test-automation-engineer` | sonnet | impl | qa-lead | Testcontainers suites, contract tests, Playwright/Compose UI/XCUITest, CI test infrastructure. |
| `qa-tester` | sonnet | impl | qa-lead | Test cases, exploratory sessions, bug reports, regression checklists, evidence capture. |
| `product-analytics-engineer` | sonnet | impl | product-manager | Event taxonomy, privacy-safe tracking, funnels, experiment instrumentation. |
| `dev-tooling-engineer` | sonnet | impl | platform-lead | Codegen, local dev scripts, seed data, CI helpers, studio scripts. |
| `prototyper` | sonnet | impl | product-manager | Throwaway spikes in `prototypes/` to answer one question fast. |

## Quality — debugging, penetration testing, UAT

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `debugger` | inherit | impl | principal-engineer | Systematic diagnosis: reproduce, hypotheses ranked by evidence (traces, logs, metrics, bisect), root cause proven before any fix, regression test that fails before and passes after. |
| `penetration-tester` | sonnet | impl + WebSearch + WebFetch | security-lead | Authorised penetration testing of **the company's own products only**, on staging or an approved window, under written scope and rules of engagement; OWASP WSTG/MASTG/API Top 10; findings with CVSS, reproduction and retest. |
| `uat-coordinator` | sonnet | impl | qa-lead | User acceptance testing: business-language scenarios from acceptance criteria, UAT environment and data, session facilitation, defect intake, sign-off record. |

## Business — market, pricing, marketing, sales

Business agents answer with **sourced market numbers** under `.claude/docs/business-research-protocol.md`; markets in scope: Egypt, GCC/MENA. They advise on business; they do not edit product code.

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `business-director` | opus | research + Agent(market-researcher, pricing-strategist, marketing-lead, sales-lead) | user | Business entry point: strategy, positioning, business model, unit economics, go-to-market decisions; routes questions to the business team and consolidates one sourced answer. |
| `market-researcher` | inherit | research | business-director | Market sizing (TAM/SAM/SOM bottom-up), competitor landscape and published prices, buyer behaviour, channels, macro data for Egypt and GCC/MENA — every number sourced and dated. |
| `pricing-strategist` | inherit | research | business-director | Price levels, packaging, currency/region pricing (EGP, SAR, AED, USD), discounts and offers, subscription vs one-time vs self-hosted licence economics; hands the decided model to `pricing-billing-designer`. |
| `marketing-lead` | inherit | research | business-director | Positioning, messaging, channels (SEO, content, paid, partnerships, communities), launch plans, budgets and CAC targets, campaign measurement. |
| `sales-lead` | inherit | research | business-director | Sales motion (self-serve, inside sales, enterprise), ICP qualification, pipeline stages, enterprise deal terms, resellers/partners, objection handling, proposals. |

## Product, design and customer

| Agent | Model | Tools | Reports to | Purpose |
|---|---|---|---|---|
| `ux-designer` | inherit | design | design-director | Flows, information architecture, interaction patterns, onboarding, empty/error states. |
| `ui-designer` | inherit | design + Bash | design-director | Screens through impeccable (`craft`, `audit`, `polish`), design tokens, component specs. |
| `accessibility-specialist` | sonnet | impl | design-director | WCAG target, screen readers (web/TalkBack/VoiceOver), keyboard, contrast, motion. |
| `localization-lead` | sonnet | impl | product-manager | i18n architecture, Arabic/English, RTL, pluralisation, formatting, translation workflow. |
| `technical-writer` | sonnet | design | product-manager | API docs, user docs, self-hosted install/upgrade guides, runbook editing. |
| `customer-success` | sonnet | design | product-manager | Release notes, support triage, customer comms, feedback synthesis. |
| `growth-lifecycle` | sonnet | design | product-manager | Activation, onboarding experiments, retention, churn and dunning journeys. |

## Vendored (impeccable, Apache-2.0 — do not edit)

`impeccable-asset-producer`, `impeccable-documenter`, `impeccable-finish-reviewer`,
`impeccable-manual-edit-applier`. Invoked by the impeccable skill; `ui-designer`
and `design-director` drive them through `/impeccable`.

## Escalation

Product conflict → `product-director`. Business/market conflict → `business-director`, then the user. Technical conflict → `cto`. Schedule or
cross-team conflict → `producer`. Security disagreement → `security-lead`, then `cto`.
