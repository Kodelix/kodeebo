> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PE-FEASIBILITY — Principal Engineer Implementation Feasibility

Agent: `principal-engineer` | Model tier: session (inherit) | Domain: Code-level architecture, standards, review (Tier 2 lead — invoked when a stack lead's feasibility sign-off is needed)

**Trigger**: After the master architecture document is written
(`/create-architecture`), or when a new architectural pattern is proposed.

**Context to pass**:
- Architecture document path (`docs/architecture/architecture.md`)
- Technical requirements baseline summary
- ADR list with statuses
- Stack references for the layers involved (`docs/stack-reference/`, `pins.yaml`)
- Budgets (`docs/architecture/perf-budgets.md`) and team size / estimates available

**Checks**:
1. Each decision can be implemented with the stated stack and language at the pinned versions: list any that would be difficult or impossible, with the stack-reference line.
2. Interface definitions are complete: every context boundary has the ports, DTOs and contract (`contracts/`) that programmers would otherwise have to invent; name the missing ones.
3. No pattern creates avoidable technical debt or contradicts the idioms of the pinned stack (for example thread-per-request assumptions in Go, blocking calls on coroutine dispatchers, state held in a SPA that the contract should own).
4. The performance budgets are reachable with the proposed design: cite the budget, the estimate of what the design costs against it, and the gap between them.
5. Estimates or capacity available (team size, stack leads) are checked against the scope of the architecture; cite the numbers given.
6. For every concern, at least one alternative that would fit is named.

**Prompt**:
> "Review this architecture for implementation feasibility. Flag: (a) any
> decisions that would be difficult or impossible to implement with the stated
> stack and language, (b) any missing interface definitions that programmers
> would need to invent themselves, (c) any patterns that create avoidable
> technical debt or that contradict standard idioms of the pinned stack, (d) any
> budget the design cannot reach, with the gap. Name at least one alternative
> that would fit for each flag. Return FEASIBLE, CONCERNS [list], or INFEASIBLE
> [blockers that make this architecture unimplementable as written]."

**Verdicts**: FEASIBLE / CONCERNS / INFEASIBLE

**NOT ASSESSED when**: the architecture document, the requirements baseline or
the stack reference for a layer the architecture uses cannot be read. A budget
or estimate the skill reports as not yet set is a finding for check 4 or 5,
not a missing input.

**Output**: the standard block, with an alternatives list (flag — alternative that fits).
