# /setup-stack — Phase 7: Output Summary

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 7. Output Summary

After the run, output:

```
Stack Setup
===========
Backend:        [go | ktor | go+ktor | unset]      Core track: [go | kotlin | unset]
Web / Site:     [vite-react | none | unset] / [astro | none | unset]
Mobile:         [compose | kmp | kmp+swiftui | swiftui | none | unset]
Data:           [postgres, mongo, redis, dragonfly — those set | unset]
Messaging:      [value | unset — decide with /research]
Deploy:         [compose-vps | kubernetes | unset]
Distribution:   [hosted | self-hosted | hybrid | unset]
Tenancy:        [model | unset]
Code roots:     [list | unset (detected: ...)]
project.yaml:   [updated | unchanged | not written — declined]

Stack reference (docs/stack-reference/):
  FRESH [n] · STALE [n] · UNDATED [n] · MISSING [n] · no reference exists [n]
  [one line per layer that is not FRESH, with date/age or reason]
Toolchain probe: [n matched · n differ · n NOT DETERMINED]
Coherence check: [ran — MATCH n · AHEAD n · BEHIND n · FLOATING n · LICENCE n · ABSENT n · SKIPPED n | NOT ASSESSED — reason]

Unset by choice: [layers left unset]
Findings: [cross-field and licence findings from Phase 3, or none]
```

Then print **one** next-steps list matching the resolved `workflow` tier. Name only
skills that exist (Glob `.claude/skills/<name>/SKILL.md`); mark others
"(not installed yet)".

**`minimal` — the lean 4-step floor (you are on step 1):**
```
2. /brainstorm — the one-page design/product-brief.md (skip if it already exists)
3. /create-stories — turn the brief's MVP list into stories
4. /dev-story — first line of product code, after the feature's research note
```
(No `/map-domains`, `/design-spec`, `/create-architecture` or `/sprint-plan` at
`minimal` — the brief replaces the specs and its build order is the plan. The
eight Definition of Done gates still apply.)

**`standard` / `full` — the full pipeline:**
```
2. /brainstorm → /map-domains → /design-spec (×N) — if no brief or specs yet
3. /create-architecture → /architecture-decision (×N) — the stack is now fixed
4. /gate-check — Discovery → Product Design and onward
```
Add `/studio <goal>` as the main entry point if `.claude/skills/studio/SKILL.md`
exists; otherwise say it is not installed yet.

### Verdict

- **COMPLETE** — every set layer validated, the changeset (if any) written and read back, every required stack reference `FRESH`, and the coherence check ran.
- **COMPLETE WITH GAPS** — everything above except one or more of: a `STALE`, `UNDATED` or `MISSING` reference, a layer with no reference, an unresolved cross-field finding, a probe that could not determine a version. The gaps are listed by name. This is the best a run with an outstanding item can say.
- **NOT ASSESSED** — the coherence check, the enum validation, or the stack-reference scan did not run. Name which, and what would let it run.
- **CANCELLED** — the user declined the write; nothing changed.

Rank: `NOT ASSESSED` outranks `COMPLETE`, and a known gap is never hidden behind
it. Never print COMPLETE with a stale or missing reference or an unrun check
outstanding.

**Checkpoint.** Before the final message, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/setup-stack — <verdict>`, Next step = the first item of the
next-steps list printed above (for `minimal`, `/brainstorm`), plus Blocked on
(stale/missing references, an unrun check) / Files in progress (`project.yaml`
if written) / Open questions (layers left unset); append the Notes line. Still
updated for NOT ASSESSED and CANCELLED, with the blocker or "nothing written".

---
