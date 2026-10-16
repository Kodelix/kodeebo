# /setup-stack — Phase 4: Write `project.yaml`

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Write `project.yaml`

Skip this phase in verify and refresh modes.

### 4a: Show the changeset

Build the table of every key this run would change: key, current value (or
`unset`), new value, source (`evidence: go.mod` / `user answer`). Include the
cross-field findings from Phase 3 under it. Nothing that did not change appears.

Ask: "May I write these values to `project.yaml`?" — one question for the whole
changeset (multi-key changes need approval for the full set). If any value
overwrites a configured one, say so in the question and show old → new.

Wait for the answer. A skipped, dismissed or empty answer is not an answer: write
nothing, re-ask in plain text, and state what is waiting on it.

### 4b: Write

Read `project.yaml` first. Use the Edit tool, one block at a time, matching the
parent line plus the leaf line so the match is unique. Preserve every comment and
every key this skill does not own.

- Scalars keep their existing quoting: `backend: "go"` or `backend: go`, whichever the file uses; an empty `""` placeholder is replaced, and its trailing comment kept.
- Arrays use the inline form already in the file: `data: [postgres, redis]`, `code_roots: [backend, web, contracts]`.
- A block that is missing (`layout:`, `core:`) is appended at the end of the file, never between blocks.
- If the file is malformed or the structure is unusual (commented-out duplicate keys, ambiguous nesting), stop and ask rather than guess an insertion point.
- If `project.yaml` does not exist, stop: `/start` creates it. Do not create a bare file here.

Write `core.repo`, `core.version` and `core.modules` only when the user supplied
them this run. Never invent a release tag.

### 4c: Read back

```bash
bash .claude/hooks/yaml-helper.sh validate_yaml_enum project.yaml
```

and re-read the file. Every key written must hold exactly the approved value, and
the helper must report no invalid enum. A mismatch is reported to the user before
the phase ends; it is not patched silently. If the validation could not run, say
`NOT ASSESSED — read-back validation did not run`.

Print what was written, and what was left unset by choice:
`Set <key>=<value> in project.yaml.` per key.

---
