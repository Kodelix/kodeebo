# /create-epics — EPIC.md and Index Format

> Part of `/create-epics`. Read at Step 5 when writing files.

### `production/epics/[epic-slug]/EPIC.md`

```markdown
# Epic: [Context Name]

> **Layer**: [Foundation / Core / Feature / Presentation]
> **Spec(s)**: design/specs/[filename].md   (or: none — derived from architecture.md §[section])
> **Architecture Module**: [module name]
> **Code roots**: [backend/ · web/ · mobile/ · contracts/ · deploy/]
> **Owner agents**: [backend: go-lead|ktor-lead · web: web-lead · mobile: android-lead|ios-lead|kmp-specialist · data: data-lead · contracts: api-designer]
> **Editions**: [hosted | hosted + self-hosted]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[1 paragraph describing what this epic implements, derived from the spec Overview
and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | Stack Risk |
|-----|-----------------|------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## Spec Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[feature]-001 | [requirement text from registry] | ADR-NNNN ✅ |
| TR-[feature]-002 | [requirement text] | ❌ No ADR |

## Threat Models and Contracts

| Item | Path | Status |
|------|------|--------|
| Threat model — [sensitive feature] | `docs/architecture/threat-models/[feature].md` | present / MISSING — run `/threat-model [feature]` |
| Contract — [service] | `contracts/openapi/[service].yaml` | exists / to be created by the epic's contract story |
| Shared-core module | `[module] @ [core.version]` | consumed / none |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done` with the eight DoD gates met or waived in writing
- All acceptance criteria from `design/specs/[filename].md` are verified, including negative and cross-tenant cases
- All Logic, Integration, Contract and Security stories have passing tests in their layer's test location (`directory-structure.md` "Code roots")
- All UI stories have retained screenshots in `production/qa/evidence/` plus the `/impeccable audit` result for each screen touched
- All Performance stories have a load-test result against `docs/architecture/perf-budgets.md` in `production/qa/evidence/`
- Every sensitive feature in the epic has a threat model and its mitigations are linked to stories
- Each exposed endpoint was called against a running stack and the observation retained (run-and-observe)

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

### Update `production/epics/index.md`

Create or update the master index. An epic that already has a row keeps it:
update that row in place and keep its `Stories` value — never append a second
row, and never reset `Stories` to `Not yet created`:

```markdown
# Epics Index

Last Updated: [date]
Stack: [layers + pinned versions]

| Epic | Layer | Context | Spec | Stories | Status |
|------|-------|---------|------|---------|--------|
| [name] | Foundation | [context] | [file] | Not yet created | Ready |
```
