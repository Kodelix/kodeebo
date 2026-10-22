#!/bin/bash

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

# Claude Code PreToolUse hook: Validates git push commands
# Warns on pushes to protected branches -- as hook JSON on stdout, the only
# channel the user or Claude sees on exit 0.
# Exit 0 = allow (the normal permission flow still applies), Exit 2 = block
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git push origin main" } }

INPUT=$(cat)

# Most Bash and PowerShell calls do not mention git at all. Leave before any
# parsing: this hook runs on every one of them, and the parse is most of its
# cost (the early exit is the shell start-up alone).
# Tested only after the "tool_input" key: matching the whole payload also
# tests cwd and transcript_path, so a project path containing "GitHub" or
# "digital" never took this exit and paid the full parse on every call.
case "$INPUT" in *'"tool_input"'*[Gg][Ii][Tt]*) ;; *) exit 0 ;; esac

# Parse command -- use jq if available, fall back to grep. The fallback's string
# body is (\\.|[^"\\])* so an escaped quote does not end it early.
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    # LC_ALL=C: in a UTF-8 locale an emoji in the command makes this grep match
    # nothing, and an empty COMMAND skips the check below.
    COMMAND=$(echo "$INPUT" | LC_ALL=C grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 | LC_ALL=C sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    # Decode the JSON escapes once, here, and never jq's output -- \\ first,
    # through a placeholder. validate-commit.sh explains each escape.
    COMMAND=$(printf '%s\n' "$COMMAND" \
      | LC_ALL=C awk '{ gsub(/\\\\/, "\002"); gsub(/\\r/, ""); gsub(/\\t/, "\t"); gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
      | tr '\002' '\\')
fi

# Print the first segment of $2 that runs `git $1`, anywhere in the command.
# An ^git anchor missed every chained push (`git add . && git push`).
# Kept identical in validate-commit.sh, which explains the splitting.
git_segment() {
    printf '%s\n' "$2" \
      | awk '{ while ($0 ~ /\\$/) { line = $0; sub(/\\$/, "", line); if ((getline nxt) > 0) { $0 = line nxt } else { $0 = line; break } } print }' \
      | awk '
          pd != "" { t = $0; sub(/\r$/, "", t); if (t ~ /^'"'"'@/) pd = ""; next }
          d != "" { t = $0; sub(/\r$/, "", t); if (tabs) sub(/^\t+/, "", t); if (t == d) d = ""; next }
          { print }
          match($0, /<<-?[ \t]*("[^"]*"|'"'"'[^'"'"']*'"'"'|\\?[A-Za-z_][^ \t\r;&|()<>"'"'"'\\]*)/) && substr($0, RSTART - 1, 1) != "<" \
            && substr($0, 1, RSTART - 1) !~ /\$\(\([^)]*$/ \
            && $0 !~ /(^|[^A-Za-z0-9_.-])(bash|sh|zsh|dash|ksh|fish|pwsh|powershell|python[0-9.]*|py|node|ruby|perl|php|eval|source)([ \t]|$)/ {
              t = substr($0, RSTART, RLENGTH); q = ""
              for (i = 1; i < RSTART; i++) {
                  c = substr($0, i, 1)
                  if (q == "") { if (c == "\"" || c == "'"'"'") q = c }
                  else if (c == q || (q == "\"" && c == "$" && substr($0, i + 1, 1) == "(")) q = ""
              }
              if (q == "") { d = t; tabs = (d ~ /^<<-/); sub(/^<<-?[ \t]*/, "", d); gsub(/[\\"'"'"']/, "", d) }
          }
          # A PowerShell single-quote here-string body (opened by @ then a
          # single quote, closed by a single quote then @) is literal text,
          # the same as a bash here-doc -- UNLESS it is the double-quote form,
          # which PowerShell itself expands $(...) inside, so that form is
          # left unmarked and flows through unchanged.
          $0 ~ /@'"'"'[ \t]*\r?$/ { pd = "x" }' \
      | awk '{
          s = $0; out = ""
          gsub(/"([^"]*[\/\\])?[Gg][Ii][Tt](\.exe)?"/, "git", s); gsub(/'"'"'([^'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?'"'"'/, "git", s)
          gsub(/\$\([^ \t;&|()`"'"'"']*\)|`[^ \t;&|()`"'"'"']*`/, "$_", s)
          while (match(s, /(-[Cc]|--(git-dir|work-tree|namespace|super-prefix|config-env|attr-source))[ \t]+("[^"]*"|'"'"'[^'"'"']*'"'"')|=("[^"]*"|'"'"'[^'"'"']*'"'"')/)) {
              p = out substr(s, 1, RSTART - 1); a = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
              if (a ~ /^=/) {
                  f = "="; ok = p ~ /(^|[ \t;&|(){`"'"'"'])([^ \t;&|(){`"'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?([ \t]+[^ \t;&|(){`"'"'"']+)+$/
              } else {
                  f = a; sub(/[ \t]+["'"'"'].*$/, " ", f)
                  ok = p ~ /(^|[ \t;&|(){`"'"'"'])([^ \t;&|(){`"'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?([ \t]+[^ \t;&|(){`"'"'"']+)*[ \t]+$/
              }
              if (!ok) { out = p substr(a, 1, 1); s = substr(a, 2) s; continue }
              v = a; sub(/^[^"'"'"']*["'"'"']/, "", v); v = substr(v, 1, length(v) - 1); gsub(/[ \t;&|()`]/, "\001", v)
              out = p f v
          }
          s = out s
          # A quoted WORD with nothing inside it a shell would split on (a
          # quoted branch name, a quoted refspec) is unquoted the same way
          # rather than read as a delimiter -- a bare `"` or `'"'"'` used to
          # split the line here, dropping the quoted text (and everything
          # after it on that line) from what the classifier below ever saw.
          # A quoted string that DOES contain such characters is left alone:
          # it may be a whole command (`bash -c "git commit"`) meant to fall
          # on its own line for re-inspection, or a commit message, and either
          # reading is unchanged from before.
          out = ""
          while (match(s, /"[^" \t;&|()`]*"|'"'"'[^'"'"' \t;&|()`]*'"'"'/)) {
              p = out substr(s, 1, RSTART - 1); a = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
              out = p substr(a, 2, length(a) - 2)
          }
          s = out s
          gsub(/&&|\|\|/, "\n", s); gsub(/[;&|()`"'"'"']/, "\n", s); print s
        }' \
      | grep -E "^[[:space:]]*((if|then|else|elif|do|while|until|time|exec|command|nohup|!|[{])[[:space:]]+|(env|sudo|doas|xargs|nice|timeout|stdbuf|winpty|command)([[:space:]]+-[A-Za-z0-9-]+(=[^[:space:]]*)?([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+([0-9][0-9.]*[smhd]?[[:space:]]+)?|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*([^[:space:]]*[/\\])?[Gg][Ii][Tt](\.exe)?([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|super-prefix|config-env|attr-source)[[:space:]]+[^[:space:]]+|-[A-Za-z]|--[A-Za-z-]+(=[^[:space:]]+)?))*[[:space:]]+$1([[:space:]]|\$)"
}

# Only process git push commands
PUSH_SEG=$(git_segment push "$COMMAND") || exit 0

# --- Skipping git hooks on a push (BLOCKING) ---------------------------------
# A product's pre-push git hook runs the same checks as CI (tests, architecture
# tests, OSV-Scanner, gitleaks; Kodeebo ADR-0011). An agent that pushes with
# --no-verify (git accepts any unambiguous prefix, e.g. --no-veri) or points
# core.hooksPath elsewhere skips all of it. Scope, stated so a miss is not read
# as a pass: this reads the push segment only, so a hooks path set by an earlier
# `export GIT_CONFIG_*` or `git config` command is not seen. The user can still
# push this way from their own terminal; the block is for agents.
if printf '%s\n' "$PUSH_SEG" | LC_ALL=C grep -qE '(^|[[:space:]])--no-veri[a-z]*([[:space:]=]|$)' \
   || printf '%s\n' "$PUSH_SEG" | LC_ALL=C grep -qiE 'core\.hookspath'; then
    echo "BLOCKED: this push skips the git hooks (--no-verify or core.hooksPath)." >&2
    echo "The pre-push hook runs the same checks as CI; fix what it reports and push normally." >&2
    echo "If skipping it is really needed, ask the user to push from their own terminal." >&2
    exit 2
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
MATCHED_BRANCH=""

# Check if pushing to a protected branch: main, master, or any release/*
# branch (the trunk model's only other protected line -- no GitFlow develop).
for branch in main master; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        MATCHED_BRANCH="$branch"
        break
    fi
    # Also check if pushing to a protected branch explicitly: as its own word,
    # or as a refspec's destination (HEAD:main, feature:main, +main,
    # refs/heads/main). `main:feature` pushes TO feature and stays quiet.
    if echo "$PUSH_SEG" | grep -qE "([[:space:]+:]|refs/heads/)${branch}([[:space:]]|$)"; then
        MATCHED_BRANCH="$branch"
        break
    fi
done

# release/* is a name pattern, not a fixed branch, so it needs its own checks:
# pushing FROM a release/* branch (a bare `git push`), or explicitly TO one.
if [ -z "$MATCHED_BRANCH" ]; then
    case "$CURRENT_BRANCH" in
        release/*) MATCHED_BRANCH="$CURRENT_BRANCH" ;;
    esac
fi
if [ -z "$MATCHED_BRANCH" ] && echo "$PUSH_SEG" | grep -qE "([[:space:]+:]|refs/heads/)release/[^[:space:]:]+([[:space:]]|$)"; then
    MATCHED_BRANCH=$(echo "$PUSH_SEG" | grep -oE "release/[^[:space:]:]+" | head -1)
fi

# --- Secrets in the commits being pushed (BLOCKING) -------------------------
# The commit hook scans what is staged; this catches anything committed
# outside it (another terminal, --no-verify, a rebase).
#
# What is scanned is what the command pushes, not whatever HEAD is: each refspec's
# source (`feature`, `HEAD`, `abc123:main`, `+topic:release/1`) is scanned for the
# commits that are on no remote ref yet (`<src> --not --remotes`). That is correct
# for a brand-new branch (its remote ref does not exist, so there is no upstream
# to diff against) as well as for an existing one, and it does not depend on an
# upstream being configured. A bare `git push` / `git push origin` pushes HEAD.
# `--all` / `--mirror` / a glob refspec scan every local branch, `--tags` every
# tag; a delete (`:old`, `--delete`) sends no commits. With no remote-tracking ref
# at all (never fetched) "not on any remote" would be the whole history, so the
# last 100 commits of the source are scanned instead and the note says so.
_push_ranges() { # prints one gitleaks --log-opts range per line
    local line w t i seen_push remote_done mode del src r spec any
    local has_remote=""; [ -n "$(git for-each-ref --count=1 refs/remotes 2>/dev/null)" ] && has_remote=1
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        read -r -a w <<< "$line"; seen_push=""; remote_done=""; mode=""; del=""; spec=()
        i=0
        while [ $i -lt ${#w[@]} ]; do
            t="${w[$i]}"; i=$((i+1))
            if [ -z "$seen_push" ]; then [ "$t" = push ] && seen_push=1; continue; fi
            case "$t" in
                --all|--branches|--mirror) mode=all ;;
                --tags) [ -z "$mode" ] && mode=tags ;;
                --delete|-d) del=1 ;;
                -o|--push-option|--repo|--receive-pack|--exec) i=$((i+1)) ;;
                -*) ;;
                *) if [ -z "$remote_done" ]; then remote_done=1; else spec+=("$t"); fi ;;
            esac
        done
        [ -n "$del" ] && continue
        any=""
        if [ "$mode" = all ]; then
            printf '%s\n' "--branches --not --remotes"; any=1
        elif [ "$mode" = tags ]; then
            printf '%s\n' "--tags --not --remotes"; any=1
        fi
        for r in ${spec[@]+"${spec[@]}"}; do
            r="${r#+}"
            case "$r" in
                :*) any=1; continue ;;                            # delete a remote ref: sends no commits
                *\**) printf '%s\n' "--branches --not --remotes"; any=1; continue ;;
            esac
            src="${r%%:*}"
            [ -n "$src" ] || continue
            git rev-parse --verify -q "${src}^{commit}" >/dev/null 2>&1 || continue
            if [ -n "$has_remote" ]; then printf '%s\n' "$src --not --remotes"; else printf '%s\n' "-100 $src"; fi
            any=1
        done
        if [ -z "$any" ] && [ -z "$mode" ]; then
            if [ -n "$has_remote" ]; then printf '%s\n' "HEAD --not --remotes"; else printf '%s\n' "-100 HEAD"; fi
        fi
    done <<< "$1"
}
_GL_NOTE=""
if command -v gitleaks >/dev/null 2>&1; then
    _RANGES=$(_push_ranges "$PUSH_SEG" | sort -u)
    # An empty list means the push sends no commits (a delete): nothing to scan.
    if [ -z "$(git for-each-ref --count=1 refs/remotes 2>/dev/null)" ]; then
        _GL_NOTE=" No remote-tracking refs exist, so the last 100 commits of each pushed ref were scanned for secrets, not only the unpushed ones."
    fi
    while IFS= read -r _RANGE; do
        [ -n "$_RANGE" ] || continue
        if gitleaks git --help >/dev/null 2>&1; then
            _GL=$(gitleaks git --log-opts="$_RANGE" --redact --verbose --no-color --no-banner --exit-code 1 . 2>&1); _RC=$?
        else
            _GL=$(gitleaks detect --log-opts="$_RANGE" --redact --verbose --no-color --no-banner --exit-code 1 2>&1); _RC=$?
        fi
        if [ "$_RC" = 1 ]; then
            echo "BLOCKED: gitleaks found secrets in commits about to be pushed ($_RANGE):" >&2
            printf '%s\n' "$_GL" | grep -E 'Finding|RuleID|File|Commit|Line' | head -40 >&2
            echo "Rewrite those commits to remove the secret (and rotate it) before pushing." >&2
            exit 2
        fi
        [ "$_RC" != 0 ] && _GL_NOTE="$_GL_NOTE gitleaks failed to run (exit $_RC) — outgoing commits were NOT scanned for secrets."
    done <<< "$_RANGES"
else
    _GL_NOTE=" gitleaks is not installed — outgoing commits were NOT scanned for secrets."
fi

# Allow the push, but warn where it is seen: hook JSON, because stderr on
# exit 0 reaches neither the user nor Claude. No permissionDecision — "allow"
# would skip the user's own permission prompt.
if [ -n "$MATCHED_BRANCH" ] || [ -n "$_GL_NOTE" ]; then
    MSG=""
    if [ -n "$MATCHED_BRANCH" ]; then
        MSG="Push to protected branch '$MATCHED_BRANCH'. CI is the gate: lint (golangci-lint / ktlint+detekt or the ADR-chosen Kotlin linters / eslint+tsc / swiftlint), unit + Testcontainers integration + contract tests, govulncheck/OSV scan. Confirm they pass locally for the roots you changed, and that no S1 bug or failing security test is open."
    fi
    MSG="$MSG$_GL_NOTE"
    . .claude/hooks/yaml-helper.sh 2>/dev/null
    if command -v hook_warn >/dev/null 2>&1; then
        hook_warn PreToolUse "$MSG"
    else
        printf '%s\n' "$MSG" >&2
    fi
fi
exit 0
