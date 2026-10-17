#!/usr/bin/env bash
# S58 (part 5): version and advisories for the HarfBuzz, FreeType and ICU commits pinned by Skia m150-a3f509bf52 (F521).
#  1. identify the nearest release for each commit (GitHub compare / googlesource header files)
#  2. OSV commit queries for the three commits
#  3. GitHub repo security-advisory lists (harfbuzz/harfbuzz, unicode-org/icu, freetype/freetype, google/skia)
# Run: bash scripts/p5-s58-skia-natives-advisories.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run %Y-%m-%dT%H:%MZ"
HB=9cb1fee51069b206effb4736e443b038d230789d; FT=264b5fbf5b912b39f98d038bf75d39be0a73f21b; ICU=364118a1d9da24bb5b770ac3d762ac144d6da5a4
gh_api() { if command -v gh >/dev/null; then gh api "$1" 2>"$2.err"; else curl -sSL -m 60 -H 'Accept: application/vnd.github+json' "https://api.github.com/$1" 2>"$2.err"; fi; }
echo "--- HarfBuzz commit $HB"
gh_api "repos/harfbuzz/harfbuzz/commits/$HB" "$out/hb-commit" > "$out/hb-commit.json"
python3 -I -c "import json,sys; d=json.load(open('$out/hb-commit.json')); print('commit date', d['commit']['committer']['date'], '|', d['commit']['message'].splitlines()[0])" 2>&1 | head -3
gh_api "repos/harfbuzz/harfbuzz/releases?per_page=12" "$out/hb-releases" > "$out/hb-releases.json"
python3 -I - "$out/hb-releases.json" <<'PY' > "$out/hb-tags.txt"
import json,sys
for r in json.load(open(sys.argv[1])): print(r["tag_name"], r["published_at"])
PY
cat "$out/hb-tags.txt"
for t in $(awk '{print $1}' "$out/hb-tags.txt" | head -6); do
  gh_api "repos/harfbuzz/harfbuzz/compare/$t...$HB" "$out/hb-cmp-$t" > "$out/hb-cmp-$t.json"
  python3 -I -c "import json; d=json.load(open('$out/hb-cmp-$t.json')); print('$t...HB:', d.get('status'), 'ahead_by', d.get('ahead_by'), 'behind_by', d.get('behind_by'))" 2>&1 | head -2
done
echo "--- FreeType (Chromium mirror) $FT: header version"
curl -sSL -m 60 "https://chromium.googlesource.com/chromium/src/third_party/freetype2/+/$FT/include/freetype/freetype.h?format=TEXT" | base64 -d 2>/dev/null | grep -E "define FREETYPE_(MAJOR|MINOR|PATCH)" | tee "$out/ft-version.txt"
curl -sSL -m 60 "https://chromium.googlesource.com/chromium/src/third_party/freetype2/+/$FT?format=JSON" | tail -n +2 > "$out/ft-commit.json"
python3 -I -c "import json; d=json.load(open('$out/ft-commit.json')); print('FT commit', d['committer']['time'], '|', d['message'].splitlines()[0])" 2>&1 | head -2
echo "--- ICU (Chromium deps/icu) $ICU: version header"
curl -sSL -m 60 "https://chromium.googlesource.com/chromium/deps/icu.git/+/$ICU/source/common/unicode/uvernum.h?format=TEXT" | base64 -d 2>/dev/null | grep -E "define U_ICU_VERSION(_MAJOR_NUM| )|define U_ICU_VERSION_MAJOR_NUM|define U_ICU_VERSION " | tee "$out/icu-version.txt"
curl -sSL -m 60 "https://chromium.googlesource.com/chromium/deps/icu.git/+/$ICU?format=JSON" | tail -n +2 > "$out/icu-commit.json"
python3 -I -c "import json; d=json.load(open('$out/icu-commit.json')); print('ICU commit', d['committer']['time'], '|', d['message'].splitlines()[0])" 2>&1 | head -2
echo "--- OSV commit queries"
for c in "harfbuzz $HB" "freetype $FT" "icu $ICU"; do
  set -- $c
  curl -sS -m 60 -X POST https://api.osv.dev/v1/query -d "{\"commit\":\"$2\"}" -o "$out/osv-commit-$1.json" -w "OSV commit $1 HTTP %{http_code} %{size_download} bytes\n"
  python3 -I -c "import json; d=json.load(open('$out/osv-commit-$1.json')); v=d.get('vulns',[]); print('  vulns:', len(v), [x['id'] for x in v][:25])"
done
echo "--- GitHub repository security advisories (published)"
for r in harfbuzz/harfbuzz unicode-org/icu freetype/freetype google/skia; do
  f="$out/ghsa-$(echo $r | tr / _).json"
  gh_api "repos/$r/security-advisories?state=published&per_page=100" "$f" > "$f"
  python3 -I -c "import json; d=json.load(open('$f')); print('$r published advisories:', len(d) if isinstance(d,list) else d)" 2>&1 | head -2
done
