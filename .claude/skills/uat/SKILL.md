---
name: uat
description: "User acceptance testing for a release: a UAT plan built from the specs' acceptance criteria in business language (Arabic and English), the release-candidate environment with seeded tenants, scripts per role, facilitated sessions, defect intake through /bug-report, and a sign-off record that says who accepted what. Participants' feedback is never acceptance."
argument-hint: "[plan | run | signoff] [release-id] [--env <named staging>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Agent, AskUserQuestion, Bash(git diff *), Bash(git log *), Bash(date *), Bash(bash "*/.claude/skills/uat/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,accessibility,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`. **Scenario results,
participants' words and the approver's decision are never filled in by any mode**:
they are recorded only from what was said in this conversation.

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

**`workflow` and `qa.level` do not make UAT optional or lighter once it is in
scope.** Whether a release *needs* UAT is decided in Phase 1 and recorded either
as required or as `not required — [reason]`; it is never silently absent.

# UAT

Gets the release in front of the people who will use and buy it, proves **in
their words** that it does what was promised, and leaves a sign-off record that
states exactly who accepted what, when, with which open items. The plan, scripts
and records are prepared by `uat-coordinator`; the sessions are run by people;
the acceptance is the business approver's.

**Output**
- `production/qa/uat-plan-[release].md` — plan, scenarios, scripts, environment, exit criteria
- `production/qa/evidence/[release]/uat-results.md` — results per scenario and the session log
- `production/qa/evidence/[release]/uat-signoff.md` — the sign-off record (path read by `/team-qa`, `/release-checklist` and the workflow catalog)
- `production/qa/bugs/BUG-[NNNN].md` for each defect, through `/bug-report`

> **A UAT sign-off asserts acceptance by a person with authority; this skill
> cannot supply it.** Approval rows stay `PENDING` unless the approver gave a
> decision in this conversation. A participant's "looks fine" is feedback, a
> verbal sign-off is no sign-off, and a quote that did not come from a real
> session is fabricated. A scenario nobody ran is `NOT RUN`, not passed.

> **Verdicts (UAT result):** `READY FOR SIGN-OFF` / `NOT READY` / `NOT ASSESSED`.
> Precedence: `NOT READY`, then `NOT ASSESSED`, then `READY FOR SIGN-OFF`.
> `NOT READY`: an exit criterion numerically failed, a must-have scenario FAILED,
> or an S1/S2 defect is open. `NOT ASSESSED`: a must-have scenario is `NOT RUN` or
> `BLOCKED`, the environment is not the release candidate, the Arabic pass was not
> run, or a self-hosted scenario was not executed — it outranks `READY` and ranks
> below `NOT READY` (a known failure is more actionable than a session that never
> happened). **Sign-off status** is separate and is the approver's, not the
> skill's: `ACCEPT` / `ACCEPT WITH OPEN ITEMS` / `REJECT` / `PENDING`.
> Two more closing words, never a pass: `BLOCKED — [what is needed]` (a missing
> prerequisite, e.g. no release id and none can be inferred) and
> `BLOCKED — write declined by user` (a declined plan or results/sign-off write;
> nothing is then reported as recorded, and the release gate sees no record).

---

## Phase 1: Release, Scope and Whether UAT Is Required

1. **Release.** Resolve `[release-id]` against the release record
   (`production/releases/`, from `release-manager`) and read it: build/tag,
   editions shipping (hosted, self-hosted bundle, Android, iOS, web), the
   upgrade-from versions for self-hosted, the stories shipped. No release record →
   `NOT ASSESSED — no release record`; ask which stories and editions.
2. **Is UAT required?** From the release checklist and `design/product-brief.md`.
   Unknown → ask (`AskUserQuestion`): required / not required (reason). Record
   `not required — [reason]` and stop if the user says so, closing with
   `NOT ASSESSED — UAT not required ([reason])`: the release gate reads that as a
   recorded decision, never as a UAT pass.
3. **Inputs, each FOUND or ABSENT:** specs and their acceptance criteria
   (`design/specs/`), personas and plans (`design/product-brief.md`,
   `design/specs/pricing-model.md`), the QA plan and automated coverage
   (`production/qa/`, `.claude/docs/testing-standards.md` — UAT does not repeat
   what tests already cover), open bugs (`production/qa/bugs/`), seed data
   (`tools/seed/`), localization policy (`design/localization/`). An absent
   criterion for a shipped feature is a gap reported to `product-manager`.
4. **Mode.** `plan` / `run` / `signoff`; none → infer from which of the plan,
   results and sign-off files exist.

## Phase 2: Plan — `uat-coordinator`

**Read `references/1-plan-and-environment.md` now and follow it.** Spawn
`uat-coordinator` via `Agent` with the fixed brief in that file. It produces the
plan: scenarios in the user's words citing the criterion each proves (spec path +
criterion ID), scripts per role with at least one negative scenario each, English
and Arabic (RTL) versions, the self-hosted scenarios when the bundle ships, the
environment specification, the participants by role and organisation, and
**numeric exit criteria**. The Arabic text is a draft until `localization-lead`
(or a named native reviewer) reviews it — spawn `localization-lead` for that
review; record `Arabic scripts: reviewed by [..]` or `unreviewed`.

Present the plan. `AskUserQuestion`: approve the plan and the exit criteria /
revise scenarios / change exit criteria / cancel. **Exit criteria are agreed
before the first session.** Ask: "May I write the plan to
`production/qa/uat-plan-[release].md`?" A decline ends the run with
`BLOCKED — write declined by user`.

## Phase 3: Environment and Participants

**Follow `references/1-plan-and-environment.md` (Environment).** `--env <name>`
names the environment the sessions run against: `dev` (the local stack) or a
staging environment **the user names explicitly in this conversation** — the name
is recorded in the plan header. Production is never an environment for UAT, and an
unnamed or production-looking target is refused (`BLOCKED — environment not
named`). The environment
must be the **release candidate** build; seeded tenants per participant group come
from `tools/seed/`; **no production export is loaded**. Masked customer-shaped
data only with the user's written approval, with the mask rules and the deletion
date recorded. A rebuild after sessions began invalidates the passed scenarios the
diff touches — compute that list. Environment health, the build hash and the seed
version go into the plan header. If the environment cannot be confirmed, the run
stops with `NOT ASSESSED — environment not confirmed`.

## Phase 4: Sessions

**Read `references/2-sessions-and-defects.md` now and follow it.** Sessions are
facilitated by people. For each session, produce the per-role script sheet from
the approved plan, then collect results with `AskUserQuestion` per batch of 3–4
scenarios (`PASS` / `FAIL` / `BLOCKED` / `NOT RUN`, then the description).
**Wait for the answer; record only what was said.** Quotes are recorded only when
the user supplies them from a real session, with the participant's role; observe
without leading. Participants are referred to by ID, not by name.

## Phase 5: Defect Intake

Every FAIL becomes a bug through `/bug-report`: build, environment, tenant and
role, steps, expected, actual, screenshot or recording, **language and
direction**, and a severity *proposal* citing the S1–S4 rule. Spawn `qa-lead` to
classify S1–S4 when several arrive; the final severity is `qa-lead`'s. Retest is
by the reporter or `qa-tester` with evidence attached — the coordinator never
retests and closes its own defect. A suspected cross-tenant exposure is S1:
announced in conversation immediately and routed to `security-lead` through
`qa-lead`.

## Phase 6: Results, Exit Criteria and Sign-off

**Read `references/3-signoff.md` now and follow it.** Compute the results table
(counts add up to the scenario total), evaluate each exit criterion as target vs
actual, derive the **UAT result** verdict, and have `uat-coordinator` draft the
sign-off record. The approval block is presented to the approver as it stands;
**the decision rows are filled only from the approver's own words in this
conversation**. Ask: "May I write `uat-results.md` and `uat-signoff.md` to
`production/qa/evidence/[release]/`?" Name both. If the approver is not available,
the record is written with every approval row `PENDING` and the release gate sees
exactly that. If the user declines the write, close with
`BLOCKED — write declined by user` (the computed UAT result is still stated in
conversation, marked not recorded).

**Run `/bug-report` and `/smoke-check` through the `Skill` tool**, and append the
`UAT:` line to `production/session-state/active.md` with `Edit`.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent's return contract named a path,
check it exists before treating the phase as done. If `uat-coordinator` returns
BLOCKED, errors or cannot complete: surface it immediately, do not proceed past
what it blocks, and produce a partial plan or record with the gap named. Full
procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Business language, not engineering language** — scenarios use the user's words; no endpoints, tables or flags
- **Every scenario cites a criterion; every criterion has a scenario** — gaps in either direction are listed
- **Arabic (RTL) and English for every scenario**, and a refusal scenario per role
- **The release candidate, a seeded environment, no production data** — approval for masked data recorded with deletion date
- **Results only from what was reported**; quotes only from real sessions; participants by ID
- **Never sign off for the business**, never pre-tick an approval, never accept an open S1/S2 because the date is fixed — only `qa-lead` and the user waive, in writing
- **Never fix product code or data to make a scenario pass** — route via `qa-lead` to the owning lead
- Ask before every write; no commits unless the user asks

## Recommended Next Steps

- `READY FOR SIGN-OFF`: the approver decides; then `/team-qa release` (reads the sign-off), `/release-checklist`
- `NOT READY` / `NOT ASSESSED`: fix defects via `/dev-story` or `/hotfix`, re-run the affected scenarios with `/uat run [release]`; rebuild → re-run what the diff touches
- Findings worth automating: `/automate-test`; open defects: `/bug-triage`
- Release gate: `/gate-check`, `/team-release`
