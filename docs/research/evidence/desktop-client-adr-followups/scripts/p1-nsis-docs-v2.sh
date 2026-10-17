#!/usr/bin/env bash
# Tier-E probe v2 (v1 matched .changeset files, see p1-nsis-docs.out.txt: wrong filter). Reads the saved tree.json from v1,
# picks docs paths under website/docs or docs/ whose name contains nsis, fetches them, greps install/uninstall options.
# Usage: p1-nsis-docs-v2.sh <outdir-with-tree.json>   (run 2026-10-17)
set -u
out="$1"
date -u +"run at %Y-%m-%dT%H:%M:%SZ"
grep -o '"path": *"[^"]*"' "$out/tree.json" | sed 's/"path": *"//;s/"$//' | grep -i 'nsis' | grep -v '^\.changeset' | grep -i '\.md$' | head -10
for p in $(grep -o '"path": *"[^"]*"' "$out/tree.json" | sed 's/"path": *"//;s/"$//' | grep -i 'nsis' | grep -v '^\.changeset' | grep -i 'docs.*\.md$' | head -3); do
  f="$out/$(basename $p)"
  curl -sS -m 30 "https://raw.githubusercontent.com/electron-userland/electron-builder/master/$p" -o "$f" -w "$p http=%{http_code}\n"
  grep -n -i "deleteAppDataOnUninstall\|oneClick\|perMachine\|allowElevation\|/allusers\|/currentuser\|HKCU\|HKLM\|uninstall" "$f" | cut -c1-400 | head -40
done
