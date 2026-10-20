# /setup-stack — Phase 2: Choose the Stack

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Choose the Stack

**In this file:**

- 2a: Evidence scan
- 2b: Read what is already configured
- 2c: One question per unset layer (guided)
- 2d: Direct mode
- 2e: Starting-point recommendations

### 2a: Evidence scan (silent, before the first question)

Collect what the repository already says. Evidence proposes a value; it never
sets one without the user's confirmation.

| Evidence | Proposes |
|---|---|
| `go.mod` anywhere under a code root | `stack.backend: go` |
| `build.gradle.kts` that applies Ktor (`io.ktor`) | `stack.backend: ktor` |
| both of the above | `stack.backend: go+ktor` — ask; two backends means two shared cores |
| `package.json` with `vite` and `react` | `stack.web: vite-react` |
| `package.json` with `astro` | `stack.site: astro` |
| an Android module (`com.android.application`) | `stack.mobile: compose` |
| a Kotlin Multiplatform module (`kotlin("multiplatform")`) | `stack.mobile: kmp` |
| an Xcode project or `Package.swift` | `stack.mobile: swiftui` (and `kmp+swiftui` with a KMP shared module) |
| Compose files in `deploy/` | `deploy.target: compose-vps` |
| manifests naming Postgres, Mongo, Redis or Dragonfly (images in compose files, drivers in `go.mod` / catalogs) | members of `stack.data` |
| `design/product-brief.md` Distribution and Stack lines | `distribution.model`, and layers the brief already names |

Code roots: `layout.code_roots` if set; otherwise the conventional `backend/`,
`web/`, `site/`, `mobile/`, `desktop/`, `contracts/` that exist on disk (the resolution
`resolve_code_root` performs). **If code exists elsewhere** (`app/`, `services/`,
a nested `apps/`), propose those directories for `layout.code_roots` — otherwise
hooks that scan source will not see them.

If the scan cannot run (no Bash result, unreadable manifests), say so. An empty
evidence table means "nothing found", not "nothing to find" — ask.

### 2b: Read what is already configured

Read `project.yaml` for every key this skill owns. An empty string or empty list
is unset. For each layer already set:

- Show it, with its provenance (`project.yaml`).
- Keep it unless the user asks to change it. **Do not re-ask a configured layer.**
- If the value is not in the enum list, show the rejected value and treat the layer as unset.

### 2c: One question per unset layer (guided)

Ask in this order, each via `AskUserQuestion`, skipping a layer the evidence
already settled *and* the user confirmed. Each question shows the evidence-based
option first, marked `(Recommended)`, and always offers `Leave unset`:

1. **Distribution** — `hosted` / `self-hosted` / `hybrid`. Ask first: it constrains deployment, tenancy and which cache engine is allowed in a customer bundle. Source: the brief's Distribution line if present.
2. **Backend** — `go` / `ktor` / `go+ktor`.
3. **Tenancy** — `shared-schema-rls` / `schema-per-tenant` / `db-per-tenant` / `single-tenant`. Ask whether the product serves many customers from one deployment or one customer per deployment, and whether any customer needs data separation stronger than row-level isolation. `single-tenant` pairs naturally with a self-hosted-only product.
4. **Web app** — `vite-react` / `none`.
5. **Marketing site** — `astro` / `none`.
6. **Mobile** — `compose` / `kmp` / `kmp+swiftui` / `swiftui` / `none`.
7. **Data stores** (multi-select) — `postgres`, `mongo`, `redis`, `dragonfly`. Ask what each is for; two stores for one job is a finding.
8. **Messaging** — not one of the enum-checked keys; `nats`, `rabbitmq`, `kafka` or `none`, **decided by `/research` and an ADR (at `modes.workflow: minimal`, an entry in the brief's decision log)**, not here. Offer `Leave unset — decide with /research` as the default. If the user names one, record it with the note that it has no stack reference (Phase 5 reports that as a gap).
9. **Deploy target** — `compose-vps` / `kubernetes`. Note that the studio's deployment rules and the stack reference cover Docker Compose; `kubernetes` is accepted but has no stack reference (Phase 5 reports the gap).
10. **Core track** — follows the backend: `go` → `go`, `ktor` → `kotlin`. For `go+ktor` ask which track the *shared core* follows, and say that the other backend then has no shared core yet. Ask for `core.repo` / `core.version` only if the user has a released core to pin; otherwise leave them unset and say the cores are built after the studio.
11. **Code roots** — confirm the roots found in 2a; accept a different list.

If the user answers "I don't know" to a layer, leave it unset and move on; list it
in the summary as unset. A layer left unset is a valid result.

### 2d: Direct mode

Take the pairs the user gave. Treat anything else as unchanged, and run 2b for
what is already set. Do not run 2c for unspecified layers; list them in the
summary as unchanged or unset.

### 2e: Starting-point recommendations

These are defaults to reason from, not verdicts; present at most two options with
the honest trade-off, then let the user choose.

- **Web app**: the studio ships one answer, a static Vite + React SPA with no Node server in production (`CLAUDE.md`, `.claude/docs/standing-decisions.md`). `none` is right for an API-only or mobile-only product.
- **Backend**: `go` and `ktor` each have a studio lead agent (`go-lead`, `ktor-lead`) and a shared-core track (`saas-core-go`, `saas-core-kotlin`). The trade-off to put to the user: Kotlin on both the backend and a KMP/Android client lets code and people move between them; Go keeps the backend a separate toolchain from the mobile apps. `go+ktor` doubles the cores, agents and CI — recommend it only with a stated reason.
- **Tenancy**: `shared-schema-rls` is the lowest-cost multi-tenant model and the one the studio's tenant-isolation checks are written around; stronger models cost more operations. Say which isolation test each implies (`.claude/docs/security-baseline.md`).
- **Desktop**: the studio has no default desktop runtime and no desktop lead agent. `stack.desktop` is set only from a `/research` note and an ADR (OS versions to support, packaging, offline storage, hardware such as printers and cash drawers); until they exist leave it unset, or `none` when the product has no desktop client. The ADR also names which lead owns `desktop/` (`/dev-story` routes by it).
- **Data**: recommend the fewest stores that do the job. Cache-engine licensing in customer bundles is a hard constraint (Phase 3).
- **Mobile**: `compose` or `swiftui` alone for one platform; `kmp` / `kmp+swiftui` when business logic should be shared. For factual claims about a layer's current version or support window, read `docs/stack-reference/<layer>/VERSION.md` and cite it; do not state a version or date from memory.

Close with: "This is a starting point, not a verdict — `/setup-stack` can be re-run,
and a change to tenancy or backend after data exists is a migration, not a setting."

---
