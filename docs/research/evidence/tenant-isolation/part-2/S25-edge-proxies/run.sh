#!/usr/bin/env bash
# S25: Caddy 2.11.7 and Traefik 3.7.14 as edge proxy: spoofed tenant/forwarding headers, client IP, access/error log content.
# Usage: bash run.sh > output.txt 2>&1     Needs docker, curl; images caddy:2.11.7-alpine, traefik:v3.7.14.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NET=ti-p2-proxynet
cleanup() { docker rm -fv ti-p2-up ti-p2-edge >/dev/null 2>&1; docker network rm $NET >/dev/null 2>&1; }
trap cleanup EXIT; cleanup
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### caddy: $(docker run --rm caddy:2.11.7-alpine caddy version)"
echo "### traefik: $(docker run --rm traefik:v3.7.14 traefik version | tr '\n' ' ')"
echo "### $(docker --version)"
docker network create $NET >/dev/null
GW=$(docker network inspect $NET -f '{{(index .IPAM.Config 0).Gateway}}'); echo "### bridge gateway (the TCP peer seen by the edge when curl runs on the host): $GW"
# upstream = neutral Go net/http echo (echo-go/main.go, built: cd echo-go && CGO_ENABLED=0 go build -o /tmp/ti-p2-tools/echo .); the first exploratory run used a Caddy echo, which drops underscore headers itself
docker run -d --name ti-p2-up --network $NET --entrypoint /echo -v /tmp/ti-p2-tools/echo:/echo:ro caddy:2.11.7-alpine >/dev/null

start_caddy()   { docker rm -fv ti-p2-edge >/dev/null 2>&1; docker run -d --name ti-p2-edge --network $NET -v "$HERE/$1:/etc/caddy/Caddyfile:ro" caddy:2.11.7-alpine >/dev/null; }
start_traefik() { docker rm -fv ti-p2-edge >/dev/null 2>&1; docker run -d --name ti-p2-edge --network $NET -v "$HERE/$1:/etc/traefik/traefik.yml:ro" -v "$HERE/traefik-dynamic.yml:/etc/traefik/dynamic.yml:ro" traefik:v3.7.14 >/dev/null; }

SPOOF=(
  -H 'X-Tenant-Id: evil-tenant' -H 'X-Tenant-Slug: evil-slug' -H 'X-Tenant: bare-tenant-header' -H 'X-Tenantdomain: evil-no-hyphen'
  -H 'X_Tenant_Id: underscore-variant' -H 'X-Tenant-Foo: other-suffix'
  -H 'X-Forwarded-For: 6.6.6.6' -H 'X-Forwarded-Host: evil.example' -H 'X-Forwarded-Proto: https'
  -H 'X-Forwarded-Prefix: /t/evil' -H 'X-Forwarded-Port: 4443' -H 'X-Forwarded-Server: evil-server'
  -H 'Forwarded: for=6.6.6.6;proto=https' -H 'X-Real-IP: 7.7.7.7' -H 'X-Client-IP: 9.9.9.9'
  -H 'Referer: http://app.example/t/cafe-slug/menu?x=1'
  -H 'Traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01'
)
run_requests() { # $1 = label, $2 = IP of edge
  local ip=$2
  for _ in $(seq 1 60); do curl -s -o /dev/null "http://$ip/healthprobe" && break; sleep 0.25; done
  sleep 1; SINCE=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ); sleep 1
  echo; echo "--- R1: GET /t/cafe-slug/menu?x=1 with spoofed headers -> upstream echo"
  curl -sS -i "${SPOOF[@]}" "http://$ip/t/cafe-slug/menu?x=1" | tee /tmp/ti-p2-r1.txt
  echo; echo "--- R2: same, plus Connection: X-Client-Ip, X-Forwarded-For (hop-by-hop abuse)"
  curl -sS -i "${SPOOF[@]}" -H 'Connection: X-Client-Ip, X-Forwarded-For' "http://$ip/t/cafe-slug/menu?x=1" | tee /tmp/ti-p2-r2.txt
  echo; echo "--- R3: GET /dead/t/cafe-slug/menu (upstream dial failure -> 502)"
  curl -sS -i "${SPOOF[@]}" "http://$ip/dead/t/cafe-slug/menu" | head -5
  sleep 1
  echo; echo "--- edge container log since $SINCE (all lines)"
  docker logs --since "$SINCE" ti-p2-edge 2>&1 | tee /tmp/ti-p2-log.txt
}
hdr() { grep -E "^HDR $1:" "$2" | head -1 || true; }
show() { # $1 file ; prints the headers of interest as seen by the upstream, or ABSENT
  for h in X-Tenant-Id X-Tenant-Slug X-Tenant X-Tenantdomain X_Tenant_Id X-Tenant-Foo X-Forwarded-For X-Forwarded-Host X-Forwarded-Proto X-Forwarded-Prefix X-Forwarded-Port X-Forwarded-Server Forwarded X-Real-Ip X-Client-Ip Traceparent; do
    l=$(grep -iE "^HDR $h:" "$1" | head -1); echo "  $h => ${l:-ABSENT}"
  done
}

echo; echo "=================== CADDY 2.11.7: Caddyfile.edge (header_up -X-Tenant*, global+site log filters)"
start_caddy Caddyfile.edge; IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" ti-p2-edge)
run_requests caddy "$IP"
echo; echo "--- what the upstream saw (R1)"; show /tmp/ti-p2-r1.txt
echo; echo "--- what the upstream saw (R2, Connection: X-Client-Ip, X-Forwarded-For)"; show /tmp/ti-p2-r2.txt

echo; echo "=================== CADDY 2.11.7: Caddyfile.edge.plain (plain reverse_proxy, no header_up: default behaviour)"
start_caddy Caddyfile.edge.plain; IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" ti-p2-edge)
for _ in $(seq 1 40); do curl -s -o /dev/null "http://$IP/healthprobe" && break; sleep 0.25; done
curl -sS "${SPOOF[@]}" "http://$IP/t/cafe-slug/menu?x=1" > /tmp/ti-p2-r1.txt; show /tmp/ti-p2-r1.txt
echo "--- Caddy plain: underscore header sent directly to the Caddy edge, raw request via nc-free curl --http1.1 -v (request headers as sent)"
curl -sS -v -H 'X_Tenant_Id: u1' "http://$IP/x" 2>&1 | grep -E "^> X_|^HDR X_" 

echo; echo "=================== CADDY 2.11.7: Caddyfile.edge.trusted (peer inside trusted_proxies)"
start_caddy Caddyfile.edge.trusted; IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" ti-p2-edge)
for _ in $(seq 1 40); do curl -s -o /dev/null "http://$IP/healthprobe" && break; sleep 0.25; done
curl -sS -H 'X-Forwarded-For: 6.6.6.6' "http://$IP/x" | grep -E "^HDR (X-Forwarded-For|X-Client-Ip):"

for V in default hardened; do
  echo; echo "=================== TRAEFIK 3.7.14: traefik-$V.yml (middleware 'strip' = customRequestHeaders with empty values)"
  start_traefik traefik-$V.yml; IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" ti-p2-edge)
  run_requests traefik-$V "$IP"
  echo; echo "--- what the upstream saw (R1)"; show /tmp/ti-p2-r1.txt
  echo; echo "--- what the upstream saw (R2, Connection: X-Client-Ip, X-Forwarded-For)"; show /tmp/ti-p2-r2.txt
done

echo; echo "=================== TRAEFIK 3.7.14 with forwardedHeaders.trustedIPs = bridge range (peer trusted)"
sed 's|address: ":80"|address: ":80"\n    forwardedHeaders:\n      trustedIPs: ["172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8"]|' "$HERE/traefik-default.yml" > /tmp/ti-p2-traefik-trusted.yml
cp /tmp/ti-p2-traefik-trusted.yml "$HERE/traefik-trusted.yml"
start_traefik traefik-trusted.yml; IP=$(docker inspect -f "{{(index .NetworkSettings.Networks \"$NET\").IPAddress}}" ti-p2-edge)
for _ in $(seq 1 60); do curl -s -o /dev/null "http://$IP/healthprobe" && break; sleep 0.25; done
curl -sS -H 'X-Forwarded-For: 6.6.6.6' -H 'X-Forwarded-Proto: https' "http://$IP/x" | grep -E "^HDR (X-Forwarded-For|X-Forwarded-Proto|X-Forwarded-Host):"
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
