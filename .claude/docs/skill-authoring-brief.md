# Skill Authoring Brief (Wave 5 — new skills)

Shared instructions for every subagent writing a new studio skill. There is no
source to port: the skill is authored from the standards, using the ported
skills as the model for structure and machinery.

## Read before writing anything

1. `.claude/docs/skills-reference.md` — your skill's name, model and purpose (Wave 5 tables).
2. `.claude/rules/skill-authoring.md` — obligations every skill keeps.
3. Two ported skills as structural models: `.claude/skills/story-done/` (phased, `references/`, `CONTRACT.md`) and `.claude/skills/security-audit/` (scanner runs, report). Copy their frontmatter shape, the `resolve_config` bootstrap line + matching `allowed-tools` grant (with your skill's directory name), the "Resolved above — use as-is" line, `AskUserQuestion` gates, review/automation mode handling, and the collaborative protocol section.
4. `CLAUDE.md`, `coding-standards.md` (eight DoD gates), `workflow-modes.md`, `agent-roster.md`, `director-gates.md`, `directory-structure.md`, `automation-modes.md`, `config-resolution.md`.
5. The standards, rules, templates, agents and stack references your skill's purpose touches (named in your batch instructions).

## Rules

- **Frontmatter:** `name` (= directory), `description` (one line, says when to use it), `argument-hint`, `user-invocable: true`, `allowed-tools`, `model` exactly as in `skills-reference.md`. Use `disable-model-invocation: true` for skills with irreversible or always-collaborative effects (incident, pentest, core-release, db-migration apply steps).
- **Bootstrap:** request only the config keys you use (`--keys`). Valid labels: rigor, review_mode, automation, workflow, docs.density, story_granularity, qa.level, team.size, project.stage, automation_always_ask, stack (aliases tenancy, distribution, deploy), testing.strict, accessibility, performance.enforce, system_overrides.
- **Agents and gates:** only names in `agent-roster.md` and gate IDs with a file in `.claude/docs/director-gates/`. Spawn independent agents in parallel (coordination-rules.md).
- **Templates:** use the files in `.claude/docs/templates/`; never invent a parallel format.
- **Scripts:** use the studio scripts where they exist (`migration-lint.sh`, `project-coherence.sh`, `spec-structure-check.sh`, `artifact-check.sh`, `review-scope.sh`); report their real output.
- **Never from memory:** versions, APIs, CLI flags, regulations, market numbers. Stack facts come from `docs/stack-reference/`; anything missing is `NOT SOURCEABLE` and routed to `/research` (or, for business, per `business-research-protocol.md`).
- **Checks that did not run** are reported as not run, never as passed. Verdict words are fixed per skill and listed in the skill.
- **Writes:** ask "May I write…" per the collaboration protocol except the orchestrated exception; the skill names every destination path.
- **Size:** as long as the job needs; split phases over ~120 lines into `references/`. Write `CONTRACT.md` for skills other skills call into.

## Done means

`bash .claude/scripts/skill-lint.sh <your skills>` (from `/home/kiko/saas-studio`) reports nothing for your skills, and a grep of your directories for game vocabulary is empty. Write only inside your own skill directories.
