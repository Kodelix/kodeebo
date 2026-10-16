# /prototype — Phase 9: Summary and Next Steps

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 9: Summary and Next Steps

**Checkpoint.** Before the summary, update `production/session-state/active.md`
per `.claude/docs/checkpoint-handoff.md`, overwriting the Phase 4 build
checkpoint: Current task `/prototype <name> — <PROCEED | PIVOT | KILL | NOT
ASSESSED>`, Next step = the first step of the branch below, plus Blocked on /
Files in progress / Open questions; append the Notes line (the recommendation and
its ordered path). NOT ASSESSED or a declined write still updates it with the
blocker.

Output a summary: the hypothesis, the result, and the final recommendation. Link
to `prototypes/[name]/REPORT.md`.

**If PROCEED:**
The prototype validated the idea. Now build it properly, informed by what you just
learned. **The prototype code is not migrated** — it is rewritten to production
standards; the README findings and report feed the design.

At `workflow: minimal`: `/create-stories` (from the brief), then `/dev-story` on the
first story — the rest of this list is the `standard`/`full` path. The research
note (`/research`) and, for a sensitive area, `/threat-model` are required before
`/dev-story` at every tier.

Recommended path (in order, `standard`/`full`):
1. `/research [feature]` — turn what the prototype touched (a provider, a library, a query shape) into a sourced note; the report's "Security / tenancy surprises" seed the threat model
2. Update `design/product-brief.md` with what the prototype revealed (a decision-log line per finding, asked before writing) — `/spec-review` reviews one feature spec, not the brief, so it comes after step 5
3. `/gate-check` — confirm readiness to advance
4. `/map-domains` — decompose the product into bounded contexts and features
5. `/design-spec [feature]` — spec for each MVP feature; use prototype learnings (limits, thresholds, timeouts) in Detailed Behaviour and Non-Functional Requirements
6. `/review-all-specs` — cross-spec consistency check

**Note:** if a mock proved desirability but feasibility is still uncertain, run a
code spike on the feasibility question before writing specs.

**If PIVOT:**

Before routing to the next prototype, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

1. "What specifically worked in this prototype that we should preserve in the next version?"
2. "What is the single most important thing to change?"

Ask: "May I write this to `prototypes/[name]/PIVOT-NOTE.md`?"

If yes, write the file with: original hypothesis, what to keep, what to change, and
the revised hypothesis for the next prototype. The next `/prototype` run picks it up
at the start of Phase 1.

- Run `/prototype [revised-concept]` to test the adjusted direction
- Or `/brainstorm [hint]` if the concept needs more fundamental rethinking

**If KILL:**

Before moving on, confirm the verdict is sound and not temporary frustration:

- [ ] Core value still unclear to testers after 2+ sessions?
- [ ] No "aha" moment (task finished unaided, a pre-order, a "when can I have this?") observed in any session?
- [ ] 3+ PIVOT iterations on the same concept with no clear improvement?
- [ ] Concept only works when heavily explained or when the builder guides the user?
- [ ] The feasibility measurement misses the budget by an order of magnitude with no cheaper design in sight?
- [ ] Building this feels like obligation, not excitement?

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → consider one more focused PIVOT before killing. This checklist is also the decision rule when the third PIVOT on a concept forces the KILL question (`SKILL.md` Important Constraints): 0–1 boxes allows one more PIVOT with a changed hypothesis recorded in `PIVOT-NOTE.md`; 2+ boxes means KILL.

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this concept to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

```
## [Concept Name] — YYYY-MM-DD
- **Kill reason:** [specific blocker — not "it was boring" but "buyers never understood why they'd switch from spreadsheets"]
- **What worked:** [2-3 things worth carrying forward to future concepts]
- **What failed:** [the specific assumption, design decision or scope issue]
- **Next time:** [one explicit action to try differently on a similar concept]
```

- Run `/brainstorm open` or `/brainstorm [new-hint]` to explore a different concept
- The prototype report is the deliverable — no further action needed

**If NOT ASSESSED (nobody has used it):**

There is no evidence yet, so PROCEED, PIVOT and KILL are all unreachable — report
NOT ASSESSED and stop here rather than guess.

- Put it in front of the ICP (or run the measurement), then run `/prototype [same concept]` again
- The report and the index row read NOT ASSESSED until that happens

**Clean-up:** a concluded prototype is archived or deleted once its findings are
captured (`prototype-code.md` → Cleanup). It never grows into production code.

---
