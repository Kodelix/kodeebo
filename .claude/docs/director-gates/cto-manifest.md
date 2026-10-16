> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-MANIFEST — Control Manifest Review

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After control-manifest rules are extracted and previewed
(`/create-control-manifest`), before the manifest file is written.

**Context to pass**:
- The Control Manifest Preview (rule counts per context and layer, full extracted rule list)
- The list of ADRs covered, with statuses
- Stack versions (`docs/stack-reference/pins.yaml`)
- Any rules sourced from the standards (`coding-standards.md`, `security-baseline.md`, `observability-standard.md`, `performance-standard.md`, `.claude/rules/`) or the stack reference rather than from an ADR
- `docs/architecture/perf-budgets.md` (when it exists)

**Checks**:
1. Every mandatory pattern from an Accepted ADR is captured and accurately stated: sample the ADRs and cite ADR line against manifest rule.
2. Every forbidden approach is complete and attributed to its source ADR or standard.
3. No rule lacks a source: each is traceable to an ADR, a standard in `.claude/docs/`, a rule in `.claude/rules/`, or a stack-reference file. A rule with no source is invented, not extracted.
4. Performance guardrails match the budgets the ADRs and `perf-budgets.md` set (p95, queries per request, payload size); a number that differs is a finding.
5. Rules are flat must / never statements, testable by a reviewer, and scoped to a context and layer.
6. No rule contradicts another, an Accepted ADR, or a DoD gate in `coding-standards.md`; rules from a Proposed or Superseded ADR are excluded.
7. Rules that bind the self-hosted bundle (cache store, Mongo image, observability) match `.claude/rules/deploy.md`.

**Prompt**:
> "Review this control manifest before it is written. Are all mandatory ADR
> patterns captured and accurately stated? Are the forbidden approaches complete
> and correctly attributed to their source ADR? Were any rules added that lack a
> source ADR or standard — that is, invented rather than extracted? Are the
> performance guardrails consistent with the constraints the ADRs actually set?
> Return APPROVE, CONCERNS [list the specific rules to revise], or REJECT
> [rules that are wrong or unsourced and must be fixed before the manifest is
> written]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the preview, the ADR list or an ADR a rule cites cannot
be read.

**Output**: the standard block, with a table of rules checked (rule — source — result).
