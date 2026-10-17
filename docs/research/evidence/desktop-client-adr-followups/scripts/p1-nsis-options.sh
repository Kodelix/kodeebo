#!/usr/bin/env bash
# Tier-E probe: fetch electron-builder NsisOptions.ts (doc comments of deleteAppDataOnUninstall, perMachine, oneClick, allowElevation).
# Usage: p1-nsis-options.sh <outdir>   (run 2026-10-17; tree.json from p1-nsis-docs.sh listed the path)
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%M:%SZ"
p=$(grep -o '"path": *"[^"]*"' "$(dirname "$0")/../fetched/nsis/tree.json" | sed 's/"path": *"//;s/"$//' | grep -i 'NsisOptions\.ts$' | head -1)
echo "path: $p"
curl -sS -m 30 "https://raw.githubusercontent.com/electron-userland/electron-builder/master/$p" -o "$out/NsisOptions.ts" -w "http=%{http_code}\n"
grep -n -B6 -i "deleteAppDataOnUninstall\|readonly perMachine\|readonly oneClick\|readonly allowElevation\|readonly guid" "$out/NsisOptions.ts" | cut -c1-300 | head -80
