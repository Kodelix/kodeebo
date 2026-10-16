# /team-feature — Phases 5–6: Contract, Data, Cache, UX, Architecture, Stories

> Part of `/team-feature`. Read again if the conversation was compacted.

## 1. Phase 5a — Start the independent lanes together

After spec approval (and the threat model, where it fired), these have no
dependency on one another. Start every fired lane in the **same turn**; issue all
`Agent` calls before waiting, and invoke the skills in the order they need user
input so the user is never asked two things at once:

| Lane | How | Notes |
|---|---|---|
| Contract | `/api-contract <slug>` — or `/team-api <slug>` when the change is **BREAKING** (per `/api-contract`'s own classification) or touches two or more client layers | contract first: nothing backend or client starts before it merges |
| Data | `/team-data <slug>` when the change spans two or more of schema / cache / messaging or a tenant-owned table; otherwise `/db-migration <slug>` — **user-run**: print the command, with the research note and spec paths, and continue other lanes | the migration plan and files are the artifact to verify |
| Cache | `/cache-design <slug>` when a hot read path is added or changed; "no cache" is a valid written decision | portable across Redis / Valkey / Dragonfly |
| UX | `/ux-design <slug>` then `/ux-review design/ux/<slug>.md` | needs `PRODUCT.md`; absent → STOP this lane: `/impeccable init`. The implementation of the screens is Phase 7 (`/team-ui`), not here |
| Observability | `/observability-plan` | only for a new service, background job or SLO |
| Core | `/core-use <module>` for each module the routing note lists, `/core-extract` for a gap | before the backend lane |

Apply the rules of those skills unchanged; this phase only sequences them.

## 2. Phase 5b — Verify the artifacts and the merge

For each fired lane check the artifact **on disk**, not the skill's reply:

- Contract: `contracts/openapi/*.yaml` carries the change; the contract-change
  record exists; the BREAKING table is empty or an ADR/major version exists;
  generated clients regenerated or reported `not regenerated`.
- Migration (user-run): `docs/architecture/migration-plans/<slug>.md` and the
  migration files exist; `bash .claude/scripts/migration-lint.sh` output was
  shown by the skill. **If the user has not run `/db-migration` yet, say the
  backend lane for stories that touch the schema is waiting on it** and continue
  with the others; a destructive step or an apply is never taken from here.
- Cache decision record, UX spec + `/ux-review` verdict, observability plan.

"Merged" for the contract means the user has approved the change and it is
written to `contracts/`; committing is the user's call (no commits from here). A
lane that returned `NOT ASSESSED` or `BLOCKED` is named in the checkpoint and
blocks only the lanes that depend on it.

## 3. Phase 6a — Architecture decisions

`principal-engineer` proposes the module design for the feature (ports, composition
root, `domain/app/adapters` placement, where each core module is wired) and lists
every architectural choice: write to `production/features/<slug>/architecture.md`
(named path). For each choice that is architectural — a new store, boundary,
messaging pattern, DI/library decision, core-vs-product call — invoke
`/architecture-decision "<title>"`; `CTO-ADR` runs inside it per `review_mode`.
At `workflow: minimal` the decision goes to the decision log in
`design/product-brief.md` (asked) instead of an ADR file. **Critical ADRs**
(tenancy, identity/auth, data store, messaging, API style, deployment topology,
licensing) are required at `standard` and `full`.

**Gate — ADR.** Moving an ADR to `Accepted` is the user's (or `cto` on the user's
explicit confirmation); this orchestrator never edits that field. Stories that
reference a `Proposed` ADR stay Blocked.

## 4. Phase 6b — Epics and stories

1. If the bounded context has no epic: `/create-epics <context>`.
2. `/create-stories <epic-slug>`: stories embed TR-ID, ADR guidance, acceptance
   criteria including negative and cross-tenant cases, story type, owner agent and
   the DoD evidence each produces, in **contract-first order**. `QL-STORY-READY`
   runs inside it per `review_mode`.
3. Check the story list against the lane plan: every fired step has at least one
   story (a contract story, a data story, a backend story per use case, a client
   story per layer, a deploy story if compose files change); a story spanning more
   than three lanes is split.

**Gate — story list.** Present the stories with type, lane, owner and
dependencies; the user approves, edits or stops. Waves in Phase 7 are derived from
this list.
