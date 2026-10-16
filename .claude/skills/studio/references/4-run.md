# /studio — Phase 4: Run the Flow

> Part of `/studio`.

## Executing a step

- **A step that is a skill** → invoke it with the Skill tool and pass the
  context it needs (feature name, paths). Its own gates and protocol apply.
- **User-typed skills.** These are `disable-model-invocation: true` on purpose
  and cannot be invoked through the Skill tool. Derive the set, do not trust a
  copy: use the Grep tool with pattern `disable-model-invocation: true`, glob
  `.claude/skills/*/SKILL.md`, output mode `files_with_matches`
  (today `/dev-story`, `/story-done`, `/db-migration`, `/hotfix`,
  `/post-release-fix`, `/incident`, `/pentest`, `/core-release`). For them: print
  the exact command with its arguments (e.g.
  `/dev-story production/epics/billing/story-003.md`), record it as the **Next**
  line in the checkpoint, and pause. If the Skill tool refuses a skill, that is
  the same hand-off — never route around it by doing the skill's work yourself.
  On `/studio resume`, verify the step's artifacts on disk before moving on —
  never assume the user ran it:
  - `/dev-story`: the story's `Status:` — `In Review` means implemented and next
    for `/story-done`; `In Progress` means started, not finished; `Ready` means
    not started. Also the evidence folder `production/qa/evidence/<STORY-ID>/`.
  - `/story-done`: `Status: Complete` and a `## Completion Notes` section.
  - `/db-migration`: the migration files and the lint output.
  - `/pentest`: `pentest-report.md` in its evidence folder.
  A step whose artifact is not on disk is reported as `not done`, not skipped.
- **A step owned by an agent** → spawn the owner from `agent-roster.md` with:
  the goal, the paths to read, the exact destination path for any new
  artifact (this activates the agents' orchestrated-write exception), and the
  verdict words expected.
- **Independent steps run in parallel** (coordination-rules.md parallel task
  protocol): e.g. `/research` for two providers; `/cache-design` and
  `/api-contract` once the spec is approved. Dependent steps run in order.
- **Never do a specialist's work yourself** when the owner exists.
- **Freshness checks** (is an evidence file, review or smoke report current?) use
  the Dating rule in `.claude/skills/story-done/` (file `2-read-story.md`): `git log`
  is valid only for tracked, clean files; uncommitted work is dated by file mtime
  or the artifact's own date line, and the source used is named.

## Gates (always prompt, every automation mode)

research conclusion · spec approval · threat-model residual risk · ADR ·
story list · each story's Done · release go/no-go · any destructive data step
(migration apply, deletion) · anything publishing externally · each promotion
step of a staged rollout. Two of these carry a content check, not just a prompt:
a research note must be `Status: Complete` (or its gaps accepted in writing), and
a threat model must carry a residual-risk acceptance by a named person — a
subagent's or a skill's "done" never stands in for either.

Present each gate:

```
## Decision: <what>
Produced: <paths>
It decides: <one line>
Options: A) … B) … C) …
Recommendation: <option> — <why, citing the artifact>
```

Then `AskUserQuestion`. A skipped or dismissed question is not an answer:
re-ask in plain text and wait.

## BLOCKED, failures, missing skills

- BLOCKED from an agent/skill: stop the flow at that step; show what is needed.
- A failing check is shown with its real output; the flow does not proceed past
  a BLOCKING gate without the user's explicit override, recorded with the risk.
- Missing skill: run the step manually against its standard and say so.

## Conflicts

Product → `product-director`; technical → `cto`; schedule/cross-team →
`producer`; business/market → `business-director`. Present the conflict and the
owner's recommendation; the user decides.
