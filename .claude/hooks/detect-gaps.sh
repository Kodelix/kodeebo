#!/bin/bash
# Hook: detect-gaps.sh
# Event: SessionStart
# Purpose: surface missing product/engineering artifacts relative to what
# already exists on disk. OBSERVATIONS, never verdicts: every line names what
# was compared and suggests a skill; nothing is blocked.

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

[ -f .claude/hooks/yaml-helper.sh ] && . .claude/hooks/yaml-helper.sh 2>/dev/null
have_helper=0; command -v get_yaml_key >/dev/null 2>&1 && have_helper=1

_k() { [ "$have_helper" = 1 ] && [ -f project.yaml ] && get_yaml_key project.yaml "$1" 2>/dev/null; }
BACKEND=$(_k stack.backend)
WEB=$(_k stack.web)
MOBILE=$(_k stack.mobile)

ROOTS=""
command -v resolve_code_root >/dev/null 2>&1 && ROOTS=$(resolve_code_root 2>/dev/null | cut -f1)

count_src() {
    local n=0 r c
    for r in $ROOTS; do
        [ -d "$r" ] || continue
        c=$(find "$r" -type d \( -name node_modules -o -name build -o -name .gradle -o -name dist \) -prune -o \
              -type f \( -name '*.go' -o -name '*.kt' -o -name '*.swift' -o -name '*.ts' -o -name '*.tsx' \) -print 2>/dev/null \
              | head -n 200 | wc -l | tr -d ' ')
        n=$((n + c))
    done
    echo "$n"
}
SRC=$(count_src)

echo "=== Checking for Gaps ==="
GAPS=0
gap() { GAPS=$((GAPS + 1)); echo ""; echo "⚠️  $1"; shift; for l in "$@"; do echo "    $l"; done; }

# --- 0a. Stray nested .claude/ trees (checked before the fresh-project exit) -----------------------------------------
# An agent spawned away from the root leaves .claude/agent-memory/ there, and
# old hooks then wrote session logs beside it (dogfood #40, #41). Searched across
# the repository, caches and build output pruned. Observation only.
STRAY=$(find . \( -path ./.git -o -path "*/node_modules" -o -path "*/build" -o -path ./production/session-state/cache \) -prune \
    -o -type d -name .claude -print 2>/dev/null | grep -vx "./.claude" | head -5)
if [ -n "$STRAY" ]; then
    gap "Stray .claude/ folder(s) outside the project root's own: $(printf '%s ' $STRAY)" \
        "Move agent memory to .claude/agent-memory/<agent>/, delete stray session logs, then remove the folder. Run commands from the project root."
fi

# --- 0. Fresh project -------------------------------------------------------
if [ -z "$BACKEND" ] && [ ! -f design/product-brief.md ] && [ "$SRC" = 0 ]; then
    echo ""
    echo "🚀 NEW PROJECT: no stack configured, no product brief, no code."
    echo "   Run: /studio <what you want to build>   (or /start for guided onboarding)"
    echo "==================================="
    exit 0
fi

# --- workflow tier -----------------------------------------------------------
WORKFLOW="minimal"
if command -v resolve_setting >/dev/null 2>&1; then
    _w=$(resolve_setting modes.workflow 2>/dev/null | cut -f1); [ -n "$_w" ] && WORKFLOW="$_w"
fi

# --- 1. Stack not configured but code exists --------------------------------
if [ -z "$BACKEND" ] && [ "$SRC" -gt 0 ]; then
    gap "Code exists ($SRC+ source files) but stack.backend is not set in project.yaml." \
        "Agents cannot route work or load the right stack reference." \
        "Suggested: /setup-stack (or /adopt for an existing codebase)"
fi
if [ -z "$ROOTS" ] && [ -n "$BACKEND" ]; then
    gap "NOT CHECKED: no code root resolved (layout.code_roots unset, no conventional dirs)." \
        "Checks 3–7 below did NOT run." \
        "Suggested: set layout.code_roots in project.yaml"
fi

# --- 2. Product brief ---------------------------------------------------------
if [ "$SRC" -gt 0 ] && [ ! -f design/product-brief.md ]; then
    gap "Code exists but design/product-brief.md is missing (required at every workflow tier)." \
        "Suggested: /brainstorm, or /reverse-document brief"
fi

# --- 3. Bounded contexts without research notes (gate 1) ---------------------
if [ -d backend/internal ] || [ -d backend/src/main/kotlin ]; then
    # Parameter expansion, not `xargs -r dirname/basename`: -r is a GNU-ism.
    CTX=$( { find backend/internal -mindepth 1 -maxdepth 1 -type d 2>/dev/null
             find backend/src/main/kotlin -mindepth 2 -maxdepth 3 -type d -name domain 2>/dev/null \
               | while IFS= read -r d; do printf '%s\n' "${d%/*}"; done; } \
           | while IFS= read -r d; do printf '%s\n' "${d##*/}"; done \
           | grep -vxE 'platform|shared|common|config|internal' | sort -u)
    MISSING=""
    for c in $CTX; do
        found=false
        for n in docs/research/*; do
            case "$(printf '%s' "${n##*/}" | tr '[:upper:]' '[:lower:]')" in
                *"$(printf '%s' "$c" | tr '[:upper:]' '[:lower:]')"*) found=true; break ;;
            esac
        done
        [ "$found" = true ] || MISSING="$MISSING $c"
    done
    [ -n "$MISSING" ] && gap "Bounded context(s) with code but no research note in docs/research/:$MISSING" \
        "DoD gate 1 (research before implementation)." \
        "Suggested: /research <context>  — or /reverse-document research <context> for existing code"
fi

# --- 4. API code without a contract -----------------------------------------
if [ -n "$BACKEND" ] && [ "$SRC" -gt 0 ]; then
    if ! find contracts -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.proto' \) 2>/dev/null | grep -q .; then
        gap "Backend code exists but contracts/ has no OpenAPI/proto files." \
            "Clients cannot be generated and contract tests cannot run." \
            "Suggested: /api-contract"
    fi
fi

# --- 5. Engineering baselines --------------------------------------------------
if [ "$SRC" -gt 0 ]; then
    [ -f docs/architecture/perf-budgets.md ] || gap "No docs/architecture/perf-budgets.md — DoD gate 6 has nothing to measure against." \
        "Suggested: /perf-profile budgets (defaults in .claude/docs/performance-standard.md)"
    SENSITIVE=$(find $ROOTS -type d \( -name auth -o -name identity -o -name billing -o -name licensing -o -name tenancy \) \
                  -not -path '*/node_modules/*' 2>/dev/null | head -5)
    if [ -n "$SENSITIVE" ] && ! ls docs/architecture/threat-models/*.md >/dev/null 2>&1; then
        gap "Security-sensitive code exists ($(printf '%s' "$SENSITIVE" | tr '\n' ' ')) but no threat model in docs/architecture/threat-models/." \
            "Suggested: /threat-model <feature>"
    fi
fi
STAGE=$(_k project.stage)
case "$STAGE" in Hardening|Release|Live)
    [ -f docs/architecture/slos.md ] || gap "Stage is $STAGE but docs/architecture/slos.md is missing — alerts have no SLO to burn against." \
        "Suggested: /observability-plan"
    ls docs/runbooks/*.md >/dev/null 2>&1 || gap "Stage is $STAGE but docs/runbooks/ is empty — every alert needs a runbook." \
        "Suggested: /observability-plan runbooks" ;;
esac

# --- 6. UI without impeccable product context --------------------------------
if { [ -n "$WEB" ] && [ "$WEB" != none ]; } || { [ -n "$MOBILE" ] && [ "$MOBILE" != none ]; }; then
    if [ ! -f PRODUCT.md ]; then
        gap "UI layers are configured but no PRODUCT.md (impeccable's design context) exists." \
            "Suggested: /impeccable init  (it writes PRODUCT.md at the project root)"
    fi
fi

# --- 7. Specs expected at this tier ------------------------------------------
if [ "$WORKFLOW" != minimal ] && [ "$SRC" -gt 20 ]; then
    NSPEC=$(find design/specs -maxdepth 1 -name '*.md' -type f 2>/dev/null | grep -vcE '/(domain-map|spec-cross-review-[^/]*)\.md$')
    [ "${NSPEC:-0}" -lt 1 ] && gap "workflow=$WORKFLOW and $SRC+ source files, but design/specs/ has no feature specs." \
        "Suggested: /reverse-document spec <feature>"
fi

# --- 8. Prototypes without README --------------------------------------------
if [ -d prototypes ]; then
    for d in prototypes/*/; do
        [ -d "$d" ] || continue
        [ -f "$d/README.md" ] || gap "Prototype ${d%/} has no README.md (hypothesis, how to run, findings)." \
            "Suggested: /reverse-document concept ${d%/}"
    done
fi

[ "$GAPS" = 0 ] && echo "No gaps detected."
echo "==================================="
exit 0
