# /create-stories — Step 4b: QA Lead Story Readiness Gate

> Part of `/create-stories`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4b. QA Lead Story Readiness Gate

**Review mode check** — apply before spawning QL-STORY-READY:
- `solo` → skip. Note: "QL-STORY-READY skipped — Solo mode." Proceed to Step 5 (present stories for review).
- `lean` → skip (not a PHASE-GATE). Note: "QL-STORY-READY skipped — Lean mode." Proceed to Step 5 (present stories for review).
- `full` → spawn as normal.

After decomposing all stories (Step 4 complete) but before presenting them for write approval, spawn `qa-lead` **once** via `Agent` using gate **QL-STORY-READY** (`.claude/docs/director-gates/ql-story-ready.md`). A single call returns **both** the readiness verdict and the test-case specs — do not spawn `qa-lead` a second time to generate specs.

Pass: the full story list inline — no story file exists yet, so the stories themselves stand in for the gate's story paths — with each story's acceptance criteria, story type, and TR-IDs with their requirement text from `tr-registry.yaml`; the epic's spec acceptance criteria for reference; the research-note path and, for Security stories, the threat-model path (present or MISSING). Require in the return:
1. The QL-STORY-READY verdict per story (ADEQUATE / GAPS / INADEQUATE, or NOT ASSESSED naming a missing input).
2. For every story it marks **ADEQUATE**, its test-case spec block (formats below) — one Given/When/Then per acceptance criterion for Logic, Integration, Contract and Security stories, or manual verification steps for UI stories.

Present the assessment, then act on each story's verdict — the gate's own words, handled per `.claude/docs/director-gates.md`:

- **ADEQUATE** — keep the returned specs.
- **GAPS** — use `AskUserQuestion`: `Revise flagged criteria` / `Accept and proceed` / `Discuss further`. Do not revise before the user chooses. On *Revise*, draft the revised criteria, show them, and re-request specs for just those stories in one follow-up call. On *Accept*, the criteria stay as written and the story carries no qa-lead specs — its `## QA Test Cases` reads `*Test cases not yet defined — run /qa-plan to generate them.*`
- **INADEQUATE** — blocking: the story is not written as it stands. Revise its criteria with the user (draft, show, confirm), then re-request its specs; if the user will not revise it, drop it from this run and name it as dropped in the Step 5 list.
- **NOT ASSESSED** [missing input] — not an ADEQUATE: name what was missing, then supply it and re-request that story's verdict, or write the story without qa-lead specs (the `/qa-plan` line above in its `## QA Test Cases`) and mark it `QL-STORY-READY: NOT ASSESSED — [input]` in the Step 5 list.

Untestable criteria cannot be implemented correctly, so a story carries qa-lead specs only once it is ADEQUATE. Criteria the gate marks `DEFERRED` (they need a deployed stack, a real provider or a store review) keep their text and the condition under which they become testable; a deferred criterion is not a blocked story.

**Prefer an existing QA plan when one already covers a story** — this substitutes for the qa-lead's specs, it does not add a spawn. Glob `production/qa/qa-plan-*.md` for the most recent file; if it holds test specs for stories in this epic (match titles/slugs in its Automated Tests Required section) that differ from the qa-lead's, use `AskUserQuestion` (Use QA-plan specs / Use qa-lead specs / Skip and leave `*Test cases not yet defined — run /qa-plan to generate them.*`). Either way no additional `qa-lead` spawn occurs.

The spec block formats — Logic / Integration / Contract / Security:

```
Test: [criterion text]
  Given: [precondition — including tenant and role]
  When: [action]
  Then: [expected result / assertion]
  Negative: [wrong role / other tenant / invalid input / replay — as applicable]
  Edge cases: [boundary values or failure states to test]
```

For UI stories, produce manual verification steps instead:
```
Manual check: [criterion text]
  Setup: [how to reach the state — role, tenant, locale (AR/RTL and EN)]
  Verify: [what to look for]
  Pass condition: [unambiguous pass description]
```

These test case specs are embedded directly into each story's `## QA Test Cases` section. The engineer implements against these cases. The engineer does not write tests from scratch — QA has already defined what "done" looks like.

---
