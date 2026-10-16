# /team-api — Phases 1–2: Intake, Consumers, the Contract

> Part of `/team-api`. Read again if the conversation was compacted.

## 1. Intake

Restate the change in one sentence in the user's language; derive `<slug>`
(kebab-case; the feature spec stem when the change belongs to a feature). Inventory,
each row FOUND or ABSENT:

| Artifact | Path |
|---|---|
| Spec (Data & Contracts section) | `design/specs/<slug>.md` |
| Research note | `docs/research/<slug>.md` |
| Threat model (required for auth, billing, licensing, webhooks, upload, admin surfaces) | `docs/architecture/threat-models/<slug>.md` |
| Current contract(s) | `contracts/openapi/*.yaml` (and `contracts/proto/**` only if an ADR chose gRPC) |
| Last released contract (the diff baseline) | git tag or release record — found by `/api-contract` |
| API policy: minimum support window for deprecated versions | the product's stated policy / ADRs under `docs/architecture/` |
| ADRs: JSON field case, client generator, API style | `docs/architecture/adr-*.md` |
| A prior contract-change record for this slug | `production/qa/evidence/<STORY-ID>/contract-change.md` or `production/qa/contract-change-*.md` |
| Existing stories for this change | `production/epics/**` |

`contracts/` absent → this is the first contract; `/api-contract` handles it (the
baseline is `none — first contract`). A sensitive surface with no threat model:
route to `/threat-model` first; the contract may be drafted but the verdict
cannot be `COMPLETE`.

## 2. The consumer map

Who consumes the operations being changed? Build it from evidence:

1. The operations touched (from the spec or the sentence; refined after Phase 2).
2. For each lane in the Phase 0 table, grep its code root for the operation IDs,
   paths, generated-client method names and the schemas' names
   (`resolve_code_root`; an empty result means the scan **did not run**, said so):
   `web/src`, `mobile/shared`, `mobile/android`, `mobile/ios`, `deploy/` (health
   checks, proxy rules), `site/` (marketing pages calling the API), `tools/`
   (seed, codegen).
3. Webhook consumers: the product's outbound webhook catalogue and its documented
   payload versions.

| Consumer | Lane / location | Operations used (file:line) | Can be migrated in this run? |
|---|---|---|---|
| web SPA | `web/` | | yes / no — reason |
| KMP shared / Android / iOS | | | |
| Self-hosted customers, customer automations, old mobile app versions in the field, third-party webhook receivers | **not enumerable from this repo** | - | `NOT ASSESSED — external consumers cannot be listed from the repository`; the support window and the headers are the only lever |

Print the table, including the unenumerable row. A lane that consumes nothing is
`skipped — does not consume <operations>` and is not spawned.

## 3. Phase 2 — the contract (`/api-contract`)

Invoke `/api-contract <slug> [--service <name>]` via the `Skill` tool. It spawns
`api-designer`, runs the checklist review, asks the user the design questions,
writes `contracts/openapi/<service>.yaml` after approval, runs lint / the
breaking-change diff / client generation **only where the repository defines
them** (otherwise `not run`), plans the contract tests, and writes the
contract-change record. Do not design the contract here and do not write
`contracts/` yourself.

When the change spans independent services or a webhook catalogue, `/api-contract`
may use more than one `api-designer`; its rules apply.

**Verify on disk (Trigger 0):** the edited `contracts/openapi/*.yaml` carries the
change; the contract-change record exists; read its **classification table**, the
**tooling table** (lint / diff / generation: ran or `not run — reason`), the
checklist result and the contract-test plan.

Classification (from the record; the diff output wins over the designer's
self-assessment, a manual diff is labelled as such):
- **ADDITIVE** → Phase 3 skipped (`skipped — classification ADDITIVE`).
- **DEPRECATING** → Phase 3 runs for the deprecation parts.
- **BREAKING** → Phase 3 runs; **no lane starts** until the route is decided and,
  for the ADR route, the ADR is `Accepted`.

`/api-contract`'s own verdict is carried: `BLOCKED` stops this run;
`NOT ASSESSED` (tooling absent, no baseline) is carried forward and caps this
run's verdict at `NOT ASSESSED` unless the user supplies what is missing.

**Gate — contract approved and written** (decided inside `/api-contract`; restated
here before lanes start): the lanes begin only after an explicit yes. "Merged"
means approved and written to `contracts/`; committing is the user's call.
