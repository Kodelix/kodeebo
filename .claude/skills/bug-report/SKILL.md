---
name: bug-report
description: "Structured bug report from a description, or analyze code for potential bugs. Repro steps, expected/actual, tenant/role/plan/environment/version, rule-based S1-S4 severity, redacted evidence; offers /debug for root cause."
argument-hint: "[description] | analyze [path-to-file] | verify [BUG-ID] | close [BUG-ID]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(curl * http://localhost:*), Bash(curl * http://127.0.0.1:*), Bash(go -C * test *), Bash(pnpm -C * test *), Bash(pnpm -C * run *), Bash(pnpm -C * exec playwright test *), Bash(./gradlew -p * *), Bash(swift test --package-path *), Bash(git log *), Bash(git rev-parse *), Bash(git status), Bash(git status *), Bash(git worktree add *), Bash(git worktree remove *), Bash(mktemp -d), Bash(mktemp -d *), Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Bug Report

Turns "it is broken" into a record an engineer can act on without asking the
reporter anything: what happened, to whom (tenant, role, plan), on which
version and environment, how to reproduce it, how bad it is **by rule**, and
what evidence exists. It also verifies and closes fixed bugs.

This skill **files and verifies**; it does not diagnose. Root cause is the
`debugger` agent's job (`/debug [BUG-ID]`) and the fix belongs to the owning
stack lead.

**Output:** `production/qa/bugs/BUG-[NNNN].md`

## Phase 1: Parse Arguments

Determine the mode from the argument:

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze [path]` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify [BUG-ID]` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close [BUG-ID]` → **Close Mode**: mark a verified bug as closed with resolution record

If no argument is provided, ask the user for a bug description before proceeding;
if none is given, close with `NOT ASSESSED — no bug description`. An `analyze`
target that does not exist or cannot be read closes with
`BLOCKED — [path] not found or unreadable`.

**Redaction rule, every mode.** A bug file is committed to the repository. It
never contains passwords, tokens, OTP codes, API keys, card data, national IDs,
or customer emails/phone numbers in clear — mask or hash them
(`observability-standard.md` "Never log"). Tenants are named by test-tenant name
or a hashed/short ID, never by customer name. Evidence is referenced by
location (trace ID, log query, screenshot path), not pasted wholesale.

---

## Phase 2A: Description Mode

1. **Parse the description** for: what broke, for whom (tenant, role, plan), on which version/environment, how to reproduce it, and what should have happened. For each field the description does not give, ask once (batch the questions) — an unknown stays `Unknown`, it is never guessed.

2. **Search the codebase** with Grep/Glob for related files to add context (affected bounded context, layer, likely files). Resolve layers with `bash .claude/hooks/yaml-helper.sh resolve_code_root`; an empty result means the search did not run — say so in **Technical Context** rather than listing no files.

3. **Classify the severity by rule.** Apply `qa-lead`'s S1–S4 rule and cite the clause that matched in the report; do not negotiate severity by deadline:

   | Severity | Rule |
   |---|---|
   | **S1 — Critical** | Data loss or corruption; **cross-tenant exposure**; security breach or any security vulnerability; payment or licence failure; outage of a critical journey; crash on launch |
   | **S2 — High** | Core journey broken with no workaround, or a regression of a shipped feature |
   | **S3 — Medium** | Degraded behaviour with a workaround |
   | **S4 — Low** | Cosmetic or copy |

   **Suspected S1 handling.** If the report suggests data loss, a security issue
   or a possible cross-tenant read/write, say so in conversation **immediately**
   (do not wait for the file write): "Possible S1 — [clause]. `security-lead`
   should be told now" (cross-tenant or credential impact) and offer `/incident`
   if it is live in production. Severity is a recommendation until `qa-lead`
   confirms; the report says `proposed`.

4. **Draft the bug report**:

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low] (proposed) — rule matched: [clause from the table above]
**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**Status**: Open
**Reported**: [Date]
**Reporter**: [the reporter's name as the user gives it, else `—`; never an email address or account ID taken from the session]
**Confidential**: [No / Yes — security-sensitive: exploit details kept out of this file, held by security-lead]
**Origin**: [Reported and reproduced / Reported, not yet reproduced / Found by code analysis, not reproduced]

## Classification
- **Category**: [Functional / Authorization & tenancy / Security / Data integrity / Billing & licensing / Performance / Reliability / UI / Accessibility & i18n / Integration (provider) / Install & upgrade (self-hosted)]
- **Feature / bounded context**: [spec stem or context — when the bug spans contexts, the one whose code must change; the others go under Related contexts]
- **Layer**: [backend / web / site / android / ios / kmp-shared / contracts / deploy / self-hosted bundle]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%) — over N attempts: N]
- **Regression**: [Yes — last known good version/commit / No / Unknown]

## Environment and Context
- **Version / commit**: [product version and commit hash; for clients, the app version/build]
- **Edition**: [Hosted (environment: production / staging / local compose) / Self-hosted (bundle version, upgrade path taken)]
- **Tenant**: [test-tenant name, or hashed/short ID — never a customer name]
- **Role**: [anonymous / member / admin / owner / platform operator]
- **Plan / entitlements**: [plan, relevant limits or flags]
- **Client**: [browser + version / device model + OS version / API client]
- **Locale and direction**: [en / ar (RTL)]
- **Feature flags / config**: [flags that differ from defaults]
- **Data shape**: [volume or shape that matters, e.g. "tenant with 40k rows"]

## Reproduction Steps
**Preconditions**: [Required state before starting — tenant, role, seeded data (`tools/seed/`)]

1. [Exact step 1 — request, click, command]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen — cite the spec/acceptance criterion if one exists]
**Actual Result**: [What actually happens — status code, error body (RFC 9457 `type`/`status`), screen]

## Impact
- **Who is affected**: [tenants / roles / plans / versions; hosted only, self-hosted only, or both]
- **Since when**: [version, date (UTC), or Unknown]
- **Data at risk**: [none / wrong data shown / data lost / data corrupted / another tenant's data reachable]
- **Workaround**: [none / describe]

## Technical Context
- **Likely affected files**: [List of files based on codebase search, or "code search did not run: [reason]"]
- **Related contexts**: [What other bounded contexts or providers might be involved]
- **Possible root cause**: [If identifiable from the description — a hypothesis, labelled as such]

## Evidence
- **trace_id(s)**: [one or more, with UTC timestamps — the fastest route to the failing request]
- **Logs**: [log query + the relevant lines, redacted]
- **Request / response**: [method, path, status, headers/body with secrets and PII redacted]
- **Visual**: [screenshot / recording path under `production/qa/evidence/BUG-[NNNN]/`]
- **Not available**: [evidence that does not exist, e.g. "self-hosted customer, telemetry off — logs supplied by customer"]

## Related Issues
- [Links to related bugs, stories, specs, threat models, incidents]

## Notes
[Any additional context or observations]
```

The **Severity** and **Priority** labels use `/bug-triage`'s S and P numbers and
names, which it parses out of this file. `P4-Won't fix` is its `P4 — Won't fix /
Deferred` (an accepted risk), not a wishlist. If you change either ladder, change
`.claude/skills/bug-triage/SKILL.md` too.

---

## Phase 2B: Analyze Mode

1. **Read the target file(s)** specified in the argument. Map each to its layer (`resolve_code_root`); a file outside every code root is analysed but its layer is `unresolved`.

2. **Identify potential bugs**, tagging the stack-neutral classes first:
   - **A query or cache/queue/file key that can reach another tenant's data** (missing tenant scope) — a candidate **S1**, reported at once
   - Missing authorization or object-level check on a resource access; tenant or role taken from the request body
   - Non-idempotent write that a client or webhook can repeat; missing timeout on an outbound call
   - Nil/null dereference, off-by-one, unchecked error, swallowed exception
   - Race conditions and unbounded concurrency (goroutine or coroutine per item, shared mutable state)
   - Resource leaks (connections, rows not closed, goroutines/coroutines never cancelled)
   - Unhandled edge cases: empty input, huge input, time zones, money rounding, partial failure
   - N+1 queries or an unbounded list (performance bugs that only show under data volume)

3. **For each potential bug**, generate a bug report with the template above, with the likely trigger scenario and recommended fix filled in. **Origin** is `Found by code analysis, not reproduced` and Frequency/Regression are `Unknown`: reading code does not establish that a bug exists. Offer `/debug` to turn each candidate into a proven one.

---

## Phase 2C: Verify Mode

**Find the bug file by its number**, here and in close mode: Glob
`production/qa/bugs/BUG-*.md` and take the file whose number matches `[BUG-ID]`,
whatever its zero-padding — an older three-digit file with a slug is found by
its number too. If none matches, stop: "No bug [BUG-ID] in `production/qa/bugs/`."
Verdict: **BLOCKED — no such bug**.

Read that file. Extract the reproduction steps and expected result.

1. **Re-run the reproduction** against a running stack where the bug is observable through the stack (`.claude/docs/run-and-observe.md`: `docker compose -f deploy/compose.dev.yaml up -d --wait`, the seeded test tenant, the same role). HTTP requests are `curl` to `http://localhost:<port>` or `http://127.0.0.1:<port>` only (the grant is scoped to those hosts); a bug reproduced on another environment is re-run by the user, who reports the result in step 4. Record the request/response or screenshot in `production/qa/evidence/[BUG-ID]/`. If the stack cannot be brought up, say `repro not re-run: [reason]` — Grep/Glob showing that the code path changed is **not** a re-run.
2. **Run the related test** — if the bug's feature has a regression test, run it with the command for its layer from the `layer-checks.md` table in `/dev-story`'s references folder (sourced from the stack reference), narrowed to the affected package/suite where the runner allows. This skill runs the layer's test line itself (granted: `go -C … test`, `pnpm -C … test|run`, `pnpm -C … exec playwright test`, `./gradlew -p …`, `swift test --package-path …`); anything else on that table (linters, scanners) is not run here. Never write a runner line from memory; a script name not defined in the project's own `package.json` or Gradle build is `not run — task not defined`. Report pass/fail with the real output. A fix for a bug that has **no** regression test is not verified by this step: say so.
3. **Check for siblings and regression** — grep the codebase for any new occurrence of the pattern that caused the bug. A cross-tenant or authz bug also needs the negative test (wrong tenant / wrong role) to exist and pass.
4. **Manual verification** — when no related test ran, the repro could not be re-run, or the bug's Category is UI / Accessibility & i18n (whose look no automated test checks), ask via `AskUserQuestion`: "Did you run the reproduction steps in [bug file] on a build with the fix? Which build/version, and on which environment?" —
   `[No longer occurs]` / `[Still occurs]` / `[Not run yet]`.
   Record the answer and the build as the user gives them; a changed code path is never taken as their answer.

Produce a verification verdict:

- **VERIFIED FIXED** — the bug is gone by every check that applies: the repro re-run (or the user's run) no longer reproduces it, any related test ran and passed, and, for S1/S2 and authz/tenancy bugs, a regression test exists and was seen failing on the unfixed commit and passing on the fixed one (`debugger` standard). **The unfixed-commit proof uses the scratch-worktree method (the one `/automate-test` uses)**: `git worktree add --detach <dir from mktemp -d> <pre-fix commit>`, run the test there with `-C`/`-p` pointing at the worktree, save the red output, then `git worktree remove <dir>` and confirm `git status` is clean. The working tree is never touched; no unfixed commit findable (`git log`) → the red proof is `not shown` and the bug stays short of VERIFIED FIXED. With no test run, a manual verification for a named build is the verification — recorded as such: `[user], manual, build [X]`. A changed code path on its own is never a pass
- **STILL PRESENT** — a related test fails on the bug's case, the repro still reproduces it, or the user answered `[Still occurs]`; the fix did not resolve the issue
- **CANNOT VERIFY** — step 4 was answered `[Not run yet]`, or nothing could run: name what is missing (stack would not start, no related test, layer toolchain absent, UI bug) and say that running the reproduction on a build with the fix settles it — run `/bug-report verify [BUG-ID]` again once done. Outranks VERIFIED FIXED; does not outrank STILL PRESENT

Ask: "May I update `production/qa/bugs/[bug file]` to set Status: Verified Fixed / Still Present / Cannot Verify?" — naming the file found above, whatever its padding or slug. With the Status, write a `**Verified by**:` line under it: `[test file(s)] — ran and passed`, or `[user], manual, build [X]` for a manual verification. If the user declines, close with `BLOCKED — write declined by user`: the verification verdict above is stated in conversation, marked not recorded, and the bug file is unchanged.

If STILL PRESENT: reopen the bug, set Status back to Open, and suggest `/debug [BUG-ID]` (the fix did not address the cause) or, for S1/S2 in production, `/hotfix [BUG-ID]`.

---

## Phase 2D: Close Mode

Read the bug file, found by its number as in verify mode. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first." Verdict: **BLOCKED — bug [ID] is not Verified Fixed** (its current Status is named).

Show the closure record below and the Status change, then ask: "May I update `production/qa/bugs/[bug file]` to mark it Closed?" Nothing is written before a yes; on no, stop — the bug stays Verified Fixed. Verdict: **BLOCKED — write declined by user**.

On yes, append the closure record to the bug file:

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fixed in**: [version(s) — hosted deploy date, self-hosted release, store build]
**Fix commit / PR**: [if known]
**Verified by**: [the verify record's `**Verified by**:` line — the test that ran and passed, or "[user], manual, build [X]"]
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification" when verify recorded a manual run]
**Status**: Closed
```

Then update the top-level `**Status**:` field to `**Status**: Closed`.

After closing, check `production/qa/bug-triage-*.md` — if the bug appears in an open triage report, note: "Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the open bug count." For a bug fixed on hosted but not yet in a self-hosted release, note that self-hosted customers still carry it until the next bundle (`/release-checklist`).

---

## Phase 3: Save Report

Present the completed bug report(s) to the user.

**Allocate the ID** before asking: Glob `production/qa/bugs/BUG-*.md`, take the
highest number and add 1, zero-padded to four digits (`BUG-0001` when there are
none). Several reports in one run (analyze mode) take consecutive IDs from
there, one each — never the same ID twice.

**Confidential reports.** If `Confidential` is `Yes`, ask first via
`AskUserQuestion`: file the redacted summary in the repository
(`production/qa/bugs/`, exploit specifics left out and held by `security-lead`),
or write nothing and keep the report in the restricted channel the user names
(verdict **COMPLETE WITH GAPS** — report drafted and handed over; no file in the
repository, so `/bug-triage` will not see it).
Never write exploit payloads, working proof-of-concept requests or real
identifiers into the repository.

Ask: "May I write this to `production/qa/bugs/BUG-[NNNN].md`?" For several
reports, ask once and name every file: "May I write these to
`production/qa/bugs/BUG-[NNNN].md`, `production/qa/bugs/BUG-[NNNN+1].md`, …?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed. (Analyze mode: **COMPLETE** — [N] candidate reports filed; each is `Found by code analysis, not reproduced`.)

If no, stop here. Verdict: **BLOCKED — write declined by user**; the report stays in conversation only and nothing is reported as filed.

---

## Phase 4: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/bug-report <mode>
BUG-[NNNN] — <verdict>`, Next step = the first suggestion below for the mode
(`/debug [BUG-ID]`, `/bug-report verify [BUG-ID]`, `/bug-report close [BUG-ID]`),
plus Blocked on / Files in progress / Open questions; append the Notes line.
Still updated when the write is declined (`BLOCKED`: record nothing written and
why) or the report is held back as confidential (no file in the repository).

After saving, suggest based on mode:

**After filing (Description/Analyze mode):**
- Run `/debug [BUG-ID]` for the `debugger` agent to reproduce minimally, prove the root cause and specify the failing-first regression test — especially when the cause is unknown, the bug is intermittent, or it is S1/S2
- Run `/bug-triage` to prioritize alongside existing open bugs
- If S1 or S2: run `/hotfix [BUG-ID]` for the emergency fix path; if it is live in production, `/incident`
- If cross-tenant, credential or security-related: `security-lead` owns it — SLA and routing are in `/bug-triage`

**After fixing the bug (developer confirms fix is in):**
- Run `/bug-report verify [BUG-ID]` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still Open

**After verify returns CANNOT VERIFY:**
- Run the reproduction on a build with the fix, then run `/bug-report verify [BUG-ID]` again and answer its question

**After verify returns VERIFIED FIXED:**
- Run `/bug-report close [BUG-ID]` — write the closure record and update status
- Run `/bug-triage` to refresh the open bug count and remove it from the active list

## Collaborative Protocol

- **Never guess a field** — ask once, batched; an unknown is written `Unknown`
- **Severity is a proposal until `qa-lead` confirms**; cite the rule clause, never negotiate by deadline
- **Never write secrets, tokens, OTPs, customer PII or exploit payloads** into a bug file
- **A check that did not run is reported as not run** — repro not re-run, test not run, search not run: say so; never let them read as VERIFIED FIXED
- **Never close without Verified Fixed**, and never write any file before the user says yes
