# /uat — Phase 4 and 5: Sessions and Defect Intake

> Part of `/uat`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. Before a session

- Re-check the build identity against the plan header. A mismatch stops the
  session until the plan records the new build and the invalidated scenarios.
- Produce a **script sheet** per role from the approved plan: starting state,
  numbered steps, the observable expected result, English and Arabic versions.
  Nothing in the sheet leads the participant ("you should see…" is the facilitator's
  reference, not read aloud).
- The seeded tenant and users are ready; credentials are given to participants
  through the channel the user uses — never written in the plan or the results.

## 2. During a session

Facilitation is human. The skill's job is to record faithfully.

- **Observe without leading.** Note what the participant did and said; do not
  help unless they are stuck, and then record that they needed help.
- Capture for each scenario: participant ID and role, language/direction, start
  state, what happened, time to complete if relevant, any confusion, a screenshot
  or recording path under `production/qa/evidence/[release]/` for failures and
  for the key screens.
- **Quotes** are recorded verbatim only when the user supplies them from the
  session, with the participant's role attached. They are never invented,
  paraphrased as quotes, or reused from another product.

## 3. Recording results

Per batch of 3–4 scenarios, `AskUserQuestion`:

```
question: "UAT — [scenario IDs and titles], participant [P-ID], [EN|AR]"
options:
  - "PASS — the participant completed it and the result matched"
  - "FAIL — result did not match (describe after)"
  - "BLOCKED — could not run (reason, who owns it)"
  - "NOT RUN — not attempted (reason)"
```

Record the answer and the description exactly as given. A scenario nobody
answered stays `NOT RUN`. The result set per scenario is `PASS`, `FAIL (defect
ID)`, `BLOCKED (reason)`, `NOT RUN (reason)`; the counts must add up to the
scenario total.

Each must-have scenario is run in **English and Arabic**; a scenario run in one
language only is recorded as such, and the missing pass is `NOT RUN`.

## 4. Defect intake

For each FAIL:

1. Run `/bug-report` with: ID (allocated by that skill), build, environment,
   tenant and role, numbered steps, expected, actual, screenshot or recording,
   **language and direction**, and a **severity proposal that quotes the S1–S4
   rule** matched (the table lives in `/bug-report`). The final severity is
   `qa-lead`'s; spawn `qa-lead` via `Agent` to classify when several defects
   arrive together — pass the bug files, ask for the S1–S4 classification only.
2. **Suspected cross-tenant exposure, data loss, payment or licence failure** is
   S1: tell the user at once, route to `security-lead` through `qa-lead`, and
   keep detail out of shared places.
3. Link the defect to the scenario row in the results.
4. **Retest** is by the reporter or `qa-tester`, with the evidence attached;
   the coordinator does not retest and close. A fix means a new build — Phase 3's
   invalidation rule applies.
5. An open S1/S2 is escalated to `qa-lead` and the user; only they waive, in
   writing. "The date is fixed" is not a waiver.

## 5. `uat-results.md`

`production/qa/evidence/[release]/uat-results.md`:

```markdown
# UAT Results: [release] — [date range]
**Build**: [hash/tag] · **Environment**: [..] · **Seed version**: [..]

| Scenario | Criterion | Role | Participant | Lang | Result | Defect | Evidence |
|---|---|---|---|---|---|---|---|

## Counts
Total [N] · PASS [n] · FAIL [n] · BLOCKED [n] · NOT RUN [n]   (sum = N)

## Sessions
| # | Date (UTC) | Participants (IDs, roles) | Scenarios | Facilitator | Notes |

## Quotes (verbatim, from real sessions, role attached)
[none | list]

## Invalidated by rebuilds
[scenarios returned to NOT RUN, with the build change]
```
