#!/usr/bin/env bash
# S13b run: follow-up probe. Usage: run-s13b.sh <run-number>
set -u
R=/home/kiko/saas-products/kodeebo
E=$R/docs/research/evidence/module-structure-and-core-boundary/part-3
PGPORT=57613 java -cp "$R/production/session-state/cache/module-structure-and-core-boundary/part-3/jars/*" "$E/scripts/S13b.java" "$E/s13/work-b$1" 2>&1
