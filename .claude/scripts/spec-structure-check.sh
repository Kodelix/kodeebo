#!/usr/bin/env bash
# spec-structure-check.sh — deterministic section-presence check for feature specs.
#
# Replaces a full-document model read per spec with two lines of output that
# cannot hallucinate a missing section.
#
# REPORTS PRESENCE ONLY — IT DOES NOT JUDGE COMPLETENESS. Which sections are
# required depends on the workflow tier and the feature
# (.claude/docs/workflow-modes.md). The caller applies the tier.
#
# Usage:
#   bash .claude/scripts/spec-structure-check.sh                         # every spec
#   bash .claude/scripts/spec-structure-check.sh design/specs/a.md [...] # named specs
#
# Output (the ABSENT line is omitted when nothing is absent):
#   billing.md PRESENT: Overview,User Value,Detailed Behaviour,...
#   billing.md ABSENT:  Edge Cases & Failure Modes

set -u
# File arguments are relative to the CALLER's directory: anchor them before
# moving to the repo root, or a caller outside the root gets "Not found".
_abs=()
for a in "$@"; do
    case "$a" in /*) _abs+=("$a") ;; *) _abs+=("$PWD/$a") ;; esac
done
set -- ${_abs[@]+"${_abs[@]}"}
cd "$(dirname "$0")/../.." || { echo "spec-structure-check: cannot reach repo root" >&2; exit 1; }

# Each MATCH entry is an ERE alternation of accepted headings for one section;
# LABEL is the canonical name. Aliases keep a conforming spec from reading as
# incomplete because of a wording variant.
MATCH=("Overview" \
       "User Value|Value|Jobs[ -]to[ -]be[ -]done" \
       "Detailed Behaviou?r|Detailed Rules|Behaviou?r" \
       "Data (&|and) Contracts|Data Model|Contracts" \
       "Edge Cases|Failure Modes" \
       "Dependencies" \
       "Non[- ]Functional( Requirements)?|NFRs?" \
       "Acceptance Criteria")
LABEL=("Overview" "User Value" "Detailed Behaviour" "Data & Contracts" \
       "Edge Cases & Failure Modes" "Dependencies" "Non-Functional Requirements" \
       "Acceptance Criteria")

not_a_feature_spec() {
    case "$(basename "$1")" in
        domain-map.md|spec-cross-review-*.md|README.md) return 0 ;;
        *) return 1 ;;
    esac
}

check_file() {
    local f="$1" present="" absent="" i s b
    for i in "${!MATCH[@]}"; do
        s="${MATCH[$i]}"
        if grep -qiE "^##+[[:space:]]+([0-9]+[.)]?[[:space:]]*)?(${s})" "$f"; then
            present="$present,${LABEL[$i]}"
        else
            absent="$absent,${LABEL[$i]}"
        fi
    done
    b="$(basename "$f")"
    echo "$b PRESENT: ${present#,}"
    [ -n "$absent" ] && echo "$b ABSENT:  ${absent#,}"
    return 0
}

if [ $# -gt 0 ]; then
    for f in "$@"; do
        [ -f "$f" ] || { echo "Not found: $f" >&2; continue; }
        not_a_feature_spec "$f" && continue
        check_file "$f"
    done
    exit 0
fi

any=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    not_a_feature_spec "$f" && continue
    any=1
    check_file "$f"
done <<LIST
$(find design/specs -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
LIST
[ "$any" -eq 1 ] || echo "No feature specs found in design/specs/."
