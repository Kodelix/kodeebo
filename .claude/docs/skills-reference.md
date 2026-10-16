# Skills Reference

Authoritative list of studio skills: name, origin, model tier, purpose. Skill
files must match it. Wave 4 ports skills from Claude-Code-Game-Studios 1.1.3
(source: `~/my-game/.claude/skills/<origin>/`); Wave 5 adds SaaS-native skills.

**Porting rules** (Wave 4): keep the original's mechanics that are domain-free
— phase/`references/` structure, `resolve_config` bootstrap line, verdict words,
`AskUserQuestion` gates, automation/review modes, collaborative protocol,
"a check that did not run is reported as not run". Replace everything
game-specific using the terminology map below. Every port also wires in the
eight DoD gates (`coding-standards.md`) where the skill touches implementation,
review or completion.

## Terminology map (game → SaaS)

| Game studio | SaaS studio |
|---|---|
| GDD, system GDD, `design/gdd/<system>.md` | feature spec, `design/specs/<feature>.md` (8 sections, `workflow-modes.md`) |
| game concept / game brief | `design/product-brief.md` |
| systems index | `design/specs/domain-map.md` (bounded contexts + features) |
| system | feature (spec) or bounded context (architecture) — say which |
| player, player fantasy | user / customer / tenant admin; user value |
| playtest | usability test |
| engine, `/setup-engine`, engine-reference | stack, `/setup-stack`, `docs/stack-reference/` + `pins.yaml` |
| code root (`src/`, `Assets/`, `Source/`) | code roots from `resolve_code_root` (backend/, web/, mobile/, contracts/) |
| art bible, asset specs | design system via impeccable (`PRODUCT.md`, `DESIGN.md` at repo root) |
| balance, economy | pricing, plans, entitlements, quotas |
| HUD | app shell / dashboard |
| save data, cheats | tenant data, abuse, authz bypass |
| certification, store submission (console) | Play Console / App Store review, self-hosted release channel |
| live ops | growth / lifecycle |
| Stages: Concept → Systems Design → Technical Setup → Pre-Production → Production → Polish → Release | Discovery → Product Design → Architecture → Pre-Production → Production → Hardening → Release → Live |
| Story types: Logic, Integration, Visual/Feel, UI, Config/Data | Logic, Integration, Contract, Security, Performance, UI, Config |
| Test roots per engine | per layer — `directory-structure.md` "Code roots" table |

### Agents

| Game agent | SaaS agent |
|---|---|
| creative-director | product-director |
| technical-director | cto |
| producer | producer |
| lead-programmer | principal-engineer |
| game-designer | product-manager |
| systems-designer | domain-architect |
| economy-designer | pricing-billing-designer |
| art-director, technical-artist | design-director, ui-designer |
| ux-designer, accessibility-specialist, localization-lead, release-manager, qa-lead, qa-tester, prototyper | same names |
| gameplay/engine/ai programmer, engine specialists | the stack lead for the layer (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`, `kmp-specialist`) routed by `principal-engineer` |
| network-programmer | `api-designer` + backend lead |
| ui-programmer | `web-lead` / `android-lead` / `ios-lead` |
| devops-engineer | `platform-lead`, `infra-engineer` |
| performance-analyst | `performance-engineer` |
| security-engineer | `security-lead`, `appsec-engineer` |
| analytics-engineer | `product-analytics-engineer` |
| community-manager | `customer-success` |
| live-ops-designer | `growth-lifecycle` |
| writer, narrative roles | `technical-writer` (docs), `ux-designer` (microcopy) |
| tools-programmer | `dev-tooling-engineer` |

### Director gates (`.claude/docs/director-gates/`)

| Game prefix | SaaS prefix | Owner |
|---|---|---|
| CD-* | PD-* | product-director |
| TD-* | CTO-* | cto |
| AD-* | DD-* | design-director |
| LP-* | PE-* | principal-engineer |
| PR-* | PR-* | producer |
| QL-* | QL-* | qa-lead |
| ND-* | (dropped) | — |
| — | SL-* (new) | security-lead |
| — | SRE-* (new) | sre-lead |

## Wave 4 — ported skills (67)

Model: `opus` = synthesises many documents with high-stakes output; `haiku` = read-and-format only; else `sonnet`.

### Onboarding & navigation
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/start` | start | sonnet | First-run onboarding: where are you, which flow; sets `modes.rigor`/`automation`; hands to `/studio` |
| `/help` | help | haiku | What next, from stage + artifacts + `workflow-catalog.yaml` |
| `/project-stage-detect` | project-stage-detect | haiku | Full audit: stage, gaps, next steps |
| `/adopt` | adopt | sonnet | Brownfield: audit an existing product repo's artifacts, migration plan into studio format |
| `/settings` | settings | sonnet | View/change effective config (`project.yaml`, `project.local.yaml`) |
| `/onboard` | onboard | haiku | Onboarding doc for a new engineer or agent on this product |
| `/setup-stack` | setup-engine | sonnet | Configure `stack`, `deploy`, `distribution`, `tenancy`, `layout`; verify/refresh stack reference; run `project-coherence.sh` |

### Product design
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/brainstorm` | brainstorm | sonnet | Product ideation: ICP, jobs-to-be-done, positioning, pricing model; writes the product brief |
| `/map-domains` | map-systems | sonnet | Decompose the product into bounded contexts and features; `domain-map.md`; design order |
| `/reverse-document` | reverse-document | sonnet | Adopt an existing product: reconstruct the brief, a research note, a feature spec, the architecture doc or a prototype brief from code; every claim cites file:line, unknown intent is `[UNVERIFIED — ask]` |
| `/design-spec` | design-system | sonnet | Section-by-section feature spec at the effective tier |
| `/quick-spec` | quick-design | sonnet | Lightweight spec for small changes, embedded in the story |
| `/spec-review` | design-review | sonnet | Review one spec: completeness, consistency, implementability, NFRs |
| `/review-all-specs` | review-all-gdds | opus | Cross-spec review: contradictions, permission/plan conflicts, tenancy and data-ownership clashes |
| `/propagate-spec-change` | propagate-design-change | sonnet | A spec changed → stale ADRs, stories, contracts; impact report |
| `/consistency-check` | consistency-check | sonnet | Cross-document conflicts against the domain map and entity registry |
| `/content-audit` | content-audit | sonnet | Planned vs built per spec; required vs present docs at the tier |
| `/pricing-check` | balance-check | sonnet | Plans/entitlements/quotas sanity: loopholes, margin, unreachable tiers, abuse paths |

### UX
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/ux-design` | ux-design | sonnet | UX spec for a screen/flow/app shell in `design/ux/`, feeding impeccable |
| `/ux-review` | ux-review | sonnet | Validate a UX spec: accessibility target, RTL, states, spec alignment |
| `/usability-report` | playtest-report | sonnet | Structure usability-test notes into findings and actions |

### Architecture
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/create-architecture` | create-architecture | sonnet | Architecture doc: contexts, ports, data stores, tenancy, deployment (hosted + self-hosted), against the stack reference |
| `/architecture-decision` | architecture-decision | sonnet | Write an ADR |
| `/architecture-review` | architecture-review | opus | Traceability spec requirements → ADRs; gaps, conflicts, stack-version risks |
| `/create-control-manifest` | create-control-manifest | sonnet | Flat must/never rules per context and layer from accepted ADRs |

### Planning
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/create-epics` | create-epics | sonnet | Epics per context/module from specs + architecture |
| `/create-stories` | create-stories | sonnet | Stories with TR-IDs, ADR guidance, acceptance criteria, DoD evidence per story type |
| `/estimate` | estimate | sonnet | Effort estimate with confidence |
| `/sprint-plan` | sprint-plan | sonnet | Sprint plan from milestone, done work, capacity |
| `/sprint-status` | sprint-status | haiku | Sprint snapshot |
| `/scope-check` | scope-check | haiku | Scope creep vs plan |
| `/milestone-review` | milestone-review | sonnet | Milestone go/no-go |
| `/retrospective` | retrospective | sonnet | Sprint/milestone retro |

### Implementation
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/story-readiness` | story-readiness | sonnet | READY/NEEDS WORK: criteria, research note present, ADRs, threat model when required |
| `/dev-story` | dev-story | sonnet | Implement a story via the stack lead; research gate; tests; DoD evidence plan |
| `/code-review` | code-review | sonnet | Review against the eight DoD gates and stack rules |
| `/story-done` | story-done | sonnet | Close a story: criteria, eight gates with evidence, run-and-observe, deviations |
| `/tech-debt` | tech-debt | sonnet | Debt register and prioritisation |
| `/prototype` | prototype | sonnet | Throwaway spike in `prototypes/`; PROCEED/PIVOT/KILL |
| `/vertical-slice` | vertical-slice | sonnet | Thin end-to-end slice (DB → API → web/mobile → deploy) proving the architecture |

### QA
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/qa-plan` | qa-plan | sonnet | Sprint QA plan by story type |
| `/smoke-check` | smoke-check | sonnet | Critical-path smoke gate on a running stack |
| `/regression-suite` | regression-suite | sonnet | Coverage vs critical journeys; fixed bugs without regression tests |
| `/test-setup` | test-setup | sonnet | Scaffold test frameworks + CI per layer (Testcontainers, Vitest/Playwright, Compose UI, XCTest) |
| `/test-helpers` | test-helpers | sonnet | Factories, fakes, Testcontainers fixtures per layer |
| `/test-evidence-review` | test-evidence-review | sonnet | Quality of tests/evidence, not just presence |
| `/test-flakiness` | test-flakiness | sonnet | Flaky tests from CI history; quarantine |
| `/load-test` | soak-test | sonnet | k6 load/soak protocol against budgets |
| `/bug-report` | bug-report | sonnet | Structured bug report |
| `/bug-triage` | bug-triage | sonnet | Re-prioritise open bugs |

### Security & performance
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/security-audit` | security-audit | sonnet | ASVS/MASVS/API Top 10 audit: authz, tenancy, injection, secrets, supply chain |
| `/perf-profile` | perf-profile | sonnet | Profile vs budgets; ranked fixes; creates `perf-budgets.md` if missing |

### Release
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/release-checklist` | release-checklist | sonnet | Per-release checklist: hosted deploy, self-hosted bundle, mobile stores |
| `/launch-checklist` | launch-checklist | sonnet | First-launch readiness across every function (legal, privacy, billing, support, status page) |
| `/changelog` | changelog | sonnet | Changelog from commits + stories (internal and customer-facing) |
| `/release-notes` | patch-notes | sonnet | Customer-facing release notes |
| `/hotfix` | hotfix | sonnet | Emergency fix path with audit trail and backport |
| `/post-release-fix` | day-one-patch | sonnet | Focused fix mini-sprint after a release |
| `/localize` | localize | sonnet | Hardcoded strings, extraction, AR/EN, RTL checks |

### Teams (ported orchestrations)
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/team-qa` | team-qa | sonnet | qa-lead → qa-tester + test-automation-engineer full test cycle |
| `/team-release` | team-release | sonnet | release-manager, qa-lead, platform-lead, producer, customer-success |
| `/team-ui` | team-ui | sonnet | design-director → ux/ui designers (impeccable) → stack lead → accessibility review |
| `/team-hardening` | team-polish | sonnet | performance-engineer, appsec-engineer, accessibility-specialist, qa-tester pass before release |
| `/team-growth` | team-live-ops | sonnet | growth-lifecycle, pricing-billing-designer, product-analytics-engineer, customer-success |

### Gates & meta
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/gate-check` | gate-check | opus | Phase gate: PASS/CONCERNS/NOT ASSESSED/FAIL |
| `/skill-test` | skill-test | sonnet | Validate skill files (static + behavioural) |
| `/skill-improve` | skill-improve | sonnet | Test-fix-retest loop for a skill |

**Dropped:** `art-bible`, `asset-spec`, `asset-audit` (→ impeccable + `/dependency-audit`), `team-audio`, `team-combat`, `team-level`, `team-narrative` (→ Wave 5 teams).

## Wave 5 — new SaaS skills (41)

No source to port: authored from the standards. Structure and machinery follow
the ported skills (`skill-authoring-brief.md`).

### Orchestration & engineering
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/studio` | new | opus | Single entry point: classify a goal, run the matching flow across skills and agents with approval gates |
| `/research` | new | sonnet | DoD gate 1: research note from primary sources (`research-protocol.md`) |
| `/threat-model` | new | opus | STRIDE + abuse cases per trust boundary; mitigations linked to stories/tests (SL-THREAT-MODEL) |
| `/api-contract` | new | sonnet | Contract-first OpenAPI change, lint, breaking-change diff, client generation |
| `/db-migration` | new | sonnet | Expand→migrate→contract migration with migration-lint, backfill plan, rollback, self-hosted upgrade path |
| `/cache-design` | new | sonnet | Cache decision record per `caching-standard.md`, portable across Redis/Valkey/Dragonfly |
| `/observability-plan` | new | sonnet | Instrumentation plan, SLOs, burn-rate alerts, runbooks |
| `/integration` | new | sonnet | External provider integration: research, integration spec, adapter behind a port, webhooks, tests |
| `/tenant-check` | new | sonnet | Tenant-isolation audit: RLS, scoping, cache keys, storage prefixes, negative tests (SL-TENANT-ISOLATION) |
| `/dependency-audit` | new | sonnet | CVEs (govulncheck, OSV-Scanner), deprecated APIs, licences, stack-reference freshness, project-coherence |
| `/incident` | new | sonnet | Incident command: triage, mitigate, communicate, timeline |
| `/postmortem` | new | sonnet | Blameless postmortem with actions owned and dated |
| `/license-design` | new | opus | Self-hosted licence model: signed licences, activation, grace, revocation, update eligibility |
| `/core-use` | new | sonnet | Adopt a `saas-core-<track>` module in a product |
| `/core-extract` | new | sonnet | Promote a product capability into the core (upstream proposal + ADR) |
| `/core-upgrade` | new | sonnet | Bump the product's core pin: changelog, breaking changes, migration |
| `/core-release` | new | sonnet | Release a core module: semver, changelog, conformance tests, deprecation policy |

### Teams
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/team-feature` | new | sonnet | End-to-end feature: research → spec → contract → backend/web/mobile → QA → done |
| `/team-api` | new | sonnet | Contract change across api-designer, backend lead, client leads |
| `/team-data` | new | sonnet | Schema/data change across data-lead, migration, cache, messaging specialists |
| `/team-security` | new | sonnet | Threat model → audit → pentest → fixes → sign-off |
| `/team-perf` | new | sonnet | Budgets → profile → load test → fixes → verification |
| `/team-integration` | new | sonnet | Provider integration across integrations-engineer, security, QA |
| `/team-billing` | new | sonnet | Pricing → entitlements → billing integration → licence enforcement |
| `/team-mobile` | new | sonnet | KMP shared + Android + iOS delivery of a feature |

### Quality
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/test` | new | sonnet | Run the relevant suites across layers for a change; real output |
| `/debug` | new | sonnet | Systematic diagnosis → proven root cause → fix via owner → regression test |
| `/automate-test` | new | sonnet | Turn manual cases and fixed bugs into automated tests |
| `/manual-test` | new | sonnet | Exploratory/manual session with charter and retained evidence |
| `/pentest` | new | sonnet | Authorised penetration test of our own product under written scope |
| `/uat` | new | sonnet | UAT plan, business-user sessions, sign-off |

### Business (`business-research-protocol.md`; Egypt, GCC/MENA)
| Skill | Origin | Model | Purpose |
|---|---|---|---|
| `/business` | new | opus | Business entry point: route the question to the business team, one sourced answer |
| `/market-research` | new | sonnet | Bottom-up market sizing and buyer research with sourced numbers |
| `/competitor-analysis` | new | sonnet | Competitor files with dated price captures and comparison matrix |
| `/pricing-strategy` | new | sonnet | Value metric, packaging, regional prices, licence economics, price tests |
| `/offer-design` | new | sonnet | Launch deals, discounts, bundles, trials with guardrails and expected impact |
| `/brand-architecture` | new | sonnet | Brand architecture decision, name criteria and candidate screening (trademark screening record, brief for counsel), per-vertical theme handoff |
| `/gtm-plan` | new | sonnet | Go-to-market: segment, positioning, channels, launch sequence, targets |
| `/marketing-plan` | new | sonnet | Channels, content, budget, CAC targets, measurement |
| `/sales-playbook` | new | sonnet | Sales motion, qualification, pipeline, enterprise terms, objections |
| `/business-case` | new | sonnet | Unit economics and financial model (CAC, LTV, churn, payback, margin) |
| `/team-business` | new | sonnet | Business team end to end for a decision (research → pricing → GTM → sales) |
