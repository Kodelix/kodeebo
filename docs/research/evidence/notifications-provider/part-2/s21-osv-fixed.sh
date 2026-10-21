#!/usr/bin/env bash
# S21 (tier E): OSV advisories per exact Maven version. Fixes s20's sed delimiter bug (wrong run: see s20 output).
set -u
echo "date: $(date -u +%F) ; curl $(curl --version | head -1 | cut -d' ' -f1-2)"
q() { # name version label
  if [ -n "$2" ]; then body="{\"package\":{\"name\":\"$1\",\"ecosystem\":\"Maven\"},\"version\":\"$2\"}"; else body="{\"package\":{\"name\":\"$1\",\"ecosystem\":\"Maven\"}}"; fi
  ids=$(curl -s -X POST https://api.osv.dev/v1/query -d "$body" | grep -o '"id": *"[^"]*"' | sed 's|"id": *||; s|"||g' | sort -u)
  echo "$1 ${2:-ANY-VERSION}: $(printf '%s' "$ids" | grep -c .) advisories: $(printf '%s' "$ids" | tr '\n' ' ')"
}
q nl.martijndwars:web-push 5.1.2
q nl.martijndwars:web-push ""
q com.google.firebase:firebase-admin 9.11.0
q com.google.firebase:firebase-admin ""
q com.google.auth:google-auth-library-oauth2-http 1.54.0
q org.bouncycastle:bcprov-jdk18on 1.86
q org.bouncycastle:bcprov-jdk18on ""
q io.ktor:ktor-client-cio 3.6.0
q io.ktor:ktor-client-core 3.6.0
echo "control (expect >0):"; q org.apache.logging.log4j:log4j-core 2.14.1
