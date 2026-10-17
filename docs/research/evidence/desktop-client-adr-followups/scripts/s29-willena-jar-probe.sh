#!/usr/bin/env bash
# S29 (part 2): inspect the io.github.willena:sqlite-jdbc 3.53.4.0 jar from Maven Central: bundled licence/notice entries, and embedded SQLite / SQLite3MC version strings
# in the Windows x86_64 DLL. The jar is untrusted data: downloaded into its own new dir, read with python zipfile in isolated mode (-I), nothing executed.
# Usage: s29-willena-jar-probe.sh <new-empty-download-dir> <outfile-dir>
set -u
dl="$1"; out="$2"; mkdir -p "$dl" "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
M=https://repo1.maven.org/maven2/io/github/willena/sqlite-jdbc/3.53.4.0
code=$(curl -sS --max-time 90 -o "$dl/sqlite-jdbc-3.53.4.0.jar" -w '%{http_code}' "$M/sqlite-jdbc-3.53.4.0.jar"); echo "jar HTTP $code size $(wc -c < "$dl/sqlite-jdbc-3.53.4.0.jar")"
sha256sum "$dl/sqlite-jdbc-3.53.4.0.jar"
curl -sS --max-time 30 "$M/" | grep -o 'href="[^"]*"' | head -20
python3 -I - "$dl/sqlite-jdbc-3.53.4.0.jar" "$out" <<'PY'
import sys, zipfile, re
jar, out = sys.argv[1], sys.argv[2]
z = zipfile.ZipFile(jar)
names = z.namelist()
print("entries:", len(names))
for n in names:
    if re.search(r"(?i)(licen[cs]e|notice|copying|META-INF/MANIFEST|\.dll$|\.so$|\.dylib$|native)", n) and not n.endswith("/"):
        print("  ", n, z.getinfo(n).file_size)
for n in names:
    if re.search(r"(?i)META-INF/(LICENSE|NOTICE)", n) and not n.endswith("/"):
        data = z.read(n)
        open(out + "/jar-" + n.replace("/", "_"), "wb").write(data)
        print("---", n, len(data), "bytes; head:", data[:300].decode("utf-8", "replace").replace("\n", " | "))
for n in names:
    if re.search(r"(?i)windows.*x86_64.*\.dll$|x86_64.*windows.*\.dll$", n):
        b = z.read(n)
        print("DLL", n, len(b))
        for pat in (rb"SQLite version 3\.\d+\.\d+[^\x00]{0,20}", rb"3\.5\d\.\d+(?:\.\d+)?", rb"SQLite3 Multiple Ciphers[^\x00]{0,60}", rb"sqlite3mc[^\x00]{0,40}\d+\.\d+\.\d+", rb"SQLITE_SOURCE_ID[^\x00]{0,10}|\d{4}-\d\d-\d\d \d\d:\d\d:\d\d [0-9a-f]{40,}"):
            found = sorted(set(re.findall(pat, b)))[:6]
            print("  pattern", pat[:40], "->", [f.decode("latin-1") for f in found])
PY
