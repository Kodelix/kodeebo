#!/usr/bin/env bash
# Part 4 evidence: latest stable GitHub release tag and date for each tool named in the note.
# Usage: part4-latest-releases.sh > output file. Unauthenticated GitHub REST API (tier 3 data, fetched by tier-E script).
for r in electron/electron electron-userland/electron-builder tauri-apps/tauri tauri-apps/plugins-workspace velopack/velopack wixtoolset/wix jrsoftware/issrc Squirrel/Squirrel.Windows wailsapp/wails fyne-io/fyne microsoft/WindowsAppSDK microsoft/winget-cli JetBrains/compose-multiplatform packaging-tool/placeholder sparkle-project/winsparkle vslavik/winsparkle; do
  out=$(curl -sS -m 30 "https://api.github.com/repos/$r/releases/latest" 2>&1)
  tag=$(printf '%s' "$out" | python3 -I -c 'import sys,json
try:
 d=json.load(sys.stdin); print(d.get("tag_name","NONE"), d.get("published_at","-"), d.get("prerelease"))
except Exception as e: print("ERR",e)')
  echo "$r $tag"
done
date -u +"run at %Y-%m-%dT%H:%MZ"
