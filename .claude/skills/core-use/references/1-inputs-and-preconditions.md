# /core-use — Phase 1: Inputs and Preconditions

> Part of `/core-use`. `SKILL.md` names when to read this file.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<module>` | The core module to adopt (e.g. one of identity, observability, otp, notify, storage, billing, licensing, tenancy, audit, ratelimit — the core repo's own module list is the authority, not this list) |
| `--version <tag>` | A requested **released** tag. Without it, Phase 2 proposes one |
| no argument | Ask which module (`AskUserQuestion`), offering the module list read from the core repo in step 3 if it is readable |

## 2. Read the product's side

Read `project.yaml` → `core.track`, `core.repo`, `core.version`, `core.modules`,
and the resolved `stack` line. Record each as FOUND or ABSENT.

**The track rule.** `core.track` follows `stack.backend`:

| `stack.backend` | Required `core.track` |
|---|---|
| `go` | `go` |
| `ktor` | `kotlin` |
| `go+ktor` | not decidable from config — ask which service adopts the module; a service uses the core of **its own** language. One product pins one `core.version`; if the two cores' tags differ, say so and stop (not supported by a single pin — route to `cto`) |
| unset | **STOP**: `stack.backend is unset in project.yaml — run /setup-stack`. Never default a track |

- `core.track` unset: propose the track from the table and ask; it is written in
  Phase 5, not now.
- `core.track` set and **different** from the table: **BLOCKED — track
  mismatch** (`core.track: <x>` vs `stack.backend: <y>`). The fix is the user's:
  correct `core.track` (a `schema_changes` decision) or revisit the stack with
  `/setup-stack`. Do not continue.
- `core.version` set and the module already in `core.modules`: report "already
  adopted at <tag>" and route to `/core-upgrade`; stop.

## 3. Read the core repo

`core.repo` is a git URL or a local path. Unset → ask for it; do not search the
disk for candidates.

1. Reachability: for a local path, `git -C <path> rev-parse --is-inside-work-tree`;
   for a URL, `git ls-remote --tags <url>`. Show the real output (credentials
   redacted). Not reachable → `NOT ASSESSED — core repo not readable (<reason>)`;
   offer: supply the path or access, or stop.
2. Released versions: the list of tags from the same command. A **release** is a
   tag the core repo's own release policy names (`docs/` in the core repo,
   written by `/core-release`). If the policy cannot be read, say so and treat
   only tags that parse as semantic versions as candidates, flagged
   `release policy: NOT ASSESSED`.
3. **No release exists** (no tags): **BLOCKED — no released core version.** A
   product pins a released tag only (`directory-structure.md`, "Core
   repositories"); it does not pin a branch or a commit. Options for the user:
   wait for `/core-release` in the core repo; use `/core-extract` if the
   capability is meant to be created from this product; or implement
   product-locally with a written reason (and a risk entry).
4. The module list at the candidate tag: the directories/docs the core repo's
   layout defines. The module must exist there. Not present → `BLOCKED —
   module <x> is not in <core repo> at <tag>`; route to `/core-extract` if the
   capability belongs in the core.

## 4. Read the product's need

| Input | Path | Why |
|---|---|---|
| Feature spec, Dependencies section | `design/specs/<feature>.md` | the capability the product needs from the module |
| Domain map core-vs-product split | `design/specs/domain-map.md` | the context the module serves |
| Research note | `docs/research/<feature>.md` | required for a new capability; for a sensitive module it feeds the threat model |
| Threat model | `docs/architecture/threat-models/<feature>.md` | required before adopting identity, billing, licensing, tenancy, audit-bearing or upload/webhook-bearing modules (`security-baseline.md`, Threat modelling) |
| Existing product-local implementation | grep in the code roots (`resolve_code_root`) | what the module replaces; an empty code-root result means the scan **did not run** |
| ADRs | `docs/architecture/adr-*.md` | an existing decision on this capability or on DI |
| Stack facts | `docs/stack-reference/<layer>/`, `pins.yaml` | toolchain floors the module must satisfy |

Absent rules: no spec and no research note → ask the user for the need in one
sentence and record `need: stated by user, no spec`; a sensitive module with no
threat model → `BLOCKED` at Phase 3 until `/threat-model` has run (the plan may
be drafted).

Print the input table (FOUND / ABSENT per row) before moving on.
