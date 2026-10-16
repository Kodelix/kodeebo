# /api-contract - Phase 6: Contract-Test Plan and Record

> Phase 6 of `SKILL.md`. The tests themselves are written in stories by the
> consumers' owners; this skill plans them.

## 1. Contract-test plan

`.claude/docs/testing-standards.md`: contract tests prove backend and clients
agree on `contracts/` (OpenAPI schema validation of real responses; consumer
tests generated from the spec; runs on every PR). Plan per consumer and per
operation; test locations come from `.claude/docs/directory-structure.md` "Code
roots" (do not invent paths), and names follow the layer's convention in
`testing-standards.md` "Naming".

| Consumer | Layer / code root | What is tested | Story type |
|---|---|---|---|
| Backend (provider side) | `backend/` (Go or Ktor, per stack) | real responses (success and every declared error) validate against the schema; problem+json shape with stable `code` and `trace_id`; cursor/limit cap; idempotency replay returns the stored response, reuse with a different body 409/422; `ETag`/`If-Match` 412 | Contract |
| Web client | `web/` | the generated TypeScript client type-checks; consumer tests for the operations the app uses | Contract |
| Android / KMP | `mobile/shared/`, `mobile/android/` | generated KMP client compiles; error mapping from `code`; unknown-enum tolerance | Contract |
| iOS | `mobile/ios/` | generated Swift client compiles; error mapping; unknown-enum tolerance | Contract |
| Self-hosted / customer automation | published contract | breaking-change gate in CI against the last released contract | Contract |

Only the consumers that exist in the `stack` appear; a consumer in the stack
with no test location yet is listed as `Gap - no test location`.

**Per-endpoint security cases** (testing-standards: "Every endpoint: contract
test + authz test"): anonymous, wrong role, wrong tenant (expects 404, not
403), mass-assignment attempt (extra field rejected), oversized body, over-limit
page size, rate-limit 429 with `Retry-After`. Name each case; sensitive
surfaces carry the threat model's negative tests (`Threat model:` mitigation
IDs).

## 2. Obligations of a breaking or deprecating change

For each BREAKING row accepted via a new major or an ADR, and each deprecation:

- the `Deprecation` and `Sunset` headers on the old behaviour;
- a changelog entry (`/changelog`) and customer-facing notice (`/release-notes`);
- the minimum support window **from the product's API policy**, or "no policy
  recorded" with an owner to write one; never an invented window;
- an upgrade note for self-hosted customers (they may lag several versions);
- the ADR path and its CTO-ADR verdict (APPROVE / CONCERNS / REJECT / NOT
  ASSESSED / skipped - mode);
- the removal story, scheduled after the sunset, never in the same release.

## 3. Verdict (first match wins)

| Verdict | When |
|---|---|
| `BLOCKED` | a security item (K2, K4, K6, K7, K18-K22, K25) is `not met`; a BREAKING change has neither a new major nor an Accepted ADR; CTO-ADR returned REJECT; hand edits found in generated code |
| `NOT ASSESSED` | lint, the breaking-change diff or client generation did not run; no baseline found; an input was absent (field-case ADR unanswered, spec missing for a sensitive surface, threat model missing for one); the checklist was only partly read. Every cause is named with what closes it |
| `COMPLETE WITH GAPS` | non-security checklist items open with owners; a consumer with no test location; CTO-ADR CONCERNS; no API policy recorded for a deprecation |
| `COMPLETE` | checklist clean, lint / diff / generation ran and are clean, no unresolved BREAKING, test plan covers every consumer in the stack |

`NOT ASSESSED` ranks above `COMPLETE` and below `BLOCKED`.

## 4. Present, ask, write

Present: the proposal summary, checklist result, tooling table, the BREAKING
table, the test plan and the verdict. Then ask: "May I write the contract-change
record to `production/qa/evidence/<STORY-ID>/contract-change.md`?" (when a story
ID is known; otherwise `production/qa/contract-change-<service>-<date>.md`).
Write only after approval; the record holds the checklist result, tooling
table (commands, exit codes, trimmed output or `not run - reason`), the BREAKING
table, the plan and the verdict. Verify it exists before reporting it written.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/api-contract <service>
<feature> — <verdict>`, Next step = the first Recommended Next Step for that
verdict (`/create-stories` when approved; for `BLOCKED` / `NOT ASSESSED` the
step that clears the cause), plus Blocked on / Files in progress / Open
questions; append the Notes line. Still updated when the verdict is `BLOCKED` /
`NOT ASSESSED` or the user declines the write (record nothing written and why).

## 5. Report

```text
Contract: <service> <feature>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED | BLOCKED
Designed by: api-designer | this session (reason)   Baseline: <tag | none>
Operations: N added, N changed, N removed   BREAKING: N (route: new major | ADR <id> | none)
Checklist (review, not a lint): met N / not met N / n/a N / not assessed N
Tooling: lint <ran|not run - reason>; diff <ran|not run - reason>; manual diff <N changes>;
         clients TS <...> KMP <...> Swift <...>
CTO-ADR: APPROVE | CONCERNS | REJECT | NOT ASSESSED | skipped - <mode> mode | not applicable
Contract tests planned: N consumers, N cases; gaps: <list>
NOT ASSESSED / BLOCKED causes: <each, with what closes it>
Written: contracts/... , <record path | not written>
```
