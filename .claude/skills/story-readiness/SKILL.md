---
name: story-readiness
description: "Is a story implementation-ready? Checks acceptance criteria, research note, threat model, contract ordering, ADRs, story type and evidence. READY/NEEDS WORK/BLOCKED/NOT ASSESSED."
argument-hint: "[story-file-path or 'all' or 'sprint'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,qa.level,testing.strict,performance.enforce,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Story Readiness

This skill validates that a story file contains everything a developer needs
to begin implementation — no mid-sprint design interruptions, no guessing,
no ambiguous acceptance criteria, no missing research note or threat model, no
client story started ahead of its contract. Run it before assigning a story.

**This skill is read-only.** It never edits story files. It reports findings
and asks whether the user wants help filling gaps.

**Output:** Verdict per story (READY / NEEDS WORK / BLOCKED / NOT ASSESSED) with a specific
gap list for each non-ready story, the story type with the evidence it requires,
and the owner agent per layer.

> **`NOT ASSESSED` is not a synonym for `BLOCKED`.** `BLOCKED` is a
> finding about the story — a Proposed ADR, an ADR file it names that does not
> exist, an unresolved dependency, an unmerged contract story, a missing threat
> model on a sensitive story — and it tells the reader exactly what to clear.
> Use `NOT ASSESSED` when the story could not be evaluated at all: the file is
> unreadable or unparseable, a referenced ADR exists but has no readable
> `## Status` (malformed), or a referenced spec cannot be located, so
> the checks below cannot run. Collapsing that into `BLOCKED` reports a blocker
> that does not exist and hides the one that does — the reader chases a phantom
> blocker instead of the unreadable file.
> `READY` must never be reachable for a story that was not actually evaluated.
>
> **Precedence — first matching rule wins**, in this order: **BLOCKED**, then
> **NEEDS WORK**, then **NOT ASSESSED**, then **READY**. `NOT ASSESSED` outranks
> `READY` (a story that could not be evaluated has not been shown ready) and
> ranks **below** both failure verdicts (a known blocker is more actionable than
> an unknown, and demoting it behind an access problem buries it). A story with
> both a real blocker and an unevaluable check is `BLOCKED` — the blocker is the
> actionable finding. This half of the rank has to be stated: the rule above
> establishes only that `READY` is unreachable, which would leave the ordering
> against `BLOCKED` to inference.
>
> A check that could not run (empty scan, unreadable file, directory missing) is
> reported as `not checked — [reason]`, never counted as met.

---

## Phase 0: Resolve Review Mode

See `.claude/docs/director-gates.md` for the full check pattern and mode definitions. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Resolve the workflow tier per story** (per `.claude/docs/workflow-modes.md`):
for the feature a story belongs to (**the spec filename stem** of its `Spec:` path;
the `[feature]` segment of a `TR-[feature]-NNN` ID is a fallback alias only), use the
`system_overrides` row for that feature if the block lists one, else the
project value. When validating multiple stories (`all` / `sprint` scope),
resolve **per story** — different features may sit at different tiers. The tier
sets which checklist sections block — see the tier note in `references/checklist.md`.

**`qa.level`**: controls how much *additional* test evidence the story must name. The
"Test evidence requirement is clear" item is validated at **every** tier: Logic,
Integration, Contract and Security stories must name the tests that will exist and pass
(`coding-standards.md` — these tests are BLOCKING at every tier). At `standard` also
validate the extra evidence (strictness for the other types from `testing.strict`); at
`full`, also validate a coverage target. Distinct axis from `workflow`. **Never waived at
any `qa.level`:** the retained screenshot of every UI story, run-and-observe evidence for
anything a user can see or call, and the negative tests of a Security story.

---

## 1. Parse Arguments

**Scope:** `$ARGUMENTS` with any `--review <mode>` pair removed (blank = ask user via AskUserQuestion). What remains is one value — a path may contain spaces.

- **Specific path** (e.g., `/story-readiness production/epics/billing/story-001-create-subscription.md`):
  validate that single story file.
- **`sprint`**: read the current sprint plan from `production/sprints/` (most
  recent file), extract every story path it references, validate each one.
- **`all`**: glob `production/epics/*/story-*.md` and validate every file found.
  Epic and index files are not stories: `EPIC.md` and `production/epics/index.md`
  (and any `index.md`) are never in scope. Report the denominator — "N story files
  in scope, M non-story files excluded" — so an excluded file is visible.
- **No argument**: ask the user which scope to validate.

If no argument is given, use `AskUserQuestion`:
- "What would you like to validate?"
  - Options: "A specific story file", "All stories in the current sprint",
    "All stories in production/epics/", "Stories for a specific epic"

Report the scope before proceeding: "Validating [N] story files."

> **If the scope resolves to ZERO story files, stop and report
> `NOT ASSESSED — no stories in scope`.** Name which scope was searched and
> which path was empty (`production/epics/**/*.md`, the sprint file's story
> list, or the specific path given), and route: `/create-epics [context]` then
> `/create-stories [epic-slug]`.
>
> **The zero-scope path is mandatory.** Without it an empty glob falls through
> to the aggregate template and renders `Ready: 0 /
> Needs Work: 0 / Blocked: 0` above an empty list — **indistinguishable from
> "I checked every story and none needed work"**. A scan that finds nothing
> because there was nothing to scan must never be reported the same way as a
> clean result.
>
> **A zero-story sprint scope is not the same as an absent sprint file.** If
> `production/sprints/` has no file at all, say that instead — "no sprint plan
> found" and "the sprint plan lists no stories" send the reader to different
> fixes, and Section 7 already draws that distinction for the handoff block.

---

## 2. Load Supporting Context

Before checking any stories, load reference documents once (not per-story):

- `design/specs/domain-map.md` — to know which features have approved specs (absent at `workflow: minimal`; `design/product-brief.md` stands in)
- `docs/architecture/control-manifest.md` — story-readiness needs only the header
  `Manifest Version:` date (its manifest check is existence + version, not the rule
  bodies), so grep it (`Grep pattern="Manifest Version" path="docs/architecture/control-manifest.md"`)
  rather than a full read. If the file does not exist, note it as missing once; do not
  re-flag per story.
- `docs/architecture/tr-registry.yaml` — index all entries by `id`. Used to
  validate TR-IDs in stories. If the file does not exist, say so once and
  **name the consequence**: the TR-ID item is `not checked — tr-registry.yaml
  absent` for every story that carries a TR-ID (it is written by
  `/architecture-review`). It is never a silent pass: at `full` (where the item
  blocks) the story is **NOT ASSESSED** for that item; at `standard` and `minimal`
  it is listed under Gaps as advisory. A story with no TR-ID reference is `N/A`.
  The registry's absence is itself a Gap line in the aggregate report.
- All ADR status fields — resolve these with **one scan, not one read per ADR**.
  A `Status:` value is a single line; reading whole ADR files to find it costs the
  entire architecture corpus, and in `all` scope that multiplies across every
  story in the repo:
  ```
  Grep pattern="^## Status" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
  ```
  Establish the denominator first (glob `docs/architecture/adr-*.md`, count **N**)
  and interpret against it: **0 matches with N > 0 means malformed ADRs, not
  "no Accepted ADRs"** — report "run `/architecture-decision retrofit [file]`"
  rather than failing every story's ADR check. Never treat an unreadable status as
  a failed one. Cache the resulting map; do not re-scan per story.
- **Research notes and threat models** — one Glob each, cached:
  `docs/research/*.md` and `docs/architecture/threat-models/*.md`. A note is matched to a story by the feature slug (the spec filename stem). Where the story names the path, check that path.
- **Contract stories** — from the story headers (one grep of `Type:` across `production/epics/**/story-*.md`), index which stories are `Contract` type and their `Status:`, so contract-ordering checks need no per-story reads.
- `contracts/` — Glob only, to confirm named operation files exist.
- The current sprint file (if scope is `sprint`) — to identify Must Have /
  Should Have priority for escalation decisions

---

## 3. Story Readiness Checklist

Read `references/checklist.md` and evaluate every item for each story file. A
story is READY only if all items pass or are explicitly marked N/A with a stated
reason. The checklist has eight groups:

1. **Design Completeness** — spec requirement referenced, self-contained, testable criteria
2. **Research and Security Gates** — research note exists (DoD gate 1) or the story is research-exempt per `research-protocol.md`; threat model linked when the feature hits a `security-baseline.md` trigger (SL-THREAT-MODEL)
3. **Architecture Completeness** — ADRs Accepted, TR-ID, manifest version, stack-reference notes, control-manifest rules
4. **Layers, Owners and Contract Order** — owner agent named per layer; contract story merged before dependent backend/client stories
5. **Scope Clarity** — DoD-inclusive estimate, in/out of scope, dependencies
6. **Open Questions**
7. **Referenced Files Check** — contracts, specs, UX specs, evidence paths exist
8. **Definition of Done** — story type set and its required evidence listed, minimum criteria, performance budget and cache decision on hot paths, negative/cross-tenant criteria

The tier note at the top of `references/checklist.md` says which items block at
`full`, `standard` and `minimal`. The research note and the threat model for a
sensitive story block at **every** tier — `minimal` has fewer documents, not
weaker engineering (`workflow-modes.md`).

Triggers (research-exempt table, threat-model triggers, hot-path definition)
are in `references/triggers.md`; read it when a story's category is not obvious.

---

## 4. Verdict Assignment

Assign one of four verdicts per story, first match wins in the order BLOCKED,
NEEDS WORK, NOT ASSESSED, READY (the precedence stated at the top):

**READY** — All checklist items pass, have explicit N/A justifications, or are
advisory-level gaps (a checklist item whose gate level resolved to advisory via
`testing.strict` / `performance.enforce`, or one the tier note makes advisory).
Advisory gaps are still listed under Gaps in the output.
The story can be assigned immediately.

**NEEDS WORK** — One or more checklist items fail, but all dependency stories
exist, are not DRAFT, and every required prerequisite artifact is present or
obtainable by the story's author. The story can be fixed before assignment.

**BLOCKED** — One or more dependency stories are missing or in DRAFT state,
OR a **Contract story the story depends on is not Complete (merged)**,
OR a governing ADR is `Proposed`, `Deprecated` or `Superseded`, or its file is missing,
OR the story is **security-sensitive and has no threat model** (or its threat model
carries an SL-THREAT-MODEL REJECT, or its residual risk has no named acceptor),
OR the research note lists a blocking open question with no resolution,
OR a critical design question (flagged UNRESOLVED in a criterion or rule) has
no owner. The story cannot be assigned until the blocker is resolved. Note:
a story that is BLOCKED may also have NEEDS WORK items — list both.

**NOT ASSESSED** — the story could not be evaluated at all (unreadable or
unparseable file, a referenced ADR with no readable `## Status`, or a referenced
spec that cannot be located, so the checks cannot run — a referenced
ADR file that does not exist is BLOCKED instead). Name what could not be read.
Never READY.

A **missing research note** is NEEDS WORK, not BLOCKED: the fix is `/research
[feature]` (or `researcher`) before `/dev-story`, and the story's author can
start it. Say so in the Fix line.

---

## 5. Output Format

### Single story output

```
## Story Readiness: [story title]
File: [path]
Verdict: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]
Type: [Logic / Integration / Contract / Security / Performance / UI / Config — or "missing"]
Required evidence: [the evidence the type requires, with its location and gate level (BLOCKING / ADVISORY)]
Owners: [layer → owner agent, e.g. contracts → api-designer; backend → go-lead; web → web-lead]
Research: [path | exempt — [table row] | MISSING]
Threat model: [path | not required — [reason] | MISSING]

### Passing Checks (N/[total])
Design Completeness: [passing items, briefly]
Research and Security Gates: [passing items — or "N/A — [reason]"]
Architecture Completeness: [passing items — or "N/A — [reason]", e.g. "N/A at `minimal` (referenced-ADR check applied)"]
Layers, Owners and Contract Order: [passing items]
Scope Clarity: [passing items]
Open Questions: [passing items]
Referenced Files: [passing items — or "no file references"]
Definition of Done: [passing items]

### Gaps
- [Checklist item]: [exact description of what is missing or wrong]
  Fix: [specific text needed to resolve this gap]

### Blockers (if BLOCKED)
- [What is blocking]: [story ID, ADR, contract story or threat model that must resolve first]

### Not checked
- [check] — [reason it could not run]
```

Name all eight check groups under Passing Checks every time. A group with nothing
passing says so ("none — see Gaps"), so a reader can see that each group was
evaluated rather than skipped.

### Multiple story aggregate output

```
## Story Readiness Summary — [scope] — [date]

Ready:        [N] stories
Needs Work:   [N] stories
Blocked:      [N] stories
Not Assessed: [N] stories

### Ready Stories
- [story title] ([path])

### Needs Work
- [story title]: [primary gap — one line]
- [story title]: [primary gap — one line]

### Blocked Stories
- [story title]: Blocked by [story ID / ADR / contract story / threat model / design question]

---
[Full detail for each non-ready story follows, using the single-story format]
```

### Sprint escalation

If the scope is `sprint` and any Must Have stories are NEEDS WORK, BLOCKED or
NOT ASSESSED, add a prominent warning at the top of the output:

```
WARNING: [N] Must Have stories are not implementation-ready.
[List them with their primary gap or blocker.]
Resolve these before the sprint begins or replan with `/sprint-plan update`.
```

---

## 6. Collaborative Protocol

This skill is read-only. It never proposes edits or asks to write files.

After reporting findings, offer:

"Would you like help filling in the gaps for any of these stories? I can
draft the missing sections for your approval."

If the user says yes for a specific story, draft only the missing sections
in conversation. Do not use Write or Edit tools — the user (or
`/create-stories`) handles writing.

**Redirect rules:**
- If a story file does not exist at all: "This story file is missing entirely.
  Run `/create-epics [context]` then `/create-stories [epic-slug]` to generate stories from the spec and ADRs."
- If a story has no spec reference and the work appears small: "This story has
  no spec reference. If the change is small (under about one week of implementation), run
  `/quick-spec [description]` to create a quick spec, then reference
  that spec in the story."
- If the research note is missing: "Run `/research [feature]` first — no feature is implemented from memory (DoD gate 1)."
- If a sensitive story has no threat model: "Run `/threat-model [feature]` — the story stays BLOCKED until SL-THREAT-MODEL has a model to review."
- If a client story's contract is not merged: "Complete the contract story first (`api-designer`, `/api-contract`); then re-run readiness."
- If a story's scope has grown beyond its original sizing: "This story appears
  to have expanded in scope. Consider splitting it or escalating to the producer
  before implementation begins."

---

## 7. Next-Story Handoff

After completing a single-story readiness check (not `all` or `sprint` scope):

1. Read the current sprint file from `production/sprints/` (most recent).
2. Find stories that are:
   - Status `Ready` (compare case-insensitively) — the same set `/dev-story` lists when it
     is run with no argument. A `Not Started` / `Draft` story has not passed a readiness
     check, so it is **not** offered as "next": list it on a separate line,
     `Needs /story-readiness first: [title] ([status])`. A story that is `In Progress`,
     `In Review`, `Complete` or `Done` is already started or finished and is never offered
   - Not the story just checked
   - Not blocked by incomplete dependencies (including an unmerged contract story)
   - In the Must Have or Should Have tier

If any are found, surface up to 3:

```
### Other Ready Stories in This Sprint

1. [Story name] — [1-line description] — Est: [X days] — Owner: [agent]
2. [Story name] — [1-line description] — Est: [X days] — Owner: [agent]

Run `/story-readiness [path]` to validate before starting.
```

If no sprint file exists, or no other ready stories are found, say which — `Next ready stories: no sprint file found` or `Next ready stories: none ready in [sprint]` — rather than omitting the section. The two mean different things (nothing to read versus nothing ready) and an omitted section reads as neither.

---

## Phase 8: Director Gates

Apply the review mode resolved in Phase 0 before spawning either gate below.
**Solo skips the director's opinion, never a checklist item above** — the
research, threat-model and contract-order checks already ran.

### 8a. QL-STORY-READY

- `solo` → skip. Note: "QL-STORY-READY skipped — Solo mode." Proceed to 8b.
- `lean` → skip. Note: "QL-STORY-READY skipped — Lean mode." Proceed to 8b.
- `full` → spawn as normal.

Spawn `qa-lead` via `Agent` using gate **QL-STORY-READY** (`.claude/docs/director-gates/ql-story-ready.md`).

Pass the context that gate lists, plus this skill's findings:
- Story file path
- Story type (Logic / Integration / Contract / Security / Performance / UI / Config) — the gate's prompt branches on it
- Acceptance criteria list (verbatim, all items)
- The spec requirement the story covers (TR-ID and text)
- Research note path and, for security-sensitive stories, the threat model path
- Dependency status (all dependencies listed and their current state: exist / DRAFT / missing; contract story status)
- Overall verdict (READY / NEEDS WORK / BLOCKED / NOT ASSESSED) from Phase 4

Handle the verdict per standard rules in `director-gates.md`:
- **ADEQUATE** → story is cleared. Proceed.
- **GAPS [list]** → surface the specific gaps to the user via `AskUserQuestion`:
  options: `Update story with suggested gaps` / `Accept and proceed anyway` / `Discuss further`.
- **INADEQUATE** → the gate says the story must be revised before sprint inclusion, so it is not READY: the verdict becomes at least NEEDS WORK (a BLOCKED one stays BLOCKED). List the gaps and restate the final verdict line, then ask whether to update the story or proceed anyway. If the user proceeds anyway, the verdict stays NEEDS WORK (BLOCKED if it was BLOCKED) and the output states the override — "proceeding despite QL-STORY-READY: INADEQUATE (user override)" — never a silent READY.
- **NOT ASSESSED [missing input]** → the gate made no judgement; never read it as ADEQUATE. Name the missing input and offer to supply it and re-run the gate; otherwise a READY verdict becomes NOT ASSESSED (BLOCKED and NEEDS WORK stand).

### 8b. SL-THREAT-MODEL (security-sensitive stories only)

Applies only to a story that hit a threat-model trigger and whose threat model file exists.

- `solo` → skip. Note: "SL-THREAT-MODEL skipped — Solo mode." The file-exists check in the checklist still stands.
- `lean` → skip. Note: "SL-THREAT-MODEL skipped — Lean mode."
- `full` → spawn `security-lead` via `Agent` using gate **SL-THREAT-MODEL** (`.claude/docs/director-gates/sl-threat-model.md`), passing the threat model path, the spec path, the story, and the architecture data-flow.

Handle the verdict: **APPROVE** → cleared. **CONCERNS [gaps]** → list the gaps; they become tasks inside the story's stories, user chooses via `AskUserQuestion`: `Update story` / `Accept and proceed anyway` / `Discuss further`. **REJECT** → the story is BLOCKED until the model is revised. **NOT ASSESSED [missing input]** → a READY verdict becomes NOT ASSESSED; name the input.

---

## Recommended Next Steps

- Run `/dev-story [story-path]` to begin implementation once the story is READY
- Run `/story-readiness sprint` to check all stories in the current sprint at once
- Run `/create-stories [epic-slug]` if a story file is missing entirely
- Run `/research [feature]`, `/threat-model [feature]` or `/api-contract` for the prerequisite artifacts the Gaps list names
