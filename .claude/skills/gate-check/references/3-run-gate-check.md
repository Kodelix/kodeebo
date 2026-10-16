# /gate-check — Section 3: Run the Gate Check

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Run the Gate Check

**In this file:**

- Artifact Checks (deterministic scan, existence is not adequacy, the smoke report)
- Spec and cross-spec checks
- Quality Checks (tests per layer, performance, localization, stack coherence, licence rules)
- Recorded director verdicts
- Cross-Reference Checks

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Product Design → Architecture, pull entries in Pricing, Permissions or Data
Ownership; if checking Architecture → Pre-Production, pull entries in
Architecture, Stack, Tenancy). Carry these as context — recurring conflict
patterns in the target domain warrant increased scrutiny on those specific
checks.

For each item in the target gate:

### Artifact Checks

**Resolve existence and counts deterministically — do not open files to find out
what exists:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [source-phase]
```

Pass the phase being advanced *from* (its steps are the work that must be
complete): `discovery` for the Discovery → Product Design gate,
`product-design` for Product Design → Architecture, `architecture`,
`pre-production`, `production`, `hardening`, `release` for the later gates.

At `workflow: minimal`, also run
`bash .claude/scripts/artifact-check.sh --path minimal`: the brief and stories
live on that path, not on any phase, and its rows are this tier's floor.

It reads the workflow catalog (`workflow-catalog.yaml`) — which encodes each
step's `glob`, `pattern`, `min_count` and `any_of` — and reports per step:

| status | Meaning |
|---|---|
| `PRESENT` | glob matched, `min_count` met, `pattern` found where specified |
| `ABSENT` | nothing matched |
| `SHORT` | matched but fewer than `min_count` (`count=` and `min=` given) |
| `PATTERN_MISS` | files exist but none contains the required marker |
| `NO_CHECK` | the step declares no artifact — **not detectable from disk** |

It emits observations, never a verdict: **you** apply the workflow tier and the
required/optional split from Section 2. An `ABSENT` required artifact is a
blocker at `full` and frequently not one at `minimal`; the script does not know
that and does not decide it.

**If the script did not run** — the catalog is missing, there is no Python
interpreter, or it exits with an error — the deterministic scan did not happen.
Say so in the report by name (`artifact-check.sh: did not run — [reason]`), fall
back to `Glob` / `Bash` against each artifact path in the gate file, and treat
every item whose existence you could not establish that way as MANUAL CHECK
NEEDED. Never let a script that printed nothing stand in for a scan that found
nothing.

**`NO_CHECK` is not `PRESENT`.** The header prints a `NO_CHECK:` count before any
row precisely so this cannot be skimmed past. Those steps were *scanned*, not
*satisfied* — carry each into Section 4 (Collaborative Assessment) and ask, or
mark MANUAL CHECK NEEDED. A gate that reports PASS because most of its checklist
was undetectable is the failure mode this count exists to prevent.

**Existence is not adequacy.** The script cannot tell a real document from a
template skeleton. So: for any artifact the verdict actually turns on, spot-read
it and confirm it has real content — unfilled `[...]` template fields, `TBD`, an
empty section body, or a document still entirely placeholder text is
**present but empty**, which Section 5 turns into NOT ASSESSED. Do not
spot-read artifacts the verdict does not turn on.

> **A smoke report is always an artifact the verdict turns on — spot-reading it
> is mandatory, not discretionary.** At `minimal` it is frequently the *only*
> required artifact at several gates, so the whole gate rests on one file that
> nothing generated and nothing verifies. Check its claims against the repo, and
> raise any that the tree contradicts:
>
> - It reports a passing automated suite → the layer's test location
>   (`.claude/docs/directory-structure.md` "Code roots") must actually contain
>   test files and the project must have a runner. "24 passed, 0 failed" in a
>   repo with no test files for that layer and no runner is a finding, not
>   evidence.
> - It marks a critical journey PASS → the code for that journey must exist in
>   a code root. A PASS on "invite a teammate" with no invitation code is a
>   finding.
> - It carries no date, or predates the newest change to the code roots → say
>   so; a stale smoke report describes a stack that no longer exists. Date the
>   code by the **Dating rule** (`.claude/skills/story-done/`, file `2-read-story.md`):
>   `git log -1 --format=%cI -- <roots>` only for tracked, clean paths;
>   `git status --porcelain -- <roots>` plus file mtime for uncommitted changes
>   (which `git log` cannot see); the report's own date line otherwise. Print the
>   `freshness source:` used. If no source is usable, that comparison did not run
>   — say so, do not skip it silently.
> - It was run against anything other than the local stack and seeded test
>   tenant (`/smoke-check` never touches shared or production environments) →
>   a finding.
>
> Report a contradiction at the same level the artifact was required at: a
> Blocker where the smoke check is required, CONCERNS where it is recommended.
> Existence plus a verdict-line grep would clear a fabricated report.

For code checks, resolve the code roots (`layout.code_roots` in `project.yaml`,
else the conventional `backend/`, `web/`, `site/`, `mobile/*`, `contracts/`
directories that exist — `.claude/docs/directory-structure.md`) and verify
directory structure and file counts per root. **An empty result means the check
did not run — report `NOT ASSESSED — code roots unresolved`, never zero hits.**

**Product Design → Architecture gate — cross-spec review check**:
Use `Glob('design/specs/spec-cross-review-*.md')` to find the `/review-all-specs`
report. If no file matches: at `full` mark the "cross-spec review report exists"
artifact as **FAIL** and surface it prominently ("No `/review-all-specs` report
found in `design/specs/`. Run `/review-all-specs` before advancing to
Architecture."); at `standard` the report is recommended, so mark it
**CONCERNS**, not a blocker; at `minimal` this gate is not applicable (see the
gate file). If a file is found, read it and check the verdict line: a FAIL
verdict means the cross-spec consistency check failed and must be resolved
before advancing. A NOT ASSESSED verdict means that review could not compare
the specs, so it satisfies nothing here: mark the item NOT ASSESSED for this
gate, never passed. A report older than the newest spec it covers is stale —
say so and ask for a re-run.

### Quality Checks

- **Tests.** Run the product's own test commands per layer in scope, taken from
  its scripts, `Makefile`, CI workflow or `docs/stack-reference/<layer>/` —
  **never a command, flag or version written from memory.** A layer with no
  sourced command is `NOT ASSESSED — command not sourced` for that layer, with
  `/test-setup` or `/research` as the fix, never zero failures. **If no runner
  is configured at all, that is `NOT ASSESSED`, not a silent skip** — see the
  trigger in Section 5. A gate that ran no tests found no test failures, which
  is not the same as passing. Tests run against the local stack and seeded test
  tenant only — never a shared, staging or production environment, never a
  command that deletes volumes.
  A test failure's effect on the verdict depends on the `testing.strict` block
  **resolved in Section 1** (`resolve_config` merges `project.local.yaml` over
  `project.yaml`; reading the file directly would drop a local override), per
  test type:
  - **Logic** — unit tests beside the code, gated by `testing.strict.logic`.
  - **Integration** — Testcontainers suites against real PostgreSQL / MongoDB /
    Redis-compatible stores, gated by `testing.strict.integration`.
  - **Contract** — contract tests against `contracts/` from each consumer, gated
    by `testing.strict.contract`.
  - **Security** — negative tests (authz bypass, cross-tenant, injection),
    gated by `testing.strict.security`.
  - **UI** — the retained screenshots and `/impeccable audit` results, gated by
    `testing.strict.ui` (an evidence check, not a test run).
  - **Performance** — load-test results against the budget, gated by
    `testing.strict.performance` and `performance.enforce` (below).
  - **Logic, Integration, Contract and Security are strict at every tier and
    every `qa.level`; `testing.strict.<type>` can only make the *other* types
    stricter** (`.claude/docs/coding-standards.md`). A `false` for one of those
    four is surfaced to the user as ignored, not applied. For the other types:
    take `testing.strict.<type>` from that block; use it only
    if its value is `true` or `false` (case-insensitive). If the key is absent,
    empty, or holds any other value, read `testing.strict` as a plain boolean
    (legacy single-value form); if that too is absent or invalid, apply the
    default from `.claude/docs/coding-standards.md` "Test evidence by story
    type": Logic, Integration, Contract, Security and UI are **strict**
    (`true`); Performance is advisory unless `performance.enforce: block`;
    Config is advisory. Surface any unrecognized value to the user.
  - At a strict (`true`) gate level, failures of that type are **Blockers**
    (verdict FAIL). At an advisory (`false`) level, they are **Concerns**
    (verdict minimum CONCERNS, not FAIL) — list them under Recommendations, not
    Blockers.
- **Spec completeness.** Gather section presence **deterministically** — do not
  read the specs to count headings:

  ```
  Bash: bash .claude/scripts/spec-structure-check.sh
  ```

  It prints a `PRESENT:` / `ABSENT:` pair per feature spec and accepts the
  documented heading aliases. It reports presence only and makes no
  REQUIRED/ADVISORY judgment.

  Then apply each feature's **effective tier** (per-feature resolution in
  Section 2b) to those lists — all 8 sections at `full`; at `standard` the 5
  required sections plus Edge Cases & Failure Modes when the feature calls an
  external provider, moves money, changes entitlements or runs asynchronously
  (`.claude/docs/workflow-modes.md`). A missing *required* section blocks; a
  missing section that is optional at the effective tier is advisory. A section
  reported PRESENT can still fail review if it is an empty heading — spot-read
  any section the verdict actually turns on. If the script did not run, say so
  and spot-read instead.
- **Performance.** Read the budgets from `docs/architecture/perf-budgets.md`
  (p95 latency, queries per request, payload size, web LCP/INP/CLS and bundle
  size, mobile cold start — the defaults live in
  `.claude/docs/performance-standard.md`) and compare against measured data:
  load-test results in `production/qa/evidence/`, `/load-test` and
  `/perf-profile` output. What a breach *means* is set by `performance.enforce`,
  taken from the Section 1 resolved block (it is locally overridable, so do not
  read the file for this one):
  - `warn` (default) — breaches are **CONCERNS**, never Blockers.
  - `block` — breaches are **Blockers** from the Hardening gate onward.
  - `off` — budgets are informational; do not surface breaches in the verdict.

  Only these three values are recognized. Surface anything else to the user and
  fall back to `warn` rather than guessing. **A budget file that is missing, or
  a profile with placeholder numbers, is not a measurement** — it is NOT
  ASSESSED (Section 5), not a pass.
- **Localization.** `Grep` for hardcoded user-facing strings in the **code
  roots** (resolved as above) and check the Arabic/English and RTL evidence
  the gate file names. **If the code roots are unresolved, report
  `NOT ASSESSED — code roots unresolved` rather than zero hits.**
- **Stack coherence** (the gates that name it): run

  ```
  Bash: bash .claude/scripts/project-coherence.sh
  ```

  It compares what the product declares (`go.mod`, Gradle catalogs,
  `package.json`, Compose files, `project.yaml`) against
  `docs/stack-reference/pins.yaml`, and emits **observations, never a verdict**:
  `MATCH`, `AHEAD`, `BEHIND`, `FLOATING`, `LICENCE`, `ABSENT`, `SKIPPED`. You
  apply them:
  - `LICENCE` — an engine in `deploy/self-hosted/` that breaks the licence rules
    (`.claude/rules/deploy.md`) is a **Blocker** at the Hardening → Release
    gate and a **finding at the level the gate file names** earlier; it is never
    waved through as "pins.yaml may be stale".
  - `BEHIND` — missing fixes: **CONCERNS**, naming the layer and the
    `breaking-changes.md` to read first; `AHEAD` is informational (pins may be
    stale — re-verify via `/setup-stack`).
  - `FLOATING` — a `latest` or bare-major image tag is not reproducible:
    **CONCERNS** at Architecture → Pre-Production and Pre-Production →
    Production, a **Blocker** for anything in `deploy/self-hosted/` at
    Hardening → Release.
  - `ABSENT` — the manifest or key was not found; the layer may not be used.
    Not a finding by itself; cross-check against `stack` in the resolved block.
  - `SKIPPED` — **the comparison did not run.** Report the line verbatim as
    `NOT ASSESSED — stack coherence: [reason]` (for example `pins.yaml missing —
    run /setup-stack`). It is never counted as MATCH.
  The script always exits 0 and prints observations; an empty output is itself a
  failure of the run — report it as `project-coherence.sh: produced no output`
  and treat the item as NOT ASSESSED.
- **Licence rules** (Hardening → Release, and wherever a gate file cites them):
  for `distribution.model: self-hosted` or `hybrid`, the customer bundle in
  `deploy/self-hosted/` follows `.claude/rules/deploy.md` "Hosted vs customer
  bundle": cache **Valkey only** (no Redis ≥ 7.4, no Dragonfly); MongoDB only as
  an `image:` reference to the official image (no binary, tarball or image we
  build); observability **OTel Collector only** with exporters disabled by
  default (no Grafana/Loki/Tempo/Mimir); PostgreSQL and Caddy/Traefik allowed;
  telemetry off by default; the bundle signed and the installer verifying the
  signature. `deploy/hosted/` is exempt from these. `Grep` the Compose files for
  `image:` lines and read the `LICENCE` lines from `project-coherence.sh`; the two
  must agree. `distribution.model: hosted` → "not applicable — hosted only"
  stated in the report. **`distribution.model` empty → NOT ASSESSED
  (`/setup-stack`)**; an unset value is never read as "hosted".

### Recorded director verdicts

Several gates ask whether a per-feature or per-story director gate has a
recorded outcome (SL-THREAT-MODEL on a threat model, SL-TENANT-ISOLATION and
PE-DOD on a story, QL-STORY-READY, CTO-ADR on an ADR). **Read the status header
the verdict was recorded in** (`.claude/docs/director-gates.md` "Recording Gate
Outcomes") — do not re-spawn the director for each one. A recorded
`APPROVED`, `CONCERNS (accepted)` or `REVISED` satisfies the item; a recorded
`skipped — Solo mode` / `skipped — Lean mode` satisfies it **only if
`review_mode` at the time was that mode** (the DoD itself was checked
mechanically by `/story-done`, which solo does not waive); a recorded `NOT
ASSESSED` satisfies nothing; a header with **no** recorded line is a
**CONCERNS** finding naming the document, never a pass. Report a count (n of m
recorded) and list the unrecorded ones.

### Cross-Reference Checks

- Compare `design/specs/` documents against implementations in the **code roots**
- Check that every bounded context referenced in the architecture doc has corresponding code
- Check that `tenancy.model` and `distribution.model` in `project.yaml` agree with `docs/architecture/architecture.md` and the files in `deploy/`
- Verify sprint plans reference real story paths under `production/epics/`
- Verify every story's `TR-[feature]-NNN` resolves in `docs/architecture/tr-registry.yaml`

---
