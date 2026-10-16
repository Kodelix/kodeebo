# Clean Architecture Standard

DoD gate 2. The goal is not diagrams — it is that business rules can be
tested in milliseconds without a database, and that swapping Postgres for
Mongo, Stripe for Paymob, or S3 for MinIO touches one adapter and nothing else.

## The dependency rule

```
adapters  ──►  app (use cases)  ──►  domain
(HTTP, DB,      orchestration,        entities, value objects,
 cache, queue,  transactions,         domain services, domain
 providers)     ports (interfaces)    errors, invariants
```

- **Dependencies point inward only.** `domain` imports nothing from `app` or `adapters`, and nothing from a framework, driver, ORM, HTTP library, or logger.
- **`app` defines ports** (interfaces) for everything it needs from the outside: repositories, cache, clock, ID generator, event publisher, payment provider. Adapters implement them.
- **Wiring happens once**, in the composition root (`cmd/<binary>/main.go`, Ktor `Application.module`, DI graph on mobile). Nothing else constructs adapters.
- **Bounded contexts are top-level folders** (`billing/`, `identity/`, `projects/`). A context never reaches into another's `domain` or tables; it calls the other context's `app` API or consumes its events.

## What goes where

| Concern | Layer |
|---|---|
| "An invoice cannot be paid twice" | domain |
| "Charge the card, then mark paid, then emit `InvoicePaid`, in one unit of work" | app |
| SQL, Mongo queries, Redis keys, HTTP handlers, JSON shapes, provider SDK calls | adapters |
| Request validation of *shape* (types, lengths) | adapter (edge) |
| Validation of *meaning* (plan allows this, quota not exceeded) | domain / app |
| Authorization decision | app (policy port), enforced before any side effect |
| Tenant scoping | app passes tenant context; adapter enforces it in every query (and RLS backs it up) |
| Telemetry spans | adapter edges + app use cases; domain stays free of telemetry imports |
| Caching | adapter (decorator around a repository port) — the use case does not know |

## Per stack

### Go (`backend/`)

```
cmd/api/main.go                      # composition root
internal/<context>/domain/           # pure Go: types, rules, errors
internal/<context>/app/              # use cases + port interfaces
internal/<context>/adapters/http/    # handlers, request/response DTOs
internal/<context>/adapters/postgres/
internal/<context>/adapters/redis/
internal/platform/                   # cross-cutting: config, otel setup, db pool
```
- Interfaces are declared by the **consumer** (`app`), kept small.
- `context.Context` is the first parameter of every port method that does I/O.
- Errors: domain sentinel/typed errors; adapters wrap with `%w`; HTTP adapter maps to RFC 9457.

### Ktor (`backend/`)

```
src/main/kotlin/<pkg>/<context>/domain/
src/main/kotlin/<pkg>/<context>/app/        # use cases, ports (interfaces)
src/main/kotlin/<pkg>/<context>/adapters/{http,persistence,cache}/
src/main/kotlin/<pkg>/Application.kt        # composition root, plugins, DI
```
- Domain is plain Kotlin — no Ktor, no Exposed/JDBC, no serialization annotations.
- Use cases are `suspend` functions; structured concurrency only, no `GlobalScope`.
- Sealed result/error hierarchies at the domain boundary; exceptions only for the truly exceptional.

### Web (`web/`, Vite + React)

```
src/app/                 # router, providers, composition
src/features/<feature>/  # ui/, model/ (state, hooks), api/ (query fns) — feature-sliced
src/shared/              # design system, api client, utilities — no feature imports
```
- Server state lives in TanStack Query; UI state stays local. No global store for server data.
- Components do not call `fetch` — they call feature `api/` functions generated from `contracts/`.
- Authorization in the SPA is UX only; the backend is the authority.

### Android / KMP / iOS (`mobile/`)

- KMP `shared/commonMain` holds domain + use cases + repository ports + Ktor client adapters; platform code holds UI and platform adapters (keystore/keychain, notifications).
- Compose: unidirectional data flow — `ViewModel` exposes immutable `StateFlow<UiState>`, receives intents; composables are stateless where possible.
- SwiftUI: `@Observable` view models on the main actor, use cases injected; Swift 6 strict concurrency.
- Offline-first features define their sync and conflict policy in the spec before code.

## Review checklist (used by `principal-engineer` and `/code-review`)

- [ ] `domain` has zero imports outside the standard library and other domain packages.
- [ ] No adapter type (DB row, DTO, SDK type) crosses into `app` or `domain`.
- [ ] Every external dependency of a use case is a port, injected.
- [ ] A use case can be unit-tested with fakes, no containers.
- [ ] No context reads another context's tables or domain types.
- [ ] Transactions are owned by the use case (unit of work port), not by handlers.
- [ ] Composition root is the only place adapters are constructed.

## Anti-patterns that fail review

- Anaemic domain + fat handlers ("service" that is a bag of SQL).
- Generic repository (`Repository<T>`) leaking query concerns upward.
- Shared "utils"/"common" package that every context imports and that grows forever.
- Framework annotations on domain types.
- Premature microservices: contexts start as modules in one deployable; split only with an ADR and a measured reason.
