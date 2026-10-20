#!/usr/bin/env bash
# S22 (tier 2 official-docs extraction by script): Kafka current version and doc passages. Page copies go to the gitignored cache dir ($1); only grep excerpts are printed.
# Run: bash S22-kafka-docs.sh production/session-state/cache/jobs-and-outbox > S22-output.txt   Date: 2026-10-20. Read-only GETs.
set -u; C="$1"; strip() { sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<[^>]*>/ /g' -e 's/&[a-z#0-9]*;/ /g' | tr -s ' \n' | cat; }
echo "# S22 run $(date -u +%FT%TZ)"
curl -s https://kafka.apache.org/downloads -o $C/downloads.html; echo "downloads.html bytes: $(wc -c < $C/downloads.html)"
strip < $C/downloads.html | grep -oE '(Kafka )?[0-9]+\.[0-9]+\.[0-9]+[^.]{0,60}' | sort -uV | tail -8
curl -s https://kafka.apache.org/documentation/ -o $C/doc-stub.html
T=$(grep -oE 'url=[^"]+' $C/doc-stub.html | head -1 | sed 's/url=//'); echo "redirect target: ${T:-none}"
case "$T" in http*) U="$T";; /*) U="https://kafka.apache.org$T";; *) U="";; esac
if [ -n "$U" ]; then
  curl -sL "$U" -o $C/doc.html; echo "doc.html bytes: $(wc -c < $C/doc.html)  url: $U"
  for pat in 'combined' 'page cache' 'heap' 'at-least-once|at least once' 'exactly-once|exactly once' 'process.roles'; do echo "--- grep: $pat"; strip < $C/doc.html | grep -iE "$pat" | cut -c1-420 | head -4; done
fi
