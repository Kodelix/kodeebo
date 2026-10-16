---
name: incident
description: "Incident command: declare severity and roles, mitigate first (rollback, flag off, scale), keep a UTC timeline as it happens, draft customer comms for approval, use docs/runbooks, spawn debugger for diagnosis, then hand off to /postmortem. Always collaborative; runs only when typed."
argument-hint: "[<what is happening> | update [incident-file] | resolve [incident-file]] [--sev 1|2|3|4]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(git status), Bash(git status *), Bash(git diff *), Bash(git show *), Bash(docker compose ps), Bash(docker compose ps *), Bash(docker compose -f * ps), Bash(docker compose -f * ps *), Bash(docker compose logs *), Bash(docker compose -f * logs *), Bash(date -u), Bash(date -u *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/incident/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,stack`

# Incident

> **Explicit invocation only**: this skill runs only when the user types
> `/incident`. It does not auto-invoke on context matching.

> **Always collaborative.** `incident` is exempt from `modes.automation`
> (`.claude/docs/automation-modes.md`). Whatever the project's mode is,
> including `autonomous`, every decision below is the user's: severity, which
> mitigation to apply, who is told what, when to declare it over. Resolved
> config above is used as-is for the stack facts (`distribution`, `deploy`,
> `tenancy`); `automation` and `review_mode` are read only to say they are
> ignored here. A key that did not resolve is read as the stricter option.

**Act first, document after.** Customers are hurting now. Order of work:
**declare -> mitigate -> communicate -> diagnose -> resolve -> hand off.**
Mitigation (stop the damage) comes before diagnosis (find the cause): rolling back,
turning a flag off or scaling is a time-to-mitigate action that does not wait for
a proven root cause (`debugger`, `sre-lead`). Questions are short and one at a
time. If the user answers "later" to a documentation question, the incident goes
on; documentation gaps are recorded as gaps, never invented.

**This skill executes nothing against production.** It proposes the exact
steps from the runbook; the user (or the on-call who owns the system) runs them,
or names the exact target and command and says to run them. It never runs
`docker compose down -v`, volume or image prunes, a restore over live data, a data
delete, a force-push or a key rotation on its own (`deploy.md`, `sre-lead` Must
Not). Read-only diagnostics run only against a local or staging stack, or a
production read the user explicitly names. **Read-only is an instruction to this
skill, not something the tool list can enforce.** `allowed-tools` only decides what
runs without a permission prompt: it pre-approves the read-only diagnostics
(`git log`/`show`/`diff`/`status`, `date -u`, `docker compose ps`/`logs`) and
nothing that changes state, so a mutating command always prompts. But the
pre-approved patterns are not narrowed to a target or to a safe use —
`docker compose logs` reads whatever stack the local Docker daemon or the named
`-f` file points at, and can be left streaming — so the limits below are rules this
skill follows, not guarantees the grant gives: logs are read with a fixed
`--tail N` (never `-f`/`--follow`), against a local or staging project the user
has named, and never against a production host unless the user names it. Every
mutating step is **printed for the user to run**, never run by the skill; a
command outside the pre-approved list triggers a normal permission prompt, and
approving one is the user running it.

**It never publishes.** Status-page posts, e-mails and in-app banners are drafted
by `customer-success`, facts and cadence approved by `sre-lead` or the user, and
**sent by the user**. Sending any message needs explicit user approval.

**Output:** the incident record `production/incidents/incident-[date]-[slug].md`
from `.claude/docs/templates/incident-response.md` (filed in `production/incidents/`
whatever path the template's own comment names — `/postmortem` and `/hotfix` read
it there), kept current as it happens; then a hand-off to
`/postmortem`.

> **Status words (the template's):** `Active` -> `Mitigated` -> `Resolved` ->
> `Post-Mortem Complete`. **Unknown is not zero.** Impact, scope and data
> exposure that are not yet known are written `NOT KNOWN` with the check that
> would establish them, never `none`. `Data exposure` stays **`Suspected`** until
> a named piece of evidence rules it out. An incident is not `Resolved` until the
> resolution criteria in Phase 6 are met with evidence, and is never closed without
> a recorded postmortem decision.

---

## Phase 1: Declare (first two minutes)

**Read `references/1-declare-and-roles.md` now and follow it.** It parses the
argument (new / `update` / `resolve`), asks the five facts that decide
everything - what customers experience, since when (UTC), who is affected
(hosted / self-hosted versions, tenants), whether data may be exposed, what
changed recently - proposes a severity from the `sre-lead` ladder for the user to
confirm, names the three roles (incident commander, communications, operations),
and asks once to create the incident record and append the timeline as we go.
A suspected cross-tenant or credential exposure hands command to `security-lead`
now. On `update` or `resume` it reads the record and
`production/session-state/active.md` instead of re-asking what is written.

## Phase 2: Mitigate

**Read `references/2-mitigate.md` now and follow it.** It finds the runbook in
`docs/runbooks/` for the alert or symptom, lists the mitigation options that apply
(roll back, flag off, scale, rate-limit or block, pause a job, provider
degraded mode, halt a mobile rollout), asks which to apply, and verifies the
effect against the SLI - not against "it feels better". For a security-flavoured
incident, containment and evidence preservation come in a fixed order. Every
decision is appended to the timeline with its UTC time.

## Phase 3: Communicate and Diagnose (parallel)

Once a mitigation is applied or the first update is due, whichever is first, spawn
in one turn - their inputs are independent:

- `customer-success` -> draft the next customer message (investigating / identified / monitoring / resolved; English and Arabic status) from the facts in the record. Brief and rules in `references/3-comms-and-diagnosis.md`.
- `debugger` -> diagnosis of cause and scope, **read-only**, with a mitigation option stated separately from the fix. Brief in the same file.

Spawn `sre-lead` instead of the user to approve the facts and cadence if the user
asks for it; `security-lead` is consulted for a security-flavoured incident.
Verify the artifacts exist before reading replies
(`.claude/docs/error-recovery-protocol.md`). The user reviews each draft, edits
it, and sends it themselves; record the sent time in the timeline.

## Phase 4: Keep the Timeline

**Read `references/4-timeline-resolve-handoff.md` §1 now.** Every event, decision
and message is appended to the record as it happens, UTC, with evidence
references (trace ID, dashboard link, deploy or commit ID) and never a secret or
PII. Check in every time something changes and at the update cadence the user and
`sre-lead` set; when the user goes quiet for longer than that cadence, ask whether
the customer update is due.

## Phase 5: Update and Re-declare

On new information: severity can go up or down - ask, and log the change with the
reason. A new data-exposure suspicion re-runs Phase 1's security hand-off. A failed
mitigation goes back to Phase 2.

## Phase 6: Resolve

**Read `references/4-timeline-resolve-handoff.md` §2 now.** Resolution requires
evidence: the SLI/error rate back in range on the dashboard the SLO uses, a smoke
check of the affected journey, a monitoring window the user and `sre-lead` agree,
the mitigation's temporary parts listed (a flag left off, a rollback not yet
re-rolled forward are open items). Then the all-clear message (draft, user sends).

## Phase 7: Hand Off

**Checkpoint.** When the run ends (resolved, or handed over still open), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/incident <INC-ID> — <resolved | mitigated, open | handed over>`,
Next step = the first hand-off below (`/postmortem <incident-file>`, or the open
mitigation / monitoring item if not resolved), plus Blocked on / Files in
progress (the incident file) / Open questions (decisions the user still owes);
append the Notes line. The `Active incident:` line stays and is updated too.

**Read `references/4-timeline-resolve-handoff.md` §3 now.** Record the postmortem
decision (required for SEV1 and SEV2, within 5 working days per `sre-lead`; for
SEV3/SEV4 the user decides and the decision is written down), then:

- `/postmortem <incident-file>` for the blameless review
- `/hotfix <bug>` if a code fix must reach released versions
- `/bug-report` for defects found; `/create-stories` for prevention actions after the postmortem
- runbook gaps found -> `sre-lead` / `observability-engineer` (an alert without a runbook is not merged)

---

## Error Recovery Protocol

**First, verify the artifact.** A spawned agent's reply is not evidence: check the
draft or diagnosis file it was told to produce exists before relying on it. If an
agent returns BLOCKED or errors, say so at once and carry on without it: a missing
draft means the user writes the message from the facts in the record; a missing
diagnosis does not hold up mitigation. Full procedure:
`.claude/docs/error-recovery-protocol.md`. Anything that could not be assessed is
recorded `NOT KNOWN` or `NOT ASSESSED - [what was missing]` in the record.

## Collaborative Protocol

- **Every decision is the user's**: severity, mitigation, wording, closure. The skill proposes with reasons and waits
- **Mitigate before you diagnose.** Never hold a rollback or a flag-off for a proven root cause
- **Nothing is executed on production by this skill**; DESTRUCTIVE commands are marked and need the user to name the target
- **Nothing is published by this skill.** Drafts only; the user sends
- **Unknown is recorded as `NOT KNOWN`**, never as none, zero or "no impact"; data exposure is `Suspected` until ruled out with evidence
- **Customer data, secrets, tokens and PII never go into the record, the drafts or the evidence**; tenants are referenced by internal ID only. One tenant's data is never shown to another
- **Blameless.** The record names systems, safeguards and decisions, not people
- **No root-cause speculation, internal hostnames or vendor names in customer messages** until the postmortem confirms them
- **A security-flavoured incident (cross-tenant exposure, credential exposure, active exploitation) is `security-lead`'s to command** from the moment it is suspected; evidence is preserved (time-boxed, 15 minutes by default) before anything is deleted or rotated
- **Regulator and customer breach notification duties and deadlines** come from `privacy-compliance-specialist` and counsel via the user, never from memory
- Ask "May I write..." once for the record at declaration (covering timeline appends); other new files ask separately. No commits unless the user asks

## Recommended Next Steps

- `/postmortem <incident-file>` within 5 working days for SEV1/SEV2
- `/hotfix` for a code fix on a released version; `/smoke-check` to verify the recovered journey
- `/observability-plan` for missing alerts, dashboards and runbooks the incident exposed
- `/release-notes` for the customer-facing note of the fix; `/tech-debt` for deferred prevention work
