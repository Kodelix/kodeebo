# /license-design - Phase 1: Scope, Inputs, Core-First

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Arguments

| Argument | Meaning |
|---|---|
| `<product-slug>` | Product the licence model is for; default: this repository's product |
| `--update` | A model exists (`docs/architecture/licence-model.md`); revise it, keep section numbers, show a diff |
| `--review` | override `review_mode` (gates only) |

## 2. Scope: does the product ship a self-hosted edition?

Read `distribution.model` from the resolved `stack` block.

- includes self-hosted (`self-hosted` or `hybrid`): continue.
- `hosted` only: `not applicable - distribution.model is hosted`. Offer to continue
  only if the user says a self-hosted edition is being planned; then record the
  assumption in the model header.
- **unset:** not a skip. Ask (`AskUserQuestion`: hosted only / self-hosted only /
  hybrid). If unanswerable: verdict at best `NOT ASSESSED - distribution unset (set
  it with /setup-stack)`.

## 3. Inputs: FOUND or ABSENT

| Input | Path | Why |
|---|---|---|
| Commercial terms | `design/specs/pricing-model.md` section "Licence Terms for Self-Hosted" | licence types, unit of licensing, update eligibility, grace, renewal. Owned by `pricing-billing-designer`. Missing = every term `NOT DECIDED` |
| Entitlement catalogue | `design/specs/pricing-model.md` (plans, entitlements, quotas), `design/registry/entities.yaml` | the feature keys the licence claims must reuse |
| Product brief and specs | `design/product-brief.md`, `design/specs/*.md` naming licensing, seats, editions | scope |
| Existing model, threat model, ADRs | `docs/architecture/licence-model.md`, `docs/architecture/threat-models/licensing.md`, `docs/architecture/adr-*.md` | `--update` baseline; decisions not to contradict |
| Research note | `docs/research/licensing.md` | library choice (Phase 2) |
| Architecture and deploy | `docs/architecture/architecture.md`, `deploy/self-hosted/`, the installer and update-channel files, release manifest format | where the verifier runs; signed-bundle verification; release date in the manifest |
| Core | `project.yaml` `core.track`, `core.version` (resolved `stack`); the `saas-core-<track>` licensing module docs | core-first check |
| Rules and baseline | `.claude/rules/security-sensitive.md`, `.claude/rules/deploy.md`, `.claude/docs/security-baseline.md`, `observability-standard.md` | non-negotiables |
| Stack reference | `docs/stack-reference/pins.yaml`; `go/best-practices.md` (Testing: `testing/synctest`, `testing/cryptotest.SetGlobalRandom`), `kotlin/best-practices.md` (`runTest`), `docker-compose/best-practices.md`, `tooling/best-practices.md` (gitleaks) | test strategy; **it does not document Ed25519 library APIs** |
| Runbooks | `docs/runbooks/licensing*.md` | key-compromise and support playbooks |

An ABSENT commercial-terms input is not a stop: the terms become questions for
`pricing-billing-designer` in Phase 3 and stay `NOT DECIDED` until answered.

## 4. Core-first check

Licensing is a shared capability (`licence-model.md` header, `integrations.md`
"prefer saas-core modules"). Read the `saas-core-<track>` licensing module
documentation and version if the core is reachable.

1. **Module exists:** the design extends it. The model records the module and
   version, what the product wires (embedded public-key set, entitlement adapter,
   installer hook) and what it adds. Gaps in the module are `/core-extract`
   proposals, not a fork. `/core-use licensing` adopts it.
2. **No module yet** (the cores are built after the studio): the design is written
   as the **specification the core module will implement**; the model header says
   `Core module: none yet - this model is the core module's spec`, and stories are
   written against `saas-core-<track>`, not the product repo.
3. **Core not reachable:** `core-first check - NOT ASSESSED (core not reachable)`;
   ask the user; do not assume absent.
4. A product-specific implementation needs a written reason in the header.

Never edit `saas-core-*` from a product repo.

## 5. Report the scope

"Designing the licence model for [product]; distribution [value]; commercial terms
[decided / N items NOT DECIDED]; core [module@version | none | unreachable]; review
mode [mode]."
