#!/bin/bash

# Claude Code PreToolUse hook: blocks Bash commands that write scratch files
# outside the repository (/tmp, /var/tmp, /dev/shm, or mktemp with no -p).
# Exit 0 = allow (the normal permission flow still applies), Exit 2 = block.
#
# Why: the studio rule is that sessions and researchers never write outside the
# repository (drafts go in production/session-state/drafts/, caches in
# production/session-state/cache/<slug>/, both gitignored). Two Kodeebo
# sessions broke it in one week (/tmp, /dev/shm) and reported it themselves;
# a written rule with nothing enforcing it was not enough (dogfood #35).
#
# Scope, stated so a miss is not mistaken for a pass: this reads the command
# string only. It catches shell redirection, tee, common file-writing tools
# given one of those directories, mktemp without an explicit -p/--tmpdir, and
# TMPDIR set to one of them. It does not see writes made inside an interpreter
# (python -c "open('/tmp/x','w')") or by a program that picks /tmp itself.
# Here-doc bodies fed to cat/tee (a script being saved, not run) and bodies
# sent over ssh (they run on another machine) are not inspected. Container-side
# paths (-v host:/tmp, --tmpfs /tmp) are not host writes and are allowed.
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "echo x > /tmp/a" } }

INPUT=$(cat)

# Fast exit: most commands mention none of these.
case "$INPUT" in
  *'"tool_input"'*/tmp*|*'"tool_input"'*/dev/shm*|*'"tool_input"'*mktemp*|*'"tool_input"'*TMPDIR*) ;;
  *) exit 0 ;;
esac

if command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
    # Same fallback as validate-push.sh: string body is (\\.|[^"\\])*, then the
    # JSON escapes are decoded once (\\ first, through a placeholder).
    COMMAND=$(printf '%s' "$INPUT" | LC_ALL=C grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 | LC_ALL=C sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    COMMAND=$(printf '%s\n' "$COMMAND" \
      | LC_ALL=C awk '{ gsub(/\\\\/, "\002"); gsub(/\\r/, ""); gsub(/\\t/, "\t"); gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
      | tr '\002' '\\')
fi
[ -z "$COMMAND" ] && exit 0

# Drop here-doc bodies that are data (saved with cat/tee, or sent over ssh to
# run elsewhere). Bodies fed to a local interpreter stay: they run here.
SCAN=$(printf '%s\n' "$COMMAND" | LC_ALL=C awk '
    d != "" { t = $0; sub(/\r$/, "", t); sub(/^\t+/, "", t); if (t == d) d = ""; next }
    { print }
    match($0, /<<-?[ \t]*("[^"]*"|'"'"'[^'"'"']*'"'"'|\\?[A-Za-z_][A-Za-z0-9_]*)/) && substr($0, RSTART - 1, 1) != "<" {
        t = substr($0, RSTART, RLENGTH); sub(/^<<-?[ \t]*/, "", t); gsub(/["'"'"'\\]/, "", t)
        local_run = ($0 ~ /(^|[^A-Za-z0-9_.-])(bash|sh|zsh|dash|ksh|python[0-9.]*|node|perl|ruby|php|eval|source)([ \t]|$)/)
        if ($0 ~ /(^|[^A-Za-z0-9_.-])ssh([ \t]|$)/) local_run = 0
        if (!local_run) d = t
    }')

DIRS='(tmp|var/tmp|dev/shm)'
END_='(/|[[:space:]"'"'"']|$)'
reason=""
if printf '%s\n' "$SCAN" | LC_ALL=C grep -qE "(^|[^0-9A-Za-z<])[0-9&]?>>?[[:space:]]*[\"']?/${DIRS}${END_}"; then
    reason="redirects output into a system temp directory"
elif printf '%s\n' "$SCAN" | LC_ALL=C grep -qE "(^|[[:space:];|&(])tee([[:space:]]+-[A-Za-z-]+)*[[:space:]]+[\"']?/${DIRS}${END_}"; then
    reason="tees output into a system temp directory"
elif printf '%s\n' "$SCAN" | LC_ALL=C grep -qE "(^|[[:space:];|&(])(cp|mv|install|touch|mkdir|ln|dd|rsync|tar|unzip|curl|wget|git)[[:space:]][^;&|]*[[:space:]=][\"']?/${DIRS}${END_}"; then
    reason="writes a file into a system temp directory"
elif printf '%s\n' "$SCAN" | LC_ALL=C grep -qE "(^|[[:space:];]|export[[:space:]]+)TMPDIR=[\"']?/${DIRS}${END_}"; then
    reason="points TMPDIR at a system temp directory"
else
    # Each mktemp call needs an explicit -p DIR or --tmpdir=DIR outside the
    # system temp directories; without one it uses $TMPDIR or /tmp.
    bad_mktemp=$(printf '%s\n' "$SCAN" | LC_ALL=C grep -oE "(^|[[:space:];|&(]|\\\$\()mktemp([[:space:]][^;&|)]*)?" \
      | LC_ALL=C awk -v dirs="^[\"']?/${DIRS}" '{
            s = $0; ok = 0
            if (match(s, /(^|[ \t])-p[ \t]+[^ \t]+/)) { a = substr(s, RSTART, RLENGTH); sub(/^[ \t]*-p[ \t]+/, "", a); if (a !~ dirs) ok = 1 }
            if (match(s, /--tmpdir=[^ \t]+/)) { a = substr(s, RSTART + 9, RLENGTH - 9); if (a !~ dirs) ok = 1 }
            if (!ok) { print "bad"; exit }
        }')
    [ -n "$bad_mktemp" ] && reason="calls mktemp without -p <dir inside the repository> (it would use /tmp)"
fi

[ -z "$reason" ] && exit 0

cat >&2 <<MSG
BLOCKED (scratch outside the repository): this command ${reason}.
Studio rule: never write outside the repository. Use the gitignored folders instead:
  drafts and check files: production/session-state/drafts/
  tool caches and downloads: production/session-state/cache/<slug>/
  a temp dir: mktemp -d -p production/session-state/drafts
Reading with ls, cat or grep is allowed; container-side paths (-v host:/tmp, --tmpfs /tmp) are allowed.
If this write must happen outside the repository, ask the user first.
MSG
exit 2
