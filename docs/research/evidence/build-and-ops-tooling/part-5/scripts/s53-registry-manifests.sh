#!/bin/bash
# S53 (area A(b)): read OCI manifests and repository metadata for the Trivy databases WITHOUT downloading any blob.
# Only HTTP GETs of tokens, tag lists, manifests (JSON, a few KB) and GitHub repository metadata.
# Usage: s53-registry-manifests.sh <evidence_dir>
set -u
E="$1"; M="$E/manifests"; mkdir -p "$M"
echo "date_utc: $(date -u +%FT%TZ)"
ACC='application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json'
show() { python3 -I - "$1" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
print(" mediaType:",m.get("mediaType"),"artifactType:",m.get("artifactType"))
a=m.get("annotations",{})
for k in sorted(a): print(" manifest annotation",k,"=",a[k][:120])
if "manifests" in m:
    for x in m["manifests"]: print(" index entry",x.get("mediaType"),x.get("size"),x.get("platform"),x.get("digest"))
tot=0
cfg=m.get("config")
if cfg: print(" config",cfg.get("mediaType"),cfg.get("size"))
for l in m.get("layers",[]):
    tot+=l["size"]; print(" layer",l["mediaType"],"size",l["size"],"annotations",{k:v[:80] for k,v in l.get("annotations",{}).items()})
print(" TOTAL layer bytes:",tot)
PY
}
for spec in "aquasecurity/trivy-db:2" "aquasecurity/trivy-java-db:1" "aquasecurity/trivy-checks:2"; do
  repo=${spec%%:*}; tag=${spec#*:}; f="$M/ghcr.$(echo $repo | tr / _).$tag.json"
  echo; echo "#### ghcr.io/$repo:$tag"
  TOK=$(curl -fsS --max-time 30 "https://ghcr.io/token?service=ghcr.io&scope=repository:$repo:pull" | python3 -I -c 'import json,sys;print(json.load(sys.stdin)["token"])') || { echo "token failed"; continue; }
  curl -sS --max-time 30 -D "$f.headers" -H "Authorization: Bearer $TOK" -H "Accept: $ACC" "https://ghcr.io/v2/$repo/manifests/$tag" -o "$f"; head -1 "$f.headers"; grep -i -E '^(content-type|docker-content-digest|content-length):' "$f.headers" | tr -d '\r'
  show "$f"
  echo " tags:"; curl -sS --max-time 30 -H "Authorization: Bearer $TOK" "https://ghcr.io/v2/$repo/tags/list?n=20" | cut -c1-400
done
for spec in "aquasec/trivy-db:2" "aquasec/trivy-java-db:1" "aquasec/trivy-checks:2"; do
  repo=${spec%%:*}; tag=${spec#*:}; f="$M/mirrorgcr.$(echo $repo | tr / _).$tag.json"
  echo; echo "#### mirror.gcr.io/$repo:$tag (anonymous)"
  curl -sS --max-time 30 -D "$f.headers" -H "Accept: $ACC" "https://mirror.gcr.io/v2/$repo/manifests/$tag" -o "$f"; head -1 "$f.headers"; grep -i -E '^(content-type|docker-content-digest|content-length|www-authenticate):' "$f.headers" | tr -d '\r'
  head -c 300 "$f"; echo
done
for r in trivy trivy-db trivy-java-db trivy-checks vexhub; do
  echo; echo "#### GitHub repo aquasecurity/$r"
  curl -sS --max-time 30 "https://api.github.com/repos/aquasecurity/$r" -o "$M/gh.$r.json"
  python3 -I - "$M/gh.$r.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
print(" full_name",r.get("full_name"),"license",(r.get("license") or {}).get("spdx_id"),(r.get("license") or {}).get("name"),"size_kb",r.get("size"),"pushed_at",r.get("pushed_at"),"archived",r.get("archived"),"default_branch",r.get("default_branch"))
PY
done
