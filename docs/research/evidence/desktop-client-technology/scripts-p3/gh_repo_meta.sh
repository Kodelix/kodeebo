#!/usr/bin/env bash
# Tier-3 metadata probe (GitHub REST API, unauthenticated). Usage: gh_repo_meta.sh owner/repo ...
# Prints: repo, license SPDX, archived flag, pushed_at, latest release tag + date (or none).
for r in "$@"; do
  m=$(curl -s -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$r")
  rel=$(curl -s -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$r/releases/latest")
  python3 -I - "$r" "$m" "$rel" <<'PY'
import json,sys
r,m,rel=sys.argv[1],json.loads(sys.argv[2]),json.loads(sys.argv[3])
if "full_name" not in m: print(r,"-> not found / rate-limited:",m.get("message")); sys.exit()
lic=(m.get("license") or {}).get("spdx_id")
print(f'{m["full_name"]} | license={lic} | archived={m["archived"]} | pushed_at={m["pushed_at"]} | stars={m["stargazers_count"]} | latest_release={rel.get("tag_name","none")} {rel.get("published_at","")}')
PY
done
