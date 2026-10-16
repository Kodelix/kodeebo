> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-ADR — Architecture Decision Review

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After an individual ADR is authored (`/architecture-decision`), before
it is marked Accepted. Not required at `workflow: minimal` (decisions go in the
brief's decision log); at `standard` required for critical ADRs only
(`workflow-modes.md`).

**Context to pass**:
- ADR file path (`docs/architecture/adr-*.md`)
- Stack versions for the layers the ADR touches (`docs/stack-reference/<layer>/VERSION.md`, `docs/stack-reference/pins.yaml`) and any stack-risk notes
- Related ADRs (if any) with statuses
- The research note the decision rests on (`docs/research/<feature>.md`)
- Spec requirements (TR-IDs) the ADR claims to cover

**Checks**:
1. The ADR has a clear problem statement and a rationale tied to a stated driver (requirement, budget, risk) — cite the lines.
2. At least two rejected alternatives are recorded, each with a reason that is specific to this product, not generic.
3. Consequences acknowledge the trade-offs honestly: what becomes harder, what it costs, and what must be revisited and when.
4. Stack versions are stamped and match `pins.yaml`; any API or behaviour past the stack reference is flagged (CTO-STACK-RISK when it is a new risk).
5. The ADR states its effect on both editions when `distribution.model` is `hybrid` or `self-hosted` (for example licence constraints in `.claude/rules/deploy.md`).
6. Security, tenancy, data-retention, observability and performance consequences are each addressed or marked not applicable with a reason; a foundation decision links the threat model.
7. The ADR links the spec requirements (TR-IDs) it covers.
8. The ADR states whether it is a critical ADR (`workflow-modes.md`: tenancy, identity/auth, data store, messaging, API style, deployment topology, licensing).
9. The ADR does not conflict with an Accepted ADR, or names the one it supersedes.
10. The reviewer is not the author: if `cto` authored the ADR, a recorded second review by `principal-engineer` exists.

**Prompt**:
> "Review this Architecture Decision Record. Does it have a clear problem
> statement and rationale? Are the rejected alternatives genuinely considered?
> Does the Consequences section acknowledge the trade-offs honestly? Are the
> stack versions stamped? Are risks past the stack reference flagged? Does it
> link to the spec requirements it covers? Return APPROVE, CONCERNS [specific
> gaps], or REJECT [the decision is underspecified or makes unsound technical
> assumptions]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the ADR file cannot be read, or the stack reference for a
layer the ADR depends on is not available (say which layer; the reference being
absent for a layer the skill reports as not configured is a finding).

**Output**: the standard block; the agent's ADR-review template adds `Critical ADR: yes | no (reason)` and a "Required before approval" list — include both.
