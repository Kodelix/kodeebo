# /architecture-decision — Steps 3a and 3b: Gather Context

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Gather context

### 3a: Architecture Registry Check (BLOCKING gate) — do this FIRST

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by bounded context, domain keyword, or data touched).
Run this before reading any existing ADR — the registry exists specifically so a
new ADR's author does not need to open prior ADRs to learn their binding facts
(data ownership, tenancy rules, interface contracts, forbidden patterns).

**If the registry file does not exist**, say so: `Registry check: NOT ASSESSED —
docs/registry/architecture.yaml not found.` Fall back to scanning `## Summary`,
`## Status` and the Stack Compatibility `Domain` of every ADR in the same domain
(`Grep` the headers; read an ADR only when a collision looks possible), and offer
to create the registry at Step 5's registry update. An absent registry is never
read as "no stances exist".

Present any relevant stances to the user **before** the collaborative design
begins, as locked constraints:

```
## Existing Architectural Stances (must not contradict)

Data Ownership:
  invoices → owned by billing context, PostgreSQL (ADR-0004)
  Interface: billing.app.InvoiceReader (read-only port)
  → If this ADR reads invoices, it must use this port, never the tables.

Tenancy Rules:
  tenant scoping → app passes TenantContext; adapters enforce; RLS backs it up (ADR-0002)
  → Every new store or query path must follow it.

Interface Contracts:
  plan_changed → domain event via outbox (ADR-0006)
  → If this ADR reacts to plan changes it must consume this event.

Forbidden Patterns:
  ✗ cross_context_table_read (ADR-0001)
  ✗ redis_as_system_of_record (ADR-0003)
  → The proposed approach must not use these patterns.
```

If the user's proposed decision would contradict any registered stance, surface
the conflict immediately:

> "⚠️ Conflict: This ADR proposes [X], but ADR-[NNNN] established that [Y] is
> the accepted pattern for this purpose. Proceeding without resolving this will
> produce contradictory ADRs and inconsistent stories.
> Options: (1) Align with the existing stance, (2) Supersede ADR-[NNNN] with
> an explicit replacement, (3) Explain why this case is an exception."

Do not proceed to Step 4 (collaborative design) until any conflict is resolved
or explicitly accepted as an intentional exception. Also check the stances
against `.claude/rules/deploy.md` licence rules and `.claude/docs/clean-architecture.md`:
a proposal that breaks either is a conflict even if no ADR says so.

### 3b: Existing ADRs, Related Specs and Research — registry-scoped, never unbounded

The registry (3a) covers *what* prior decisions bind — not always *why*. If the
registry surfaced a directly relevant ADR and its reasoning matters here (not
just its stated facts), read that specific ADR — never glob-and-read every
ADR in `docs/architecture/` on the chance one is relevant:

1. **Map its headings first** (cheap):
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Under ~50KB** (`Bash: wc -c "docs/architecture/[adr-file].md"`) — one full
   `Read` is fine; per-call overhead exceeds the savings from bounded reads at
   this size.
3. **~50KB or larger** — bounded-read only `## Context`, `## Decision`, and
   `## Consequences` (the sections that carry reasoning, not just facts) via
   `Read(offset, limit)` from the heading map.

Read specs the same way `/design-spec` does: only specs the registry or the ADR
list names as directly relevant, and only their `## Data & Contracts`,
`## Edge Cases & Failure Modes`, `## Non-Functional Requirements` and
`## Dependencies` sections
(`Grep pattern="^## (Data & Contracts|Edge Cases|Non-Functional|Dependencies)" ... -A 40`) — never a
speculative full read of `design/specs/*.md` looking for anything that might
relate.

Read the research note for the feature (`docs/research/<feature>.md`) in full if
it exists — it holds the options, versions and sources the ADR must cite, and the
ADR must not contradict it. Read `docs/architecture/architecture.md` sections
that name this decision (Required ADRs, the relevant context cards).

Skip the ADR/spec reads entirely if the registry and the research note already
answer everything this decision needs — most ADRs will.

---
