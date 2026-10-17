#!/usr/bin/env bash
# S11b: correct re-run of the RLS per-tenant export part of S11. In S11 the seed INSERT used table names t1..t3 (seq -w 1 3 pads to width 1)
# instead of t01..t03, and its errors were discarded, so "rows: 0" in s11-output.txt is a WRONG TEST for that sub-test (kept, labelled).
# Needs rls_db and role dump_rt from run-s11.sh.
set -u
PSQL() { docker exec -i ti-p1-pg psql -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }
echo "== S11b start $(date -u +%FT%TZ)"
PSQL -d rls_db -t -A -c "select version()"
tidA=$(PSQL -d rls_db -t -A -c "select id from tenants order by slug limit 1")
tidB=$(PSQL -d rls_db -t -A -c "select id from tenants order by slug desc limit 1")
for t in t01 t02 t03; do
  PSQL -d rls_db -c "insert into $t (id, tenant_id, a) select gen_random_uuid(), '$tidA', 'a' from generate_series(1,100)" -c "insert into $t (id, tenant_id, a) select gen_random_uuid(), '$tidB', 'b' from generate_series(1,50)"
done
echo "superuser view: t01 rows total = $(PSQL -d rls_db -t -A -c 'select count(*) from t01') (expect 150)"
echo "-- pg_dump as non-bypass role dump_rt WITHOUT --enable-row-security (expect error):"
docker exec -e PGOPTIONS="-c app.tenant_id=$tidA" ti-p1-pg pg_dump -U dump_rt -Fc -d rls_db -f /tmp/rls_a.dump 2>&1 | head -3
echo "-- pg_dump as dump_rt WITH --enable-row-security --inserts, tenant A in PGOPTIONS:"
docker exec -e PGOPTIONS="-c app.tenant_id=$tidA" ti-p1-pg pg_dump -U dump_rt --enable-row-security --inserts -d rls_db -f /tmp/rls_b.sql 2>&1 | head -3
echo "INSERT lines for public.t01 in the dump: $(docker exec ti-p1-pg grep -c 'INSERT INTO public.t01 ' /tmp/rls_b.sql) (expect 100)"
echo "INSERT lines naming tenant B id: $(docker exec ti-p1-pg grep -c "$tidB" /tmp/rls_b.sql) (expect 0)"
echo "INSERT lines naming the tenants table rows (tenants has no RLS): $(docker exec ti-p1-pg grep -c 'INSERT INTO public.tenants ' /tmp/rls_b.sql) (a table without RLS is dumped in full)"
echo "-- pg_dump as dump_rt WITH --enable-row-security and NO tenant context (expect no tenant rows):"
docker exec ti-p1-pg pg_dump -U dump_rt --enable-row-security --inserts -d rls_db -f /tmp/rls_c.sql 2>&1 | head -3
echo "INSERT lines for public.t01 with no context: $(docker exec ti-p1-pg grep -c 'INSERT INTO public.t01 ' /tmp/rls_c.sql) (expect 0)"
echo "== S11b end $(date -u +%FT%TZ)"
