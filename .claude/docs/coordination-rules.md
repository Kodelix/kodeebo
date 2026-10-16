# Agent Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `product-director` for product
   conflicts or `cto` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

## Single decider per decision

Where several agents touch one decision, exactly one decides; the rest
recommend, consult or contribute.

| Decision | Decides | Recommends / consulted / contributes |
|---|---|---|
| Tenancy model (`tenancy.model`, per-tier deviation) | `cto`, via ADR | `multitenancy-specialist` recommends; `data-lead`, `domain-architect` consulted |
| Bug severity S1–S4 | `qa-lead` | `debugger` proposes at diagnosis; `sre-lead` for production impact |
| Incident severity SEV1–SEV4 | `sre-lead` (incident commander) | `qa-lead`, `debugger` inform |
| Restore drill (schedule, run, evidence) | `sre-lead` owns | `data-lead`, `postgres-specialist`, `infra-engineer` contribute |
| Accessibility waiver (WCAG 2.2 AA, `accessibility.target: wcag-aa`) | the user, recorded | `accessibility-specialist` assesses; `design-director` recommends |
| Prices, plans offered | the user | `pricing-strategist` recommends price points; `pricing-billing-designer` models plans/entitlements |

**Severity map.** Bug severity S1–S4 maps to incident severity SEV1–SEV4 one to
one when the bug is live in production: S1=SEV1, S2=SEV2, S3=SEV3, S4=SEV4
(definitions: `qa-lead.md` for S1–S4, `sre-lead.md` for SEV1–SEV4). `qa-lead`
rates a bug before release and `sre-lead` rates a production incident; neither
re-rates the other's ladder, and where both apply the higher severity is used
until the deciders agree. A bug found before release keeps S1–S4 only; an
incident always gets a SEV.

## Shared core absent

The cores (`saas-core-go`, `saas-core-kotlin`) may not exist yet for a product,
or may lack a module. When the product's `core.track` core is missing or lacks
the module (`project.yaml` `core.version` unset counts as missing):

1. Implement a **product-local adapter behind the same port interface** the core
   module will expose.
2. Record it in an **ADR** (what, why local, the trigger for extraction).
3. Schedule its extraction into the core with **`/core-extract`**.

Never "block until the core exists", and never ship a divergent interface — the
adapter must be liftable into the core without changing its callers.

## Model Tier Assignment

Read `.claude/docs/model-tiers.md` on demand. It carries the tier table, the
per-skill assignments and the authoring rule.

**Key point:** whether a skill's `model:` is used
depends on how the skill starts. Typed as `/skill-name`: yes, except a `haiku`
pin in auto mode. Started by Claude through the Skill tool: no. Never tell a
user a `haiku` skill saves money; an `opus` skill typed in a Sonnet session
costs more. The agent-side `model:` is a different mechanism, and is applied.

## Subagents vs Agent Teams

This project uses two distinct multi-agent patterns:

### Delegation lists are intended, advisory in subagents

Each agent's `Agent(type, ...)` list in `agent-roster.md` is the **intended
delegation graph**. Claude Code enforces the parenthesised type allowlist only
for an agent running as the main thread (`claude --agent <name>`). In a
subagent, listing `Agent` lets it spawn subagents while the nesting depth is
within `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (default 3; `settings.json` sets
`"3"`), and the type list in parentheses is ignored. So the lists are advisory
when running as a subagent — **agents must follow them anyway**, and an agent
without `Agent` in its tools never spawns.

### Subagents (current, always active)
Spawned via the `Agent` tool within a single Claude Code session (renamed from
`Task` in Claude Code 2.1.63; `Task` still works as an alias). Used by all
`team-*` skills and orchestration skills. Subagents share the session's
permission context, run sequentially or in parallel within the session, and
return results to the parent.

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both `Agent` calls simultaneously
rather than waiting. Example: `/review-all-specs` **Phase 2** (consistency) and
**Phase 3** (design theory) are independent — spawn both at the same time.
Phase 1 loads the specs and both depend on it, so it is the one phase here that
must NOT be parallelised.

### Agent Teams (experimental — opt-in)
Multiple independent Claude Code *sessions* coordinated via a shared task list.
Opt-in only — read `.claude/docs/agent-teams.md` on demand before proposing one.

## Parallel Task Protocol

When an orchestration skill spawns multiple independent agents:

1. Issue all independent `Agent` calls before waiting for any result
2. Collect all results before proceeding to dependent phases
3. If any agent is BLOCKED, surface it immediately — do not silently skip
4. Always produce a partial report if some agents complete and others block
