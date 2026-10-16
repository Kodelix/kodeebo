#!/usr/bin/env bash
# Part 4 evidence: latest stable Tauri 2.x core release and updater plugin 2.x release.
for spec in "tauri-apps/tauri tauri-v2\\." "tauri-apps/plugins-workspace ^updater-v2\\." "tauri-apps/plugins-workspace ^updater-v"; do
  set -- $spec
  for page in 1 2 3; do
  curl -sS -m 30 "https://api.github.com/repos/$1/releases?per_page=100&page=$page"
  done | python3 -I -c '
import sys,json,re
txt=sys.stdin.read()
dec=json.JSONDecoder(); i=0; items=[]
while i < len(txt):
    while i < len(txt) and txt[i].isspace(): i+=1
    if i>=len(txt): break
    o,j=dec.raw_decode(txt,i); i=j
    if isinstance(o,list): items+=o
pat=sys.argv[1]
c=[(x["published_at"],x["tag_name"],x["prerelease"]) for x in items if re.search(pat,x["tag_name"])]
c.sort(reverse=True)
print("pattern",pat,"count",len(c))
for r in c[:4]: print(r)
' "$2"
done
date -u +"run at %Y-%m-%dT%H:%MZ"
