# Capacity, Lanes and Ordering

Read in Phase 1b of `/sprint-plan`. Capacity is computed **per lane**, because a
sprint with spare web days and no backend days is not feasible.

## 1. Lanes

Include only lanes the resolved `stack` contains. A lane the stack lacks is
"not applicable — [stack]", not zero capacity.

| Lane | Typical owner agents | Stories it carries |
|---|---|---|
| Contracts | `api-designer` | OpenAPI/proto change + consumer contract tests |
| Backend | `go-lead` or `ktor-lead` (+ `data-lead` for schema/cache) | Domain, use cases, adapters, migrations, jobs |
| Web | `web-lead` | SPA screens, app shell, marketing site pages |
| Mobile | `android-lead`, `ios-lead`, `kmp-specialist` | Screens, shared module, offline sync, store-bound work |
| Platform | `platform-lead`, `infra-engineer` | CI, compose bundle, self-hosted installer, observability plumbing |
| Cross-cutting | `researcher`, `appsec-engineer`, `qa-tester`, `test-automation-engineer` | Research notes, threat models, test infrastructure |

## 2. Capacity arithmetic

For each lane:

```
available = (people in lane x working days in sprint)
          - leave and holidays
          - on-call / support load
          - review time owed to other lanes (about 10% of a lead's days)
buffer    = 20% of available   (unplanned work, incidents, hotfixes)
plannable = available - buffer
```

Rules:

- Planned days (DoD-inclusive estimates) must be ≤ plannable **in every lane**. Report the lane that binds.
- A solo developer is every lane at once: capacity is one pool, but the ordering rules below still apply, and context switches between lanes cost about 10%.
- Capacity is stated in days. Where there is velocity history (`production/sprints/`, retrospectives), compare the plan to the last two sprints' completed days per lane; where there is none, write "no velocity history — plan is not calibrated" in the header and treat the plan as uncalibrated, not padded.
- Calendar lead times (provider approval, store review, legal sign-off, a `saas-core` release) are **not** capacity. They are external dependencies with a date; a story needing one that lands after the sprint end is excluded or split.

## 3. Ordering rules

1. **Contract first.** For each backend/client story consuming a new or changed API: the contract story is merged first (spec in `contracts/`, contract test in the consuming layer). A client lane may begin on a reviewed contract; it may not begin on an unwritten one.
2. **Research and threat model before the story they gate.** `docs/research/<feature>.md` (DoD gate 1) and, for security-baseline triggers, `docs/architecture/threat-models/<feature>.md` (SL-THREAT-MODEL) precede implementation. If they are not done, plan them as tasks at the head of the chain, with owners (`researcher`, `appsec-engineer` via `/threat-model`).
3. **ADRs Accepted before dependent stories.** A story governed by a `Proposed` ADR is excluded.
4. **Migrations before the code that needs them**, expand → migrate → contract across sprints when the table is hot (`.claude/rules/migrations.md`).
5. **Provider/sandbox access before integration stories.**
6. **Critical path first.** Must Have = the chain that delivers the sprint goal. Should Have = independent of the chain. Nice to Have = cut first.

## 4. DoD-inclusive estimate check

A story's estimate is acceptable only if its evidence work is in it:

| Present in the estimate? | Item |
|---|---|
| yes / no | Research note (or research-exempt reason) |
| yes / no | Tests per story type (unit, Testcontainers, contract) |
| yes / no | Observability (span, RED metrics, logs with `trace_id`) |
| yes / no | Cache decision, or the written reason for none |
| yes / no | Performance evidence vs `docs/architecture/perf-budgets.md` |
| yes / no | Security negatives + ASVS/MASVS mapping (security-sensitive stories) |
| yes / no | Run-and-observe evidence (callable/visible changes) |

A "no" without a stated reason sends the story back to `/estimate` before it is planned.

## 5. Sprint-level DoD

The Definition of Done in the plan comes from `.claude/docs/templates/sprint-plan.md`. Keep every line; add lines only for the sprint's own risks (for example "contract `X` merged by day 2"). Never remove an evidence line to make the sprint look achievable.
