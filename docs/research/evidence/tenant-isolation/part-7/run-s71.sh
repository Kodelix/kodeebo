#!/usr/bin/env bash
# S71 runner (tier E): corrected rerun of S70 plus T10 recheck. Output: s71-output.txt.
set -u
cd "$(dirname "$0")"
C=ti-p7-pg
docker rm -f $C >/dev/null 2>&1
docker run -d --name $C -e POSTGRES_PASSWORD=fixture postgres:18.6 >/dev/null
for i in $(seq 1 60); do docker exec $C pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 3
IP=$(docker exec $C hostname -i | awk '{print $1}')
P="docker exec -i -e PGPASSWORD=fixture $C psql -X -a -h $IP -U postgres -d postgres"
{
echo "# date: $(date -u +%FT%TZ)  image: postgres:18.6  container IP: $IP"
docker exec $C postgres --version
echo "##### SETUP (s70-setup.sql, unchanged)"; $P < s70-setup.sql 2>&1
echo "##### TESTS (s71-tests.sql)"; $P < s71-tests.sql 2>&1
echo "##### T10 recheck"; docker exec -i $C bash -s < t10.sh 2>&1
} > s71-output.txt 2>&1
docker rm -f $C >/dev/null 2>&1
echo done
