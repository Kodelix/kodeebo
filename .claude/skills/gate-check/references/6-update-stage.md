# /gate-check — Section 6: Update Stage on PASS

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance, write the
new stage to `project.yaml`. **Never create `production/stage.txt`** — readers prefer
`project.stage` and use the mirror only as a fallback. If `production/stage.txt`
already exists (a project created before 2026-10-13), update it in the same
approved write so the two never disagree.

The stage name is exactly one of the `project.stage` enum values — spelled and
cased as listed: `Discovery`, `Product Design`, `Architecture`, `Pre-Production`,
`Production`, `Hardening`, `Release`, `Live`. The gate argument is the lowercase
slug of the stage entered (`product-design` → `Product Design`). Any other
spelling fails enum validation and is dropped by `resolve_config`, so the stage
would silently not advance.

**On CONCERNS, the user may override — explicitly.** Do not offer the stage
write by default. If the user asks to advance anyway, list every concern and
ask: "The gate returned CONCERNS. Accept these risks — [list] — and may I update
`project.stage` in `project.yaml` to '[stage]' (and the existing legacy
`production/stage.txt`, if there is one)?" Only on an explicit yes, add the `### Accepted Risks`
section to the gate report (each concern, accepted by the user, with the date)
and write the stage as below. **A FAIL is never overridden into a stage change, and
neither is NOT ASSESSED** — the blockers must be fixed, or the missing input
produced, and the gate re-run.

### 6.1 Primary write — `project.yaml`

Set `project.stage` to the new stage name in `project.yaml` at the repo root.

- **If a `project:` block already exists** (the shipped template has one with
  `stage:`): Read `project.yaml` first (the Edit tool requires the file to have
  been read in this session), then use the Edit tool to change its `stage:` value.
  Change that one line only; touch nothing else in the file.
- **If `project.yaml` exists but has no `project:` block**: Read `project.yaml`
  first, then use the Edit tool to insert the block immediately after the
  `framework:` block (before `modes:` if present). Insert exactly (replace `<new-stage>`):
  ```yaml
  project:
    stage: <new-stage>
  ```
- **If `project.yaml` does not exist at all**: do **not** create it. The file is
  the studio's configuration store and is written by `/start` and `/setup-stack`;
  a stage-only file created here would resolve every other setting to defaults
  without saying so. Report "project.yaml is missing — stage NOT written. Run
  `/start`," and keep the verdict as given. Do not write `production/stage.txt`
  on its own.

  Do not seed `modes.review_mode` or any other rigor-fronted knob here: an
  explicit value would shadow the `modes.rigor` expansion and pin the setting
  regardless of the product's rigor.

### 6.2 Legacy mirror — `production/stage.txt` (only if it already exists)

Never create `production/stage.txt`. Check whether it exists; only if it does,
write the single-line stage name (no trailing newline) to it in the same approved
write, using the Write tool with the stage name as the whole content, so the
mirror and `project.yaml` never disagree. If it does not exist, skip this step.

### 6.3 Verify the write

After the write, Read `project.yaml` and confirm it shows the new stage. Read
`production/stage.txt` too **only if it exists**, and confirm it shows the same
stage. If they diverge, report the discrepancy to the user and stop — a split
stage indicator corrupts future auto-detection.

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the existing legacy `production/stage.txt`, if there is one)?" — on an accepted CONCERNS override, the explicit yes above is that ask.

### 6.4 Rigor-fit check (advisory — never affects the verdict)

After the stage advance is confirmed, if the new stage is **Production** (or
later) while the resolved `workflow` is `minimal` (the `rigor: minimal`
posture, from the config block), add one line:

> "You're entering [stage] on `rigor: minimal` — most products this size run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

### 6.5 Record the outcome

After the report is written, append one line to the Gate Outcomes record per
`.claude/docs/director-gates.md` "Recording Gate Outcomes": the gate, verdict,
date and the report path, in `production/session-state/active.md`
(appends to `active.md` need no separate approval). A phase gate is recorded
there, not in any ADR or spec header.

---
