# /create-stories — Step 6: Story File Format

> Part of `/create-stories`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 6. Write Story Files

For each story, write `production/epics/[epic-slug]/story-[NNN]-[slug].md`. Never reuse an `NNN`
already in the directory. The **Story ID** is `[EPIC-SLUG-UPPER]-[NNN]` (for example `BILLING-003`) —
the commit-body reference (`Story: BILLING-003`) and the evidence directory name
(`production/qa/evidence/BILLING-003/`).

> **At `minimal` tier the Context/traceability inputs do not exist** (no spec, ADR,
> TR registry, or control manifest). Fill the template from the brief instead —
> apply this mapping exactly, so every run is deterministic rather than improvised:
> - **Spec** → `design/product-brief.md`
> - **Requirement** → `Brief MVP feature N` (the feature this story implements — NOT a `TR-[feature]-NNN` ID)
> - **ADR Governing Implementation / ADR Decision Summary / ADR Version** → `N/A (minimal — no ADRs)`; decisions are in the brief's decision log
> - **Manifest Version** and **Control Manifest Rules (this layer)** → `N/A (minimal — no control manifest)`
> - **Stack** and **Risk** → read `docs/stack-reference/<layer>/VERSION.md` for the
>   story's code root (layer from `stack.*`). **Stack** is the layer + pinned version
>   from `pins.yaml`. **Risk** is the risk level that file assigns to the pinned
>   version. If the file is missing or assigns no level, write
>   `NOT ASSESSED (no stack-reference risk rating)` — never guess a level.
>
>   > **This field is load-bearing and must not be improvised.** `/dev-story`
>   > treats a HIGH stack risk as the trigger for a mandatory stack-lead review.
>   > At `minimal` there is no ADR, so the stack reference is the *only* source —
>   > a story written with an invented `Risk: MEDIUM` against a rating of HIGH
>   > silently disables that review. Treat `NOT ASSESSED` as HIGH for the review
>   > decision: an unknown risk is not a low one.
> - **Stack Notes** → `none (no ADR stack-compatibility analysis at minimal)`
> - The Acceptance-Criteria source line → "From `design/product-brief.md` (the MVP feature this story implements and its acceptance notes), scoped to this story" — derive concrete, testable ACs from what the user wrote there rather than inventing them from a bare MVP bullet; the mandatory standard criteria of Step 4c still apply and are labelled
> - The **`## QA Test Cases`** section → at any tier where the QL-STORY-READY / qa-lead gate is skipped (`minimal`, or `lean`/`solo` review mode) no qa-lead specs are authored; write "*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*" rather than improvising test cases.
> - The **Definition of Done evidence** table is **not** relaxed at `minimal`: the eight gates apply at every tier (`workflow-modes.md`). Only the *record* of decisions moves from ADR files to the brief's decision log. The test rows are not waived at `qa.level: minimal` either: Logic, Integration, Contract and Security tests exist and pass at every tier, and so do the security rows, the run-and-observe row and a UI story's retained screenshot. `qa.level` only changes the *extra* evidence asked for.

```markdown
# Story [NNN]: [title]

> **Story ID**: [EPIC-SLUG-UPPER]-[NNN]
> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Code root**: [backend/ | web/ | mobile/shared | mobile/android | mobile/ios | contracts/ | deploy/]
> **Type**: [Logic | Integration | Contract | Security | Performance | UI | Config]
> **Owner agent**: [go-lead | ktor-lead | web-lead | android-lead | ios-lead | kmp-specialist | api-designer | data-lead | platform-lead | ... — with supporting specialists]
> **Estimate**: [hours or t-shirt size — fill before sprint planning]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**Spec**: `design/specs/[filename].md`
**Requirement**: `TR-[feature]-NNN`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**Research note**: `docs/research/[feature].md` — [present | MISSING — run `/research [feature]` before implementation]
**Threat model**: `docs/architecture/threat-models/[feature].md` — [present | MISSING — run `/threat-model [feature]` | not required: [reason]]
**Contract**: `contracts/openapi/[service].yaml` — [story NNN authors it | existing, unchanged | n/a — [reason]]

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary of what the ADR decided]
**ADR Version**: [the ADR's `## Last Verified` date, else its `## Date`, else `unversioned`]

**Stack**: [layer + pinned version] | **Risk**: [LOW / MEDIUM / HIGH / NOT ASSESSED (no stack-reference risk rating)]
**Stack Notes**: [from ADR Stack Compatibility section — post-cutoff APIs, verification required; deprecated-apis.md entries to avoid]
**Editions**: [hosted | hosted + self-hosted — and the licence rule that binds this story, if any]

**Control Manifest Rules (this layer and context)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]

---

## Acceptance Criteria

*From spec `design/specs/[filename].md`, scoped to this story. Criteria added by the studio standards are labelled with their source:*

- [ ] [criterion 1 — directly from the spec]
- [ ] [criterion 2]
- [ ] [negative criterion — other tenant's resource returns 404, no data leaked] `[standard: security-baseline.md]`
- [ ] [negative criterion — wrong role returns 403; anonymous 401] `[standard: testing-standards.md]`
- [ ] [performance criterion if applicable — p95 / queries per request from perf-budgets.md]
- [ ] [OPEN — spec does not say [what]; resolve before implementation]  *(only when applicable)*

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance from the ADR: which context, which layer of `domain` / `app` / `adapters`, which ports, what must never be imported where. Do not paraphrase in ways that change meaning. This is what the engineer reads instead of the ADR.]

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story NNN+1]: [what it handles]

---

## QA Test Cases

*Written by qa-lead at story creation. The engineer implements against these — do not invent new test cases during implementation. (At tiers where the QL-STORY-READY gate is skipped — `minimal`, or `lean`/`solo` review mode — no qa-lead specs exist; see the `minimal` mapping note above.)*

**[For Logic / Integration / Contract / Security stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition — tenant, role]
  - When: [action]
  - Then: [assertion]
  - Negative: [wrong role / other tenant / invalid input / replay]
  - Edge cases: [boundary values / failure states]

**[For UI stories — manual verification steps]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state — role, tenant, locale (AR/RTL and EN)]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]

---

## Definition of Done Evidence

*All eight gates apply (`.claude/docs/coding-standards.md`). Each row is met with the evidence below, or waived with a written reason in this file. `/story-done` checks every row.*

| # | Gate | Evidence this story must produce | Status |
|---|------|----------------------------------|--------|
| 1 | Research first | `docs/research/[feature].md` linked above; contradicted-by-implementation → update the note first | [ ] |
| 2 | Clean architecture | Domain imports no framework/DB/HTTP; ports at the boundary — [ports this story adds/uses]; no cross-context table reads | [ ] |
| 3 | Tests | [by type — see Test Evidence below, incl. tenant-isolation and negative tests] | [ ] |
| 4 | Observability | Span(s) [names], RED metrics, structured logs with `trace_id`, no PII; [alerts/runbook if any] | [ ] |
| 5 | Caching | Cache decision: [pattern, key schema with tenant ID, TTL, invalidation, stampede protection] — or "no cache: [reason]" | [ ] |
| 6 | Performance | Budget: [row from `docs/architecture/perf-budgets.md` — p95, queries/request, payload | `budget not yet set`]; no N+1; load test if Performance type — `performance.enforce` = [warn/block] | [ ] |
| 7 | Security | ASVS [IDs] / MASVS [IDs] (looked up in the official documents, not recalled); tenant-isolation test; threat model [link / n/a]; dependency scan clean | [ ] |
| 8 | Decision record | ADR for any architectural decision this story makes: [none expected | ADR needed: title] | [ ] |
| — | Run and observe | The endpoint called / screen opened against a running stack as owner, member, other tenant and anonymous (UI: AR/RTL + EN); retained in `production/qa/evidence/[STORY-ID]/` | [ ] |

---

## Test Evidence

*Logic, Integration, Contract and Security tests are BLOCKING at every tier — they exist and pass (`coding-standards.md`). `qa.level` changes only the extra evidence (manual cases, coverage signal, UAT); `testing.strict.*` may only make the other types stricter. Security evidence, the run-and-observe record and a UI story's retained screenshot are never waived.*

**Story Type**: [type] — **Gate level**: [BLOCKING | ADVISORY] (from `testing.strict.[type]` else the `coding-standards.md` default)
**Required evidence**:
- Logic: unit tests beside the code in `[code root test location per directory-structure.md]` — must exist and pass at every tier
- Integration: Testcontainers integration test against the real store/provider sandbox — `[path]`
- Contract: consumer contract test against `contracts/[file]` + breaking-change check output — `[path]`
- Security: negative tests (authz bypass, cross-tenant, injection, rate limit as applicable) + ASVS/MASVS mapping in `production/qa/evidence/[STORY-ID]/`
- Performance: load-test result vs the `perf-budgets.md` row in `production/qa/evidence/[STORY-ID]/` (ADVISORY unless `performance.enforce: block`)
- UI: retained screenshot of every screen touched (AR/RTL + EN) + `/impeccable audit` result in `production/qa/evidence/[STORY-ID]/`
- Config: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [Contract story NNN (contract first), Story NNN-1 must be DONE, or "None"]
- Unlocks: [Story NNN+1, or "None"]
- Needs before sprint: [`/research [feature]` | `/threat-model [feature]` | ADR acceptance — or "None"]
```

### Also update `production/epics/[epic-slug]/EPIC.md`

At `minimal` with no `EPIC.md` yet, this is where the Step 2 draft is written, with the
table below. Otherwise replace the "Stories: Not yet created" line with a
populated table; if the table already exists (a return visit), append a row per
new story and leave the existing rows as they are:

```markdown
## Stories

| # | Story ID | Story | Type | Code root | Owner | Status | ADR |
|---|----------|-------|------|-----------|-------|--------|-----|
| 001 | BILLING-001 | [title] | Contract | contracts/ | api-designer | Ready | ADR-NNNN |
| 002 | BILLING-002 | [title] | Logic | backend/ | go-lead | Ready | ADR-MMMM |
```

### Also update `production/epics/index.md`

Find the row in the index table matching this epic (by epic name or slug). Set its `Stories` column to `[N] stories`, where N is the epic's total story count after this run — the existing rows plus the ones just written, not only the new ones. If the index file does not exist, say so in one line — `Epics index not updated: production/epics/index.md absent` — and continue. Do not skip silently: the index is what a reader consults to learn which epics have stories, so an un-updated one keeps reporting `Not yet created` for work that now exists, and nothing else would ever reveal the gap.
