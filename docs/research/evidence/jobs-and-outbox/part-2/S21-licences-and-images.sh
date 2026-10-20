#!/usr/bin/env bash
# S21 (tier 3 lookup script): licence file heads, Kafka/Debezium current versions, Docker Hub compressed image sizes (metadata only, no pulls).
# Run: bash S21-licences-and-images.sh > S21-output.txt   Date: 2026-10-20. Read-only HTTP GETs.
set -u
echo "# S21 run $(date -u +%FT%TZ)"
head_of() { echo "=== $1"; curl -s "$1" | head -n "${2:-14}" | cut -c1-200; }
head_of https://raw.githubusercontent.com/rabbitmq/rabbitmq-server/main/LICENSE 12
head_of https://raw.githubusercontent.com/meilisearch/meilisearch/main/LICENSE 12
head_of https://raw.githubusercontent.com/elastic/elasticsearch/main/LICENSE.txt 12
echo "=== elasticsearch licence dir"; curl -s https://api.github.com/repos/elastic/elasticsearch/contents/licenses | jq -r '.[]?.name' | head
echo "=== meilisearch root files"; curl -s https://api.github.com/repos/meilisearch/meilisearch/contents | jq -r '.[]?.name' | grep -i licen
echo "=== Kafka downloads page (newest tarball names)"
curl -s https://kafka.apache.org/downloads | grep -oE 'kafka_2\.13-[0-9]+\.[0-9]+\.[0-9]+\.tgz' | sort -uV | tail -4
echo "=== Debezium release tags (non-pre-release names, newest last)"
curl -s "https://api.github.com/repos/debezium/debezium/tags?per_page=40" | jq -r '.[].name' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+\.Final$' | sort -V | tail -3
echo "=== Docker Hub compressed sizes (full_size bytes, amd64 entries), tag filter by name"
hub() { echo "-- $1 :: $2"; curl -s "https://hub.docker.com/v2/repositories/$1/tags?name=$2&page_size=5" | jq -c '.results[]? | {name, last_updated, amd64: ([.images[]? | select(.architecture=="amd64") | .size] | first)}'; }
hub library/nats 2.15.1-alpine
hub library/rabbitmq 4.4.0-alpine
hub valkey/valkey 9.1.2-alpine
hub meilisearch/meilisearch v1.55.0
hub getmeili/meilisearch v1.55.0
hub typesense/typesense 30.2
hub opensearchproject/opensearch 3.9.0
hub apache/kafka latest
hub debezium/server latest
hub library/postgres 18.6-alpine
