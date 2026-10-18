#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 runner)
# Date: 2026-10-16
#   run.sh selftest | replay <seed> [mutant] | phase1 | replay1 <seed> <cipher> <point> [mutant] | tamper
#          | phase2 [seeds_per_cell] [campaign_runs] | replay2 <seed> <cell|random> [mutant] | ts09
#          | sc19 [seeds_per_cell] | replay19 <seed> <cell> [mutant] | sc20 [seeds] | sc20real [seeds] | replay20 <seed> <cell> [mutant] | sc21 [seeds] | replay21 <seed> <cell> [mutant] | sc22 [seeds] | replay22 <seed> <cell> [mutant] | sc23 [seeds] | replay23 <seed> <cell> [mutant] | sc25 [tenth|full|both] | replay25 <seed> <tenth|full> [mutant] | sc25b [seeds] | replay25b <seed> <cell> [mutant] | sc28 [seeds] | replay28 <seed> <cell> [mutant] | sc29 [seeds] | replay29 <seed> <cell> [mutant] | sc30 [seeds] | replay30 <seed> <cell> [mutant] | sc31 [seeds] | replay31 <seed> <cell> [mutant] | sc13 [seeds] | replay13 <seed> <cell> [mutant] | ts07 [seeds] | replay07 <seed> <cell> [mutant] | ts02 [seeds] | replay02 <seed> <cell> [mutant] | stop
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
  phase1)   start_pg; build_server; .venv/bin/python harness/driver.py phase1 ;;
  replay1)  start_pg; build_server; .venv/bin/python harness/driver.py replay1 "$2" "$3" "$4" "${5:-}" ;;
  tamper)   .venv/bin/python harness/tamper.py ;;
  phase2)   start_pg; build_server; .venv/bin/python harness/driver.py phase2 "${2:-50}" "${3:-3000}" ;;
  replay2)  start_pg; build_server; .venv/bin/python harness/driver.py replay2 "$2" "$3" "${4:-}" ;;
  ts09)     start_pg; build_server; .venv/bin/python harness/driver.py ts09 ;;
  sc19)     start_pg; build_server; .venv/bin/python harness/driver.py sc19 "${2:-50}" ;;
  replay19) start_pg; build_server; .venv/bin/python harness/driver.py replay19 "$2" "$3" "${4:-}" ;;
  sc20)     start_pg; build_server; .venv/bin/python harness/driver.py sc20 "${2:-50}" ;;
  sc20real) start_pg; build_server; unshare -r -m .venv/bin/python harness/driver.py sc20real "${2:-50}" ;;
  sc21)     start_pg; build_server; .venv/bin/python harness/driver.py sc21 "${2:-50}" ;;
  sc22)     start_pg; build_server; .venv/bin/python harness/driver.py sc22 "${2:-50}" ;;
  sc23)     start_pg; build_server; .venv/bin/python harness/driver.py sc23 "${2:-50}" ;;
  sc25)     start_pg; build_server; .venv/bin/python harness/driver.py sc25 "${2:-both}" ;;
  sc25b)    start_pg; build_server; .venv/bin/python harness/driver.py sc25b "${2:-20}" ;;
  replay25b) start_pg; build_server; .venv/bin/python harness/driver.py replay25b "$2" "$3" "${4:-}" ;;
  sc28)     start_pg; build_server; .venv/bin/python harness/driver.py sc28 "${2:-24}" ;;
  replay28) start_pg; build_server; .venv/bin/python harness/driver.py replay28 "$2" "$3" "${4:-}" ;;
  sc29)     start_pg; build_server; .venv/bin/python harness/driver.py sc29 "${2:-20}" ;;
  replay29) start_pg; build_server; .venv/bin/python harness/driver.py replay29 "$2" "$3" "${4:-}" ;;
  sc30)     start_pg; build_server; .venv/bin/python harness/driver.py sc30 "${2:-20}" ;;
  replay30) start_pg; build_server; .venv/bin/python harness/driver.py replay30 "$2" "$3" "${4:-}" ;;
  sc31)     start_pg; build_server; .venv/bin/python harness/driver.py sc31 "${2:-20}" ;;
  replay31) start_pg; build_server; .venv/bin/python harness/driver.py replay31 "$2" "$3" "${4:-}" ;;
  sc13)     start_pg; build_server; .venv/bin/python harness/driver.py sc13 "${2:-20}" ;;
  replay13) start_pg; build_server; .venv/bin/python harness/driver.py replay13 "$2" "$3" "${4:-}" ;;
  ts07)     start_pg; build_server; .venv/bin/python harness/driver.py ts07 "${2:-20}" ;;
  replay07) start_pg; build_server; .venv/bin/python harness/driver.py replay07 "$2" "$3" "${4:-}" ;;
  ts02)     start_pg; build_server; .venv/bin/python harness/driver.py ts02 "${2:-20}" ;;
  replay02) start_pg; build_server; .venv/bin/python harness/driver.py replay02 "$2" "$3" "${4:-}" ;;
  replay25) start_pg; build_server; .venv/bin/python harness/driver.py replay25 "$2" "$3" "${4:-}" ;;
  replay23) start_pg; build_server; .venv/bin/python harness/driver.py replay23 "$2" "$3" "${4:-}" ;;
  replay22) start_pg; build_server; .venv/bin/python harness/driver.py replay22 "$2" "$3" "${4:-}" ;;
  replay21) start_pg; build_server; .venv/bin/python harness/driver.py replay21 "$2" "$3" "${4:-}" ;;
  replay20) start_pg; build_server; .venv/bin/python harness/driver.py replay20 "$2" "$3" "${4:-}" ;;
  stop)     docker rm -f "$PG" >/dev/null 2>&1 || true ;;
  *) echo "usage: run.sh selftest | replay <seed> [mutant] | phase1 | replay1 <seed> <cipher> <point> [mutant] | tamper | phase2 [seeds] [runs] | replay2 <seed> <cell|random> [mutant] | ts09 | sc19 [seeds] | replay19 <seed> <cell> [mutant] | sc20 [seeds] | sc20real [seeds] | replay20 <seed> <cell> [mutant] | sc21 [seeds] | replay21 <seed> <cell> [mutant] | sc22 [seeds] | replay22 <seed> <cell> [mutant] | sc23 [seeds] | replay23 <seed> <cell> [mutant] | sc25 [tenth|full|both] | replay25 <seed> <tenth|full> [mutant] | sc25b [seeds] | replay25b <seed> <cell> [mutant] | sc28 [seeds] | replay28 <seed> <cell> [mutant] | sc29 [seeds] | replay29 <seed> <cell> [mutant] | sc30 [seeds] | replay30 <seed> <cell> [mutant] | sc31 [seeds] | replay31 <seed> <cell> [mutant] | sc13 [seeds] | replay13 <seed> <cell> [mutant] | ts07 [seeds] | replay07 <seed> <cell> [mutant] | ts02 [seeds] | replay02 <seed> <cell> [mutant] | stop" >&2; exit 2 ;;
esac
