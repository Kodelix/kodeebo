# /dependency-audit - Phase 3: Project Coherence, Deprecated APIs, Freshness

> Phase 3 of `SKILL.md`. These checks read the studio's own references. A
> reference that is missing, empty or undated makes its check `NOT ASSESSED`.

## 1. `project-coherence.sh`

```bash
bash .claude/scripts/project-coherence.sh
```
The script emits **observations, never verdicts**, and always exits 0. Quote its
output in full in the evidence folder. Line statuses: `MATCH`, `AHEAD`, `BEHIND`,
`FLOATING`, `LICENCE`, `ABSENT`, `SKIPPED`.

| Status | Handling |
|---|---|
| `LICENCE` | an engine in `deploy/self-hosted/` that breaks L1-L4: a finding (see `4-licences-and-bundle-rules.md`), HIGH |
| `FLOATING` | image tag `latest` or a bare major: not reproducible; MEDIUM |
| `BEHIND` | declared below the pin: check the layer's `breaking-changes.md` before recommending; MEDIUM (HIGH if a listed fix is a security fix) |
| `AHEAD` | fine; `pins.yaml` may be stale: note for `/research refresh <layer>` |
| `ABSENT` | manifest or key not found (layer may not be used): reported, not a finding |
| `SKIPPED` | the comparison **did not run** (no Python, missing `pins.yaml`, not comparable): the freshness/coherence category is `NOT ASSESSED` with the script's reason |

If the script itself cannot run, that is `not run - [reason]`. Never read silence
as agreement.

## 2. Deprecated APIs

Source: `docs/stack-reference/<layer>/deprecated-apis.md`. Format of the files:
Deprecated -> Replacement -> Since -> Source. Procedure, per layer **in use**
(derive from the inventory and `stack`; an unset stack means every layer whose
manifest exists):

1. Read the layer's `deprecated-apis.md`. Absent -> `NOT ASSESSED - no
   deprecated-apis reference for <layer>`.
2. From each row's **Deprecated** cell take the distinctive backticked
   identifiers (function, option, import path, attribute, metric, setting name).
3. Search the code roots (and config files such as `pnpm-workspace.yaml`, compose
   files, `build.gradle*`, collector config) for each identifier with `Grep`;
   exclude `vendor`, `node_modules`, generated and build output.
4. Report each hit: `file:line`, the identifier, the replacement and the
   `Since`/source exactly as the reference states them. A replacement the
   reference marks `NOT SOURCEABLE` is reported as such, not guessed.
5. Rows whose Deprecated cell has no distinctive greppable token (a behaviour
   change, a default) are counted as **not greppable** and listed by row; they are
   not "no hits".
6. Coverage line per layer: `rows N / greppable M / hits K / not greppable L`.

Severity: a deprecated API with a published CVE or security advisory in the
reference is HIGH; removed in a version the pins already require (it will not
compile or behave) is MEDIUM; deprecated but working is LOW. Findings are queued
through `/tech-debt`; the skill does not edit code. If the references are
themselves stale (below), the scan result carries the staleness caveat.

## 3. Stack-reference freshness (> 90 days)

Read each layer's date with `Grep` (no script is run), and take today's date from
`date -u +%F`:

```text
Grep  pattern: "last verified"  (case-insensitive)  glob: docs/stack-reference/*/VERSION.md
Grep  pattern: "last verified"  (case-insensitive)  path: docs/stack-reference/pins.yaml
Bash: date -u +%F
```

For each file take the first `YYYY-MM-DD` after "last verified", subtract it from
today's date and print one line per file: `STALE|FRESH <age> d <date> <path>`.
- `Last verified` older than **90 days** -> `STALE`; the layer's pinned versions
  and every sourced claim from that layer are unconfirmed until
  `/research refresh <layer>` re-verifies them (MEDIUM finding per stale layer in
  use, LOW for layers not in use).
- `NO DATE` or `NOT READ` -> that layer is `NOT ASSESSED - no readable Last
  verified date`. It is **not** fresh.
- `pins.yaml` stale means every tool pin used in Phase 2 is unconfirmed: say so
  beside the scanner versions.
- Show the day arithmetic for each file (date minus date); if today's date cannot be
  read, the category is `not run`.
- A layer's reference older than its pinned version's release date is also stale
  (`research-docs.md`); where a release date is stated in `VERSION.md`, compare
  and report.
