#!/bin/sh
# S13 runner. From the repository root:  sh docs/research/evidence/notifications-provider/part-1/s13/s13-run.sh <run-name>
# Generates throwaway certificates and two per-run random secrets (never written to evidence), starts the stdlib sink on
# 127.0.0.1, runs Spike.java on the local JDK 21 against the cached Maven Central jars, stops the sink and deletes the keys.
# No network access, no download. Output: <run-name>/ under this folder (tee the stdout to <run-name>-output.txt).
set -u
RUN=${1:?run name}
R=docs/research/evidence/notifications-provider/part-1/s13
C=production/session-state/cache/notifications-provider
J=$C/jars
OUT=$R/$RUN
TLS=$C/$RUN-tls
mkdir -p "$OUT/sink" "$TLS"
SINK_PW=$(openssl rand -hex 12); export SINK_PW
TS_PW=$(openssl rand -hex 12); export TS_PW

echo "== S13 run $RUN, $(date -u +%FT%TZ)"
java -version 2>&1
javac -version 2>&1
python3 -I -c 'import sys; print("python", sys.version.split()[0])'
openssl version
for j in "$J"/*.jar; do
  echo "-- $(basename "$j") $(wc -c < "$j") bytes sha1 $(sha1sum "$j" | cut -d' ' -f1)"
  unzip -p "$j" META-INF/MANIFEST.MF | tr -d '\r' | grep -E '^(Bundle-SymbolicName|Bundle-Version|Implementation-Version|Automatic-Module-Name):' | sed 's/^/     /'
done

gen() {
  openssl req -x509 -newkey rsa:2048 -nodes -days 1 -keyout "$TLS/$1.key" -out "$TLS/$1.pem" -subj "$2" -addext "subjectAltName=$3" 2>/dev/null
  echo "cert $1: $(openssl x509 -in "$TLS/$1.pem" -noout -subject -ext subjectAltName -fingerprint -sha256 | tr '\n' ' ')"
}
gen good /CN=localhost "DNS:localhost,IP:127.0.0.1"
gen wrong /CN=other.example.test "DNS:other.example.test"
gen untrusted /CN=localhost "DNS:localhost,IP:127.0.0.1"
keytool -importcert -noprompt -alias good -file "$TLS/good.pem" -keystore "$TLS/ts.p12" -storetype PKCS12 -storepass:env TS_PW 2>&1 | sed 's/^/keytool: /'
keytool -importcert -noprompt -alias wrong -file "$TLS/wrong.pem" -keystore "$TLS/ts.p12" -storetype PKCS12 -storepass:env TS_PW 2>&1 | sed 's/^/keytool: /'

python3 -I "$R/s13-sink.py" "$TLS" "$OUT/sink" "$OUT/ports.txt" > "$OUT/sink-stdout.txt" 2>&1 &
SP=$!
i=0
while [ ! -s "$OUT/ports.txt" ] && [ $i -lt 50 ]; do sleep 0.2; i=$((i+1)); done
echo "sink pid $SP, ports file lines: $(wc -l < "$OUT/ports.txt")"

echo "== angus-mail 2.0.5 IMAP doc lines (source tag 2.0.5, saved in raw/) naming the imaps prefix"
grep -n -i 'imaps' "$R/raw/angus-imap-package-info.java" | head -8 | cut -c1-200

echo "== java"
timeout 280 java -Djava.net.preferIPv4Stack=true \
  -Djavax.net.ssl.trustStore="$TLS/ts.p12" -Djavax.net.ssl.trustStoreType=PKCS12 -Djavax.net.ssl.trustStorePassword="$TS_PW" \
  -cp "$J/angus-mail-2.0.5.jar:$J/jakarta.mail-api-2.1.5.jar:$J/jakarta.activation-api-2.1.4.jar:$J/angus-activation-2.0.3.jar" \
  "$R/${2:-Spike.java}" "$OUT/ports.txt" "$OUT/sink"
echo "java exit: $?"

kill $SP 2>/dev/null
sleep 0.3
echo "sink files: $(ls "$OUT/sink" | wc -l)"
rm -rf "$TLS"
echo "keys and certificates deleted: $([ -d "$TLS" ] && echo NO || echo yes)"
