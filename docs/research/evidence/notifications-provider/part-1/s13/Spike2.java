import jakarta.mail.*;
import jakarta.mail.internet.*;
import javax.net.ssl.SSLSocketFactory;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * S13 run 2: a stage-tracking SMTPTransport subclass (protected hooks mailFrom/rcptTo/data/finishData) and a corrected
 * classifier. Throwaway code. Usage: java -cp <jars> Spike2.java <ports-file> <sink-log-dir>   (SINK_PW from the environment)
 */
public class Spike2 {
    static final Map<String, Integer> PORTS = new HashMap<>();
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
        return s.length() > 240 ? s.substring(0, 240) + "..." : s;
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

    static String chain(Throwable t) {
        StringBuilder sb = new StringBuilder();
        for (Throwable x : all(t)) {
            if (sb.length() > 0) sb.append("\n      <- ");
            sb.append(x.getClass().getName()).append(" (\"").append(one(x.getMessage())).append("\")");
            Object rc = q(x, "getReturnCode"), cmd = q(x, "getCommand");
            if (rc != null) sb.append(" getReturnCode=").append(rc);
            if (cmd != null) sb.append(" getCommand=\"").append(one(cmd.toString())).append("\"");
        }
        return sb.toString();
    }

    /** Corrected rule: a reply code above 0 decides by code and command; an I/O failure decides by the stage marker. */
    static String classify(Throwable e, String stage) {
        if (e == null) return "ACCEPTED";
        for (Throwable x : all(e)) {
            if (x instanceof javax.net.ssl.SSLException || x instanceof java.security.cert.CertificateException) return "CONFIG_FAULT(tls)";
            if (x instanceof AuthenticationFailedException) return "CONFIG_FAULT(auth)";
        }
        for (Throwable x : all(e)) {
            Object rc = q(x, "getReturnCode"), cmd = q(x, "getCommand");
            if (rc instanceof Integer r && r > 0 && cmd != null) {
                String c = cmd.toString().trim().toUpperCase(Locale.ROOT);
                if (c.startsWith("MAIL")) return "CONFIG_FAULT(mail from " + r + ")";
                if (c.startsWith("RCPT")) return r >= 500 ? "REJECTED(recipient " + r + ")" : "TRANSIENT(rcpt " + r + ")";
                if (c.startsWith("DATA")) return r >= 500 ? "REJECTED(message, to DATA " + r + ")" : "TRANSIENT(data " + r + ")";
                if (c.equals(".")) return r >= 500 ? "REJECTED(message, to dot " + r + ")" : "TRANSIENT(dot " + r + ")";
                return "UNCLASSIFIED(cmd=" + c + " rc=" + r + ")";
            }
        }
        return (stage.equals("BODY") || stage.equals("DOT")) ? "AMBIGUOUS(I/O in stage " + stage + ")" : "TRANSIENT(I/O in stage " + stage + ")";
    }

    /** Records how far the dialogue got, using the library's own protected hooks. */
    static class StageTransport extends org.eclipse.angus.mail.smtp.SMTPTransport {
        volatile String stage = "NONE";
        StageTransport(Session s, URLName u) { super(s, u, "smtps", true); }
        @Override protected void mailFrom() throws MessagingException { stage = "MAIL"; super.mailFrom(); }
        @Override protected void rcptTo() throws MessagingException { stage = "RCPT"; super.rcptTo(); }
        @Override protected OutputStream data() throws MessagingException { stage = "DATA_CMD"; OutputStream o = super.data(); stage = "BODY"; return o; }
        @Override protected void finishData() throws IOException, MessagingException { stage = "DOT"; super.finishData(); stage = "DONE"; }
    }

    static class FixedIdMessage extends MimeMessage {
        final String id;
        FixedIdMessage(Session s, String id) { super(s); this.id = id; }
        @Override protected void updateMessageID() throws MessagingException { setHeader("Message-ID", id); }
    }

    static MimeMessage msg(Session s, String body) throws Exception {
        MimeMessage m = new FixedIdMessage(s, "<std-2@example.test>");
        m.setFrom(new InternetAddress(USER));
        m.setRecipient(Message.RecipientType.TO, new InternetAddress("rcpt@example.test"));
        m.setSubject("S13 run 2", "UTF-8");
        m.setText(body, "UTF-8");
        m.saveChanges();
        return m;
    }

    static MimeMessage std(Session s) throws Exception { return msg(s, "hello"); }

    static Properties props(int conn, int read, int write) {
        Properties p = new Properties();
        String x = "mail.smtps.";
        if (conn > 0) p.put(x + "connectiontimeout", String.valueOf(conn));
        if (read > 0) p.put(x + "timeout", String.valueOf(read));
        if (write > 0) p.put(x + "writetimeout", String.valueOf(write));
        p.put(x + "auth", "true");
        p.put(x + "ssl.checkserveridentity", "true");
        p.put(x + "localhost", "mail.example.test");
        p.put(x + "from", "bounces+t1.i1@example.test");
        return p;
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
        volatile long endMs = -1, sendStartMs = -1, wdReturnMs = -1;
        volatile Throwable err;
        volatile boolean ok, capped;
        volatile String stage = "?";
    }

    static Out run(String scen, Properties pr, Mk mk, long capMs, long wdAt, Tracker tr) throws Exception {
        Out o = new Out();
        Session s = Session.getInstance(pr);
        StageTransport t = new StageTransport(s, new URLName("smtps", HOST, PORTS.get(scen), null, null, null));
        long st = System.nanoTime();
        if (wdAt > 0) {
            Thread w = new Thread(() -> {
                try { Thread.sleep(wdAt); } catch (InterruptedException e) { return; }
                try { for (Socket k : tr.all) k.close(); } catch (Throwable e) { /* reported by timing */ }
                o.wdReturnMs = ms(st);
            }, "watchdog");
            w.setDaemon(true);
            w.start();
        }
        Future<?> f = EX.submit(() -> {
            try {
                t.connect(HOST, PORTS.get(scen), USER, PW);
                MimeMessage m = mk.make(s);
                o.sendStartMs = ms(st);
                t.sendMessage(m, m.getAllRecipients());
                o.ok = true;
            } catch (Throwable e) {
                o.err = e;
            } finally {
                o.stage = t.stage;
                o.endMs = ms(st);
                try { t.close(); } catch (Throwable ignore) { }
            }
        });
        try { f.get(capMs, TimeUnit.MILLISECONDS); } catch (TimeoutException e) { o.capped = true; }
        return o;
    }

    static void chk(String id, String scen, String note, Properties pr, Mk mk, String expect, long wdAt, Tracker tr, long boundMs) throws Exception {
        Out o = run(scen, pr, mk, 12000, wdAt, tr);
        String cl = o.capped ? "NOT ENDED" : classify(o.err, o.stage);
        p("[" + id + "] sink " + scen + " (" + note + ")\n    endMs=" + (o.capped ? "NOT ENDED at cap" : o.endMs) + " sendStartMs=" + o.sendStartMs
            + " stage=" + o.stage + " ok=" + o.ok + (wdAt > 0 ? " watchdogReturnedMs=" + o.wdReturnMs : "")
            + "\n    exception: " + (o.err == null ? "-" : chain(o.err)) + "\n    classify -> " + cl);
        boolean timeOk = boundMs <= 0 || (!o.capped && o.endMs <= boundMs);
        result(id, !o.capped && cl.startsWith(expect) && timeOk, scen + ": stage=" + o.stage + " -> " + cl + " (expected " + expect + "), ended " + o.endMs + " ms");
    }

    public static void main(String[] a) throws Exception {
        for (String l : Files.readAllLines(Path.of(a[0]))) {
            String[] x = l.trim().split(" ");
            if (x.length == 2) PORTS.put(x[0], Integer.parseInt(x[1]));
        }
        p("JAVA " + Runtime.version() + " | StageTransport extends " + StageTransport.class.getSuperclass().getName());
        Properties base = props(1000, 1500, 1500);
        p("\n=== RUN 2, part A: stage marker and corrected classifier (timeouts connect 1000, read 1500, write 1500) ===");
        chk("S2.1", "ok_good", "normal send", base, Spike2::std, "ACCEPTED", 0, null, 0);
        chk("S2.2", "close_dot", "FIN after the dot, no reply", base, Spike2::std, "AMBIGUOUS", 0, null, 0);
        chk("S2.3", "rst_dot", "RST after the dot, no reply", base, Spike2::std, "AMBIGUOUS", 0, null, 0);
        chk("S2.4", "stall_dot", "no reply to the dot, read timeout", base, Spike2::std, "AMBIGUOUS", 0, null, 0);
        chk("S2.5", "close_354", "closed after 354", base, Spike2::std, "AMBIGUOUS", 0, null, 0);
        StringBuilder big = new StringBuilder();
        String line = "A".repeat(79) + "\n";
        for (int i = 0; i < 500_000; i++) big.append(line);
        String bigS = big.toString();
        chk("S2.6", "stall_read_data", "40 MB body, sink stops reading, write timeout", base, s -> msg(s, bigS), "AMBIGUOUS", 0, null, 0);
        chk("S2.7", "close_data_cmd", "closed on the DATA command", base, Spike2::std, "TRANSIENT", 0, null, 0);
        chk("S2.8", "close_rcpt", "closed on RCPT", base, Spike2::std, "TRANSIENT", 0, null, 0);
        chk("S2.9", "stall_greeting", "no greeting", base, Spike2::std, "TRANSIENT", 0, null, 0);
        chk("S2.10", "mail_550", "reply", base, Spike2::std, "CONFIG_FAULT", 0, null, 0);
        chk("S2.11", "rcpt_552", "reply", base, Spike2::std, "REJECTED(recipient", 0, null, 0);
        chk("S2.12", "rcpt_450", "reply", base, Spike2::std, "TRANSIENT(rcpt 450)", 0, null, 0);
        chk("S2.13", "auth_535", "reply", base, Spike2::std, "CONFIG_FAULT(auth)", 0, null, 0);
        chk("S2.14", "dot_451", "reply", base, Spike2::std, "TRANSIENT(dot 451)", 0, null, 0);
        chk("S2.15", "dot_554", "reply", base, Spike2::std, "REJECTED(message, to dot 554)", 0, null, 0);

        p("\n=== RUN 2, part B: socket-close watchdog at 2000 ms (backstop read timeout 8000) with the tracking factory AND the stage marker; identity check on ===");
        Tracker t1 = new Tracker();
        Properties w1 = props(1000, 8000, 8000);
        w1.put("mail.smtps.ssl.socketFactory", t1);
        chk("S2.16", "stall_dot", "watchdog closes sockets at 2000 ms", w1, Spike2::std, "AMBIGUOUS", 2000, t1, 2500);
        Tracker t2 = new Tracker();
        Properties w2 = props(1000, 8000, 8000);
        w2.put("mail.smtps.ssl.socketFactory", t2);
        chk("S2.17", "stall_greeting", "watchdog closes sockets at 2000 ms", w2, Spike2::std, "TRANSIENT", 2000, t2, 2500);

        p("\n=== RUN 2, part C: identity check with the tracking socket factory installed (trust store: good and wrong certificates) ===");
        Tracker t3 = new Tracker();
        Properties w3 = props(1000, 5000, 5000);
        w3.put("mail.smtps.ssl.socketFactory", t3);
        chk("S2.18", "ok_good", "right name, tracking factory", w3, Spike2::std, "ACCEPTED", 0, null, 0);
        Tracker t4 = new Tracker();
        Properties w4 = props(1000, 5000, 5000);
        w4.put("mail.smtps.ssl.socketFactory", t4);
        chk("S2.19", "ok_wrong", "certificate for another name, tracking factory", w4, Spike2::std, "CONFIG_FAULT(tls)", 0, null, 0);
        Tracker t5 = new Tracker();
        Properties w5 = props(1000, 5000, 5000);
        w5.put("mail.smtps.ssl.socketFactory", t5);
        chk("S2.20", "ok_untrusted", "untrusted certificate, tracking factory", w5, Spike2::std, "CONFIG_FAULT(tls)", 0, null, 0);

        result("S2.21", true, "the whole run-2 harness ran to its end on JDK " + Runtime.version());
        long pass = SUMMARY.stream().filter(s -> s.contains(" PASS - ")).count();
        p("\n=== SUMMARY (run 2): " + pass + " PASS, " + (SUMMARY.size() - pass) + " FAIL of " + SUMMARY.size() + " ===");
        for (String s : SUMMARY) p(s.length() > 220 ? s.substring(0, 220) + "..." : s);
        System.exit(0);
    }
}
