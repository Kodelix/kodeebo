// d-billing.js - Node reference of billing algorithm A using BigInt. Run: node d-billing.js <vectors.json>
const fs = require('fs'); const cases = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); const out = [];
const fdiv = (a, b) => { let q = a / b; if (a % b !== 0n && ((a < 0n) !== (b < 0n))) q -= 1n; return q; };
for (const c of cases) {
  let total = 0n, num = 0n; for (const s of c.segments) { total += BigInt(s.elapsed_ms); num += BigInt(s.elapsed_ms) * BigInt(s.rate_pph); }
  const min = BigInt(c.min_billable_minutes) * 60000n, unit = BigInt(c.increment_minutes) * 60000n;
  let f = total > min ? total : min, r;
  if (c.mode === 'up') r = (f + unit - 1n) / unit * unit; else if (c.mode === 'down') r = f / unit * unit; else r = (2n * f + unit) / (2n * unit) * unit;
  if (min > r) r = min; num += (r - total) * BigInt(c.segments[c.segments.length - 1].rate_pph);
  out.push(`${c.id},${fdiv(2n * num + 3600000n, 2n * 3600000n)}`);
}
console.log(out.join('\n'));
