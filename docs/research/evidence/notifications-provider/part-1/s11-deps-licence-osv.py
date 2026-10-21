# S11: (1) licence text head and pom dependency versions for Angus Mail 2.0.5 and Simple Java Mail 9.3.8,
# (2) OSV query under the right package names (F116), (3) locate the SMTP property documentation in the Angus 2.0.5 tag.
# Read-only network, no credentials, no jar download. Run: python3 -I <this file> from the repo root.
import json, re, urllib.request
R = "docs/research/evidence/notifications-provider/part-1/raw/"
def get(u, post=None):
    rq = urllib.request.Request(u, data=post, headers={"User-Agent": "kodeebo-researcher", "Content-Type": "application/json"})
    with urllib.request.urlopen(rq, timeout=40) as x: return x.read()
lic = get("https://raw.githubusercontent.com/eclipse-ee4j/angus-mail/2.0.5/LICENSE.md").decode()
open(R + "angus-LICENSE.md", "w").write(lic)
print("== Angus LICENSE.md head"); print(lic[:700].replace("\n\n", "\n"))
for n in ("NOTICE.md",):
    try:
        t = get("https://raw.githubusercontent.com/eclipse-ee4j/angus-mail/2.0.5/" + n).decode(); open(R + "angus-" + n, "w").write(t)
        print("== NOTICE head"); print(t[:900])
    except Exception as e: print("NOTICE ERR", e)
pom = open(R + "angus-mail-2.0.5.pom").read()
print("== angus-mail 2.0.5 pom: groupId/artifactId/version of dependencies")
for m in re.finditer(r"<dependency>(.*?)</dependency>", pom, re.S):
    b = m.group(1); g = lambda t: (re.search("<%s>(.*?)</%s>" % (t, t), b) or [None, "-"])[1]
    print(g("groupId"), g("artifactId"), g("version"), g("scope"))
sj = get("https://repo1.maven.org/maven2/org/simplejavamail/simple-java-mail/9.3.8/simple-java-mail-9.3.8.pom").decode()
open(R + "sjm-9.3.8.pom", "w").write(sj)
print("== simple-java-mail 9.3.8 pom dependencies")
for m in re.finditer(r"<dependency>(.*?)</dependency>", sj, re.S):
    b = m.group(1); g = lambda t: (re.search("<%s>(.*?)</%s>" % (t, t), b) or [None, "-"])[1]
    print(g("groupId"), g("artifactId"), g("version"), g("scope"))
print("== OSV querybatch, right names")
q = {"queries": [
 {"package": {"ecosystem": "Maven", "name": "org.eclipse.angus:smtp"}, "version": "2.0.5"},
 {"package": {"ecosystem": "Maven", "name": "org.eclipse.angus:smtp"}, "version": "2.0.3"},
 {"package": {"ecosystem": "Maven", "name": "org.eclipse.angus:angus-core"}, "version": "2.0.5"},
 {"package": {"ecosystem": "Maven", "name": "org.simplejavamail:simple-java-mail"}, "version": "9.3.8"},
 {"package": {"ecosystem": "Maven", "name": "org.simplejavamail:core-module"}, "version": "9.3.8"}]}
r = json.loads(get("https://api.osv.dev/v1/querybatch", json.dumps(q).encode()))
open(R + "osv-result-2.json", "w").write(json.dumps(r))
for qq, rr in zip(q["queries"], r["results"]):
    print(qq["package"]["name"], qq["version"], [v["id"] for v in rr.get("vulns", [])])
print("== SMTP property docs location in tag 2.0.5")
t = json.loads(get("https://api.github.com/repos/eclipse-ee4j/angus-mail/git/trees/2.0.5?recursive=1"))
paths = [x["path"] for x in t["tree"] if "smtp" in x["path"] and re.search(r"package(-info\.java|\.html)|SMTPTransport\.java|SMTPAddressSucceededException|SMTPSendFailedException", x["path"])]
print(paths)
