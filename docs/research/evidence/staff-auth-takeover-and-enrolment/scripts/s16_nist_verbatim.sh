#!/usr/bin/env bash
# S16 (tier-E): save the NIST SP 800-63B-4 page and print the verbatim text around the binding-code
# figures (40 bits / 112 bits / 10 minutes), the notification rule and the OOB approval rule, to check
# the summarised reading in F118 and F124.
# Usage: bash s16_nist_verbatim.sh <evidence-dir>
# Size is listed (HEAD) before the download; the download is capped at 5 MB by curl.
set -u
ev="$1"
url="https://pages.nist.gov/800-63-4/sp800-63b.html"
mkdir -p "$ev/fetched/nist-800-63b-4"
echo "== HEAD =="
curl -sIL --max-time 30 "$url" | grep -i -E '^(HTTP|content-length|content-type|last-modified)' || echo "no headers"
echo "== download (cap 5000000 bytes) =="
curl -sSL --max-time 90 --max-filesize 5000000 -o "$ev/fetched/nist-800-63b-4/sp800-63b.html" "$url"
echo "curl exit: $?"
wc -c "$ev/fetched/nist-800-63b-4/sp800-63b.html"
sha256sum "$ev/fetched/nist-800-63b-4/sp800-63b.html"
