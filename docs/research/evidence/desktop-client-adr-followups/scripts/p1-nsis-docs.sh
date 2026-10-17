#!/usr/bin/env bash
# Tier-E probe: find and fetch electron-builder NSIS docs source (website/docs) and grep install/uninstall options.
# Usage: p1-nsis-docs.sh <outdir>   (run 2026-10-17, unauthenticated GitHub API + raw)
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%M:%SZ"
curl -sS -m 30 "https://api.github.com/repos/electron-userland/electron-builder/git/trees/master?recursive=1" -o "$out/tree.json" -w "tree http=%{http_code}\n"
grep -o '"path": *"[^"]*nsis[^"]*"' "$out/tree.json" | head -20
for p in $(grep -o '"path": *"[^"]*nsis[^"]*\.md"' "$out/tree.json" | sed 's/"path": *"//;s/"$//' | head -3); do
  f="$out/$(basename $p)"
  curl -sS -m 30 "https://raw.githubusercontent.com/electron-userland/electron-builder/master/$p" -o "$f" -w "$p http=%{http_code}\n"
  grep -n -i "deleteAppDataOnUninstall\|oneClick\|perMachine\|allowElevation\|/allusers\|/currentuser\|differentialPackage\|HKCU\|HKLM" "$f" | cut -c1-300 | head -40
done
