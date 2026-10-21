# S12: (1) SMTP property docs of Angus Mail 2.0.5 (package-info.java + SMTPTransport.sendMessage javadoc) ; (2) ASVS 5.0.0 requirement rows.
# Read-only network, no credentials. Run: python3 -I <this file> from the repo root.
import json, re, urllib.request
R = "docs/research/evidence/notifications-provider/part-1/raw/"
def get(u):
    rq = urllib.request.Request(u, headers={"User-Agent": "kodeebo-researcher"})
    with urllib.request.urlopen(rq, timeout=60) as x: return x.read().decode("utf-8", "replace")
base = "https://raw.githubusercontent.com/eclipse-ee4j/angus-mail/2.0.5/providers/smtp/src/main/java/org/eclipse/angus/mail/smtp/"
pi = get(base + "package-info.java"); open(R + "angus-smtp-package-info.java", "w").write(pi)
tx = get(base + "SMTPTransport.java"); open(R + "angus-SMTPTransport.java", "w").write(tx)
print("package-info bytes", len(pi), "SMTPTransport bytes", len(tx))
names = ["connectiontimeout", "timeout", "writetimeout", "sendpartial", "from", "starttls.enable", "starttls.required", "ssl.checkserveridentity", "ssl.enable", "ssl.protocols", "auth.mechanisms", "allow8bitmime", "dsn.notify", "dsn.ret", "submitter", "reportsuccess", "localhost", "quitwait", "connectionpool", "mailextension", "ehlo", "sasl", "auth.disable", "auth.plain.disable", "noop.strict", "userset"]
lines = pi.splitlines()
for n in names:
    key = "mail.smtp." + n
    for i, l in enumerate(lines):
        if re.search(r"<td>\s*" + re.escape(key) + r"\s*</td>", l) or (key in l and "<td" in l and l.strip().startswith(("<td", "*  <td", "* <td"))):
            print("--", key, "|", " ".join(x.strip(" *") for x in lines[i:i+6])[:430]); break
    else: print("--", key, "| NOT FOUND in package-info")
print("== SMTPTransport.sendMessage javadoc and partial handling")
i = tx.find("public synchronized void sendMessage")
print(re.sub(r"\s+", " ", tx[max(0, i-2400):i])[-2100:])
for m in re.finditer(r"sendPartial|reportSuccess", tx): pass
print("== uses of sendPartial in SMTPTransport (line numbers)")
for n, l in enumerate(tx.splitlines(), 1):
    if "sendPartial" in l: print(n, l.strip()[:150])
# ASVS
tree = json.loads(get("https://api.github.com/repos/OWASP/ASVS/git/trees/v5.0.0?recursive=1"))["tree"]
files = [x["path"] for x in tree if x["path"].startswith("5.0/en/0x") and x["path"].endswith(".md")]
print("== ASVS files", files)
want = re.compile(r"\*\*(12\.3\.\d+|13\.3\.\d+|13\.2\.\d+|2\.4\.\d+|2\.3\.\d+|14\.2\.\d+|16\.2\.\d+|16\.3\.\d+|6\.4\.\d+|1\.2\.\d+|1\.3\.\d+|5\.2\.\d+)\*\*")
for f in files:
    if not re.search(r"V(2|5|6|12|13|14|16)-", f): continue
    t = get("https://raw.githubusercontent.com/OWASP/ASVS/v5.0.0/" + f); open(R + "asvs-" + f.split("/")[-1], "w").write(t)
    for l in t.splitlines():
        m = want.search(l)
        if m: print(f.split("/")[-1][:12], re.sub(r"\s+", " ", l)[:300])
