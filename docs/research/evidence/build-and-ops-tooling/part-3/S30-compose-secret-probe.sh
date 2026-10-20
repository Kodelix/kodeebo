#!/usr/bin/env bash
# S30: what Compose does with ownership/mode of file-based and environment-based secrets,
# and what `docker inspect` / `docker compose config` reveal. Fake placeholder bytes only.
# Uses an already-present image (pull_policy: never). No network, no download.
# Usage: bash S30-compose-secret-probe.sh <workdir>   (workdir is inside docs/research/evidence/...)
set -u
W="$1"
mkdir -p "$W"
printf 'FAKE-PLACEHOLDER-S30-NOT-A-SECRET\n' > "$W/fake_file.txt"
chmod 0400 "$W/fake_file.txt"
cat > "$W/compose.yaml" <<'EOF'
name: s30probe
services:
  short:
    image: eclipse-temurin:21-jre
    pull_policy: never
    user: "10001:10001"
    command: ["sh","-c","id; ls -ln /run/secrets; cat /run/secrets/fake_file 2>&1 | head -c 60; echo"]
    secrets: [fake_file]
  long:
    image: eclipse-temurin:21-jre
    pull_policy: never
    user: "10001:10001"
    command: ["sh","-c","id; ls -ln /run/secrets; cat /run/secrets/fake_file 2>&1 | head -c 60; echo"]
    secrets:
      - source: fake_file
        target: fake_file
        uid: "10001"
        gid: "10001"
        mode: 0400
  envsrc:
    image: eclipse-temurin:21-jre
    pull_policy: never
    user: "10001:10001"
    command: ["sh","-c","id; ls -ln /run/secrets; cat /run/secrets/fake_env 2>&1 | head -c 60; echo"]
    secrets:
      - source: fake_env
        target: fake_env
        uid: "10001"
        gid: "10001"
        mode: 0400
  inspectme:
    image: eclipse-temurin:21-jre
    pull_policy: never
    user: "10001:10001"
    environment:
      FAKE_PLAIN_ENV_S30: "FAKE-PLACEHOLDER-PLAIN-ENV"
    command: ["sleep","60"]
    secrets: [fake_file]
secrets:
  fake_file:
    file: ./fake_file.txt
  fake_env:
    environment: FAKE_ENV_S30
EOF
export FAKE_ENV_S30='FAKE-PLACEHOLDER-S30-ENV-NOT-A-SECRET'
cd "$W" || exit 1
echo "== versions"; docker --version; docker compose version
echo "== host: uid=$(id -u) file:"; ls -ln fake_file.txt
for s in short long envsrc; do
  echo "== run service: $s"
  docker compose run --rm --no-deps -T "$s" 2>&1
done
echo "== docker compose config (does it print secret values?)"
docker compose config 2>&1
echo "== inspect a running container"
docker compose up -d inspectme 2>&1
C=$(docker compose ps -q inspectme)
echo "-- inspect .Config.Env"; docker inspect --format '{{json .Config.Env}}' "$C"
echo "-- inspect .Mounts"; docker inspect --format '{{json .Mounts}}' "$C"
echo "-- /proc/1/environ via docker exec (needs docker access)"; docker exec "$C" sh -c 'tr "\0" "\n" < /proc/1/environ | grep -i FAKE' 2>&1
docker compose down 2>&1
