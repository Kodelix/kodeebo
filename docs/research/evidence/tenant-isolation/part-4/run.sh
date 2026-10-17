#!/usr/bin/env bash
# S40a runner. Own container ti-p4-pg on 127.0.0.1:57441, removed at the end. Output in 10-tests.out etc.
set -u
cd "$(dirname "$0")"
docker rm -f ti-p4-pg >/dev/null 2>&1
docker run -d --name ti-p4-pg -e POSTGRES_PASSWORD=ti_p4_throwaway -p 127.0.0.1:57441:5432 postgres:18.6 >/dev/null
for i in $(seq 1 60); do docker exec ti-p4-pg pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1 && break; sleep 1; done
sleep 2
{ date -u +%FT%TZ; docker exec ti-p4-pg psql -U postgres -Atc 'select version()'; docker image inspect postgres:18.6 --format '{{.Id}}'; } > versions.out
docker exec -i ti-p4-pg psql -U postgres -v ON_ERROR_STOP=1 < 00-setup.sql > 00-setup.out 2>&1
docker exec -i -e PGPASSWORD=ti_p4_throwaway ti-p4-pg psql -h 127.0.0.1 -U app_rt -d postgres < 10-tests.sql > 10-tests.out 2>&1
docker exec -i ti-p4-pg psql -U postgres -d postgres < 20-mv-rls-try.sql > 20-mv-rls-try.out 2>&1
docker rm -f ti-p4-pg >/dev/null 2>&1
