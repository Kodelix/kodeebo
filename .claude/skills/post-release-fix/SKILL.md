---
name: post-release-fix
description: "Focused mini-sprint after a release — fixes the known issues found since the release gate, with a QA gate and a rollback plan written first. Fix-only: not a hotfix, not a full sprint."
argument-hint: "[scope: known-bugs | review-feedback | all]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/post-release-fix/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,qa.level,testing.strict,performance.enforce,project.stage,stack`

# Post-Release Fix

Every release has a short tail of known issues: bugs found after the release
gate passed, store-review feedback, and small problems from the first hours of
real traffic. Planning the fix for that tail prevents chaos. This skill scopes
the fix to only what is safe and necessary, gates it through a lightweight QA
pass, and ensures a rollback plan exists before anything ships. It is a
mini-sprint — not a `/hotfix` (an emergency on a live defect), not a full sprint.

> **Always collaborative.** `post-release-fix` is exempt from `modes.automation`
> (`.claude/docs/automation-modes.md` § Exemptions). Whatever the project's mode,
> scope, rollback plan, fixes, QA verdict, deploy and publication each need the
> user's explicit sign-off. Do not add or follow an automation prelude.

**When to run:**
- Right after a release is tagged and shipped (or a release candidate is tagged), and known bugs exist that were too risky to fix inside it
- When Play Console / App Store review feedback requires small fixes after submission
- When first-days-in-production signals (error rates, support tickets, usability sessions) surface must-fix issues after the release gate passed
- When self-hosted customers report upgrade friction that a small patch can remove

If the issue is an emergency hurting customers *now* — an outage, data exposure,
broken billing — stop and use `/hotfix`. Scope rules for this skill:

- Only P1/P2 bugs that are SAFE to fix quickly
- No new features — fix-only
- No refactoring — minimum viable change
- Any fix needing more than 4 hours of dev time belongs in the next planned release, not this patch
- No schema change that is not expand-only and backwards-compatible with the version shipped (`.claude/rules/migrations.md`)

**Output:** `production/releases/post-release-fix-[version].md`
(+ `production/releases/rollback-plan-[version].md`)

---

## Phase 1: Load Release Context

Read:
- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — confirm the project is in `Release` or `Live`
- The most recent file in `production/gate-checks/` — read the release gate verdict
- `production/releases/` — the release record, release checklist and the tag this patch builds on
- `production/qa/bugs/*.md` — load all bugs with Status: Open or Fixed — Pending Verification
- `production/sprints/` most recent — what shipped
- `production/hotfixes/` — hotfixes since the release (do not re-fix, do not conflict with them)
- `production/qa/security-audit-*.md` most recent (what `/security-audit` writes) — open security items

If the resolved stage is not `Release` or `Live`:
> "Post-release fixes are for products that have shipped. Current stage: [stage]. This skill is not appropriate until a release exists."

Verdict: **NOT ASSESSED — no release exists yet (stage: [stage])**. Nothing is written.

**Check the premise, do not assume it.** This skill rests on a release that
already passed a release gate — that premise justifies its lightweight QA pass
instead of a full one. Verify it rather than inferring it from the stage value:

- **No file in `production/gate-checks/`**, or none recording a release-gate
  verdict: report `Release gate: NOT ASSESSED — no gate-check record found`.
  Do not proceed silently. Say plainly that the reduced QA scope below is
  justified by a gate nobody can find, and ask whether to run `/gate-check`
  first or proceed with a full QA pass instead.
- **The most recent record is FAIL, CONCERNS or NOT ASSESSED**: name it and stop,
  with Verdict: **STOPPED — release gate not passed ([verdict], [date])**.
  A post-release fix on top of a build that never passed its gate is not a
  post-release fix; it is the release gate, arriving late and scoped to the
  wrong changes.
- `project.stage: Release` or `Live` on its own does **not** establish this. The
  stage is a claim about where the project is; the gate record is the evidence
  that it earned the position.

**Identify the editions in play** from `project.yaml` (`distribution`, `stack`)
and the release record: hosted, self-hosted bundle, Android, iOS, web. Each
edition has its own rollback and its own publish step (Phases 3 and 7). If you
cannot tell which editions shipped, ask — do not assume.

---

## Phase 2: Scope the Patch

### Step 2a — Classify open bugs for patch inclusion

For each open bug, evaluate:

| Criterion | Include? |
|-----------|----------|
| S1 or S2 severity | Yes — must include if safe to fix (an *active* S1 is a `/hotfix`) |
| P1 priority | Yes |
| Fix estimated < 4 hours | Yes |
| Security-related fix (any severity) | Yes if small — and it needs `appsec-engineer` review (Phase 4); wording follows `/release-notes` responsible-disclosure rules |
| Fix requires architecture change or a contract change | No — defer to the next release |
| Fix introduces new code paths or a non-expand-only migration | No — too risky |
| Fix is config/data only (no code change) | Yes — very low risk; changes to prices, limits or flags still get a `pricing-billing-designer` check |
| Store-review feedback that blocks approval | Yes — required |
| Fix affects `deploy/self-hosted/` | Only if it respects the licence decisions in `.claude/docs/standing-decisions.md` (L1–L4) and the signed-bundle rules in `.claude/rules/deploy.md` |
| S3/S4 severity | Only if a trivial config fix; otherwise defer |

### Step 2b — Present patch scope to the user

Use `AskUserQuestion`:
- Prompt: "Based on open bugs and review feedback, here is the proposed patch scope. Does this look right?"
- Show: table of included bugs (ID, severity, editions affected, description, estimated effort)
- Show: table of deferred bugs (ID, severity, reason deferred)
- Options: `[A] Approve this scope` / `[B] Adjust — I want to add or remove items` / `[C] No patch needed`

If [C]: output "No post-release fix required. Proceed to `/retrospective` for the release." Stop. Verdict: **NO PATCH NEEDED**.

### Step 2c — Check total scope

Sum estimated effort. If the total exceeds 1 day of work:
> "Warning: patch scope is [N hours] — this exceeds a safe post-release window. Consider deferring lower-priority items to the next planned release. A bloated patch introduces more risk than it removes."

Use `AskUserQuestion` to confirm proceeding or reduce scope.

---

## Phase 3: Rollback Plan

Before any code is written, define the rollback procedure. This is non-negotiable.

Spawn `release-manager` via `Agent`. Ask for a rollback plan covering **each
edition in scope**:

- **Hosted**: how to return to the released image digests; whether the migration (if any) was expand-only and the previous app version is compatible (production migrations are forward-only); data-compatibility between old and new app versions during rollout; who flips it and how long it takes
- **Self-hosted**: whether rollback is supported for this patch; the backup taken before upgrade and the restore steps; what customers who already upgraded do; whether the licence/update channel needs a pull or revoke
- **Android / iOS**: halt the staged rollout; the previous build stays live (a store cannot recall an installed build — say so); server-side mitigation for users still on the old build
- **Web / marketing site**: previous static bundle and cache invalidation
- Who is responsible for triggering the rollback, and the trigger condition (error-rate/SLO threshold, S1 count, time window)
- What customer communication a rollback requires (with `customer-success`)

Present the plan. Ask: "May I write this rollback plan to `production/releases/rollback-plan-[version].md`?"

Do not proceed to Phase 4 until the rollback plan is written. If the user declines,
close with `BLOCKED — write declined by user`: no fix is started without a recorded
rollback plan.

---

## Phase 4: Implement Fixes

For each code fix in the approved scope, spawn a focused implementation loop:

1. Route to the stack lead for the layer (`go-lead`, `ktor-lead`, `web-lead`,
   `android-lead`, `ios-lead`) via `principal-engineer`, with:
   - The bug report (exact reproduction steps and root cause if known)
   - The constraint: minimum viable fix only, no cleanup
   - The affected files (from the bug report's Technical Context)

   It returns, per bug, the minimal fix and the files it would change —
   writing nothing.

2. Ask once, for the whole set: "May I apply these fixes? [BUG-ID → files, one
   line each]". No code changes before this approval.

3. On yes, hand each approved fix back to the stack lead (a new `Agent` call
   carrying its plan) to implement it. **Each fix gets a regression test that
   fails before the fix and passes after** (or a written waiver and follow-up
   story). The stack lead runs the targeted tests (this skill has no shell): the
   commands come from the product's own scripts and CI — never a runner line
   written from memory. If no command can be sourced, say so and record
   `Tests: NOT RUN — command not sourced` for that bug. If the user declines the
   apply question, close with `STOPPED — fixes declined by user` (the rollback
   plan stays written).

4. Spawn `qa-tester` via `Agent` to verify: does the bug reproduce after the fix, on the running stack (`.claude/docs/run-and-observe.md`)? Include the negative path (other tenant / wrong role) for anything near authz.

5. **Security-related fixes** also go to `appsec-engineer` via `Agent` for review of the diff, the negative tests and the dependency scan.

For config/data-only fixes: make the change directly (no stack lead needed).
First ask, naming the file and the change: "May I edit `[config file]` — `[key]`:
[old value] → [new value]?" Confirm the value changed and re-run any relevant
smoke test.

---

## Phase 5: Patch QA Gate

A lightweight QA pass — not a full `/team-qa`. The release is already
QA-approved from the release gate; we are only re-verifying the changed areas.

Spawn `qa-lead` via `Agent` with: the list of all changed files, the bugs fixed
(with Phase 4 verification status), and the smoke scope for the affected
contexts and surfaces.

Ask `qa-lead` to determine: **is a targeted smoke check sufficient, or do any
fixes touch contexts that need a broader regression?**

Run the required QA scope:

- **Targeted smoke check** — run `/smoke-check` through the `Skill` tool (add
  `--surface` for each edition touched: `web`, `android`, `ios`, `self-hosted`)
- **Broader regression** — the affected contexts' tests in the code roots (the
  stack lead / `qa-tester` resolve them with `resolve_code_root`; test locations in
  `.claude/docs/directory-structure.md`) run by those agents using the commands in
  the product's scripts/CI, narrowed to the affected suites where the runner
  allows. If no command can be sourced, the broader
  regression is NOT ASSESSED; say so.

The QA verdict must be PASS or PASS WITH WARNINGS before proceeding. If FAIL:
scope the failing fix out of this patch and defer it.

**If the QA verdict is `NOT ASSESSED`, that is not a pass.** `/smoke-check`
returns it when the suite never ran — no stack, no runner, or a result nobody
confirmed. Do not proceed on it and do not re-read it as PASS WITH WARNINGS: the
warnings value means somebody looked and saw something minor, and this means
nobody looked. Either obtain the result (the verdict names what would make it
runnable) or defer the fix. A patch ships to every customer on the current
release, the worst possible audience for an unverified change.

---

## Phase 6: Generate Patch Record

```markdown
# Post-Release Fix: [Product Name] v[version]

**Date prepared**: [date]
**Target release**: [date/time window, per edition]
**Base build**: [release tag or commit]
**Patch build**: [patch tag or commit]
**Editions in scope**: [hosted | self-hosted | Android | iOS | web]

---

## Patch Notes (Internal)

### Bugs Fixed
| BUG-ID | Severity | Editions | Description | Fix summary | Regression test |
|--------|----------|----------|-------------|-------------|-----------------|
| BUG-NNNN | S[1-4] | [..] | [description] | [one-line fix] | [name] |

### Deferred to the next release
| BUG-ID | Severity | Description | Reason deferred |
|--------|----------|-------------|-----------------|
| BUG-NNNN | S[1-4] | [description] | [reason] |

---

## QA Sign-Off

**QA scope**: [Targeted smoke / Broader regression] · surfaces: [..]
**Verdict**: [PASS / PASS WITH WARNINGS / NOT ASSESSED]
**QA lead**: qa-lead agent
**Date**: [date]
**Warnings (if any)**: [list or "None"]
**Not assessed (if any)**: [what could not be checked, and why — or "None"]
**Evidence**: `production/qa/evidence/[..]`

---

## Rollback Plan

See: `production/releases/rollback-plan-[version].md`

**Trigger condition**: if [N] or more S1 bugs, or [SLO/error-rate threshold], within [X] hours of rollout, execute rollback.
**Rollback owner**: [user / producer]

---

## Approvals Required Before Deploy

- [ ] stack lead / principal-engineer: all fixes reviewed
- [ ] appsec-engineer: security-related fixes reviewed (or "n/a — none")
- [ ] qa-lead: QA gate PASS confirmed
- [ ] platform-lead: deploy plan (hosted; self-hosted bundle build)
- [ ] producer: deployment timing approved
- [ ] release-manager: store submissions / self-hosted channel confirmed

---

## Customer-Facing Notes

[Draft for customer-success to review before publishing — written with /release-notes, English and Arabic]
```

Ask: "May I write this patch record to `production/releases/post-release-fix-[version].md`?"
If the user declines, close with `BLOCKED — write declined by user` (the record
stays in conversation; no verdict below is reported as recorded).

Merge, tag, deploy and publish are **separate**, explicit decisions after the
record is written — ask with `AskUserQuestion` for each (hosted deploy,
self-hosted bundle publish, store submission); none is implied by approving the
record.

---

## Phase 7: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/post-release-fix <version> —
<verdict>`, Next step = the first next step below (`/release-notes`), plus Blocked
on / Files in progress / Open questions; append the Notes line. STOPPED, NOT
ASSESSED, BLOCKED or a declined write still updates the checkpoint with the
blocker.

After the patch record is written:

1. Run `/release-notes` to generate the customer-facing notes (and the self-hosted upgrade notes)
2. Run `/bug-report verify [BUG-ID]` for each fixed bug after the patch is live
3. Run `/bug-report close [BUG-ID]` for each verified fix
4. Schedule a post-release review 48–72 hours after the release with `/retrospective [milestone-name]` for the release milestone in `production/milestones/`

**If any S1 bugs remain open after the patch:**
> "S1 bugs remain open and were not patched. These are accepted risks. Document
> them in the rollback plan trigger conditions — if they occur at scale,
> rollback may be preferable to a follow-up patch."

Verdicts: **PATCH READY** (record written, QA PASS or PASS WITH WARNINGS,
rollback plan written) · **PATCH READY WITH CONCERNS** (a requested review or
edition check did not run — list it) · **NOT ASSESSED** (release gate record or
QA could not be assessed, or no release exists yet) · **NO PATCH NEEDED** ·
**STOPPED** (gate not passed, fixes declined, or QA FAIL with nothing left in
scope) · **BLOCKED** (`write declined by user`). A review that did not run is
reported as not run.

Use `AskUserQuestion`:
- Prompt: "Post-release fix complete. What's next?"
- Options:
  - `[A] Run /release-notes — generate customer-facing notes`
  - `[B] Run /bug-report to log any issues found post-deploy`
  - `[C] Stop here`

---

## Collaborative Protocol

- **Scope discipline is everything** — resist scope creep; every addition increases risk
- **Rollback plan first, always** — a patch without a rollback plan is irresponsible
- **Deferred is not forgotten** — every deferred bug is listed in the record's
  "Deferred to the next release" table; run `/bug-triage` afterwards to schedule
  them into the next sprint (if the project has no sprint plan, as on the default
  minimal workflow, into the product brief's build order)
- **Customer communication is part of the patch** — `/release-notes` is a required output, not optional
- **Every edition is a separate decision** — hosted, self-hosted, and each store are approved, deployed and verified independently
