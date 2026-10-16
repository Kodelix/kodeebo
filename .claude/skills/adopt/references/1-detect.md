# /adopt — Phase 1: Detect Project State

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Detect Project State

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

Then read silently before presenting anything else.

### Existence check
- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — if either is present, use that value (authoritative phase)
- `design/product-brief.md` — brief exists? (a template with unfilled placeholders counts as absent)
- `design/specs/domain-map.md` — domain map exists?
- Count feature spec files: `design/specs/*.md` (excluding `domain-map.md`)
- Count ADR files: `docs/architecture/adr-*.md`
- Count story files: `production/epics/**/*.md` (excluding EPIC.md)
- `project.yaml` — `stack.*`, `deploy.target`, `distribution.model`, `tenancy.model`, `core.track` configured? (an empty string is not configured)
- `docs/stack-reference/` — a `VERSION.md` for each configured layer?
- Code roots: `layout.code_roots` from `project.yaml`, else the conventional `backend/`, `web/`, `site/`, `mobile/`, `contracts/` that exist (the same resolution as `resolve_code_root` in `.claude/hooks/yaml-helper.sh`). Count source files per root. **If none resolves, say so** — a codebase kept under `app/` or `services/` is invisible to the conventional scan, and "no code roots" must not be read as "no code". Ask the user where the code lives; `/setup-stack` records it in `layout.code_roots`.
- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

### Infer phase (if no project.stage / stage.txt)
Use the same heuristic as `/project-stage-detect`:
- 10+ source files across the code roots → Production
- Stories in `production/epics/` → Pre-Production
- ADRs exist → Architecture
- `domain-map.md` exists → Product Design
- `product-brief.md` exists → Discovery
- Nothing → Fresh

If the code roots hold source files but no studio artifacts exist, this is still
a brownfield project: the inferred phase is `Production` and the plan will be
mostly creating the missing artifacts around the code.

A project is **Fresh** only when there are no studio artifacts **and** no source
files **and** a code-root scan that actually ran. If the code-root scan could not
run (unresolved roots), it is not Fresh — it is `NOT ASSESSED`; ask where the
code lives before concluding anything.

If the project is Fresh, use `AskUserQuestion`:
- "This looks like a fresh project — no existing artifacts or code found. `/adopt` is for
  projects with work to migrate. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

Then stop — do not proceed with the audit regardless of which option the user picks
(each option leads to a different skill or manual investigation).

Report: "Detected phase: [phase]. Found: [N] specs, [M] ADRs, [P] stories, [S] source files in [roots]."

---
