# /create-architecture — Phase 6: ADR Audit and Traceability Check

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: ADR Audit + Traceability Check

Review all existing ADRs from Phase 0c against both the architecture built in
Phases 1-5 AND the Technical Requirements Baseline from Phase 0b.

### ADR Quality Check

For each ADR:
- [ ] Does it have a Stack Compatibility section?
- [ ] Are the pinned versions recorded and do they match `pins.yaml`?
- [ ] Are post-cutoff APIs flagged?
- [ ] Does it have a "Spec Requirements Addressed" section?
- [ ] Does it state its effect on both editions (hosted and self-hosted), and does it respect the licence rules for `deploy/self-hosted/`?
- [ ] Does it conflict with the context, data-store, tenancy or topology decisions made in this session?
- [ ] Is it still valid for the pinned stack versions (not touching an API in `deprecated-apis.md`)?
- [ ] Is its status `Accepted`? A `Proposed` ADR is a decision nobody has made.

| ADR | Stack Compat | Versions | Spec Linkage | Editions/Licence | Conflicts | Status | Valid |
|-----|--------------|----------|--------------|------------------|-----------|--------|-------|
| ADR-0001: [title] | yes/no | yes/no | yes/no | ok/violation | None/[conflict] | Accepted/Proposed | yes/needs review |

### Traceability Coverage Check

Map every requirement from the Technical Requirements Baseline to existing ADRs.
For each requirement, check if any ADR's "Spec Requirements Addressed" section
or decision text covers it. **Only an `Accepted` ADR is coverage** — mark a
requirement covered solely by a `Proposed` ADR as `Covered (Proposed)`, never as
covered:

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-billing-001 | Subscription state machine | ADR-0003 | Covered |
| TR-billing-002 | Dunning schedule | ADR-0004 (Proposed) | Covered (Proposed) |
| TR-reports-002 | Async 100k-row export | — | GAP |

Count: X covered, Y covered (Proposed), Z gaps. For each gap, it becomes a
**Required New ADR**. At `minimal` the "ADR" is the decision-log entry in the
brief; at `standard` only critical ADRs (tenancy, identity/auth, data store,
messaging, API style, deployment topology, licensing) are required, and a
non-critical gap is listed, not blocking.

### Required New ADRs

List all decisions made during this architecture session (Phases 1-5) that do
not yet have a corresponding ADR, PLUS all uncovered Technical Requirements.
Group by layer — Foundation first:

**Foundation Layer (must create before any coding):**
- `/architecture-decision [title]` → covers: TR-[id], TR-[id]

**Core Layer:**
- `/architecture-decision [title]` → covers: TR-[id]

If no ADRs exist yet, say so as a count of zero, not as a clean audit.

---
