# /dev-story — Phase 3: Resolve Layers and Route

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Resolve Layers and Route

Work reaches a stack lead through `principal-engineer`, never around it:
`principal-engineer` owns the module design (port list, composition root,
bounded-context folders) and the integration of the leads' results
(`principal-engineer.md` → Responsibilities 1–2). This skill resolves the
**lanes**, hands `principal-engineer` the lane plan, and `principal-engineer`
delegates to the leads.

### Step 1 — Resolve the layers (lanes) from the story and `stack`

Inputs: the story's **Code root**, **Type**, **Owner agent** line and the files
its Implementation Notes name; the `stack:` line of the resolved block;
`resolve_code_root` output. **A layer whose `stack.*` value is `unset` is a STOP,
not a default** (`/setup-stack`). A code root that does not exist on disk and
that the story does not create is also a STOP — report it.

| Lane | Code root | Resolved by | Lead |
|---|---|---|---|
| Contract | `contracts/` | any `Type: Contract` story, or a story that adds/changes an operation | `api-designer` (contract first — nothing downstream starts before it merges) |
| Data (schema, migrations, cache, messaging) | `backend/` migration/adapter paths | the story creates or alters tables, collections, cache key families, queues | `data-lead` (delegates to `postgres-specialist`, `mongo-specialist`, `cache-specialist`, `messaging-specialist`, `migration-specialist`) |
| Backend | `backend/` | `stack.backend` = `go` (or `go+ktor`: the story's `Owner agent` line says which service) | `go-lead` (with `go-api-specialist`, `go-concurrency-specialist`) |
|  |  | `stack.backend` = `ktor` | `ktor-lead` (with `kotlin-coroutines-specialist`, `kotlin-persistence-specialist`) |
| Web SPA | `web/` | `stack.web` = `vite-react` (`none` → STOP: no web layer) | `web-lead` (with `react-specialist`) |
| Marketing site | `site/` | `stack.site` = `astro` | `web-lead` (with `astro-specialist`) |
| KMP shared | `mobile/shared/` | `stack.mobile` = `kmp` or `kmp+swiftui` | `kmp-specialist` (with `offline-sync-specialist` when the spec defines offline behaviour) |
| Android | `mobile/android/` | `stack.mobile` = `compose`, `kmp` or `kmp+swiftui` | `android-lead` (with `compose-ui-specialist`, `android-platform-specialist`) |
| iOS | `mobile/ios/` | `stack.mobile` = `swiftui` or `kmp+swiftui` | `ios-lead` (with `swiftui-specialist`, `swift-concurrency-specialist`) |
| Deploy / CI | `deploy/`, CI config | story edits compose files, healthchecks, installer, pipelines | `platform-lead` (with `infra-engineer`) — and `.claude/rules/deploy.md` for self-hosted licence rules |
| Provider integration | `backend/` adapters | payments, SMS/OTP, email, storage, push, OAuth, webhooks | `integrations-engineer` behind a port, under the backend lead |

**Secondary specialists** (consulted by the primary lead, named in the brief):

| Story concerns | Add |
|---|---|
| authentication, sessions, MFA, SSO, RBAC | `auth-identity-specialist` |
| tenant model, RLS, tenant-context propagation | `multitenancy-specialist` |
| licences, activation, entitlement enforcement | `licensing-specialist` |
| Type: Performance, or a budgeted hot path | `performance-engineer` |
| telemetry wiring beyond the standard span/metric/log set | `observability-engineer` |
| PII, export/delete, consent | `privacy-compliance-specialist` (advisory) |
| AR/EN, RTL, translatable strings | `localization-lead` (advisory) |

Use only names in `.claude/docs/agent-roster.md`. If a name in this table is not
in the roster, stop and report it rather than inventing a replacement.

### Step 2 — Order the lanes

Contract → Data → Backend → Clients (web, KMP shared, Android, iOS) → Deploy.
A lane starts only when the lanes it consumes are merged or the story is a single
lane. Independent client lanes (web vs Android vs iOS) may run in parallel after
the contract and backend lanes they depend on are done. A story that spans more
than three lanes is a scope smell: say so and ask whether to split it via
`/create-stories` (a story is one reviewable change).

State the plan to the user before spawning:
```
Layers resolved: [lane → lead (secondaries)], in order [1 → 2 → 3]
Source: story Code root [x]; stack: [backend=go web=vite-react …]
```

### Step 3 — Config stories need no lead

If the story's Type is `Config` (limits, flags, prices, TTLs), no agent is
required for the edit: read the acceptance criteria, show the specified changes
as from → to values, and ask "May I write to [config/data file path]?" before
editing it directly. A price, quota, limit or flag lives in config or the
database with a typed default — if the "change" would put a business value
inline in code, it is not a Config story; stop and re-classify. Then continue to
Phase 6 (smoke check) — Phases 4–5 reduce to the from → to display.

### Step 4 — UI stories go through the design workflow

For `Type: UI` (web or mobile screens) the visual work runs through
`/impeccable`, driven by `ui-designer`; the lead implements what the design
establishes.

1. Prerequisites: `PRODUCT.md` and `DESIGN.md` exist at the repo root (impeccable's location) and a UX spec exists in `design/ux/` for the screen or flow. If either is missing, STOP and name the fix: `/impeccable init` / `/impeccable document` for the root files, `/ux-design [screen]` for the UX spec. Do not let a lead invent the visual language.
2. Spawn `ui-designer` first (via `Agent`) with the UX spec, the story's criteria and the surface list; it drives `/impeccable shape` (if the screen has no brief) and returns the design direction. The design-system decision itself (new token, new surface type) is `design-director`'s call (DD-VISUAL, owned by `/team-ui`) — not made here.
3. Then `principal-engineer` routes the implementation to `web-lead` (or `android-lead` / `ios-lead`), briefed with the `ui-designer` output.
4. After implementation, Phase 6 has `ui-designer` (spawned via `Agent`; this skill holds no `Skill` grant) run `/impeccable audit [target]` (web) — or the native audit reference for Android/iOS — and `/impeccable polish [target]`, with the audit summary kept in the evidence folder.

### Step 5 — The stack-risk rule

The risk rating comes from `docs/stack-reference/<layer>/VERSION.md`, not from
the story card alone. If the story's `Risk` field is absent, `NOT ASSESSED`, or
disagrees with the reference, **the reference wins and an unknown counts as
HIGH.** For HIGH, the lead is briefed with the Phase 2 stack-risk escalation:
every API checked against the stack reference before use, gaps reported as
`NOT SOURCEABLE`, none filled from memory.

---
