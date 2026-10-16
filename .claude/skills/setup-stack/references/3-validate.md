# /setup-stack — Phase 3: Validate the Profile

> Part of `/setup-stack`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Validate the Profile

**In this file:**

- 3a: Enum validation
- 3b: Cross-field checks
- 3c: Licence constraints for customer bundles

Validate everything — pending values and values already in `project.yaml` — before
any approval prompt. Verify mode runs only this phase against the file as it is.

### 3a: Enum validation

Run, from the project root (the helper moves to the project root itself):

```bash
bash .claude/hooks/yaml-helper.sh validate_enum_value <dotted.path> <value>
```

once per pending key. A non-zero return prints the allowed set on stderr; show it
verbatim and do not offer to write that value. For a whole-file check of what is
already on disk:

```bash
bash .claude/hooks/yaml-helper.sh validate_yaml_enum project.yaml
```

Allowed values (the authoritative list is `_yaml_helper_enums` in
`.claude/hooks/yaml-helper.sh`; read it rather than trusting this copy if they differ):

| Key | Allowed |
|---|---|
| `stack.backend` | `go`, `ktor`, `go+ktor` |
| `stack.web` | `vite-react`, `none` |
| `stack.site` | `astro`, `none` |
| `stack.mobile` | `compose`, `kmp`, `kmp+swiftui`, `swiftui`, `none` |
| `deploy.target` | `compose-vps`, `kubernetes` |
| `distribution.model` | `hosted`, `self-hosted`, `hybrid` |
| `tenancy.model` | `shared-schema-rls`, `schema-per-tenant`, `db-per-tenant`, `single-tenant` |
| `core.track` | `go`, `kotlin` |

Not enum-checked by the helper, validated here: each member of `stack.data` must be
one of `postgres`, `mongo`, `redis`, `dragonfly`; `layout.code_roots` entries must be
relative directory names (no leading `/` or `..`) — and a root that does not exist
on disk is reported, not rejected (it may be created by the first story);
`stack.messaging` is free text from `/research` (`nats`, `rabbitmq`, `kafka`,
`none`) and is recorded as given.

If the helper is unavailable (missing file, no Python), report
`NOT ASSESSED — enum validation did not run` and do not write: an unvalidated
write is how a typo becomes a mode every skill silently ignores.

### 3b: Cross-field checks

Report each as a finding with the two values involved. None is auto-corrected.

| Finding | Condition |
|---|---|
| Core track mismatch | `core.track` does not follow `stack.backend` (`go`↔`go`, `ktor`↔`kotlin`). `go+ktor` has no single track: ask |
| Track without a backend | `core.track` set while `stack.backend` is unset |
| Self-hosted without Compose | `distribution.model` is `self-hosted` or `hybrid` and `deploy.target` is not `compose-vps` — the customer bundle is the Compose bundle (`.claude/rules/deploy.md`) |
| Web/mobile with no backend | `stack.web` or `stack.mobile` set, `stack.backend` unset |
| No data store | `stack.backend` set, `stack.data` empty |
| Single-tenant on shared hosting | `tenancy.model: single-tenant` with `distribution.model: hosted` — valid, but ask whether each customer gets its own deployment |
| Mobile track mismatch | `stack.mobile` includes `kmp` and `stack.backend` is `go` — valid; note that the shared Kotlin module and the backend then share no code |
| Code root missing on disk | a `layout.code_roots` entry is not a directory |

### 3c: Licence constraints for customer bundles

When `distribution.model` is `self-hosted` or `hybrid`, the bundle in
`deploy/self-hosted/` is bound by the decisions recorded in `docs/ROADMAP.md`
and `.claude/rules/deploy.md`. Tell the user, once, as advisories (not errors):

- `dragonfly` in `stack.data` is **hosted only** — it must not appear in the customer bundle; the bundle's cache is Valkey, so code stays within the portable command subset.
- `mongo` in the bundle is an `image:` reference to the official image only.
- Observability in the bundle is the OTel Collector only.

If `stack.data` includes `redis` or `dragonfly`, name the cache engine the bundle
will use. Do not state licence terms from memory; cite `docs/stack-reference/redis/VERSION.md`,
`dragonfly/VERSION.md` and `mongo/VERSION.md`, and if the relevant file is missing
write `NOT SOURCEABLE — licence terms not covered by docs/stack-reference/`.

---
