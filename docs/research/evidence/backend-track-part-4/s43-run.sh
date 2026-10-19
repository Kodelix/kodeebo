#!/bin/sh
# s43-run.sh - S41 spike: ONE Go source of the billing function, compiled to (1) WASM run in Node and (2) a c-shared library called from the JVM.
# Run from the repository root: sh docs/research/evidence/backend-track-part-4/s43-run.sh > docs/research/evidence/backend-track-part-4/s43-run.output.txt 2>&1
E=docs/research/evidence/backend-track-part-4
echo "# s43-run $(date -u +%Y-%m-%dT%H:%M:%SZ)"; go version; java -version 2>&1 | head -1; node --version; gcc --version | head -1; uname -sr
python3 -I docs/research/evidence/local-first-sync/d-billing-gen.py $E/s43-data
jq -c '.[]' $E/s43-data/d-billing-vectors.json > $E/s43-data/vectors.jsonl
wc -l $E/s43-data/vectors.jsonl
echo "## build"
( cd $E/s43-src && GOOS=js GOARCH=wasm go build -o ../s43-build/bill.wasm . && echo "wasm build ok" )
( cd $E/s43-src && CGO_ENABLED=1 go build -buildmode=c-shared -o ../s43-build/libbill.so . && echo "c-shared build ok" )
ls -l $E/s43-build
echo "## run: Node + Go WASM"
node $E/s43-src/harness.js "$(go env GOROOT)/lib/wasm/wasm_exec.js" $E/s43-build/bill.wasm $E/s43-data/d-billing-vectors.json > $E/s43-data/out-wasm.txt
echo "## run: JVM FFM + Go c-shared"
java --enable-preview --source 21 --enable-native-access=ALL-UNNAMED $E/s43-src/Harness.java $E/s43-build/libbill.so $E/s43-data/vectors.jsonl > $E/s43-data/out-jvm.txt
for f in wasm jvm; do
  printf '%s lines=%s sha256=%s\n' $f "$(wc -l < $E/s43-data/out-$f.txt)" "$(sha256sum < $E/s43-data/out-$f.txt | cut -c1-16)"
  cmp $E/s43-data/d-billing-expected-python.txt $E/s43-data/out-$f.txt && echo "python reference == $f: identical"
done
printf 'python lines=%s sha256=%s\n' "$(wc -l < $E/s43-data/d-billing-expected-python.txt)" "$(sha256sum < $E/s43-data/d-billing-expected-python.txt | cut -c1-16)"
