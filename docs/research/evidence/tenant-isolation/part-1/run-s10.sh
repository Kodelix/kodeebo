#!/usr/bin/env bash
# S10: re-verify RLS facts on postgres:18.6 in container ti-p1-pg (own container started by this research session).
# usage: bash run-s10.sh   (container must be running; psql runs inside the container)
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker exec -i ti-p1-pg psql -U postgres -v ON_ERROR_STOP=0 -X -q < "$here/s10-rls-reverify.sql" > "$here/s10-output.txt" 2>&1
echo "exit=$?"
