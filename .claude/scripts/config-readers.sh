#!/bin/bash
# config-readers.sh — which skills receive a config key in their bootstrap block.
# An observation, never a verdict: it lists, it does not judge.
#
# Usage: config-readers.sh <key>      e.g. config-readers.sh workflow
#        config-readers.sh --all      one line per key: <key> <count>
#
# A skill "receives" a key when its SKILL.md calls `resolve_config --keys ...`
# naming it, or calls bare `resolve_config` (every key). The effects map cites
# this script instead of hand-kept counts, which drifted as skills changed.
# Keys are matched as written in --keys (labels, not dotted paths: `workflow`,
# `review_mode`, `testing.strict`, `performance.enforce`, `stack`, ...).

set -u
cd "$(dirname "$0")/../.." || { echo "config-readers: cannot reach repo root" >&2; exit 1; }

[ "$#" -eq 1 ] || { echo "usage: config-readers.sh <key> | --all" >&2; exit 2; }

# One "<skill> <key|ALL>" line per resolve_config call and key.
pairs() {
    for f in .claude/skills/*/SKILL.md; do
        s=${f#.claude/skills/}; s=${s%/SKILL.md}
        [ "$s" = impeccable ] && continue
        # Only the bootstrap call (a `!`-prefixed shell line). Prose and the
        # allowed-tools pattern also say resolve_config and must not count.
        grep -E '^!`.*yaml-helper\.sh"? resolve_config' "$f" 2>/dev/null \
          | grep -oE 'resolve_config( --keys [a-z_.,]+)?' | while IFS= read -r call; do
            case "$call" in
                *--keys*) printf '%s\n' "${call#*--keys }" | tr ',' '\n' | sed "s/^/$s /" ;;
                *)        printf '%s ALL\n' "$s" ;;
            esac
        done
    done | sort -u
}

if [ "$1" = --all ]; then
    pairs | awk '$2 != "ALL" { print $2 }' | sort | uniq -c | awk '{ printf "%-22s %s\n", $2, $1 }'
    n_all=$(pairs | awk '$2 == "ALL" { print $1 }' | sort -u | wc -l | tr -d ' ')
    echo "(bare resolve_config, all keys): $n_all"
    exit 0
fi

list=$(pairs | awk -v k="$1" '$2 == k || $2 == "ALL" { print $1 }' | sort -u)
n=$(printf '%s\n' "$list" | grep -c .)
echo "$1: $n skill(s)"
[ -n "$list" ] && printf '%s\n' "$list" | sed 's/^/  /'
exit 0
