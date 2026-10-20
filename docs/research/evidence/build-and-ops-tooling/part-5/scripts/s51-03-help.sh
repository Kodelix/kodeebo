#!/bin/bash
# S51 step 3: version and help text of Trivy v0.76.0 under the scanner condition (no network, no input).
set -u
. "$(dirname "$0")/s51-lib.sh"
chmod 0644 "$CACHE"/images/*.tar
echo "date_utc: $(date -u +%FT%TZ)"
echo "docker flags: ${SCAN_DOCKER_FLAGS[*]}  --entrypoint /opt/trivy/trivy $RUNTIME <args>"
for args in "--version" "image --help" "sbom --help" "convert --help"; do
  echo; echo "######## trivy $args"
  docker run "${SCAN_DOCKER_FLAGS[@]}" --entrypoint /opt/trivy/trivy "$RUNTIME" $args 2>&1
  echo "exit status: $?"
done
