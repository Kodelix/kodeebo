# /create-architecture — Phase 1: Bounded Contexts, Layers and Ports

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Bounded Contexts, Layers and Ports

Take every bounded context from `design/specs/domain-map.md` and give it a
concrete shape. Follow `.claude/docs/clean-architecture.md`: dependencies point
inward only; contexts are top-level modules of one deployable at first.

Two views, both required:

### 1a. Layer map (build-order layers)

Map every context into a build-order layer. This is the `Layer` taxonomy the
ADR template uses (how early the decision must exist), not the clean-architecture
ring:

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │  ← web app shell, mobile screens,
│                                             │    marketing site, emails
├─────────────────────────────────────────────┤
│  FEATURE LAYER                              │  ← product features built on core
│                                             │    contexts: reports, workflows
├─────────────────────────────────────────────┤
│  CORE LAYER                                 │  ← the product's core domain
│                                             │    contexts and their use cases
├─────────────────────────────────────────────┤
│  FOUNDATION LAYER                           │  ← tenancy, identity, data stores,
│                                             │    messaging, API style, billing/
│                                             │    licensing, observability, audit
├─────────────────────────────────────────────┤
│  PLATFORM LAYER                             │  ← OS/runtime, containers, Compose,
│                                             │    reverse proxy, CI, `saas-core`
└─────────────────────────────────────────────┘
```

### 1b. Context cards

For each bounded context, produce a card:

- **Layer** (build order) and **kind** (core module / generic / product-specific, from the domain map)
- **Owns** — data, state, language, and the invariants it enforces (domain)
- **Use cases** — the application-level operations (app), one line each
- **Ports** (declared by the consumer, in `app`): repositories, clock, ID generator,
  event publisher, cache, payment/SMS/email/storage provider, policy (authz). List each
  port with the adapter(s) planned: `postgres`, `mongo`, `redis`/`valkey`, `http`, a provider.
- **Exposes** — the app API other contexts may call and the events it publishes
- **Consumes** — the other contexts' app APIs/events it uses (never their tables or domain types)
- **Shared-core modules used** — `saas-core` module @ `core.version` (identity, observability,
  otp, notify, storage, billing, licensing, tenancy, audit, ratelimit …), or "none". Reimplementing
  a core capability in the product is a flagged finding; a needed capability the core lacks is a
  `/core-extract` candidate, not a local copy.
- **Stack touch-points** — which backend/web/mobile layers carry its code, and the stack-reference
  area each depends on (with version and risk level noted)

Format as a table per layer, then as a dependency diagram (Mermaid, so it diffs
in review). Verify the diagram has no cycle and that no context reads another's
`domain` or tables; a cycle or a table read is a finding to resolve before
approval.

**Backend layout check**: show where the contexts land in the code roots from
`resolve_code_root` (`internal/<context>/{domain,app,adapters}/` for Go,
`<pkg>/<context>/{domain,app,adapters}/` for Ktor), and where web
(`src/features/<feature>/`) and mobile code for each context live. State any
context that is a candidate to split into its own service later, and the
measured reason required to do so (an ADR) — the default is one deployable.

**Stack awareness check**: For each context in the Foundation and Core layers,
flag if it touches a HIGH or MEDIUM risk stack area. Show the relevant
stack-reference excerpt inline:

```
⚠️  [package/feature] — [layer] [pinned version] (HIGH risk)
    Verified against: docs/stack-reference/[layer]/[file].md
    Behaviour confirmed: [yes / NEEDS VERIFICATION]
```

Present the proposed map and cards and ask for approval before proceeding.
Record the approved map in `production/session-state/active.md`; it goes into
the document at Phase 8.

---
