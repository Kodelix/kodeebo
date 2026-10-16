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
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  STUDIO_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  STUDIO_ROOT="$CLAUDE_PROJECT_DIR"
else
  STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$STUDIO_ROOT" ] && cd "$STUDIO_ROOT" 2>/dev/null || true

# Claude Code PreToolUse hook: Validates git commit commands
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }

INPUT=$(cat)

# Most Bash and PowerShell calls do not mention git at all. Leave before any
# parsing: this hook runs on every one of them, and the parse is most of its
# cost (the early exit is the shell start-up alone).
# Tested only after the "tool_input" key: matching the whole payload also
# tests cwd and transcript_path, so a project path containing "GitHub" or
# "digital" never took this exit and paid the full parse on every call.
case "$INPUT" in *'"tool_input"'*[Gg][Ii][Tt]*) ;; *) exit 0 ;; esac

# Parse command -- use jq if available, fall back to grep. The fallback's string
# body is (\\.|[^"\\])* so an escaped quote (-m \"msg\") does not end it early.
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    # LC_ALL=C: in a UTF-8 locale an emoji in the command makes this grep match
    # nothing, and an empty COMMAND skips every check below.
    COMMAND=$(echo "$INPUT" | LC_ALL=C grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 | LC_ALL=C sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    # The grep leaves the JSON escapes in place; decode them once, here, and
    # never jq's output. \\ goes first, through a placeholder: decoded after \r,
    # the path C:\\Users\\me\\review lost the `r` of `review` (a segment
    # starting t or n became a tab or a line break), the -C check below found
    # no repository, and the commit went unchecked. A \" left escaped ended a
    # quoted branch name in a stray backslash; a \t or \r left escaped never
    # closed a tab-indented `<<-EOF` or a CRLF here-doc, dropping every command
    # after it.
    COMMAND=$(printf '%s\n' "$COMMAND" \
      | LC_ALL=C awk '{ gsub(/\\\\/, "\002"); gsub(/\\r/, ""); gsub(/\\t/, "\t"); gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
      | tr '\002' '\\')
fi

# Print the first segment of $2 that runs `git $1`, anywhere in the command.
# Anchoring on ^git let every chained form through unchecked:
# `git add -A && git commit`, `git -C . commit`, `cd x && git commit`,
# `GIT_DIR=.git git commit`, a commit on a second line. Segments split on
# && || ; & | ( ) backticks and quotes, and on newlines. Before a segment's
# `git`, VAR=value words, `env`/`sudo`/`doas`/`xargs`/`nice`/`timeout` with
# their flags (a flag's value and timeout's duration included), shell keywords
# (`if`, `do`, `{`, `time`, ...) and a path, either slash (`/usr/bin/git`,
# `C:\Git\cmd\git.exe`) are allowed, and a QUOTED path to git ("C:\Program
# Files\Git\cmd\git.exe") is read as plain `git`; after it, git's own options
# (-C <dir>, -c <k=v>, --git-dir <dir> and the other long options that take a
# separate value, -p, --flag[=v]). A quoted value of git's own options --
# `-C "my repo"`, `--git-dir ".git"`, `-c user.name="A B"`, `--work-tree="."`,
# `-C "$(pwd)"` -- is unquoted first and its spaces and shell operators carried
# as \001, or the split cut `git` off from its subcommand and the commit went
# unchecked; an unquoted `$(pwd)` with no space in it is one word, too. Only
# when it follows `git`: a shell's own `bash -c "git commit"` was unquoted the
# same way, which glued the inner command into one word and skipped the check,
# and the quote after `=` in `grep "key=" f && git commit -m "x"` closes a
# string rather than opening a value. All splitting is awk: BSD sed writes a
# literal `n` for `\n`, so on macOS a sed split missed every chained form.
# Over-splitting only costs a check that finds nothing staged; under-splitting
# is the bypass. Kept identical in validate-push.sh.
#
# `git` itself is matched case-insensitively (`Git`, `GIT`) and a bare quoted
# `"git"` or `'git'` (no path) reads as plain `git` too, the same as a quoted
# path ending in it. `stdbuf`, `winpty` and `command -p` join `env`/`sudo`/...
# as prefixes that take flags. A line ending in a lone `\` is joined with the
# next before any of this runs, so `git \` then `commit` on the next line is
# still one command; `1<<y` inside `$((...))` is left-shift, not a here-doc
# opener, even though it matches `<<` the same as a real one. A quoted WORD
# with no shell-meaningful character inside it (a quoted branch name, `"main"`)
# is unquoted in place rather than read as a delimiter; a quoted string that
# DOES contain one is left for the here-doc/command handling above.
#
# A here-document body is text, not commands: a commit message, a file being
# written. Read as commands, a message quoting `git push origin main` warned
# about a push, and `cat > notes.md <<EOF` mentioning git commit blocked on
# staged data. So the body is dropped -- UNLESS its line runs an interpreter
# (bash <<EOF, python - <<EOF), whose here-doc IS commands: dropping that
# would be the bypass. `<<<` is a here-string, not a here-doc. An interpreter
# may carry a path (`/bin/bash <<EOF`). The delimiter is the whole word, or the
# whole quoted string (`<<'END-NOTES'`), and a `<<` inside a quoted string
# (`echo "a<<b"`) opens nothing -- `$(cat <<EOF` inside one still does. Either
# mistake left a here-doc that never closed and dropped every later line, a
# real commit included. A PowerShell single-quote here-string (`@'` ... `'@`)
# is the same kind of text and is dropped the same way; the double-quote form
# (`@"` ... `"@`) is left alone, because PowerShell itself expands `$(...)`
# inside it, and that content is still live.
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

# Only process git commit commands
COMMIT_SEG=$(git_segment commit "$COMMAND") || exit 0

# `git -C <dir> commit` commits whatever repository <dir> is in. Only this
# project's staged files are ours to check; another repository is not. Leave
# only when <dir> PROVABLY is another repository: a <dir> rev-parse cannot
# resolve here -- `"$CLAUDE_PROJECT_DIR"`, `~/x`, `"$(pwd)"`, all unexpanded in
# the command text -- is this project as often as not, and skipping it let the
# commit through unchecked.
#
# COMMIT_SEG can hold more than one line -- a chained `git -C other commit &&
# git commit` -- and this early exit must not fire on the strength of the
# FIRST one alone: that let a real commit of THIS repo, chained after a
# provably-elsewhere one, through unchecked. So it only applies when exactly
# one commit invocation was found; a chain of several falls through to the
# normal staged-file checks below, which are already scoped to this repo.
if [ "$(printf '%s\n' "$COMMIT_SEG" | grep -c .)" = 1 ]; then
GIT_OPTS=${COMMIT_SEG%%[[:space:]]commit*}
case "$GIT_OPTS" in
    *-C*)
        C_DIR=$(printf '%s' "$GIT_OPTS" | sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p' | tr '\001' ' ')
        if [ -n "$C_DIR" ] && _C_TOP=$(git -C "$C_DIR" rev-parse --show-toplevel 2>/dev/null) && [ -n "$_C_TOP" ]; then
            _OUR_TOP=$(git rev-parse --show-toplevel 2>/dev/null)
            [ "$_C_TOP" != "$_OUR_TOP" ] && [ ! "$_C_TOP" -ef "$_OUR_TOP" ] && exit 0
        fi ;;
esac
fi

# A `git add` / `git stage` earlier in the SAME command runs after this hook has
# read the index, so the secret scans below (gitleaks --staged and the staged
# diff) would check the old index: a new file holding a key could pass unseen,
# and an already-fixed file could block. Stage in one command, commit in the
# next, so every scan reads exactly what will be committed (dogfood #22).
if printf '%s\n' "$COMMAND" | LC_ALL=C awk '
    { s = s $0 "\n" }
    END {
        # Only an add BEFORE the first commit counts: text after it (a message
        # that mentions "git add", a later add) is not staged for this commit.
        G = "(^|[^A-Za-z0-9_.-])git([ \t]+-[A-Za-z-]+([ \t]+[^ \t;&|-][^ \t;&|]*)?)*[ \t]+"
        if (!match(s, G "commit([ \t]|$)")) exit 1
        head = substr(s, 1, RSTART)
        # In command position only (line start or after ; & | ( ), so a quoted
        # mention such as grep "git add" is not an add.
        A = "(^|[;&|(\n])[ \t]*git([ \t]+-[A-Za-z-]+([ \t]+[^ \t;&|-][^ \t;&|]*)?)*[ \t]+(add|stage)([ \t]|$)"
        exit match(head, A) ? 0 : 1
    }'; then
    echo "BLOCKED: this command stages files and commits in one call. The commit checks (secret scan included) read the index before the command runs, so they would not see what the add stages. Run the git add in one command, then the git commit in the next." >&2
    exit 2
fi

# Resolve a Python interpreter ONCE for every batched check below. Both the
# blocking JSON scan and the advisory design scan must not spawn one process per
# item; they spawn one each, and share this lookup.
# Run it, do not just find it: the Windows Store `python` placeholder passes
# `command -v` and then prints an install hint instead of running anything.
# And ask for Python 3: a Python 2 first on PATH runs `import sys` fine, then
# fails every check below (they read sys.stdin.buffer), and valid data blocked.
_VC_PY=""
for _c in python python3 py; do
    if command -v "$_c" >/dev/null 2>&1 && "$_c" -c 'import sys; sys.exit(sys.version_info[0] < 3)' >/dev/null 2>&1; then
        _VC_PY="$_c"; break
    fi
done

# Get the files this commit will record, and where each committed copy lives.
# A plain commit records the INDEX. `-a` / `--all` (or a cluster such as -am)
# also commits every modified tracked file, and `git commit <path>` commits the
# named paths' WORKING copies, staged or not -- both read from the working tree
# (WT_FILES). core.quotePath=false: without it a non-ASCII path comes back
# quoted ("assets/data/caf\303\251.json") and no pattern below matched it.
_GIT="git -c core.quotePath=false"
COMMIT_ARGS=" ${COMMIT_SEG#*[[:space:]]commit}"
INDEX_FILES=$($_GIT diff --cached --name-only 2>/dev/null)
WT_FILES=""
if printf '%s' "$COMMIT_ARGS" | grep -qE '[[:space:]](-[ABDEGHIJKLMNOPQRTUVWXYZbdefghijklnopqrsvwxyz]*a[A-Za-z]*|--all)([[:space:]]|$)'; then
    WT_FILES=$($_GIT diff --name-only 2>/dev/null)
fi
# Pathspecs after the `commit` word. ANY pathspec takes working copies -- `.`,
# `-- .`, a folder, a glob, `:/` -- not only a literal assets/ path, and a
# message or an -F file is not one. So Python tokenises the command as a shell
# would (shlex; COMMIT_SEG was split at quotes and cannot say where `-m "a b"`
# ends) and git expands the pathspecs. Without Python only literal data paths
# are found, and the data check below blocks on them anyway.
#
# The tokeniser also reads an -a the grep above cannot see: COMMIT_ARGS stops
# at the first quote, so `git commit -m "x" -a` and `--all` committed every
# modified tracked file unchecked. `-a` counts in a short-option cluster only
# before a letter that takes a value (`-am x` is -a; `-ma` is the message "a").
#
# A path-limited commit (`git commit -m x src/player.gd`, no -i/--include)
# records ONLY those paths -- `git commit --dry-run` lists nothing else -- so a
# broken file staged for later must not block it. The tokeniser says so on its
# first line (CCGS-ONLY), and only when it read every commit in the command:
# one inside `bash -c "..."` or a here-doc is a single word or plain text to it.
#
# A relative pathspec resolves where the commit runs, and this hook runs at the
# project root: after a `cd`, under -C, or in a session sitting in a subfolder,
# `cd assets && git commit -m x data/item.json` named nothing here and the file
# went unchecked. There, and whenever a pathspec names no tracked file, every
# modified tracked file is checked (`:/`), and the index with it.
#
# A `git add` (or `git stage`) earlier in the same command stages its files
# after this hook has read the index, so `git add -A && git commit` committed a
# new broken data file unchecked. Each add before a commit is read too, and
# what it will stage -- modified tracked files, and untracked ones unless it is
# -u (ignored ones only with -f) -- is checked as working copies. A dry run
# (-n) stages nothing, an add after the commit is for a later one, a
# path-limited commit still records only its own paths, and after a cd or -C
# an add's pathspecs are read as the whole tree, as above.
if [ -n "$_VC_PY" ]; then
    if command -v jq >/dev/null 2>&1; then
        _VC_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
    else
        _VC_CWD=$(echo "$INPUT" | LC_ALL=C grep -oE '"cwd"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 \
          | LC_ALL=C sed 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\/\\/g')
    fi
    _VC_AWAY=0
    [ -n "$_VC_CWD" ] && [ ! "$_VC_CWD" -ef . ] && _VC_AWAY=1
    _VC_TOK=$(printf '%s\n' "$COMMAND" | "$_VC_PY" -c '
import re, shlex, subprocess, sys
OPS = set(";&|()<>")
GIT_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix", "--config-env", "--attr-source"}
REDIR = re.compile(r"^[<>]+&?$|^&>+$")  # >, >>, >&, <, <<, &>: a redirection operator
COMMIT_ARG = {"--message", "--file", "--reuse-message", "--reedit-message", "--fixup", "--squash",
              "--author", "--date", "--template", "--cleanup", "--trailer", "--pathspec-from-file"}
def words(line):
    try:
        lx = shlex.shlex(line, posix=True, punctuation_chars=True)
        lx.whitespace_split = True
        lx.commenters = ""
        return list(lx)
    except ValueError:  # an unclosed quote: the line continues a string
        return line.split()
def git(*args):
    return subprocess.run(["git", "-c", "core.quotePath=false"] + list(args),
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
def add(w, k):  # git add/stage from w[k] -> pathspecs, takes untracked, -f, -n, next k
    specs, rest, alln, upd, force, dry = [], False, False, False, False, False
    while k < len(w):
        a = w[k]
        if a.isdigit() and k + 1 < len(w) and w[k + 1][:1] in "<>":
            k += 1
            continue
        if REDIR.match(a):
            k += 2
            continue
        if a and set(a) <= OPS:
            break
        if rest or not a.startswith("-") or a == "-":
            specs.append(a)
        elif a == "--":
            rest = True
        elif a.startswith("--"):
            alln = alln or a in ("--all", "--no-ignore-removal")
            upd, force, dry = upd or a == "--update", force or a == "--force", dry or a == "--dry-run"
            if a.startswith("--pathspec-from-file"):
                specs.append(":/")  # paths only git reads
        else:  # no short option of git add takes a value: -Av is -A -v
            alln, upd, force, dry = alln or "A" in a, upd or "u" in a, force or "f" in a, dry or "n" in a
        k += 1
    if not specs and (alln or upd):
        specs = [":/"]  # -A and -u with no pathspec take the whole tree
    return specs, alln or not upd, force, dry, k
text = sys.stdin.buffer.read().decode("utf-8", "replace")
away = sys.argv[1] == "1" or re.search(r"(^|[^\w.-])(cd|pushd|popd)(\s|[;&|)]|$)", text, re.M) is not None
specs, commits, only = [], 0, True
adds, pending = [], []  # what each git add stages: before a commit, not yet
def logical_lines(t):
    # Split on newlines that are OUTSIDE quotes, so a multi-line -m message
    # (subject, blank line, Story: X) or a $(cat <<EOF ...) message stays one
    # command. Splitting per physical line turned message words into pathspecs.
    SQ, DQ, BS, NL = chr(39), chr(34), chr(92), chr(10)
    out, cur, q, i = [], [], "", 0
    while i < len(t):
        c = t[i]
        if q:
            if c == BS and q == DQ and i + 1 < len(t):
                cur.append(c); cur.append(t[i + 1]); i += 2; continue
            if c == q: q = ""
            cur.append(c)
        elif c in (SQ, DQ):
            q = c; cur.append(c)
        elif c == NL:
            out.append("".join(cur)); cur = []
        else:
            cur.append(c)
        i += 1
    out.append("".join(cur))
    return out
for line in logical_lines(text):
    w, i = words(line), 0
    while i < len(w):
        if w[i].replace("\\", "/").rsplit("/", 1)[-1].lower() not in ("git", "git.exe"):
            i += 1
            continue
        j = i + 1
        while j < len(w) and w[j].startswith("-"):
            away = away or w[j] in ("-C", "--git-dir", "--work-tree") or w[j].startswith(("--git-dir=", "--work-tree="))
            j += 2 if w[j] in GIT_ARG else 1
        if j < len(w) and w[j] in ("add", "stage"):
            s, new, force, dry, i = add(w, j + 1)
            if not dry:
                pending.append((s, new, force))
            continue
        if j >= len(w) or w[j] != "commit":
            i = j
            continue
        commits += 1
        adds, pending = adds + pending, []
        k, rest, mine, index = j + 1, False, [], False
        while k < len(w):
            a = w[k]
            if a.isdigit() and k + 1 < len(w) and w[k + 1][:1] in "<>":
                k += 1  # 2>&1, 2> err.txt: a file descriptor, not a pathspec
                continue
            if REDIR.match(a):
                k += 2  # the redirection and its target; the commit goes on after it
                continue
            if a and set(a) <= OPS:
                break  # the next command
            if rest or not a.startswith("-") or a == "-":
                mine.append(a)
            elif a == "--":
                rest = True
            elif a.startswith("--"):
                if a == "--all" or a.startswith("--pathspec-from-file"):
                    mine.append(":/")  # every tracked change, or paths only git reads
                index = index or a in ("--all", "--include", "--patch", "--interactive") \
                    or a.startswith("--pathspec-from-file")
                if a in COMMIT_ARG:
                    k += 1  # --message <msg>: the value is not a pathspec
            else:
                for n, ch in enumerate(a[1:], 1):  # -am: -a, then -m <msg>
                    if ch in "mFCct":
                        if n == len(a) - 1:
                            k += 1
                        break
                    if ch in "uS":
                        break  # -uno, -S<key>: the rest is its value
                    if ch == "a":
                        mine.append(":/")
                    index = index or ch in "aip"
            k += 1
        specs += mine
        only = only and bool(mine) and not index
        i = k
if specs and not away:
    away = git("ls-files", "--error-unmatch", "--", *specs).returncode != 0
if specs and away:
    specs.append(":/")
    only = False
only = only and commits > 0 and len(re.findall(r"(?<![\w.-])commit(?![\w-])", text)) == commits
out = git("diff", "--name-only", "HEAD", "--", *specs) if only else None
if out is None or out.returncode != 0:  # not path-limited, or no HEAD yet
    only = False
    out = git("diff", "--name-only", "--", *specs) if specs else None
more = b""
for s, new, force in ([] if only else adds):
    s = [":/"] if away else s
    more += git("diff", "--name-only", "--", *s).stdout
    if new:
        more += git("ls-files", "--others", "--full-name", *([] if force else ["--exclude-standard"]), "--", *s).stdout
sys.stdout.buffer.write((b"CCGS-ONLY\n" if only else b"CCGS-INDEX\n") + (out.stdout if out else b"") + more)
' "$_VC_AWAY" 2>/dev/null)
    case "$_VC_TOK" in CCGS-ONLY*) INDEX_FILES="" ;; esac
    WT_FILES=$(printf '%s\n%s' "$WT_FILES" "$(printf '%s\n' "$_VC_TOK" | tail -n +2)")
else
    _AFTER=$(printf '%s' "$COMMAND" | LC_ALL=C awk '
        !f && match($0, /(^|[^A-Za-z0-9_.-])commit([ \t]|$)/) { f = 1; print substr($0, RSTART + RLENGTH); next }
        f { print }')
    for _p in $(printf '%s' "$_AFTER" | LC_ALL=C grep -oE '(backend|web|site|mobile|contracts|deploy|design|docs|tools)/[^[:space:]"'"'"';|&)]*'); do
        WT_FILES=$(printf '%s\n%s' "$WT_FILES" "$($_GIT diff --name-only -- "$_p" 2>/dev/null)")
    done
    # No tokeniser to read a `git add`'s paths: take every change and new file.
    if git_segment add "$COMMAND" >/dev/null || git_segment stage "$COMMAND" >/dev/null; then
        WT_FILES=$(printf '%s\n%s\n%s' "$WT_FILES" "$($_GIT diff --name-only 2>/dev/null)" \
          "$($_GIT ls-files --others --exclude-standard --full-name 2>/dev/null)")
    fi
fi
WT_FILES=$(printf '%s\n' "$WT_FILES" | grep -v '^$' | sort -u)
# A project in a subfolder of a larger repository (product/ in a monorepo): git
# names every path above from the repository's top level, and every check below
# matches from the PROJECT root (^contracts/, ^design/specs/, the code roots) and
# reads files relative to it. Unconverted, nothing matched and the commit went
# through unchecked. Keep this project's paths with the prefix dropped; files
# outside the project are not ours to check. "" at the top level.
_VC_PREFIX=$(git rev-parse --show-prefix 2>/dev/null)
if [ -n "$_VC_PREFIX" ]; then
    INDEX_FILES=$(printf '%s\n' "$INDEX_FILES" | LC_ALL=C awk -v p="$_VC_PREFIX" 'index($0, p) == 1 { print substr($0, length(p) + 1) }')
    WT_FILES=$(printf '%s\n' "$WT_FILES" | LC_ALL=C awk -v p="$_VC_PREFIX" 'index($0, p) == 1 { print substr($0, length(p) + 1) }')
fi
STAGED=$(printf '%s\n%s\n' "$INDEX_FILES" "$WT_FILES" | grep -v '^$' | sort -u)
if [ -z "$STAGED" ]; then
    exit 0
fi

WARNINGS=""

# Source the config helper once, ahead of every consumer below. Success is
# detected by whether the function EXISTS, not by the source's exit status.
_VC_HELPER=0
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null || true
    command -v resolve_setting >/dev/null 2>&1 && _VC_HELPER=1
fi

# ===========================================================================
# BLOCKING CHECKS FIRST — everything after this section is advisory.
# A starved hook (15 s timeout) must already have done the part that matters.
# ===========================================================================

# --- 1. Secret material staged as files -------------------------------------
# .env.example / *.example are documentation and allowed. A .pem / .key / .pub is
# judged by what it HOLDS, not its name: a file whose every PEM block is a PUBLIC
# KEY or a CERTIFICATE (the licence-verifier public key, a CA certificate) is
# public material and allowed; anything with a PRIVATE KEY block, or no
# recognisable PEM header at all, still blocks. Keystores (.p12 .pfx .jks
# .keystore) are binary and always block.
_vc_content() { # $1 path: the staged copy, else the working copy
    $_GIT show ":./$1" 2>/dev/null || cat -- "$1" 2>/dev/null
}
_vc_public_only() { # 0 only when the file holds nothing but PUBLIC KEY / CERTIFICATE PEM blocks
    local c; c=$(_vc_content "$1" | LC_ALL=C tr -d '\0')
    [ -n "$c" ] || return 1
    if printf '%s\n' "$c" | LC_ALL=C grep -qE 'PRIVATE KEY'; then return 1; fi
    printf '%s\n' "$c" | LC_ALL=C grep -qE -- '^-----BEGIN (RSA |EC )?(PUBLIC KEY|CERTIFICATE|TRUSTED CERTIFICATE|X509 CRL)-----' || return 1
    if printf '%s\n' "$c" | LC_ALL=C grep -E -- '^-----BEGIN ' \
         | LC_ALL=C grep -qvE -- '^-----BEGIN (RSA |EC )?(PUBLIC KEY|CERTIFICATE|TRUSTED CERTIFICATE|X509 CRL)-----'; then return 1; fi
    return 0
}
SECRET_CAND=$(printf '%s\n' "$STAGED" | grep -E '(^|/)(\.env(\.[^/]*)?|[^/]*\.(pem|key|p12|pfx|jks|keystore)|id_(rsa|ed25519|ecdsa)|credentials\.json|service-account[^/]*\.json)$' \
  | grep -vE '(^|/)\.env\.example$|\.example$|\.sample$')
SECRET_FILES=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    # A file that no longer exists (a staged deletion) adds no secret.
    [ -e "$f" ] || $_GIT cat-file -e ":./$f" 2>/dev/null || continue
    case "$f" in
        *.pem|*.key) _vc_public_only "$f" && continue ;;
    esac
    SECRET_FILES="$SECRET_FILES$f
"
done <<< "$SECRET_CAND"
SECRET_FILES=$(printf '%s' "$SECRET_FILES" | grep -v '^$')
if [ -n "$SECRET_FILES" ]; then
    printf '%s\n' "$SECRET_FILES" | while IFS= read -r f; do
        [ -n "$f" ] && echo "BLOCKED: $f looks like secret material (env file / private key / keystore). Remove it from the commit; secrets come from the secret store. A .pem/.key that holds only PUBLIC KEY or CERTIFICATE blocks is allowed; a genuinely public .env-style file should be renamed *.example." >&2
    done
    exit 2
fi

# --- 2. Secrets inside staged content ----------------------------------------
# gitleaks when installed (authoritative); a built-in high-confidence pattern
# scan always runs, so a machine without gitleaks is still protected against
# the obvious cases. The built-in list is deliberately short: every pattern
# here BLOCKS, so it must not cry wolf.
if command -v gitleaks >/dev/null 2>&1; then
    if gitleaks git --help >/dev/null 2>&1; then
        _GL_OUT=$(gitleaks git --pre-commit --staged --redact --verbose --no-color --no-banner --exit-code 1 . 2>&1); _GL_RC=$?
    else
        _GL_OUT=$(gitleaks protect --staged --redact --verbose --no-color --no-banner --exit-code 1 2>&1); _GL_RC=$?
    fi
    if [ "$_GL_RC" = 1 ]; then
        echo "BLOCKED: gitleaks found secrets in the staged changes:" >&2
        printf '%s\n' "$_GL_OUT" | grep -E 'Finding|Secret|RuleID|File|Line' | head -40 >&2
        echo "Remove the secret, rotate it if it was ever real, and commit again." >&2
        exit 2
    elif [ "$_GL_RC" != 0 ]; then
        WARNINGS="$WARNINGS\nSKIPPED: gitleaks is installed but failed to run (exit $_GL_RC) — only the built-in secret patterns were checked."
    fi
else
    WARNINGS="$WARNINGS\nSKIPPED: gitleaks is not installed — only the built-in secret patterns were checked. Install gitleaks for full coverage."
fi

# Added lines, each prefixed "<path>\001". Lines in a testdata/ or fixtures/
# directory are dropped when they, or the file's other added lines, carry an
# obviously-fake marker (EXAMPLE, FAKE, DUMMY, NOT A REAL, TEST ONLY, PLACEHOLDER,
# REDACTED, XXXXXXXX): a fixture key that says it is fake is not a leak, a bare
# one still blocks. Everything outside those directories is always scanned.
_VC_ADDED=$($_GIT diff --cached -U0 --no-color 2>/dev/null; if [ -n "$WT_FILES" ]; then $_GIT diff -U0 --no-color 2>/dev/null; fi)
_VC_DIFF=$(printf '%s\n' "$_VC_ADDED" | LC_ALL=C awk '
    function flush(   i, fake, low) {
        if (file == "") return
        fixture = (file ~ /(^|\/)(testdata|fixtures?|__fixtures__|__mocks__)\//)
        fake = 0
        if (fixture) for (i = 1; i <= n; i++) { low = tolower(L[i]); if (low ~ /example|fake|dummy|not a real|not-a-real|test only|test-only|placeholder|redacted|xxxxxxxx/) { fake = 1; break } }
        if (!(fixture && fake)) for (i = 1; i <= n; i++) print file "\001" L[i]
        n = 0
    }
    /^diff --git / { flush(); file = ""; next }
    /^\+\+\+ / { p = substr($0, 5); sub(/^b\//, "", p); file = (p == "/dev/null" ? "" : p); n = 0; next }
    /^\+/ && file != "" { n++; L[n] = substr($0, 2) }
    END { flush() }')
# AWS documentation keys (AKIA...EXAMPLE) are not secrets, wherever they appear.
_VC_SCAN=$(printf '%s\n' "$_VC_DIFF" | LC_ALL=C sed -E 's/(AKIA|ASIA)[0-9A-Z]{9}EXAMPLE//g')
_SECRET_RE='-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|sk_live_[0-9A-Za-z]{16,}|rk_live_[0-9A-Za-z]{16,}|whsec_[0-9A-Za-z]{16,}|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[0-9A-Za-z]{36,}|github_pat_[0-9A-Za-z_]{40,}|AIza[0-9A-Za-z_-]{35}|SG\.[0-9A-Za-z_-]{22}\.[0-9A-Za-z_-]{43}'
_HITS=$(printf '%s\n' "$_VC_SCAN" | LC_ALL=C grep -cE -- "$_SECRET_RE")
# Database URLs with an inline password (postgres://user:pass@, mongodb(+srv)://,
# redis://:pass@, mysql, amqp). Placeholders are not secrets: ${VAR} / <angle> /
# %(fmt)s interpolation, and the explicit stand-in words below (a weak real-looking
# word such as pass or postgres is NOT a placeholder: write ${DB_PASSWORD} or
# <password>). Matched on a lowercased copy so the word list needs no case variants.
_DBURL_RE='(postgres(ql)?|mongodb(\+srv)?|redis|rediss|mysql|amqps?)://[^[:space:]/:@]*:[^[:space:]/@$<{%][^[:space:]/@]{2,}@'
_DBURL_FAKE='://[^[:space:]/:@]*:(changeme|change-me|change_me|example|placeholder|redacted|your[-_]?password|x{3,}|\*{3,})@'
_DBHITS=$(printf '%s\n' "$_VC_SCAN" | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C sed -E "s#${_DBURL_FAKE}#://x@#g" | LC_ALL=C grep -cE -- "$_DBURL_RE")
if [ "${_HITS:-0}" -gt 0 ] || [ "${_DBHITS:-0}" -gt 0 ]; then
    echo "BLOCKED: $(( ${_HITS:-0} + ${_DBHITS:-0} )) added line(s) match a known secret format (private key, AWS/Stripe/Stripe-webhook/GitHub/Slack/Google/SendGrid key, or a database URL with an inline password: use a \${DB_PASSWORD} or <password> placeholder in docs and examples). Remove it, rotate it, and commit again. Lines are not echoed here on purpose." >&2
    exit 2
fi

# --- 3. Contract and data JSON must parse ------------------------------------
# Only where JSON is data the product depends on. tsconfig.json and editor
# settings are JSON-with-comments and are never checked here.
DATA_FILES=$(printf '%s\n' "$STAGED" | grep -E '^(contracts|deploy|tools/seed)/.*\.[Jj][Ss][Oo][Nn]$')
if [ -n "$DATA_FILES" ]; then
    if [ -z "$_VC_PY" ]; then
        echo "BLOCKED: $(printf '%s\n' "$DATA_FILES" | grep -c .) staged JSON file(s) could not be validated — no Python 3 interpreter found. Install Python 3 and commit again." >&2
        exit 2
    fi
    BAD_JSON=$(printf '%s\n' "$DATA_FILES" | "$_VC_PY" -c '
import json, sys, os
out = ["STUDIO-JSON-CHECKED"]
for p in sys.stdin.read().splitlines():
    p = p.strip()
    if not p or not os.path.isfile(p):
        continue
    try:
        with open(p, "rb") as fh:
            json.loads(fh.read().decode("utf-8-sig"))
    except Exception:
        out.append(p)
sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
' 2>/dev/null)
    if [ "$(printf '%s\n' "$BAD_JSON" | head -1)" != "STUDIO-JSON-CHECKED" ]; then
        echo "BLOCKED: the JSON check did not run under '$_VC_PY'. Check that it is a working Python 3 and commit again." >&2
        exit 2
    fi
    BAD_JSON=$(printf '%s\n' "$BAD_JSON" | tail -n +2 | grep -v '^$')
    if [ -n "$BAD_JSON" ]; then
        printf '%s\n' "$BAD_JSON" | while IFS= read -r b; do echo "BLOCKED: $b is not valid JSON" >&2; done
        exit 2
    fi
fi

# ===========================================================================
# ADVISORY CHECKS — append to $WARNINGS; the commit proceeds.
# ===========================================================================

# --- 4. Commit message: Conventional Commits + story/task reference ----------
# Read from -m/--message values, or from the -F/--file file (it already exists
# when this PreToolUse hook runs; a relative path is read from the project root,
# where the command runs). `-F -` fed by a here-doc (`git commit -F - <<EOF`)
# is checked from the here-doc body, which is lifted out before tokenising so an
# apostrophe in it cannot make the command unparseable. `-F -` fed any other way
# (a pipe), an unreadable file and an editor message are not visible here, and
# that is said rather than passed silently.
if [ -n "$_VC_PY" ]; then
    _VC_MSG_CHECK=$(printf '%s\n' "$COMMAND" | "$_VC_PY" -c '
import re, shlex, sys
text = sys.stdin.read()
stdin_body = None
hd = re.search(r"(?:-F\s*|--file[=\s]\s*)-\s+<<-?\s*([\x27\"]?)([\w.-]+)\1[^\n]*\n(.*?)\n[ \t]*\2[ \t]*(?=\n|$)", text, re.S)
if hd:
    stdin_body = hd.group(3)
    text = text[:hd.start(3)] + text[hd.end():]
try:
    lx = shlex.shlex(text, posix=True, punctuation_chars=";&|")
    lx.whitespace_split = True
    lx.commenters = ""
    w = list(lx)
except ValueError:
    print("UNPARSED"); sys.exit()
msgs, seen_commit, via_file, files = [], False, False, []
for i, a in enumerate(w):
    if a == "commit":
        seen_commit = True; continue
    if not seen_commit:
        continue
    if a in ("-m", "--message") and i + 1 < len(w):
        msgs.append(w[i + 1])
    elif a.startswith("--message="):
        msgs.append(a.split("=", 1)[1])
    elif re.fullmatch(r"-[a-zA-Z]*m", a) and i + 1 < len(w):
        msgs.append(w[i + 1])
    elif a in ("-F", "--file") and i + 1 < len(w):
        via_file = True; files.append(w[i + 1])
    elif a.startswith("--file="):
        via_file = True; files.append(a.split("=", 1)[1])
    elif re.fullmatch(r"-F.+", a):
        via_file = True; files.append(a[2:])
    elif a in (";", "&&", "||", "|", "&"):
        break
for f in files:
    if f == "-":
        if stdin_body is not None:
            msgs.append(stdin_body); continue
        print("FILE:stdin"); sys.exit()
    try:
        with open(f, encoding="utf-8") as fh:
            msgs.append(fh.read())
    except OSError:
        print("FILE:" + f); sys.exit()
if not msgs:
    print("FILE:a file" if via_file else "NONE"); sys.exit()
msg = "\n".join(msgs)
# Unwrap $(cat <<EOF ... EOF) forms: keep the here-doc body.
m = re.search(r"<<-?\s*[\x27\"]?(\w+)[\x27\"]?\s*\n(.*?)\n\s*\1\b", msg, re.S)
if m:
    msg = m.group(2)
first = msg.strip().splitlines()[0] if msg.strip() else ""
problems = []
if not re.match(r"^(feat|fix|perf|refactor|test|docs|chore|security|build|ci|revert|style)(\([a-z0-9._/-]+\))?!?: \S", first):
    problems.append("subject is not Conventional Commits (type(scope): summary)")
if len(first) > 72:
    problems.append("subject longer than 72 characters")
if not re.search(r"^(Story|Task|Refs|Spec|ADR|Incident):\s*\S+", msg, re.M):
    problems.append("no Story:/Task:/Refs:/Spec:/ADR:/Incident: reference in the body")
print("PROBLEMS:" + "; ".join(problems) if problems else "OK")
' 2>/dev/null)
    case "$_VC_MSG_CHECK" in
        PROBLEMS:*) WARNINGS="$WARNINGS\nMESSAGE: ${_VC_MSG_CHECK#PROBLEMS:}." ;;
        FILE:*)     WARNINGS="$WARNINGS\nSKIPPED: commit message comes from ${_VC_MSG_CHECK#FILE:} (-F), which could not be read here, so its format was NOT checked." ;;
        UNPARSED)   WARNINGS="$WARNINGS\nSKIPPED: the commit command could not be tokenised, so the message format was NOT checked." ;;
    esac
fi

# --- 5. Migrations -----------------------------------------------------------
MIG_FILES=$(printf '%s\n' "$STAGED" | grep -E '(^|/)(migrations?|db/migration)/.*\.sql$')
if [ -n "$MIG_FILES" ] && [ -f .claude/scripts/migration-lint.sh ]; then
    _MIG_OUT=$(printf '%s\n' "$MIG_FILES" | tr '\n' '\0' | xargs -0 bash .claude/scripts/migration-lint.sh 2>/dev/null)
    [ -n "$_MIG_OUT" ] && WARNINGS="$WARNINGS\n$(printf '%s' "$_MIG_OUT" | sed 's/^/MIGRATION /')"
fi

# --- 6. Feature specs carry the sections their tier requires ----------------
# The tier is per feature: workflow_overrides.system_overrides.<spec filename
# stem> from project.yaml when set, else the project-wide workflow
# (.claude/docs/workflow-modes.md "Resolution"). Each spec is checked on its
# own so the tier follows the file, and a name with spaces stays one value.
SPEC_FILES=$(printf '%s\n' "$STAGED" | grep -E '^design/specs/[^/]+\.md$' | grep -vE '/(domain-map|spec-cross-review-[^/]*)\.md$')
if [ -n "$SPEC_FILES" ] && [ -f .claude/scripts/spec-structure-check.sh ]; then
    WORKFLOW="minimal"
    if [ "$_VC_HELPER" = 1 ]; then
        _W=$(resolve_setting modes.workflow 2>/dev/null | cut -f1)
        [ -n "$_W" ] && WORKFLOW="$_W"
    fi
    while IFS= read -r _SPEC; do
        [ -n "$_SPEC" ] || continue
        _TIER="$WORKFLOW"
        if [ "$_VC_HELPER" = 1 ] && [ -f project.yaml ]; then
            _STEM=$(basename "$_SPEC" .md)
            case "$_STEM" in
                *[!A-Za-z0-9._-]*) ;;   # a key with spaces or odd characters cannot be a YAML path
                *) _O=$(get_yaml_key project.yaml "workflow_overrides.system_overrides.$_STEM" 2>/dev/null | head -1)
                   case "$_O" in minimal|standard|full) _TIER="$_O" ;; esac ;;
            esac
        fi
        # Required sets per .claude/docs/workflow-modes.md. Flags and the Edge
        # Cases conditional are judged by /spec-review and /gate-check, which can
        # read the spec's meaning; this is the floor.
        case "$_TIER" in
            full)     REQUIRED="Overview,User Value,Detailed Behaviour,Data & Contracts,Edge Cases & Failure Modes,Dependencies,Non-Functional Requirements,Acceptance Criteria" ;;
            standard) REQUIRED="Overview,Detailed Behaviour,Data & Contracts,Non-Functional Requirements,Acceptance Criteria" ;;
            *)        REQUIRED="" ;;
        esac
        [ -n "$REQUIRED" ] || continue
        # The checker prints "<basename> ABSENT:  a, b": split at the marker, never at
        # whitespace, so a filename containing spaces is kept whole.
        _SPEC_OUT=$(bash .claude/scripts/spec-structure-check.sh "$_SPEC" 2>/dev/null \
          | awk -v req="$REQUIRED" -v wf="$_TIER" -v path="$_SPEC" '
              BEGIN { n = split(req, r, ",") }
              { i0 = index($0, " ABSENT:"); if (i0 == 0) next
                list = substr($0, i0 + 8); gsub(/^[ \t]+/, "", list); m = split(list, a, ",")
                miss = ""
                for (i = 1; i <= m; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); for (j = 1; j <= n; j++) if (a[i] == r[j]) miss = miss (miss ? ", " : "") a[i] }
                if (miss) print "SPEC: " path " lacks section(s) required at workflow=" wf ": " miss }')
        [ -n "$_SPEC_OUT" ] && WARNINGS="$WARNINGS\n$_SPEC_OUT"
    done <<< "$SPEC_FILES"
fi

# --- 7. Source-level scans across every code root ----------------------------
CODE_ROOTS=""
[ "$_VC_HELPER" = 1 ] && CODE_ROOTS=$(resolve_code_root 2>/dev/null | cut -f1)
_SRC_RE='\.(go|kt|kts|swift|ts|tsx|astro)$'
if [ -z "$CODE_ROOTS" ]; then
    if printf '%s\n' "$STAGED" | grep -qE "$_SRC_RE"; then
        WARNINGS="$WARNINGS\nSKIPPED: source files are staged but no code root resolved (layout.code_roots unset and no backend/ web/ site/ mobile/ contracts/ dir found). gofmt, debug-output, hardcoded-value and TODO scans did NOT run."
    fi
else
    _ROOT_RE="^($(printf '%s' "$CODE_ROOTS" | tr ' ' '|'))/"
    CODE_FILES=$(printf '%s\n' "$STAGED" | grep -E "$_ROOT_RE" | grep -E "$_SRC_RE" | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done)
    PROD_FILES=$(printf '%s\n' "$CODE_FILES" | grep -vE '(_test\.go|\.test\.tsx?|Tests?\.(kt|swift)|/src/(test|integrationTest|commonTest|androidTest)/|/e2e/|/testdata/|/fixtures/)')

    # gofmt is fast enough for a commit hook; heavier linters run in CI and at push.
    GO_FILES=$(printf '%s\n' "$CODE_FILES" | grep -E '\.go$')
    if [ -n "$GO_FILES" ]; then
        if command -v gofmt >/dev/null 2>&1; then
            _UNFMT=$(printf '%s\n' "$GO_FILES" | tr '\n' '\0' | xargs -0 gofmt -l 2>/dev/null)
            [ -n "$_UNFMT" ] && WARNINGS="$WARNINGS\nFORMAT: not gofmt-formatted: $(printf '%s' "$_UNFMT" | tr '\n' ' ')"
        else
            WARNINGS="$WARNINGS\nSKIPPED: Go files staged but gofmt is not installed — formatting NOT checked."
        fi
    fi

    if [ -n "$PROD_FILES" ]; then
        # Debug output left in production code.
        _DBG=$(printf '%s\n' "$PROD_FILES" | tr '\n' '\0' \
          | xargs -0 grep -lE '(^|[^.[:alnum:]_])(fmt\.Print(ln|f)?\(|console\.(log|debug)\(|println\(|debugPrint\(|print\()' 2>/dev/null || true)
        [ -n "$_DBG" ] && while IFS= read -r f; do
            [ -n "$f" ] && WARNINGS="$WARNINGS\nCODE: $f has debug output (fmt.Print*/console.log/println/print) — use the structured logger."
        done <<< "$_DBG"

        # Business values typed inline instead of config/catalogue.
        _HC=$(printf '%s\n' "$PROD_FILES" | tr '\n' '\0' \
          | xargs -0 grep -liE '(price|amount|quota|max_?seats|seat_?limit|trial_?days|plan_?limit|rate_?limit)[[:space:]]*(:=|=|:)[[:space:]]*[1-9][0-9]*(\.[0-9]+)?([^0-9]|$)' 2>/dev/null || true)
        [ -n "$_HC" ] && while IFS= read -r f; do
            [ -n "$f" ] && WARNINGS="$WARNINGS\nCODE: $f may hardcode a business value (price/quota/limit/trial) — read it from config or the plan catalogue."
        done <<< "$_HC"

        # String-built SQL — the classic injection shape.
        _SQLI=$(printf '%s\n' "$PROD_FILES" | grep -E '\.(go|kt)$' | tr '\n' '\0' \
          | xargs -0 grep -lE '(Sprintf|format)\([^;]*"[[:space:]]*(SELECT|INSERT|UPDATE|DELETE)[[:space:]][^"]*(%[sv]|\{\})|\+[[:space:]]*"[[:space:]]*(WHERE|AND|OR|VALUES|SET|ORDER BY)[[:space:]]|"(SELECT|INSERT|UPDATE|DELETE)[^"]*"[[:space:]]*\+[[:space:]]*[A-Za-z_]|"[^"]*(WHERE|VALUES|SET)[^"]*\$\{?[A-Za-z_]' 2>/dev/null || true)
        [ -n "$_SQLI" ] && while IFS= read -r f; do
            [ -n "$f" ] && WARNINGS="$WARNINGS\nSECURITY: $f may build SQL by string formatting/concatenation — use parameterized queries."
        done <<< "$_SQLI"
    fi

    # TODO/FIXME/HACK must carry an owner or ticket: TODO(name) / TODO(ABC-123).
    if [ -n "$CODE_FILES" ]; then
        _UNOWNED=$(printf '%s\n' "$CODE_FILES" | tr '\n' '\0' | xargs -0 grep -lE '(TODO|FIXME|HACK)[^(]' 2>/dev/null || true)
        [ -n "$_UNOWNED" ] && while IFS= read -r f; do
            [ -n "$f" ] && WARNINGS="$WARNINGS\nSTYLE: $f has TODO/FIXME/HACK without owner — use TODO(name) or TODO(TICKET-123)."
        done <<< "$_UNOWNED"
    fi
fi

# Warnings allow the commit. They go out as hook JSON: stderr on exit 0 reaches
# the debug log only. stderr stays as the fallback when the helper did not load.
if [ -n "$WARNINGS" ]; then
    _VC_OUT=$(printf '%b' "=== Commit Validation Warnings ===$WARNINGS\n================================")
    if command -v hook_warn >/dev/null 2>&1; then
        hook_warn PreToolUse "$_VC_OUT"
    else
        printf '%s\n' "$_VC_OUT" >&2
    fi
fi

exit 0
