# Model Tier Assignment

> ### When a skill's `model:` is used — skills only
>
> A skill's `model:` overrides the session model for the rest of the turn the
> skill runs in, and your next prompt returns to the session model. Whether the
> override happens depends on how the skill starts:
>
> | How the skill starts | Is `model:` used? |
> |---|---|
> | You type `/skill-name` in Manual (`default`) mode | Yes |
> | You type `/skill-name` in auto mode | `sonnet` and `opus`: yes. `haiku`: no — auto mode does not support Haiku, so the session keeps its model |
> | Claude starts the skill itself, through the Skill tool | No — the session model runs it |
>
> Two things follow:
>
> - **An `opus` skill costs more in a Sonnet session.** Typing
>   `/architecture-review`, `/gate-check` or `/review-all-specs` moves that turn
>   to Opus.
> - **A `haiku` skill saves nothing in auto mode** (this project's settings start
>   terminal sessions in Manual, but a user can switch) — or when Claude starts
>   it. Never tell a user a `haiku` tier is saving them money.
>
> Because the override ends at your next prompt, a skill that stops to ask you
> something in chat finishes on the session model after you answer.
>
> **This does NOT apply to agents.** `model:` in `.claude/agents/*.md` is a
> different mechanism, spawned as a separate session rather than executed inline,
> and Claude Code documents it as applied: it is second in the subagent model
> order, after a `model` Claude passes for one invocation. See the agent section
> below.

Skills and agents are assigned tiers by task complexity. A tier is written as
the alias `model:` takes, never as a model ID: Claude Code resolves each alias
to the current model in that family, so this table does not change when a new
model ships.

| Tier | `model:` | When to use |
|------|----------|-------------|
| **Haiku** | `haiku` | Read-only status checks, formatting, simple lookups — no creative judgment needed |
| **Sonnet** | `sonnet` | Implementation, design authoring, analysis of individual systems — default for most work |
| **Opus** | `opus` | Multi-document synthesis, high-stakes phase gate verdicts, cross-system holistic review |
| **Session** | `inherit` | Agents only — runs on whatever model the session runs |

Skills with `model: haiku` (5): `/help`, `/onboard`, `/project-stage-detect`,
`/scope-check`, `/sprint-status`

> `/release-notes` and `/changelog` are `sonnet`, not `haiku`: both produce
> **player-facing** copy and need judgement the cheapest tier is defined as not
> doing. Full reasoning in each skill's own header.
>
> `/settings` was moved off `haiku` for the same reason. It does not only read
> and format — it resolves every leaf with provenance and then compares the
> configured rigor against the project's observable working practice. That is
> synthesis, which is what the Haiku row is defined as excluding.

Skills with `model: opus` (7): `/architecture-review`, `/business`, `/gate-check`,
`/license-design`, `/review-all-specs`, `/studio`, `/threat-model`.

`/pentest` and the `penetration-tester` agent are pinned to `sonnet` on purpose
(verified 2026-10-13): Opus 5's cyber safeguards refuse the `/pentest` skill
text at the API — even against `localhost`, before the skill can apply its own
hard stops — while Sonnet runs it and refuses correctly without a scope. Do not
raise them to `opus` or `inherit` without re-running
`tools/framework-tests/scenarios.py pentest-refuses-without-scope`.

All other skills are Sonnet. When creating a new skill, assign Haiku if it only
reads and formats; assign Opus if it must synthesize 5+ documents with
high-stakes output; otherwise write `model: sonnet` explicitly. Every skill
declares a tier. Whether the tier takes effect depends on how the skill starts
(see the table at the top of this file).

**Agent model tiers.** 60 studio agents (roster: `agent-roster.md`, which is
authoritative). 26 use `model: inherit` and run on the session's model; 34 are
pinned. The four vendored `impeccable-*` agents keep upstream's `inherit`.

- **opus (3):** `product-director`, `cto`, `producer`. Under an Opus session an
  `opus` pin runs on the session's exact model, `[1m]` included, so it never
  gets a smaller window than its parent.
- **inherit (26):** everyone who designs or writes production code where the
  senior bar depends on the strongest model available — `studio-orchestrator`,
  `principal-engineer`, the stack leads (`go-lead`, `ktor-lead`, `web-lead`,
  `android-lead`, `ios-lead`, `kmp-specialist`, `data-lead`), the other leads,
  `api-designer`, `auth-identity-specialist`, `multitenancy-specialist`,
  `integrations-engineer`, `performance-engineer`, `appsec-engineer`,
  `licensing-specialist`, `ux-designer`, `ui-designer`.
- **sonnet (31):** bounded specialist and support work — the stack
  sub-specialists (Go, Kotlin, data stores, React, Astro, Compose, Swift),
  `researcher`, `observability-engineer`, `infra-engineer`, testing roles,
  tooling, `release-manager`, and the content/customer roles.
- **haiku (0):** no agent. Every agent drafts, writes or judges.

When a lead delegates hot-path or security-sensitive code to a `sonnet`
sub-specialist, the lead reviews the result before hand-off — the pin trades
cost for a mandatory review step, not for a lower bar.

Every agent not named above is `inherit`. The `model:` line in the agent's own
file is what runs.

A pin gets that model's context window, whatever the session runs. On the
Anthropic API `sonnet` currently resolves to Sonnet 5, which always has a 1M
window, so a `sonnet` pin is not smaller than a 1M session there; `haiku`
resolves to Haiku 4.5 and its 200K window, and behind an LLM gateway a `sonnet`
pin can be smaller too. A subagent starts from
the brief it is given, not the parent's conversation, so this only matters when
a brief is very large. If a pinned agent does overflow, run every subagent on
the session's model with one line in your `.claude/settings.local.json`
(Claude Code v2.1.257 or later):

```json
{ "env": { "CLAUDE_CODE_SUBAGENT_MODEL_FORCE": "1" } }
```

It applies to **every** pin, the three `opus` directors included: under a
Sonnet session they run on Sonnet too. `CLAUDE_CODE_SUBAGENT_MODEL` alone does
not do it: it applies only to agents that set no model of their own.
