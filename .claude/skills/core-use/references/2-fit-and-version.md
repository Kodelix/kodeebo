# /core-use — Phase 2: Module Fit and Version Selection

> Part of `/core-use`. Read again if the conversation was compacted.

## 1. Read the module at the candidate tag

Candidate tag: `--version`, else the highest released tag that Phase 1 accepted.
Read from the core repo **at that tag** (`git show <tag>:<path>` or a checkout of
the tag in a scratch directory outside the product — never check out into the
product, never modify the core clone):

- the module's README / docs: what it does, what it does not do;
- its port interfaces (the files the core's layout names) and the list of
  adapters it ships;
- its config keys, defaults, required infrastructure (databases, caches,
  brokers) and the tenancy and observability contract it states;
- the module's `CHANGELOG` from the first version to the candidate: breaking
  changes, deprecations, migration notes;
- its conformance tests: which adapters pass them.

Any of these not found at the tag is `NOT SOURCEABLE — <item> not found in
<core repo>@<tag>` and is listed under "Not run / not checked". A module with no
CHANGELOG or no conformance tests is not rejected here, but it is reported in
the fit table as a gap — `cto.md` requires both of a core module.

## 2. Fit table

| Check | Evidence (file in the core repo, or product path) | Result |
|---|---|---|
| Covers the need: each requirement the spec/need names maps to a port method or documented behaviour | port file:line | FIT / PARTIAL / NO |
| Track: module exists in the product's track core | tag + module path | yes / no |
| Toolchain floor: the module's declared language/toolchain/framework versions vs the product's `pins.yaml` rows (run `bash .claude/scripts/project-coherence.sh`, show its real output) | module build file vs `pins.yaml` | compatible / BEHIND / unreadable |
| Tenancy: the module is tenant-aware in the way `tenancy.model` needs (tenant taken from the authenticated context, scoping inside the adapter) | module docs, adapter file:line | yes / no / n/a |
| Infrastructure it requires vs distribution: for `distribution.model` `self-hosted` or `hybrid`, every engine the module's adapters need must be allowed in the customer bundle (Valkey not Redis/Dragonfly for cache; official Mongo image only; OTel Collector only — `.claude/docs/standing-decisions.md` L1–L4, `.claude/rules/deploy.md`) | adapter list vs rules | OK / CONFLICT |
| Observability: the module emits spans/metrics/logs per `observability-standard.md` and carries no PII | module docs, adapter file:line | yes / no / not documented |
| Deprecations: any symbol the product would use is deprecated at this tag | CHANGELOG | none / list |
| Conformance: the adapter the product will use is covered by the module's conformance tests | conformance test paths | yes / no / not found |
| Licence of the module and its dependencies is compatible with customer-bundle redistribution | licence files | OK / unknown (`NOT SOURCEABLE` → `cto` decides) |

Gaps: a `PARTIAL` or `NO` row names the missing capability. The choices, each
the user's: adopt anyway and keep a **thin product-local wrapper** with a written
reason; take the part that fits and file the rest to `/core-extract`; stop.
A product-local re-implementation of what the module does is **not** an option
(`coding-standards.md`, "Shared capabilities come from `saas-core`").

## 3. Version proposal

- Propose the highest **released** tag that satisfies the fit table; show the
  alternatives (the tag before it, and `--version` if given) with the reason each
  was not chosen.
- Pre-1.0 caution: whether a minor bump may break is decided by the core's
  deprecation/versioning policy in its `docs/`; if that policy cannot be read,
  say `policy: NOT ASSESSED` and read every CHANGELOG entry between tags
  instead of trusting the version number.
- If `core.version` is already set (another module adopted earlier), the
  candidate **must equal it**, or the request is an upgrade: route to
  `/core-upgrade`.

## 4. Decision

Present, per `automation-modes.md`:

```
## Decision: adopt <module> at <tag>
Produced: fit table (above), CHANGELOG excerpt, project-coherence output
It decides: module, version, how each gap is handled
Options: A) adopt <tag> as proposed  B) adopt <other tag>  C) adopt part + /core-extract the rest  D) stop
Recommendation: <option> — <why, citing a fit-table row>
```

`AskUserQuestion`. A `NO` on "covers the need" with no accepted gap handling →
`BLOCKED`. Record the choice for the adoption record.

## 5. Where the adoption decision is recorded

- `workflow: full`: an ADR via `/architecture-decision` ("Adopt <module> from
  saas-core-<track>"), `Domain: Core`, stamped with the tag; gate `CTO-ADR`
  follows that skill's review-mode rule.
- `workflow: standard`: an ADR when the module is critical (identity, tenancy,
  billing, licensing, data store, messaging — `workflow-modes.md`), else the
  adoption record alone.
- `workflow: minimal`: one line in the decision log of `design/product-brief.md`
  (asked, not assumed) plus the adoption record.

Ask which applies if `workflow` does not settle it; record the choice. This skill holds no
`Skill` grant: where an ADR is called for, tell the user to run `/architecture-decision` (with
the module, tag and fit table as input) and list it under Next steps — never claim it was written.
