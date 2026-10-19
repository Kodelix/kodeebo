#!/usr/bin/env bash
# S18 (tier-E): save RFC 9700 (plain text) and grep it for the device grant, to settle F109
# (characters 100,000-124,665 were not read through the summarising tool).
# Usage: bash s18_rfc9700_grep.sh <evidence-dir>
# HEAD first (size), download capped at 3 MB.
set -u
ev="$1"
url="https://www.rfc-editor.org/rfc/rfc9700.txt"
mkdir -p "$ev/fetched/rfc9700"
curl -sIL --max-time 30 "$url" | grep -i -E '^(HTTP|content-length|content-type)' || echo "no headers"
curl -sSL --max-time 60 --max-filesize 3000000 -o "$ev/fetched/rfc9700/rfc9700.txt" "$url"
echo "curl exit: $?"
wc -c "$ev/fetched/rfc9700/rfc9700.txt"
sha256sum "$ev/fetched/rfc9700/rfc9700.txt"
for pat in "8628" "[Dd]evice [Aa]uthorization" "[Dd]evice [Cc]ode" "[Dd]evice [Gg]rant" "user code" "cross-device" "RFC 8628" "device flow"; do
  echo "== grep -c '$pat' =="
  grep -c -E "$pat" "$ev/fetched/rfc9700/rfc9700.txt"
done
echo "== lines matching 8628 or device authorization (with context) =="
grep -n -i -B2 -A4 -E "8628|device authorization|device code|device flow" "$ev/fetched/rfc9700/rfc9700.txt" | head -60
