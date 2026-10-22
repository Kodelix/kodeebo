import jakarta.mail.*;
import jakarta.mail.internet.*;
import javax.net.ssl.SSLSocketFactory;
import java.io.IOException;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.regex.*;

/**
 * S13: Angus Mail 2.0.5 against the local throwaway sink (s13-sink.py). Throwaway code, not product code.
 * Usage: java -cp <jars> Spike.java <ports-file> <sink-log-dir>   (SINK_PW from the environment)
 * Every case prints a RESULT line (PASS or FAIL) with the measured facts.
 */
public class Spike {
    static final Map<String, Integer> PORTS = new HashMap<>();
    static Path SINK;
    static final String PW = System.getenv("SINK_PW");
    static final String USER = "no-reply@example.test";
    static final String HOST = "localhost";
    static final ExecutorService EX = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "spike-worker");
        t.setDaemon(true);
        return t;
    });
    static final List<String> SUMMARY = new ArrayList<>();

    interface Mk { MimeMessage make(Session s) throws Exception; }

    static void p(String s) { System.out.println(s); }

    static void result(String id, boolean pass, String detail) {
        String l = "RESULT " + id + " " + (pass ? "PASS" : "FAIL") + " - " + detail;
        p(l);
        SUMMARY.add(l);
    }

    static String one(String s) {
        if (s == null) return "null";
        s = s.replace("\r", "\\r").replace("\n", "\\n");
        return s.length() > 280 ? s.substring(0, 280) + "..." : s;
    }

    static long ms(long startNanos) { return (System.nanoTime() - startNanos) / 1_000_000; }

    static Object q(Object o, String m) {
        try { return o.getClass().getMethod(m).invoke(o); } catch (Throwable e) { return null; }
    }

    static Throwable next(Throwable t) {
        if (t instanceof MessagingException me && me.getNextException() != null) return me.getNextException();
        return t.getCause();
    }

    static List<Throwable> all(Throwable t) {
        List<Throwable> l = new ArrayList<>();
        Set<Throwable> seen = Collections.newSetFromMap(new IdentityHashMap<>());
        while (t != null && seen.add(t) && l.size() < 10) { l.add(t); t = next(t); }
        return l;
    }

    static String addrs(Address[] a) {
        if (a == null) return "null";
        StringBuilder sb = new StringBuilder("[");
        for (Address x : a) sb.append(x).append(' ');
        return sb.append(']').toString();
    }

    static String chain(Throwable t) {
        StringBuilder sb = new StringBuilder();
        for (Throwable x : all(t)) {
            if (sb.length() > 0) sb.append("\n      <- ");
            sb.append(x.getClass().getName()).append(" (\"").append(one(x.getMessage())).append("\")");
            Object rc = q(x, "getReturnCode"), cmd = q(x, "getCommand");
            if (rc != null) sb.append(" getReturnCode=").append(rc);
            if (cmd != null) sb.append(" getCommand=\"").append(one(cmd.toString())).append("\"");
            if (x instanceof SendFailedException sfe) {
                sb.append(" validSent=").append(addrs(sfe.getValidSentAddresses()))
                  .append(" validUnsent=").append(addrs(sfe.getValidUnsentAddresses()))
                  .append(" invalid=").append(addrs(sfe.getInvalidAddresses()));
            }
        }
        return sb.toString();
    }

    /** The mapper ADR-0013 Decision 3 asks for, built only from what the library exposes. */
    static String classify(Throwable e, Object lastRc) {
        if (e == null) return "ACCEPTED";
        for (Throwable x : all(e)) {
            if (x instanceof javax.net.ssl.SSLException || x instanceof java.security.cert.CertificateException)
                return "CONFIG_FAULT(tls)";
            if (x instanceof AuthenticationFailedException) return "CONFIG_FAULT(auth)";
        }
        for (Throwable x : all(e)) {
            Object rc = q(x, "getReturnCode"), cmd = q(x, "getCommand");
            if (rc instanceof Integer r && cmd != null) {
                String c = cmd.toString().trim().toUpperCase(Locale.ROOT);
                if (c.startsWith("MAIL")) return "CONFIG_FAULT(mail from " + r + ")";
                if (c.startsWith("RCPT")) return r >= 500 ? "REJECTED(recipient " + r + ")" : "TRANSIENT(rcpt " + r + ")";
                if (c.startsWith("DATA")) return r >= 500 ? "REJECTED(message, to DATA " + r + ")" : "TRANSIENT(data " + r + ")";
                if (c.equals(".")) return r >= 500 ? "REJECTED(message, to dot " + r + ")" : "TRANSIENT(dot " + r + ")";
                return "UNCLASSIFIED(cmd=" + c + " rc=" + r + ")";
            }
        }
        boolean io = false;
        for (Throwable x : all(e)) if (x instanceof IOException) io = true;
        if (io || e instanceof MessagingException) {
            return (lastRc instanceof Integer r && r == 354) ? "AMBIGUOUS(I/O after DATA began)" : "TRANSIENT(I/O before DATA)";
        }
        return "UNCLASSIFIED";
    }

    static Properties props(String proto, int conn, int read, int write) {
        Properties p = new Properties();
        String x = "mail." + proto + ".";
        if (conn > 0) p.put(x + "connectiontimeout", String.valueOf(conn));
        if (read > 0) p.put(x + "timeout", String.valueOf(read));
        if (write > 0) p.put(x + "writetimeout", String.valueOf(write));
        p.put(x + "auth", "true");
        p.put(x + "ssl.checkserveridentity", "true");
        p.put(x + "localhost", "mail.example.test");
        p.put(x + "from", "bounces+t1.i1@example.test");
        return p;
    }

    /** Message whose Message-ID is chosen by the application (Decision 2). */
    static class FixedIdMessage extends MimeMessage {
        final String id;
        FixedIdMessage(Session s, String id) { super(s); this.id = id; }
        @Override protected void updateMessageID() throws MessagingException { setHeader("Message-ID", id); }
    }

    static MimeMessage msg(Session s, String id, String to, String body, String subject) throws Exception {
        MimeMessage m = id == null ? new MimeMessage(s) : new FixedIdMessage(s, id);
        m.setFrom(new InternetAddress(USER));
        m.setRecipient(Message.RecipientType.TO, new InternetAddress(to));
        m.setSubject(subject, "UTF-8");
        m.setText(body, "UTF-8");
        m.saveChanges();
        return m;
    }

    static MimeMessage std(Session s) throws Exception {
        return msg(s, "<std-1@example.test>", "rcpt@example.test", "hello", "S13 test");
    }

    static class Tracker extends SSLSocketFactory {
        final SSLSocketFactory d = (SSLSocketFactory) SSLSocketFactory.getDefault();
        final List<Socket> all = new CopyOnWriteArrayList<>();
        <T extends Socket> T r(T s) { all.add(s); return s; }
        public String[] getDefaultCipherSuites() { return d.getDefaultCipherSuites(); }
        public String[] getSupportedCipherSuites() { return d.getSupportedCipherSuites(); }
        public Socket createSocket(Socket s, String h, int po, boolean ac) throws IOException { all.add(s); return r(d.createSocket(s, h, po, ac)); }
        public Socket createSocket(String h, int po) throws IOException { return r(d.createSocket(h, po)); }
        public Socket createSocket(String h, int po, InetAddress la, int lp) throws IOException { return r(d.createSocket(h, po, la, lp)); }
        public Socket createSocket(InetAddress h, int po) throws IOException { return r(d.createSocket(h, po)); }
        public Socket createSocket(InetAddress a, int po, InetAddress la, int lp) throws IOException { return r(d.createSocket(a, po, la, lp)); }
        public Socket createSocket() throws IOException { return r(d.createSocket()); }
    }

    static class Out {
        volatile long endMs = -1, connectDoneMs = -1, sendStartMs = -1, wdReturnMs = -1;
        volatile Throwable err, wdErr;
        volatile boolean ok, capped;
        volatile Object lastRc, lastResp;
        volatile Boolean connectedAtFail;
    }

    /** One SMTPS send on a worker thread. wd: 0 none, 1 watchdog calls Transport.close(), 2 watchdog closes tracked sockets. */
    static Out run(String scen, Properties pr, Mk mk, long capMs, int wd, long wdAt, Tracker tr) throws Exception {
        Out o = new Out();
        Session s = Session.getInstance(pr);
        Transport t = s.getTransport("smtps");
        long st = System.nanoTime();
        if (wd != 0) {
            Thread w = new Thread(() -> {
                try { Thread.sleep(wdAt); } catch (InterruptedException e) { return; }
                try {
                    if (wd == 1) t.close(); else for (Socket k : tr.all) k.close();
                } catch (Throwable e) { o.wdErr = e; }
                o.wdReturnMs = ms(st);
            }, "watchdog");
            w.setDaemon(true);
            w.start();
        }
        Future<?> f = EX.submit(() -> {
            try {
                t.connect(HOST, PORTS.get(scen), USER, PW);
                o.connectDoneMs = ms(st);
                MimeMessage m = mk.make(s);
                o.sendStartMs = ms(st);
                t.sendMessage(m, m.getAllRecipients());
                o.ok = true;
            } catch (Throwable e) {
                o.err = e;
                o.lastRc = q(t, "getLastReturnCode");
                o.lastResp = q(t, "getLastServerResponse");
                o.connectedAtFail = t.isConnected();
            } finally {
                o.endMs = ms(st);
                try { t.close(); } catch (Throwable ignore) { }
            }
        });
        try { f.get(capMs, TimeUnit.MILLISECONDS); } catch (TimeoutException e) { o.capped = true; }
        return o;
    }

    static Out runImap(String scen, Properties pr, long capMs) throws Exception {
        Out o = new Out();
        Session s = Session.getInstance(pr);
        Store store = s.getStore("imaps");
        long st = System.nanoTime();
        Future<?> f = EX.submit(() -> {
            try {
                store.connect(HOST, PORTS.get(scen), "bounces@example.test", PW);
                o.ok = true;
            } catch (Throwable e) {
                o.err = e;
            } finally {
                o.endMs = ms(st);
                try { store.close(); } catch (Throwable ignore) { }
            }
        });
        try { f.get(capMs, TimeUnit.MILLISECONDS); } catch (TimeoutException e) { o.capped = true; }
        return o;
    }

    static String desc(Out o) {
        return "endMs=" + (o.capped ? "NOT ENDED at cap" : String.valueOf(o.endMs)) + " connectDoneMs=" + o.connectDoneMs
            + " sendStartMs=" + o.sendStartMs + " ok=" + o.ok + " lastReturnCode=" + o.lastRc + " lastServerResponse=\""
            + one(String.valueOf(o.lastResp)) + "\" isConnectedAtFail=" + o.connectedAtFail
            + "\n    exception: " + (o.err == null ? "-" : chain(o.err))
            + "\n    classify -> " + (o.capped ? "n/a" : classify(o.err, o.lastRc));
    }

    // ---- sink files ----
    static Path latest(String sc, String suffix) throws IOException {
        try (var st = Files.list(SINK)) {
            return st.filter(f -> { String n = f.getFileName().toString(); return n.startsWith(sc + ".") && n.endsWith(suffix); })
                .max(Comparator.comparingInt(f -> Integer.parseInt(f.getFileName().toString().split("\\.")[1]))).orElse(null);
        }
    }

    static List<String> cmds(String sc) throws IOException {
        Path f = latest(sc, ".cmds.txt");
        List<String> out = new ArrayList<>();
        if (f != null) for (String l : Files.readAllLines(f)) out.add(l.replaceFirst("^\\+[0-9.]+ ", ""));
        return out;
    }

    static String data(String sc) throws IOException {
        Path f = latest(sc, ".data.bin");
        return f == null ? "" : new String(Files.readAllBytes(f), StandardCharsets.ISO_8859_1);
    }

    // ---- cases ----
    static void case1() throws Exception {
        p("\n=== CASE 1: timeouts and watchdog (scaled for speed: connect 1000, read 1500, write 1500 ms; hard cap 12000 ms per send) ===");
        final int C = 1000, R = 1500, W = 1500;
        final long CAP = 12000;

        Out a = run("stall_greeting", props("smtps", C, R, W), Spike::std, CAP, 0, 0, null);
        p("[1a] sink: TLS ok, no 220 greeting\n    " + desc(a));
        result("1a", !a.capped && a.err != null && a.endMs <= R + 1000, "greeting stall ended " + a.endMs + " ms after start (read timeout " + R + ")");

        Out b = run("stall_tcp", props("smtps", C, R, W), Spike::std, CAP, 0, 0, null);
        p("[1b] sink: TCP accepted, TLS handshake never answered\n    " + desc(b));
        result("1b", !b.capped && b.err != null && b.endMs <= C + R + 1000, "handshake stall " + (b.capped ? "NOT bounded within the " + CAP + " ms cap" : "ended " + b.endMs + " ms") + " (connect " + C + ", read " + R + ")");

        Out c = run("stall_dot", props("smtps", C, R, W), Spike::std, CAP, 0, 0, null);
        p("[1c] sink: dot received, no reply, connection held\n    " + desc(c));
        long cSend = c.endMs - c.sendStartMs;
        result("1c", !c.capped && c.err != null && cSend <= R + 1000, "stall after the dot ended " + cSend + " ms after sendMessage began (read timeout " + R + ")");

        StringBuilder big = new StringBuilder();
        String line = "A".repeat(79) + "\n";
        for (int i = 0; i < 500_000; i++) big.append(line);
        String bigS = big.toString();
        Out d = run("stall_read_data", props("smtps", C, R, W), s -> msg(s, "<big-1@example.test>", "rcpt@example.test", bigS, "S13 big"), CAP, 0, 0, null);
        p("[1d] sink: 354 sent, then the sink stops reading a ~40 MB body\n    " + desc(d));
        long dSend = d.endMs - d.sendStartMs;
        result("1d", !d.capped && d.err != null && dSend <= Math.max(W, R) + 1000, "blocked write " + (d.capped ? "NOT bounded within cap" : "ended " + dSend + " ms after sendMessage began") + " (write timeout " + W + ")");

        Out e = run("stall_greeting", props("smtps", 0, 0, 0), Spike::std, 4000, 0, 0, null);
        p("[1e] CONTROL, no timeout properties, same greeting stall, cap 4000 ms\n    " + desc(e));
        result("1e", e.capped, "without timeouts the send " + (e.capped ? "was still blocked at the 4000 ms cap (default is infinite)" : "ended after " + e.endMs + " ms"));

        Out f1 = run("stall_greeting", props("smtps", C, 8000, 8000), Spike::std, CAP, 1, 2000, null);
        p("[1f] watchdog at 2000 ms calls Transport.close(); backstop read timeout 8000; sink: no greeting (blocked inside connect())\n    watchdog close() returned at " + f1.wdReturnMs + " ms, wdErr=" + f1.wdErr + "\n    " + desc(f1));
        result("1f", f1.wdReturnMs >= 0 && f1.wdReturnMs <= 2500 && !f1.capped && f1.endMs <= 2500, "Transport.close() returned at " + f1.wdReturnMs + " ms; blocked connect() ended at " + f1.endMs + " ms (deadline 2000)");

        Out g = run("stall_dot", props("smtps", C, 8000, 8000), Spike::std, CAP, 1, 2000, null);
        p("[1g] watchdog at 2000 ms calls Transport.close(); backstop read timeout 8000; sink: no reply to the dot (blocked inside sendMessage())\n    watchdog close() returned at " + g.wdReturnMs + " ms, wdErr=" + g.wdErr + "\n    " + desc(g));
        result("1g", g.wdReturnMs >= 0 && g.wdReturnMs <= 2500 && !g.capped && g.endMs <= 2500, "Transport.close() returned at " + g.wdReturnMs + " ms; blocked sendMessage() ended at " + g.endMs + " ms (deadline 2000)");

        Tracker th = new Tracker();
        Properties ph = props("smtps", C, 8000, 8000);
        ph.put("mail.smtps.ssl.socketFactory", th);
        Out h = run("stall_dot", ph, Spike::std, CAP, 2, 2000, th);
        p("[1h] ALTERNATIVE watchdog: close the tracked socket (own SSLSocketFactory records sockets) at 2000 ms; sink: no reply to the dot; sockets tracked=" + th.all.size() + "\n    watchdog returned at " + h.wdReturnMs + " ms, wdErr=" + h.wdErr + "\n    " + desc(h));
        result("1h", h.wdReturnMs >= 0 && !h.capped && h.endMs <= 2500, "socket close at 2000 ms ended sendMessage() at " + h.endMs + " ms");

        Tracker ti = new Tracker();
        Properties pi = props("smtps", C, 8000, 8000);
        pi.put("mail.smtps.ssl.socketFactory", ti);
        Out i = run("stall_greeting", pi, Spike::std, CAP, 2, 2000, ti);
        p("[1i] ALTERNATIVE watchdog on a greeting stall (blocked in connect()); sockets tracked=" + ti.all.size() + "\n    watchdog returned at " + i.wdReturnMs + " ms, wdErr=" + i.wdErr + "\n    " + desc(i));
        result("1i", i.wdReturnMs >= 0 && !i.capped && i.endMs <= 2500, "socket close at 2000 ms ended connect() at " + i.endMs + " ms");
    }

    static void case2() throws Exception {
        p("\n=== CASE 2: lost reply after the end-of-data dot, and failures before/after DATA began (read timeout 5000) ===");
        Object[][] sc = {
            {"close_dot", "2a", true, "dot received, FIN, no reply"},
            {"rst_dot", "2b", true, "dot received, RST, no reply"},
            {"close_354", "2c", true, "354 sent then closed before the body"},
            {"close_data_cmd", "2d", false, "closed on the DATA command, no 354"},
            {"close_rcpt", "2e", false, "closed on RCPT, no reply"},
        };
        for (Object[] x : sc) {
            Out o = run((String) x[0], props("smtps", 3000, 5000, 5000), Spike::std, 12000, 0, 0, null);
            p("[" + x[1] + "] sink: " + x[3] + "\n    " + desc(o));
            boolean after = o.lastRc instanceof Integer r && r == 354;
            boolean cls = classify(o.err, o.lastRc).startsWith((Boolean) x[2] ? "AMBIGUOUS" : "TRANSIENT");
            result((String) x[1], !o.capped && o.err != null && after == (Boolean) x[2] && cls,
                "afterDataBegan expected " + x[2] + ", lastReturnCode=" + o.lastRc + " says " + after + "; classify=" + classify(o.err, o.lastRc));
        }
    }

    static void case3() throws Exception {
        p("\n=== CASE 3: Message-ID and envelope (sink ok_good) ===");
        String id = "<item-i1.a1@example.test>";
        Out o = run("ok_good", props("smtps", 3000, 5000, 5000), s -> msg(s, id, "rcpt@example.test", "body line", "S13 id test"), 12000, 0, 0, null);
        p("[3a] send ok=" + o.ok + (o.err != null ? "\n    exception: " + chain(o.err) : ""));
        List<String> cm = cmds("ok_good");
        String d = data("ok_good");
        String headers = d.contains("\r\n\r\n") ? d.substring(0, d.indexOf("\r\n\r\n")) : d;
        p("    sink commands:\n      " + String.join("\n      ", cm));
        p("    sink received header block:\n      " + headers.replace("\r\n", "\n      "));
        Matcher m = Pattern.compile("(?im)^Message-ID:[ \\t]*(.*)$").matcher(headers);
        List<String> ids = new ArrayList<>();
        while (m.find()) ids.add(m.group(1).trim());
        long rcpts = cm.stream().filter(l -> l.startsWith("C: RCPT TO:")).count();
        boolean from = cm.stream().anyMatch(l -> l.startsWith("C: MAIL FROM:<bounces+t1.i1@example.test>"));
        boolean ehlo = cm.contains("C: EHLO mail.example.test");
        boolean fromHdr = Pattern.compile("(?im)^From:.*no-reply@example.test").matcher(headers).find();
        result("3a", o.ok && ids.size() == 1 && ids.get(0).equals(id), "Message-ID headers on the wire=" + ids + ", expected exactly [" + id + "]");
        result("3b", o.ok && from && fromHdr, "MAIL FROM is the VERP address from mail.smtps.from=" + from + "; header From stays no-reply@=" + fromHdr);
        result("3c", o.ok && rcpts == 1, "RCPT commands for one recipient=" + rcpts);
        result("3d", o.ok && ehlo, "EHLO name from mail.smtps.localhost seen as 'EHLO mail.example.test'=" + ehlo);

        Out c = run("ok_good", props("smtps", 3000, 5000, 5000), s -> msg(s, null, "rcpt@example.test", "body", "S13 control"), 12000, 0, 0, null);
        String d2 = data("ok_good");
        Matcher m2 = Pattern.compile("(?im)^Message-ID:[ \\t]*(.*)$").matcher(d2.contains("\r\n\r\n") ? d2.substring(0, d2.indexOf("\r\n\r\n")) : d2);
        String gen = m2.find() ? m2.group(1).trim() : "none";
        p("[3e] CONTROL, plain MimeMessage: generated Message-ID=" + gen);
        result("3e", c.ok && !gen.equals(id) && !gen.equals("none"), "without the override the library generates its own ID: " + gen);

        Out inj = run("ok_good", props("smtps", 3000, 5000, 5000), s -> msg(s, id, "rcpt@example.test", "body", "Hi\r\nBcc: evil@example.test"), 12000, 0, 0, null);
        String d3 = data("ok_good");
        String h3 = d3.contains("\r\n\r\n") ? d3.substring(0, d3.indexOf("\r\n\r\n")) : d3;
        boolean bcc = Pattern.compile("(?im)^Bcc:").matcher(h3).find();
        p("[3f] EXTRA: Subject containing CRLF then 'Bcc:' ok=" + inj.ok + (inj.err != null ? "\n    exception: " + chain(inj.err) : "\n    header block received:\n      " + h3.replace("\r\n", "\n      ")));
        result("3f", inj.err != null || !bcc, "CRLF in Subject " + (inj.err != null ? "was refused: " + one(inj.err.getMessage()) : "sent; a separate Bcc header line on the wire=" + bcc));
    }

    static void case4() throws Exception {
        p("\n=== CASE 4: reply classification (Decision 3 table) ===");
        String[][] sc = {
            {"mail_550", "4a", "CONFIG_FAULT"},
            {"rcpt_552", "4b", "REJECTED(recipient"},
            {"rcpt_550", "4c", "REJECTED(recipient"},
            {"rcpt_450", "4d", "TRANSIENT"},
            {"auth_535", "4e", "CONFIG_FAULT(auth)"},
            {"data_cmd_554", "4f", "REJECTED(message"},
            {"dot_451", "4g", "TRANSIENT(dot 451)"},
            {"dot_554", "4h", "REJECTED(message, to dot 554)"},
        };
        for (String[] x : sc) {
            Out o = run(x[0], props("smtps", 3000, 5000, 5000), Spike::std, 12000, 0, 0, null);
            String cl = classify(o.err, o.lastRc);
            p("[" + x[1] + "] sink: " + x[0] + "\n    " + desc(o));
            String extra = "";
            if (x[0].equals("rcpt_552")) {
                boolean inUnsent = false;
                for (Throwable t : all(o.err)) if (t instanceof SendFailedException sfe && sfe.getValidUnsentAddresses() != null && sfe.getValidUnsentAddresses().length > 0) inUnsent = true;
                extra = "; address in the validUnsent list=" + inUnsent;
                p("    (F123 check) 552 on RCPT lands in validUnsent: " + inUnsent);
            }
            result(x[1], !o.capped && !o.ok && cl.startsWith(x[2]), x[0] + " -> " + cl + " (expected prefix " + x[2] + ")" + extra);
        }
    }

    static void case5() throws Exception {
        p("\n=== CASE 5: implicit TLS with identity check (host 'localhost'; JVM trust store holds the 'good' and 'wrong' certificates, not 'untrusted'; no ssl.trust set) ===");
        Out a = run("ok_good", props("smtps", 3000, 5000, 5000), Spike::std, 12000, 0, 0, null);
        p("[5a] certificate for localhost, trusted\n    " + desc(a));
        result("5a", a.ok, "matching name + trusted cert: ok=" + a.ok);
        Out b = run("ok_wrong", props("smtps", 3000, 5000, 5000), Spike::std, 12000, 0, 0, null);
        p("[5b] certificate issued for other.example.test, in the trust store, connecting to 'localhost'\n    " + desc(b));
        result("5b", !b.ok && !b.capped && b.err != null, "wrong-name certificate refused=" + (!b.ok) + "; " + classify(b.err, b.lastRc));
        Out c = run("ok_untrusted", props("smtps", 3000, 5000, 5000), Spike::std, 12000, 0, 0, null);
        p("[5c] certificate for localhost but not in the trust store\n    " + desc(c));
        result("5c", !c.ok && !c.capped && c.err != null, "untrusted certificate refused=" + (!c.ok) + "; " + classify(c.err, c.lastRc));
        Properties off = props("smtps", 3000, 5000, 5000);
        off.put("mail.smtps.ssl.checkserveridentity", "false");
        Out d = run("ok_wrong", off, Spike::std, 12000, 0, 0, null);
        p("[5d] CONTROL: same wrong-name certificate with ssl.checkserveridentity=false\n    " + desc(d));
        result("5d", d.ok, "with the identity check off the wrong-name certificate is accepted: ok=" + d.ok + " (shows the property is what refuses 5b)");
    }

    static void case6() throws Exception {
        p("\n=== CASE 6: IMAP (imaps) timeouts (connect 1000, read 1500, write 1500; cap 12000) ===");
        Properties pr = new Properties();
        pr.put("mail.imaps.connectiontimeout", "1000");
        pr.put("mail.imaps.timeout", "1500");
        pr.put("mail.imaps.writetimeout", "1500");
        pr.put("mail.imaps.ssl.checkserveridentity", "true");
        Out a = runImap("stall_greeting", pr, 12000);
        p("[6a] imaps, TLS ok, no greeting\n    " + desc(a));
        result("6a", !a.capped && a.err != null && a.endMs <= 2500, "no-greeting stall ended " + a.endMs + " ms (read timeout 1500)");
        Out b = runImap("imap_greet_stall", pr, 12000);
        p("[6b] imaps, greeting then silence\n    " + desc(b));
        result("6b", !b.capped && b.err != null && b.endMs <= 2500, "post-greeting stall ended " + b.endMs + " ms (read timeout 1500)");
        Out c = runImap("stall_tcp", pr, 12000);
        p("[6c] imaps, TLS handshake never answered\n    " + desc(c));
        result("6c", !c.capped && c.err != null && c.endMs <= 2500, "handshake stall " + (c.capped ? "NOT bounded within the cap" : "ended " + c.endMs + " ms"));
        Properties none = new Properties();
        none.put("mail.imaps.ssl.checkserveridentity", "true");
        Out d = runImap("stall_greeting", none, 4000);
        p("[6d] CONTROL no timeout properties, cap 4000\n    " + desc(d));
        result("6d", d.capped, "without timeouts the IMAP connect " + (d.capped ? "was still blocked at the 4000 ms cap" : "ended " + d.endMs + " ms"));
        Properties wrongPrefix = new Properties();
        wrongPrefix.put("mail.imap.connectiontimeout", "1000");
        wrongPrefix.put("mail.imap.timeout", "1500");
        wrongPrefix.put("mail.imaps.ssl.checkserveridentity", "true");
        Out e = runImap("stall_greeting", wrongPrefix, 4000);
        p("[6e] CONTROL timeouts set under 'mail.imap.' (not 'mail.imaps.') with protocol imaps, cap 4000\n    " + desc(e));
        result("6e", true, "informational: timeouts under the mail.imap. prefix with the imaps protocol " + (e.capped ? "did NOT apply (still blocked at 4000 ms)" : "applied (ended " + e.endMs + " ms)"));
    }

    public static void main(String[] a) throws Exception {
        for (String l : Files.readAllLines(Path.of(a[0]))) {
            String[] x = l.trim().split(" ");
            if (x.length == 2) PORTS.put(x[0], Integer.parseInt(x[1]));
        }
        SINK = Path.of(a[1]);
        p("JAVA " + Runtime.version() + " | " + System.getProperty("java.vendor") + " | " + System.getProperty("java.vm.name"));
        p("SMTPTransport from " + Class.forName("org.eclipse.angus.mail.smtp.SMTPTransport").getProtectionDomain().getCodeSource().getLocation());
        p("Session from " + Session.class.getProtectionDomain().getCodeSource().getLocation());
        p("ports: " + PORTS.keySet().size() + " scenarios");
        case1();
        case2();
        case3();
        case4();
        case5();
        case6();
        result("7", true, "the whole harness ran to its end on JDK " + Runtime.version());
        long pass = SUMMARY.stream().filter(s -> s.contains(" PASS - ")).count();
        p("\n=== SUMMARY: " + pass + " PASS, " + (SUMMARY.size() - pass) + " FAIL of " + SUMMARY.size() + " ===");
        for (String s : SUMMARY) p(s.length() > 200 ? s.substring(0, 200) + "..." : s);
        System.exit(0);
    }
}
