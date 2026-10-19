// harness.js - loads the Go WASM build in Node and replays the billing vectors. Args: wasm_exec.js, bill.wasm, vectors.json
const fs = require('fs');
const [,, wasmExec, wasm, vec] = process.argv;
require(wasmExec);
(async () => {
  const go = new Go();
  const t0 = process.hrtime.bigint();
  const r = await WebAssembly.instantiate(fs.readFileSync(wasm), go.importObject);
  go.run(r.instance);
  const t1 = process.hrtime.bigint();
  const cases = JSON.parse(fs.readFileSync(vec, 'utf8'));
  const t2 = process.hrtime.bigint();
  const out = cases.map(c => `${c.id},${kodeeboAmount(JSON.stringify(c))}`);
  const t3 = process.hrtime.bigint();
  fs.writeSync(1, out.join('\n') + '\n');
  console.error(`node ${process.version} wasm_load_ms=${Number(t1 - t0) / 1e6} calls_ms=${Number(t3 - t2) / 1e6} n=${cases.length}`);
  process.exit(0);
})();
