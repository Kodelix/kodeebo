// S13b probe (tier-E evidence, throwaway, not production code): follow-up to S13 run 3.
// Questions raised by run 3: (H1) identical file name in two locations applied once - what if the bytes differ?
// (H2) per-module history tables hit "non-empty schema" for the second module - does baselineOnMigrate with
//      baselineVersion=0 fix it, and does the DEFAULT baselineVersion silently skip V1?
// (H3) mis-wired location against a per-module table; (H4) dropped / missing locations; (H5) validate-before-migrate with pending;
// (H6) migrations served from a classpath DIRECTORY (Gradle processResources output), not a jar.
// Run: PGPORT=57613 java -cp "<cache>/jars/*" S13b.java <workdir>
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import java.net.*; import java.nio.charset.StandardCharsets; import java.nio.file.*; import java.sql.*; import java.util.*; import java.util.jar.*;

public class S13b {
  static String PORT = System.getenv("PGPORT");
  static Path W;
  static String url(String db) { return "jdbc:postgresql://127.0.0.1:" + PORT + "/" + db; }
  static void exec(String db, String q) throws Exception { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement()) { s.execute(q); } }
  static void newDb(String db) throws Exception { exec("postgres", "DROP DATABASE IF EXISTS " + db); exec("postgres", "CREATE DATABASE " + db); }
  static Path put(Path dir, String name, String body) throws Exception { Files.createDirectories(dir); Path p = dir.resolve(name); Files.writeString(p, body); return p; }
  static String msg(Throwable t) { String m = t.getClass().getName() + ": " + t.getMessage(); m = m.replace("\r", "").replace("\n", " | ").replace(W.toString(), "W"); return m.length() > 900 ? m.substring(0, 900) + "..." : m; }
  /** cfgBaseline: null = not set; else baselineOnMigrate=true with that baselineVersion. */
  static Flyway fw(String db, String table, ClassLoader cl, String baselineVersion, String[] ignore, boolean failMissing, String... locs) {
    FluentConfiguration c = (cl != null ? Flyway.configure(cl) : Flyway.configure()).dataSource(url(db), "postgres", "").locations(locs)
        .defaultSchema("app").schemas("app").table(table);
    if (baselineVersion != null) c.baselineOnMigrate(true).baselineVersion(baselineVersion);
    if (ignore != null) c.ignoreMigrationPatterns(ignore);
    if (failMissing) c.configuration(Map.of("flyway.failOnMissingLocations", "true"));
    return c.load();
  }
  static Flyway fw(String db, String table, String... locs) { return fw(db, table, null, null, null, false, locs); }
  static void info(Flyway f) { try { for (MigrationInfo i : f.info().all()) System.out.println("   INFO v=" + i.getVersion() + " desc=" + i.getDescription() + " state=" + i.getState() + " rank=" + i.getInstalledRank()); } catch (Exception e) { System.out.println("   INFO-ERROR " + msg(e)); } }
  static void hist(String db, String table) { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement(); var r = s.executeQuery("select installed_rank, version, description, type, checksum, success from app." + table + " order by installed_rank")) { while (r.next()) System.out.println("   HIST " + table + " rank=" + r.getInt(1) + " v=" + r.getString(2) + " desc=" + r.getString(3) + " type=" + r.getString(4) + " cs=" + r.getString(5) + " ok=" + r.getBoolean(6)); } catch (Exception e) { System.out.println("   HIST-ERROR " + table + " " + msg(e)); } }
  static void tables(String db) { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement(); var r = s.executeQuery("select string_agg(tablename, ',' order by tablename) from pg_tables where schemaname='app'")) { r.next(); System.out.println("   TABLES in app: " + r.getString(1)); } catch (Exception e) { System.out.println("   TABLES-ERROR " + msg(e)); } }
  static void mig(String label, Flyway f) { try { var r = f.migrate(); System.out.println(" " + label + " migrate OK applied=" + r.migrationsExecuted); } catch (Exception e) { System.out.println(" " + label + " migrate ERROR " + msg(e)); } }
  static void val(String label, Flyway f) { try { f.validate(); System.out.println(" " + label + " validate OK"); } catch (Exception e) { System.out.println(" " + label + " validate ERROR " + msg(e)); } }
  static Path jar(Path out, Map<String, String> entries) throws Exception {
    Files.createDirectories(out.getParent());
    try (var jos = new JarOutputStream(Files.newOutputStream(out))) {
      Set<String> dirs = new TreeSet<>();
      for (String n : entries.keySet()) { String[] p = n.split("/"); String d = ""; for (int i = 0; i < p.length - 1; i++) { d += p[i] + "/"; dirs.add(d); } }
      for (String d : dirs) { jos.putNextEntry(new JarEntry(d)); jos.closeEntry(); }
      for (var e : entries.entrySet()) { jos.putNextEntry(new JarEntry(e.getKey())); jos.write(e.getValue().getBytes(StandardCharsets.UTF_8)); jos.closeEntry(); }
    }
    return out;
  }
  static URLClassLoader cl(Path... roots) throws Exception { URL[] u = new URL[roots.length]; for (int i = 0; i < roots.length; i++) { String s = roots[i].toUri().toURL().toString(); if (Files.isDirectory(roots[i]) && !s.endsWith("/")) s += "/"; u[i] = new URL(s); } return new URLClassLoader(u, S13b.class.getClassLoader()); }
  static void h(String t) { System.out.println("\n=== " + t); }

  public static void main(String[] a) throws Exception {
    W = Path.of(a[0]).toAbsolutePath(); Files.createDirectories(W);
    System.out.println("S13b java " + System.getProperty("java.version") + " pg port " + PORT);

    h("H1: same file name V2__same.sql in two locations, DIFFERENT bytes, shared table");
    newDb("s13h1"); Path A = W.resolve("h1/locA"), B = W.resolve("h1/locB");
    put(A, "V2__same.sql", "create table app.s(id int);"); put(B, "V2__same.sql", "create table app.s(id int, extra int);");
    mig("H1", fw("s13h1", "flyway_schema_history", "filesystem:" + A, "filesystem:" + B)); hist("s13h1", "flyway_schema_history"); tables("s13h1");

    h("H2a: per-module tables, second module, baselineOnMigrate=true + baselineVersion=0 on the non-empty schema");
    newDb("s13h2"); Path HA = W.resolve("h2/audit"), HO = W.resolve("h2/orders");
    put(HA, "V0001__audit_create.sql", "create table app.audit_log(id int);"); put(HA, "V0002__audit_idx.sql", "create index on app.audit_log(id);");
    put(HO, "V0001__orders_create.sql", "create table app.orders(id int);"); put(HO, "V0002__orders_idx.sql", "create index on app.orders(id);");
    mig("H2a audit (first, empty db)", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + HA));
    mig("H2a orders (second)", fw("s13h2", "flyway_orders", null, "0", null, false, "filesystem:" + HO));
    hist("s13h2", "flyway_audit"); hist("s13h2", "flyway_orders"); tables("s13h2");
    mig("H2a orders again", fw("s13h2", "flyway_orders", null, "0", null, false, "filesystem:" + HO));
    h("H2b: TRAP - same, but baselineVersion left at its default (second module)");
    newDb("s13h2b");
    mig("H2b audit", fw("s13h2b", "flyway_audit", null, "1", null, false, "filesystem:" + HA));
    mig("H2b orders (baselineOnMigrate=true, baselineVersion=1)", fw("s13h2b", "flyway_orders", null, "1", null, false, "filesystem:" + HO));
    hist("s13h2b", "flyway_orders"); tables("s13h2b");
    h("H2c: no baselineOnMigrate at all, second module (repeat of run 3 for the record)");
    newDb("s13h2c");
    mig("H2c audit", fw("s13h2c", "flyway_audit", "filesystem:" + HA)); mig("H2c orders", fw("s13h2c", "flyway_orders", "filesystem:" + HO));

    h("H3: mis-wired: orders history table (now exists, from H2a db) with the audit location");
    val("H3", fw("s13h2", "flyway_orders", null, "0", null, false, "filesystem:" + HA));
    mig("H3 migrate", fw("s13h2", "flyway_orders", null, "0", null, false, "filesystem:" + HA));

    h("H4: dropped / missing locations against the H2a database (audit applied V0001,V0002)");
    Path empty = W.resolve("h4/empty"); Files.createDirectories(empty);
    val("H4a empty location, default patterns", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + empty));
    val("H4b empty location, ignoreMigrationPatterns=repeatable:missing (so 'future' is no longer ignored)", fw("s13h2", "flyway_audit", null, "0", new String[]{"repeatable:missing"}, false, "filesystem:" + empty));
    Path onlyV2 = W.resolve("h4/onlyV2"); put(onlyV2, "V0002__audit_idx.sql", "create index on app.audit_log(id);");
    val("H4c location has V0002 only (V0001 gone), default patterns", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + onlyV2));
    Path nowhere = W.resolve("h4/does-not-exist");
    val("H4d location directory does not exist, default", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + nowhere));
    mig("H4d migrate", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + nowhere));
    mig("H4e location directory does not exist, failOnMissingLocations=true", fw("s13h2", "flyway_audit", null, "0", null, true, "filesystem:" + nowhere));
    mig("H4f classpath location absent from the classpath, failOnMissingLocations=true", fw("s13h2", "flyway_audit", null, "0", null, true, "classpath:db/migration/net/kodelix/core/audit/"));
    mig("H4g classpath location absent from the classpath, default", fw("s13h2", "flyway_audit", null, "0", null, false, "classpath:db/migration/net/kodelix/core/audit/"));

    h("H5: validate-before-migrate with a PENDING migration (V0003 added to audit), and with ignore pending");
    put(HA, "V0003__audit_more.sql", "alter table app.audit_log add column note text;");
    val("H5a default patterns", fw("s13h2", "flyway_audit", null, "0", null, false, "filesystem:" + HA));
    val("H5b ignoreMigrationPatterns=*:pending", fw("s13h2", "flyway_audit", null, "0", new String[]{"*:pending"}, false, "filesystem:" + HA));
    Files.writeString(HA.resolve("V0001__audit_create.sql"), "create table app.audit_log(id int);\n-- tampered\n");
    val("H5c ignore pending + V0001 edited after apply (checksum)", fw("s13h2", "flyway_audit", null, "0", new String[]{"*:pending"}, false, "filesystem:" + HA));

    h("H6: migrations served from a classpath DIRECTORY (what Gradle processResources produces), then the same module from a jar");
    newDb("s13h6"); Path res = W.resolve("h6/resources"); String CP = "db/migration/net/kodelix/core/audit/";
    String v1 = "create table app.audit_log(id int);\n", v2 = "create index on app.audit_log(id);\n";
    put(res.resolve(CP), "V0001__create.sql", v1); put(res.resolve(CP), "V0002__idx.sql", v2);
    try (var l = cl(res)) { mig("H6a directory", fw("s13h6", "flyway_audit", l, "0", null, false, "classpath:" + CP)); }
    hist("s13h6", "flyway_audit");
    Path j = jar(W.resolve("h6/audit.jar"), Map.of(CP + "V0001__create.sql", v1, CP + "V0002__idx.sql", v2));
    try (var l = cl(j)) { var f = fw("s13h6", "flyway_audit", l, "0", null, false, "classpath:" + CP); val("H6b jar after directory", f); mig("H6b", f); info(f); }
    h("H6c: directory AND jar of the same module both on the classpath");
    try (var l = cl(res, j)) { var f = fw("s13h6", "flyway_audit", l, "0", null, false, "classpath:" + CP); val("H6c", f); mig("H6c", f); }
    System.out.println("\nDONE");
  }
}
