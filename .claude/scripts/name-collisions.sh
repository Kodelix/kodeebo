#!/bin/bash
# name-collisions.sh — studio skills and agents shadowed by the user's personal ones.
# An observation, never a verdict.
#
# Usage: name-collisions.sh            (from the project root)
# Prints one line per collision:
#   SHADOWED skill /<name> — ~/.claude/skills/<name> runs instead of the studio's
#   SHADOWED agent <name> — ~/.claude/agents/<name>.md is used instead of the studio's
# Prints nothing when there is no collision. Exit status is always 0.
#
# Why: when a project skill or agent and a personal one share a name, Claude
# Code uses the PERSONAL one (verified 2026-10-13: `/code-review` in a product
# ran the user's own review skill, without the studio's eight DoD gates). The
# studio's gates then silently do not run. Plugin skills are namespaced
# (`plugin:skill`) and cannot collide.

cd "$(dirname "$0")/../.." 2>/dev/null || exit 0
USER_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ -d "$USER_DIR/skills" ] && [ -d .claude/skills ]; then
    for d in .claude/skills/*/; do
        name=$(basename "$d")
        [ -f "$d/SKILL.md" ] || continue
        if [ -e "$USER_DIR/skills/$name" ]; then
            echo "SHADOWED skill /$name — ~/.claude/skills/$name runs instead of the studio's"
        fi
    done
fi
if [ -d "$USER_DIR/agents" ] && [ -d .claude/agents ]; then
    for f in .claude/agents/*.md; do
        [ -f "$f" ] || continue
        name=$(basename "$f" .md)
        if [ -e "$USER_DIR/agents/$name.md" ]; then
            echo "SHADOWED agent $name — ~/.claude/agents/$name.md is used instead of the studio's"
        fi
    done
fi
exit 0
