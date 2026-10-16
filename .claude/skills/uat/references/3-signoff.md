# /uat — Phase 6: Exit Criteria, Verdict and Sign-off

> Part of `/uat`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. Evaluate the exit criteria

For each criterion in the approved plan: **target vs actual**, from
`uat-results.md` and the bug files (`production/qa/bugs/`), and whether it was
met. Do not restate a criterion in softer words. Open defects are listed with ID,
severity, owner and target release if any.

## 2. Derive the UAT result

First matching rule wins:

1. **NOT READY** — an exit criterion numerically failed; any must-have scenario
   FAILED; an S1 or S2 defect is open (including one raised before UAT that
   touches an in-scope story).
2. **NOT ASSESSED** — nothing above applies, but: a must-have scenario is `NOT RUN`
   or `BLOCKED`; the environment was not the release candidate or its health was
   not confirmed; a required Arabic pass was not run; a required self-hosted
   scenario was not executed; the participants required by the plan did not take
   part; the Arabic scripts were never reviewed and an Arabic scenario depended on
   them. List each cause and what closes it.
3. **READY FOR SIGN-OFF** — every exit criterion met with the evidence on disk,
   open items (S3/S4) each with an owner and a target release.

`READY FOR SIGN-OFF` is not acceptance. It means the approver has what they need
to decide.

## 3. The sign-off record

Spawn `uat-coordinator` via `Agent` to draft it, with the results file path, the
plan path, the exit-criteria evaluation and the verdict rules above verbatim — do
not name a verdict or pre-fill the decision lines. Return contract: write to
`production/qa/evidence/[release]/uat-signoff.md` (that named path is its write
authorisation), return the path and a ≤5-bullet summary. Format (from
`uat-coordinator.md`):

```markdown
## Release / build / environment / seed version
## Scope: covered | not covered
## Results: | Scenario | Criterion | Role | Lang | Result | Defect |
## Exit criteria: target vs actual
## Open items accepted: ID, severity, owner, target release
## Approvals: name, role, date, decision (ACCEPT | ACCEPT WITH OPEN ITEMS | REJECT)
## UAT result: READY FOR SIGN-OFF | NOT READY | NOT ASSESSED — [causes]
```

Check the draft against the rules in this file and read it back. If it disagrees
with the evidence (a verdict that outranks the facts, a pre-ticked approval,
open items accepted that nobody accepted), show both and ask — never silently
substitute your own.

## 4. Approvals — the approver's words only

- A sign-off is given by a person **with authority to accept for the business**:
  the user, or a delegate the user names in this conversation. UAT participants
  are not approvers.
- Present the scope, results, exit-criteria evaluation and open items to the
  approver, then ask (`AskUserQuestion`): `ACCEPT` / `ACCEPT WITH OPEN ITEMS
  (list)` / `REJECT (reason)` / `Not yet`.
- Write the approver's name, role, date and decision **as given**. "Open items
  accepted" lists only those the approver accepted, each with owner and target
  release.
- No decision given in this conversation → the rows read `PENDING`; the record is
  still written so the release gate sees an honest state.
- `ACCEPT` while the UAT result is `NOT READY` or `NOT ASSESSED` is allowed only
  as the user's explicit override: record it as `ACCEPT (override of [result])`
  with the named risk and the owner — the verdict line itself is unchanged.

## 5. After the write

- Append to `production/session-state/active.md`:
  `<!-- UAT: [date] | Release: [id] | Result: [..] | Sign-off: [ACCEPT|ACCEPT WITH OPEN ITEMS|REJECT|PENDING] | Record: production/qa/evidence/[release]/uat-signoff.md -->`
- Update the checkpoint in `production/session-state/active.md` per
  `.claude/docs/checkpoint-handoff.md`: Current task `/uat <release> — <result>,
  sign-off <decision>`, Next step = the "Next:" item below, plus Blocked on (a
  `PENDING` approval, a REJECT) / Files in progress / Open questions; append the
  Notes line; leave the `Flow:` line and other blocks alone. Still updated when
  the write was declined or the result is NOT ASSESSED.
- A rebuild after sign-off voids it for the scenarios the diff touches; the next
  `/uat run` lists them.
- Next: `/team-qa release` and `/release-checklist` consume the record; open
  items accepted go to `/bug-triage` with their target release.
