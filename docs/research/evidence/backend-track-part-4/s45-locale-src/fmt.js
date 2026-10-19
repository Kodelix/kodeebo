// fmt.js - Node Intl formatting, same inputs as Fmt.java. Run: node fmt.js
console.log('node', process.version, 'icu', process.versions.icu, 'cldr', process.versions.cldr, 'unicode', process.versions.unicode);
for (const tag of ['ar-EG', 'ar-EG-u-nu-latn', 'en-EG', 'en-US']) {
  const c = new Intl.NumberFormat(tag, { style: 'currency', currency: 'EGP' });
  const n = new Intl.NumberFormat(tag);
  const d = new Intl.DateTimeFormat(tag, { dateStyle: 'medium', timeStyle: 'medium', timeZone: 'Africa/Cairo' });
  console.log(tag, 'currency(1234567.5)=' + c.format(1234567.5), ' currency(0.5)=' + c.format(0.5), ' number(1234567.5)=' + n.format(1234567.5));
  console.log(tag, 'date=' + d.format(new Date('2026-10-18T21:05:00Z')));
}
