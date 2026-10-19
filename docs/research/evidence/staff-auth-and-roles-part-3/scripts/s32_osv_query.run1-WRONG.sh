#!/usr/bin/env bash
# S32 - OSV advisory query for the versions this part relies on. Run 2026-10-19. POST https://api.osv.dev/v1/querybatch (OSV includes GitHub Security Advisories).
cat > /dev/stdin <<'JSON' | curl -sS --max-time 60 -X POST -H 'Content-Type: application/json' -d @- https://api.osv.dev/v1/querybatch
{"queries":[
 {"package":{"name":"io.ktor:ktor-server-auth-jvm","ecosystem":"Maven"},"version":"3.6.0"},
 {"package":{"name":"io.ktor:ktor-server-sessions-jvm","ecosystem":"Maven"},"version":"3.6.0"},
 {"package":{"name":"io.ktor:ktor-server-core-jvm","ecosystem":"Maven"},"version":"3.6.0"},
 {"package":{"name":"org.jetbrains.exposed:exposed-core","ecosystem":"Maven"},"version":"1.5.1"},
 {"package":{"name":"electron","ecosystem":"npm"},"version":"44.8.0"},
 {"package":{"name":"io.ktor:ktor-server-core-jvm","ecosystem":"Maven"},"version":"3.1.0"}
]}
JSON
