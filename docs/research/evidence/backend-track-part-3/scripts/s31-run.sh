#!/usr/bin/env bash
# S31: BC bcpkix 1.86 detached CAdES-BES-shaped signature + OpenSSL cross-check. Args: <repo-root>
set -eu
R="$1"; E="$R/docs/research/evidence/backend-track-part-3"; C="$R/production/session-state/cache/backend-track/part-3/downloads/bc186"
echo "date_utc: $(date -u +%FT%TZ)"; java -version 2>&1 | head -1; openssl version
for a in bcprov bcpkix bcutil; do [ -s "$C/$a-jdk18on-1.86.jar" ] || curl -sf -m 120 -o "$C/$a-jdk18on-1.86.jar" "https://repo1.maven.org/maven2/org/bouncycastle/$a-jdk18on/1.86/$a-jdk18on-1.86.jar"; done
ls -l "$C"; sha256sum "$C"/*.jar
CP="$C/bcprov-jdk18on-1.86.jar:$C/bcpkix-jdk18on-1.86.jar:$C/bcutil-jdk18on-1.86.jar"
W="$E/s31-work"; rm -f "$W"/*
java -cp "$CP" "$E/scripts/S31Cades.java" "$W"
echo "== openssl cms -cmsout -print (attributes) =="
openssl cms -cmsout -print -inform DER -in "$W/sig.der" | grep -E 'digestAlgorithm|signatureAlgorithm|object:|signedAttrs|unsignedAttrs|Version' | head -40
echo "== openssl cms -verify (signature only, -noverify skips chain; self-signed throwaway cert) =="
openssl cms -verify -inform DER -in "$W/sig.der" -content "$W/data.bin" -binary -noverify -out /dev/null && echo "openssl verify OK (exit 0)" || echo "openssl verify FAILED"
echo "== tamper check =="
printf 'x' >> "$W/data.bin"; openssl cms -verify -inform DER -in "$W/sig.der" -content "$W/data.bin" -binary -noverify -out /dev/null 2>&1 | tail -1; echo "tamper exit=$?"
