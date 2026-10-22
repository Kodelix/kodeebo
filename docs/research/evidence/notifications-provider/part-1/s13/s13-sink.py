"""S13 throwaway SMTP/IMAP sink. Python 3 stdlib only. Run: python3 -I s13-sink.py <tls-dir> <log-dir> <ports-file>

Binds 127.0.0.1 only, one listener (ephemeral port) per scripted scenario, implicit TLS (like 465/993)
with a certificate generated per run by the runner. The accepted login password comes from the
environment variable SINK_PW (generated per run by the runner); no secret literal exists in this file.
Per connection it writes <log-dir>/<scenario>.<n>.cmds.txt (timestamped command/reply log, AUTH data
redacted) and <scenario>.<n>.data.bin (the raw DATA bytes up to the end-of-data dot).
Not production code, not a security tool.
"""
import base64, os, socket, ssl, struct, sys, threading, time

TLS_DIR, LOG_DIR, PORTS_FILE = sys.argv[1], sys.argv[2], sys.argv[3]
PW = os.environ["SINK_PW"]
USER = "no-reply@example.test"
HOST = "sink.example.test"
CAP = 30  # seconds: every stall ends by itself

# Per-scenario script. Defaults: good certificate, SMTP, every reply positive.
SCEN = {
    "ok_good": {},
    "ok_wrong": {"cert": "wrong"},
    "ok_untrusted": {"cert": "untrusted"},
    "stall_tcp": {"tls": False},                       # TCP accepted, TLS handshake never answered
    "stall_greeting": {"greet": False},                # TLS ok, no 220 / no IMAP greeting
    "stall_dot": {"after_dot": "stall"},               # end-of-data dot received, no reply, connection held
    "stall_read_data": {"after_354": "stop_reading"},  # 354 sent, then the sink stops reading
    "close_dot": {"after_dot": "close"},               # dot received, FIN without a reply
    "rst_dot": {"after_dot": "rst"},                   # dot received, RST without a reply
    "close_354": {"after_354": "close"},               # 354 sent, closed before any body is read
    "close_data_cmd": {"on_data": "close"},            # DATA command received, closed without a reply
    "close_rcpt": {"on_rcpt": "close"},                # RCPT received, closed without a reply
    "mail_550": {"mail": "550 5.7.1 sender refused"},
    "rcpt_552": {"rcpt": "552 5.2.2 mailbox full"},
    "rcpt_550": {"rcpt": "550 5.1.1 no such user"},
    "rcpt_450": {"rcpt": "450 4.2.0 mailbox busy"},
    "auth_535": {"auth": "535 5.7.8 Authentication credentials invalid"},
    "data_cmd_554": {"data": "554 5.5.1 no valid recipients"},
    "dot_451": {"dot": "451 4.3.0 local error in processing"},
    "dot_554": {"dot": "554 5.6.0 message rejected"},
    "imap_greet_stall": {"proto": "imap"},              # IMAP greeting, then silence
}

counters = {}
lock = threading.Lock()


class Conn:
    def __init__(self, scen):
        with lock:
            counters[scen] = counters.get(scen, 0) + 1
            self.n = counters[scen]
        self.scen = scen
        self.t0 = time.monotonic()
        self.f = open(f"{LOG_DIR}/{scen}.{self.n}.cmds.txt", "w", buffering=1)

    def log(self, s):
        self.f.write(f"+{time.monotonic() - self.t0:.3f} {s}\n")


def contexts():
    out = {}
    for name in ("good", "wrong", "untrusted"):
        c = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        c.load_cert_chain(f"{TLS_DIR}/{name}.pem", f"{TLS_DIR}/{name}.key")
        out[name] = c
    return out


CTX = contexts()


def wait_close(c, conn):
    conn.settimeout(CAP)
    try:
        while True:
            if not conn.recv(4096):
                c.log("EVENT client closed (EOF)")
                return
    except socket.timeout:
        c.log(f"EVENT stall cap {CAP}s reached, sink closes")
    except (ssl.SSLError, OSError) as e:
        c.log(f"EVENT client closed ({type(e).__name__})")


def send(c, conn, text):
    c.log("S: " + text.replace("\r\n", " | ").strip(" |"))
    conn.sendall(text.encode() if isinstance(text, str) else text)


def creds_ok(b64):
    try:
        parts = base64.b64decode(b64.strip()).split(b"\0")
        return parts[-2].decode() == USER and parts[-1].decode() == PW
    except Exception:
        return False


def smtp(c, conn, cfg):
    f = conn.makefile("rb")
    if not cfg.get("greet", True):
        c.log("EVENT sink sends no greeting")
        wait_close(c, conn)
        return
    send(c, conn, f"220 {HOST} ESMTP ready\r\n")
    authed = False
    while True:
        line = f.readline()
        if not line:
            c.log("EVENT client closed (EOF)")
            return
        text = line.decode("utf-8", "replace").rstrip("\r\n")
        verb = text[:4].upper()
        if verb in ("EHLO", "HELO"):
            c.log("C: " + text)
            send(c, conn, f"250-{HOST}\r\n250-AUTH PLAIN LOGIN\r\n250-8BITMIME\r\n250 SIZE 104857600\r\n")
        elif verb == "AUTH":
            mech = text.split()[1].upper() if len(text.split()) > 1 else ""
            c.log(f"C: AUTH {mech} <redacted>")
            ok = False
            if mech == "PLAIN":
                arg = text.split(None, 2)[2] if len(text.split()) > 2 else None
                if arg is None:
                    send(c, conn, "334 \r\n")
                    arg = f.readline().decode().strip()
                    c.log("C: <auth data redacted>")
                ok = creds_ok(arg)
            elif mech == "LOGIN":
                parts = text.split(None, 2)
                if len(parts) > 2:
                    user = parts[2]
                else:
                    send(c, conn, "334 VXNlcm5hbWU6\r\n")
                    user = f.readline().decode().strip()
                    c.log("C: <auth data redacted>")
                send(c, conn, "334 UGFzc3dvcmQ6\r\n")
                pw = f.readline().decode().strip()
                c.log("C: <auth data redacted>")
                try:
                    ok = base64.b64decode(user).decode() == USER and base64.b64decode(pw).decode() == PW
                except Exception:
                    ok = False
            if "auth" in cfg:
                send(c, conn, cfg["auth"] + "\r\n")
                continue
            if ok:
                authed = True
                send(c, conn, "235 2.7.0 Authentication successful\r\n")
            else:
                send(c, conn, "535 5.7.8 credentials did not match the per-run value\r\n")
        elif verb == "MAIL":
            c.log("C: " + text)
            send(c, conn, cfg.get("mail", "250 2.1.0 OK") + "\r\n")
        elif verb == "RCPT":
            c.log("C: " + text)
            if cfg.get("on_rcpt") == "close":
                c.log("EVENT sink closes without a reply")
                return
            send(c, conn, cfg.get("rcpt", "250 2.1.5 OK") + "\r\n")
        elif verb == "DATA":
            c.log("C: DATA")
            if cfg.get("on_data") == "close":
                c.log("EVENT sink closes without a reply")
                return
            reply = cfg.get("data", "354 End data with <CR><LF>.<CR><LF>")
            send(c, conn, reply + "\r\n")
            if not reply.startswith("354"):
                continue
            if cfg.get("after_354") == "close":
                c.log("EVENT sink closes after 354")
                return
            if cfg.get("after_354") == "stop_reading":
                c.log("EVENT sink stops reading the body and holds the connection")
                time.sleep(CAP)
                return
            body = b""
            while True:
                ln = f.readline()
                if not ln:
                    c.log("EVENT client closed during DATA")
                    return
                if ln == b".\r\n":
                    break
                body += ln
            c.log(f"EVENT end-of-data dot received, body {len(body)} bytes")
            with open(f"{LOG_DIR}/{c.scen}.{c.n}.data.bin", "wb") as df:
                df.write(body)
            ad = cfg.get("after_dot")
            if ad == "close":
                c.log("EVENT sink closes without a reply")
                return
            if ad == "rst":
                c.log("EVENT sink resets (SO_LINGER 0) without a reply")
                conn.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack("ii", 1, 0))
                return
            if ad == "stall":
                c.log("EVENT sink holds the connection without a reply")
                wait_close(c, conn)
                return
            send(c, conn, cfg.get("dot", "250 2.0.0 queued as TESTID1") + "\r\n")
        elif verb == "QUIT":
            c.log("C: QUIT")
            send(c, conn, "221 2.0.0 bye\r\n")
            return
        elif verb in ("RSET", "NOOP"):
            c.log("C: " + text)
            send(c, conn, "250 OK\r\n")
        else:
            c.log("C: " + text[:80])
            send(c, conn, "500 5.5.2 unrecognised\r\n")


def imap(c, conn, cfg):
    send(c, conn, "* OK [CAPABILITY IMAP4rev1 AUTH=PLAIN] sink ready\r\n")
    c.log("EVENT IMAP greeting sent; the sink now stays silent")
    wait_close(c, conn)


def handle(scen, raw, cfg):
    c = Conn(scen)
    try:
        raw.settimeout(CAP)
        c.log("EVENT tcp accepted")
        if cfg.get("tls") is False:
            c.log("EVENT sink does not answer the TLS handshake")
            wait_close(c, raw)
            return
        conn = CTX[cfg.get("cert", "good")].wrap_socket(raw, server_side=True)
        c.log(f"EVENT tls {conn.version()} {conn.cipher()[0]} cert={cfg.get('cert', 'good')}")
        (imap if cfg.get("proto") == "imap" else smtp)(c, conn, cfg)
        if cfg.get("proto") == "imap":
            return
    except Exception as e:  # noqa: BLE001 - a throwaway sink logs and moves on
        c.log(f"EVENT {type(e).__name__}: {e}")
    finally:
        try:
            raw.close()
        except OSError:
            pass
        c.f.close()


def serve(scen, cfg, srv):
    while True:
        raw, _ = srv.accept()
        threading.Thread(target=handle, args=(scen, raw, cfg), daemon=True).start()


ports = []
for scen, cfg in SCEN.items():
    srv = socket.socket()
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", 0))
    srv.listen(32)
    ports.append(f"{scen} {srv.getsockname()[1]}")
    threading.Thread(target=serve, args=(scen, cfg, srv), daemon=True).start()
with open(PORTS_FILE + ".tmp", "w") as pf:
    pf.write("\n".join(ports) + "\n")
os.rename(PORTS_FILE + ".tmp", PORTS_FILE)
while True:
    time.sleep(3600)
