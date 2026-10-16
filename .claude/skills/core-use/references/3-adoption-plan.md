# /core-use — Phase 3: Adoption Plan

> Part of `/core-use`. Read again if the conversation was compacted.

## 1. Sensitive-module gate

If the module is one of the `security-baseline.md` triggers (authentication or
authorization model, billing, licensing, file upload, webhooks, PII
export/delete, admin/impersonation), or its docs say it handles any of them,
a threat model must exist for the feature using it
(`docs/architecture/threat-models/<feature>.md`). Absent → `BLOCKED` until
`/threat-model <feature>` has run; the plan below may still be drafted. For
identity and sessions consult `auth-identity-specialist`; for licensing,
`licensing-specialist`; for billing, `pricing-billing-designer` (plans and
entitlements are the product's, the engine is the core's).

## 2. Spawn principal-engineer for the plan

Spawn `principal-engineer` via `Agent` (it owns module boundaries and
core-vs-product decisions). Brief it with paths and the decisions already made —
do not paste documents. It reads the Phase 1–2 results, the module's port files
at the tag, and `clean-architecture.md`. It returns a plan and writes it to
`production/core/adopt-<module>-<date>-plan.md` (path named here, so it is the
agent's write authorisation: a new artifact under `production/`; you ask once
for the plan in Phase 3 step 4, not per write).

The plan answers, with file paths:

1. **Dependency declaration** — where the core module is declared and at what
   tag: Go → the `go.mod` of `backend/` (and `go.sum` from the tool); Ktor → the
   version catalog `gradle/libs.versions.toml` and the module's build file. The
   exact coordinates come from the core repo (module path or published
   coordinates). How a private core repo is authenticated in CI and locally is
   `NOT SOURCEABLE` in `docs/stack-reference/` — the plan reuses whatever
   mechanism the product already uses for private dependencies, else it asks
   `platform-lead` (through `principal-engineer`) and records the question.
2. **Port wiring** — which port(s) of the module the product's use cases need;
   the adapter chosen per environment (hosted vs self-hosted may differ — see
   the Phase 2 infrastructure row); the **single composition root** that
   constructs it: Go → `cmd/<binary>/main.go`; Ktor → `Application.module`.
   `domain` imports nothing from the core's adapters; `app` depends on the
   port. Whether the product wraps the core port in a product-owned port
   (isolation, easier fakes) or uses the core's port type directly is decided
   here and recorded — default: use the core port directly unless the product
   needs a narrower contract.
3. **Configuration** — each config key the module needs, its source (env or
   secret store), its typed default, and what is hosted-only vs bundle. No
   secret in code, logs, URLs or client bundles; no business value inline.
4. **Replaced code** — the product-local code the module supersedes (from the
   Phase 1 grep) and the removal plan: the old path is deleted in the same
   change once parity tests pass, never left running beside the core.
   Storage-backed modules that take over tables → `/db-migration` and
   `/team-data`.
5. **Tests in the product** (the core's own conformance tests are the core's;
   the product proves its **use** of the module):
   - composition-root test: the module is constructed with the product's
     config and the app starts (health endpoint up);
   - integration test of each use case that calls the port, against the real
     adapter's dependencies via Testcontainers (never a mocked database —
     `testing-standards.md`), including tenant isolation (tenant A cannot see
     tenant B) when the module holds tenant data, and the failure paths the
     module documents (timeout, provider/dependency down);
   - unit tests of use cases with a fake of the port. If the core ships a fake
     or in-memory adapter, use it; if it does not, the plan includes a
     product-local fake and a note to ask for one upstream;
   - a contract test only if the module exposes HTTP/proto surfaces the product
     republishes (`contracts/`, `/api-contract`).
6. **Observability** — which of the module's spans/metrics/logs the product
   keeps, and the product-side span attributes; no PII.
7. **Lanes and owners** — resolved from `stack`, in the `/dev-story` order:
   Contract (if any) → Data → Backend (`go-lead` or `ktor-lead`) → Clients.
   Client-side core pieces (`clients/` KMP, Swift, TypeScript in the core repo)
   go to `kmp-specialist`, `ios-lead`, `web-lead` respectively. An unset layer
   is a STOP, never a default.
8. **Rollback** — how to return to the previous state (revert the dependency
   and wiring commit; data steps per `/db-migration`).
9. **DoD gates** the change must evidence (the eight gates, `coding-standards.md`),
   marking gate 8 per the Phase 2 decision record.

## 3. Review (parallel, `review_mode: full` only)

In `full`, spawn in one message, before the user sees the plan:
`go-lead` or `ktor-lead` (per track) to check the wiring and idioms against the
stack reference, and `security-lead` when the module is sensitive. Lean/solo:
`plan review skipped — <mode> mode`. The skipped review is stated in the plan
header, not omitted.

## 4. Approval of the file set

Show the plan and the **complete list of files** to be created or changed
(dependency files, composition root, config, tests, removed code). Ask once:
"May the stack lead create/change these files?" Options: approve · approve minus
<files> · revise the plan · stop. Only a yes authorises Phase 4 writes. Multi-file
changes require explicit approval for the full changeset (`CLAUDE.md`).
