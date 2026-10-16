#!/bin/sh
# d-billing-run.sh - cross-language determinism of billing algorithm A. Run from this directory: sh d-billing-run.sh
# Versions printed below. Date of the run is in the output file header.
D=$(dirname "$0"); cd "$D" || exit 1
echo "# d-billing-run $(date -u +%Y-%m-%dT%H:%M:%SZ)"; python3 --version; go version; java -version 2>&1 | head -1; node --version
python3 -I d-billing-gen.py . 
go run d-billing.go d-billing-vectors.json > d-billing-out-go.txt
java d-Billing.java d-billing-vectors.json > d-billing-out-java.txt
node d-billing.js d-billing-vectors.json > d-billing-out-node.txt
for f in python go java node; do
  src=d-billing-out-$f.txt; [ "$f" = python ] && src=d-billing-expected-python.txt
  printf '%s lines=%s sha256=%s\n' "$f" "$(wc -l < $src)" "$(sha256sum < $src | cut -c1-16)"
done
for f in go java node; do cmp d-billing-expected-python.txt d-billing-out-$f.txt && echo "python == $f: identical"; done
