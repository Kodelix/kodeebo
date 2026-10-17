#!/usr/bin/env bash
# S28 (part 2): evaluate every published GitHub security advisory of the vendor repos against the exact shipped versions.
# Inputs: s27's electron-ghsa-list.json (re-used, same day) plus fresh lists for the other repos. Usage: s28-ghsa-range-check.sh <s27-dir> <outdir>
set -u
s27="$1"; out="$2"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
cp "$s27/electron-ghsa-list.json" "$out/electron__electron.json"
for r in electron-userland/electron-builder Willena/sqlite-jdbc-crypt utelle/SQLite3MultipleCiphers java-native-access/jna JetBrains/skiko JetBrains/compose-multiplatform m4heshd/better-sqlite3-multiple-ciphers Koromix/koffi nodejs/node-addon-api; do
  n="$(echo "$r" | sed 's#/#__#')"
  gh api "repos/$r/security-advisories?state=published&per_page=100" > "$out/$n.json" 2> "$out/$n.err" || echo "$r: FAILED $(head -c 160 "$out/$n.err")"
done
python3 -I - "$out" <<'PY'
import json, re, sys, glob, os
out = sys.argv[1]
def parse(v):
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.\-]+))?", v.strip())
    if not m: return None
    core = tuple(int(x) for x in m.groups()[:3]); pre = m.group(4)
    return (core, pre)
def key(v):
    p = parse(v); core, pre = p
    if pre is None: return (core, (1,))
    return (core, (0,) + tuple((0, int(x), "") if x.isdigit() else (1, 0, x) for x in pre.split(".")))
def in_range(version, rng):
    ok = True
    for part in [x.strip() for x in rng.split(",") if x.strip()]:
        m = re.match(r"^(<=|>=|<|>|=)\s*(\S+)$", part)
        if not m: return None
        op, b = m.groups(); a, bb = key(version), key(b)
        ok &= {"<": a < bb, "<=": a <= bb, ">": a > bb, ">=": a >= bb, "=": a == bb}[op]
    return ok
targets = {
 "electron__electron": [("electron", "44.8.0"), ("electron", "44.9.0")],
 "electron-userland__electron-builder": [("electron-updater", "6.8.9"), ("electron-updater", "6.8.10"), ("electron-builder", "26.17.0"), ("app-builder-lib", "26.17.0"), ("builder-util-runtime", "9.7.0"), ("builder-util", "26.16.0"), ("electron-publish", "26.16.0")],
 "Willena__sqlite-jdbc-crypt": [], "utelle__SQLite3MultipleCiphers": [], "java-native-access__jna": [("net.java.dev.jna:jna", "5.19.1")],
 "JetBrains__skiko": [], "JetBrains__compose-multiplatform": [], "m4heshd__better-sqlite3-multiple-ciphers": [("better-sqlite3-multiple-ciphers", "13.0.3")],
 "Koromix__koffi": [("koffi", "2.16.3")], "nodejs__node-addon-api": [("node-addon-api", "8.9.2")],
}
for f in sorted(glob.glob(out + "/*.json")):
    n = os.path.basename(f)[:-5]
    try: data = json.load(open(f))
    except Exception as e: print(n, "UNREADABLE", e); continue
    if not isinstance(data, list): print(n, "not a list:", str(data)[:150]); continue
    print(f"\n== {n}: {len(data)} published advisories; evaluating {targets.get(n)}")
    if not data: print("   (none published)")
    hits = 0
    for a in data:
        for v in a.get("vulnerabilities", []):
            for pkg, ver in targets.get(n, []):
                if v["package"]["name"] == pkg:
                    r = in_range(ver, v.get("vulnerable_version_range") or "")
                    if r:
                        hits += 1; print(f"   AFFECTED {pkg}@{ver}: {a['ghsa_id']} {a.get('cve_id')} {a.get('severity')} | {a['summary'][:100]} | range {v['vulnerable_version_range']} fixed {v.get('patched_versions')}")
                    elif r is None:
                        print(f"   UNPARSED range for {a['ghsa_id']}: {v.get('vulnerable_version_range')}")
    print(f"   hits against shipped versions: {hits}")
    if n != "electron__electron":
        for a in data[:12]:
            print("   -", a["ghsa_id"], a.get("severity"), a.get("published_at", "")[:10], a["summary"][:90], [(v["package"]["name"], v.get("vulnerable_version_range"), v.get("patched_versions")) for v in a.get("vulnerabilities", [])][:2])
# Electron: advisories that touch 44.x at all
d = json.load(open(out + "/electron__electron.json"))
print("\n== Electron advisories with any range overlapping the 44 line (title, range for 44, published)")
for a in sorted(d, key=lambda x: x.get("published_at", "")):
    for v in a.get("vulnerabilities", []):
        r = v.get("vulnerable_version_range") or ""
        if re.search(r"44\.", r):
            print("  ", a["ghsa_id"], a.get("cve_id"), a.get("severity"), a.get("published_at", "")[:10], "|", a["summary"][:80], "|", r, "->", v.get("patched_versions"))
PY
