# /story-done — Phase 8: Update Story Status

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Update Story Status

**Reached one of two ways**: normally, immediately after a COMPLETE or
COMPLETE-WITH-NOTES verdict in Phase 7; or, after a BLOCKED **or NOT ASSESSED**
verdict, only if the user explicitly asks to close the story despite the
blockers (Phase 7 does not advance here on its own in either case).

**Automation note**: This is the story-completion gate. Closing a story whose
verdict is BLOCKED (failing criteria, an unmet BLOCKING gate) **or NOT ASSESSED**
(criteria or gates nobody could evaluate) — the "Accept deviations as-is and
close anyway" option — is a `scope_changes` decision. Call
`bash .claude/hooks/yaml-helper.sh is_always_ask_category scope_changes`; when it returns 0 (the default), this gate
prompts via `AskUserQuestion` **regardless of `modes.automation`** — autonomous
mode must NOT silently close a BLOCKED story, even when the user's own request is
what got you here. For a COMPLETE or COMPLETE-WITH-NOTES verdict, autonomous mode
may pick "Close the story (Recommended)" and record it via `bash .claude/hooks/yaml-helper.sh log_decision "story-done" "<decision-point>" "<options>" "<chosen>" "<reason>" "<category>"` (format in `.claude/docs/automation-modes.md`).

**Close-anyway on a security-sensitive story** additionally requires, before
anything is written: the residual risk named in one sentence, an **owner**, an
**expiry date**, and the user's explicit acceptance of it (the user, not this
skill, `security-lead` or `cto`). These go into Completion Notes under `Security
override:` and into a Security row in the debt register (see below). A cross-tenant
finding (SL-TENANT-ISOLATION REJECT) additionally requires `security-lead` to have
been notified — state that it was, or that the user declined to notify.

Use `AskUserQuestion` before writing anything:
- Prompt: "Verification complete. How do you want to proceed?"
- Options:
  - `Close the story — update file, mark Complete, log notes (Recommended)`
  - `Close and log advisory deviations / gaps as tech debt in docs/tech-debt-register.md`
  - `There are issues I want to fix first — don't close yet`
  - `Accept deviations as-is and close anyway`

If "Close", "Close and log tech debt", or "Accept deviations": edit the story file.
If "Close and log tech debt": after updating the story file, also append the advisory deviations and gaps to `docs/tech-debt-register.md` (create the file if it does not exist).
If "Fix first": stop here and list what the user flagged. Do not write any files.

1. Update the status field: `Status: Complete`
2. Update the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist, add it after the `Status:` line.
3. Update the story's `## Definition of Done Evidence` table: set each row's `Status` box from the Phase 6 table (`[x]` met, `[w]` waived, `[ ]` otherwise) and fill the evidence path. Do not tick a box for a `not run` or `not checked` row.
4. Record gate verdicts in the story's status header, one line each for the gates that ran, per `director-gates.md` → Recording Gate Outcomes:
   `> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REJECTED [date] / NOT ASSESSED [date] — [missing input]` — and `skipped — [mode] mode` for a gate that did not run. A DoD waiver is never a gate verdict: it goes in Completion Notes.
5. Add a `## Completion Notes` section at the bottom:

```markdown
## Completion Notes
**Completed**: [date]
**Criteria**: [X/Y passing] ([any deferred items listed, each with its releasing condition])
**Deviations**: [None] or [list of advisory deviations]
**Test Evidence**: [Logic: tests at path, passed (exit 0, N tests) | Integration: … | Security: negative tests + ASVS/MASVS mapping at path | UI: screenshots in production/qa/evidence/[STORY-ID]/ | None required (Config)]
**Tests not run**: [None] or [command — reason]
**Run and Observe**: [OBSERVED — files … | OBSERVED — partial: … | NOT VERIFIED — reason | N/A — reason]
**DoD gates**: 1 [met/waived/…] · 2 … · 8 […] — evidence in production/qa/evidence/[STORY-ID]/
**Waivers**: [None] or [Gate N — reason (verbatim) — approved by [user] on [date]]
**Security override**: [None] or [residual risk — owner — expiry — accepted by [user]]
**Code Review**: [Complete — PE-CODE-REVIEW [verdict] [date] | Skipped — [mode] mode | Pending]
**Untested criteria**: [None] or [AC-N list — recommend follow-up story]
```

6. If the user chose "Close and log tech debt": append each advisory deviation and ADVISORY gap to `docs/tech-debt-register.md` as one row of `/tech-debt`'s register table — the format under "Debt Register Format" in `.claude/skills/tech-debt/SKILL.md` — so `/tech-debt report` can date it from its `Added` column:
   ```
   | TD-[next free NNN] | [category] | [deviation or gap description] — from [story file path] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | — | Open | [YYYY-MM-DD] | Backlog |
   ```
   Category is one of `/tech-debt`'s nine (Architecture, Code Quality, Test, Documentation, Dependency, Performance, Security, Observability, Deprecated API) — a missing test is `Test`, a missing span/metric/runbook `Observability`, an unmet security row or an accepted security override `Security`, a deprecated-API hit `Deprecated API`. Effort and Impact are your estimate; Priority stays `—` until `/tech-debt prioritize` scores it; `Added` is today. A `Security` row from a close-anyway override has Impact `High` or `Critical` and its Status is `Accepted — [risk]; owner [name]; expires [YYYY-MM-DD]`. If the file does not exist, create it with that format's heading, `Last updated:` and `Total items:` lines and table header; if it exists, update those two lines (and add the table header first if the file has none yet).

7. **Update `production/sprint-status.yaml`** (if it exists):
   - Find the entry matching this story's file path or ID
   - Set `status: done` and `completed: [today's date]`
   - Update the top-level `updated` field
   - This is a silent update — no extra approval needed (already approved in the step above). If the file does not exist, say so in one line: `Sprint status not updated: production/sprint-status.yaml absent`.

8. **Suggest a git commit** (never run it — no commit without the user's instruction): output a ready-to-use command covering the implementation files from the dev-story summary, the evidence folder and the updated story file:

```
Suggested commit:
git add [implementation and test files across the code roots] production/qa/evidence/[STORY-ID]/ [story-file-path]
git commit -m "feat: [story title] ([TR-ID])" -m "Story: [STORY-ID]"
```

   Use the Conventional Commits type that fits (`feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `chore`, `security`). Commits reference the story or task ID in the body (`coding-standards.md`). The `validate-commit.sh` hook checks the commit; the story and spec references go in the message from you.

### Session State Update

After updating the story file, silently update the checkpoint in
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md` —
**overwrite the `<!-- CHECKPOINT -->` …
`<!-- /CHECKPOINT -->` block, never append** (schema:
`.claude/docs/templates/session-state.md`), and append that rule's one-line Notes
entry; leave the `Flow:` line and other skills' blocks alone. `session-start.sh` shows exactly
that block when the next session opens. Fill **Next step** from Phase 9, so it
names the same next story the user is shown:

    <!-- CHECKPOINT -->
    **Updated:** [date]
    **Branch:** `[current git branch]`
    **Current task:** /story-done — [story file path] closed: [COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED]
    **Flow:** [keep the existing `Flow:` line unchanged — it belongs to `/studio` or `/team-feature` — or `none` if there was none]
    **Next step:** [/story-done [next story path] for an In Review story, else /dev-story [next story path] — or "build order done: run the product end to end" — or the blocker to clear when every unfinished story is blocked — or the sprint's next step]
    **Blocked on:** [nothing, or what blocked this verdict]
    **Files in progress:** none
    **Open questions:** [tech debt logged: N items; tests not run: …; or none]
    <!-- /CHECKPOINT -->

If `active.md` does not exist, create it from the template. If it exists with no
markers (a file from before the schema), insert the template's STATUS and
CHECKPOINT blocks at the top and leave the rest untouched.
Confirm in conversation: "Session state updated."

---
