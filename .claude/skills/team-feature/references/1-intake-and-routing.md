# /team-feature — Phase 1: Intake, Routing and the Plan

> Part of `/team-feature`. Read again if the conversation was compacted.

## 1. Resolve the feature

- `resume [slug]`: read the `Flow:` line of the CHECKPOINT block and the
  "Feature pipeline — <slug>" block of
  `production/session-state/active.md` (or a "Studio flow" block whose `Flow:` names
  this feature, when `/studio` drove the run) and `production/features/<slug>/`;
  restate flow, step, open gate, blockers; continue at that step. No block and no
  directory → say so and start fresh.
- Otherwise restate the feature in one sentence in the user's language and derive
  `<feature-slug>` (kebab-case; the spec filename stem, since it keys
  `system_overrides` — `workflow-modes.md`). If a spec `design/specs/<slug>.md`
  exists, use its stem.
- Resolve the feature's workflow tier: `system_overrides.<slug>` if the block
  lists it, else `workflow`.

## 2. Inventory — FOUND or ABSENT, every row

| Artifact | Path |
|---|---|
| Product brief | `design/product-brief.md` |
| Domain map; the bounded context this feature lives in | `design/specs/domain-map.md` |
| Spec / quick-spec | `design/specs/<slug>.md`, `design/quick-specs/<slug>.md` |
| Research note | `docs/research/<slug>.md` |
| Threat model | `docs/architecture/threat-models/<slug>.md` |
| UX spec; `PRODUCT.md`, `DESIGN.md` at the repo root | `design/ux/<slug>.md` |
| Contract | `contracts/openapi/*.yaml` |
| Migration plan | `docs/architecture/migration-plans/<slug>.md` |
| Cache decision | the `/cache-design` record path |
| ADRs on this area | `docs/architecture/adr-*.md` |
| Epic and stories | `production/epics/<context>/` |
| Registry | `design/registry/entities.yaml` (plans, roles, permissions, quotas) |
| Previous run | `production/features/<slug>/`, the "Feature pipeline — <slug>" (or "Studio flow") block of `active.md` |

An existing artifact is reused (never overwritten silently); an ABSENT one is
produced by its phase or its absence is justified in the plan.

## 3. Core-first check

Shared capabilities come from `saas-core-<track>`
(`coding-standards.md`). Read `project.yaml` `core.*` and the feature's needs:

- need maps to a module already in `core.modules` → use it; the feature's spec
  lists it under Dependencies;
- need maps to a core module **not yet adopted** → `/core-use <module>` is a
  step of this plan (before the backend lane);
- need is a reusable capability the core lacks (identity, OTP, notify, storage,
  billing, licensing, tenancy, audit, ratelimit...) → do **not** build it
  product-locally: `/core-extract` is a step, the feature's dependent stories wait
  on the core release as a recorded risk (`producer.md`) — the user decides
  between waiting and a written, temporary product-local implementation;
- provider integration (payments, SMS/OTP, email, storage, push, OAuth) → the
  feature is an `/integration` (or `/team-integration`) flow: say so and offer to
  switch rather than duplicating it here.

## 4. Routing note (principal-engineer)

Spawn `principal-engineer` via `Agent` (it routes work to leads — never route
around it). Brief with the slug, the sentence, the inventory table, the resolved
`stack` line, `core.*` and the core-first findings. It writes
`production/features/<slug>/routing.md` and returns the standard contract. The
note must contain, with file paths:

1. **Bounded context** and whether it is new (→ `domain-architect` at Phase 3).
2. **Layers and lanes** with the lead for each, in the `/dev-story` lane order
   (Contract → Data → Backend → Clients → Deploy); `unset` layers marked STOP.
3. **Triggers fired** — one row per backbone step (the table below) with the
   evidence from the sentence/spec (the trigger words), or "not fired".
4. **Architectural choices likely needed** (each → an ADR) and the pattern risks.
5. **Core-vs-product boundary** findings.
6. **Gate hot spots** among the eight DoD gates (cache decision needed? perf
   budget row? tenant isolation? observability for a new job?).
7. **Open questions** with owners.

## 5. The trigger table → the plan

Build this table from the routing note; it is shown to the user and is the
"skipped step is named" record. `Runs?` is `yes`, or `skipped — <reason>` using
the exact reason shown.

| # | Step | Runs when (trigger) | Skipped reason if not | Owner |
|---|---|---|---|---|
| 1 | `/research` → `docs/research/<slug>.md` | always, except the research-protocol exemptions: a bug fix inside already-researched code (cite the note); copy, styling or a config value change | `research-protocol exemption: <row>` | `researcher` |
| 2 | `/design-spec`, or `/quick-spec` for a small, non-sensitive change | `workflow` standard/full; `/quick-spec` when the change is small and touches no security trigger | `workflow: minimal — brief + research note are the record` | `product-manager` |
| 3 | `/threat-model` | the feature touches authentication, the authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, or a new external integration (`security-baseline.md`) | `no security-baseline trigger fired` | `security-lead` |
| 4 | `/ux-design` (+ `/team-ui` in Phase 7) | screens change; needs `PRODUCT.md` (else `/impeccable init`) | `no screen changes` | `ux-designer` |
| 5 | `/api-contract` (or `/team-api` when breaking or ≥2 client layers) | an endpoint, event or webhook changes | `no contract change` | `api-designer` |
| 6 | `/db-migration` (user-run) or `/team-data` (≥2 of schema / cache / messaging, or a tenant-owned table); `/cache-design` | schema changes, or a hot read path is added | `no schema change`, `no hot read path (written cache decision: none needed)` | `data-lead` |
| 7 | Architecture: `/architecture-decision` per choice | any architectural choice (new store, boundary, pattern, core-vs-product call, DI/library decision) | `no architectural choice` | `principal-engineer` / `cto` |
| 8 | `/create-epics` (if the context has no epic), `/create-stories` | always | - | `producer` / `product-manager` |
| 9 | Per story: `/story-readiness` → implementation → `/code-review` → `/story-done` (user-run) | always | - | leads |
| 10 | `/smoke-check`, `/team-qa feature: <slug>` | always | - | `qa-lead` |
| 11 | `/release-notes` | user-visible change | `not user-visible` | `technical-writer` |
| + | `/core-use`, `/core-extract` | Phase 1 §3 | `core-first check: nothing to adopt or extract` | `principal-engineer` |
| + | `/observability-plan` | a new service, background job or SLO | `no new service, job or SLO` | `sre-lead` |

## 6. The plan gate

Present: the active set, the plan table, the routing note's open questions and
the layers STOPPED for an unset stack. Ask "Run this plan?" (`AskUserQuestion`:
run as shown · adjust steps · stop). Record the plan and the user's answer in the
checkpoint. Steps the user removes are recorded as `skipped — removed by user`
and carried to the report; a removed step does not remove the evidence it would
have produced from the Definition of Done.
