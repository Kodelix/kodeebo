---
name: team-security
description: "Orchestrate the security team for a feature, area or release — security-lead direction, threat model, appsec review and scans in parallel, optional penetration test, fixes routed to the stack leads, then security sign-off evidence for SL-RELEASE-SECURITY. Uses /threat-model, /security-audit, /dependency-audit, /tenant-check, /pentest."
argument-hint: "[feature | area | release] [--pentest] [--resume <pentest-report-path>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(git log *), Bash(date *), Agent, AskUserQuestion, Edit, Skill, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/team-security/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Security

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-security [feature | area | release] [--pentest] [--review full|lean|solo]` — name what to secure (e.g., `billing`, `file upload`, `self-hosted licensing`, `release 1.4`). `--resume <path>` continues after a penetration test. Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the security team through a structured pipeline: from "what could go wrong" to "the evidence the release gate reads".

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. **Accepting a
residual risk, scheduling or approving a penetration test, and any waiver of
security evidence are never delegated to a mode.** See `.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,stack,tenancy,distribution`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow` and `qa.level` do not relax this pipeline.** Security evidence is
required at every tier (`security-baseline.md`; `SL-RELEASE-SECURITY` runs at
`minimal`, `standard` and `full`).

`review_mode` sets director-gate depth. This pipeline's gates: **SL-THREAT-MODEL**
(run by `/threat-model` in Phase 2), **SL-TENANT-ISOLATION** (run inside
`/security-audit` at `full`), and **SL-RELEASE-SECURITY** (Phase 6, spawned here
only at `review_mode: full`; at `lean` and `solo` it is recorded
`SL-RELEASE-SECURITY skipped — [mode] mode`, and `/gate-check` still runs it as a
phase gate). A skipped gate waives the director's opinion, never the evidence:
the audit, the scans, the control mapping and the negative tests are required at
every mode.

`automation` drives the Decision Points note above.

**`team.size`**: which agents are active (orthogonal to review_mode and workflow).
- **`individual`** (default): `appsec-engineer` only; `security-lead` is invoked at the two phase gates that end in a security decision (Phase 2 threat model, Phase 6 sign-off) and no others. Specialists are consulted through `appsec-engineer`.
- **`small`**: `security-lead` + `appsec-engineer` throughout, and the stack lead(s) for the layer(s) a fix lands in (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`, routed by `principal-engineer`). A pentest is the user's `/pentest`, never spawned from here.
- **`studio`**: + `privacy-compliance-specialist`, `auth-identity-specialist`, `multitenancy-specialist` for their areas, and an adversarial review pass: Phase 3 reviewers are told "your job is not to confirm this is safe — find the path that breaks it", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists**, whatever the `automation` mode; an agent restricted to "phase gates only" is spawned there and nowhere else.

**Announce the active set before Phase 1 — never let the collapse be silent.**
State in one line which agents this run will spawn and which the pipeline names
but will **not** spawn at the resolved `team.size`:

> `Active set (team.size: <resolved>): <agents for that size>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct (the narrow default is the token lever); without
saying so a reader cannot tell a collapsed run from a broken one. A constraint
that is enforced but never surfaced is indistinguishable from one that was never
enforced.

## Team Composition

- **security-lead** — threat-model adequacy, control mapping, risk acceptance recommendations, SLA setting, sign-off (`SL-*` gates)
- **appsec-engineer** — secure review against ASVS 5.0.0 / MASVS 2.1.0 / API Top 10 2023, scanner runs and triage, negative tests, write-ups
- **penetration-tester** — authorised dynamic testing under written scope (only through the user-typed `/pentest`; never spawned by this skill or by `security-lead`)
- **privacy-compliance-specialist** — personal data inventory, retention, DSAR export/delete (PDPL / GDPR), when PII is in scope
- **auth-identity-specialist**, **multitenancy-specialist** — authentication and isolation findings (`studio`)
- **principal-engineer** + stack leads — fixes (never made by the security agents)

## How to Delegate

Use the `Agent` tool: `subagent_type: security-lead` · `appsec-engineer` · `privacy-compliance-specialist` · `auth-identity-specialist` · `multitenancy-specialist` · `principal-engineer` (fix routing) · stack leads via `principal-engineer`. Penetration testing is `/pentest`, which is user-invoked only.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline, never a path to a document you already read. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." **Implementation files are the exception:** an agent writing fixes first returns the files it will create or change; its contract names them only after you asked once for the set and the user said yes.

| Phase / agent | Writes to |
|---|---|
| 3 privacy-compliance-specialist | `production/qa/evidence/security-[slug]/privacy-review.md` |
| 3 auth-identity-specialist, multitenancy-specialist (studio) | `production/qa/evidence/security-[slug]/review-[agent].md` |
| 5 principal-engineer | `production/qa/evidence/security-[slug]/fix-routing.md` |
| 5 appsec-engineer (negative tests) | test directories of the owning layer, at the paths the set approval named |
| 6 security-lead | gate verdict returned as text (the orchestrator writes the report) |

Sub-skills (`/threat-model`, `/security-audit`, `/dependency-audit`, `/tenant-check`) write their own artifacts under their own protocols and ask before writing.

> **Why this does not violate the Collaboration Protocol.** A subagent spawned here writes **without** asking, a deliberate, bounded exception. It holds only when: (1) the path is one **you** named in the prompt; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

### Phase 1: Load Context

Resolve the scope from the argument: a feature or area → its specs, stories and code; `release` → the release record in `production/releases/`, the stories shipped, the editions (hosted, self-hosted bundle, Android, iOS, web).

Read and report each as FOUND or ABSENT:
- **Triggers** in the scope from `security-baseline.md` "Threat modelling": authentication, authorization model, billing, licensing, file upload, webhooks, PII export/delete, admin/impersonation, a new external integration. A trigger with no threat model is a finding (REJECT-class), not a missing input.
- `docs/architecture/threat-models/` for each trigger; the latest `production/qa/security-audit-*.md`; pentest reports under `production/qa/evidence/`; open security bugs in `production/qa/bugs/`; gate outcomes in `production/gate-checks/`
- `stack`, `tenancy.model` and `distribution.model` from the resolved config and `resolve_code_root` — an unset value is **not** "not applicable" (`/security-audit` Phase 1 states the rule): ask, or mark the affected category `NOT ASSESSED`.

`--resume <path>` → skip to Phase 5 with that pentest report as an input.

Report: "Security cycle for [scope]. Triggers: [list]. Threat models: [n present / n absent]. Last audit: [date or none]. Pentest scheduled: [yes/no]. Ready?"

### Phase 2: Threat Model (security-lead)

For each trigger without a current model: run `/threat-model [feature]`; for one whose feature changed since the model was written (compare `git log` on the feature paths against the model's date): `/threat-model [feature] --update`. Do not re-implement the skill — it runs `SL-THREAT-MODEL` itself, maps requirement IDs from the official documents, and records residual risk by name.

**Gate (phase gate):** summarise verdicts. A **REJECT** blocks implementation of that sensitive area: stop for it and continue only the unaffected scope if the user chooses. **CONCERNS** → `AskUserQuestion`: revise / accept the listed concerns with an owner / discuss. Residual risk is accepted by the **user**, with owner and expiry — never by an agent.

### Phase 3: Review and Scans (parallel)

Two tracks, launched together — issue every `Agent` call first, then run Track A in this session:

**Track A — in this session (skills):**
- `/security-audit [full | backend | web | mobile | selfhosted | deps | quick]` for the scope (it spawns `appsec-engineer`, runs the scanners and, at `full` review mode, SL-TENANT-ISOLATION). A release scope is `full`.
- `/dependency-audit` for CVEs, deprecations and licences; `/tenant-check` when `tenancy.model` is multi-tenant or unset.

**Track B — agents in the background:** `privacy-compliance-specialist` when PII is in scope (data inventory, retention, DSAR export/delete, legal basis) → its path above; at `studio`, `auth-identity-specialist` and `multitenancy-specialist` review authentication/session and isolation designs against the threat model (adversarial pass).

Collect everything before Phase 4. Summarise by severity (CRITICAL / HIGH / MEDIUM / LOW) with the **NOT ASSESSED** list beside it (scanners not installed, unscanned lockfiles, unset scoping values, requirement IDs `NOT SOURCEABLE`). A suspected live secret or cross-tenant exposure is announced **immediately** and routed to `security-lead` — it does not wait for the phase end.

**Gate (phase gate):** `AskUserQuestion`: proceed to fixes / re-scope / stop.

### Phase 4: Penetration Test Decision

`/pentest` is **user-invoked only** (`disable-model-invocation`): this pipeline cannot start it and never spawns `penetration-tester`.

**`--pentest` flag.** It means "include the latest user-run `/pentest` report in this review": the newest pentest report under `production/qa/evidence/` for the scope is read as an input to Phases 5 and 6 (findings `PT-NNN`, retest through `/pentest retest [report-path]`), and the question below is not asked. If no report exists, tell the user to run `/pentest <scope>` and follow the **Scheduled** branch below (hand-off written after asking, pipeline paused). Without the flag, ask: schedule a test (write the hand-off below) / not scheduled (reason).

- **Scheduled:** write the hand-off the user will take to `/pentest` — targets, the threat-model abuse cases and audit leads as test cases, the accounts the seed provides — to `production/qa/evidence/security-[slug]/pentest-handoff.md` (ask). Pause the pipeline: "Run `/pentest scope` — it refuses without written scope, a named approver and a window. Continue with `/team-security [scope] --resume [report-path]` when the report exists." Phases 5–6 may start on the audit findings meanwhile only if the user says so.
- **Not scheduled:** record `Penetration test: not scheduled — dynamic testing NOT ASSESSED`. For a release that ships a self-hosted or enterprise edition this is a **CONCERN** in Phase 6, not silence.

### Phase 5: Fixes (stack leads) and Re-verification

Spawn `principal-engineer` with the consolidated findings (audit `SEC-NNN`, dependency, privacy, pentest `PT-NNN`) to route each to the owning lead — return contract: `fix-routing.md` with finding → owner → story or bug → fix window. Fix windows are the policy defaults (CRITICAL 48 h, HIGH 7 d, MEDIUM 30 d, LOW 90 d from triage) unless an ADR changed them.

- File a bug per finding with `/bug-report` (cross-tenant and credential findings are S1: `/hotfix` if live, `/incident`). Each fix is a story for `/dev-story`; the stack lead returns the files it will change, you ask once for the set, and it writes after a yes (File Write Protocol).
- `appsec-engineer` adds the **negative test** each finding calls for (authz bypass, cross-tenant, injection, replay, rate limit) — a fix without its regression test is not done.
- **The model never proposes waiving security evidence on a security-sensitive story.** A finding left open is an accepted risk: the user decides, with owner and expiry, recorded in the report.
- **Re-verify:** after fixes, `/security-audit quick` and `/test` on the changed layers; for a pentest, the retest through `/pentest retest [report-path]`. Re-verification output replaces the earlier status; a finding is `OPEN` until that evidence exists.

### Phase 6: Sign-off Evidence

Build the control-mapping table (requirement ID with its source URL — or `NOT SOURCEABLE` — story, negative test, evidence path, status), the scans table (tool, version, scope, result — or `not run`), the findings list with status, the threat-model verdicts, and the residual-risk list (owner, expiry).

At `review_mode: full`, spawn `security-lead` for **SL-RELEASE-SECURITY**: the `Agent` prompt tells it to read `.claude/docs/director-gates/sl-release-security.md` first (you do not read it) and passes the release identifier and commit range, the editions, the control mapping, the threat models and their verdicts, the scan results, the vulnerability register (findings with severity, owner, status, accepted-risk expiry) and the SL-TENANT-ISOLATION verdict. Record its verdict (READY / CONCERNS / NOT READY / NOT ASSESSED). At `lean`/`solo` record the skip.

**Security evidence status** (this pipeline's own, derived mechanically; first match wins):
1. **NOT READY** — an open CRITICAL or HIGH not accepted by the user, a REJECT threat model for an in-scope area, or a gate verdict NOT READY.
2. **NOT ASSESSED** — nothing above, but a scan or audit category did not run, an in-scope scoping value is unset, the control mapping is `NOT SOURCEABLE` for a category in scope, or a trigger has no threat model.
3. **CONCERNS** — accepted risks, open MEDIUM/LOW, or dynamic testing not run on a release with a self-hosted or enterprise edition.
4. **READY** — none of the above.

`NOT ASSESSED` outranks `READY` and ranks below `NOT READY`. Present the report, then ask: "May I write the team security report to `production/qa/evidence/security-[slug]/team-security-report.md`?" Write only after a yes; on a no the verdict is `BLOCKED — write declined by user`. Stamp the report date from `date +%F`.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** Resume the agent
naming the unmet contract; "I could not write" is a valid answer, silence is not.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Code roots unresolved or a layer without source → that category is `NOT ASSESSED`, never zero findings
- Scanner not installed → `not run`; install is the user's call (`/dependency-audit` names the tool)
- Threat model REJECT for a sensitive area → stop that area; no implementation until `/threat-model` is revised
- `/pentest` refused for missing scope or approver → the test did not happen; record it
- Conflict between `security-lead` and the stack lead on a fix → escalate to `cto`, then the user decides

## Output

A summary covering: scope and triggers, active set, threat-model verdicts, audit and scan results (with every NOT ASSESSED cause), penetration-test status, findings by severity and status, fixes routed and negative tests added, gate verdict or skip, security evidence status (READY / CONCERNS / NOT READY / NOT ASSESSED), and accepted risks.

Verdict: **COMPLETE** — the cycle ran; the evidence status above is the security result.
Verdict: **COMPLETE — [pentest | scan | mapping] NOT ASSESSED ([reason])** — the cycle ran with the named gap.
Verdict: **BLOCKED** — a REJECT, an unresolvable input or a stop condition halted the pipeline; partial report produced.
Verdict: **BLOCKED — write declined by user** — the user declined the report write; the evidence status above stands in conversation only and nothing is reported as COMPLETE.

Replace, with `Edit`, this skill's own `## Security pipeline — <slug>` block in `production/session-state/active.md` in place (add it after the existing content if absent; create the file with `Write` only if it does not exist; never touch another skill's block): `Scope`, `Phase` reached, `Evidence status` (READY / CONCERNS / NOT READY / NOT ASSESSED), `Result` (the verdict above), `Report: production/qa/evidence/security-[slug]/team-security-report.md`, `Next` command, date from `date +%F`. Per `.claude/docs/checkpoint-handoff.md`, also overwrite the `<!-- CHECKPOINT -->` block's `Current task` (`/team-security <slug> — <verdict>`), `Next step` (the same `Next` command), `Blocked on`, `Files in progress` and `Open questions`, and append the Notes line; leave the `Flow:` line and other blocks alone. Still done on BLOCKED, NOT ASSESSED or a declined write.

## Next Steps

- `/release-checklist` and `/gate-check` read this evidence for SL-RELEASE-SECURITY; `/team-release` for the release
- Open findings: `/dev-story` per fix story; `/security-audit quick` after each batch
- `/team-hardening` for the performance, accessibility and QA passes that sit beside this one
