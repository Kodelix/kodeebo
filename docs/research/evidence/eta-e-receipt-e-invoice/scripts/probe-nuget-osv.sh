#!/bin/sh
# Tier-E probe: (1) list published versions of the ETA toolkit NuGet package; (2) query OSV for known advisories. Read-only public endpoints, no credentials.
# Usage: probe-nuget-osv.sh <out-dir>
o="$1"; date -u +"run at %Y-%m-%dT%H:%M:%SZ" > "$o/probe-nuget-osv.out.txt"
echo "## nuget flat container index" >> "$o/probe-nuget-osv.out.txt"
curl -sS -m 40 -w "\nHTTP %{http_code}\n" https://api.nuget.org/v3-flatcontainer/eta.ereceipt.integrationtoolkit/index.json >> "$o/probe-nuget-osv.out.txt" 2>&1
echo "## OSV query (NuGet / ETA.eReceipt.IntegrationToolkit)" >> "$o/probe-nuget-osv.out.txt"
curl -sS -m 40 -X POST -H 'Content-Type: application/json' -d '{"package":{"name":"ETA.eReceipt.IntegrationToolkit","ecosystem":"NuGet"}}' -w "\nHTTP %{http_code}\n" https://api.osv.dev/v1/query >> "$o/probe-nuget-osv.out.txt" 2>&1
