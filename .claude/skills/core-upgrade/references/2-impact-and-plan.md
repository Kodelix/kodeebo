# /core-upgrade — Phases 3–4: Impact, Plan and Decision

> Part of `/core-upgrade`. Read again if the conversation was compacted.

## 1. Build the symbol list

From Phase 2: every changed, re-typed, renamed, removed, newly deprecated and
newly required symbol, config key and behaviour, per module, with its release.

## 2. Scan the product

Resolve the code roots (`bash .claude/hooks/yaml-helper.sh resolve_code_root`).
**An empty result means the scan did not run** — report `impact scan: NOT RUN —
no code roots resolved` and the verdict is capped at `NOT ASSESSED`; never "zero
uses". Include the client roots when the core ships client pieces
(`mobile/shared`, `mobile/android`, `mobile/ios`, `web/`).

Grep each symbol and config key (imports, call sites, config files, deploy
files under `deploy/`, `.env` examples, docs that cite them). Output, one row
per use:

| Module | Symbol / key | Change | Release | Product use (file:line) | Class |
|---|---|---|---|---|---|
| | | removed / changed / deprecated / new-required | | | MUST CHANGE / SHOULD CHANGE / NONE |

A grep miss is not proof of non-use (reflection, generated code, build scripts):
the **compile and the test run in Phase 5 are the second net**, and a compile
error the scan missed is recorded as a scan gap in the report.

*In `check` mode, stop here and print the summary, then the command to upgrade.*

## 3. The plan

`principal-engineer` writes it (spawn via `Agent`; brief with paths: the Phase 2
summary, the Phase 3 table, the product's composition roots), to
`production/core/upgrade-<from>-to-<to>-<date>-plan.md` (named path, bounded
exception). Contents, in order:

1. **Stops.** If a migration note says "upgrade through <tag> first", or data
   migrations are order-sensitive, or the jump crosses a major with breaking
   changes in several releases, the plan has **intermediate stops**, each a
   complete verified step (apply → test → pin), not one big bump.
2. **Code changes** per MUST CHANGE row, at file:line, with the migration the
   CHANGELOG gave. A breaking change whose CHANGELOG gives **no migration
   step** is migrated by the lead from the diff and flagged "migration derived
   by us, not documented by core" (a gap for the core's owners).
3. **Config and secrets** — new, renamed, removed keys; hosted vs bundle
   differences; nothing hardcoded; no secret in files.
4. **Data steps** — hand each to the right skill, never inlined: schema/data →
   `/db-migration` (user-invoked: it has its own apply gate) and `/team-data`;
   an exposed-contract change → `/api-contract` / `/team-api`. The plan orders
   them (expand before the code switch, contract after).
5. **Deprecations** — each `deprecated` row used by the product: fix now (cheap,
   mechanical) or defer. A deferral records the core's removal version/date, an
   owner and a date in `/tech-debt`; a symbol **removed in the target** cannot be
   deferred (it is MUST CHANGE).
6. **Infrastructure** — new required engines checked against the customer-bundle
   licence rules (Valkey, official Mongo image, OTel Collector;
   `.claude/docs/standing-decisions.md` L1–L4, `.claude/rules/deploy.md`); handed to `infra-engineer`
   via `platform-lead` when compose files change.
7. **Tests** — the product's existing suites that must stay green, the new tests
   the changes need (tests first for changed behaviour), and the security
   negatives re-run when a sensitive module (identity, billing, licensing,
   tenancy, audit) changed.
8. **Self-hosted and release** — whether the product's own release needs a
   higher "minimum upgrade-from", a migration note or a changelog entry
   (`release-manager`); customers on older product versions are affected by data
   steps the core bump brings.
9. **Rollback** — revert the change set and the pin together; data steps per
   their migration plan.
10. **DoD gates** the change evidences (the eight gates).

In `review_mode: full`, spawn the track's backend lead (`go-lead` or `ktor-lead`)
and, for a sensitive module, `security-lead` to review the plan in parallel
before the user sees it; lean/solo record `plan review skipped — <mode> mode`.

## 4. Decision and file-set approval

Present per `automation-modes.md`:

```
## Decision: upgrade core <pin> → <target>
Produced: per-module summary, impact table, plan (paths)
It decides: target (full / stop at <intermediate> / defer), deprecation handling, file set
Options: A) upgrade to <target>  B) upgrade to <intermediate> now  C) defer — record why  D) stop
Recommendation: <option> — <why, citing a breaking row or a floor>
```

`AskUserQuestion`. Then, for A or B: list **every file** the lead will create,
change or delete and ask "May the stack lead make these changes?" (multi-file
changes need explicit approval for the full changeset). A `NOT ASSESSED` module
is shown as such in the decision; the user may proceed past it, and the record
says the upgrade proceeded with that module's changes unread. Deferral is a
valid, recorded outcome (verdict `COMPLETE WITH GAPS` with the reason).
