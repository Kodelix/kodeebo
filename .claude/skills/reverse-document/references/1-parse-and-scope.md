# /reverse-document - Phase 1: Parse and Scope

> Phase 1 of `SKILL.md`. Read-only except for the questions it asks. Nothing is
> written here. Mode details are in `2-modes.md`.

## 1. Parse the argument

`$ARGUMENTS` is one of these shapes. Anything else stops here.

| Argument | Meaning |
|---|---|
| `brief` | Product brief from the code |
| `research <context>` | `<context>` = a bounded context (a directory name under a code root, for example `billing`) |
| `spec <feature>` | `<feature>` = the spec filename stem, lowercase kebab-case (`team-invitations`); it is also the key under `workflow_overrides.system_overrides` |
| `architecture` | Whole-product architecture doc; takes no path |
| `concept <prototype-dir>` | `<prototype-dir>` = a directory under `prototypes/` (for example `prototypes/quote-flow`) |

- **Empty argument or an unknown mode:** verdict `BLOCKED` - print the five
  shapes above and ask which one. Do not guess a mode from the repository.
- **A mode that needs a name and has none** (`research`, `spec`, `concept`):
  `BLOCKED — needs <context | feature | prototype-dir>`. If the repository makes
  the candidates obvious (the bounded-context directories with no note in
  `docs/research/`, the prototypes without a `README.md`), list them and ask via
  `AskUserQuestion`; the answer completes the argument. A dismissed question is
  not an answer: re-ask in plain text and wait.
- Normalise `<context>` and `<feature>` to lowercase kebab-case for the output
  filename and say so if it changed.
- `concept` accepts the path with or without a trailing slash; it must resolve to
  a directory directly under `prototypes/`. A path outside `prototypes/` is
  `BLOCKED` - this mode reads prototypes only (a production feature is `spec`).

## 2. Resolve the code roots

Run `bash .claude/hooks/yaml-helper.sh resolve_code_root`. It prints
`<roots>\t<source>`: the space-separated roots (`layout.code_roots` from
`project.yaml`, else the conventional `backend/ web/ site/ mobile/ contracts/
core/` that exist) and where they came from (`layout.code_roots`, `detected` or
`unset`).

- **Roots empty or source `unset` (modes `brief`, `research`, `spec`,
  `architecture`):** verdict `NOT ASSESSED — no code root resolved`. Say plainly
  that this is not "the product has no code": a codebase under `app/` or
  `services/` is invisible to the conventional scan. Ask the user where the code
  lives and tell them `/setup-stack` records it in `layout.code_roots`. Stop;
  write nothing.
- **A resolved root that does not exist on disk:** report it by name as not
  scanned (`NOT ASSESSED — root <r> missing`) and continue with the roots that
  exist; the final verdict is `NOT ASSESSED` if the missing root was the one the
  target lives in.
- **Mode `concept`** reads `prototypes/<name>/` and does not need a code root.
  Production code roots are still read for one purpose only: to confirm the
  prototype is not imported by production code (`.claude/rules/prototype-code.md`),
  and that check is reported as run or not run.
- Read `docs/stack-reference/pins.yaml` when it exists (used by `research` and
  `architecture`); absent means "pins not available", reported as such, never
  "no drift".

## 3. Resolve the effective tier

The bootstrap block above carries `workflow` and `system_overrides`. The tier
that matters is the **feature's** for `spec`: `system_overrides.<feature>` when
listed, else the project `workflow`. The other modes are tier-independent in
*what they write*, but the tier decides where follow-up decisions are recorded:
"an ADR (at `workflow: minimal`, an entry in the brief's decision log)". Semantics
of the tiers are in `.claude/docs/workflow-modes.md`. State the tier in the
findings (Phase 3). An unresolved tier is stated as unresolved, not assumed
`minimal`.

## 4. Check the output path before reading anything else

Compute the output path from `2-modes.md`, then Glob it.

| What is at the path | Action |
|---|---|
| Nothing | New file. Continue |
| A file that is empty or only the unfilled template (placeholders such as `[Working Title]`, `[Feature Name]`, no real content) | Treat as absent, but the write question in Phase 5 names it as "replacing an unfilled template" |
| A file whose first 15 lines contain `Reconstructed from code` (this skill's banner) | A previous reconstruction. Continue in **update** mode: Phase 5 shows a per-section diff and asks to update that file; the banner stays |
| Any other file | An authored document. **Never overwrite or merge into it.** Verdict `BLOCKED — <path> exists and is authored`. Offer, via `AskUserQuestion`: write the reconstruction beside it as `<name>.reconstructed.md` for comparison, or stop. Only the first re-enters the flow, with the new path as the target. Declining both leaves the verdict `BLOCKED` |

For `research <context>` the skill's premise is "code but no note": an existing
authored note at `docs/research/<context>.md` is `BLOCKED — note exists`, and the
next step is `/research <context>` (it extends or re-verifies a note); this skill
does not touch it.

## 5. Announce the scope

Print, before Phase 2 starts: mode, resolved roots and their source, effective
tier, the target code paths, the output path and whether it is new or an update.
Anything unresolved above is printed as `NOT ASSESSED` with its reason, so a
silent skip and a successful step never look alike.
