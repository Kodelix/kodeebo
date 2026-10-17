#!/bin/bash
# Usage: bash fetch.sh <name> <url>   (run from docs/research/evidence/licensing-part-4/)
# Downloads to work/<name>.raw, records URL, UTC time, HTTP code, size and SHA-256 of the raw bytes in fetched/MANIFEST.tsv,
# writes visible text (HTML) or the file itself (non-HTML) to fetched/<name>.txt, then removes the raw file.
set -u
name="$1"; url="$2"
raw="work/$name.raw"
code=$(curl -sL -A 'Mozilla/5.0 (X11; Linux x86_64) research-fetch' --max-time 60 -o "$raw" -w '%{http_code}' "$url")
sha=$(sha256sum "$raw" | cut -d' ' -f1); size=$(stat -c %s "$raw")
if head -c 5 "$raw" | grep -q '%PDF'; then pdftotext -layout "$raw" "fetched/$name.txt"; elif head -c 2000 "$raw" | grep -qi '<html\|<!doctype'; then python3 -I scripts/html2text.py "$raw" > "fetched/$name.txt"; else cp "$raw" "fetched/$name.txt"; fi
rm -f "$raw"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$(date -u +%Y-%m-%dT%H:%MZ)" "$code" "$size" "$sha" >> fetched/MANIFEST.tsv
echo "$name http=$code bytes=$size sha256=$sha text=$(wc -c < fetched/$name.txt)"
