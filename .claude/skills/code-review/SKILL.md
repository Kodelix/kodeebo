---
name: code-review
description: "Review an implementation against the eight DoD gates, the stack rules, clean architecture, tenancy, RFC 9457 and secrets. Verdict APPROVE/CONCERNS/REJECT/NOT ASSESSED with file:line findings."
argument-hint: "[files-or-directories] [story-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(git log *), Bash(git diff *), Bash(git status *), Bash(git merge-base *), Agent, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(git status), Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Code Review

An implementation review at the senior bar: does this change meet **each of the
eight Definition of Done gates** (`.claude/docs/coding-standards.md`), the stack
rules for its layer, the clean-architecture checklist, tenant isolation, RFC 9457
error handling and the secrets rules? Findings carry `path:line`, a severity and
the rule they break — "looks fine" is never a finding or a verdict.

This skill reviews **code**. Evidence completeness (research note dated before
the first commit, retained screenshots, load-test results, waivers) is
`/story-done` + PE-DOD; where a gate is not judgeable from the diff this report
says `see PE-DOD`. Tests are **not run** here — this skill reads. A test result
nobody supplied is `not run`, never green.

**The only file this skill ever writes** is the review record in Phase 10, after
the user approves it. Everything else is read-only.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (source files under the code roots, the story file, the governing ADR(s), the control manifest, the research note, the threat model, the test files and `production/qa/evidence/<story-id>/`, `docs/stack-reference/<layer>/`, `docs/architecture/perf-budgets.md`).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an adjacent artifact, and do not leave a cell to be filled by whoever reads the template next.
4. If **every** required input is ABSENT (no readable source under the named paths), stop and report **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer
when there is nothing to look at. The failure mode this prevents is a verdict
enum with no "could not run" state, which produces false clean passes — an
APPROVE over code that was never read, tests nobody ran, or a stack no reference
covers. **Absence of evidence is never evidence of absence**: a grep that finds
no matches because there were no files to grep has verified nothing. Say which of
the two happened.

---

## Phase 1: Resolve Scope and Review Mode

**Arguments:** `$ARGUMENTS` with any `--review <mode>` pair removed. What remains
is a list of files and/or directories, optionally ending with a story file path
(`production/epics/**/story-*.md`).

- **Files/directories given** → the review targets. Expand directories with Glob; skip generated code (`**/generated/**`, `*.gen.*`, lockfiles) and say so — generated clients are reviewed through `contracts/`, not by hand.
- **Only a story path given** → targets are the story's `Files in progress` from `production/session-state/active.md` if it names this story, else the files changed since the base (`git merge-base HEAD main` then `git diff --name-only <base>`), shown to the user for confirmation.
- **Nothing given** → ask via `AskUserQuestion`: "What should I review?" with options `Files changed since main (git diff)` / `A story's implementation (give the path)` / `Specific files or directories`.

Map each target file to a **layer** with `resolve_code_root` (run
`bash .claude/hooks/yaml-helper.sh resolve_code_root`): `backend/` (Go or Ktor per
`stack.backend`), `web/`, `site/`, `mobile/shared|android|ios`, `contracts/`,
`deploy/`, `**/migrations/**`. A file outside every code root, or an empty
`resolve_code_root`, is reported as `layer not resolved — [file]` and that file's
stack checks are `NOT ASSESSED`. A layer whose `stack.*` value is `unset` is
**not defaulted** (`/setup-stack`).

Report the scope before proceeding: "Reviewing [N] files across [layers]; story:
[path | none]; review mode: [mode]."

**Review mode** (`review_mode`, overridden by `--review`): decides whether the
**PE-CODE-REVIEW gate** is spawned in Phase 8. `full` → spawn; `lean`/`solo` →
skip and record `PE-CODE-REVIEW skipped — [mode] mode`. **Solo skips the
principal engineer's opinion, never the review**: Phases 3–7 are this skill's own
checks and always run. The security-sensitive `appsec-engineer` review (Phase 8)
is a rule of `.claude/rules/security-sensitive.md`, not a gate, and is spawned at
every mode.

---

## Phase 2: Load the Targets and Context

Read the target files in full (no truncated reads; page large files). Then, only
what the checks need:

- The **story** (if given): `Type`, `Code root`, `Acceptance Criteria`, `Out of Scope`, `QA Test Cases`, `Definition of Done Evidence`, `Research note` and `Threat model` paths, `Contract` line, governing ADR, `Manifest Version`.
- **Spec** (`design/specs/<feature>.md`) rules the code claims to implement — Grep the story's TR-ID in `docs/architecture/tr-registry.yaml` for the current requirement text.
- **Control manifest** layer rules — Grep one section (`^## <layer> Layer Rules`), not the whole file. Absent at `minimal`: say `control manifest: ABSENT (not expected at minimal)`.
- **Layer rules**: the `.claude/rules/*.md` whose `paths:` match the targets, and `docs/stack-reference/<layer>/` (`best-practices.md`, `deprecated-apis.md`). If the layer's reference is missing, stack idiom checks are `NOT ASSESSED — no stack reference`, and any API claim is `UNVERIFIED`.
- **Tests and evidence**: Glob the story's declared test paths and `production/qa/evidence/<STORY-ID>/`; read test files for the checks in `references/checklist.md` section F row 3. Any pasted test/lint/scan output the author supplies is quoted with its source; otherwise those checks are `not run`.
- **Security-sensitive?** Does any target path match `.claude/rules/security-sensitive.md` (`**/auth/**`, `**/identity/**`, `**/billing/**`, `**/licensing/**`, `**/tenancy/**`, `**/admin/**`) or does the story hit a threat-model trigger? If so the threat model must exist; its absence is a BLOCKER finding (`Sensitive code with no threat model — /threat-model`).

---

## Phase 3: ADR Compliance Check

Search for ADR references, in priority order:
1. The story file (if provided)
2. Header comments at the top of the implementation files
3. Commit messages referencing these files (`git log --oneline -- [file]`)

Look for `ADR-NNNN` or `docs/architecture/adr-` (either case). If no ADR references
are found, note: "No ADR references found — ADR compliance check skipped. For
full ADR compliance review, provide the story path: `/code-review [files]
[story-path]`." That result is **`NO ADRS FOUND`**, which is not `NOT ASSESSED`.

For each referenced ADR, load **only the sections this check needs — never an
unbounded full read.** A substantial ADR exceeds the 25k-token `Read` cap:

1. **Map the headings** (cheap): `Grep pattern="^## " path="[adr-file]" output_mode="content" -n`
2. **Bounded-read `## Decision` (with its Implementation Guidelines) and `## Consequences`** with `Read(offset, limit)` spans that end where the next heading begins. If the heading map is empty (a nonstandard ADR), one full `Read`; if that truncates, grep for the decision content rather than paging.

Also check the ADR's `## Status`: a reference to a `Proposed`, `Deprecated` or
`Superseded` ADR is a finding (the code is built on a decision nobody accepted).
A referenced ADR that is missing or unreadable makes ADR Compliance
`NOT ASSESSED — [ADR] could not be read`: name it.

Classify any deviation:
- **ARCHITECTURAL VIOLATION** → BLOCKER: uses a pattern the ADR explicitly rejected
- **ADR DRIFT** → MAJOR: meaningfully diverges from the chosen approach without a forbidden pattern
- **MINOR DEVIATION** → MINOR: small difference from ADR guidance that does not affect the architecture

Then the **control manifest** and **research note**: a *Forbidden* pattern present
is a BLOCKER; a *Required* pattern absent is a MAJOR; code that contradicts the
research note's decision means "update the note first, then the code"
(`research-protocol.md`) — MAJOR, citing the note section.

---

## Phase 4: Standards Compliance

Evaluate section A of `references/checklist.md` (doc comments, complexity,
function length, dependency injection, no hardcoded business values, errors as
values with context, no debug output). Report `X/N passing` and list each failure
with `path:line`; a missing doc comment names the function or type.

## Phase 5: Clean Architecture and SOLID

Evaluate sections B and C of `references/checklist.md`. **Run the import greps
with the Grep tool** (the table in section B) over the `domain` packages and list
every violating import with `path:line` — "checked by grep" is the evidence. A
grep over a path that matched no files is `not checked — no domain package found
at [path]`, not clean.

## Phase 6: SaaS Rules — Tenancy, Authorization, API, Resilience, Secrets, Data

Evaluate section D of `references/checklist.md`: tenancy (list **every query** in
the changed code with `path:line` and its tenant scoping), authorization and
abuse, RFC 9457 errors and API conventions against `contracts/`, external calls
and idempotency, secrets and PII in logs, migrations, caching, observability,
performance. For anything in `**/migrations/**` also quote the output of
`bash .claude/scripts/migration-lint.sh` **if the author supplied it**; this skill
does not run it.

## Phase 7: Eight-Gate Table

Build the table of section F of `references/checklist.md`: every gate 1–8 with a
status (`met` / `unmet` / `see PE-DOD` / `not checked`) and evidence (`path:line`
or a number). Gate levels (BLOCKING / ADVISORY) from the resolved
`testing.strict.*` and `performance.enforce`. An unmet **BLOCKING** gate is a
BLOCKER finding; an unmet ADVISORY gate is a MAJOR or MINOR by consequence.
**`not run` tests, lint or scans are listed under "Not run", never marked met.**

---

## Phase 8: Specialist Reviews (Parallel)

Spawn all applicable agents simultaneously via `Agent` — issue every call before
waiting for any result; do not wait for one before starting the next. Brief each
with **file paths and what to read**, not pasted content.

> **Verify every specialist finding before reporting it. Do not pass findings
> through unchecked.** For each finding, record in the report:
>
> - **File and line** it refers to.
> - **Evidence** — the quoted code, or the concrete input/state that triggers it.
> - **Confidence** — `VERIFIED` (you checked it yourself) or `UNVERIFIED —
>   specialist claim` (you could not).
>
> A finding you could not verify is reported as unverified or dropped, never
> promoted to a defect on the strength of confident phrasing.
>
> **Why this is mandatory.** Agents are reliable when deriving and unreliable when
> diagnosing existing code: in practice three separate agents produced three
> different **wrong** claims about the same six-line function, each fluent enough
> to pass a skim. Without this step the parent review is a laundering channel — a
> guess enters as a specialist finding and leaves as a reviewed defect. This
> applies equally to claims about stack APIs: a claim not backed by
> `docs/stack-reference/<layer>/` is `UNVERIFIED — not in stack reference`.

### 8a. PE-CODE-REVIEW (principal-engineer)

- `solo` / `lean` → skip. Note: "PE-CODE-REVIEW skipped — [mode] mode."
- `full` → spawn `principal-engineer` via `Agent` using gate **PE-CODE-REVIEW** (`.claude/docs/director-gates/pe-code-review.md`) — the agent reads the gate file, this skill does not. Pass the context that gate lists: implementation paths per code root, the story path, the spec section, governing ADR(s) and control manifest, test paths and the evidence directory. It returns **APPROVE / CONCERNS / REJECT / NOT ASSESSED**, its DoD table, and `[BLOCKER|MAJOR|MINOR] path:line` findings. Verify its findings as above, merge them into this report, and fold its verdict into Phase 9 by the strictest-wins rule.

### 8b. Security review (appsec-engineer) — security-sensitive paths

If Phase 2 found security-sensitive paths or a threat-model trigger, spawn
`appsec-engineer` via `Agent` (any review mode — `security-sensitive.md` makes it
a rule). Pass: the sensitive files, the threat model (its rows → mitigations →
ASVS/MASVS IDs → negative tests), the spec, `security-baseline.md`. Ask it to check
that each mitigation exists in code **and** has a negative test (authz bypass,
cross-tenant, replay, brute force / rate limit, expired or forged token,
injection), constant-time comparisons for secrets/OTPs, vetted crypto/JWT/password
libraries, step-up for admin/impersonation paths, billing prices server-side,
licence signing outside the repo, and audit-log writes. Requirement IDs are quoted
from the threat model/research note — never recalled. If no sensitive path
applies, record `appsec review: not applicable — no security-sensitive path`.

### 8c. Stack lead review — layer idioms

Resolve the lead per target layer from `stack` (never default an `unset` layer):
`go-lead` (Go), `ktor-lead` (Ktor/Kotlin backend), `web-lead` (web, site),
`android-lead` (Android), `ios-lead` (iOS), `kmp-specialist` (KMP shared),
`api-designer` (contracts), `data-lead` (migrations, cache, messaging adapters),
`platform-lead` (deploy files). Spawn one per layer touched, in parallel. Each
reviews the layer idioms in section E of `references/checklist.md`
against the layer's rules file and `docs/stack-reference/<layer>/`. If a layer's
stack is `unset` or has no reference: `Stack validation ([layer]): NOT ASSESSED —
[reason]`. A skipped check that says nothing is indistinguishable from one that
passed, so record the line.

### 8d. QA testability review (qa-tester)

For Logic, Integration, Contract and Security stories, also spawn `qa-tester`.
Pass the implementation files, the story's `## QA Test Cases` and `## Acceptance
Criteria`. Ask it to evaluate:
- [ ] Are test hooks and interfaces exposed (ports injectable, `Clock`/`IDGenerator` seams), not hidden behind private access?
- [ ] Do the story's QA test cases map to testable code paths?
- [ ] Are any acceptance criteria untestable as implemented (hardcoded values, no injection seam, no way to reach a state)?
- [ ] Does the implementation introduce edge cases not covered by the QA test cases (tenant mismatch, duplicate delivery, cache down, provider timeout)?
- [ ] Are there observable side effects that should have a test but don't?

For UI stories: does the implementation let a checker reach every state the
manual steps need (loading, empty, error, RTL)?

Collect all specialist findings before producing output.

---

## Phase 9: Output the Review

```
## Code Review: [File/System Name]
Scope: [N files — layers]   Story: [path | none]   Review mode: [mode]
Inputs: [list each with FOUND / ABSENT]

### Stack Validation: [N/A — see reason | CLEAN | ISSUES FOUND | NOT ASSESSED — layer unset / no stack reference]
[Per-layer stack lead findings, each VERIFIED or UNVERIFIED]

### Testability: [N/A — no story path / N/A — UI or Config story / TESTABLE / GAPS / BLOCKING]
[qa-tester findings; if BLOCKING: the code must expose [X] before the story's QA test cases can run]

### ADR Compliance: [NOT ASSESSED / NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[Each ADR checked, result, deviations with severity; control manifest and research-note contradictions]

### Standards Compliance: [X/N passing]
### Architecture (clean architecture): [NOT ASSESSED / CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[Import-grep results with path:line]
### SOLID: [NOT ASSESSED / COMPLIANT / ISSUES FOUND]
### SaaS Rules: [tenancy | authorization | RFC 9457 | external calls & idempotency | secrets | migrations | caching | observability | performance — each CLEAN / ISSUES FOUND / NOT ASSESSED]
[Query table: location — mechanism — tenant-scoped? — negative test]
### Security Review: [N/A — no security-sensitive path | CLEAN | ISSUES FOUND | NOT ASSESSED]

### DoD gates
| # | Gate | Level | Status (met / unmet / see PE-DOD / not checked) | Evidence / gap |

### PE-CODE-REVIEW: [APPROVE / CONCERNS / REJECT / NOT ASSESSED — reason | skipped — [mode] mode]

### Findings
- [BLOCKER|MAJOR|MINOR] path:line — problem → fix (rule or standard cited) — VERIFIED | UNVERIFIED

### Positive Observations
[What is done well — always include this section]

### Not run / not checked
- [test suite, lint, scan, migration-lint, load test … — reason; layers or sections NOT ASSESSED]

### Suggestions
[Nice-to-have improvements — never BLOCKER or MAJOR items]

### Verdict: [APPROVE / CONCERNS / REJECT / NOT ASSESSED]
```

Choose the verdict, first match wins (the vocabulary of
`.claude/docs/director-gates/pe-code-review.md`, ranked as in `director-gates.md`):

- **REJECT** — any BLOCKER finding (including an unmet BLOCKING gate, an ARCHITECTURAL VIOLATION, a tenant-isolation hole, a missing threat model on sensitive code), or the PE-CODE-REVIEW gate returned REJECT. Must be revised before merge.
- **CONCERNS** — no BLOCKER, but at least one MAJOR finding, an unmet ADVISORY gate, or the PE-CODE-REVIEW gate returned CONCERNS.
- **NOT ASSESSED** — nothing to review (the no-data path above), or any report section reads `NOT ASSESSED` (a referenced ADR that could not be read, an `unset` stack layer, a missing stack reference, a specialist that could not be spawned or returned NOT ASSESSED), or a **BLOCKING gate reads `not checked`** in the Phase 7 table (evidence absent, unreadable, or a test/lint/scan never run with no output supplied — a `not checked` BLOCKING gate is never read as met); name which. It ranks **below** REJECT and CONCERNS (a known defect is more actionable than a skipped check) and **above** APPROVE: a review that skipped a check has not approved the code. `NO ADRS FOUND` is not NOT ASSESSED — with no ADR to check it does not stop an approval.
- **APPROVE** — no BLOCKER, no MAJOR, no unmet gate, no BLOCKING gate `not checked`, nothing NOT ASSESSED. MINOR findings and Suggestions may accompany it ("APPROVE with suggestions").

Handling specialist verdicts: the strictest verdict wins; one `NOT ASSESSED` keeps
the result from being `APPROVE`; a PE-CODE-REVIEW `REJECT` is never downgraded by
this skill — if you judge a specialist finding wrong, mark it `UNVERIFIED` with
your evidence and ask the user.

---

## Phase 10: Next Steps and Review Record

Use `AskUserQuestion`:
- Prompt: "Code review complete — verdict: [verdict]. How would you like to proceed?" (the Phase 9 verdict, word for word)
- Options (adjust to the verdict):
  - If APPROVE:
    - `[A] Run /story-done to verify the evidence and close the story`
    - `[B] Stop here`
  - If CONCERNS:
    - `[A] Fix the findings, then re-run /code-review (Recommended)`
    - `[B] Run /story-done with the concerns recorded — I accept them`
    - `[C] Stop here`
  - If REJECT:
    - `[A] Fix the BLOCKERs and re-run /code-review`
    - `[B] Stop here`
    (A REJECT cannot be accepted away from this menu; `/story-done` will stop on it too.)
  - If NOT ASSESSED:
    - `[A] Fix what stopped the review (point me at the code, run /setup-stack, supply the test/lint/scan output, or fix the unreadable ADR reference), then re-run /code-review`
    - `[B] Stop here`

**Routing for violations:**
- A BLOCKER that contradicts an **existing ADR**: fix the implementation to comply with `docs/architecture/[adr-file].md`. If the design has legitimately changed, run `/architecture-decision` to *revise* the ADR — do not create a competing one.
- A pattern with **no ADR** for an architectural choice the code makes: run `/architecture-decision` to record it before fixing the code (DoD gate 8).
- A sensitive change with no threat model: `/threat-model [feature]`.
- A cross-tenant or credential-exposure finding: notify `security-lead`; do not wait for the next review cycle.
- A capability the product re-implements that `saas-core` provides: stop and move it upstream (`/core-extract`).

**Review record (the only write).** If a story path was given, ask: "May I write
this review to `production/qa/evidence/[STORY-ID]/code-review.md` and add the
line `> **Principal Engineer Review (PE-CODE-REVIEW)**: [APPROVED | CONCERNS (accepted) | REJECTED | NOT ASSESSED — reason | skipped — [mode] mode] [date]`
to the story's status header?" (`director-gates.md` → Recording Gate Outcomes;
`/story-done` reads that header line.) On yes, write exactly those two things.
On no, nothing is written, the verdict stands as printed with `review record not written — write declined by user`, and the report is the whole record (`/story-done` then finds no PE-CODE-REVIEW line). With no story path,
nothing is written and that is stated.

**Checkpoint.** Last, update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/code-review <target> —
<verdict>`, Next step = the first menu option for that verdict (`/story-done` on
APPROVE; fix the findings or BLOCKERs then re-run `/code-review`; for NOT
ASSESSED, what clears it), plus Blocked on / Files in progress (the review record,
or `none`) / Open questions; append the Notes line. Still updated on REJECT /
NOT ASSESSED or when the record write was declined.

---

## Collaborative Protocol

- **Read-only until the Phase 10 ask.** Findings are reported, not fixed; fixing is `/dev-story`'s lead or the author, through the normal approval flow.
- **Cite, don't opine.** Every finding names `path:line`, the rule or standard, and the fix. Every "met" names the evidence.
- **Report what did not run.** Tests, lint, scans, load tests and `migration-lint` outputs the author did not supply are `not run` — and an unmet BLOCKING test gate with no output is `NOT ASSESSED` at best.
- **Never accept a risk on the company's behalf.** A security finding's residual risk is accepted by the user, recorded with owner and expiry — not by this skill, `appsec-engineer`, `security-lead` or `cto`.
- **Do not review what you cannot source.** Stack-API claims come from `docs/stack-reference/`; a gap is `NOT SOURCEABLE`/`UNVERIFIED`, not a verdict.
