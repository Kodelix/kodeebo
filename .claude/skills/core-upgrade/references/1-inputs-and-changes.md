# /core-upgrade — Phases 1–2: Inputs, Target and the Changes

> Part of `/core-upgrade`. Read again if the conversation was compacted.

## 1. Inputs

Read `project.yaml`: `core.track`, `core.repo`, `core.version`, `core.modules`,
and the resolved `stack`. Record each as FOUND or ABSENT.

| Condition | Result |
|---|---|
| `core.version` unset or `core.modules` empty | nothing is adopted: route to `/core-use`; stop |
| `core.track` does not match `stack.backend` (go→go, ktor→kotlin) | `BLOCKED — track mismatch`; the user fixes config (`/setup-stack` / `/settings`) |
| `stack.backend` unset | STOP — `/setup-stack`; never default a track |
| `core.repo` unset or unreadable (`git -C <path> rev-parse --is-inside-work-tree` or `git ls-remote --tags <url>`; show output, credentials redacted) | `NOT ASSESSED — core repo not readable`; supply path/access or stop |
| `core.version` is not a tag in the core repo | `BLOCKED — pinned version <x> not found in <core repo>` (a pin that cannot be resolved is already broken; report it, do not guess a replacement) |

## 2. Target and scope

Arguments: `<release-tag>` · `latest` (the highest **released** tag above the pin
— released per the core repo's release policy in its `docs/`; if the policy
cannot be read, tags that parse as semantic versions, flagged `release policy:
NOT ASSESSED`) · `check` · none (ask: upgrade or check, which target).

- Target **equal** to the pin: "already at <tag>"; stop.
- Target **below** the pin: not this skill (a rollback). Stop and say how:
  revert the upgrade change set and the `core.version` edit together, on the
  user's explicit instruction.
- Target is a branch name, commit hash or range: refuse; a released tag only.
- List every release tag in `(pin, target]`. These are the **intermediate
  releases**: all of them are read in Phase 2, not just the target's.
- **Scope = `core.modules`.** Changes in modules the product does not consume are
  listed by name as "not read — not consumed", except where a consumed module
  declares a dependency on them (then they are in scope; a dependency that
  cannot be determined makes that module's transitive check `NOT ASSESSED`).

## 3. Read the changes (per consumed module, per intermediate release)

Read from the core repo at each tag (`git show <tag>:<path>`, or a throwaway
clone/worktree **outside** the product; never modify the core clone). For each
module × release, extract into a table:

| Item | Source | If missing |
|---|---|---|
| Version bump class declared (major / minor / patch) | the module's CHANGELOG heading | `NOT ASSESSED` for that release |
| **Breaking changes** | CHANGELOG "Breaking" section | heading absent → `NOT ASSESSED — CHANGELOG lacks a Breaking section` (this is **not** "none"); heading present with "None" → none *claimed* |
| **Deprecations** (symbol, replacement, earliest removal version/date) | CHANGELOG "Deprecated" section | same rule |
| **Migration steps** (code, config, data, order) | CHANGELOG "Migration" section | same rule |
| New, renamed, removed **config keys**; new required infrastructure | CHANGELOG and module docs/config schema | list as unknown |
| Toolchain / framework floors | module build files (`go.mod` `go` line and `toolchain`; Gradle catalogs/plugins) vs `docs/stack-reference/pins.yaml` and the product's own build files | unreadable → unknown |
| Data/schema changes shipped by the module | CHANGELOG, migrations in the module | list as unknown |
| Conformance results recorded at release | the release notes (written by `/core-release`) | "not recorded" — reported, not penalised |

If the module has **no CHANGELOG at all** (the core directory-structure requires
one per module), its verdict for the run is `NOT ASSESSED`; the port diff below
still runs and is reported, but a diff alone does not establish what behaviour
changed.

## 4. The diff, and the consistency check

For each consumed module, diff the module's **port files** (the files the core
repo's layout defines as the port — read the layout, do not guess) and its
**public config schema** between the pinned tag and the target:
`git diff <pin> <target> -- <port paths>`; show the real output (trim, do not
rewrite). If the core repo or the product defines an API-compatibility tool,
run it and show its output; if none is defined, the diff is a **manual review,
labelled as such** — there is no assumed tool.

Cross-check CHANGELOG vs diff, per release:

| Observation | Meaning | Action |
|---|---|---|
| Removed/renamed/re-typed port member with no Breaking entry | **CHANGELOG INCONSISTENT** — the diff wins | treat as breaking; list in the report for the core's owners |
| Breaking entry in a minor/patch release | policy violation (the deprecation/versioning policy in the core repo decides what is allowed; if unreadable, say so) | treat as breaking; report |
| Major bump with an empty Breaking section | suspicious | read the diff harder; report |
| Deprecation whose replacement or removal version is missing | incomplete deprecation | the product must treat the removal as imminent; report |

Print the per-module summary:
`<module>: <n> releases read · breaking <n> (claimed) / <n> (diff) · deprecated <n> · migration steps <n> · floors <changed|unchanged|unknown> · config keys +<a> ~<b> -<c> · data steps <n> · evidence: CHANGELOG <read|missing>, diff <run|manual|not run>`.
