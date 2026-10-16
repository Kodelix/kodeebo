# /setup-stack — Phase 5: Verify the Stack Reference

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Verify the Stack Reference

**In this file:**

- 5a: Which layers are required
- 5b: Presence and freshness
- 5c: Toolchain probe
- 5d: Refresh through the researcher
- 5e: Refresh mode

The stack reference is what agents read instead of their training data
(`CLAUDE.md`, `.claude/docs/research-protocol.md`). A configured layer without a
fresh reference means agents will fill the gap from memory — the failure this
phase exists to make visible.

### Sourcing rule for everything in this phase

**Never fill a gap from training data. Write the gap down instead.** This skill
does not write versions, dates or support windows into the stack reference. It
reads them, compares them and reports. Where the reference does not cover
something the profile needs, the finding is
`NOT SOURCEABLE — <what> is not covered by <path>`, and it is a successful
outcome of this phase, not a failure to finish.

### 5a: Which layers are required

Derive the set from the profile now in `project.yaml` (after Phase 4 when it ran).
Do not enumerate from this table alone — Glob `docs/stack-reference/*/VERSION.md`
and treat any directory found there that maps to a configured value as required.

| Profile value | Reference directories required |
|---|---|
| any configured profile | `tooling`, `opentelemetry` (cross-cutting: scanners, linters, Definition of Done gate 4) |
| `stack.backend: go` | `go` |
| `stack.backend: ktor` | `ktor`, `kotlin` |
| `stack.backend: go+ktor` | `go`, `ktor`, `kotlin` |
| `stack.web: vite-react` | `vite-react` |
| `stack.site: astro` | `astro` |
| `stack.mobile: compose` | `compose`, `kotlin` |
| `stack.mobile: kmp` | `kmp`, `compose`, `kotlin` |
| `stack.mobile: kmp+swiftui` | `kmp`, `compose`, `swiftui`, `kotlin` |
| `stack.mobile: swiftui` | `swiftui` |
| `stack.data` contains `postgres` / `mongo` / `redis` / `dragonfly` | the directory of the same name |
| `deploy.target: compose-vps` | `docker-compose` |
| `stack.desktop` set and not `none` | `desktop` (cross-cutting: OS support window, packaging and installers, bundled runtime, code signing, auto-update), plus a directory named after the value if one exists |

A configured value with **no directory in the table or on disk** — `deploy.target:
kubernetes`, any `stack.messaging` choice, a `stack.desktop` runtime with no
directory — has no stack reference. Report it as
`NOT SOURCEABLE — no stack reference for <value> under docs/stack-reference/` and
offer a researcher run (5d) to create one. Do not describe that layer's versions
from memory in the meantime.

If no layer is configured at all, there is nothing to verify: report
`NOT ASSESSED — no layers configured`, not "all references fresh".

### 5b: Presence and freshness

Get today's date once (`date +%F`). For each required layer:

1. **Present?** `docs/stack-reference/<layer>/VERSION.md` exists. Also note whether
   `best-practices.md`, `breaking-changes.md` and `deprecated-apis.md` sit beside
   it (missing companions are listed, not blocking).
2. **Last verified.** `Grep -i -m1 "last verified"` in `VERSION.md` and take the
   first `YYYY-MM-DD` on that line (the line may be `Last verified: **2026-10-11**`
   or a table row — both forms occur). Compute the age in days against today.
3. **Classify:**

| State | Condition | Report as |
|---|---|---|
| `FRESH` | date found, age ≤ 90 days | fine |
| `STALE` | date found, age > 90 days | name the layer, the date and the age; offer a researcher refresh (5d) |
| `UNDATED` | file exists, no parseable date | `NOT ASSESSED — last-verified date not found in <path>`; treat as stale |
| `MISSING` | no `VERSION.md` | `NOT SOURCEABLE — no stack reference for <layer>`; offer a researcher run |

A date in the future is `UNDATED` (a typo is not a fresh verification).

4. **Pins.** Confirm `docs/stack-reference/pins.yaml` exists and that each required
   layer has a top-level block in it (the layer name, with the exceptions of
   `docker-compose` and `tooling`, whose keys are named in the file). A missing
   pins file or block: `ABSENT` — the coherence check in Phase 6 cannot compare
   that layer, and says so.

Print one row per layer: `layer | VERSION.md | last verified | age | state`.
Nothing is hidden: the summary counts `FRESH`, `STALE`, `UNDATED`, `MISSING`.

### 5c: Toolchain probe (installed vs pinned)

A reference says what the stack's current versions are; it does not say what the
developer has installed. Probe, read-only, for the layers configured, and compare
with the pin in `pins.yaml` (read it; do not type a version):

| Layer | Probe |
|---|---|
| `go` | `go version` |
| `ktor` / `kotlin` / `compose` / `kmp` | `java -version`, and `gradle --version` or the wrapper's `gradle-wrapper.properties` |
| `vite-react` / `astro` | `node --version`, `pnpm --version` |
| `docker-compose` | `docker compose version` |
| `swiftui` | `xcodebuild -version` (macOS only; elsewhere `not applicable`) |

A probe that fails or whose binary is missing is **`installed version NOT
DETERMINED`**, never "not installed" — a probe that could not run has not
established absence. A mismatch with the pin is reported with both values and left
to the user; `project-coherence.sh` (Phase 6) compares the *manifests*, which is a
separate question from this one.

### 5d: Refresh through the researcher

Offer this for every `STALE`, `UNDATED` and `MISSING` layer, and for any layer
the user names with `refresh`. Ask once for the set:

"May I have the `researcher` agent re-verify `docs/stack-reference/<layers>/` from
primary sources and update those files and `docs/stack-reference/pins.yaml`?"

On approval, spawn the `researcher` agent with this brief (one agent per layer, in
parallel when several):

- Scope: only `docs/stack-reference/<layer>/` and that layer's block in `docs/stack-reference/pins.yaml`.
- Re-fetch every version, date and support claim in `VERSION.md` from the vendor's official page, release feed or registry; never copy a value forward unchecked.
- A claim not re-fetched keeps its old date and is marked unverified; a claim the sources do not state becomes `NOT SOURCEABLE — <what>, not stated at <url>`.
- Update `Last verified` only for what was re-fetched this run; do not restamp a date that was not checked.
- Append new breaking changes and deprecations to `breaking-changes.md` and `deprecated-apis.md` under a heading naming the version span; never truncate older spans.
- Keep `pins.yaml` and `VERSION.md` consistent in the same change.
- Report, per changed row, the URL it was fetched from.

When the agent returns, run `git diff --stat -- docs/stack-reference/` and show it.
Re-run 5b for the refreshed layers. A layer whose researcher run reported it
could not reach sources stays `STALE` in the report — it is not promoted to fresh
because a refresh was attempted.

If the user declines, the layer stays in the summary as `STALE` / `MISSING` with
the age or reason; the skill continues.

### 5e: Refresh mode

`/setup-stack refresh [layer]` runs 5a–5d for the named layer (or every required
layer when none is named), skips Phases 2–4, then runs Phase 6, because a refreshed
pin changes what the coherence check compares against. After the coherence output,
list every `BEHIND` line with the layer it belongs to and point to
`/dependency-audit` for the upgrade plan — this skill does not edit the product's
manifests.

---
