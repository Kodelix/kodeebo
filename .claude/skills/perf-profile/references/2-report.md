# /perf-profile — Budget Creation and Report Template

> Phases 2 and 4 of `SKILL.md`.

## Creating `docs/architecture/perf-budgets.md` when it is missing

Owner: `performance-engineer`. Template:
`.claude/docs/templates/perf-budgets.md`. Defaults: the table in
`.claude/docs/performance-standard.md`.

1. Tell the user the file is missing and that **a surface with no committed
   budget cannot be passed** — it is `NOT ASSESSED — no budget`.
2. Offer: "Create `docs/architecture/perf-budgets.md` from the template, with the
   `performance-standard.md` defaults as proposals?" (`AskUserQuestion`).
3. If yes, fill the template: header `Status: Draft`, `Enforcement` from the
   resolved `performance.enforce`, section 1 "Default" column with the standard's
   values and the "Product budget" column **left for the user** (`[ ]`), sections
   2–5 with the product's hot paths (from `contracts/openapi/*.yaml` and the
   specs' Non-Functional Requirements) and capacity assumptions the user gives
   (tenants now / at 12 months, largest tenant, peak req/s, data growth) — an
   assumption the user does not give is written `Unknown`, not invented.
4. Ask the user to **confirm which defaults are the product's budgets**
   (`AskUserQuestion`: "Use the defaults as the product budgets" / "I'll set my
   own" / "Not now"). Confirmed rows are written into the "Product budget"
   column and the file's `Status` becomes `Active`. Unconfirmed rows stay `[ ]`.
5. **Show the draft and ask "May I write this to
   `docs/architecture/perf-budgets.md`?"** — it is a new file but a path this
   skill chose; wait for the yes.

**Measuring against a Draft or unconfirmed budget:** allowed, but every result
against it is reported as `vs default (unconfirmed)` and counts as `NOT ASSESSED`
for the gate. The defaults are used as thresholds only because the user said so
for this run. Never measure against a template placeholder.

Never weaken a budget to make a result pass. A missed budget needs a fix or a
written waiver in `perf-budgets.md` §7 (surface, budget, actual, reason, approver,
expiry); `performance.enforce: block` is honoured as a blocker.

## Report

Path: `production/qa/perf-profile-[scope]-[date].md`; raw captures under
`production/qa/evidence/perf-profile-[scope]-[date]/` (or the story's evidence
folder when a story ID was given).

```markdown
## Performance Profile: [scope]
Generated: [Date] · Commit: [hash] · Enforcement: [warn | block | off]

### Inputs
| Input | Status |
|---|---|
| perf-budgets.md | FOUND (Active) / FOUND (Draft) / ABSENT |
| Dev stack / seeded data | up — [rows, tenants] / not run: [reason] |
| [each tool] | ran / not installed / invocation not sourced |

### Environment
Hardware/container limits · data volume (rows, tenants) · versions · tool + version · runs (N) and variance

### Budgets vs Measured
| Surface / metric | Budget (p95 unless stated) | Measured (p50 / p95 / p99) | Runs | Status | Evidence |
|---|---|---|---|---|---|
| [GET /v1/...] | [150 ms] | [..] | [3] | [OK / WARNING / OVER / NOT MEASURED / NOT ASSESSED] | [path] |

Status: **OK** within budget on every run · **WARNING** run-to-run variance straddles the budget · **OVER** over budget · **NOT MEASURED** the tool/environment did not run (reason) · **NOT ASSESSED** no committed budget. `block` + OVER = **BLOCKER** (DoD gate 6 fails).

### Hotspots Identified
| # | Location | Issue | Evidence grade | Share / impact | Fix effort |
|---|---|---|---|---|---|

### Optimization Recommendations (priority order)
1. **[Title]** — [description]
   - Location: [file:line]
   - Evidence: [path | STATIC (file:line)]
   - Expected gain: [MEASURED: share/delta | `not quantified — needs a profile`]
   - Risk: [Low/Med/High] · Effort: [S/M/L] · Owner: [lead]
   - Approach: [how]
   - Re-measure: [what proves it]

### Quick Wins (< 1 hour each)
- [...]

### Requires Investigation / NOT MEASURED
- [layer — reason — the one thing that makes it measurable]

### Deferred (waived)
- [surface — waiver in perf-budgets.md §7, approver, expiry]
```

Close the chat summary with: top 3 hotspots, headroom against each budget that is
**committed** (for a surface without one: `no budget — headroom not assessed`),
and the recommended next action.
