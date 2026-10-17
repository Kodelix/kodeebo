#!/usr/bin/env bash
# S60 - database-level tenant tests on postgres:18.6. Container ti-p6-pg (no published port), removed at the end.
set -u
D=$(cd "$(dirname "$0")" && pwd)
docker rm -f ti-p6-pg >/dev/null 2>&1
docker run -d --name ti-p6-pg -e POSTGRES_HOST_AUTH_METHOD=trust postgres:18.6 >/dev/null
for i in $(seq 1 40); do docker exec ti-p6-pg pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 2
echo "### version"; docker exec ti-p6-pg psql -U postgres -Atc "select version()"
echo "### setup"; docker exec -i ti-p6-pg psql -U postgres -v ON_ERROR_STOP=1 < "$D/setup.sql" 2>&1 | tail -3
echo "### catalogue (as superuser)"; docker exec -i ti-p6-pg psql -U postgres -X < "$D/catalogue.sql" 2>&1
echo "### runtime role"; docker exec -i ti-p6-pg psql -U kodeebo_app -d postgres -X < "$D/runtime.sql" 2>&1
echo "### runtime role R4 redo"; docker exec -i ti-p6-pg psql -U kodeebo_app -d postgres -X < "$D/runtime-r4.sql" 2>&1
echo "### owner role"; docker exec -i ti-p6-pg psql -U kodeebo_owner -d postgres -X < "$D/owner.sql" 2>&1
docker rm -f ti-p6-pg >/dev/null 2>&1; echo "### container removed"
