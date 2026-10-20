# /architecture-decision — Step 1: Load Stack Context

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 1. Load Stack Context (ALWAYS FIRST)

Before doing anything else, establish the stack environment:

1. From the config block, note `stack.*`, `deploy`, `distribution`, `tenancy`. If
   no stack is configured, prompt: "No stack is configured. Run `/setup-stack`
   first, or tell me which layers this decision touches." A decision cannot be
   validated against a stack that is not named.

2. Identify the **layer(s)** and **domain** of this architecture decision from the
   title or the user's description.
   - Layers: Go backend, Ktor backend, Web (Vite+React), Marketing (Astro), Android, iOS, KMP, Data, Deploy.
   - Domains: Identity, Tenancy, Billing, Licensing, Data, API, Messaging, Caching, Observability, Security, UI, Deploy, Core.

3. For each touched layer read `docs/stack-reference/<layer>/VERSION.md`
   (pinned version, risk level, licence notes), then `docs/stack-reference/pins.yaml`
   for the machine-readable pin. Read `best-practices.md` for the sections that
   match the decision (for example portability for a cache, RLS for Postgres).

4. Read `docs/stack-reference/<layer>/breaking-changes.md` — flag any changes in
   the relevant domain that post-date the model's training cutoff.

5. Read `docs/stack-reference/<layer>/deprecated-apis.md` — flag any APIs in the
   relevant domain that should not be used.

6. If `distribution.model` is `hybrid` or `self-hosted`, read `.claude/rules/deploy.md`
   and the licence decisions in `.claude/docs/standing-decisions.md`: a decision that picks a cache,
   database or observability component must be valid for the customer bundle, not
   only for hosted.

7. Look for the research note: `docs/research/<feature>.md` for the feature(s)
   the decision serves. Read it if it exists. **If it does not, say so now**: the
   ADR is written with `Research note: NOT FOUND` and cannot be Accepted until the
   note exists (`research-protocol.md`; run `/research`). Never invent the note's
   findings.

8. **Display a stack knowledge-gap warning** before proceeding if the domain carries
   MEDIUM or HIGH risk, or a touched layer is `NOT SOURCEABLE`:

   ```
   ⚠️  STACK KNOWLEDGE GAP WARNING
   Layer(s): [name + pinned version]
   Domain: [domain]
   Risk Level: HIGH — pinned version is past what the model reliably knows.

   Key changes verified from docs/stack-reference/:
   - [Change 1 relevant to this domain]
   - [Change 2]

   NOT SOURCEABLE: [layer or API not covered by docs/stack-reference/ — research required]

   This ADR will be cross-referenced against the stack reference.
   Proceed with verified information only — do NOT rely solely on training data.
   ```

   A decision that depends on an API beyond the stack reference is a
   `CTO-STACK-RISK` candidate (Step 5.6).

---
