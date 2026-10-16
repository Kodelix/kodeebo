# /setup-stack — Phase 6: Run the Coherence Check

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 6. Run the Coherence Check

Run it exactly as written, from the project root:

```bash
bash .claude/scripts/project-coherence.sh
```

It compares what the product *declares* (`go.mod`, Gradle version catalogs,
`package.json`, Compose files, `project.yaml`) against the recommended pins in
`docs/stack-reference/pins.yaml`. It emits observations and always exits 0; the
reader decides. **Report its output to the user as it is printed** — every line,
not a paraphrase — and then your own reading of it.

Line statuses:

| Status | Meaning | What to say |
|---|---|---|
| `MATCH` | declared equals the pin | nothing needed |
| `AHEAD` | declared is newer than the pin | fine; the pin may be stale — point at the layer's refresh (Phase 5) |
| `BEHIND` | declared is older than the pin | missing fixes; read the layer's `breaking-changes.md` before upgrading; point to `/dependency-audit` |
| `FLOATING` | a `latest` or bare-major image tag | not reproducible; list the file |
| `LICENCE` | an engine in `deploy/self-hosted/` breaks a licence decision | **blocks the self-hosted bundle**: show the rule from `.claude/rules/deploy.md` |
| `ABSENT` | manifest or key not found | the layer may not be used yet — expected on a new product; unexpected if the layer is configured and code exists |
| `SKIPPED` | the check could not run, with a reason | **a comparison that did not run** — report the reason by name |

**Not a pass:** `ABSENT` and `SKIPPED` lines are comparisons that did not happen.
Say how many of each there were. If the script could not run at all (not found,
no Python — it prints `SKIPPED  all  …`), report
`NOT ASSESSED — the coherence check did not run: <reason>` and do not let the
summary read COMPLETE. An empty output is the same finding, not a clean result.

On a brand-new product with no manifests, expect `ABSENT` for most lines. Say that
once and what will populate them (the first `/dev-story`), rather than listing it as
a problem.

The script reads the profile in `project.yaml`; it does not validate it. Phase 3's
enum validation and this check are different questions, and both must be reported.

---
