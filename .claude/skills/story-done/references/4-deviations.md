# /story-done — Phases 4, 4b and 4c: Deviations, QA Coverage Gate, Tenant-Isolation Gate

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Check for Deviations

Compare the implementation against the design documents.

> **Workflow tier adjustment** (resolved in Phase 1, per the story's feature).
> Checks 1 (spec rules) and 3 (ADR constraints) below are the `full` baseline:
> - **`full`** — run both: full spec traceability against the current TR text +
>   the ADR constraints check.
> - **`standard`** — run the spec rules check against the **5 required sections**;
>   run the ADR constraints check only where a **critical ADR** governs the story.
> - **`minimal`** — **acceptance-criteria check only** for spec/ADR traceability:
>   skip checks 1 and 3 (no spec/ADR traceability expected; `design/product-brief.md`
>   and its decision log stand in). Checks 2 (manifest), 4 (hardcoded values), 5
>   (scope), 6 (research note) and 7 (tenancy and secrets) **still run as written**
>   — tiers scale documents, never engineering.
>
> This adjustment governs only the Phase 4 *deviation* checks. The evidence gates
> (Phase 3, Phase 4b, Phase 6) are governed by `qa.level`, `testing.strict`,
> `performance.enforce`, and the eight DoD gates — they run independently of the
> tier here.

Run these checks automatically:

1. **Spec rules check**: Using the current requirement text from `tr-registry.yaml`
   (looked up by the story's TR-ID), check that the implementation reflects what
   the spec actually requires now — not what it required when the story was written.
   `Grep` the implemented files for key function names, types, ports or endpoints
   mentioned in the current spec section.

2. **Manifest version staleness check**: Compare the `Manifest Version:` date
   embedded in the story header against the `Manifest Version:` date in the
   current `docs/architecture/control-manifest.md` header.
   - If they match → pass silently.
   - If the story's version is older → flag as ADVISORY:
     `ADVISORY: Story was written against manifest v[story-date]; current manifest
     is v[current-date]. New rules may apply. Run /story-readiness to check.`
   - If the story carries a `Manifest-Note:` (set by `/dev-story`), include it in
     the deviations section without re-checking staleness.
   - If control-manifest.md does not exist → skip this check and say so.

3. **ADR constraints check**: Use the ADR's `## Decision` section already loaded in
   Phase 2 — do not read the ADR file again. Check for forbidden patterns from
   `docs/architecture/control-manifest.md` (if it exists) and the layer rules in
   `.claude/rules/`. `Grep` for patterns explicitly forbidden. Also `Grep` the
   implementation for entries in `docs/stack-reference/<layer>/deprecated-apis.md`
   (a deprecated API used without an ADR exception is a deviation; if the layer's
   reference is missing, record `deprecated-API scan: NOT ASSESSED — no stack reference`).

4. **Hardcoded values check**: `Grep` the implemented files for prices, limits,
   quotas, TTLs, timeouts, retry counts and flags that should be configuration
   (already begun in Phase 3 — reuse its hits, do not re-scan).

5. **Scope check**: Did the implementation touch files outside the story's stated
   scope? (files not listed in "files to create/modify"; compare against
   `git diff --name-only <base>` when the base is known.) Touching `saas-core-*`
   from a product repo, or CI/deploy files outside the story's lane, is always
   flagged.

6. **Research-note consistency**: does the implementation contradict the research
   note's Decision (a different provider, library or pattern than the note chose)?
   If yes, the note must be updated first (`research-protocol.md`) — flag
   ADVISORY, BLOCKING if the contradiction changes a security-relevant choice.

7. **Tenancy and secrets spot check** (cheap greps; `/code-review` and Phase 4c
   do the deep review): any new query without a tenant predicate in a
   tenant-owned table's repository; a tenant read from the request body/path in a
   handler; a stack trace or raw error text in an HTTP response path; a secret or
   token in a log call. A hit is BLOCKING pending review.

For each deviation found, categorize:

- **BLOCKING** — implementation contradicts the spec, an ADR, a threat-model
  mitigation or a security rule (must fix before marking complete)
- **ADVISORY** — implementation drifts slightly from spec but is functionally
  equivalent (document, user decides)
- **OUT OF SCOPE** — additional files were touched beyond the story's stated
  boundary (flag for awareness — may be valid or scope creep)

---

## Phase 4b: QA Coverage Gate

**`qa.level` does not skip this phase** — tests are required at every tier, so their
coverage is reviewed at every tier (the review-mode check below still decides whether the
QL-TEST-COVERAGE director is spawned). **Skip for a Config story** (no code tests) with
the note "QL-TEST-COVERAGE skipped — Config story." and proceed to Phase 4c.

**Review mode check** — apply before spawning QL-TEST-COVERAGE:
- `solo` → skip. Note: "QL-TEST-COVERAGE skipped — Solo mode." Proceed to Phase 4c.
- `lean` → skip (not a PHASE-GATE). Note: "QL-TEST-COVERAGE skipped — Lean mode." Proceed to Phase 4c.
- `full` → spawn as normal.

> **A skipped QL-TEST-COVERAGE does not skip the checking.** Phase 3 already
> mapped criteria to tests and established the pass/fail/not-run state, and
> Phase 6 re-derives DoD gate 3 from that evidence. Only the qa-lead's opinion on
> *adequacy* is absent; the report records it as skipped, never as ADEQUATE.

After completing the deviation checks in Phase 4, spawn `qa-lead` via `Agent` using gate **QL-TEST-COVERAGE** (`.claude/docs/director-gates/ql-test-coverage.md`).

Pass:
- The story file path and story type
- Test file paths found during Phase 3 (exact paths, or "none found") and the test-result classification per layer (`passed` / `FAILED` / `not run` / `stale`) with the output files
- The evidence directory `production/qa/evidence/<STORY-ID>/`
- The story's `## QA Test Cases` and `## Acceptance Criteria`
- The spec acceptance criteria and Edge Cases & Failure Modes for the feature, from the spec section read in Phase 2 — or "no spec for this feature" when there is none (at `workflow: minimal` the story's own criteria are the spec); an absent spec is information for the gate, not a missing input
- Gate levels resolved from `testing.strict.*` and `performance.enforce`

The qa-lead reviews whether the tests actually cover what was specified — not
just whether files exist.

Apply the verdict:
- **ADEQUATE** → proceed to Phase 4c
- **GAPS** → flag as **ADVISORY**: "QA lead identified coverage gaps: [list]. Story can complete but gaps should be addressed in a follow-up story."
- **INADEQUATE** → flag as **BLOCKING**: "QA lead: critical logic is untested. Verdict cannot be COMPLETE until coverage improves. Specific gaps: [list]."
- **NOT ASSESSED [missing input]** → no judgement was made; never read it as ADEQUATE. Name the missing input — supply it and re-run the gate, or carry it to Phase 7, where it keeps the verdict at best NOT ASSESSED.

Record the verdict in the story's header in Phase 8 (`director-gates.md` → Recording Gate Outcomes).

---

## Phase 4c: Tenant-Isolation Gate

**Applies only when the story reads or writes tenant-owned data** — a new table,
collection, cache key family, queue, file prefix, search index or endpoint.
Determine from the story's code root, its migrations and its Implementation
Notes; borderline → applies. Otherwise note "SL-TENANT-ISOLATION not applicable —
no tenant-owned data touched" and proceed to Phase 5. `tenancy.model:
single-tenant` → the gate is recorded `not applicable — single-tenant` with the
reason.

**Review mode check** — apply before spawning SL-TENANT-ISOLATION:
- `solo` / `lean` → skip. Note: "SL-TENANT-ISOLATION skipped — [mode] mode." **The check itself is not skipped**: the isolation evidence is a DoD gate 7 row in Phase 6 (negative tests exist and passed; every query scoped) and is checked there from Phase 3 and Phase 4 check 7.
- `full` → spawn `security-lead` via `Agent` using gate **SL-TENANT-ISOLATION** (`.claude/docs/director-gates/sl-tenant-isolation.md`).

Pass the context that gate lists: the story and spec paths; code paths for the
repositories/adapters, use cases and HTTP handlers touched, per code root; the
migration paths (RLS policies, schema or database provisioning); test paths and
`production/qa/evidence/<STORY-ID>/` negative-test results (with their
passed/not-run state from Phase 3); `tenancy.model`; the threat model path.

Apply the verdict:
- **APPROVE** → proceed.
- **CONCERNS [gaps]** → ADVISORY findings carried to the report; surface via `AskUserQuestion` (`Fix first` / `Accept and proceed` / `Discuss further`).
- **REJECT** → **BLOCKING**: a path exists by which one tenant can reach another tenant's data, or the proof is missing. Never closed by this skill without the explicit close-anyway override (Phase 8), which for a cross-tenant finding also requires notifying `security-lead`.
- **NOT ASSESSED [missing input]** (e.g. `tenancy.model` unset, negative tests not run) → name the input; the verdict stays at best NOT ASSESSED.

---
