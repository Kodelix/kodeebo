#!/usr/bin/env bash
# S13 run: Flyway 13.10.3 library, offline (jars from cache), own container msc-part3-pg on 127.0.0.1:57613.
# Usage: run-s13.sh <run-number>  -> work dir docs/research/evidence/.../part-3/s13/work-<n> (kept as evidence)
set -u
R=/home/kiko/saas-products/kodeebo
E=$R/docs/research/evidence/module-structure-and-core-boundary/part-3
PGPORT=57613 java -cp "$R/production/session-state/cache/module-structure-and-core-boundary/part-3/jars/*" "$E/scripts/S13.java" "$E/s13/work-$1" 2>&1
