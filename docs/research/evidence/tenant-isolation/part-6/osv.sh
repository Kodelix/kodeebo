#!/usr/bin/env bash
# OSV query for each pinned version used by the tests (POST https://api.osv.dev/v1/query); date: $(date -u +%F)
q() { echo "### $1 $2 $3"; curl -sS -m 30 -X POST https://api.osv.dev/v1/query -d "{\"version\":\"$3\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$1\"}}" | head -c 1500; echo; }
q Go github.com/jackc/pgx/v5 v5.11.0
q npm playwright 1.64.0
q npm vitest 5.0.3
q npm react 19.3.0
q npm vite 8.3.4
q Maven io.ktor:ktor-server-core 3.6.0
q Maven org.jetbrains.exposed:exposed-core 1.5.1
