# /team-api — Phases 5–6: Verification, Docs, Report

> Part of `/team-api`. Read again if the conversation was compacted.

## 1. Phase 5 — verification

Commands come from the `layer-checks.md` lookup table in the `dev-story` skill
folder (`.claude/skills/dev-story/`) and from the repo's own scripts; Gradle task
names and `package.json` scripts are confirmed in the build files first. Report each
cell `passed` / `FAILED` / `not run — <reason>`:

| Check | Per | Notes |
|---|---|---|
| Lint of the contract | contract | the tool the repo defines; not defined → `not run — tooling not in the stack reference and not set up in this repository` |
| Breaking-change diff against the last released contract | contract | tool output; absent tool → the manual diff from `/api-contract`, labelled as such |
| Generated clients up to date (regenerate, then no diff) | TS / KMP / Swift | only via the generator |
| Contract tests: real responses validate against the schema (success and each declared error) | backend | `testing-standards.md`; Testcontainers for dependencies, never a mocked database |
| Consumer contract tests / client type-check | web, KMP, Android, iOS | the lane's own commands |
| **Authz tests per operation**: anonymous, wrong role, **wrong tenant → 404 not 403**, mass-assignment (extra field rejected), oversize body, over-limit page size, rate-limit 429 with `Retry-After`, idempotency replay and key-reuse with a different body | backend | the threat model's negative tests for sensitive surfaces; **never waived at `qa.level: minimal`** |
| Old client × new server for each deprecated operation | backend + the old generated client | proves the deprecation path |
| Unit/integration suites of each lane | each | existing tests must stay green; none disabled |

At `small` and above, spawn `test-automation-engineer` for the contract-test and
authz gaps the plan lists (named path `production/api/<slug>/contract-tests.md`;
it adds tests, never weakens or skips one). At `individual` the **backend lead**
writes the same `contract-tests.md` (the tests it added and their results); nobody
else is spawned for it. At `studio`, `appsec-engineer` reviews
the operations against the API Top 10 items in `security-baseline.md` (named path
`review-appsec-engineer.md`), with the adversarial instruction. Spawn these in
parallel with the checks above. A `FAILED` cell is shown with its output and not
auto-fixed: send it back to the lead, or stop.

## 2. Phase 5 — run and observe

`.claude/docs/run-and-observe.md`. The backend lead (or `test-automation-engineer`) brings up the dev stack (never
production; staging only if the user names it explicitly; never real customer data). For **each changed operation**: call it as
each relevant role, plus the negative paths (no token, wrong role, other tenant),
and retain request/response with secrets redacted and one trace
(`trace_id` in the error body and the `traceparent` header) in
`production/qa/evidence/<STORY-ID>/` (or `production/qa/evidence/api-<slug>/`).
For a deprecated operation, capture the `Deprecation` and `Sunset` response
headers. A screenshot or capture that was not retained is an assertion, not
evidence. If the stack will not come up, that is the finding: capture the logs
and report `run-and-observe: not run — <reason>`, which caps the verdict at
`NOT ASSESSED`.

## 3. Phase 6 — docs and notice (drafts)

- `/changelog` entry and, for a public or deprecating change, `/release-notes`
  (API & Integration Changes: Added / Deprecated with sunset / Removed-Breaking
  with migration steps). `technical-writer` updates the API docs from the contract
  (active at `small`+).
- Published notices (release notes, customer email, status banner) are **external
  publication**: not done here; the drafts are the output. Ask whether to proceed
  to the publishing step, and if yes name the exact action first.

## 4. Report and checkpoint

Ask: "May I write the report to `production/api/<slug>/team-api-report.md`?" Then
update `production/session-state/active.md` after every gate and at the end (the
checkpoint — exempt from the prompt; replace this pipeline's own block, do not
append history; `## Studio flow` belongs to `/studio` alone, and the `Flow:` line
below names the running flow):

```markdown
## API pipeline — <slug>
**Goal:** <one sentence>
**Flow:** api-change (team-api)   **Started:** <date>
**Step:** <n>/6 — <phase name>   **Waiting on:** <gate or nothing>
**Artifacts:** <paths, newest first>
**Skipped:** <step — reason>
**Blockers:** <list or none>
**Next:** <exact command, e.g. `/story-done production/epics/billing/story-004.md`>
```

**Checkpoint.** The same update follows `.claude/docs/checkpoint-handoff.md`:
also overwrite `Current task` (`/team-api <slug> — <verdict>`), `Next step` (the
block's **Next:** command), `Blocked on`, `Files in progress` and `Open
questions` in the `<!-- CHECKPOINT -->` block and append the Notes line; leave
the `Flow:` line to `/studio` and other skills' blocks alone. Still updated when
the run ends BLOCKED or the report write is declined.

End with: what was done (paths); what was not done and why; the classification and
route; the deprecation timeline (dates and owners) if any; **Not run / not
checked** (external consumers not enumerable, tools not defined, generators
absent, stacks unset); the next command.
