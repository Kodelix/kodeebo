---
name: postmortem
description: "Blameless postmortem for an incident: timeline rebuilt from evidence, contributing factors by missing safeguard, what went well, SLO and error-budget impact in numbers, runbook updates, and actions each with an owner, a date and a story. From templates/post-mortem.md."
argument-hint: "[incident-file | incident-id] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(git show *), Bash(date *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/postmortem/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **Action owners and due dates
are never filled in by a mode**: they are always asked.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. The postmortem is part of
reliability engineering, not a document tier (`workflow-modes.md`): every SEV1
and SEV2 gets one at every tier.

# Postmortem

An incident that is not learned from will happen again. This skill turns a
resolved incident into a **blameless** review: what happened (a timeline rebuilt
from evidence, not from memory), why the safeguards did not stop it, what worked,
what it cost against the SLOs, and what changes - each change an **action with an
owner, a due date and a story**, so it is tracked until closed. Owner:
`sre-lead`. It is the step after `/incident`; it is not a sprint or milestone
retrospective (`/retrospective`).

**Blameless means**: the review names systems, safeguards and decisions made with
the information available at the time, never people. "Why did the safeguard not
catch it?" replaces "who did it?". Postmortems that name a person are rejected by
`sre-lead`.

**Output:** `production/incidents/postmortem-[date]-[slug].md` from
`.claude/docs/templates/post-mortem.md` (filed beside the incident record, per
the incident template), runbook updates under `docs/runbooks/` when approved, and
an action list for `/create-stories`.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: the incident is still `Active` (use `/incident`), no
> incident record exists, or a person is named as a cause and the user declined to
> reword. `NOT ASSESSED`: the timeline cannot be evidenced (sources unreadable),
> the SLO/error-budget impact cannot be computed (no `slos.md`, no SLI readings),
> or the root cause is `UNKNOWN`. `COMPLETE WITH GAPS`: an action lacks an owner,
> date or story; a contributing factor has no action and no recorded acceptance;
> a runbook gap has no update or ticket. **Unknown is written `NOT KNOWN`, never
> filled in; a number without a source is not a number.** Every cause is named in
> the report.

---

## Phase 1: Locate, Qualify, Schedule

**Read `references/1-locate-and-evidence.md` §1-§2 now and follow it.** It finds
the incident record (argument, or the newest `Resolved` record in
`production/incidents/incident-*.md`), refuses an `Active` one, and checks the
postmortem decision and deadline: SEV1/SEV2 within 5 working days of resolution
(`sre-lead`). A milestone or sprint review is redirected to `/retrospective`.

## Phase 2: Evidence Inventory

**Read `references/1-locate-and-evidence.md` §3 now and follow it.** Every source
is recorded FOUND, ABSENT or NOT READ: the incident record, the diagnosis and
comms drafts, the hotfix record, the runbook that was used, `docs/architecture/slos.md`,
dashboards and alert history the user can export, deploy and git history, CI runs.
The timeline is rebuilt row by row and each row is classed **EVIDENCED**,
**REPORTED** (someone recalls it) or **INFERRED**. A row without evidence is
labelled, never smoothed over.

## Phase 3: Fill the Gaps (parallel)

When the root cause is not `PROVEN`, or detection and alerting need analysis,
spawn in one turn (independent, read-only):

- `debugger` — only if the confidence is `LIKELY` or `UNKNOWN`: extend the diagnosis with the missing probes; reproduction on a non-production stack; hypotheses and what each check showed.
- `observability-engineer` — the detection question: which signals existed, what an SLO burn-rate alert would have done, time to detect, and what telemetry was missing; no change to alert rules (that is an action, not an edit).

Briefs in `references/2-factors-and-actions.md` §1. Verify the files they were
told to write exist before reading the replies. If an agent cannot be spawned, say
why and mark the dependent section `NOT ASSESSED`.

## Phase 4: Analysis

**Read `references/2-factors-and-actions.md` §2-§5 now and follow it.** Contributing
factors are classed by the safeguard that failed (requirements, design, review,
tests, rollout, detection, response, mitigation tooling, dependency), each tied to
evidence. What went well is recorded with equal care. The SLO and error-budget
impact is computed from SLI readings and `slos.md`, with the policy it triggers
quoted from the document. Runbook gaps are listed with the exact step that was
missing or wrong.

## Phase 5: Actions

**Read `references/2-factors-and-actions.md` §6 now and follow it.** Every action
has a type (prevent / detect / mitigate), an owner, a due date, and becomes a
story. Owners and dates are asked, never invented. Every contributing factor maps
to at least one action, or to an explicit, user-recorded acceptance with an owner
and an expiry date.

## Phase 6: Draft, Blameless Check, Review

**Read `references/3-draft-checks-and-write.md` now and follow it.** It fills the
template, runs the **blameless check** (a mechanical scan of the draft for
personal names taken from the git authors and for blame phrases), runs checks
P1-P14, and sends the draft to `sre-lead` for the process review (spawn; the
postmortem is `sre-lead`'s process) - never in `solo` mode if the incident was
SEV1/SEV2 and the user has not run it themselves; record `review skipped - [mode]`
where skipped.

## Phase 7: Write

Present the postmortem summary, the checks table, the action list and the Not
known list in conversation. Ask: "May I write the postmortem to
`production/incidents/postmortem-[date]-[slug].md`?" and, separately, "May I update
the runbook(s) `docs/runbooks/[names]` as shown?" and, only when the verdict is `COMPLETE` or `COMPLETE WITH GAPS`, "May I set the
incident record's Status to `Post-Mortem Complete` and link this postmortem?"
(a `NOT ASSESSED` postmortem leaves the incident `Resolved` and does not ask).
Name every path. If the user declines the postmortem write, close with
`BLOCKED — write declined by user` (the draft and its computed verdict stay in
conversation, marked not recorded). Write only after approval. Never include a secret, customer record, personal
data or a person's name.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/postmortem <incident> —
<verdict>`, Next step = `/create-stories` for the actions (the first item below),
plus Blocked on / Files in progress / Open questions; append the Notes line.
`NOT ASSESSED`, BLOCKED or a declined write still updates the checkpoint with the
blocker.

Then: `/create-stories` for the actions (the skill hands the list; the story IDs
are written back into the action table when they exist), `/observability-plan` for
detection actions, `/hotfix` if a fix is still unreleased, `/tech-debt` for
deferred items, `/retrospective` to raise the lessons.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file is
not an analysis. If an agent returns BLOCKED or errors, surface it, do not proceed
past what it blocks, and produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`. A section that could not be assessed is
recorded `NOT ASSESSED - [what was missing]` in the postmortem itself.

## Collaborative Protocol

- **Blameless, always.** Systems and safeguards, not people. Rewording a blame sentence is not softening a finding: the finding is kept, the framing is fixed
- **Evidence over recollection.** Each timeline row says whether it is evidenced, reported or inferred
- **Never invent a number.** Impact, SLO consumption and durations come from sources named in the document; otherwise `NOT KNOWN`
- **Owners and due dates are the user's** (and the owner's); the skill proposes roles, never assigns a named person or a date on its own
- **Actions are stories** and are tracked until closed; open actions are reviewed at the next reliability review (`sre-lead`)
- **Root cause is stated at the confidence the evidence supports** (`PROVEN`, `LIKELY`, `UNKNOWN`) - never upgraded for a tidier story
- **No customer data, secrets, PII or other tenants' details**; tenants by internal ID only
- **Customer-facing post-incident summary** (if wanted) is drafted by `customer-success` from this postmortem and the user sends it
- Ask "May I write..." naming every path; no commits unless the user asks
