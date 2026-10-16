# /reverse-document - Mode Reference

> Read only the section for the chosen mode. Every mode shares the rules in
> `3-evidence-and-sufficiency.md` and the brief in `5-draft-and-verify.md`.
> "Read" below means the skill reads it in Phase 2 and records it in the ledger;
> it does not mean the draft may add anything the ledger lacks.

Tags used in every draft: `[UNVERIFIED — ask]` (the code cannot show it; listed as
a question) and `(inferred from <path:line>)` (a deduction that still cites the
lines it rests on). Intent, rationale, audience and targets are never merely
inferred: they are `[UNVERIFIED — ask]` unless a cited README line, comment,
commit message or ADR states them, in which case the draft writes
`(stated in <path:line>)`.

---

## Mode `brief`

**Output**: `design/product-brief.md`, template `.claude/docs/templates/product-brief.md`
(the one-page format at every tier). **Agent**: `product-manager`.

**Read (ledger sources)**
- Stack profile: package manifests and lockfiles (`go.mod`, `build.gradle(.kts)`,
  `package.json`, `Package.swift`), Dockerfiles, `deploy/` (compose files, the
  self-hosted bundle); compare with `project.yaml` `stack`
- What the product does: route tables, handlers, screens, jobs, webhooks - the
  list becomes the MVP list (one row per user-visible capability, each with a cite)
- Pricing model: plan, entitlement, quota and price code or seed data, the billing
  provider adapter, currency and tax handling (field names and structure, never
  customer data)
- Distribution: hosted vs self-hosted (`deploy/self-hosted/`, licence checks),
  web / Android / iOS targets, marketing site
- Tenancy and foundation decisions visible in code (tenant key, RLS policies in
  migrations, identity, data stores, API style): each is a decision-log row; the
  date comes from read-only `git log` (`--diff-filter=A` on the file), the *why*
  is `[UNVERIFIED — ask]` unless a cited line states it
- Stated purpose: `README.md`, docs, app store text, landing-page copy - cited as
  `(stated in <path:line>)`, never as verified fact
- Stubs, `TODO`/`FIXME`, flags that are off: candidates for "Out of scope" or
  open items, listed with cites and marked `[UNVERIFIED — ask]` as to intent

**Fills from the code**: Stack (profile), Pricing model (structure only), Distribution
(delivery, channels present), MVP (what exists), Decision log (decisions visible).

**Never filled from the code** (each gets `[UNVERIFIED — ask]` plus its question):
Problem, ICP, Jobs-to-be-done, Positioning, Success metric, Out of scope (as
intent), Build order (the product already exists; ask whether a roadmap exists),
and every RECOMMENDED line. Where the README states one, quote the line number
instead of a guess.

**Tier**: the brief is the same one page at every tier. At `standard` and `full` the
template's "Fuller sections" (market and competitors, personas, pricing
hypotheses and unit economics, risks, success metrics, roadmap) are listed in the
draft as `NOT DERIVABLE FROM CODE — ask` with a pointer (`/market-research`,
`/brainstorm`); they are never filled.

**Sufficiency floor**: at least one manifest or entry point **and** at least two
user-visible capabilities in the ledger.

---

## Mode `research <context>`

**Output**: `docs/research/<context>.md`, template `.claude/docs/templates/research-note.md`
(all nine sections, same headings). **Agent**: `researcher`.

**Locate the context**: Glob the resolved roots for a directory named `<context>`
(case-insensitive) - `backend/internal/<context>`, `backend/src/main/kotlin/**/<context>`,
`web/src/**/<context>`, `mobile/**/<context>`. Several matches: list them and ask
which belong (a context can span layers; all chosen are read). None: `NOT ASSESSED
- context <context> not found under <roots>`.

**Read (ledger sources)**
- Versions: manifests and lockfiles for the libraries the context imports, with
  the line of each pinned version; compare with `docs/stack-reference/pins.yaml`
  and report each as `matches pin` / `differs from pin (<pin>)` / `not in pins`.
  A layer with no `docs/stack-reference/<layer>/VERSION.md` is
  `NOT SOURCEABLE — no stack reference for <layer>`
- Choices the code made: persistence approach and store, external providers and
  SDKs, auth and session handling, hashing and crypto calls, queue / cache use,
  retry / timeout / idempotency handling, webhook verification
- Security surface: authn/authz checks, tenant scoping on queries, input
  validation, secret handling (names only), file upload handling, PII fields
- Performance and caching: caches (pattern, key, TTL), pagination, indexes in
  migrations, loops that call the database, payload bounds
- Observability: spans, metrics, log events found (and their absence)

**Note content rules**
- Header: `Status: Draft`, plus the line `Origin: Reconstructed from code by
  /reverse-document on <date> at commit <sha>. Records the choices the code
  already made; it is not research done before the code and does not by itself
  satisfy gate 1 for new work in this context.`
- Section 3 Findings: each row is an observed choice with `path:line`; the Tier
  column reads `code` (code evidence, not a source). A claim about external
  behaviour (a library's guarantee, an advisory, an ASVS control ID) has a source
  link and tier only if the `researcher` fetched it at the pinned version in this
  run; otherwise `NOT SOURCEABLE — <what was searched>`.
- Section 4 Options: only alternatives evidenced in the repository (an old
  adapter, a comment, an ADR, a commit message, cited). Alternatives the
  researcher adds are labelled `researched after the fact, not what was
  considered at the time`.
- Section 5 Decision: `Chosen (observed)` with cites; `Why` is `[UNVERIFIED —
  ask]` unless cited; `Follow-up record` is the ADR (at `workflow: minimal`, a
  brief decision-log line) the user should write.
- Sections 6 to 8: observed controls, caching and telemetry, each gap named
  against the standards (`.claude/docs/security-baseline.md`,
  `caching-standard.md`, `observability-standard.md`). A context touching auth,
  billing, licensing, file upload or PII with no threat model in
  `docs/architecture/threat-models/` is flagged for `/threat-model`.
- Section 9 Open Questions: every `[UNVERIFIED — ask]`, owner `user`.

**Tier**: required at every tier. **Sufficiency floor**: at least one external
dependency or one persisted entity or one endpoint in the context, and ~20 lines
of non-boilerplate code.

---

## Mode `spec <feature>`

**Output**: `design/specs/<feature>.md`, template
`.claude/docs/templates/spec-from-implementation.md`. **Agent**: `product-manager`.

**Locate the feature**: Grep the resolved roots and `contracts/` for the feature's
routes, handlers, use cases, entities, migrations, screens and tests. Show the
files found and confirm the boundary with the user when more than one directory
is involved ("is `invites` part of this feature?"). The spec's `Source` field
lists every path read.

**Read (ledger sources)**: rules and flows as implemented; state machines and
transitions; permission checks per role and tenant (enforced at `path:line`, or
absent); entities with tenant key, retention and PII fields (migrations);
endpoints, idempotency keys and auth policy, compared with `contracts/` (drift
named); events and webhooks; provider calls; limits, quotas and plan gates (named
configuration or hardcoded - hardcoded business values are listed with cites);
formulas (pricing, proration, quota maths); edge cases handled (and
`TODO`/missing ones); tests that exist (names with `path:line`) and cross-tenant
or negative tests that do not; NFR evidence per `coding-standards.md` gates
(research note, threat model, perf budget, cache decision, spans and metrics,
accessibility and AR/EN strings).

**Tier sections** (feature tier from `1-parse-and-scope.md` section 3; sections
named in `.claude/docs/workflow-modes.md`):
- `full`: the Summary and all 8 numbered sections.
- `standard`: the Summary and the 5 required (Overview, Detailed Behaviour, Data &
  Contracts, Non-Functional Requirements, Acceptance Criteria), plus Edge Cases &
  Failure Modes when the ledger shows the feature calls an external provider, moves
  money, changes entitlements or runs asynchronously (cite the line that shows
  which). User Value and Dependencies are optional and are **not generated**; the
  draft ends with `Sections not generated at this tier: User Value, Dependencies`.
- `minimal`: a spec is not required (the brief and research note cover it). The
  skill says `minimal: spec not required; writing voluntarily at the standard
  section set`, because the user typed the command, and generates as `standard`.

Section 2 (User Value, when generated) is always `[UNVERIFIED — ask]` for role,
job and plan gate unless the code states them; the skill lists the observable
gates (`plan == "pro"` checks) with cites and asks for the rest. Acceptance
criteria: "What Exists" is built from the tests found; the missing negative and
cross-tenant cases are listed under "What Is Missing", never invented as passing.

**Sufficiency floor**: at least one endpoint, handler or use case **and** one of
entity / rule / state in the feature scope.

---

## Mode `architecture`

**Output**: `docs/architecture/architecture.md`, template
`.claude/docs/templates/architecture-doc-from-code.md`, retitled
`Architecture (as built): <repository or product name>`; the Decision section
describes the system as implemented. **Agent**: `principal-engineer`. If it cannot
be spawned, the stack lead for the dominant layer named by the resolved `stack`
(`go-lead`, `ktor-lead`, `web-lead`, `android-lead` or `ios-lead`); if none can
be spawned, `NOT ASSESSED — no owning agent`.

**Read (ledger sources)**: every resolved root. Bounded contexts (directories) and
their layering (does the domain package import frameworks, DB drivers or HTTP -
cite each violation of `.claude/docs/clean-architecture.md`); ports and adapters;
data store per context (drivers, migrations, repositories) and ownership;
tenancy mechanism (tenant column, RLS policies, middleware, per-tenant schema) and
where it is enforced; identity and session; API style and contract files;
messaging, jobs and webhooks; cache usage; observability wiring (OTel, logging);
shared-core usage (imports of `saas-core`, or local re-implementations of
identity, billing, licensing, storage, notifications: cite); deployment topology
(hosted compose, `deploy/self-hosted/`, CI files); dependency versions against
`docs/stack-reference/pins.yaml` (drift listed).

**Content rules**
- Key Implementation Details is a table of foundation decisions found (tenancy,
  identity, data stores, API style, messaging, deployment, licensing), each with
  cites, `Rationale` as `[UNVERIFIED — ask]` unless cited. This skill does **not**
  write ADR files; the Follow-Up Work lists one ADR per foundation decision (at
  `workflow: minimal`, a decision-log line in the brief) for the user to accept.
- Alternatives Considered holds only alternatives the repository evidences.
  Otherwise the section reads `none found in the source`.
- Validation and Known Issues list observed defects only: layering violations,
  missing tenant scope, hardcoded business values, missing tests, pin drift,
  each with a cite.
- Diagrams, if any, are Mermaid built only from ledger rows.

**Tier**: the document is written at every tier (voluntary at `minimal`, where the
brief's decision log carries decisions). **Sufficiency floor**: at least two
modules or contexts **and** one data store or deployment artifact.

---

## Mode `concept <prototype-dir>`

**Output**: `prototypes/<name>/CONCEPT.md`, template
`.claude/docs/templates/brief-from-prototype.md`; **and**, when
`prototypes/<name>/README.md` does not exist, a short `README.md` (hypothesis,
how to run, status, findings pointer) because `.claude/rules/prototype-code.md`
requires one and `detect-gaps.sh` flags its absence. Both files are one changeset
in one "May I write". **Agent**: `product-manager`.

**Read (ledger sources)**: everything under the prototype directory except
`node_modules`, build output and `.env*`. What it does (screens, routes, scripts),
how it runs (scripts, compose, README), stack and libraries, shortcuts taken
(hardcoded tenant, no auth, fake billing, seeded data, mocked provider - each with
a cite), reusable pieces, whether any production file imports `prototypes/`
(checked by Grep over the code roots; reported as run or not run).

**What a prototype cannot tell**: the hypothesis, who tested it, what they said,
the outcome and the Go / No-Go. These are `[UNVERIFIED — ask]` unless an existing
README, notes file or commit message states them (cited). Sections 11 (Usability
Feedback) and 8 (Principles Alignment) stay `none found in the source` unless the
directory holds notes; the skill never writes tester quotes. `Final
Recommendation` is the user's: the draft leaves `GO | NO-GO | PIVOT` as
`[UNVERIFIED — ask]` and records only the evidence for each.

**Tier**: tier-independent. **Sufficiency floor**: at least ~20 lines of
non-boilerplate source or a runnable artifact in the prototype directory.
