#!/bin/sh
# d-pg-time.sh - run d-pg-time.sql against the pinned postgres:18.6 image; needs d-billing-vectors.json (run d-billing-run.sh first). Run from this directory.
D=$(dirname "$0"); cd "$D" || exit 1
echo "# d-pg-time $(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker rm -f d-pgtime >/dev/null 2>&1
docker run -d --name d-pgtime -e POSTGRES_HOST_AUTH_METHOD=trust postgres:18.6 >/dev/null
for i in $(seq 1 40); do docker exec d-pgtime pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 2
echo "image tzdata header: $(docker exec d-pgtime sh -c 'head -1 /usr/share/zoneinfo/tzdata.zi')"
echo "pg_config tzdata: $(docker exec d-pgtime sh -c 'pg_config --configure' | tr ' ' '\n' | grep -i tzdata)"
docker cp d-billing-vectors.json d-pgtime:/tmp/d-billing-vectors.json
docker cp d-pg-time.sql d-pgtime:/tmp/d-pg-time.sql
docker exec d-pgtime psql -U postgres -X -q -f /tmp/d-pg-time.sql 2>&1
docker cp d-pgtime:/tmp/d-billing-out-sql.txt d-billing-out-sql.txt
cmp d-billing-expected-python.txt d-billing-out-sql.txt && echo "python == sql: identical ($(wc -l < d-billing-out-sql.txt) lines, sha256 $(sha256sum < d-billing-out-sql.txt | cut -c1-16))"
docker rm -f d-pgtime >/dev/null
