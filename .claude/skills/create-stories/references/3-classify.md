# /create-stories — Step 3: Classify Stories by Type

> Part of `/create-stories`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Classify Stories by Type

**Story Type Classification** — assign each story a type based on its acceptance criteria:

| Story Type | Assign when criteria reference... | Owner agent (routed by `principal-engineer`) |
|---|---|---|
| **Logic** | Domain rules, pricing/plan/entitlement calculations, state machines, validation, use-case orchestration with fakes | the layer's stack lead: `go-lead` / `ktor-lead` (backend), `web-lead`, `android-lead`, `ios-lead`, `kmp-specialist` |
| **Integration** | A database, cache, queue, object storage or external provider (payments, SMS, email, push); repository adapters; migrations; webhooks | stack lead + `data-lead` (stores/migrations) or `integrations-engineer` (providers) |
| **Contract** | The API shape between backend and clients: authoring or changing `contracts/openapi/*.yaml` or `contracts/proto/`, generated clients, consumer contract tests, breaking-change checks | `api-designer` (contract), then the consumer's stack lead |
| **Security** | Authentication, authorization model, tenant isolation, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, secrets, rate limits | `appsec-engineer` with the stack lead; `auth-identity-specialist`, `multitenancy-specialist`, `licensing-specialist` as the criteria require |
| **Performance** | A hot path with a budget in `perf-budgets.md`: list/search endpoints, dashboards, jobs, startup, bundle size; load-test criteria | `performance-engineer` with the stack lead |
| **UI** | Web or mobile screens, flows, states, empty/error states, RTL and accessibility | `web-lead` / `android-lead` / `ios-lead`, design via `ui-designer` (`/impeccable`) and `ux-designer` |
| **Config** | Limits, plans, flags, prices, quotas as data or config only — no new logic; deploy/compose changes | `pricing-billing-designer` (plans/quotas) or `platform-lead` / `infra-engineer` (deploy) |

Mixed stories: assign the type that carries the highest implementation risk, with this
precedence when in doubt: **Security > Contract > Integration > Performance > Logic > UI > Config**.
The type determines what test evidence is required before `/story-done` can close the story
(`coding-standards.md` "Test evidence by story type"). The eight DoD gates apply to
every story regardless of type; the type picks the evidence that is *primary*.

A story touching more than one code root is split (Step 4): one story, one code root, one owner.

**Gate level per type** comes from `testing.strict.*` in the resolved block, else
the defaults in `.claude/docs/coding-standards.md`: Logic, Integration, Contract, Security and UI
BLOCKING; Performance ADVISORY (BLOCKING when `performance.enforce: block`); Config ADVISORY.
State the effective level in each story's evidence table.

---
