#!/usr/bin/env bash
# S13 set-up (tier-E evidence, throwaway). Copies the six jars from the part-1 cache of build-and-ops-tooling and
# starts OWN container msc-part3-pg (postgres:18.6, --pull=never, loopback only, trust auth, no secret).
# Never touches lfs-spike-pg or any other container.
set -eu
R=/home/kiko/saas-products/kodeebo
SRC=$R/production/session-state/cache/build-and-ops-tooling/part-1/jars
DST=$R/production/session-state/cache/module-structure-and-core-boundary/part-3/jars
for j in flyway-core-13.10.3 flyway-database-postgresql-13.10.3 postgresql-42.7.14 jackson-annotations-2.22 jackson-core-3.2.4 jackson-databind-3.2.4; do cp "$SRC/$j.jar" "$DST/"; done
( cd "$DST" && sha256sum *.jar && du -cb *.jar | tail -1 )
PORT=57613
if ss -ltn | grep -q ":$PORT "; then echo "port $PORT busy"; exit 1; fi
docker run --pull=never --rm -d --name msc-part3-pg -e POSTGRES_HOST_AUTH_METHOD=trust -p 127.0.0.1:$PORT:5432 postgres:18.6
for i in $(seq 1 40); do docker exec msc-part3-pg pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1 && break; sleep 1; done
sleep 2
docker exec msc-part3-pg psql -U postgres -h 127.0.0.1 -Atc 'select version()'
echo "PORT=$PORT"
