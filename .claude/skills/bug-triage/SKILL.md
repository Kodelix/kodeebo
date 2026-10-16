---
name: bug-triage
description: "Re-evaluate open bugs — priority vs severity, assign to sprints, route security bugs to security-lead with an SLA, link regressions, surface systemic trends. Run when the count grows."
argument-hint: "[sprint | full | trend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/bug-triage/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Bug Triage

This skill processes the open bug backlog into a prioritised, sprint-assigned
action list. It distinguishes between **severity** (how bad is the impact?) and
**priority** (how urgently must we fix it?), routes **security bugs to
`security-lead` with a fix SLA**, links **regressions** to the change that
introduced them, detects systemic trends, and ensures no critical bug is lost
between sprints.

**Output:** `production/qa/bug-triage-[date].md`

**When to run:**
- Sprint start — assign open bugs to the new sprint or backlog
- After `/team-qa` completes and new bugs have been filed
- When the bug count crosses 10+ open items
- Immediately, for any newly filed S1 (do not wait for the cadence)

---

## 1. Parse Arguments

**Modes:**
- `/bug-triage sprint` — triage against the current sprint; assign fixable bugs
  to the sprint backlog; defer the rest
- `/bug-triage full` — full triage of all bugs regardless of sprint scope
- `/bug-triage trend` — trend analysis only (no assignment); **read-only**: the
  metrics are shown in conversation and **nothing is written** (Section 6 is
  skipped; the bug files and the triage report directory are untouched)
- No argument — run sprint mode if a current sprint exists, else full mode

---

## 2. Load Bug Backlog

### Step 2a — Discover bug files

Glob for bug reports in priority order:
1. `production/qa/bugs/*.md` — individual bug report files (preferred format)
2. `production/qa/bugs.md` — single consolidated bug log (fallback)
3. Any `production/qa/qa-plan-*.md` "Bugs Found" table (last resort)

If no bug files found:
> "No bug files found in `production/qa/bugs/`. If bugs are tracked in a
> different location, adjust the glob pattern. If no bugs exist yet, there is
> nothing to triage."

Stop and report. Do not proceed if no bugs exist. Verdict: **NOT ASSESSED —
no bug files found** in the three locations searched (`production/qa/bugs/*.md`,
`production/qa/bugs.md`, the QA-plan "Bugs Found" tables); no external tracker was
consulted. This is "nothing found where I looked", never "no open bugs" — it must
not read as a clean backlog.

**In `trend` mode, do not read full bug bodies.** Trend metrics (volume, severity
mix, by-context, by-date) are computable from the header fields alone:
```
Grep pattern="\*\*(Severity|Priority|Status|Reported|Confidential|Origin)\*\*|\*\*(Category|Layer|Regression|Feature / bounded context)\*\*" glob="production/qa/bugs/*.md" output_mode="content"
```
(Bug-report fields are bolded — `**Severity**:`, `- **Layer**:` — so match the
`**field**` form, not a bare line-start `Field:`.)
Full bug bodies are needed only for the priority-vs-severity **re-evaluation** in
`sprint`/`full` modes; `trend` is a read-only report and skips it. (The one
deviation check that needs a story's status — "bug filed against a Complete
story" — is a targeted story-status grep either way, not a bug-body read.)

**A bug file whose Severity or Status cannot be parsed** is listed under
`Unparsed` in the report and counted as open — never silently dropped, and
never assumed S4. It also reaches the verdict (Section 6): the run cannot close
as a clean COMPLETE while any file is unparsed.

### Step 2b — Load sprint context

Read the most recently modified file in `production/sprints/` to understand:
- Current sprint number / name
- Stories in scope (for assignment target)
- Sprint capacity constraints (if noted)

If no sprint file exists: note "No sprint plan found — assigning to backlog only." At `workflow: minimal` there are no sprints by design — say that instead, and name the P1 bugs as the next fixes, ahead of the next story in the brief's build order (`design/product-brief.md`).

### Step 2c — Load severity reference

Read `.claude/agents/qa-lead.md` (the severity rule, "Senior Bar") and
`.claude/docs/security-baseline.md` (vulnerability SLAs live in
`.claude/agents/security-lead.md`). If they cannot be read, use the definitions
in Step 3, say so in the report's header, and let it lower the verdict to
COMPLETE WITH GAPS (Section 6).

---

## 3. Classify Each Bug

For each bug, extract or infer:

### Severity (impact of the bug)

Rule-based, as `qa-lead` assigns it — the bug's `rule matched` clause is the
authority; this table is the same rule restated.

| Severity | Definition |
|----------|-----------|
| **S1 — Critical** | Data loss or corruption, **cross-tenant exposure**, security breach or vulnerability, payment or licence failure, outage of a critical journey, or crash on launch. |
| **S2 — High** | Core journey broken with no workaround, or a regression of a shipped feature. |
| **S3 — Medium** | Degraded behaviour with a workaround. |
| **S4 — Low** | Cosmetic or copy. |

A bug whose recorded severity contradicts its own description (a "S3" that
describes another tenant's data on screen) is flagged `Severity disagrees with
rule — proposed S1` and presented as a recommendation. Severity is objective;
the user and `qa-lead` confirm.

### Priority (urgency of the fix)

| Priority | Definition |
|----------|-----------|
| **P1 — Fix this sprint** | Blocks QA, blocks release, is a regression from the last release, or is any open S1 |
| **P2 — Fix soon** | Should be resolved before the next major milestone |
| **P3 — Backlog** | Would be good to fix, but no active blocking impact |
| **P4 — Won't fix / Deferred** | Accepted risk or out of scope for current product scope |

Release gate reminder: any open S1 or S2 blocks a release (S2 only with a
written exception approved by the user, and none at `workflow: full`); an S3
needs a named owner, ticket and target release. S4 never blocks. Those bugs are
P1 unless the release is not the next one.

### Security routing (all tiers, every mode that assigns)

A bug is **security-related** when its Category is `Security` or `Authorization
& tenancy`, it is marked Confidential, or its text describes cross-tenant
access, credential/token exposure, injection, authentication or authorization
bypass, or licence/billing forgery. For each:

- **Route to `security-lead`** — name it in the report's Security Routing table. `security-lead` owns severity of the vulnerability, the exception register and the decision on customer notification for self-hosted editions; triage does not accept the risk.
- **Set the fix SLA** from triage date (`security-lead` default policy, changed only by ADR): **critical 48 h** (fix or mitigate) · **high 7 days** · **medium 30 days** · **low 90 days**. Reachability, exposure and data class decide the level, not a CVSS score alone; a cross-tenant read is never below high. Write the due date; a past-due date is flagged `SLA BREACHED`.
- **Never close as P4/Won't fix** without `security-lead` and the user: an accepted security risk is a register entry with an owner and an expiry date.
- **Keep details out of the report.** Confidential bugs appear by ID, category and due date only.
- A suspected cross-tenant exposure found while triaging is announced in conversation at once (S1), not left for the written report.

### Regression links

For each bug whose Regression field is `Yes`, or that is filed against a Complete story or a shipped release:
- Link the **story** (and its epic) whose behaviour broke, and the **release/version** that shipped it or the last known good version.
- If a diagnosis exists (`/debug` record or `git bisect` result in the bug file), cite the first-bad commit; if not, say `first-bad commit: not established — /debug`.
- Check the bug has a regression test path (or a stated reason it cannot); a fixed regression with none is listed under Recommended Actions (`/regression-suite`).
- A regression in a completed story → "story should be re-opened in sprint tracking".

### Assignment

For each P1/P2 bug in `sprint` mode:
- Identify which story or epic the fix belongs to
- Check whether the current sprint has remaining capacity
- If capacity exists: assign to sprint (`Sprint: [current]`)
- If capacity is full: flag as `Priority overflow — consider pulling from sprint`

For `full` mode: assign all P1 to current sprint, P2 to next sprint estimate,
P3+ to backlog.

Fixes route to the owning stack lead through `principal-engineer`; an S1/S2 in
production goes to `/hotfix`. Triage assigns, it does not fix.

### Deviation check

Flag bugs that suggest **systematic problems**:
- 3+ bugs from the same bounded context in the same sprint → "Potential design or
  implementation quality issue in [context]"
- 2+ S1/S2 bugs in the same story → "Story may need to be reopened and
  re-reviewed before shipping"
- Bug filed against a story marked Complete → "Regression in completed story —
  story should be re-opened in sprint tracking"
- 2+ authz/tenancy bugs in one repository or module → "Tenant-scoping pattern is
  probably wrong at the root — run `/tenant-check` on [module]"
- Same provider/integration failing repeatedly → "Integration fault — review the integration spec"

---

## 4. Trend Analysis

After classifying all bugs, generate trend metrics:

### Volume trends
- Total open bugs: [N]
- Opened this sprint: [N]
- Closed this sprint: [N]
- Net change: [+N / -N]

### Hot spots
- Which bounded context / layer has the most open bugs?
- Which has the highest S1/S2 ratio?
- Hosted-only vs self-hosted-only vs both

### Age analysis
- How many bugs are older than 2 sprints?
- Are any S1/S2 bugs un-assigned (sprint = none)?
- How many security bugs are past their SLA date?

### Regression indicator
- Any bugs filed against previously-completed stories or shipped releases?
- Count: [N] regression bugs (story reopened implied)

---

## 5. Generate Triage Report

```markdown
# Bug Triage Report

> **Date**: [date]
> **Mode**: [sprint | full | trend]
> **Generated by**: /bug-triage
> **Open bugs processed**: [N] ([N] unparsed, listed below)
> **Sprint in scope**: [sprint name, or "N/A"]

---

## Triage Summary

| Priority | Count | Notes |
|----------|-------|-------|
| P1 — Fix this sprint | [N] | [N] assigned to sprint, [N] overflow |
| P2 — Fix soon | [N] | Scheduled for next sprint |
| P3 — Backlog | [N] | Deferred |
| P4 — Won't fix | [N] | Accepted risk |

**Critical (S1/S2) unfixed count**: [N]
**Release-blocking now** (open S1, or S2 without an approved exception): [N]

---

## Security Routing

| ID | Severity | Category | Routed to | Triage date | Fix due (SLA) | State |
|----|----------|----------|-----------|-------------|---------------|-------|
| BUG-NNNN | S[1-2] | [category] | security-lead | [date] | [date] ([48 h / 7 d / 30 d / 90 d]) | [on time / SLA BREACHED] |

[Or "No security-related bugs open."]

---

## P1 Bugs — Fix This Sprint

| ID | Context / layer | Severity | Summary | Assigned to | Story |
|----|-----------------|----------|---------|-------------|-------|
| BUG-NNNN | [context] / [layer] | S[1-4] | [one-line description] | [sprint] | [story path] |

---

## P2 Bugs — Fix Soon

| ID | Context / layer | Severity | Summary | Target Sprint |
|----|-----------------|----------|---------|---------------|
| BUG-NNNN | [context] / [layer] | S[1-4] | [one-line description] | Sprint [N+1] |

---

## P3/P4 Bugs — Backlog / Won't Fix

| ID | Context / layer | Severity | Summary | Disposition |
|----|-----------------|----------|---------|-------------|
| BUG-NNNN | [context] / [layer] | S4 | [one-line description] | Backlog |

---

## Regressions

| ID | Broke (story / feature) | Introduced in (release / first-bad commit) | Regression test | Story reopened? |
|----|-------------------------|---------------------------------------------|-----------------|-----------------|
| BUG-NNNN | [story path] | [version, commit or `not established — /debug`] | [path or `none`] | [yes / no] |

[Or "No regressions."]

---

## Systemic Issues Flagged

[List any patterns from Step 3 deviation check, or "None identified."]

---

## Trend Analysis

**Volume**: [N] open / [+N] net change this sprint
**Hot spot**: [context or layer with most bugs]
**Regressions**: [N] bugs against completed stories or shipped releases
**Aged bugs (>2 sprints old)**: [N]

[If N aged S1/S2 bugs > 0:]
> WARNING: [N] high-severity bugs have been open for more than 2 sprints without
> assignment. These represent accepted risk that should be explicitly reviewed.

---

## Unparsed

[Bug files whose Severity/Status could not be read, with the path — or "None."]

---

## Recommended Actions

1. [Most urgent action — usually "fix P1 bugs before QA hand-off" or the S1 security item]
2. [Second action — usually "investigate [hot spot] quality"]
3. [Third action — optional improvement]
```

---

## 6. Write and Gate

Present the report in conversation. In `trend` mode stop here: nothing is written
and no question is asked (closing verdict below). Otherwise, if any bug is a P4 candidate, first ask
"Are these acceptable as Won't Fix?" and keep its disposition `P4 candidate`
until the user answers (security bugs are never P4 without `security-lead`).
Then ask:

"May I write this triage report to `production/qa/bug-triage-[date].md`?"

Write only after approval.

After writing:
- If any S1 bugs are unassigned: "S1 bugs must be assigned before the sprint
  can be considered healthy. Run `/sprint-status` to see current capacity."
- If any security bug is `SLA BREACHED`: name it and `security-lead`; this is the
  user's decision, not a note to file.
- If regression bugs exist: "Regressions found — consider re-opening the
  affected stories in sprint tracking and running `/smoke-check` to re-gate."
- Unknown-cause S1/S2 bugs: "Run `/debug [BUG-ID]` for a proven root cause before assigning a fix."
- If no P1 bugs exist: "No P1 bugs — build is in good shape for QA hand-off."

The "good shape for QA hand-off" line is printed only when no file is listed
under Unparsed — otherwise say which files were not assessed instead.

Closing verdict, first match wins:
- **BLOCKED — write declined by user** — the user declined the report write
  (`sprint` / `full`); the triage stays in conversation, marked not recorded.
- **NOT ASSESSED — [N] bug file(s) unparsed** — any file is under Unparsed. The
  other bugs are triaged and the counts say "excluding [N] unparsed"; the unparsed
  ones are counted as open and are the first recommended action.
- **COMPLETE WITH GAPS** — everything parsed, but the severity reference
  (`qa-lead.md` / `security-baseline.md`) could not be read and Step 3's
  definitions were used (name which).
- **COMPLETE** — triage report written (`sprint` / `full`), or the trend report
  shown (`trend`; nothing written by design).

**Checkpoint.** Unless the run was `trend` mode (read and report only), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/bug-triage <mode> — <verdict>`, Next step = the first recommended
action (assign unassigned S1 bugs, the unparsed files, or
`/debug [BUG-ID]`), plus Blocked on / Files in progress / Open questions; append
the Notes line. Still updated on `BLOCKED` / `NOT ASSESSED` (a declined write
records nothing written and why).

---

## Collaborative Protocol

- **Never close or mark bugs Won't Fix without user approval** — surface them
  as P4 candidates and ask: "Are these acceptable as Won't Fix?"
- **Never accept a security risk** — route to `security-lead`; acceptance is a
  register entry with owner and expiry, signed by the user
- **Never auto-assign to a sprint at capacity** — flag overflow and let the
  sprint owner decide what to pull
- **Severity is objective; priority is a team decision** — present severity
  classifications as recommendations, not mandates
- **Trend data is informational** — do not block work on trend findings alone;
  surface them as observations
- **A bug file that could not be read is reported as unparsed**, never as absent
  or low severity
