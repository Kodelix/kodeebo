# Skill Porting Brief (Wave 4)

Shared instructions for every subagent porting a skill from
Claude-Code-Game-Studios (source: `/home/kiko/my-game/.claude/skills/<origin>/`,
read-only) into SaaS Studio (`/home/kiko/saas-studio/.claude/skills/<name>/`).

## Read before porting anything

1. `.claude/docs/skills-reference.md` — target name, origin, model, purpose, and the **terminology map** (game → SaaS terms, agents, gate prefixes, stages, story types). Apply it to every line.
2. `CLAUDE.md`, `.claude/docs/coding-standards.md` (eight DoD gates, story types, evidence table), `workflow-modes.md` (spec sections, tiers), `agent-roster.md`, `director-gates.md` (gate IDs that exist), `directory-structure.md` (paths, code roots, test locations), `config-resolution.md`, `automation-modes.md`.
3. `.claude/rules/skill-authoring.md` — obligations every skill must keep.
4. The whole source skill: `SKILL.md`, every file in `references/`, and `CONTRACT.md` if present.

## How to port

- **Keep the machinery:** frontmatter keys, the `!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys …`` bootstrap line and matching `allowed-tools` grant (update the skill name in the grant path), phase structure with `references/` files, verdict words, `AskUserQuestion` gates, review modes (full/lean/solo), automation modes, "not run is reported as not run", collaborative protocol section.
- **Config keys:** `engine` → `stack` in `--keys`; `testing.strict` keys now include contract/security/performance.
- **Replace the domain:** every game concept per the terminology map. Paths: `design/gdd/` → `design/specs/`; `design/game-brief.md` → `design/product-brief.md`; systems index → `design/specs/domain-map.md`; engine reference → `docs/stack-reference/` + `pins.yaml`; code root → `resolve_code_root` (several roots).
- **Agents and gates:** only names in `agent-roster.md` and gate IDs with a file in `.claude/docs/director-gates/`.
- **Templates:** only files that exist in `.claude/docs/templates/` (see the list there).
- **Wire in the SaaS bar where the skill touches it:** research note before implementation (gate 1), threat model for sensitive features, the eight DoD gates and their evidence at review/done time, run-and-observe evidence, tenant isolation, licence rules for `deploy/self-hosted/`, stack reference before any API.
- **Domain-free improvements are welcome; behaviour regressions are not.** Do not drop a safety check the source had.
- **Size:** comparable to the source; split long phases into `references/` the way the source does.
- **CONTRACT.md:** port it if the source has one, applying the same terminology.

## Done means

`bash .claude/scripts/skill-lint.sh <your skills>` from `/home/kiko/saas-studio` reports nothing for your skills (fix every ERROR/WARN), and a grep of your directories for game vocabulary is empty. Write only inside your own skill directories.
