---
name: reverse-document
description: "Adopt an existing product: reconstruct a product brief, research note, feature spec, architecture doc or prototype brief FROM its code. Every claim cites file:line; intent the code cannot show is marked [UNVERIFIED — ask], never invented."
argument-hint: "brief | research <context> | spec <feature> | architecture | concept <prototype-dir>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(git rev-parse), Bash(git rev-parse *), Bash(git log), Bash(git log *), Bash(git status), Bash(git status *), Bash(date *), Bash(bash "*/.claude/skills/reverse-document/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow,system_overrides,stack`

Resolved above — use as-is; do not re-derive. No block → defaults in
`.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md` (collaborative asks
always · guided major-only · autonomous logs and proceeds; `automation_always_ask`
categories always prompt). **Intent questions (Phase 3) are never auto-answered
in any mode**: in `autonomous` they are carried into the document as open
questions, not answered by the skill.

# Reverse Document

Adopts an existing product into the studio by writing the documents the studio
expects *after* the code, from the code. Use it when a product was built without
the brief, research note, spec or architecture doc the studio's gates look for
(`/adopt` and `/project-stage-detect` name the gap; this skill fills it).

**What code can and cannot tell you.** Code records *what was built*, never *why*
or *for whom*. A design document is read by `/spec-review`, `/create-epics`,
`/create-stories` and `/story-readiness` as a statement of authored intent, so a
guessed rule does not stay a documentation error: it becomes a requirement, then
a story, then code written to satisfy it. Therefore, in every mode:

- **Every claim cites `path:line`** read in this run. A claim with no line behind
  it is not written as fact.
- **Unknowns are marked `[UNVERIFIED — ask]`** and listed as questions. Intent,
  rationale, audience, price points' purpose, targets and runtime figures are
  unknowns unless a cited comment, commit message, README or ADR states them.
- **An empty section says so** (`none found in the source — searched <what>`);
  it is never omitted and never filled with what such a product usually has.
- **Nothing is written before "May I write"**, and the written file carries a
  provenance banner so no reader mistakes it for authored design.

**Modes** (argument shapes are fixed; callers such as `detect-gaps.sh`, `/adopt`
and `/project-stage-detect` depend on them):

| Mode | Reconstructs | Template | Output | Owning agent |
|---|---|---|---|---|
| `brief` | Product brief from the code | `.claude/docs/templates/product-brief.md` | `design/product-brief.md` | `product-manager` |
| `research <context>` | Research note for a bounded context with code and no note | `.claude/docs/templates/research-note.md` | `docs/research/<context>.md` | `researcher` |
| `spec <feature>` | Feature spec from the implementation | `.claude/docs/templates/spec-from-implementation.md` | `design/specs/<feature>.md` | `product-manager` |
| `architecture` | Architecture doc from the code | `.claude/docs/templates/architecture-doc-from-code.md` | `docs/architecture/architecture.md` | `principal-engineer` (stack lead if absent) |
| `concept <prototype-dir>` | Brief from a prototype under `prototypes/` | `.claude/docs/templates/brief-from-prototype.md` | `prototypes/<name>/CONCEPT.md` (+ `README.md` if missing) | `product-manager` |

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `NOT ASSESSED` outranks `COMPLETE`: no code roots, nothing to read,
> too little implementation to infer from, a citation check that could not run
> or an agent that could not be spawned means the document was never established,
> which is not the same as established with nothing missing
> (`.claude/rules/skill-authoring.md`). `COMPLETE` is rare by construction: it
> needs every `[UNVERIFIED — ask]` answered by the user. A declined write ends
> `BLOCKED — write declined by user`; nothing is then reported as `COMPLETE`.
> Every path in this skill ends in one of these four words.

---

## Phase 1: Parse and Scope

**Read `references/1-parse-and-scope.md` now and follow it, then
`references/2-modes.md` for the chosen mode.** They parse the arguments, resolve
the code roots (`resolve_code_root`) and the effective tier, locate the target
code, and decide what to do when the output file already exists. An unknown mode,
a missing `<context>` / `<feature>` / `<prototype-dir>`, or an authored target
file ends here in `BLOCKED` with what is needed; no code roots or nothing to read
ends here in `NOT ASSESSED`. Read them again if the conversation was compacted or
resumed during this phase.

## Phase 2: Read the Code and Build the Evidence Ledger

**Read `references/3-evidence-and-sufficiency.md` now and follow it.** Read-only.
It builds the numbered evidence ledger (claim, `path:line`, observed or
inferred), applies the secrets rule (no `.env*` file is ever opened, no secret or
customer value is copied) and runs the sufficiency gate: when the scope holds too
little implementation to infer from, the run stops with `NOT ASSESSED` and points
to the skill that captures intent by asking.

## Phase 3: Present Findings, Ask About Intent

**Read `references/4-findings-and-questions.md` now and follow it.** It shows what
was found (every list may be empty and says so), asks the intent questions the
code cannot answer, and carries any unanswered question into the draft as an open
question. It never drafts an answer on the user's behalf.

## Phase 4: Draft Through the Owning Agent and Verify

**Read `references/5-draft-and-verify.md` now and follow it.** It spawns the
owning agent with the fixed brief (ledger, resolved config block, user answers,
template, tier), receives the draft as text (the agent writes no file), and runs
the mechanical checks: template sections for the tier, a citation on every claim,
every cited line re-read, provenance banner, no secrets, no invented intent. A
check that did not run is reported as not run.

## Phase 5: Show the Draft, Ask to Write, Hand Off

**Read `references/6-write-and-handoff.md` now and follow it.** It shows the draft
and its questions, asks "May I write this to `<path>`?" naming the exact path,
writes only after approval, reports the verdict, and names the next step for the
mode. A declined write is `BLOCKED — write declined by user`.

---

## Error Recovery Protocol

**First, verify the artifact.** The agent's return contract is a draft in its
reply that contains the template's headings; a reply that is a preamble, a
summary or a promise is a failed phase however fluent it reads
(`.claude/docs/error-recovery-protocol.md`, Trigger 0). Resume the agent once,
naming the unmet contract. If it returns BLOCKED, errors or cannot complete,
surface it immediately, do not proceed past the dependency it blocks, offer
retry narrower / stop via `AskUserQuestion`, and produce a partial report. If the
agent cannot be spawned or misses twice, write nothing from memory: the verdict
is `NOT ASSESSED — <agent> unavailable` (first miss) or `BLOCKED` (second miss),
and the ledger is kept in the report so the work is not lost.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
see `.claude/docs/automation-modes.md`.

1. **Read first, silently** — the whole scope, before presenting anything
2. **Show findings before drafting** — then ask about intent, not just "what"
3. **Never assume intent. Always ask before documenting "why"** — an unanswered
   question stays a question in the document
4. **A skipped, dismissed or empty answer is not an answer** — act on nothing,
   re-ask in plain text, say what is waiting, and wait. Only an explicit reply
   such as "unknown, draft it with open questions" lets a question be carried
5. **Ask before writing** — "May I write this to `<path>`?" with the full draft
   shown; a multi-file write (`concept` can write two files) is approved as one
   changeset
6. **Never overwrite an authored document** — only create, or update a file that
   already carries this skill's provenance banner
7. **The user removes the banner, not the next edit** — `Status` stays `Draft`
   (research) or `Reverse-Documented` (the rest) until a human confirms
8. **A check that did not run is reported as not run** — never counted as passed
9. **No commits** — this skill never runs `git commit`; git is read-only here
10. **Secrets and customer data are never copied** — not into the ledger, the
    draft, a search query or the report

---

## Recommended Next Steps

Named per mode by `references/6-write-and-handoff.md`. In short:

- `brief` written: `/map-domains`, then `/adopt` to re-audit; unanswered market and pricing questions go to `/brainstorm` or `/market-research`
- `research` written: confirm it with the user, then `/threat-model` if the note found a sensitive area; future changes to the context still need a fresh `/research` (gate 1 is about research *before* code)
- `spec` written: `/spec-review`, then `/pricing-check` and `/tenant-check` on the findings it flagged; promote to the tier's spec with `/design-spec` when confirmed
- `architecture` written: `/architecture-decision` for each foundation decision found (or a decision-log line at `workflow: minimal`), then `/architecture-review`
- `concept` written: `/design-spec` or update `design/product-brief.md`; archive the prototype with its README
