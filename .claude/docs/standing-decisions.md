# Standing Decisions

Studio-wide decisions every product inherits. They ship with `.claude/` (so a
product repository has them; `docs/ROADMAP.md` stays in the studio as build
history and is never copied). Agents and skills apply them as given and do not
re-ask them. A product deviates only through its own record: `project.yaml`
(`stack`, `distribution`, `deploy`, `tenancy`), an ADR, or the product brief's
decision log — never silently.

## Product and platform (decided 2026-10-10)

| Topic | Decision |
|---|---|
| Business model | Own SaaS products; annual subscription **and** one-time licence (a product's brief may narrow it). |
| Distribution | Hybrid by default: multi-tenant hosted + self-hosted for enterprise (signed offline licences, update channel, installer). The product's `distribution` in `project.yaml` decides what applies. |
| Infra | Docker Compose on VPS; the same bundle is the self-hosted installer. |
| Web | Static SPA (Vite + React + TanStack Router/Query) for the product app, Astro static for marketing. No Node server in production — removes the RSC / middleware CVE class seen in Next.js 2025–2026. |
| UI/UX | `impeccable` is the design layer for every UI agent and skill (vendored, `.claude/vendor/impeccable/VENDORED.md`). |
| Shared code | One core per backend track (`saas-core-go`, `saas-core-kotlin`), chosen per product (`core.track`). |
| Entry point | `/studio <goal>`, or the opt-in `studio-orchestrator` main-thread agent. |

## Licence and tooling decisions (decided 2026-10-11)

Customer bundle = `deploy/self-hosted/` (see `.claude/rules/deploy.md`). L1–L4
bind only products whose distribution includes self-hosted; a hosted-only
product records "not applicable" rather than skipping them silently.

| # | Topic | Decision | Source |
|---|---|---|---|
| L1 | Cache engine in customer bundles | **Valkey** (`valkey/valkey:9.1.2`, BSD-3). Hosted may use Redis 8.2 or Dragonfly. | `docs/stack-reference/redis/VERSION.md` |
| L2 | Dragonfly | **Hosted only** — never in customer bundles (BSL 1.1). | `docs/stack-reference/dragonfly/VERSION.md` |
| L3 | MongoDB in customer bundles | **Reference the official image only** (the customer's Docker pulls it); never ship a Mongo binary or a derived image. | `docs/stack-reference/mongo/VERSION.md` |
| L4 | Observability in customer bundles | **OTel Collector only** (Apache-2.0), telemetry off by default; the customer points it at their own backend. | `docs/stack-reference/opentelemetry/VERSION.md` |
| T1 | Secret scanner | **gitleaks** for now; re-evaluate Betterleaks when it matures. | `docs/stack-reference/tooling/VERSION.md` |
| T2 | TypeScript | **6.0.3** now; 7.x once lint/test tooling supports it. | `docs/stack-reference/vite-react/VERSION.md` |

Changing a row here is a studio change (`bash tools/update-product.sh` carries it
to products); a pinned version in a row follows `docs/stack-reference/pins.yaml`
when the two differ, and the difference is reported, not resolved silently.
