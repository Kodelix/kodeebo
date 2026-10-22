#!/usr/bin/env bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/settings.json -> cwd (a project root not yet configured;
#      a bare .claude/ is not enough: Claude Code creates .claude/agent-memory/
#      wherever a memory agent is spawned, dogfood #40/#41)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
# A cwd inside any .claude/ tree is never a project root, and a cwd counts only
# with project.yaml or .claude/settings.json: a stray .claude/agent-memory/ left
# where an agent was spawned (dogfood #40, #41) must not make hooks log there.
if case "$PWD/" in */.claude/*) false ;; *) true ;; esac && { [ -f "project.yaml" ] || [ -f ".claude/settings.json" ]; }; then
  STUDIO_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  STUDIO_ROOT="$CLAUDE_PROJECT_DIR"
else
  STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$STUDIO_ROOT" ] && cd "$STUDIO_ROOT" 2>/dev/null || true

# post-compact.sh — fires after conversation compaction
#
# THIS OUTPUT DOES NOT REACH CLAUDE. Claude Code writes PostCompact stdout to
# the debug log and discards its systemMessage (hooks documentation). Recovery
# after a compaction is session-start.sh, which SessionStart runs again with
# source `compact`; the reminder below is for the debug log only.

# features.session_state: off => this hook is a no-op. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

ACTIVE="production/session-state/active.md"

echo "=== Context Restored After Compaction ==="

if [ -f "$ACTIVE" ]; then
  # tr: BSD wc (macOS) right-aligns its count ("(      35 lines)").
  SIZE=$(wc -l < "$ACTIVE" 2>/dev/null | tr -d ' ')
  echo "Session state file exists: $ACTIVE (${SIZE:-?} lines)"
  echo "IMPORTANT: Read this file now to restore your working context."
  echo "It contains: current task, decisions made, files in progress, open questions."
else
  echo "No session state file found at $ACTIVE"
  echo "If you were mid-task, check production/session-logs/ for the last session audit."
fi

echo "========================================="
