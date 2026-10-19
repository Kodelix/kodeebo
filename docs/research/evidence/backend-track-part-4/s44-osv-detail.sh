#!/bin/sh
# s44-osv-detail.sh - read OSV record GO-2026-5932 (hit on golang.org/x/crypto 0.58.0 in s42). Run: sh s44-osv-detail.sh > s44-osv-detail.output.txt 2>&1
curl -fsS --max-time 25 https://api.osv.dev/v1/vulns/GO-2026-5932 | jq '{id, aliases, summary, published, modified, details: (.details|.[0:700]), affected: [.affected[] | {pkg: .package.name, ranges: .ranges, symbols: (.ecosystem_specific.imports // [] | map({path, symbols}))}]}'
