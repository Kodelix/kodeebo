#!/usr/bin/env bash
# S20 (tier 3 lookup script, not a behavioural test): latest GitHub release + licence per project, and OSV query by exact version.
# Run: bash S20-registry-lookup.sh > S20-output.txt   Date: 2026-10-20. Read-only HTTP GETs, unauthenticated; no downloads of artifacts.
set -u
echo "# S20 run $(date -u +%FT%TZ)"; curl --version | head -1; jq --version
for repo in nats-io/nats-server rabbitmq/rabbitmq-server apache/kafka debezium/debezium meilisearch/meilisearch typesense/typesense opensearch-project/OpenSearch elastic/elasticsearch valkey-io/valkey; do
  echo "== $repo"
  curl -s "https://api.github.com/repos/$repo" | jq -c '{full_name, license: .license.spdx_id, archived, pushed_at}'
  curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -c '{tag_name, published_at, prerelease, message}'
done
echo "== OSV (exact version queries; versions taken from the lines above)"
osv() { echo "-- $1 $2 $3"; curl -s -X POST https://api.osv.dev/v1/query -d "{\"version\":\"$3\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$1\"}}" | jq -c '{n: (.vulns|length? // 0), ids: [.vulns[]?.id]}'; }
NATS=$(curl -s https://api.github.com/repos/nats-io/nats-server/releases/latest | jq -r .tag_name | sed 's/^v//')
osv Go github.com/nats-io/nats-server/v2 "$NATS"
KAFKA=$(curl -s https://api.github.com/repos/apache/kafka/releases/latest | jq -r '.tag_name // empty')
echo "kafka latest tag: ${KAFKA:-none}"
[ -n "${KAFKA:-}" ] && osv Maven org.apache.kafka:kafka-clients "$KAFKA"
DBZ=$(curl -s https://api.github.com/repos/debezium/debezium/releases/latest | jq -r '.tag_name // empty' | sed 's/^v//')
[ -n "$DBZ" ] && osv Maven io.debezium:debezium-core "$DBZ"
