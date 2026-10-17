#!/usr/bin/env bash
# S70 runner (tier E). Starts a throw-away postgres:18.6 container, runs s70-setup.sql and s70-tests.sql with real
# SCRAM logins, then the login-expiry, replication-backup and pgaudit-availability checks. Output: s70-output.txt.
set -u
cd "$(dirname "$0")"
C=ti-p7-pg
docker rm -f $C >/dev/null 2>&1
docker run -d --name $C -e POSTGRES_PASSWORD=fixture postgres:18.6 >/dev/null
for i in $(seq 1 60); do docker exec $C pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 3
IP=$(docker exec $C hostname -i | awk '{print $1}')
export PGPASSWORD=fixture
P="docker exec -i -e PGPASSWORD=fixture $C psql -X -a -h $IP -U postgres -d postgres"
{
echo "# date: $(date -u +%FT%TZ)  image: postgres:18.6  container IP (scram path): $IP"
docker exec $C postgres --version
echo "##### SETUP"; $P < s70-setup.sql 2>&1
echo "##### TESTS"; $P < s70-tests.sql 2>&1
echo "##### T8 login of a role whose VALID UNTIL is in the past (SCRAM over TCP) -> expect failure"
docker exec -e PGPASSWORD=fixture $C psql -X -h $IP -U support_exp -d p7 -c 'select current_user' 2>&1
echo "##### T8b same role over the local socket (image pg_hba: local = trust, so no password is checked)"
docker exec $C psql -X -U support_exp -d p7 -c 'select current_user' 2>&1
echo "##### T9 REPLICATION-only role (not superuser, not BYPASSRLS) takes a base backup; do the files hold tenant rows in clear?"
docker exec $C bash -c 'rm -rf /tmp/bk; pg_basebackup -h 127.0.0.1 -U backup_rt -D /tmp/bk -Fp -X fetch -c fast 2>&1; echo "exit=$?"; grep -rl "SECRET-A-ROW-1" /tmp/bk | head -3; grep -rl "SECRET-B-ROW-1" /tmp/bk | head -3'
echo "##### T10 pgaudit available in the image?"
docker exec $C bash -c 'psql -X -U postgres -Atc "select name, default_version from pg_available_extensions where name ilike '"'"'%audit%'"'"'"; echo "(rows above; empty = none)"; ls $(pg_config --pkglibdir) | grep -i audit; echo "ls-grep exit=$?"'
} > s70-output.txt 2>&1
docker rm -f $C >/dev/null 2>&1
echo done
