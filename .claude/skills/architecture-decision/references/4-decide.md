# /architecture-decision — Step 4: Guide the Decision Collaboratively

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Guide the decision collaboratively

Before asking anything, derive the skill's best guesses from the context already
gathered (specs read, stack reference loaded, research note, existing ADRs
scanned). Then present a **confirm/adjust** prompt using `AskUserQuestion` — not
open-ended questions.

**Derive assumptions first:**
- **Problem**: Infer from the title + spec/research context what decision needs to be made, and what not deciding costs
- **Alternatives**: Propose at least 2 (ideally 3) concrete options from the stack reference, the research note and the spec requirements. For each, draft **cost** (build and run effort relative to the choice), **risk** (security, tenancy, vendor/licence, maturity at the pinned version), **performance** (against budgets in `docs/architecture/perf-budgets.md`, queries/request, memory) and **operability** (hosted run, self-hosted run, backup/upgrade, on-call burden). "Do nothing" is a legitimate alternative when applicable.
- **Editions**: when `distribution.model` is `hybrid` or `self-hosted`, how each alternative behaves in the customer bundle (licence per `.claude/rules/deploy.md`, offline operation, upgrade path)
- **Dependencies**: Scan existing ADRs for upstream dependencies. **If the scan is
  inconclusive, present `UNKNOWN — scan inconclusive, please confirm`, never
  `None`.** The two are not interchangeable: `None` asserts that nothing upstream
  constrains this decision, and a user confirming a prefilled list cannot tell an
  assertion from a guess. This field is load-bearing — `/architecture-review`
  flags unaccepted dependencies, `/dev-story` reads it, and the acceptance route
  in Phase 0 **refuses to accept an ADR whose dependencies are not themselves
  Accepted**. A dependency list that defaulted to empty makes that check pass
  while examining nothing. `UNKNOWN` must be resolved during the confirm/adjust
  prompt; it is a prompt state, never a value written to the file
- **Spec linkage**: Extract which feature specs and TR-IDs the title directly relates to (or "Foundational")
- **Critical?**: Is this a critical ADR (tenancy, identity/auth, data store, messaging, API style, deployment topology, licensing)? When in doubt, yes
- **Threat model**: Does it touch auth, billing, licensing, upload, webhooks, PII, admin or a new integration? If yes, link or request `/threat-model`
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, spec linkage, criticality and status. Schema or interface design questions (e.g., "Should the outbox be a table or a stream?", "Which key schema?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include them in the assumptions AskUserQuestion widget.

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**Present assumptions with `AskUserQuestion`:**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider (cost / risk / performance / operability each):
  A) [option derived from the research note]
  B) [option derived from the stack reference]
  C) [option from common patterns, or "do nothing"]
Specs / TR-IDs driving this: [list derived from context]
Critical ADR: [yes/no — reason]
Dependencies: [upstream ADRs if any, otherwise "None" — or UNKNOWN to confirm]
Both editions: [hosted / self-hosted effect]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the spec linkage
[D] Add a performance budget or cost constraint
```

Four options is the tool's limit: "something else needs changing first" goes
under its automatic **Other** field.

Do not generate the ADR until the user confirms assumptions or provides corrections.

**After the stack-lead and CTO reviews return** (Step 5.5/5.6), if unresolved
decisions remain, present each one as a separate `AskUserQuestion` with the proposed
options as choices plus a free-text escape:

```
Decision: [specific unresolved point]
[A] [option from the review]
[B] [alternative option]
[C] Different approach — I'll describe it
```

**ADR Dependencies** — derive from existing ADRs, then confirm:
- Does this decision depend on any other ADR not yet Accepted?
- Does it unlock or unblock any other ADR or epic?
- Does it block any specific epic from starting?

Record answers in the **ADR Dependencies** section. Write "None" for each field if no constraints apply.

---
