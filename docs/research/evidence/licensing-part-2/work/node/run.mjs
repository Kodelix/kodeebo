import { readFileSync } from 'node:fs';
import { verify, createPublicKey } from 'node:crypto';
import { ed25519 } from '@noble/curves/ed25519.js';
const vs = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const hdr = Buffer.from('302a300506032b6570032100', 'hex'); // SPKI prefix for OID 1.3.101.112 (RFC 8410), bytes built here, key appended
const t = (f) => { try { return String(f()); } catch (e) { return 'THROW(' + (e.code || e.name) + ')'; } };
console.log('node', process.version, 'openssl', process.versions.openssl);
for (const v of vs) {
  const pub = Buffer.from(v.pub, 'hex'), msg = Buffer.from(v.msg, 'hex'), sig = Buffer.from(v.sig, 'hex');
  const a = t(() => verify(null, msg, createPublicKey({ key: Buffer.concat([hdr, pub]), format: 'der', type: 'spki' }), sig));
  const b = t(() => ed25519.verify(sig, msg, pub));
  const c = t(() => ed25519.verify(sig, msg, pub, { zip215: false }));
  console.log(v.name.padEnd(55), 'node:crypto=' + a.padEnd(28), 'noble-default=' + b.padEnd(22), 'noble-zip215:false=' + c);
}
