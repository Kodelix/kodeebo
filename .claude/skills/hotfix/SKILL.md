---
name: hotfix
description: "Emergency fix path for a released product — hotfix branch from the released tag, minimal fix plus regression test, expedited review (appsec for security fixes), hosted deploy and self-hosted patch release, backport, full audit trail."
argument-hint: "[bug-id or description]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Agent, AskUserQuestion, Bash(date -u), Bash(date -u *), Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(git log *), Bash(git rev-parse *), Bash(git tag --list), Bash(git tag --list *), Bash(git tag --sort=*), Bash(git tag -n), Bash(git tag -n *), Bash(git branch --list), Bash(git branch --list *), Bash(git branch --show-current), Bash(git branch --contains *), Bash(git status), Bash(git status *), Bash(git diff *), Bash(git show *), Bash(git checkout -b hotfix/*), Bash(go -C * test *), Bash(pnpm -C * test *), Bash(pnpm -C * run *), Bash(./gradlew -p * *), Bash(swift test --package-path *), Bash(bash "*/.claude/skills/hotfix/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,qa.level,testing.strict,project.stage,stack`

# Hotfix

> **Explicit invocation only**: this skill runs only when the user requests it
> with `/hotfix`. Do not auto-invoke based on context matching.

> **Always collaborative.** `hotfix` is exempt from `modes.automation`
> (`.claude/docs/automation-modes.md` § Exemptions). Whatever the project's mode
> is — including `autonomous` — every question below is asked, every draft is
> approved before it is written, and nothing is merged, tagged, deployed or
> published without an explicit yes. Emergency decisions are the user's.

A hotfix fixes a defect that is **already released** and hurting customers or
the business now. It starts from what shipped, changes the minimum, proves the
fix with a test that failed first, goes through an expedited but real review,
reaches every edition that carries the bug (hosted, self-hosted, mobile), and
leaves an audit trail a customer, auditor or post-mortem can follow.

Resolved config above is used as-is. A key that did not resolve is treated as
the stricter reading, never the looser one.

**What this skill runs and what it only prints.** It runs read-only git
(`log`, `tag --list`, `branch --list|--contains`, `diff`, `show`, `status`), the
branch creation `git checkout -b hotfix/*` after the Phase 4 yes, the regression
and targeted test commands (`go -C`, `pnpm -C`, `./gradlew -p`, `swift test`), and
the other skills it calls through the `Skill` tool (`/smoke-check`, `/team-qa`,
`/bug-report`, `/release-notes`). **`git merge`, `git tag`, `git cherry-pick`,
`git push`, deploys and store or bundle publishing are never pre-approved.** Each
is either printed as an exact command for the user to run, or, after the Phase 8
per-action yes naming that one command, run by this skill through the ordinary
permission prompt (so the user sees it a second time). A yes to the Phase 8
question authorises the plan, not a blanket run: merge, tag, cherry-pick and
backport are each confirmed in turn. Deploy, push and publish are performed by
`platform-lead`/`release-manager` or by the user, never here.
---

## Phase 1: Assess Severity

Read the bug description or ID (`production/qa/bugs/`). Assess severity on
`/bug-triage`'s scale and `qa-lead`'s severity rules:

- **S1 (Critical)**: outage, data loss or corruption, **cross-tenant data
  exposure**, credential or secret exposure, billing or licensing broken for
  many customers, security vulnerability being exploited or trivially
  exploitable. Rate a security issue by its impact, not by how few reports exist.
- **S2 (High)**: a major journey is broken or badly degraded for a tenant
  segment, but the product is usable; a serious vulnerability with a workaround
  or limited reach.
- **S3 or lower**: degraded with a workaround, or cosmetic — the normal bug
  fix workflow and the next release apply.

Confirm with `AskUserQuestion`:
- Prompt: "I've assessed this as **[assessed severity]** — [brief rationale]. Confirm severity to proceed:"
- Options:
  - `[A] S1 (Critical) — outage, data loss/exposure, billing or licensing broken, active security issue`
  - `[B] S2 (High) — major journey broken, product still usable`
  - `[C] S3 or lower — redirect to normal bug fix workflow`

If [C]: stop. Verdict: **REDIRECTED** — use the normal bug fix workflow for S3 and below.
If no bug description or ID is given and none can be asked for, close with
`BLOCKED — no bug to assess`.

### Phase 1b: Triage questions (answer before any code)

Record the answers in the hotfix record. Ask the user for the ones you cannot
read from the repo, logs or dashboards.

1. **Is it a security issue?** If yes: the fix is developed on a **private
   branch**, nothing about the weakness goes into a public commit message, PR
   title, release note or status page until the fix is available to every
   affected edition, and `appsec-engineer` reviews it (Phase 5). If a
   vulnerability is *actively exploited*, say so, and treat Phase 2's mitigation
   as urgent.
2. **Is data exposed?** `No`, `Suspected` or `Confirmed`. Suspected or Confirmed
   starts the Breach Notification section of
   `.claude/docs/templates/incident-response.md` now and brings in
   `security-lead` and `privacy-compliance-specialist` (Egypt PDPL / GDPR
   notification duties and deadlines come from them — never from memory).
3. **Which editions carry the bug?** Hosted, self-hosted (which versions —
   `git tag --list`, the upgrade matrix), Android build(s), iOS build(s), web.
   A fix that reaches only one edition is not finished.
4. **Which tenants are affected?** All, a plan, named enterprise tenants, unknown.

---

## Phase 2: Mitigate, then decide whether a code fix is needed

A hotfix is the slowest remedy, not the first. Before writing code, list what
can stop the damage **now** and ask which to apply:

- Roll back the last deploy (hosted) to the previous image digests — only if the
  migration that shipped with it was expand-only and the previous app version is
  compatible with the migrated schema (production migrations are forward-only;
  there is no down migration to run)
- Turn the feature off (flag / kill switch / config)
- Rate-limit, block or WAF-rule the offending path or tenant
- Pause a job, queue consumer or webhook delivery
- For mobile: halt the staged rollout; keep the previous build live; mitigate
  server-side
- Status-page notice (draft only — `customer-success` sends)

`AskUserQuestion` — "Apply a mitigation first?" with the applicable options and
`[Z] No mitigation — go straight to the fix`. Record the choice and time in the
audit log. Applying a mitigation does **not** end the hotfix: a mitigation that
only hides the bug is tracked as an open risk until the fix ships.

If the bug is a bad deploy that rollback fully resolves and nothing needs
fixing in code, say so: Verdict **REDIRECTED** to `/incident` (if available) /
the rollback runbook in `docs/runbooks/`.

---

## Phase 3: Create the Hotfix Record

Draft the hotfix record from **`references/hotfix-record.md`**. Fill in what is
known (severity, blast radius, mitigation, editions, security/data-exposure
flags); leave Root Cause, Fix, Regression test and Testing to be completed as
the work proceeds.

Ask: "May I write this to `production/hotfixes/hotfix-[date]-[short-name].md`?"

If the user declines, close with `BLOCKED — write declined by user`: no record, no
branch and no code change follow, because an emergency fix earns its audit trail
before the work starts. The mitigation decided in Phase 2 is unaffected.

If yes, write the file, creating the directory if needed. From here on, append
to the Audit log in the record for every approval, decision and deployment.

---

## Phase 4: Create the Hotfix Branch

Check whether this is a git repository:

`Bash: git rev-parse --is-inside-work-tree`

If it fails or returns empty: note "Not a git repository — create the branch
manually." and skip branch creation.

`[base-ref]` is the **released tag** the bug is in. Releases are tags on `main`
(the trunk); use that release's tag (`git tag --list`; the newest is usually the
live hosted build) — or its `release/*` branch, if one was cut to stabilise it
(`git branch --list 'release/*'`). **Never the head of `main`**: it may carry
work that has not shipped, and a hotfix built from it would ship that work
unreviewed. If the bug is in several supported self-hosted versions, list each
base-ref: one fix is developed once and applied to each supported line
(Phase 8).

If the check passes, use `AskUserQuestion` before creating the branch:
- Prompt: "Ready to create hotfix branch 'hotfix/[short-name]' from [base-ref]?"
- Options:
  - `[A] Yes — create branch`
  - `[B] Use a different base ref — I'll specify it`
  - `[C] Skip — I'll create the branch myself`

Only run `git checkout -b hotfix/[short-name] [base-ref]` on [A]. On [B]: ask
for the ref, then run it. On [C]: skip and proceed. For a security fix, name the
branch neutrally (`hotfix/[date]-[ticket]`, not `hotfix/tenant-leak-exports`) and
do not push it to a public remote.

---

## Phase 5: Investigate and Propose

Find the root cause — **proven**, with the trace, log line, query or commit
that shows it (route to `debugger` for anything not obvious; a guessed cause is
not a root cause). Draft the **minimal** fix: which files change, what the
change does, what it deliberately leaves alone. Do NOT refactor, clean up or
add features alongside the hotfix.

Constraints on the fix itself:

- **No schema change unless unavoidable.** If one is needed it is
  expand-only and backwards-compatible with the previous app version
  (`.claude/rules/migrations.md`), reviewed by `migration-specialist`, and has a
  stated path for self-hosted upgrade.
- **No new dependency, no contract change** unless the bug cannot be fixed
  otherwise; a contract change needs `api-designer` and a compatibility note.
- Tenant-scoping rules, error mapping and secret handling are not relaxed
  "just for the hotfix" (`.claude/docs/coding-standards.md`).
- If the fix touches `deploy/self-hosted/`, it respects the licence decisions in
  `.claude/docs/standing-decisions.md` (L1–L4) — the emergency is not a reason to ship a
  component that is excluded from customer bundles.

Present the root cause and proposed fix, then ask: "May I implement this fix?"
If the user declines, close with `STOPPED — fix declined by user` (the record stays
IN PROGRESS, the mitigation of Phase 2 stays on, and the open risk is named).
Do not modify any code before this approval — an emergency flow earns its audit
trail by approving the change *before* it exists, not after.

### Phase 5b: Implement (only after approval)

1. **Regression test first.** Write the smallest test that reproduces the bug at
   the right layer (domain/use case unit test, Testcontainers integration test,
   contract test, or a negative security test: wrong tenant, wrong role). Run it
   and **confirm it fails for the reason in the root cause.** Record the failure
   in the hotfix record. A hotfix without a regression test is declined unless
   the user waives it in writing in the record with a reason (and a follow-up
   story is created).
2. Implement the approved minimal change through the stack lead for the layer
   (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`), routed by
   `principal-engineer`.
3. Run the regression test (must pass) and the targeted suites for the affected
   context, using the commands in the product's own scripts and CI — never a
   command written from memory. Check adjacent contexts for regressions.
4. If no test command can be sourced, or no suite covers the affected area,
   say so and record `Tests: NOT RUN — [reason]` in the Testing section; the
   Phase 7 QA gate then carries the verification.
5. Update the record with root cause, fix details, test names and results.

---

## Phase 6: Collect Approvals

Use the `Agent` tool to request sign-off **in parallel** (issue every call
before waiting for any result; collect all results; if an agent is BLOCKED,
surface it — never skip silently):

- `principal-engineer` — correctness, side effects, clean-architecture and DoD gate impact
- `appsec-engineer` — **required for any security-related fix, and for any fix touching authn/authz, tenancy, billing, uploads or PII**; reviews the diff, runs the negative tests, checks the dependency scan, and states whether the fix fully closes the issue. `security-lead` additionally signs off cross-tenant exposure, credential exposure, and billing/licence bypass fixes (gates `SL-TENANT-ISOLATION`, `SL-RELEASE-SECURITY` apply to the wording and rollout)
- `qa-tester` — runs targeted regression tests on the affected area and exercises the negative path on the running stack (`.claude/docs/run-and-observe.md`)
- `platform-lead` — the deploy plan: zero-downtime, health checks, migrations, rollback; builds the self-hosted patch artifact
- `producer` — approves deployment timing and the communication plan (with `customer-success` drafting customer-facing text)
- For S1: `sre-lead` — detection gap, runbook, SLO impact, rollback readiness (gate `SRE-OPERABILITY` informs the review)

All must return APPROVE before proceeding. Any CONCERNS or REJECT: do not
deploy — surface it, resolve it, and repeat that review. If the user chooses to stop
instead of resolving it, close with `STOPPED — approvals not obtained` naming each
reviewer and their result. A review that did not
run is reported as **not run**, never as approved. Record each result and time
in the Audit log.

---

## Phase 7: QA Re-Entry Gate

After approvals, decide the QA scope before deploying. Spawn `qa-lead` via
`Agent` with: the hotfix description and affected context, the regression test
results, and the list of contexts/modules that touch the changed files (use
Grep to find callers; check every code root from `resolve_code_root`).

Ask `qa-lead`: **is a smoke check sufficient, or does this fix need a targeted
`/team-qa` pass?**

Apply the verdict:

- **Smoke check sufficient** — run `/smoke-check` against the hotfix build on
  the dev stack. If PASS or PASS WITH WARNINGS, proceed (carry warnings into the
  record). If **FAIL**, do not deploy: return to Phase 5 with the failing
  checks, get the revised fix approved, implement it (Phase 5b), then re-run
  Phase 6's approvals — `qa-tester`'s regression run among them — and this gate.
  A hotfix that breaks the smoke suite is a second incident, not a fix.
- **Targeted QA pass required** — run `/team-qa feature: [affected-context]`
  scoped to the changed area. APPROVED or APPROVED WITH CONDITIONS proceeds;
  NOT APPROVED or BLOCKED is handled as a smoke FAIL.
- **Full QA required** — S1 fixes touching core contexts (identity, tenancy,
  billing, licensing) may need a full `/team-qa`. This delays deployment but
  prevents a bad patch.
- **Surfaces** — if the fix ships in the web app, Android or iOS, include the
  matching `--surface` check, in English and Arabic (RTL).

**If the QA step returns `NOT ASSESSED`, the gate did not run — treat it as
unmet, not as met.** `/smoke-check` returns it when the suite never executed and
`/team-qa` when a cycle produced no executed evidence. A NOT ASSESSED result is
not a pass, from either skill; under time pressure the permissive reading is the
one that will feel reasonable, which is exactly why it is written down here.
Either obtain the missing result — the verdict names what would make it
runnable — or take the decision to the producer explicitly, as a decision to
deploy an unverified hotfix rather than a gate that quietly cleared. Log that
decision — who made it and why — in the record's Testing section.

Do not skip this gate. A hotfix that breaks something else is worse than the
original bug.

---

## Phase 8: Deploy, Release and Backport

> **STOP — merge, tag, deploy and publish each require explicit approval,
> unconditionally.** These are the irreversible acts in this skill. Before any
> of them use `AskUserQuestion`:
>
> - Prompt: "Hotfix validated and approved. Proceed with: merge to [targets],
>   tag [patch tag], deploy hosted, publish self-hosted patch [version], submit
>   mobile build(s)?" — `[targets]` is `main`, plus each supported
>   `release/*` branch that has one.
> - Options: `[A] Yes — proceed with all listed` / `[B] Merge to main only —
>   hold the release` / `[C] Hosted deploy only — hold self-hosted and mobile` /
>   `[D] Stop here`
>
> This holds regardless of `modes.automation`. Never push, tag or deploy without
> the answer. The answer authorises the plan; `git merge`, `git tag` and
> `git cherry-pick` are then each confirmed by name (or printed for the user) and
> are not in this skill's pre-approved tools.

On `[A]` (each command below is run only after its own yes, or printed — see the
note under the title):

1. **Merge and tag.** Merge the hotfix branch to `main`, and to each supported
   `release/*` branch that exists; tag the patch release (the next patch
   version, e.g. `v2.4.0` → `v2.4.1`) on the fixed build — the `release/*` head
   if there is one, else the hotfix branch head — and deploy that tag, not the
   head of `main`. A security fix is merged with a neutral commit message
   (`fix:` / `security:` type, story/task ID, no exploit detail).
2. **Hosted.** `platform-lead` deploys the tag using the zero-downtime procedure
   in `.claude/rules/deploy.md` (migration job first if any, start new, health,
   switch, stop old). Watch the dashboards and SLO burn for the agreed window;
   record the observed result in the record.
3. **Self-hosted patch release.** `release-manager` builds the patch bundle for
   each supported self-hosted line: versioned, **signed**, SBOM attached,
   upgrade-from versions stated, backup-before-upgrade preserved, rollback
   documented, licence format unchanged unless the fix is in `licensing`. The
   bundle is published to the self-hosted release channel only after the signed
   artifact and its install/upgrade test pass (`/smoke-check --surface
   self-hosted`). Customers are told by `customer-success` using
   `/release-notes` with the Upgrade Notes block; security wording follows
   `/release-notes`' responsible-disclosure rules and waits for the fix to be
   available to all editions.
4. **Mobile.** If the bug is in the app itself: `release-manager` prepares the
   store submission, requests expedited review where the store allows it, and
   uses staged rollout; until the fix is live, the server-side mitigation from
   Phase 2 stays on. The plan must say that users on old builds remain exposed.
5. **Backport.** Apply the fix to every supported older line that carries the
   bug (cherry-pick onto each `release/*` branch or tag-line), each with its own
   regression test run and its own patch tag.

On `[B]`: merge to `main` only — no release-branch merge, no tag, no deploy,
no publish. On `[C]`: tag and deploy hosted; self-hosted and mobile stay open
actions in the record. On `[D]`: stop — no merge, no tag, no deploy and no bug-file
update; the record's Status stays IN PROGRESS, and say so.

> **Backport is not verified unless you verify it.** After merging, confirm
> the fix is present on `main` (the trunk) and on each supported `release/*`
> branch or maintenance line — for example `git branch --contains <fix commit>`
> or `git log <branch> --grep` — and state the result in the record's Backport
> table. An unbackported hotfix means the bug returns in the next release tagged
> from `main`, the single most common hotfix regression. Any line not checked is
> listed as **NOT VERIFIED**, with what was not checked.

Update the original bug file if one exists — find it in `production/qa/bugs/`
by number, as `/bug-report verify` does. Ask first: "May I update
`production/qa/bugs/[bug file]` with the fix record below and set its Status to
`Fixed — Pending Verification`?"

```markdown
## Fix Record
**Fixed in**: hotfix/[branch-name] — [commit hash or description]
**Released as**: [patch tags per edition]
**Fixed date**: [date]
**Status**: Fixed — Pending Verification
```

Output a deployment summary. Its title follows the Phase 8 answer — `Hotfix
Deployed: [short-name]` on `[A]`, `Hotfix Merged to main — release held:
[short-name]` on `[B]`, `Hotfix Deployed (hosted) — self-hosted and mobile held:
[short-name]` on `[C]`:

```
## Hotfix Deployed: [short-name]

**Severity**: [S1/S2]
**Security-related**: [No | Yes — disclosure status]
**Root cause**: [one line]
**Fix**: [one line]
**Regression test**: [name — failed before / passes after]
**QA gate**: [Smoke check PASS / Team-QA APPROVED / NOT ASSESSED — [why, and whose
             explicit decision it was to deploy anyway]]
**Approvals**: principal-engineer ✓ / appsec-engineer ✓ or n/a (not security) /
               qa-tester ✓ / platform-lead ✓ / producer ✓
**Editions**: hosted [deployed time] · self-hosted [patch versions / held] ·
              Android [submitted / held / n/a] · iOS [submitted / held / n/a]
**Backport**: [verified present on main and each supported line — or NOT VERIFIED, with what was not checked]
**Rollback plan**: [from the record]
**Customer communication**: [status page / release notes / advisory — sent by whom / pending]

Merge to: [targets] · Tag(s): [patch tags]
Next: /bug-report verify [BUG-ID] after deploy to confirm resolution
```

### Rules
- Hotfixes are the MINIMUM change to fix the issue — no cleanup, no refactoring
- Every hotfix has a regression test that failed before the fix, or a written waiver with a follow-up story
- Every hotfix has a rollback plan documented before deployment
- Security fixes are reviewed by `appsec-engineer`; disclosure waits until the fix is available to every affected edition
- A hotfix branch starts from the release it fixes — its tag, or its `release/*` branch if one exists — never from the head of `main`
- The fix merges to `main` and to every supported maintenance line that carries the bug; the patch release is tagged on each
- Self-hosted customers get a signed, versioned patch with upgrade notes; mobile users on old builds are called out
- Every decision, approval and deployment is in the record's Audit log, with time and who
- All hotfixes get a post-incident review recorded within 48 hours (the incident record complete and the postmortem decision made); a blameless postmortem is due within 5 working days of resolution for SEV1/SEV2 (`sre-lead`, as `/incident` and `/postmortem` state)
- If the fix is complex enough to need more than 4 hours, escalate to `cto`

---

## Phase 9: Post-Deploy Verification

After deploying, run `/bug-report verify [BUG-ID]` to confirm the fix resolved
the issue in the deployed build, and check the SLI/error rate that raised the
alarm is back in range (`sre-lead`).

- **VERIFIED FIXED**: run `/bug-report close [BUG-ID]` to formally close it.
- **STILL PRESENT**: the hotfix failed — immediately re-open, assess rollback
  using the Rollback Plan, escalate to `cto`.
- **CANNOT VERIFY**: the fix is unconfirmed — do not close the bug; exercise the
  reproduction steps on the deployed build (or the nearest equivalent), then run
  `/bug-report verify [BUG-ID]` again and answer its manual question.

Record the post-incident review within 48 hours (SEV1/SEV2: the blameless postmortem itself is due within 5 working days of resolution). `/retrospective` reviews a
sprint or milestone, not an incident: record the review with
`.claude/docs/templates/incident-response.md` (and `post-mortem.md` for a deeper
blameless review of S1/S2), file it in **`production/incidents/`** (the same place
`/incident` and `/postmortem` write; the hotfix record itself stays in
`production/hotfixes/` and links to it), and raise its lessons at the next
`/retrospective`. If the cause was a missing test, alert or
runbook, create the follow-up stories — a hotfix without prevention work is half
done.

Verdicts: **DEPLOYED** (all targeted editions, backport verified) ·
**PARTIAL** (some editions or lines held or NOT VERIFIED — list them) ·
**HELD** (merged, release held) · **STOPPED** (never reached a release: declined
fix, approvals not obtained, or `[D]` at Phase 8) · **REDIRECTED** ·
**BLOCKED** (`write declined by user`, or no bug to assess). A hotfix whose
QA gate or review did not run is **NOT ASSESSED** until the user explicitly
takes that decision; it is never reported as deployed-and-clean.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/hotfix [BUG-ID] —
<verdict>`, Next step = the first step that applies (`/bug-report verify
[BUG-ID]` or `/bug-report close [BUG-ID]` per Phase 9, `/smoke-check`, or on
HELD / PARTIAL / NOT ASSESSED the held edition or unrun gate that must be
cleared), plus Blocked on / Files in progress (hotfix record, branch) / Open
questions; append the Notes line. A run that ends before Phase 9 (`STOPPED`,
`REDIRECTED`, `BLOCKED`) updates the checkpoint at that point with the blocker.

Use `AskUserQuestion`:
- Prompt: "Hotfix complete. What's the next step?"
- Options:
  - `[A] Run /smoke-check to verify the fix`
  - `[B] Run /release-notes to write the customer-facing notes (and advisory if security)`
  - `[C] Stop here`

## Collaborative Protocol

Question → Options → Decision → Draft → Approval at every phase. Severity,
mitigation, branch, fix scope, approvals, QA scope, merge/tag/deploy/publish
each get their own explicit user decision. The record is written before any
code changes and updated as work proceeds. Nothing in this skill pushes,
tags, deploys, publishes or messages customers without a yes.
