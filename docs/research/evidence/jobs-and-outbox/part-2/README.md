# Evidence index: jobs-and-outbox part 2 (2026-10-20)

All runs are read-only HTTP GETs. Nothing was pulled, installed or downloaded beyond two stub pages (24 KB, gitignored cache `production/session-state/cache/jobs-and-outbox/`, delete at merge).

| Spike | Script | Output | Status |
|---|---|---|---|
| S20 | `S20-registry-lookup.sh` | `S20-output.txt` | ran; GitHub release/licence fields and one OSV query. Kafka and Debezium `releases/latest` returned "Not Found" (those repos publish no GitHub releases): their OSV queries did not run. |
| S21 | `S21-licences-and-images.sh` | `S21-output.txt` | ran; licence file heads, Debezium tags, Docker Hub tag metadata. Kafka downloads grep returned nothing (page is a redirect stub, see S22). `meilisearch/meilisearch` and `debezium/server` image lookups returned nothing (wrong repository names or no such tag). |
| S22 | `S22-kafka-docs.sh` | `S22-output.txt` | **wrong premise, kept: failed run.** `kafka.apache.org/downloads` is a 243-byte stub with no `url=` target, so no documentation was fetched. See F213 and F218 in the note. |
