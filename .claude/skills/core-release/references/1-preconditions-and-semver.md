# /core-release — Phases 1–2: Preconditions and Semver

> Part of `/core-release`. Read again if the conversation was compacted.

## 1. Is this the core repo?

Observe, then confirm with the user (`AskUserQuestion`: "Release from this
repository? It looks like <X>."):

```
git rev-parse --show-toplevel          # the repo
git branch --show-current ; git log -1 --oneline
git status --porcelain                 # must be empty
git tag --list --sort=-version:refname # existing releases
```

Signals of a **core repo**: the repo name (`saas-core-go` / `saas-core-kotlin`),
module directories each with ports, adapters, conformance tests and a `CHANGELOG`
(`directory-structure.md`, "Core repositories"), `docs/` with a versioning and
deprecation policy. Signals of a **product repo**: `project.yaml` has `core.track`
set and `contracts/` plus `backend/` / `web/` / `mobile/` exist and no module
carries a `CHANGELOG` → **refuse**: "run `/core-release` inside the core repo".

Record: track (`stack.backend`: `go` or `ktor` in the core repo's `project.yaml`;
unset → STOP `/setup-stack`; this chooses `go-lead` or `ktor-lead`), the module
list and where each module's CHANGELOG lives. **The layout was finalised by an
ADR when the core was built:** read it from the core's `docs/`. If no layout can
be read, ask the user for the module list and CHANGELOG paths and record
`layout: stated by user`; do not scan the filesystem for guesses.

**Dirty tree → `BLOCKED`.** Everything this skill writes must be the only
uncommitted change; ask the user to commit or stash first, then re-run. The
branch releases are cut from is the user's choice (record it; do not assume
`main`).

## 2. Last release and the tag scheme

Find each requested module's **last release**: its latest tag (module tag or the
repo tag whose notes list the module), via `git tag`/`git log`. A module with no
previous release is `first release` (the baseline is the root; the proposed first
version is the user's call, per the core's versioning policy).

**Products pin one repo-level tag** (`core.version` in a product's `project.yaml`,
e.g. `v0.4.2`), so a repo-level release tag always exists. The open points are
whether modules also get their own tags and how the repo tag's number follows the
module bumps. Read the core's policy (`docs/`). **If it is absent or silent:**
`tag scheme: NOT DECIDED`. Do not choose one silently. Present, with the
recommendation, and record the choice in an ADR (tell the user to run `/architecture-decision`;
this skill does not run other skills) before tagging:

- A) one repo tag per release; its bump is the **highest** bump among the modules
  released in it; module versions are listed in the notes and each CHANGELOG;
- B) A plus module tags `<module>/<version>` so a module's history is
  addressable;
- C) the policy's own scheme (read, quoted, applied).

The scheme is a `schema_changes`-class decision: asked, never defaulted. Without
it, Phases 1–5 can run but **Phase 6 cannot create a tag**.

## 3. The change set per module

For each module in scope (the argument, or all modules with changes since their
last release — `git diff --stat <last-tag>..HEAD -- <module>`):

1. `git log --oneline <last-tag>..HEAD -- <module>` — the commits (Conventional
   Commits prefixes are hints, not evidence).
2. `git diff <last-tag>..HEAD -- <port paths>` — the **port** files the layout
   defines; and the module's config schema, error types, persisted-data
   migrations, build files (toolchain floors) and adapter list. Show the real
   output (trim, do not paraphrase).
3. If the repo defines a public-API compatibility check (a script, a CI job, a
   build task), run it and show its output. If it does not: `public-API diff
   tool: not defined in this repo — manual review of the diff above` appears in
   the record and the release notes. Do not name or install a tool from memory;
   propose `/research` + `dev-tooling-engineer` (through `principal-engineer`) to
   choose and pin one.

A module with **no change** since its last release is not released: `unchanged —
not in this release`. A module whose only changes are docs/tests: PATCH at most,
or none — the user decides.

## 4. Classification and the bump

Classify each change by who is affected. A **port** is *called* by products
(consumer port) or *implemented* by products (extension point — e.g. a custom
adapter or a fake); the second kind is stricter.

| Class | Examples (on the diff) | Bump |
|---|---|---|
| **Breaking** | removed or renamed port member, type, error or config key; changed signature, return type, error type or documented semantics; tightened validation; **a new member on a port that products implement**; a new required config key without a default; a changed default that changes behaviour; a changed persisted format or schema without an automatic migration; a raised toolchain/framework/infrastructure floor; a dropped adapter or dropped track support; a removal of anything deprecated | **MAJOR** |
| **Additive** | new port or new member on a consumer-only port; new adapter; new optional config key with a default; new deprecation notice (the thing still works); new metric/span attributes that do not change existing ones | **MINOR** |
| **Fix** | behaviour fixed to match the documented contract; performance; internal refactor; docs; dependency patch without a floor change | **PATCH** |
| **Security fix** | as above; also listed under Security in notes and CHANGELOG; a fix that must break a contract is MAJOR with the advisory stated | per class |

- **Before 1.0:** whether a minor bump may carry breaking changes is the core's
  policy; read it. If it cannot be read, `pre-1.0 policy: NOT ASSESSED` and the
  skill applies the table above unchanged (a breaking change is MAJOR).
- A module whose release requires a **data/schema migration** states the
  migration in its Migration section and `/db-migration`'s expand→migrate→contract
  shape (`.claude/rules/migrations.md`); a module that cannot migrate in place
  without downtime is MAJOR.

Per module build the table: `module | last tag | changes (n) | breaking | additive |
fix | proposed bump | resulting version | evidence (changed symbols with file:line)`.

**Review (parallel, one message):** `principal-engineer` reviews the API surface
and the classification against the diff; `release-manager` checks the version
arithmetic, the tag scheme and the CHANGELOG impact. Each writes to a named path
(`production/releases/core-draft/semver-<agent>.md`, bounded exception: a new
artifact under `production/`, gated by the decision below). Return contract: the
path, a ≤5-bullet summary, CONCERNS/BLOCKED lines.

**Decision (`AskUserQuestion`), per module or batched:** accept the proposed bump ·
raise it · remove a change from the release. **A bump lower than the evidence
supports is refused** (`BLOCKED`), because a mislabelled breaking change breaks
every consumer that trusts the number; the user's options are to raise the bump or
to take the change out of the release.
