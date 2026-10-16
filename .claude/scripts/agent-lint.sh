#!/usr/bin/env bash
# agent-lint.sh — observations about .claude/agents/*.md against
# .claude/docs/agent-roster.md and agent-template.md. Never a verdict; exit 0.
#
# Checks per studio agent:
#   - frontmatter has name/description/tools/model/maxTurns/memory; name == filename
#   - model matches the roster
#   - Agent(...) targets exist in the roster, and match the roster's list
#   - every backticked agent-looking name in "## Delegation" exists in the roster
#   - the Collaboration Protocol block is identical to the template's
#   - required sections present; length within 90–220 lines
# Also: roster agents with no file, and files not in the roster (vendored
# impeccable-* agents are exempt).
#
# Usage: bash .claude/scripts/agent-lint.sh [agent-name ...]

set -u
cd "$(dirname "$0")/../.." || exit 0
PY=""
for c in python3 python py; do command -v "$c" >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -z "$PY" ] && { echo "SKIPPED  no Python 3 — agent lint did not run"; exit 0; }

"$PY" - "$@" <<'PYEOF'
import os, re, sys
ROSTER = ".claude/docs/agent-roster.md"
TEMPLATE = ".claude/docs/agent-template.md"
roster, roster_agents = {}, {}
for line in open(ROSTER, encoding="utf-8"):
    m = re.match(r"^\|\s*`([a-z0-9-]+)`\s*\|\s*(opus|inherit|sonnet)\s*\|\s*([^|]*)\|", line)
    if m:
        name, model, tools = m.groups()
        roster[name] = model
        a = re.search(r"Agent\(([^)]*)\)", tools)
        roster_agents[name] = None if not a else sorted(x.strip() for x in a.group(1).split(",") if x.strip())
tmpl = open(TEMPLATE, encoding="utf-8").read()
m = re.search(r"```markdown\n(## Collaboration Protocol\n.*?)```", tmpl, re.S)
protocol = m.group(1).strip() if m else None

only = set(sys.argv[1:])
files = sorted(f[:-3] for f in os.listdir(".claude/agents") if f.endswith(".md"))
REQ = ["## Read First", "## Collaboration Protocol", "## Responsibilities", "## Must Not", "## Delegation"]
issues = 0
def say(level, agent, msg):
    global issues
    issues += level != "OK"
    print(f"{level:<7} {agent}: {msg}")

for name in files:
    if name.startswith("impeccable-") or (only and name not in only):
        continue
    text = open(f".claude/agents/{name}.md", encoding="utf-8").read()
    fm = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not fm:
        say("ERROR", name, "no frontmatter"); continue
    meta = dict(re.findall(r"^([a-zA-Z]+):\s*(.*)$", fm.group(1), re.M))
    for k in ("name", "description", "tools", "model", "maxTurns", "memory"):
        if k not in meta: say("WARN", name, f"frontmatter missing `{k}`")
    if meta.get("name") != name: say("ERROR", name, f"name `{meta.get('name')}` != filename")
    if name not in roster:
        say("WARN", name, "not in agent-roster.md"); continue
    if meta.get("model") != roster[name]: say("ERROR", name, f"model `{meta.get('model')}` != roster `{roster[name]}`")
    a = re.search(r"Agent\(([^)]*)\)", meta.get("tools", ""))
    got = None if not a else sorted(x.strip() for x in a.group(1).split(",") if x.strip())
    if got != roster_agents[name]:
        say("ERROR", name, f"Agent() targets {got} != roster {roster_agents[name]}")
    for t in got or []:
        if t not in roster: say("ERROR", name, f"Agent() target `{t}` is not a roster agent")
    d = re.search(r"## Delegation\n(.*?)(\n## |\Z)", text, re.S)
    if d:
        for ref in set(re.findall(r"`([a-z][a-z0-9]+(?:-[a-z0-9]+)+)`", d.group(1))):
            if ref not in roster and not ref.startswith("impeccable-") and not ref.startswith("saas-core"):
                say("WARN", name, f"Delegation names `{ref}`, not a roster agent")
    for sec in REQ:
        if sec not in text: say("WARN", name, f"missing section `{sec}`")
    if not re.search(r"## Senior Bar|## Senior bar", text) and name != "studio-orchestrator":
        say("WARN", name, "missing `## Senior Bar`")
    p = re.search(r"(## Collaboration Protocol\n.*?)(?=\n## )", text, re.S)
    if protocol and (not p or p.group(1).strip() != protocol):
        say("WARN", name, "Collaboration Protocol differs from the template block")
    n = text.count("\n")
    if n < 90 or n > 220: say("INFO", name, f"{n} lines (target 90–220)")

if not only:
    for name in sorted(roster):
        if name not in files: say("MISSING", name, "in roster, no file")
print(f"--- {issues} observation(s)")
PYEOF
exit 0
