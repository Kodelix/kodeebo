# /core-release — Phases 5–7: Docs, Decision, Tag, Report

> Part of `/core-release`. Read again if the conversation was compacted.

## 1. CHANGELOG per module

The repo's existing CHANGELOG format wins for continuity. For a first CHANGELOG,
or to add what is missing, start from `.claude/docs/templates/changelog-template.md`
and keep its developer-relevant sections — **New Features** (here: Added),
**Improvements**, **Bug Fixes**, **Security**, **Known Issues** — then add the
three headings `/core-upgrade` reads, which are **mandatory in every entry, with
"None" when empty**:

- **Breaking changes** — each: what, why, the port member or key, the migration;
- **Deprecated** — each: symbol, replacement, earliest-removal version/date (the
  Phase 3 evidence);
- **Migration** — ordered steps for code, config and data (data steps in the
  expand→migrate→contract shape), including "upgrade through <tag> first" notes
  and minimum upgrade-from versions.

Each entry carries: module, version, date, the bump class and the evidence line
("diff reviewed manually" when no API-diff tool exists), and the conformance
result line. An entry is a sentence a consumer can act on, not a commit message.
Older entries lacking the three headings are reported (`core-upgrade` will read
them as `NOT ASSESSED`), not rewritten.

Draft by `release-manager` (spawn via `Agent`, return contract: draft written to
`production/releases/core-draft/changelog-<module>.md`, path, ≤5 bullets,
CONCERNS). Show the drafts. Ask: "May I write these entries to
`<module>/CHANGELOG.md` for each module in the release?" (paths from the layout).
Write only after approval.

## 2. Release notes for product teams

Template: `.claude/docs/templates/release-notes.md`. The audience is the **teams
that pin the core**, not end customers, so use these sections and omit the
customer-facing ones (Plan & Pricing Changes, Thank You, Coming Next):

| Template section | Content here |
|---|---|
| Headline | the one thing a product team must know |
| What's New | per module, version bump, one line each |
| Behaviour Changes | defaults changed, behaviour fixed to match the contract |
| Bug Fixes / Security | as in the CHANGELOGs; security with advisory ID once public |
| API & Integration Changes | **Added / Deprecated (with sunset) / Removed-Breaking (with migration)** across ports and config |
| Upgrade Notes | minimum pin-from version, data/config migrations, infrastructure floor changes, toolchain floors, rollback |
| Known Issues | including every `not run` cell and "unverified in this release" adapter |
| Technical Notes (Internal) | commit range, deferred items |

Add two blocks: the **module version table** (`module | previous | new | bump |
changes`) and the **conformance matrix** from Phase 4 verbatim. State at the top
the tag scheme in force, the `Applies to:` track, and `public-API diff: manual
review` where that holds.

`technical-writer` drafts (spawn via `Agent`, named path
`production/releases/core-draft/release-notes.md`, return contract as above);
`release-manager` reviews the version arithmetic against the table. Ask: "May I
write the release notes to `docs/releases/<tag>.md`?" The `<tag>` is the repo tag
derived under the scheme; with the scheme `NOT DECIDED` write `docs/releases/DRAFT.md`
and say why.

## 3. The release decision (always prompts)

Show one page: the bump table; deprecation checks; the matrix with every `not
run` / `FAILED` cell; scan results; the files written; the proposed tag and its
derivation; the verdict as it stands.

```
## Decision: release <tag>
Produced: CHANGELOGs, docs/releases/<tag>.md, conformance matrix, scan outputs (paths)
It decides: whether a tag is created from this commit
Options: A) release as shown  B) release with named unverified items (state them)  C) fix first  D) stop
Recommendation: <option> — <why, citing the matrix / the evidence>
```

`FAILED` anywhere, a refused bump, or a policy violation → options A and B are not
offered. `AskUserQuestion`; a dismissed question is not an answer — re-ask in
plain text. C or D ends the run with the verdict as it stands and `Tag: not created — user
stopped`; a declined write is `BLOCKED — write declined by user` for that file.

## 4. Commit and tag (separate, explicit)

`git add`, `git commit` and `git tag` have no `allowed-tools` grant: each is run
only after the user's explicit yes to that single action (the permission prompt
for the exact command confirms it again), or printed for the user to run. The
release-decision yes does not carry over to either.

1. **Commit.** The docs are uncommitted. Ask: "Commit the release files now?" —
   if yes (and only then, after showing the exact commands): `git add` only the files this skill wrote (list them), message
   `chore(release): <tag>` with a body listing module versions and the matrix
   result. If no: stop here; verdict `COMPLETE WITH GAPS` (files written, nothing
   committed, no tag). A tag must point at a commit that contains the CHANGELOG
   and notes; never tag a commit that does not.
2. **Tag.** Verify `git status --porcelain` is empty and the tag does not exist
   (`git tag --list <tag>`). Show the exact command and the commit it will point
   at; ask "May I create the annotated tag `<tag>` locally?" On yes:
   run `git tag -a <tag> -m "<headline>"` (or print it for the user to run) (plus module tags if scheme B). Never
   `--force`, never over an existing tag, never signed unless the core's policy
   says so and the key is the user's. Verify: `git tag -n1 <tag>` and
   `git rev-parse <tag>^{commit}` equals `git rev-parse HEAD` — show both.
3. **Push / publish.** Not done. Print: "Tag `<tag>` exists locally only. To
   publish: `git push <remote> <tag>` — your action. Registry publishing: not
   covered (`NOT SOURCEABLE` until the core's release policy defines it)." If the
   user instructs a push in this session, show the exact command, remote and ref
   and ask once more before running it.

## 5. Release record and report

Ask: "May I write the release record to `production/releases/core-<tag>.md`?"
(in the core repo; `docs/releases/` holds the product-facing notes, this is the
audit record). Contents: modules and bumps with evidence, tag scheme and its
source (policy quote or ADR), deprecation checks, the full matrix and scan
outputs with commands and exit codes, `not run` items, the decision and who made
it, commit hash, tag state.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/core-release <tag> —
<verdict>`, Next step = the first next command for product teams (or, on no-go
/ `BLOCKED` / `NOT ASSESSED`, the step that clears it), plus Blocked on / Files in
progress (CHANGELOG, release record) / Open questions; append the Notes line.
Still updated when the release is declined or a write is refused (record what was
and was not written). The tag is never pushed by this step.

Final report: the verdict; `Tag: created locally (not pushed)` or `not created —
<reason>`; the module version table; the matrix summary (`n passed, n FAILED, n
not run`); **Not run / not checked** (always present; "none" only when true:
API-diff tool, adapters without tests, products' use of deprecated symbols, signed
tags, registry publish); and the next commands for product teams.
