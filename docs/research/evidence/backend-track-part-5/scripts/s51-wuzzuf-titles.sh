#!/bin/sh
# S51: fetch the public Wuzzuf skill landing pages and save the HTML <title> and the h1 count text.
# usage: s51-wuzzuf-titles.sh <outdir>
out="$1"
for slug in Kotlin Golang Go TypeScript Ktor Android Java Node-js React; do
  f="$out/$slug.html"
  code=$(curl -sS -m 40 -A "Mozilla/5.0 (research; one-off count)" -o "$f" -w '%{http_code}' "https://wuzzuf.net/a/$slug-Jobs-in-Egypt")
  title=$(grep -o '<title>[^<]*</title>' "$f" | head -1)
  echo "$slug http=$code bytes=$(wc -c <"$f") $title"
done
