# SaaS Studio — Product Engineering Agent Architecture

SaaS product development (subscription and one-time licence, hosted and
self-hosted) managed through coordinated Claude Code subagents. Each agent owns
a domain and writes code at the level of a senior engineer in that role.

## Technology Stack

Resolved per product from `project.yaml` (`stack`, `deploy`, `distribution`,
`tenancy`). Set it with `/setup-stack`; never assume it.

- **Backend**: Go or Ktor (Kotlin)
- **Web**: Vite + React SPA (static build, no Node server in production); Astro for the marketing site
- **Mobile**: Jetpack Compose, Kotlin Multiplatform, SwiftUI
- **Data**: PostgreSQL, MongoDB, Redis, Dragonfly
- **Deploy**: Docker Compose on VPS; the same bundle is the self-hosted installer
- **Shared core**: one per backend track (`saas-core-go`, `saas-core-kotlin`) — identity, observability, OTP, notifications, storage, billing, licensing, tenancy, audit
- **Version control**: Git, trunk-based

Pinned versions live in `docs/stack-reference/<layer>/VERSION.md` (sourced,
human-readable) and `docs/stack-reference/pins.yaml` (machine-readable). Read
the relevant layer's `VERSION.md`, `breaking-changes.md` and
`deprecated-apis.md` **before** suggesting any API: the model's training data
lags these stacks. `bash .claude/scripts/project-coherence.sh` compares a
product against the pins.

## Project Structure

@.claude/docs/directory-structure.md

## How to work here: `/studio`

`/studio <goal in plain words>` is the single entry point. It reads
`project.yaml` and `production/session-state/active.md`, classifies the goal
(new product, feature, bug, performance, security, release, incident, core
change) and drives the matching flow end to end, routing to the right agents
and stopping at each approval gate. Every other skill is still callable
directly.

To make a whole session the orchestrator, start it with
`claude --agent studio-orchestrator`. That agent runs the same flow as
`/studio`; it is opt-in because it replaces the default system prompt.

## Configuration

`project.yaml` at the repo root is the config store. Skills resolve it through
`resolve_config` (see `.claude/docs/config-resolution.md`).

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  — in the default `collaborative` automation mode; `modes.automation` relaxes
  this per `.claude/docs/automation-modes.md`, never for its always-ask
  categories. Exactly three writes are exempt: (1) updates to the skill's own
  block in the `active.md` checkpoint; (2) agent memory; (3) a **new** file
  written by a **subagent** at a path the orchestrating skill or
  `studio-orchestrator` named, under `docs/`, `design/`, `business/`,
  `production/` or a test directory. (3) never covers an edit to an existing
  file — spec, doc, source or config — nor the main session running a skill;
  those ask, or not, only as the automation mode says. A folder alone never
  exempts a file
- Agents MUST show drafts or summaries before requesting approval. A draft that
  needs a file (to run checks on it, or because it is too long for the chat)
  goes in `production/session-state/drafts/` — gitignored, created on first
  use, asked for like any new file. Never write outside the repository: `/tmp`,
  `/dev/shm` and home paths are not draft locations (`validate-scratch-paths.sh`
  blocks the common forms; a temp dir is `mktemp -d -p production/session-state/drafts`)
- Spawn agents from the repository root: `cd` back before any `Agent` call
  (`validate-agent-cwd.sh` blocks a spawn from a subfolder, where Claude Code
  would leave a stray `.claude/agent-memory/`)
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

## Engineering Standards

@.claude/docs/coding-standards.md

## Research Before Implementation

No feature is implemented from memory. Before code, the `researcher` agent (or
`/research`) writes `docs/research/<feature>.md` from primary sources: official
docs at the pinned version, RFCs, OWASP, vendor API references. It records the
versions, the options considered, the one chosen and why.

## Context Management

Read `.claude/docs/context-management.md` on demand. Two conventions are
load-bearing:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.**
