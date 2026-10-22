#!/bin/bash
# Hook: validate-migration.sh
# Event: PostToolUse (Write|Edit)
# Purpose: the moment a SQL migration is written, surface lock/data-loss risks
# and a missing down migration — while the change is still in the author's
# head, not at commit time. Advisory only: observations from
# .claude/scripts/migration-lint.sh, never a block. Rules: .claude/rules/migrations.md.

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
[ -n "$STUDIO_ROOT" ] && cd "$STUDIO_ROOT" 2>/dev/null || exit 0

INPUT=$(cat)
# Cheap exit: most writes are not migrations.
case "$INPUT" in *migration*.sql*|*migration*.SQL*) ;; *) exit 0 ;; esac

if command -v jq >/dev/null 2>&1; then
    FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE=$(printf '%s' "$INPUT" | LC_ALL=C grep -oE '"file_path"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 \
      | LC_ALL=C sed 's/^"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\/\\/g')
fi
[ -n "$FILE" ] || exit 0
case "$FILE" in */migrations/*.sql|migrations/*.sql|*/migration/*.sql|migration/*.sql|*/migrations/*.SQL|*/migration/*.SQL) ;; *) exit 0 ;; esac
[ -f "$FILE" ] || exit 0

OUT=$(bash .claude/scripts/migration-lint.sh "$FILE" 2>/dev/null)
[ -z "$OUT" ] && exit 0

. .claude/hooks/yaml-helper.sh 2>/dev/null
MSG="=== Migration review: $FILE ===
$OUT
Rules: .claude/rules/migrations.md (expand→migrate→contract; self-hosted installs upgrade across versions)."
if command -v hook_warn >/dev/null 2>&1; then
    hook_warn PostToolUse "$MSG"
else
    printf '%s\n' "$MSG" >&2
fi
exit 0
