---
name: tech-debt
description: "Track, categorize and prioritize technical debt — scans code roots, dependencies, observability, tests and deprecated APIs; maintains docs/tech-debt-register.md, including security debt."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,stack`

# Tech Debt

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

> **A scan that cannot run says so.** An unresolved code root, a missing stack
> reference, an absent lockfile or an uninstalled scanner makes that *category*
> `NOT ASSESSED — [reason]` in the output. It is never rendered as "no debt found".
> Zero findings over zero files is no information (`.claude/rules/skill-authoring.md`).

## Phase 1: Parse Subcommand

- `scan` — Scan the codebase for tech debt indicators
- `add` — Add a new tech debt entry manually
- `prioritize` — Re-prioritize the existing debt register
- `report` — Generate a summary report of current debt status

If no subcommand is provided, or the first word is not one of the four above, output usage and stop. Verdict: **NOT ASSESSED** — no valid subcommand (`scan` | `add` | `prioritize` | `report`); name the word received, if any. Nothing is read or written.

---

## Phase 2A: Scan Mode

Resolve the code roots: `bash .claude/hooks/yaml-helper.sh resolve_code_root`
(`backend/`, `web/`, `site/`, `mobile/…`, `contracts/`, `deploy/`; see
`.claude/docs/directory-structure.md`). An **empty result means the roots could not
be resolved** → `NOT ASSESSED — code roots unresolved` for the whole scan; stop.
Also count the source files actually covered per root; a root with **zero** source
files is `NOT ASSESSED — no source files in [root]` and contributes nothing.

Run each category below; for each, record `scanned: N files` or
`NOT ASSESSED — [reason]`. Skip generated code (`**/generated/**`, `*.gen.*`) and
say so.

| Category | What to look for | Needs |
|---|---|---|
| **Architecture** | `domain` packages importing frameworks/DB/HTTP (Grep the import table in section B of the `/code-review` checklist); adapter types in `app`; cross-context imports; generic `utils`/`common` packages; handlers with SQL; product-local copies of identity/OTP/storage/billing/licensing that belong in `saas-core` | code roots |
| **Code Quality** | `TODO` / `FIXME` / `HACK` (count; a TODO without a story ID is itself debt); duplicated blocks; files over 500 lines; functions over 50 lines; `any`/`!!`/unchecked casts; commented-out code | code roots |
| **Test** | use cases / adapters / endpoints with no test file beside them; endpoints without an authz or tenant test; cache adapters without a cache-down test; skipped or disabled tests (`t.Skip`, `@Ignore`, `it.skip`, `xit`) without a linked issue; sleeps in tests; mocked databases in "integration" tests | test locations per `directory-structure.md` |
| **Documentation** | exported APIs without doc comments; stale ADRs (`Superseded` still referenced); specs out of date with code; missing runbooks for existing alerts (`docs/runbooks/`) | docs + code |
| **Dependency / CVE** | `go.mod`, Gradle version catalogs, `package.json`/lockfiles behind `docs/stack-reference/pins.yaml` (run `bash .claude/scripts/project-coherence.sh` — read its BEHIND / FLOATING / LICENCE lines); floating image tags in `deploy/`; lockfile missing; **known-vulnerability output** if supplied (`govulncheck ./...`, `osv-scanner scan -r .`, `pnpm audit`) — this skill does not run scanners: no output supplied means `CVE scan: NOT ASSESSED — no scanner output` and the category cannot read as clean | manifests; scanner output |
| **Performance** | N+1 shapes (a query/cache call inside a loop), missing `LIMIT`/pagination on list queries, offset pagination on growing sets, unbounded goroutines/coroutines per item, `SELECT *`, missing timeouts on outbound calls, endpoints with no row in `perf-budgets.md` | code roots; `docs/architecture/perf-budgets.md` |
| **Security** | tenant predicate missing in a repository query; tenant read from request body; secrets/tokens in code or `.env` committed; tokens in `localStorage`; `dangerouslySetInnerHTML`; `http.DefaultClient`; string-built SQL; missing rate limit on auth/OTP endpoints; a sensitive feature with no `docs/architecture/threat-models/` file; accepted security overrides past their expiry date | code roots; threat-models dir |
| **Observability** | handlers/consumers/jobs with no span or RED metrics; logs without `trace_id`; PII in log calls; services without `/livez` `/readyz`; alerts without a runbook; missing SLO entries for critical journeys | code roots; `docs/architecture/slos.md` |
| **Deprecated API** | calls matching entries in `docs/stack-reference/<layer>/deprecated-apis.md` for each configured layer (`stack` line above). Read the layer's file; a layer with **no** reference file is `NOT ASSESSED — no stack reference for [layer]`, never a clean result; a replacement marked `NOT SOURCEABLE` in that file stays so in the entry | stack reference |

**Derive the layers from the `stack` line** (and `distribution`, `tenancy`): an
`unset` layer is `NOT ASSESSED — layer unset`, not "nothing to scan". Layers not
in the stack (e.g. no `site/`) are listed as `not applicable — not in stack`.

State the denominator in the output: `Scanned N files across [roots]; categories
not assessed: [list with reasons]`. Present the findings, each with `path:line`,
category, proposed effort (S/M/L/XL) and impact (Low/Med/High/Critical).

Ask: "May I write these findings to `docs/tech-debt-register.md`?"

If yes, update the register, never overwriting it. **Match before appending:** a
finding with the same file and the same kind of debt as an existing `Open` entry
updates that entry instead of adding a duplicate. An existing `Open` entry whose
pattern is no longer in its file is proposed as `Resolved [date]` — list those and
include them in the same approval. Verdict: **COMPLETE** — scan findings written
to register (**COMPLETE WITH NOTES** when any category was `NOT ASSESSED`; name
them, and never write "none found" for those).

If no, stop here. Verdict: **BLOCKED — write declined by user**.

---

## Phase 2B: Add Mode

Ask the user for the description and affected files (plain text prompts).

Then use `AskUserQuestion` to collect the **category**. There are nine
categories and the tool takes four options, so infer from the description and
files: offer the likeliest category first, marked `(Recommended)`, and the next
three likeliest after it. Name all nine in the prompt; any of the other five is
typed under the automatic **Other** field.
- Prompt: "What category does this tech debt belong to? (Architecture, Code Quality, Test, Documentation, Dependency, Performance, Security, Observability, Deprecated API)"
- Categories:
  - `Architecture — wrong abstractions, missing patterns, coupling, boundary leaks`
  - `Code Quality — duplication, complexity, naming, missing types`
  - `Test — missing tests, flaky tests, untested edge cases`
  - `Documentation — missing/outdated docs, undocumented APIs`
  - `Dependency — outdated packages, known CVEs, version conflicts`
  - `Performance — known slow paths, N+1, unoptimized queries`
  - `Security — authz/tenancy gaps, accepted security risk, missing threat model`
  - `Observability — missing spans/metrics/logs/alerts/runbooks`
  - `Deprecated API — use of an API listed in docs/stack-reference/*/deprecated-apis.md`

Then collect the **estimated fix effort** (`S` under 1 day · `M` 1–3 days · `L` 3–7 days · `XL` over 1 week) and the **impact if left unfixed** (`Low` / `Med` / `High` / `Critical`) the same way.

**Debt is a conscious decision, not a place to hide a DoD gap.** If the entry is a
Definition of Done gap the story could not meet (`coding-standards.md`), say so:
a debt row does not waive a gate — the waiver is the user's written reason in the
story file (`/story-done`), and the row is its follow-up. For **Security** entries
that record an accepted risk, require: the risk in one sentence, an **owner**, an
**expiry date**, and acceptance by the user — not by the model, `security-lead` or
`cto` on the company's behalf. Without all four it is not accepted; it is `Open`.

Present the complete new entry to the user.

**Match before appending:** if an existing `Open` entry already has the same file
and the same category, show it and ask whether to update that entry instead.

Ask: "May I append this entry to `docs/tech-debt-register.md`?" (or, on a match,
"May I update the existing entry instead?")

If yes, append the entry (or update the matched one). Verdict: **COMPLETE** — entry added to register.
If no, stop here. Verdict: **BLOCKED — write declined by user**.

---

## Phase 2C: Prioritize Mode

Read `docs/tech-debt-register.md`. If it does not exist: Verdict: **NOT ASSESSED**
— no register at `docs/tech-debt-register.md`; run `/tech-debt scan` first. Stop.
If it exists but has no entries (no table rows, or only the header/placeholder): Verdict:
**NOT ASSESSED** — register has no entries; run `/tech-debt scan` or `/tech-debt add`. Stop;
nothing is scored and no empty ranking is written.

Score each item from its own columns: `impact ÷ effort`, with Impact `Low` 1,
`Med` 2, `High` 3, `Critical` 4 and Effort `S` 1, `M` 2, `L` 3, `XL` 4, rounded to
one decimal and written to Priority. Higher scores first; ties go to the older
`Added` date. An item whose Impact or Effort is `—` gets no score: list it after
the scored items as "not scored — [column] not judged" rather than guessing one.

**Overrides the formula does not make:**
- A **Security** item with Impact `High` or `Critical`, or any item describing cross-tenant exposure, a secret exposure or a reachable known CVE (`govulncheck` reports it reachable) is listed first as **must-schedule**, whatever its score; `/tech-debt` does not let it sit below cheap quick wins.
- A **Security** `Accepted` item whose expiry date has passed is reported as **expired acceptance — re-decide**.
- A **Dependency** item whose package has a known vulnerability is must-schedule.

Re-sort the register by priority score (must-schedule block first) and recommend
which items to include in the next sprint (at `workflow: minimal`, which has no
sprints, which to build next).

Present the re-prioritized register to the user.

Ask: "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"

If yes, write the updated file. Verdict: **COMPLETE** — register re-prioritized and saved.
If no, stop here. Verdict: **BLOCKED — write declined by user**.

---

## Phase 2D: Report Mode

Read the debt register. If it does not exist: Verdict: **NOT ASSESSED** — no
register to report on; run `/tech-debt scan` first. Stop. If it exists with no entries:
Verdict: **NOT ASSESSED** — register has no entries (an empty register is not "no debt"); stop.

Generate summary statistics:

- Open items by category, and total estimated fix effort for them
- **Security debt** and **Dependency/CVE debt** shown separately at the top, with expired acceptances called out
- Items added and items resolved during the current sprint, from each entry's `Added` date and its `Resolved [date]` status
- Trending direction (growing / stable / shrinking) — added vs resolved in that window
- Which categories the last scan marked `NOT ASSESSED` (read from the register's `Last scan:` line if present) — so a category nobody scanned is visible rather than silent

Flag any items that have been in the register for more than 3 sprints.

Output the report to the user. This mode is read-only — no files are written. Verdict: **COMPLETE** — debt report generated.

---

## Phase 3: Next Steps

**Checkpoint.** When the run added or changed register rows (Scan/Add/Prioritize) or a write was declined, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md` before the final message: Current task `/tech-debt <subcommand> — <verdict>`, Next step = the first item below that applies, plus Blocked on / Files in progress (the register) / Open questions; append the Notes line. A read-only `report` run may skip it.

- Run `/sprint-plan` to schedule high-priority debt items into the next sprint (at `workflow: minimal`, which has no sprints, add them to the brief's build order instead).
- Run `/dependency-audit` for a full dependency/CVE sweep and `/security-audit` for security debt that needs a deeper audit than a scan.
- Run `/tech-debt report` at the start of each sprint to track debt trends over time.

### Debt Register Format

```markdown
## Technical Debt Register
Last updated: [Date]
Total items: [N] | Estimated total effort: [T-shirt sizes summed]
Last scan: [Date] — scanned [N] files across [roots]; not assessed: [categories with reasons, or "none"]

| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
| TD-001 | [Cat] | [Description] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Open / Resolved YYYY-MM-DD / Accepted — reason] | [YYYY-MM-DD] | [Sprint to fix or "Backlog"] |
```

Every skill that adds a row — this one, and `/story-done` when it logs deviations
as debt — writes all ten columns in this order, and a skill that creates the file
writes the header and table head above first:

- **ID** — `TD-` and three digits, one above the highest ID already in the register (`TD-001` in a new one). IDs are never reused.
- **Category** — one of the nine under Scan Mode, written as: `Architecture`, `Code Quality`, `Test`, `Documentation`, `Dependency`, `Performance`, `Security`, `Observability`, `Deprecated API`.
- **Description** — what the debt is and why it was taken on.
- **Files** — the affected paths, comma-separated (`path:line` where known); `—` when the debt has no single file.
- **Effort** — `S`, `M`, `L` or `XL`; `—` if not yet estimated.
- **Impact** — `Low`, `Med`, `High` or `Critical`: the cost if left unfixed; `—` if not yet judged.
- **Priority** — the score `/tech-debt prioritize` writes; `—` until it runs.
- **Status** — `Open` when added. `Resolved YYYY-MM-DD` records the day the debt was fixed; `Accepted — reason` records a conscious decision to keep it (Security: `Accepted — [risk]; owner [name]; expires [YYYY-MM-DD]`).
- **Added** — the day the row was written, `YYYY-MM-DD`.
- **Sprint** — the sprint scheduled to fix it, or `Backlog`.

### Rules
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info).
- Debt never replaces a DoD gate: an unmet gate is waived in the story file by the user, and the debt row is its follow-up.
- "Scan" should run at least once per sprint to catch new debt.
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason.
