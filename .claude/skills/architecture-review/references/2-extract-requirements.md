# /architecture-review — Phase 2: Extract Technical Requirements

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Extract Technical Requirements from Every Spec

### Pre-load the TR Registry

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.

For each requirement you extract, the matching rule is:
1. **Exact/near match** to an existing registry entry for the same feature →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the spec wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
2. **No match** → assign a new ID: next available `TR-[feature]-NNN` for that
   feature, starting from the highest existing sequence + 1. `[feature]` is the
   spec filename stem.
3. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[feature]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the spec intentionally.

For each spec, read it and extract all **technical requirements** — things the
architecture must provide for the feature to work. A technical requirement is any
statement that implies a specific architectural decision.

Categories to extract:

| Category | Example |
|----------|---------|
| **Data ownership / structures** | "Each workspace has members with roles and a plan" → context ownership, schema, store |
| **Tenancy and authorization** | "A member sees only their workspace's projects" → tenant scoping, RLS, object-level authz |
| **Performance constraints** | "Dashboard loads in under 1 s with 10k rows" → budget, indexes, cache |
| **Cross-context communication** | "Plan change updates entitlements everywhere" → events, outbox, invalidation |
| **External provider** | "Charge via a payment provider, handle failed payments" → adapter, idempotency, webhooks, dunning |
| **State persistence / retention** | "Delete account removes personal data within 30 days" → retention, export/delete path |
| **Async processing** | "Export 100k rows by email" → job queue, status URL, retries |
| **Security-sensitive area** | auth, billing, licensing, upload, webhooks, PII, admin → threat model (ASVS/MASVS) |
| **Distribution** | "Works offline in self-hosted" → bundle, licence rules, upgrade path |
| **Client platform** | "Android and iOS apps, offline notes" → API contract, sync policy |

For each spec, produce a structured list:

```
Spec: [filename]
Bounded context: [context]
Technical Requirements:
  TR-[feature]-001: [requirement text] → Domain: [Identity/Tenancy/Billing/Data/API/Messaging/Caching/Observability/Security/UI/Deploy]
  TR-[feature]-002: [requirement text] → Domain: [...]  [SENSITIVE: billing]
```

Mark a requirement `SENSITIVE: <area>` when it falls in a security-sensitive
area — Phase 3 checks it has a threat model. This becomes the **requirements
baseline** — the complete set of what the architecture must cover.

---
