#!/usr/bin/env bash
# S11: footprint, provisioning, migration fan-out, per-tenant dump and fresh-connection cost of the three tenancy models
# on postgres:18.6 (own container ti-p1-pg). N tenants x T tables, same table shape in every model.
# usage: bash run-s11.sh [N] [T]   defaults N=100 T=30. Output is written by the caller (tee to s11-output.txt).
set -u
N="${1:-100}"; T="${2:-30}"
PSQL() { docker exec -i ti-p1-pg psql -U postgres -X -q -v ON_ERROR_STOP=1 "$@"; }
now() { date +%s.%N; }
el() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.2f", b-a}'; }

gen_ddl() { for i in $(seq -w 1 "$T"); do
  echo "create table t$i (id uuid primary key, tenant_id uuid not null, a text, b int, c timestamptz default now(), d bigint);"
  echo "create index t${i}_tenant_idx on t$i (tenant_id, c);"
done; }

echo "== S11 start $(date -u +%FT%TZ)  N=$N tenants  T=$T tables each (1 PK + 1 tenant-leading index per table)"
PSQL -c "select version()" -t
PSQL -c "show max_connections" -t

# ---- clean ----
PSQL -d postgres -c "drop database if exists rls_db" -c "drop database if exists sch_db" -c "drop database if exists tmpl_db" >/dev/null
for i in $(seq 1 "$N"); do PSQL -d postgres -c "drop database if exists tdb_$i" >/dev/null; done

# ---- Model 1: shared schema + RLS ----
PSQL -d postgres -c "create database rls_db" >/dev/null
s=$(now)
{ gen_ddl
  for i in $(seq -w 1 "$T"); do
    echo "alter table t$i enable row level security; alter table t$i force row level security;"
    echo "create policy tenant_isolation on t$i using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);"
  done
  echo "create table tenants (id uuid primary key, slug text unique);"
  echo "insert into tenants select gen_random_uuid(), 'ten' || g from generate_series(1,$N) g;"
} | PSQL -d rls_db >/dev/null
e=$(now); echo "[RLS ] build schema + $N tenant rows: $(el $s $e) s"
echo "[RLS ] pg_database_size: $(PSQL -d postgres -t -A -c "select pg_size_pretty(pg_database_size('rls_db'))") ; pg_class rows: $(PSQL -d rls_db -t -A -c "select count(*) from pg_class") ; pg_attribute rows: $(PSQL -d rls_db -t -A -c "select count(*) from pg_attribute")"
s=$(now)
{ for i in $(seq -w 1 "$T"); do echo "alter table t$i add column e text;"; done; } | PSQL -d rls_db >/dev/null
e=$(now); echo "[RLS ] migration fan-out (ADD COLUMN on $T tables, 1 database): $(el $s $e) s  (statements: $T)"

# ---- Model 2: schema-per-tenant (one database) ----
PSQL -d postgres -c "create database sch_db" >/dev/null
s=$(now)
for i in $(seq 1 "$N"); do echo "create schema ten_$i; set search_path = ten_$i;"; gen_ddl; done | PSQL -d sch_db >/dev/null
e=$(now); echo "[SCH ] provision $N schemas x $T tables ($(( N*T )) tables): $(el $s $e) s  (avg $(awk -v a=$(el $s $e) -v n=$N 'BEGIN{printf "%.3f", a/n}') s per tenant)"
echo "[SCH ] pg_database_size: $(PSQL -d postgres -t -A -c "select pg_size_pretty(pg_database_size('sch_db'))") ; pg_class rows: $(PSQL -d sch_db -t -A -c "select count(*) from pg_class") ; pg_attribute rows: $(PSQL -d sch_db -t -A -c "select count(*) from pg_attribute")"
s=$(now)
PSQL -d sch_db -c "do \$\$ declare r record; begin for r in select schemaname, tablename from pg_tables where schemaname like 'ten\\_%' loop execute format('alter table %I.%I add column e text', r.schemaname, r.tablename); end loop; end \$\$;" >/dev/null
e=$(now); echo "[SCH ] migration fan-out (ADD COLUMN, 1 transaction, 1 database): $(el $s $e) s  (statements: $(( N*T )))"

# ---- Model 3: database-per-tenant ----
PSQL -d postgres -c "create database tmpl_db" >/dev/null
gen_ddl | PSQL -d tmpl_db >/dev/null
s=$(now)
for i in $(seq 1 "$N"); do PSQL -d postgres -c "create database tdb_$i template tmpl_db" >/dev/null; done
e=$(now); echo "[DB  ] provision $N databases from template ($(( N*T )) tables): $(el $s $e) s  (avg $(awk -v a=$(el $s $e) -v n=$N 'BEGIN{printf "%.3f", a/n}') s per tenant)"
echo "[DB  ] pg_database_size tmpl_db: $(PSQL -d postgres -t -A -c "select pg_size_pretty(pg_database_size('tmpl_db'))") ; tdb_1: $(PSQL -d postgres -t -A -c "select pg_size_pretty(pg_database_size('tdb_1'))") ; sum of $N tdb_*: $(PSQL -d postgres -t -A -c "select pg_size_pretty(sum(pg_database_size(datname))) from pg_database where datname like 'tdb\\_%'")"
echo "[DB  ] pg_class rows per database: $(PSQL -d tdb_1 -t -A -c "select count(*) from pg_class") ; pg_database rows: $(PSQL -d postgres -t -A -c "select count(*) from pg_database")"
s=$(now)
for i in $(seq 1 "$N"); do { for k in $(seq -w 1 "$T"); do echo "alter table t$k add column e text;"; done; } | PSQL -d "tdb_$i" >/dev/null; done
e=$(now); echo "[DB  ] migration fan-out (ADD COLUMN, $N separate connections, $T statements each): $(el $s $e) s  (statements: $(( N*T )))"

# ---- per-tenant dump (one tenant), custom format ----
mid=$(( N/2 ))
s=$(now); docker exec ti-p1-pg pg_dump -U postgres -Fc -n "ten_$mid" -f /tmp/sch_one.dump sch_db; e=$(now)
echo "[SCH ] pg_dump -Fc -n ten_$mid : $(el $s $e) s ; size $(docker exec ti-p1-pg ls -l /tmp/sch_one.dump | awk '{print $5}') bytes"
s=$(now); docker exec ti-p1-pg pg_dump -U postgres -Fc -d "tdb_$mid" -f /tmp/db_one.dump; e=$(now)
echo "[DB  ] pg_dump -Fc tdb_$mid     : $(el $s $e) s ; size $(docker exec ti-p1-pg ls -l /tmp/db_one.dump | awk '{print $5}') bytes"
# restore of one tenant into a fresh database (does not touch the other tenants)
PSQL -d postgres -c "drop database if exists restore_chk" -c "create database restore_chk" >/dev/null
s=$(now); docker exec ti-p1-pg pg_restore -U postgres -d restore_chk /tmp/sch_one.dump; e=$(now)
echo "[SCH ] pg_restore of one tenant schema into a separate database: $(el $s $e) s ; tables restored: $(PSQL -d restore_chk -t -A -c "select count(*) from pg_tables where schemaname='ten_$mid'")"
# RLS model: dump with row security as non-bypass runtime role limited to one tenant
PSQL -d rls_db -c "drop role if exists dump_rt" -c "create role dump_rt login nobypassrls" -c "grant usage on schema public to dump_rt" -c "grant select on all tables in schema public to dump_rt" >/dev/null
tid=$(PSQL -d rls_db -t -A -c "select id from tenants order by slug limit 1")
for i in $(seq -w 1 3); do PSQL -d rls_db -c "insert into t$i (id, tenant_id, a) select gen_random_uuid(), '$tid', 'x' from generate_series(1,100)" >/dev/null 2>&1; done
echo "[RLS ] insert as superuser (bypasses RLS) rows for one tenant: $(PSQL -d rls_db -t -A -c "select count(*) from t01")"
echo "[RLS ] pg_dump as non-bypass role WITHOUT --enable-row-security (expect error):"
docker exec -e PGOPTIONS="-c app.tenant_id=$tid" ti-p1-pg pg_dump -U dump_rt -Fc -d rls_db -f /tmp/rls_a.dump 2>&1 | head -3
echo "[RLS ] pg_dump as non-bypass role WITH --enable-row-security --inserts, tenant GUC via PGOPTIONS (rows visible to that tenant only):"
s=$(now); docker exec -e PGOPTIONS="-c app.tenant_id=$tid" ti-p1-pg pg_dump -U dump_rt --enable-row-security --inserts -d rls_db -f /tmp/rls_b.sql 2>&1 | head -3; e=$(now)
echo "[RLS ] time $(el $s $e) s ; INSERT lines for t01 in dump: $(docker exec ti-p1-pg grep -c 'INSERT INTO public.t01 ' /tmp/rls_b.sql)  (superuser table count was $(PSQL -d rls_db -t -A -c "select count(*) from t01"))"

# ---- fresh connection + first query cost ----
loop() { local db="$1"; local q="$2"; local s e; s=$(now); for k in $(seq 1 30); do docker exec ti-p1-pg psql -U postgres -X -q -d "$db" -t -A -c "$q" >/dev/null; done; e=$(now); awk -v a="$s" -v b="$e" 'BEGIN{printf "%.1f ms per connect+query (30 runs, includes docker exec)", (b-a)/30*1000}'; }
echo "[RLS ] fresh connection to rls_db  : $(loop rls_db 'select count(*) from t01')"
echo "[SCH ] fresh connection to sch_db  : $(loop sch_db 'select count(*) from ten_50.t01')"
echo "[DB  ] fresh connection to tdb_50  : $(loop tdb_50 'select count(*) from t01')"
echo "== S11 end $(date -u +%FT%TZ)"
