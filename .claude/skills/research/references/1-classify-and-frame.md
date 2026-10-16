# /research - Phase 1: Parse, Classify, Frame

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `refresh <layer>` | Refresh mode: stop here and follow `4-refresh.md` |
| `<feature-slug>` matching a file in `design/specs/` or a story slug | Note mode for that feature; the spec and story are inputs |
| a free-text question | Note mode; derive a kebab-case slug and confirm it with the user |
| nothing | Ask which feature or question (`AskUserQuestion`); do not guess from the last file touched |

`--review` is the only flag. The slug is the **spec filename stem**
(`design/specs/team-invitations.md` -> `team-invitations`), so
`docs/research/team-invitations.md` lines up with
`workflow_overrides.system_overrides.<feature>` (`workflow-modes.md`). A slug
that collides with an existing note is handled in step 3, not overwritten.

## 2. Apply the exemption table

`.claude/docs/research-protocol.md` "When research is required":

| Change | Research note required? |
|---|---|
| New feature, new integration, new external provider | **Yes** |
| New library, framework feature, or major version bump | **Yes** |
| Anything touching auth, billing, licensing, crypto, file upload, PII | **Yes**, and it feeds the threat model |
| Bug fix inside existing, already-researched code | No - cite the existing note |
| Copy, styling, config value change | No |

Classify the request against the rows. **Ask when it is not obvious**
(`AskUserQuestion`): a "small" change that adds a dependency, a provider call, a
new HTTP surface or a new data class is a **Yes** row, whatever it is called.
When two rows match, the stricter one wins.

- **Exempt row:** the verdict is `EXEMPT`. Write nothing. Report the row that
  applies and, for the bug-fix row, the **existing note** to cite (find it with
  `Glob docs/research/*.md` and `Grep` for the component). If no existing note
  covers the code, the bug-fix exemption does not hold ("already-researched" is
  the condition): reclassify as required. Give the user the one line to put in
  the story: `Research note: exempt - <row>; see docs/research/<slug>.md`.
- **Required row:** continue. If it touches auth, billing, licensing, crypto,
  file upload or PII, record "feeds threat model" now; Phase 4 routes to
  `/threat-model`.

State the classification and the row in the output so a skipped note is never
indistinguishable from a note that was not needed.

## 3. Look for existing notes (reuse before re-researching)

`Glob docs/research/*.md`; `Grep` for the feature slug, the component names and
the provider. For each hit read its Status, date and Versions table.

| Finding | Action |
|---|---|
| No relevant note | New note |
| A note for the same slug | Ask: **re-verify** (update stale rows, keep decisions), **extend** (new section for a new question), or **replace** (user confirms the old file is superseded; keep it until the new one is written). Never overwrite silently |
| A note for a related feature that covers the same component | Reuse its findings by link; research only the delta; say which findings were reused |
| A note whose cited pin is older than the current `pins.yaml` value | Mark every reused finding from it **stale** and re-verify before relying on it (`research-protocol.md` Rules) |

## 4. Frame the question

Agree these with the user (`AskUserQuestion` for choices, plain text for the
rest). Capture them in the brief, not in the note: the note's own Question
section is the researcher's job.

1. **The decision this research informs**, in one paragraph. A research request
   with no decision attached is a reading list; ask what will be decided.
2. **Layers and components touched**: map each to a `docs/stack-reference/`
   directory (derive the set with `Glob docs/stack-reference/*/VERSION.md`, do not work from a
   fixed list) and to its `pins.yaml` keys.
3. **Feature link:** `design/specs/<slug>.md` (absent at `minimal` is fine) and
   the story ID if there is one.
4. **Distribution scope:** hosted only, or hosted and self-hosted bundle. A
   self-hosted scope triggers the L1-L4 licence check and the multi-version
   upgrade question.
5. **Known constraints:** budgets (`perf-budgets.md`), tenancy model, anything
   the user already ruled out. Ruled-out options are still listed in the note
   with the reason, so the record is complete.
6. **Sensitive-input check.** Read the question text and the user's pasted
   context for secrets, tokens, customer data, personal data or internal
   hostnames. If any appear, **stop and ask the user to rephrase**; nothing with
   such content goes into a brief or a web search.

## 5. Confirm the destination

State: "The note will be written to `docs/research/<slug>.md` by `researcher`."
Ask once for approval of that path (this is the approval the subagent write
relies on). In `autonomous` mode log the choice with `log_decision`; the path is
a `minor` decision unless a note already exists at it, which is step 3.
