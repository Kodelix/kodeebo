# /reverse-document - Phase 4: Draft Through the Owning Agent and Verify

> Phase 4 of `SKILL.md`. The owning agent drafts; this skill verifies. The agent
> writes **no file**: nothing is written before "May I write" (Phase 5).

## 1. Collect the inputs the agent cannot get itself

`product-manager` has no Bash. Per the studio rule, the skill passes what it
resolved: the config block from the bootstrap line (`stack`, `workflow`,
`system_overrides`), the effective tier, the commit short hash, today's date
(`date +%F`), the ledger (Phase 2), the user's answers and the carried questions
(Phase 3). An agent that is told nothing about the tier would pick one.

## 2. Spawn the owning agent

Spawn the agent named for the mode in `SKILL.md` via `Agent`, with the brief
below, filling only the `{...}` slots and adding no opinion of your own. Mode
`concept` and `brief` and `spec`: `product-manager`; `research`: `researcher`;
`architecture`: `principal-engineer`, then its fallback in `2-modes.md`.
Independent sub-scopes (for example `architecture` across two code roots) may be
read by one agent each in parallel and merged by the lead agent; collect every
response before continuing.

```text
Draft a reconstructed document for /reverse-document. Return it as text; do not
create, edit or delete any file.

Mode: {mode}    Template (same headings, same order): {template path}
Tier: {effective tier}    Sections to generate: {list}    Sections NOT generated
at this tier (name them at the end of the draft): {list | none}
Config (resolved by the skill; use as given): {stack / workflow / system_overrides lines}
Provenance: generated from {paths} on {date} at commit {sha}
Output path (for the banner only; you do not write it): {path}

Evidence ledger (read in this run):
{E1 ... En, each with cite and kind}
User answers (confirmed, with date): {list | none}
Carried questions (user has not answered): {list | none}
Skipped / not assessed: {list | none}

Rules you must follow:
- Every factual statement cites `path:line` taken from the ledger or from lines
  you read yourself with Read/Grep. You may read the code roots to check or
  extend the ledger; add each new observation to the list you return. Run no
  shell commands.
- You may not state why anything was built, who it is for, what a number is meant
  to be, or what the product will become, unless a cited line or a dated user
  answer states it. Otherwise write `[UNVERIFIED — ask]` and add the question to
  Open Questions.
- An empty section keeps its heading and reads `none found in the source -
  searched <what>`. Never omit a heading the tier requires, never fill one from
  what a product like this usually has.
- A deduction is written `(inferred from <path:line>)`. A deduction about intent
  is `[UNVERIFIED — ask]`.
- Where an answer contradicts the code, state both and flag it for update.
- Do not copy any secret value, token, key or customer data; cite the file:line
  and write `value not copied`.
- Put the provenance banner immediately under the title, exactly as given: {banner text}
- Do not recommend or decide architecture, pricing or scope; record what exists.
  Follow-up work is a list of skills to run, not decisions made.

Return (text): the full draft, then a section `Observations added` (new ledger
rows with cites) and a section `Open Questions` (every `[UNVERIFIED — ask]`,
owner, what it blocks).
```

Mode additions to the brief:
- `researcher`: add the pinned versions read from `pins.yaml` with their
  stack-reference files and Last-verified dates, the stale references, the layers
  with no stack reference (write `NOT SOURCEABLE`, do not fill), and the
  licence decisions in force (`.claude/docs/standing-decisions.md` L1-L4, T1). It may use WebSearch
  and WebFetch **only** to source external facts about the choices in the ledger
  at the pinned versions (advisories on GHSA/OSV with the date searched,
  deprecations, official guidance, ASVS/MASVS IDs looked up in the official
  document). Source tiers 1-5 and "NOT SOURCEABLE" per
  `.claude/docs/research-protocol.md`. Never put a secret, customer data or an
  internal hostname in a query. Findings about the code stay Tier `code`;
  findings about the world carry a fetched link and a tier.
- `principal-engineer`: add the pins drift list and `docs/architecture/` files
  that exist (so the draft links them and does not contradict an accepted ADR).
  It may route a layer-specific read to the matching stack lead.

## 3. Verify the artifact first

The return contract is a draft in the reply containing the template's headings
for the tier. Check that before reading anything else
(`.claude/docs/error-recovery-protocol.md`, Trigger 0): a preamble, a summary, a
list of intentions or a file path instead of the document is a failed phase.
Resume the agent once naming the unmet contract; a second miss ends per
`SKILL.md` Error Recovery.

## 4. The provenance banner (required, every document this skill writes)

A reconstructed document lands at the same path and in the same format as one a
person wrote by hand, and every downstream consumer treats the two identically.
Nothing asks where it came from, so the document must say so. Immediately under
the title:

```markdown
> **Reconstructed from code** — generated by `/reverse-document <mode>` from
> `<paths>` on `<YYYY-MM-DD>`, at commit `<short-sha>`.
> This records what the code **does**. Items marked `[UNVERIFIED — ask]` are not
> confirmed by the author. Where this document and the code disagree, do not
> assume the document is the requirement. It stays a draft until a human confirms
> it and removes this banner.
```

Keep the banner on revision; removing it is the user's explicit act, never a
side effect of the next edit. Set the template's own status field to `Draft`
(research note) or `Reverse-Documented` (the others). The template's own
"Reverse-Documentation Notice" block stays beneath the banner.

## 5. Mechanical checks on the draft (run them, report each as `ran` / `not run - reason`)

| # | Check | Fails when |
|---|---|---|
| C1 | **Headings** - every heading the template requires at this tier is present, in order; sections not generated are named in a closing line | a heading missing, or a tier-skipped section not announced |
| C2 | **Banner and status** - banner under the title with path, date and commit; status set; research note has the `Origin:` line | missing or altered |
| C3 | **Citations** - every factual bullet and table row carries a `path:line` | an uncited claim (strip it into `Claims dropped`, or mark `[UNVERIFIED — ask]`) |
| C4 | **Cites resolve** - Glob each distinct cited path, Read the cited lines, confirm the file exists and the line is in range; for load-bearing claims (numbers, limits, TTLs, prices, roles, retention, permissions, tenant scope) confirm the line says what the draft says | a cite that does not resolve or does not say it. The claim is dropped, never "fixed" from memory |
| C5 | **Unknown inventory** - count `[UNVERIFIED — ask]`; each has an Open Questions row with an owner | a marker without a question, or a question without a marker |
| C6 | **No invented intent** - Grep the draft for causal and intent phrasing ("because", "in order to", "designed to", "intended", "so that", "to prevent", "the goal") | any hit without `(stated in <cite>)` or a dated user answer. Rewrite as observation or mark unverified |
| C7 | **No secrets or customer data** - the draft holds no key, token, password, connection string with credentials, real email or customer name | any hit: remove it, record `value not copied`, route to `/security-audit` |
| C8 | **Mode rules** - `spec`: `Source` lists every path read and the file stem equals `<feature>`; `architecture`: no ADR file is created or implied; `research`: tier column `code` for code evidence, `NOT SOURCEABLE` for unfetched external claims; `concept`: no tester quotes or outcome unless sourced | any violation |

Failures are fixed by resuming the agent once with the exact list (not by
rewriting the draft yourself from memory). What still fails after one resume is
stripped from the body and listed in a `Claims dropped - citation could not be
verified` block, and the verdict cannot be `COMPLETE`. A check that did not run
(a file unreadable, a Glob that errored) is reported `not run - reason`; if C4
did not run for any claim, the verdict is `NOT ASSESSED — citations unverified`
and the draft is shown but not offered for writing as a finished document.
