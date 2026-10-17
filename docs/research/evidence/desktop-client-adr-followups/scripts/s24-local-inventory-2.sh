#!/usr/bin/env bash
# S24 (part 2): second read-only inventory: Electron dist file list (ffmpeg.dll?), MIT clause check, FFmpeg/other LGPL excerpts, runtime A jar list from the spike's a-compose.tar and artifacts.
# Lists and reads text only; nothing from the cache is executed or extracted outside <outdir>.
# Usage: s24-local-inventory-2.sh <spike-cache-dir> <outdir>   (outdir new/empty)
set -u
cache="$1"; out="$2"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
echo "== electron-dist top files (name size)"; ls -l "$cache/build-b/electron-dist" | awk '{print $5, $9}' | sort -k2 | head -50
echo "== Electron LICENSE: key clause present?"; grep -n -i 'included in all copies\|WITHOUT WARRANTY\|without warranty' "$cache/build-b/electron-dist/LICENSE" | head
echo "== node_modules/better-sqlite3-multiple-ciphers/deps (SQLite3MC bundled?)"; ls "$cache/build-b/node_modules/better-sqlite3-multiple-ciphers/deps" 2>/dev/null | head; ls "$cache/build-b/node_modules/better-sqlite3-multiple-ciphers/build/Release" 2>/dev/null | head
echo "== native files in production tree: .node/.dll"; find "$cache/build-b/node_modules/better-sqlite3-multiple-ciphers" "$cache/build-b/node_modules/koffi" -maxdepth 4 \( -name '*.node' -o -name '*.dll' \) 2>/dev/null | head -20
echo "== a-compose.tar listing (jars, runtime, legal)"; tar -tf "$cache/a-compose.tar" 2>/dev/null | grep -iE '\.jar$|/legal/|LICENSE|NOTICE|\.msi$|\.dll$' | head -80
echo "== artifacts dir"; ls -1 "$cache/artifacts" | head -30
echo "== FFmpeg and other excerpts from chromium notices"
python3 -I - "$cache/build-b/electron-dist/LICENSES.chromium.html" "$out" <<'PY'
import re, sys, html
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
prods = re.findall(r'<div class="product">\s*<span class="title">(.*?)</span>(.*?)(?=<div class="product">|$)', src, flags=re.S)
want = ["ffmpeg", "WebKit", "Mozilla Windows Cert code", "hunspell", "Node.js", "icu", "ISimpleDOM COM interfaces for accessibility", "Braille Translation Library", "DirectX-Shader-Compiler"]
for t, b in prods:
    tt = html.unescape(t).strip()
    if tt in want:
        s = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", b)))
        hp = re.search(r'href="([^"]+)"', b)
        print("*", tt, "| homepage:", hp.group(1) if hp else None, "| len", len(s), "|", s[:420])
PY
