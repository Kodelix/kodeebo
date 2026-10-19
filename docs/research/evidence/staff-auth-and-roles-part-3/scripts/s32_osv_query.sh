#!/usr/bin/env bash
# S32 run 2 - OSV querybatch (includes GitHub Security Advisories), 2026-10-19. Argument: path to the query JSON. The last query (electron 22.3.27, an old line) is a control that should return advisories.
curl -sS --max-time 60 -X POST -H 'Content-Type: application/json' --data-binary @"$1" https://api.osv.dev/v1/querybatch
