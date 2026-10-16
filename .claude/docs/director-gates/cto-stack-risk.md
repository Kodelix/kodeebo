> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-STACK-RISK — Stack Version Risk Review

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: When making architecture decisions that touch APIs, features or
behaviour newer than the model's training data or absent from the stack
reference, or before finalising any stack-specific implementation approach
(`/architecture-decision`, `/dev-story` research step, `/architecture-review`).

**Context to pass**:
- The specific API, library or feature being used, and the layer (Go, Ktor, Vite/React, Astro, Compose, SwiftUI, Postgres, Mongo, Redis/Valkey, OpenTelemetry)
- Pinned version and the model's knowledge cutoff (from `docs/stack-reference/<layer>/VERSION.md` and `docs/stack-reference/pins.yaml`)
- Relevant excerpt from the stack reference's breaking-changes, deprecations or best-practices files, and the research note (`docs/research/<feature>.md`)

**Checks**:
1. The API or feature is present in the pinned version: cite the stack-reference or official-documentation line. Recall from memory is not evidence (`research-protocol.md`).
2. Its signature, behaviour, default or namespace has not changed between the model's cutoff and the pinned version, or the change is documented in the reference.
3. No deprecation or removal applies at the pinned version or the next planned bump; if one does, the replacement is named.
4. No open security advisory (GitHub Security Advisories, OSV, vendor advisory) affects the pinned version of the dependency; an unchecked advisory source is reported as not checked.
5. For the self-hosted bundle, the dependency's licence and image provenance satisfy `.claude/rules/deploy.md` (for example Valkey only, official Mongo image only).
6. Where the reference has no answer, the note says `NOT SOURCEABLE — <what was searched>` rather than filling the gap.

**Prompt**:
> "Review this stack API usage against the version reference. Is this API
> present in the pinned version? Has its signature, behaviour, or namespace
> changed since the model's knowledge cutoff? Are there known deprecations,
> advisories or newer alternatives? Return APPROVE (safe to use as described),
> CONCERNS [verify before implementing], or REJECT [API has changed — provide
> corrected approach]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the stack reference (`VERSION.md`) for the layer is
missing or unreadable, or the pinned version is not stated. Do not judge a
version-qualified claim from memory.

**Output**: the standard block; REJECT must include the corrected approach with its source.
