#!/usr/bin/env bash
# S26: read Caddy v2.11.7 source (tier 3) to attribute behaviours seen in S25 (underscore headers, header_up deletion matching, forwarded headers, client_ip).
# Usage: bash run.sh > output.txt 2>&1
set -u
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
curl -sSL -o "$D/c.tgz" https://github.com/caddyserver/caddy/archive/refs/tags/v2.11.7.tar.gz && tar xzf "$D/c.tgz" -C "$D" && R="$D/caddy-2.11.7" && echo "### fetched caddy v2.11.7 source archive"
echo; echo "===== grep: underscore / invalid header handling in caddyhttp"
grep -rn -i "underscore\|strict_header\|ValidHeaderField\|invalid header" "$R/modules/caddyhttp" --include=*.go | grep -v _test.go | head -20
echo; echo "===== headers.go: ApplyTo delete matching"
sed -n "$(grep -n 'func (ops HeaderOps) ApplyTo' $R/modules/caddyhttp/headers/headers.go | cut -d: -f1),+60p" "$R/modules/caddyhttp/headers/headers.go"
echo; echo "===== reverseproxy.go: addForwardedHeaders"
sed -n "$(grep -n 'func (h Handler) addForwardedHeaders' $R/modules/caddyhttp/reverseproxy/reverseproxy.go | cut -d: -f1),+45p" "$R/modules/caddyhttp/reverseproxy/reverseproxy.go"
echo; echo "===== reverseproxy.go: hop-by-hop / Connection header handling"
grep -n -i "hop-by-hop\|hopHeaders\|Connection" "$R/modules/caddyhttp/reverseproxy/reverseproxy.go" | head -30
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
