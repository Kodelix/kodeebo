# /reverse-document - Phase 5: Show the Draft, Ask to Write, Hand Off

> Phase 5 of `SKILL.md`.

## 1. Show the draft before asking

Present the draft (key sections in full for a long document; the headings and
counts for the rest, with the file readable in the conversation), then:

```
DRAFT SUMMARY
- Mode / output: [mode] -> [path]  ([new | update | replacing an unfilled template])
- Tier: [tier]    Commit: [sha]    Agent: [name]
- Claims with citations: [N]   Verified by re-reading: [N]   Dropped: [N]
- [UNVERIFIED — ask]: [M]   NOT ASSESSED: [K]   Not generated at this tier: [list | none]
- Checks: C1 [ran/not run] ... C8 [ran/not run]
ADDITIONS BEYOND THE CODE: none. Everything here is from the ledger or from
answers you gave on [dates].
OPEN QUESTIONS (these stay open in the document):
1. [question] - owner [user] - blocks [what]
```

Defects the reading found (hardcoded business values, missing tenant scope,
layering violations, pin or contract drift, hardcoded secrets - value not copied)
are listed once here as findings; they are not fixed by this skill.

## 2. Ask, by automation mode

Ask: "May I write this to `<path>`?" naming the exact path (for `concept`, both
files in one question: `CONCEPT.md` and, when absent, `README.md`; for an update,
"May I update `<path>` with these section changes?" after a per-section diff).

- **collaborative**: wait for the answer; the user may request changes first
  (revise by resuming the agent with the requested change, then re-run the
  checks, then ask again)
- **guided**: a *new* file is still asked ("May I write?" is for new files); an
  update to an existing reconstruction proceeds after the diff summary
- **autonomous**: write, and record it with `bash .claude/hooks/yaml-helper.sh
  log_decision reverse-document "<point>" "<options>" "<chosen>" "<reason>" "<category>"`
  (the text arguments are the decision point, options, the choice, the reason
  and the category, here `none`). The banner and the open questions are still
  written. `automation_always_ask` categories (for example `file_deletions`) still
  prompt.

A skipped, dismissed or empty answer is not an approval: write nothing, ask
again in plain text, and wait. Never write a file the question did not name.

## 3. Write

After approval only: Write the file(s) at the exact path(s) approved (Edit for an
update to a reconstruction, changing only the approved sections and appending a
Version History row; never touching the banner). Confirm each path exists by Glob.

Declined: write nothing. Verdict `BLOCKED — write declined by user`. Say that the
draft was not saved and that the ledger and questions above remain in the
conversation; offer to re-run after the user decides. Nothing is reported as
`COMPLETE`.

## 4. Verdict

| Verdict | When |
|---|---|
| `COMPLETE` | Written; C1 to C8 ran and passed; every `[UNVERIFIED — ask]` was answered by the user and recorded with its date. Rare: code alone leaves questions |
| `COMPLETE WITH GAPS` | Written; at least one `[UNVERIFIED — ask]` remains, or a required section reads `none found in the source`, or a claim was dropped. The report lists each gap |
| `NOT ASSESSED` | Nothing was established: no code root, scope not found or unreadable, insufficient implementation, citations unverified (C4 not run), owning agent unavailable. Names the reason; outranks the two `COMPLETE` values |
| `BLOCKED` | Write declined; an authored file already at the path; unknown mode or missing name; agent missed its contract twice. Names what is needed |

Precedence: `BLOCKED`, `NOT ASSESSED`, `COMPLETE WITH GAPS`, `COMPLETE`. Print the
verdict line as `Verdict: <WORD> - <reason>` and the exact path written (or
`nothing written`). A step that did not run is reported as not run, never as a
pass.

## 5. Hand off - one next step, not a list of six

**Checkpoint.** Before the hand-off message, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/reverse-document <mode> <target> — <verdict>`, Next step = the one
step named below, plus Blocked on / Files in progress / Open questions (the open
questions that stay in the document); append the Notes line. NOT ASSESSED, BLOCKED
or a declined write still updates the checkpoint with the blocker.

Name the next step for the mode, drawn from what the draft found:

- **brief**: unanswered ICP / pricing / metric questions go to `/brainstorm`
  (writes the missing fields) or `/market-research`; then `/map-domains` to turn
  the MVP list into bounded contexts; then re-run `/adopt`.
- **research**: show the user the Open Questions; once they confirm, they set
  `Status: Complete` and remove the banner themselves. A sensitive context
  (auth, billing, licensing, file upload, PII) with no threat model: `/threat-model
  <feature>`. State plainly that the note records what was chosen and does not
  stand in for research before future changes (`/research <context>`).
- **spec**: `/spec-review design/specs/<feature>.md`; pricing or entitlement
  findings to `/pricing-check`; tenant-scope findings to `/tenant-check`;
  hardcoded secrets to `/security-audit`. When the user confirms the intent,
  `/design-spec` promotes it to a normal spec at the tier.
- **architecture**: `/architecture-decision` once per foundation decision listed
  under Follow-Up Work (at `workflow: minimal`, add each as a decision-log line
  in `design/product-brief.md` instead); then `/architecture-review`; a re-run of
  `/adopt` closes the architecture gap.
- **concept**: update `design/product-brief.md` with the validated parts
  (`/brainstorm`), or write the spec (`/design-spec`); a concluded prototype is
  archived with its README (`.claude/rules/prototype-code.md`).

Ask whether to start that one step. Do not start it; this skill never runs
another skill and never commits.
