# /cache-design - Handoff Contract

## Role in Pipeline
DoD gate 5 evidence: the written cache decision (or the written reason for none).
Called by `/team-data`, `/team-feature`; reads `/research` (section 7),
`/design-spec` (NFR "Caching Decision"), `/perf-profile`; feeds `/create-stories`
(adapter and tests), `/dev-story`, `/code-review`, `/story-done` (PE-DOD gate 5),
`/observability-plan`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug and the data read/written hot; staleness the product accepts (from the user) | Yes | - |
| `docs/architecture/perf-budgets.md` row, source measurement (plan, metric, trace) | For the worth-it claim; absence = evidence level `none` | Yes |
| `docs/stack-reference/redis/`, `dragonfly/`, `pins.yaml` | Yes (gaps = `NOT SOURCEABLE`) | Yes |
| `project.yaml` via `resolve_config` (`stack`, `tenancy`, `distribution`, `review_mode`, `automation`, `performance.enforce`) | Yes | Yes |
| Existing designs, adapters, `deploy/` instances | When they exist | Yes |

## Preconditions
- At least one candidate entry, or a "no cache" decision to record.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. `check` mode uses the same
words.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/architecture/cache-designs/<feature>.md` | template sections; evidence level per entry; portability table for the engines in scope (hosted engine; Valkey when self-hosted or hybrid) with `NOT SOURCEABLE` cells named "verify with /research"; test list including cache-down and the engine run for each in-scope engine | written after approval; "No cache" fills Section 1 only, with numbers |
| (conversation) spec NFR one-line summary | the decision in one line | the spec is not edited by this skill |

## Output Guarantees
- Engine behaviour is cited to the stack reference or marked `NOT SOURCEABLE`; the absence of a Valkey test run is reported, not assumed.
- Tests are reported as `planned, not run`; `check` mode reports test files as existing or absent, never as passing.
- A Redis-only or engine-specific item is never approved here; it is reported and routed to an ADR.

## Immutability Rules
- No adapter or application code is written; specs and ADRs are not edited.
- `check` mode is read-only.
