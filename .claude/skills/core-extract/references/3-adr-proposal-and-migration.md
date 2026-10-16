# /core-extract — Phases 4–6: ADR, Upstream Proposal, Consume-Back Plan

> Part of `/core-extract`. Read again if the conversation was compacted.

## 1. Phase 4 — the ADR

Invoke `/architecture-decision "Add <module> to saas-core-<track>"` and pass:
the evidence file, `design.md` and the reviews (paths), the affected stack
layers and pins, and the instruction that it is a **Foundation-layer** decision
(`Domain: Core`; a core module is shared by every product). The ADR must record,
beyond the template's usual content:

- the evidence verdict and, under an exception, the exception as a Consequence;
- at least two rejected alternatives that are specific here: *keep it in the
  product*, *a shared library outside the core* (rejected by `cto.md`: "a shared
  'common' library that becomes a second core"), *per-product copies*, *buy a
  service*;
- the port boundary: what stays in the product (domain rules, catalogue values)
  and what moves;
- the other-track parity decision and its owner;
- the product-side cost: the consume-back migration (link `consume-back.md`) and
  the dependency on an unreleased core as a risk with an owner.

`/architecture-decision` runs `CTO-ADR` per `review_mode` (`full` only; lean and
solo record `CTO-ADR skipped — <mode> mode`) and sets the status. **Who moves the
ADR to `Accepted`: the user, or `cto` on the user's explicit confirmation — this
skill never edits that field.** An ADR left `Proposed` makes the verdict at best
`COMPLETE WITH GAPS`, and the consume-back stories stay Blocked until it is
Accepted (stories referencing a `Proposed` ADR are Blocked — ADR template). A
`REJECT` → `BLOCKED`. At `workflow: minimal` with no ADR files, write the
decision-log line in `design/product-brief.md` after asking, and say the ADR was
not required at this tier.

## 2. Phase 5 — the upstream proposal

Template: `.claude/docs/templates/technical-design-document.md`. Fill every
section; do not invent a parallel format. Mapping:

| Template section | Content here |
|---|---|
| Document Status | Version 1.0, date, author `principal-engineer`, reviewer, Related ADR (with its status), Related Spec (the product's, by title only if the path is private to the product), research note |
| Stack API Surface | the track, the pinned versions the module relies on (`pins.yaml` rows), APIs depended on, **Unverified Assumptions** (each blocks `Accepted` until verified), upgrade risk |
| Overview | what the module is, and a line **"Proposed by <product>; evidence: `EVIDENCED` / `CATEGORY` / exception"** |
| Requirements | functional (the port operations, as testable statements) and non-functional (latency/availability budgets from the product's `perf-budgets.md` row, if any) |
| Architecture → Public API | the ports from `design.md` §2–3 |
| Architecture → Data Model | persistence from `design.md` §9 |
| Implementation Plan | the core repo's phases: (1) port + fake + conformance suite, (2) first real adapter(s), (3) hardening: load test, security tests, docs/CHANGELOG, `/core-release` |
| Dependencies | core modules it depends on; consumers (the evidence table's products) |
| Testing Strategy | the conformance suite (design.md §4) as named cases, plus unit, integration (Testcontainers), security (cross-tenant, authz), and the cache-down/dependency-down cases where they apply |
| Operations | rollout, self-hosted impact, deprecation/versioning stance, runbook name |
| Known Limitations / Future | non-goals; other-track parity decision |

Add a short block at the top, **"Acceptance criteria for the core repo"**: a
numbered list the core repo can turn into stories (each testable; includes
"conformance suite passes on every adapter" and "CHANGELOG, deprecation entry and
release notes exist at release").

**Content hygiene (the file leaves this repo's context):** no secrets, tokens,
customer data, internal hostnames or credentials; no product-private pricing or
plan values; product code is described, not pasted, except the minimal
interface examples the design needs.

Ask: "May I write the proposal to `production/core/proposals/<module>/proposal.md`?"
Write after approval. Tell the user it is a hand-off file; this skill does not
send it.

## 3. Phase 6 — the consume-back migration plan

`consume-back.md` is the product's plan to take the module back, owned by
`principal-engineer` with the backend lead, and `data-lead` /
`migration-specialist` when the module owns persistent data. Sections:

1. **Dependency gate** — "Blocked until `saas-core-<track>` releases a tag that
   contains <module> and passes its conformance suite." The core release is an
   external dependency with an owner and a risk-register entry (name the
   register the product uses, or the decision log). No product story waits on an
   unreleased change without that entry.
2. **Interim state** — the product-local implementation stays untouched and
   in production until parity is shown. Allowed interim work: put the product's
   own port in front of the local code so the swap is one adapter; add the
   parity tests (below) against the local implementation.
3. **Cut-over steps**, each independently shippable (expand → migrate →
   contract where data is involved — `.claude/rules/migrations.md`):
   a. `/core-use <module> --version <tag>` (adds dependency, wiring, tests);
   b. run the **parity tests** — the same behaviour tests against the local
      adapter and the core adapter; they pass on both before any switch;
   c. switch the composition root to the core adapter behind a config flag where
      the risk warrants; for storage-backed modules, data migration via
      `/db-migration` and `/team-data` (backfill, dual-read window, verification
      queries, rollback);
   d. observe on the dev stack (`.claude/docs/run-and-observe.md`), then staging
      if the product has it;
   e. delete the product-local implementation **and its tests** in one change
      once the flag is retired — never leave two live implementations.
4. **Self-hosted** — config keys and bundle changes, the upgrade path for
   customers N-2, and the licence rules for any engine the module needs.
5. **Rollback** at each step.
6. **Stories** — the list for `/create-stories`, one per cut-over step, with the
   story type (Logic / Integration / Security / Config), owner lane and the
   evidence each produces; ordering: Contract → Data → Backend → Clients.
7. **Risks and open questions** with owners and dates.

Ask: "May I write the plan to `production/core/proposals/<module>/consume-back.md`?"
Write after approval.
