#!/bin/bash
# S52 (= the planned S14): can Flyway Community 13.10.3 run every statement incl. the schema-history-table
# creation as `migrator` while logging in as deploy_rt, without the deprecated initSql?
# Adapted from part 1's run-s11.sh (not edited). Jars: part 1's cache (read only). Throwaway postgres:18.6,
# loopback-only port, trust auth (no secret). Server log_statement=all shows WHICH connection (pid) ran what.
# Usage: run-s52.sh <evidence_dir> <part5_cache_dir> <part1_jars_dir> [candidate-name ...]
set -u
D="$1"; C="$2"; J="$3"; shift 3
SEL=" $* "
S11M=/home/kiko/saas-products/kodeebo/docs/research/evidence/build-and-ops-tooling/part-1/s11-migrations
W="$C/s52-work"; rm -rf "$W"; mkdir -p "$W/mig" "$W/cb-afterConnect" "$W/cb-beforeMigrate" "$W/cb-beforeValidate" "$D/s52-logs"
cp "$S11M/V1__orders_rls.sql" "$S11M/V2__definer_fn.sql" "$S11M/V4__privileged_create_role.sql" "$W/mig/"
cat > "$W/mig/V3__who.sql" <<'SQL'
SET lock_timeout = '5s';
CREATE TABLE app.who (id serial PRIMARY KEY, session_user_name text NOT NULL, current_user_name text NOT NULL);
INSERT INTO app.who (session_user_name, current_user_name) VALUES (session_user, current_user);
SQL
for e in afterConnect beforeMigrate beforeValidate; do echo "SET ROLE migrator;" > "$W/cb-$e/$e.sql"; done
echo "date_utc: $(date -u +%FT%TZ)"; java -version 2>&1 | head -1
for j in "$J"/*.jar; do echo "sha256 $(sha256sum "$j" | cut -d' ' -f1) $(basename "$j")"; done
docker rm -f s52pg-bot-p5 >/dev/null 2>&1
docker run --pull=never -d --name s52pg-bot-p5 -e POSTGRES_HOST_AUTH_METHOD=trust -p 127.0.0.1::5432 postgres:18.6 \
  postgres -c log_statement=all -c log_connections=on -c "log_line_prefix=%m pid=%p user=%u db=%d " >/dev/null || { echo "docker run failed"; exit 1; }
trap 'docker rm -f s52pg-bot-p5 >/dev/null 2>&1' EXIT
PGPORT=$(docker port s52pg-bot-p5 5432/tcp | head -1 | sed "s/.*://"); export PGPORT; echo "host port: $PGPORT (loopback)"
for i in $(seq 1 60); do docker exec s52pg-bot-p5 psql -h 127.0.0.1 -U postgres -Atc 'select 1' >/dev/null 2>&1 && break; sleep 1; done
P(){ docker exec -i s52pg-bot-p5 psql -h 127.0.0.1 -U postgres -v ON_ERROR_STOP=1 "$@"; }
P -Atc 'select version()'
P <<'SQL'
CREATE ROLE migrator NOLOGIN;
CREATE ROLE app_rt NOLOGIN;
CREATE ROLE deploy_rt LOGIN NOSUPERUSER NOBYPASSRLS;
GRANT migrator TO deploy_rt WITH INHERIT FALSE, SET TRUE;
CREATE ROLE deploy_rt2 LOGIN NOSUPERUSER NOBYPASSRLS;
GRANT migrator TO deploy_rt2 WITH INHERIT FALSE, SET TRUE;
SQL
FL(){ timeout 90 java -cp "$J/*" "$D/scripts/Main52.java" "$@" 2>&1 | grep -v -E '^\s*$|^[A-Z][a-z]{2} [0-9]{1,2}, 20[0-9]{2}|^INFO: (Environment|Database)' | cut -c1-330; echo "(client exit ${PIPESTATUS[0]}; 124 = timed out)"; }
cand(){ # name user mode arg
  local name=$1 user=$2 mode=$3 arg=$4 db=$5
  case "$SEL" in " "*) [ "$SEL" != "  " ] && [[ "$SEL" != *" $name "* ]] && return;; esac
  echo; echo "################ CANDIDATE $name  (login $user, mode=$mode, arg='$arg')"
  P -c "CREATE DATABASE $db OWNER migrator" >/dev/null
  P -d "$db" -c "CREATE SCHEMA app AUTHORIZATION migrator; GRANT USAGE ON SCHEMA app TO app_rt; REVOKE CREATE ON SCHEMA public FROM PUBLIC" >/dev/null
  export PGDB=$db
  local mark; mark=$(docker logs s52pg-bot-p5 2>&1 | wc -l)
  echo "--- step 1: migrate to target 3 as $user"
  FL migrate "$user" "$mode" "$arg" 3 "$W/mig"
  echo "--- catalogue after step 1"
  P -d "$db" -Atc "select 'owner '||n.nspname||'.'||c.relname||' ('||c.relkind::text||') = '||pg_get_userbyid(c.relowner) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='app' and c.relkind in ('r','S') order by 1" 2>&1 | head -12
  P -d "$db" -Atc "select 'history rank='||installed_rank||' v='||coalesce(version,'-')||' installed_by='||installed_by||' success='||success from app.flyway_schema_history order by installed_rank" 2>&1 | head -8
  P -d "$db" -Atc "select 'who: session_user='||session_user_name||' current_user='||current_user_name from app.who" 2>&1 | head -3
  echo "--- step 2: migrate to latest as $user (V4 = CREATE ROLE, privileged: must fail safely)"
  FL migrate "$user" "$mode" "$arg" latest "$W/mig"
  P -d "$db" -Atc "select 'after step 2: history rows='||count(*)||' ; role spike_priv_role exists='||(select count(*) from pg_roles where rolname='spike_priv_role') from app.flyway_schema_history" 2>&1 | head -3
  docker logs s52pg-bot-p5 2>&1 | tail -n +$((mark+1)) > "$D/s52-logs/$name.server.log"
  echo "--- server log: connections and role/history statements (pid shows which connection ran what)"
  grep -E "connection authorized|SET ROLE|CURRENT_USER|current_user|CREATE TABLE .app.\..flyway_schema_history|ERROR" "$D/s52-logs/$name.server.log" | sed -E 's/^[0-9-]+ [0-9:.]+ [A-Z]+ //' | cut -c1-200 | head -${LOGN:-30}
}
cand control-initSql     deploy_rt  initSql      "SET ROLE migrator" c0
cand afterConnect-sql    deploy_rt  callbackdir  "$W/cb-afterConnect" c1
cand beforeMigrate-sql   deploy_rt  callbackdir  "$W/cb-beforeMigrate" c2
cand beforeValidate-sql  deploy_rt  callbackdir  "$W/cb-beforeValidate" c3
cand url-options         deploy_rt  urlopt       "-c role=migrator" c4
cand jdbc-properties     deploy_rt  jdbcprop     "-c role=migrator" c5
P -c "ALTER ROLE deploy_rt2 SET role = 'migrator'"
cand role-default        deploy_rt2 none         "" c6
cand java-AFTER_CONNECT  deploy_rt  javacb       "AFTER_CONNECT" c7
cand java-BEFORE_VALIDATE deploy_rt javacb       "BEFORE_VALIDATE" c8
echo; echo "container removed on exit"
