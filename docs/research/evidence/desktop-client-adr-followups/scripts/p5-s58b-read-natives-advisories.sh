#!/usr/bin/env bash
# S58b (part 5): read the saved S58 data: OSV records returned for the pinned commits, HarfBuzz repo advisories, and find the HarfBuzz release the pinned commit follows (releases page 2 + compare).
# Run: bash scripts/p5-s58b-read-natives-advisories.sh <dir containing S58 output>
set -u
out="$1"; HB=9cb1fee51069b206effb4736e443b038d230789d
date -u +"run %Y-%m-%dT%H:%MZ"
python3 -I - "$out" <<'PY'
import json, sys, glob
out = sys.argv[1]
for name in ("harfbuzz", "freetype"):
    d = json.load(open(f"{out}/osv-commit-{name}.json"))
    for v in d.get("vulns", []):
        print(f"\n== OSV {v['id']} ({name} commit) aliases {v.get('aliases')} published {v.get('published')} modified {v.get('modified')}")
        print("   summary:", (v.get("summary") or "")[:300])
        print("   details:", (v.get("details") or "")[:600].replace("\n", " "))
        for a in v.get("affected", []):
            print("   affected repo/package:", a.get("package") or a.get("ranges", [{}])[0].get("repo"), "| versions listed:", len(a.get("versions", [])), "| ranges:", [(r["type"], r.get("repo"), r["events"]) for r in a.get("ranges", [])])
        print("   severity:", v.get("severity"), "| database_specific:", str(v.get("database_specific"))[:300])
        print("   references:", [r["url"] for r in v.get("references", [])][:6])
d = json.load(open(f"{out}/ghsa-harfbuzz_harfbuzz.json"))
print("\n== harfbuzz/harfbuzz GHSA published:", len(d))
for a in d:
    vul = a.get("vulnerabilities") or []
    print(" ", a["ghsa_id"], a.get("cve_id"), a.get("severity"), a.get("published_at","")[:10], "|", a.get("summary","")[:110], "|", [(v.get("package",{}).get("name"), v.get("vulnerable_version_range"), v.get("patched_versions")) for v in vul])
PY
H='Accept: application/vnd.github+json'
echo "--- harfbuzz releases page 2 and compare"
gh api "repos/harfbuzz/harfbuzz/releases?per_page=12&page=2" 2>/dev/null | python3 -I -c "import json,sys; [print(r['tag_name'], r['published_at']) for r in json.load(sys.stdin)]" | tee "$out/hb-tags-page2.txt"
for t in $(awk '{print $1}' "$out/hb-tags-page2.txt" | head -5); do
  gh api "repos/harfbuzz/harfbuzz/compare/$t...$HB" 2>/dev/null | python3 -I -c "import json,sys; d=json.load(sys.stdin); print('$t ...HB:', d.get('status'), 'ahead_by', d.get('ahead_by'), 'behind_by', d.get('behind_by'))"
done
