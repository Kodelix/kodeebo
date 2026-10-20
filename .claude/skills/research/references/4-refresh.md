# /research - `refresh <layer>`

> Re-verify one layer of `docs/stack-reference/` and, with approval, update its
> **Last verified** date and `docs/stack-reference/pins.yaml`. Every write asks,
> in every automation mode: pins are what every agent builds against.

## R1. Resolve the layer

`Glob docs/stack-reference/*/VERSION.md` gives the list of layers (derived, never enumerated
here). The argument must name a directory in it. Otherwise stop, print the
directories that exist and ask which. Several layers may be named; each is
handled below, in parallel (R3).

Read, for the layer: `VERSION.md`, `best-practices.md`, `breaking-changes.md`,
`deprecated-apis.md`, and the layer's key(s) in `docs/stack-reference/pins.yaml`
(the mapping from layer to key is whatever the file shows; a layer with no key is
reported as such, not invented). Record the **Last verified** date of each file
and the date today.

If any of these files is missing or unreadable, that file is
`NOT ASSESSED - <path> unreadable` and the refresh of that layer is partial.

## R2. Build the claim list

Extract the re-verifiable claims, **only those the file states with a source**:
versions and their release dates, support or EOL dates, licences, image tags,
security floors, and any claim marked NOT SOURCEABLE (retry these once; they are
the likeliest to have changed). Each claim keeps its cited source link and the
line it came from. Claims the file marks as recommendations or inference
(`[R]`, "design guidance") are listed as **judgement - not re-verifiable**, not
re-asserted.

## R3. Spawn the researcher (read-only)

One `researcher` per layer, in parallel in one message. Fixed brief:

```text
Re-verify one layer of the stack reference for /research refresh.

Layer: {layer}   Today: {date}
Files: docs/stack-reference/{layer}/ (read VERSION.md, best-practices.md,
breaking-changes.md, deprecated-apis.md) and the {layer} keys of
docs/stack-reference/pins.yaml.
Charter: .claude/docs/research-protocol.md and .claude/rules/research-docs.md.
Claims to re-verify (each with its cited source): {the R2 list}

For each claim, fetch the cited source (or the primary source for that fact) and
report ONE of: UNCHANGED (source fetched, value confirmed, date of fetch);
CHANGED (old value, new value, source link, tier, date); NOT SOURCEABLE (what
was searched, why it failed). Also report: new security advisories (GHSA, OSV,
vendor) affecting the pinned versions, with the date you searched; new releases
on the same major that the file does not mention; deprecations or removals that
now apply; licence changes.
Do NOT edit, create or delete any file. Never fill a value from memory. Never
paste secrets or internal URLs into a query.
Return a table: claim | status | old | new | source | tier | fetched on.
```

Verify each reply contains a table covering every claim sent; a reply that
skips claims is incomplete, and the skipped claims are `NOT ASSESSED`. A
researcher that cannot be spawned makes the layer `NOT ASSESSED - researcher
unavailable`; nothing is updated and nothing is claimed re-verified.

## R4. Present the diff

Show per layer: the table, grouped CHANGED / UNCHANGED / NOT SOURCEABLE /
judgement; advisories; the proposed edits as an exact before/after for each
file. Then the **impact scan**, read-only:

- `Grep` `docs/research/*.md` for notes citing the changed component or old
  version; list them as **Stale (re-verify)**. Do not edit them.
- `bash .claude/scripts/project-coherence.sh` and report its real output (it
  compares the product's manifests with the pins; if it prints `SKIPPED`, say
  so). Run it **after** the edits too, if they are approved.
- A change that crosses a major version, drops support, or changes a licence
  (Redis, Dragonfly, Mongo, Valkey, OTel: the L1-L4 decisions in
  `.claude/docs/standing-decisions.md`) is flagged for `cto` / the user: it is a decision, not an
  update.

## R5. Approval and writes

Never proceed on a silent or dismissed answer.

1. `AskUserQuestion` per layer: apply all verified changes / apply selected /
   do not apply. A pin change is a `version_bumps` decision and a licence change
   a user decision; neither is auto-applied in `autonomous` mode.
2. Ask: "May I update `docs/stack-reference/<layer>/VERSION.md` (the changed rows
   and **Last verified**) and `docs/stack-reference/pins.yaml` (keys: [list])?"
   Name every path. Write only after approval. `pins.yaml` and `VERSION.md`
   change together; `pins.yaml`'s header says so. Other files of the layer
   (`best-practices.md`, `breaking-changes.md`, `deprecated-apis.md`) are edited
   only for rows the researcher marked CHANGED, with the same approval.
3. **The Last verified date is a claim about what was fetched.** Set it to
   today only if every row of that file was either UNCHANGED or CHANGED with a
   fetched source. If any row is NOT SOURCEABLE or NOT ASSESSED, leave the date
   as it was and add a line under it: `Refresh <today>: partially verified;
   not re-verified: <rows>`. A bumped date on a half-checked file would make the
   stale reference look fresh.
4. Update the `pins.yaml` header `Last verified` only when every layer in the
   file was refreshed in full; otherwise add a per-key trailing comment with the
   date for the keys that were.
5. Do not commit. Tell the user the two files must be committed together.

## R6. Report

```text
Refresh: <layer>  <date>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED
Rows: N unchanged, N changed, N not sourceable, N judgement (not re-verifiable)
Advisories: <list | none found - searched <sources> on <date> | search did not run>
pins.yaml: <keys changed | not changed>   Last verified: <set to today | left, partial>
Stale research notes: <paths>
project-coherence.sh: <real output summary | SKIPPED: reason | not run>
```

`COMPLETE` needs every row UNCHANGED or CHANGED with a source and the coherence
script run. Anything else is at best `COMPLETE WITH GAPS`; a layer whose files
or researcher were unavailable is `NOT ASSESSED`.

Next: `/dependency-audit` after a pin change; `/setup-stack` when a pin change
requires the product's manifests to move; `/research <feature>` re-verify for
each stale note.
