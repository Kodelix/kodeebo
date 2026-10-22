#!/bin/bash

# Claude Code PreToolUse hook: blocks spawning a subagent while the session's
# shell is not at the project root.
# Exit 0 = allow (the normal permission flow still applies), Exit 2 = block.
#
# Why: Claude Code creates .claude/agent-memory/<agent>/ for a memory-enabled
# agent relative to the session's working directory. Spawned from a subfolder,
# it leaves a stray .claude/ there, and anything that reads ".claude/ here means
# a project root" goes wrong from then on. Two Kodeebo sessions did this in two
# days (a skill's references folder, then a research evidence folder; dogfood
# #40, #41). The hooks no longer fall for it, but the stray folder still lands
# in the repository, so the spawn itself is stopped.
#
# Scope: compares the "cwd" field of the hook input with CLAUDE_PROJECT_DIR,
# after resolving both. With either missing it allows (it cannot tell).
#
# Input schema (PreToolUse for Agent/Task):
# { "tool_name": "Agent", "cwd": "/path", "tool_input": { ... } }

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
else
    CWD=$(printf '%s' "$INPUT" | LC_ALL=C grep -oE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
      | LC_ALL=C sed 's/"cwd"[[:space:]]*:[[:space:]]*"//;s/"$//;s/\\\//\//g;s/\\\\/\\/g')
fi
ROOT="${CLAUDE_PROJECT_DIR:-}"
{ [ -n "$CWD" ] && [ -n "$ROOT" ] && [ -d "$CWD" ] && [ -d "$ROOT" ]; } || exit 0

CWD_R=$(cd "$CWD" 2>/dev/null && pwd -P)
ROOT_R=$(cd "$ROOT" 2>/dev/null && pwd -P)
[ -n "$CWD_R" ] && [ -n "$ROOT_R" ] || exit 0
[ "$CWD_R" = "$ROOT_R" ] && exit 0

cat >&2 <<MSG
BLOCKED (agent spawned away from the project root): the shell is in
  $CWD_R
not the project root
  $ROOT_R
A memory-enabled agent spawned here makes Claude Code create .claude/agent-memory/
in this folder, which then misleads the hooks and lands in the repository.
Run \`cd "$ROOT_R"\` first, then spawn the agent again.
MSG
exit 2
