#!/usr/bin/env bash
# S30: library status + advisories. Read-only metadata queries, no downloads of artifacts.
# Run: bash s30-lib-status.sh   (curl + jq). Date of run is printed.
set -u
echo "date_utc: $(date -u +%FT%TZ)"
echo "== GitHub repo metadata (archived, pushed_at, licence) =="
for r in exaring/otelpgx XSAM/otelsql mozilla-services/pkcs7 smallstep/pkcs7 hhrutter/pkcs7 unidoc/pkcs7 OpenICP-BR/libICP bcgit/bc-java PeculiarVentures/PKI.js digitalbazaar/forge; do
  curl -s -m 20 "https://api.github.com/repos/$r" | jq -c --arg r "$r" '{repo:$r, archived, pushed_at, license:(.license.spdx_id // .message // "none")}'
done
echo "== Go proxy latest =="
for m in github.com/exaring/otelpgx github.com/XSAM/otelsql github.com/smallstep/pkcs7 github.com/hhrutter/pkcs7 github.com/OpenICP-BR/libICP; do
  printf '%s ' "$m"; curl -s -m 20 "https://proxy.golang.org/$m/@latest" | jq -c '{Version,Time}' 2>/dev/null || echo "no-answer"
done
echo "== Maven Central latest (search API) =="
for a in "org.bouncycastle:bcpkix-jdk18on" "org.bouncycastle:bcprov-jdk18on" "eu.europa.ec.joinup.sd-dss:dss-cades"; do
  g=${a%%:*}; i=${a##*:}
  printf '%s ' "$a"; curl -s -m 20 "https://search.maven.org/solrsearch/select?q=g:%22$g%22+AND+a:%22$i%22&rows=1&wt=json" | jq -c '.response.docs[0] | {latestVersion, timestamp}' 2>/dev/null || echo "no-answer"
done
echo "== npm latest =="
for p in pkijs asn1js node-forge; do
  printf '%s ' "$p"; curl -s -m 20 "https://registry.npmjs.org/$p" | jq -c '{v:."dist-tags".latest, license:.license}' 2>/dev/null || echo "no-answer"
done
echo "== OSV querybatch (advisory count per pinned package; 0 = none returned) =="
cat > /dev/stdout <<'EOQ'
EOQ
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"go.opentelemetry.io/otel","ecosystem":"Go"},"version":"1.47.0"}' | jq -c '{q:"go otel 1.47.0", n:(.vulns|length // 0)}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"github.com/exaring/otelpgx","ecosystem":"Go"}}' | jq -c '{q:"otelpgx (all versions)", ids:([.vulns[]?.id])}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"org.bouncycastle:bcpkix-jdk18on","ecosystem":"Maven"},"version":"1.86"}' | jq -c '{q:"bcpkix 1.86", ids:([.vulns[]?.id])}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"pkijs","ecosystem":"npm"}}' | jq -c '{q:"pkijs (all versions)", ids:([.vulns[]?.id])}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"node-forge","ecosystem":"npm"}}' | jq -c '{q:"node-forge (all versions)", n:([.vulns[]?.id]|length)}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"github.com/smallstep/pkcs7","ecosystem":"Go"}}' | jq -c '{q:"smallstep/pkcs7 (all versions)", ids:([.vulns[]?.id])}'
curl -s -m 30 -X POST https://api.osv.dev/v1/query -d '{"package":{"name":"go.mozilla.org/pkcs7","ecosystem":"Go"}}' | jq -c '{q:"go.mozilla.org/pkcs7 (all versions)", ids:([.vulns[]?.id])}'
