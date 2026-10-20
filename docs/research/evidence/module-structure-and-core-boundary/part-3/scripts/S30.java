// S30 (tier E, throwaway): the PROPOSED scheme end to end with Flyway 13.10.3.
// Scheme: one history table per module named flyway_<module>; one location per module = classpath:db/migration/net/kodelix/<layer>/<module>/ ;
// versions = one plain integer per module, 4 digits, starting 0001, no dots; runner loops over an explicit ordered module list;
// per module: failOnMissingLocations=true, baselineOnMigrate=true + baselineVersion=0, validate with ignoreMigrationPatterns=*:pending, then migrate;
// guard: a module must resolve >= 1 migration (catches an empty location).
// Phases: 1 product-owned (module dirs on the classpath as directories); 2 LIFT tenancy+audit into jars, same tables, new V0003 shipped by the jar;
// 3 negative cases: lift forgot the jar; a drifted copy; cross-module FK ordering (orders references tenants).
// Run: PGPORT=57613 java -cp "<cache>/jars/*" S30.java <workdir>
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
import java.net.*; import java.nio.charset.StandardCharsets; import java.nio.file.*; import java.sql.*; import java.util.*; import java.util.jar.*;

public class S30 {
  static String PORT = System.getenv("PGPORT"); static Path W;
  static String url(String db) { return "jdbc:postgresql://127.0.0.1:" + PORT + "/" + db; }
  static void exec(String db, String q) throws Exception { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement()) { s.execute(q); } }
  static void newDb(String db) throws Exception { exec("postgres", "DROP DATABASE IF EXISTS " + db); exec("postgres", "CREATE DATABASE " + db); }
  static void put(Path dir, String name, String body) throws Exception { Files.createDirectories(dir); Files.writeString(dir.resolve(name), body); }
  static String msg(Throwable t) { String m = (t.getClass().getSimpleName() + ": " + t.getMessage()).replace("\r", "").replace("\n", " | ").replace(W.toString(), "W"); return m.length() > 420 ? m.substring(0, 420) + "..." : m; }
  static Path jar(Path out, Path root) throws Exception { // jar of a resources dir
    Files.createDirectories(out.getParent());
    try (var jos = new JarOutputStream(Files.newOutputStream(out)); var st = Files.walk(root)) {
      for (Path p : (Iterable<Path>) st.sorted()::iterator) { if (p.equals(root)) continue; String n = root.relativize(p).toString().replace('\\', '/'); if (Files.isDirectory(p)) { jos.putNextEntry(new JarEntry(n + "/")); } else { jos.putNextEntry(new JarEntry(n)); jos.write(Files.readAllBytes(p)); } jos.closeEntry(); }
    }
    return out;
  }
  static URLClassLoader cl(Path... roots) throws Exception { URL[] u = new URL[roots.length]; for (int i = 0; i < roots.length; i++) { String s = roots[i].toUri().toURL().toString(); if (Files.isDirectory(roots[i]) && !s.endsWith("/")) s += "/"; u[i] = URI.create(s).toURL(); } return new URLClassLoader(u, S30.class.getClassLoader()); }
  record Mod(String name, String layer) { String loc() { return "classpath:db/migration/net/kodelix/" + layer + "/" + name + "/"; } String table() { return "flyway_" + name; } }
  /** The runner: returns false and stops at the first failing module (fail-closed). */
  static boolean run(String label, String db, ClassLoader cl, List<Mod> mods) {
    System.out.println("--- " + label);
    for (Mod m : mods) {
      try {
        var cfg = Flyway.configure(cl).dataSource(url(db), "postgres", "").locations(m.loc()).defaultSchema("app").schemas("app").table(m.table())
            .baselineOnMigrate(true).baselineVersion("0").ignoreMigrationPatterns("*:pending").configuration(Map.of("flyway.failOnMissingLocations", "true"));
        Flyway f = cfg.load();
        long resolved = Arrays.stream(f.info().all()).filter(i -> i.getType() != null && i.getType().name().equals("SQL")).count();
        if (resolved == 0) throw new IllegalStateException("module " + m.name + " resolved 0 migrations (empty location)");
        f.validate(); var r = f.migrate();
        System.out.println("  " + m.name + ": validate OK, applied=" + r.migrationsExecuted + ", table=" + m.table() + ", resolved=" + resolved);
      } catch (Exception e) { System.out.println("  " + m.name + ": STOP " + msg(e)); return false; }
    }
    return true;
  }
  static void hist(String db, String t) throws Exception { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement(); var r = s.executeQuery("select installed_rank,version,description,type,checksum from app." + t + " order by installed_rank")) { while (r.next()) System.out.println("     " + t + " rank=" + r.getInt(1) + " v=" + r.getString(2) + " " + r.getString(3) + " " + r.getString(4) + " cs=" + r.getString(5)); } }
  public static void main(String[] a) throws Exception {
    W = Path.of(a[0]).toAbsolutePath(); Files.createDirectories(W);
    System.out.println("S30 java " + System.getProperty("java.version") + " pg " + PORT);
    List<Mod> mods = List.of(new Mod("tenancy", "core"), new Mod("audit", "core"), new Mod("orders", "kodeebo"));
    String base = "db/migration/net/kodelix/";
    Path res = W.resolve("product-resources");   // what processResources would give each module, merged here as one classpath root
    put(res.resolve(base + "core/tenancy"), "V0001__create_tenants.sql", "create table app.tenants(id uuid primary key);\n");
    put(res.resolve(base + "core/audit"), "V0001__create_audit_log.sql", "create table app.audit_log(id bigint generated always as identity primary key, tenant_id uuid not null);\n");
    put(res.resolve(base + "core/audit"), "V0002__audit_index.sql", "create index on app.audit_log(tenant_id);\n");
    put(res.resolve(base + "kodeebo/orders"), "V0001__create_orders.sql", "create table app.orders(id uuid primary key, tenant_id uuid not null references app.tenants(id));\n");
    newDb("s30a");
    try (var l = cl(res)) {
      System.out.println("\n=== PHASE 1: product owns all migrations (directories on classpath), empty database");
      run("1a first run", "s30a", l, mods); run("1b second run (idempotent)", "s30a", l, mods);
    }
    for (String t : List.of("flyway_tenancy", "flyway_audit", "flyway_orders")) hist("s30a", t);

    System.out.println("\n=== PHASE 2: LIFT tenancy and audit into jars (same resource paths, same bytes); jar for audit also ships V0003; orders stays in the product");
    Path ten = W.resolve("lift/tenancy-res"), aud = W.resolve("lift/audit-res");
    Files.createDirectories(ten.resolve(base + "core")); Files.createDirectories(aud.resolve(base + "core"));
    copyTree(res.resolve(base + "core/tenancy"), ten.resolve(base + "core/tenancy")); copyTree(res.resolve(base + "core/audit"), aud.resolve(base + "core/audit"));
    put(aud.resolve(base + "core/audit"), "V0003__audit_note.sql", "alter table app.audit_log add column note text;\n");
    Path prodOnly = W.resolve("lift/product-res"); copyTree(res.resolve(base + "kodeebo"), prodOnly.resolve(base + "kodeebo"));
    Path jt = jar(W.resolve("lift/tenancy-0.1.0.jar"), ten), ja = jar(W.resolve("lift/audit-0.1.0.jar"), aud);
    try (var l = cl(prodOnly, jt, ja)) { run("2a existing database, migrations now from jars", "s30a", l, mods); }
    hist("s30a", "flyway_audit");

    System.out.println("\n=== PHASE 3a: lift forgot the audit jar (audit location absent from the classpath)");
    try (var l = cl(prodOnly, jt)) { run("3a", "s30a", l, mods); }
    System.out.println("\n=== PHASE 3b: drifted copy: product still has an edited audit V0002 next to the jar's V0002");
    Path drift = W.resolve("lift/drift-res"); put(drift.resolve(base + "core/audit"), "V0002__audit_index.sql", "create index on app.audit_log(tenant_id);\n-- edited\n");
    try (var l = cl(drift, prodOnly, jt, ja)) { run("3b (drift dir first on classpath)", "s30a", l, mods); }
    System.out.println("\n=== PHASE 3c: fresh database from the jars only (new customer / new environment)");
    newDb("s30c"); try (var l = cl(prodOnly, jt, ja)) { run("3c", "s30c", l, mods); }
    System.out.println("\n=== PHASE 3d: wrong module order (orders before tenancy) on a fresh database");
    newDb("s30d"); try (var l = cl(prodOnly, jt, ja)) { run("3d", "s30d", l, List.of(mods.get(2), mods.get(0), mods.get(1))); }
    System.out.println("\nDONE");
  }
  static void copyTree(Path from, Path to) throws Exception { try (var st = Files.walk(from)) { for (Path p : (Iterable<Path>) st::iterator) { Path d = to.resolve(from.relativize(p).toString()); if (Files.isDirectory(p)) Files.createDirectories(d); else { Files.createDirectories(d.getParent()); Files.copy(p, d, StandardCopyOption.REPLACE_EXISTING); } } } }
}
