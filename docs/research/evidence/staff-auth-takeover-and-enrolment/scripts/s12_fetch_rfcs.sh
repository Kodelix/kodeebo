#!/usr/bin/env bash
# S12 (tier-E): fetch the plain-text RFC 8628 and RFC 10027 into their own directories so the
# summarised readings (F101-F115) can be checked against verbatim text.
# Size is listed BEFORE the download (HEAD); each download is capped at 3 MB by curl.
# Usage: bash s12_fetch_rfcs.sh <evidence-dir>
set -u
ev="$1"
for rfc in rfc8628 rfc10027; do
  url="https://www.rfc-editor.org/rfc/${rfc}.txt"
  mkdir -p "$ev/fetched/$rfc"
  echo "== $rfc HEAD (size before download) =="
  curl -sIL --max-time 30 "$url" | grep -i -E '^(HTTP|content-length|content-type|last-modified)' || echo "no headers"
  echo "== $rfc download (cap 3000000 bytes) =="
  curl -sSL --max-time 60 --max-filesize 3000000 -o "$ev/fetched/$rfc/$rfc.txt" "$url"
  echo "curl exit: $?"
  wc -c "$ev/fetched/$rfc/$rfc.txt"
  sha256sum "$ev/fetched/$rfc/$rfc.txt"
done
