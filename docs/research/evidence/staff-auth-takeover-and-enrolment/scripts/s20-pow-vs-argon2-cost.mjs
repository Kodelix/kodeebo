// S20 (tier E, indicative): cost of (a) a SHA-256 hash-search proof of work, (b) PBKDF2-SHA256 (ALTCHA default family),
// versus (c) one Argon2id verification at the ADR-0007 floor (m=19456 KiB, t=2, p=1), all on THIS host (not the VPS, not a phone).
// Node built-ins only (no install, no download). Run: node s20-pow-vs-argon2-cost.mjs
import { createHash, pbkdf2Sync, argon2Sync, randomBytes } from 'node:crypto';
import os from 'node:os';
const now = () => Number(process.hrtime.bigint()) / 1e9;
console.log('node', process.version, '| cpu', os.cpus()[0].model, '| logical cpus', os.cpus().length, '| date', new Date().toISOString());
const salt = randomBytes(16).toString('hex');
let N = 2_000_000, t0 = now();
for (let i = 0; i < N; i++) createHash('sha256').update(salt + i).digest();
let dt = now() - t0;
const sha = N / dt;
console.log(`(a) SHA-256 (createHash per try): ${sha.toFixed(0)} hashes/s single thread (${N} tries in ${dt.toFixed(2)} s)`);
for (const max of [50_000, 100_000, 500_000, 1_000_000]) console.log(`    maxnumber ${max}: expected ${(max/2/sha).toFixed(3)} s mean to solve on this host (max/2 tries)`);
for (const iters of [1000, 10000, 100000]) {
  const n = iters >= 100000 ? 20 : 200; t0 = now();
  for (let i = 0; i < n; i++) pbkdf2Sync(salt + i, salt, iters, 32, 'sha256');
  dt = now() - t0; console.log(`(b) PBKDF2-SHA256 ${iters} iterations: ${(dt/n*1000).toFixed(3)} ms per try`);
}
const params = { message: Buffer.from('correct horse battery staple'), nonce: randomBytes(16), parallelism: 1, tagLength: 32, memory: 19456, passes: 2 };
argon2Sync('argon2id', params);
const ts = [];
for (let i = 0; i < 30; i++) { t0 = now(); argon2Sync('argon2id', params); ts.push((now() - t0) * 1000); }
ts.sort((a, b) => a - b);
const med = ts[15];
console.log(`(c) Argon2id m=19456 KiB t=2 p=1: median ${med.toFixed(2)} ms, min ${ts[0].toFixed(2)}, max ${ts[29].toFixed(2)} (30 runs, one at a time)`);
console.log(`    => one core verifies about ${(1000/med).toFixed(0)}/s; ${os.cpus().length} logical cpus on this host (VPS has 2 vCPU: NOT measured here)`);
console.log(`    => ratio: one Argon2id verify = ${(med/1000*sha).toFixed(0)} SHA-256 tries on this host`);
console.log(`    => memory: 19456 KiB = ${(19456/1024).toFixed(1)} MiB per concurrent verify; 8 concurrent = ${(8*19456/1024).toFixed(0)} MiB`);
