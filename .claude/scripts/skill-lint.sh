#!/usr/bin/env bash
# skill-lint.sh — observations about .claude/skills/*/SKILL.md against
# .claude/docs/skills-reference.md. Never a verdict; always exit 0.
#
# Per studio skill (vendored `impeccable` exempt):
#   - frontmatter: name, description, model; name == directory
#   - listed in skills-reference.md, and model matches it
#   - every `references/<file>.md` the skill points to exists
#   - every `.claude/docs|rules|scripts|hooks/...` and `docs/...` path it cites
#     exists (templates/gates included), placeholders like <feature> skipped
#   - every backticked agent-like name that looks like an agent exists in the roster
#   - every gate ID (PD-/CTO-/DD-/PE-/PR-/QL-/SL-/SRE-*) has a gate file
#   - no leftover game vocabulary
# Also: reference skills with no directory.
#
# Usage: bash .claude/scripts/skill-lint.sh [skill-name ...]

set -u
cd "$(dirname "$0")/../.." || exit 0
PY=""
for c in python3 python py; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -z "$PY" ] && { echo "SKIPPED  no Python 3 — skill lint did not run"; exit 0; }

"$PY" - "$@" <<'PYEOF'
import os, re, sys, glob
ref = open(".claude/docs/skills-reference.md", encoding="utf-8").read()
expected = {}
for m in re.finditer(r"^\|\s*`/([a-z0-9-]+)`\s*\|\s*[^|]*\|\s*(opus|sonnet|haiku)\s*\|", ref, re.M):
    expected[m.group(1)] = m.group(2)
wave5 = re.search(r"## Wave 5.*", ref, re.S)
w5 = set(re.findall(r"`/([a-z0-9-]+)`", wave5.group(0))) if wave5 else set()
roster = set(re.findall(r"^\|\s*`([a-z0-9-]+)`\s*\|", open(".claude/docs/agent-roster.md", encoding="utf-8").read(), re.M))
gates = {os.path.basename(p)[:-3].upper() for p in glob.glob(".claude/docs/director-gates/*.md")}
GAME = re.compile(r"\b(GDDs?|game[- ](?:design|concept|brief|pillars)|player[- ](?:fantasy|journey)|playtest\w*|Godot|Unity|Unreal|engine\.name|setup-engine|art[- ]bible|creative-director|technical-director|lead-programmer|gameplay-programmer)\b", re.I)
only = set(sys.argv[1:])
issues = 0
def say(level, s, msg):
    global issues
    issues += level not in ("OK", "INFO")
    print(f"{level:<7} {s}: {msg}")

dirs = sorted(d for d in os.listdir(".claude/skills") if os.path.isdir(f".claude/skills/{d}") and d != "impeccable")
for s in dirs:
    if only and s not in only: continue
    p = f".claude/skills/{s}/SKILL.md"
    if not os.path.isfile(p):
        say("ERROR", s, "no SKILL.md"); continue
    text = open(p, encoding="utf-8").read()
    fm = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not fm:
        say("ERROR", s, "no frontmatter"); continue
    meta = dict(re.findall(r"^([a-zA-Z-]+):\s*(.*)$", fm.group(1), re.M))
    for k in ("name", "description", "model"):
        if k not in meta: say("WARN", s, f"frontmatter missing `{k}`")
    if meta.get("name") != s: say("ERROR", s, f"name `{meta.get('name')}` != directory")
    if s in expected:
        if meta.get("model") != expected[s]: say("ERROR", s, f"model `{meta.get('model')}` != reference `{expected[s]}`")
    elif s not in w5:
        say("WARN", s, "not listed in skills-reference.md")
    alltext = text
    for rp in glob.glob(f".claude/skills/{s}/references/**/*.md", recursive=True):
        alltext += "\n" + open(rp, encoding="utf-8").read()
    for r in set(re.findall(r"references/([A-Za-z0-9_./-]+\.md)", alltext)):
        if not os.path.isfile(f".claude/skills/{s}/references/{r}"):
            say("ERROR", s, f"points to missing references/{r}")
    for path in set(re.findall(r"(?<![\w/])((?:\.claude/(?:docs|rules|scripts|hooks)|docs)/[A-Za-z0-9_./-]+\.(?:md|sh|yaml))", alltext)):
        if "<" in path or "*" in path or "NNNN" in path or "YYYY" in path: continue
        if path.startswith("docs/") and not path.startswith(("docs/stack-reference/", "docs/ROADMAP")):
            continue  # product artifacts created at runtime
        if not os.path.exists(path): say("WARN", s, f"cites missing path {path}")
    for name in set(re.findall(r"`([a-z]+(?:-[a-z]+)*-(?:lead|director|engineer|specialist|designer|manager|architect|tester|writer|orchestrator|success|lifecycle|researcher))`", alltext)):
        if name not in roster: say("WARN", s, f"names agent `{name}` not in roster")
    for g in set(re.findall(r"\b((?:PD|CTO|DD|PE|PR|QL|SL|SRE)-[A-Z][A-Z0-9-]+)\b", alltext)):
        if gates and g not in gates: say("WARN", s, f"gate `{g}` has no file in director-gates/")
    hits = sorted({m.group(0) for m in GAME.finditer(alltext)})
    if hits: say("WARN", s, f"game vocabulary: {', '.join(hits[:6])}")

if not only:
    for s in sorted(expected):
        if s not in dirs: say("MISSING", s, "in skills-reference, no directory")
print(f"--- {issues} observation(s)")
PYEOF
exit 0
