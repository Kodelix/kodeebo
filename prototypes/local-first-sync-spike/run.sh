#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 runner)
# Date: 2026-10-16
#   run.sh selftest | run.sh replay <seed> [mutant] | run.sh stop
set -euo pipefail
cd "$(dirname "$0")"
PG=lfs-spike-pg
export PGPASSWORD=spike  # throwaway password of the throwaway local container; read by pgx and docker run

start_pg() {
  if ! docker ps --format '{{.Names}}' | grep -qx "$PG"; then
    # throwaway container, throwaway password, bound to localhost only
    docker run -d --rm --name "$PG" -e POSTGRES_PASSWORD="$PGPASSWORD" -p 127.0.0.1:56432:5432 postgres:18.6 >/dev/null
  fi
  for _ in $(seq 1 60); do
    docker exec "$PG" pg_isready -U postgres >/dev/null 2>&1 && return
    sleep 0.5
  done
  echo "postgres did not become ready" >&2; exit 1
}

build_server() { (cd sut/server && go build -o server .); }

case "${1:-}" in
  selftest) start_pg; build_server; python3 harness/driver.py selftest ;;
  replay)   start_pg; build_server; python3 harness/driver.py replay "$2" "${3:-}" ;;
  stop)     docker rm -f "$PG" >/dev/null 2>&1 || true ;;
  *) echo "usage: run.sh selftest | replay <seed> [mutant] | stop" >&2; exit 2 ;;
esac
