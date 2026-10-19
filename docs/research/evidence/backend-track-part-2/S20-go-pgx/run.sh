#!/usr/bin/env bash
# S20: ADR-0002 helper on pgx v5.11.0 + postgres:18.6: SECURITY DEFINER calls, transaction_timeout,
# streaming COPY TO STDOUT under RLS, outbox claim per tenant, idempotent consumer.
# Usage: bash run.sh > output.txt 2>&1   Needs docker, go 1.27.x, network for the Go module proxy.
# Module and build caches go under production/session-state/cache/backend-track/part-2/ (gitignored).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../../.." && pwd)"
CACHE="$ROOT/production/session-state/cache/backend-track/part-2"
mkdir -p "$CACHE/gomod" "$CACHE/gocache"
export GOMODCACHE="$CACHE/gomod" GOCACHE="$CACHE/gocache" GOFLAGS=-mod=mod
NAME=bt2-pg; PGP=58461
cleanup() { docker rm -fv $NAME >/dev/null 2>&1; }
trap cleanup EXIT; cleanup
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "### $(go version); $(docker --version)"
echo "### image: postgres:18.6 $(docker image inspect postgres:18.6 --format '{{.Id}}' | cut -c1-19)"
docker run -d --name $NAME -p 127.0.0.1:$PGP:5432 -e POSTGRES_PASSWORD=bt2_super_throwaway postgres:18.6 >/dev/null
for i in $(seq 1 90); do docker exec $NAME pg_isready -h 127.0.0.1 -U postgres -q && break; sleep 1; done
sleep 2
echo "### server: $(docker exec $NAME postgres --version)"
docker exec -i $NAME psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=1 < "$HERE/setup.sql" 2>&1
docker exec -i $NAME psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=1 < "$HERE/seed.sql" 2>&1
# Edited 2026-10-19 after the run: the test reads the throwaway role password (setup.sql) from BT2_PG_PASSWORD
# instead of a URL literal (commit secret check). No behaviour change.
cd "$HERE" && BT2_PG_PASSWORD=bt2_throwaway PG_ADDR=127.0.0.1:$PGP go test -count=1 -v -p 1 ./... 2>&1
echo "### module cache size: $(du -sh "$GOMODCACHE" | cut -f1)"
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
