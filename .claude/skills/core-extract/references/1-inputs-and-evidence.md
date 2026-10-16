# /core-extract — Phases 1–2: Inputs, Scope and Reusability Evidence

> Part of `/core-extract`. Read again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<capability description>` | Free text: "OTP delivery with retry", "tenant-scoped rate limiting" |
| `<product path>` | A directory or package in this product that holds the capability (resolved with `resolve_code_root`; an empty result means the scan did not run, said so) |
| `--module <name>` | The proposed module name; the core repo's naming wins on conflict |
| none | Ask: which capability, and where does it live now? |

## 2. Read the capability where it lives

Record each as FOUND or ABSENT:

| Input | Path |
|---|---|
| The product code: ports it already has, adapters, tests, config keys, tables or collections it owns, events it emits | the paths from the argument |
| Feature spec(s) and the domain map entry | `design/specs/<feature>.md`, `design/specs/domain-map.md` (core-vs-product split) |
| Research note(s) that justified the implementation | `docs/research/<feature>.md` |
| Threat model, if any | `docs/architecture/threat-models/<feature>.md` |
| Existing ADRs on this capability | `docs/architecture/adr-*.md` |
| Registry entries it touches (plans, roles, permissions, events) | `design/registry/entities.yaml` |
| Core pin | `project.yaml` → `core.track`, `core.repo`, `core.version`, `core.modules` (unset = the product has not adopted any core; the proposal still targets the track that follows `stack.backend`) |

**Does the core already host it?** If `core.repo` is readable, list its modules
(the core repo's own layout) and its CHANGELOGs. A module that already covers
the need → **stop and route to `/core-use <module>`**; a partial cover → the
proposal is an *extension* of that module (a minor-version addition), and the
module's current port is the baseline. `core.repo` unset or unreadable → the
module list is `NOT ASSESSED`; say so, and the proposal states "existing core
coverage not checked" at the top.

## 3. Strip test: is it product-neutral?

List, with file:line, everything that ties the code to this product. Each item is
either **removed by the design** (becomes configuration or a parameter) or
**makes the capability product-specific**:

- product vocabulary in names, types, error codes, event names;
- plan names, prices, limits, quotas (business values belong in config or a
  catalogue the product supplies — never in core);
- imports of other contexts' types; reads of other contexts' tables;
- hard-wired provider, region, locale or currency;
- tenancy assumptions beyond what `tenancy.model` supports across products;
- behaviour that only makes sense for this product's workflow (that is domain
  logic: it stays).

If the strip test leaves nothing but glue — the capability *is* the product's
domain logic — the verdict is `BLOCKED — product-specific`: keep it in the
product (`domain-architect` confirms the context boundary). Say that plainly; an
extraction that would hollow out a context is refused, not renegotiated.

## 4. Reusability evidence

The extraction rule (the user's brief; `cto.md`'s bar for the core): a capability
enters the core only when **two or more products need it** or it is **in a
core-module category** (identity, observability, otp, notify, storage, billing,
licensing, tenancy, audit, ratelimit — and any category the core repo's own
module list adds), and it has a port, conformance tests and a deprecation policy.

Build the evidence table. A row counts only if its artifact was opened in this
session:

| # | Product / category | Artifact opened (path or repo, file:line) | What it shows | Differences from this product's version |
|---|---|---|---|---|
| 1 | this product | the code from section 2 | implemented | - |
| 2 | second product, or the category | the second product's code or spec, a path readable in this session; or the core repo's module list naming the category | needs / implements the same capability | the delta the port must absorb |

- A second product's evidence is a **file you read** — code, a spec, an ADR, a
  brief — in a repo you can reach (the user names the path; never search the
  disk for sibling repos). "Product B will need this too" with no artifact is
  recorded under **Claimed (unevidenced)** and does not count.
- The **category** route needs the capability to fall within a listed category
  *and* the core repo's module list or this studio's category list to name it.
  It does not need a second product, but the port must still be designed for more
  than this product (section 3's strip test).
- Count products, not teams: two services of the same product are one product.

**Evidence verdict:**

| Verdict | When | Next |
|---|---|---|
| `EVIDENCED` | two or more products, each with an opened artifact | continue |
| `CATEGORY` | category match; one product (or none beyond this one) | continue; the proposal records "category-based; second consumer pending" and the ADR lists it as a consequence |
| `NOT EVIDENCED` | neither; claims only | `BLOCKED`. Recommended: keep it in the product, record the candidate in the decision log (or `docs/architecture/risk-register.md` when the product keeps one), and re-run when a second product exists |
| `NOT ASSESSED` | the second product's repo or the core's module list could not be read | name what is missing and who can supply it; do not proceed as if evidenced |

**The exception — the only way past `NOT EVIDENCED`.** The user may override with
a stated reason (for example, a second product is committed and funded). It is
recorded in `evidence.md` with the user's words, the risk (a core module with one
consumer is a core module nobody has proven general), the owner and a review date,
and **repeated as a Consequence in the ADR**. `cto` is consulted for a
recommendation (spawn `cto` via `Agent` at `review_mode: full`; lean/solo record
`cto boundary consult skipped — <mode> mode`). The model never grants the
exception itself and never offers it as the default.

## 5. Write the evidence file

Present the strip-test list, the evidence table and the verdict. Ask: "May I
write the evidence to `production/core/proposals/<module>/evidence.md`?" Write
only after approval. Then the Phase 2 decision (`AskUserQuestion`): proceed ·
proceed under an exception (with the reason) · keep it in the product · stop.
