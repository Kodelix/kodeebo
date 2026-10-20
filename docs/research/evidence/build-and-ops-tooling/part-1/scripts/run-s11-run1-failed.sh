#!/bin/bash
# S11: Flyway 13.10.3 (library) vs postgres:18.6, loopback-bound throwaway container, trust auth (no secret).
# Usage: run-s11.sh <evidence_dir> <cache_dir>   (run from repo root)
set -u
D="$1"; C="$2"; J="$C/jars"; M=https://repo1.maven.org/maven2
W="$C/migrations-work"; rm -rf "$W"; mkdir -p "$W"; cp "$D"/s11-migrations/*.sql "$W"/
echo "date_utc: $(date -u +%FT%TZ)"; java -version 2>&1 | head -1; java --list-modules | grep -c jdk.compiler
rel(){ curl -s --max-time 30 "$M/$1/maven-metadata.xml" | grep -o '<release>[^<]*' | sed 's/<release>//'; }
JD=$(rel tools/jackson/core/jackson-databind); JC=$(rel tools/jackson/core/jackson-core); JA=$(rel com/fasterxml/jackson/core/jackson-annotations)
echo "jackson versions resolved: databind=$JD core=$JC annotations=$JA"
for p in "org/flywaydb/flyway-core/13.10.3/flyway-core-13.10.3.jar" "org/flywaydb/flyway-database-postgresql/13.10.3/flyway-database-postgresql-13.10.3.jar" "org/postgresql/postgresql/42.7.14/postgresql-42.7.14.jar" "tools/jackson/core/jackson-databind/$JD/jackson-databind-$JD.jar" "tools/jackson/core/jackson-core/$JC/jackson-core-$JC.jar" "com/fasterxml/jackson/core/jackson-annotations/$JA/jackson-annotations-$JA.jar"; do
  f="$J/$(basename "$p")"; [ -f "$f" ] || curl -fsSL --max-time 120 -o "$f" "$M/$p" || echo "DOWNLOAD FAILED $p"
  echo "sha256 $(sha256sum "$f" | cut -d' ' -f1) $(stat -c %s "$f") $(basename "$f")"
done
docker rm -f s11pg >/dev/null 2>&1
docker run --pull=never -d --name s11pg -e POSTGRES_HOST_AUTH_METHOD=trust -p 127.0.0.1:55432:5432 postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
trap 'docker rm -f s11pg >/dev/null 2>&1' EXIT
for i in $(seq 1 60); do docker exec s11pg psql -h 127.0.0.1 -U postgres -Atc 'select 1' >/dev/null 2>&1 && break; sleep 1; done
P(){ docker exec -i s11pg psql -h 127.0.0.1 -U postgres -v ON_ERROR_STOP=1 "$@"; }
P -Atc 'select version()'
P <<'SQL'
CREATE ROLE migrator NOLOGIN;
CREATE ROLE app_rt NOLOGIN;
CREATE ROLE deploy_rt LOGIN NOSUPERUSER NOBYPASSRLS;
GRANT migrator TO deploy_rt WITH INHERIT FALSE, SET TRUE;
CREATE DATABASE kodeebo OWNER migrator;
SQL
P -d kodeebo <<'SQL'
CREATE SCHEMA app AUTHORIZATION migrator;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA app TO app_rt;
SQL
run(){ echo; echo "### $*"; java -cp "$J/*" "$D/scripts/Main.java" "$@" 2>&1 | grep -v -E '^\s*$' | cut -c1-400; }
run migrate deploy_rt "SET ROLE migrator" 2 "$W"
run migrate deploy_rt "SET ROLE migrator" 3 "$W"
echo "--- index state"; P -d kodeebo -Atc "select indexrelid::regclass, indisvalid from pg_index where indexrelid::regclass::text like '%orders_tenant_idx%'"
echo "(if V3 failed above, config file test follows)"
if ! P -d kodeebo -Atc "select 1 from app.flyway_schema_history where version='3' and success" | grep -q 1; then
  echo "executeInTransaction=false" > "$W/V3__orders_index_concurrently.sql.conf"
  run migrate deploy_rt "SET ROLE migrator" 3 "$W"
  P -d kodeebo -Atc "select indexrelid::regclass, indisvalid from pg_index where indexrelid::regclass::text like '%orders_tenant_idx%'"
fi
echo "--- tamper V1 then validate"; cp "$W/V1__orders_rls.sql" "$C/V1.bak"; echo "-- tamper" >> "$W/V1__orders_rls.sql"
run validate deploy_rt "SET ROLE migrator" latest "$W"
cp "$C/V1.bak" "$W/V1__orders_rls.sql"
echo "--- migrate to latest as deploy_rt (V4 needs CREATEROLE)"
run migrate deploy_rt "SET ROLE migrator" latest "$W"
echo "--- migrate V4 as bootstrap superuser (postgres), no SET ROLE"
run migrate postgres "" latest "$W"
echo "--- pipeline run again as deploy_rt"
run migrate deploy_rt "SET ROLE migrator" latest "$W"
echo; echo "=== catalog checks"
P -d kodeebo -c "select installed_rank,version,description,type,installed_by,success from app.flyway_schema_history order by 1"
P -d kodeebo -c "select tablename,owner:=tableowner from pg_tables where schemaname='app'" 2>/dev/null || P -d kodeebo -c "select tablename,tableowner from pg_tables where schemaname='app'"
P -d kodeebo -c "select polname,polpermissive,polroles::regrole[] from pg_policy where polrelid='app.orders'::regclass"
P -d kodeebo -c "select relrowsecurity,relforcerowsecurity from pg_class where oid='app.orders'::regclass"
P -d kodeebo -c "select p.proname,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig from pg_proc p where proname='tenant_count'"
P -d kodeebo -c "select rolname from pg_roles where rolname='spike_priv_role'"
echo "container log tail:"; docker logs s11pg 2>&1 | grep -i -E "error|FATAL" | tail -12
