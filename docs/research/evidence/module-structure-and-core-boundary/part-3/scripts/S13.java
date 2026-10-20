// S13 probe (tier-E evidence, throwaway, not production code). Flyway 13.10.3 as a library, several locations.
// Run: PGPORT=57613 java -cp "<cache>/jars/*" S13.java <workdir>
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
import org.flywaydb.core.api.configuration.FluentConfiguration;
import java.net.*; import java.nio.charset.StandardCharsets; import java.nio.file.*; import java.sql.*; import java.util.*; import java.util.jar.*;

public class S13 {
  static String PORT = System.getenv("PGPORT");
  static Path W;
  static String url(String db) { return "jdbc:postgresql://127.0.0.1:" + PORT + "/" + db; }
  static void exec(String db, String q) throws Exception { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement()) { s.execute(q); } }
  static void newDb(String db) throws Exception { exec("postgres", "DROP DATABASE IF EXISTS " + db); exec("postgres", "CREATE DATABASE " + db); }
  static Path put(Path dir, String name, String body) throws Exception { Files.createDirectories(dir); Path p = dir.resolve(name); Files.writeString(p, body); return p; }
  static String msg(Throwable t) { String m = t.getClass().getName() + ": " + t.getMessage(); m = m.replace("\r", "").replace("\n", " | "); return m.length() > 1100 ? m.substring(0, 1100) + "..." : m; }
  static Flyway fw(String db, String table, boolean ooo, ClassLoader cl, String... locs) {
    FluentConfiguration c = (cl != null ? Flyway.configure(cl) : Flyway.configure()).dataSource(url(db), "postgres", "").locations(locs)
        .defaultSchema("app").schemas("app").table(table).outOfOrder(ooo);
    return c.load();
  }
  static void info(Flyway f) { try { for (MigrationInfo i : f.info().all()) System.out.println("   INFO v=" + i.getVersion() + " desc=" + i.getDescription() + " state=" + i.getState() + " rank=" + i.getInstalledRank() + " cs=" + i.getChecksum()); } catch (Exception e) { System.out.println("   INFO-ERROR " + msg(e)); } }
  static void hist(String db, String table) { try (var c = DriverManager.getConnection(url(db), "postgres", ""); var s = c.createStatement(); var r = s.executeQuery("select installed_rank, version, description, type, checksum, success from app." + table + " order by installed_rank")) { while (r.next()) System.out.println("   HIST " + table + " rank=" + r.getInt(1) + " v=" + r.getString(2) + " desc=" + r.getString(3) + " cs=" + r.getString(5) + " ok=" + r.getBoolean(6)); } catch (Exception e) { System.out.println("   HIST-ERROR " + table + " " + msg(e)); } }
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
  static URLClassLoader cl(Path... jars) throws Exception { URL[] u = new URL[jars.length]; for (int i = 0; i < jars.length; i++) u[i] = jars[i].toUri().toURL(); return new URLClassLoader(u, S13.class.getClassLoader()); }
  static void h(String t) { System.out.println("\n=== " + t); }

  public static void main(String[] a) throws Exception {
    W = Path.of(a[0]); Files.createDirectories(W);
    System.out.println("S13 java " + System.getProperty("java.version") + " pg port " + PORT);

    h("A: two filesystem locations, disjoint versions, ONE shared history table (V1,V3 in A; V2,V4 in B)");
    newDb("s13a"); Path A = W.resolve("a/locA"), B = W.resolve("a/locB");
    put(A, "V1__a_one.sql", "create table app.a1(id int);"); put(A, "V3__a_three.sql", "create table app.a3(id int);");
    put(B, "V2__b_two.sql", "create table app.b2(id int);"); put(B, "V4__b_four.sql", "create table app.b4(id int);");
    var fa = fw("s13a", "flyway_schema_history", false, null, "filesystem:" + A, "filesystem:" + B);
    mig("A", fa); hist("s13a", "flyway_schema_history");

    h("B1: SAME version 2 in two locations, different descriptions, shared table");
    newDb("s13b1"); Path BA = W.resolve("b1/locA"), BB = W.resolve("b1/locB");
    put(BA, "V1__a_one.sql", "create table app.a1(id int);"); put(BA, "V2__a_two.sql", "create table app.a2(id int);");
    put(BB, "V2__b_two.sql", "create table app.b2(id int);");
    var fb1 = fw("s13b1", "flyway_schema_history", false, null, "filesystem:" + BA, "filesystem:" + BB);
    mig("B1", fb1); val("B1", fb1); info(fb1);
    h("B2: SAME file name in two locations (V2__same.sql in both)");
    newDb("s13b2"); Path B2A = W.resolve("b2/locA"), B2B = W.resolve("b2/locB");
    put(B2A, "V2__same.sql", "create table app.s(id int);"); put(B2B, "V2__same.sql", "create table app.s(id int);");
    mig("B2", fw("s13b2", "flyway_schema_history", false, null, "filesystem:" + B2A, "filesystem:" + B2B));
    h("B3: V1.01 and V1.1 in one location; and V1.9 vs V1.10 order; and V0001 vs V1");
    newDb("s13b3"); Path B3 = W.resolve("b3/loc");
    put(B3, "V1.01__a.sql", "create table app.x1(id int);"); put(B3, "V1.1__b.sql", "create table app.x2(id int);");
    mig("B3a (1.01 vs 1.1)", fw("s13b3", "flyway_schema_history", false, null, "filesystem:" + B3));
    newDb("s13b3b"); Path B3b = W.resolve("b3/locb");
    put(B3b, "V1.10__ten.sql", "create table app.t10(id int);"); put(B3b, "V1.9__nine.sql", "create table app.t9(id int);");
    var fb3b = fw("s13b3b", "flyway_schema_history", false, null, "filesystem:" + B3b); mig("B3b (1.9 vs 1.10)", fb3b); hist("s13b3b", "flyway_schema_history");
    newDb("s13b3c"); Path B3c = W.resolve("b3/locc");
    put(B3c, "V0001__padded.sql", "create table app.p1(id int);"); put(B3c, "V1__plain.sql", "create table app.p2(id int);");
    mig("B3c (V0001 vs V1)", fw("s13b3c", "flyway_schema_history", false, null, "filesystem:" + B3c));

    h("C: module-block versions in ONE shared table: tenancy V101.*, orders V201.*; then tenancy V101.2 added after V201.1 applied");
    newDb("s13c"); Path CT = W.resolve("c/tenancy"), CO = W.resolve("c/orders");
    put(CT, "V101.1__tenancy_create.sql", "create table app.tenants(id int);"); put(CO, "V201.1__orders_create.sql", "create table app.orders(id int);");
    var fc = fw("s13c", "flyway_schema_history", false, null, "filesystem:" + CT, "filesystem:" + CO); mig("C initial", fc);
    put(CT, "V101.2__tenancy_more.sql", "create table app.tenant_x(id int);");
    var fc2 = fw("s13c", "flyway_schema_history", false, null, "filesystem:" + CT, "filesystem:" + CO);
    h("C1: outOfOrder=false"); mig("C1", fc2); val("C1", fc2); info(fc2);
    h("C2: outOfOrder=true"); var fc3 = fw("s13c", "flyway_schema_history", true, null, "filesystem:" + CT, "filesystem:" + CO);
    mig("C2", fc3); hist("s13c", "flyway_schema_history"); info(fc3);
    h("C3: after C2, validate with outOfOrder=false");
    val("C3", fw("s13c", "flyway_schema_history", false, null, "filesystem:" + CT, "filesystem:" + CO));

    h("D: ONE HISTORY TABLE PER MODULE via table(): audit (V1,V2) table flyway_audit, orders (V1) table flyway_orders, same version numbers");
    newDb("s13d"); Path DA = W.resolve("d/audit"), DO = W.resolve("d/orders");
    put(DA, "V0001__audit_create.sql", "create table app.audit_log(id int);"); put(DA, "V0002__audit_idx.sql", "create index on app.audit_log(id);");
    put(DO, "V0001__orders_create.sql", "create table app.orders(id int);");
    Flyway fda = fw("s13d", "flyway_audit", false, null, "filesystem:" + DA), fdo = fw("s13d", "flyway_orders", false, null, "filesystem:" + DO);
    mig("D audit", fda); mig("D orders", fdo); hist("s13d", "flyway_audit"); hist("s13d", "flyway_orders");
    put(DA, "V0003__audit_more.sql", "alter table app.audit_log add column note text;");
    mig("D audit again (new V0003)", fda); hist("s13d", "flyway_audit"); hist("s13d", "flyway_orders");
    h("D2: mis-wired: orders history table with the audit location");
    val("D2", fw("s13d", "flyway_orders", false, null, "filesystem:" + DA));
    h("D3: parent directory as location (recursion): location = d/ holding audit/ and orders/ subdirectories, fresh db");
    newDb("s13d3"); mig("D3 (parent dir, one table)", fw("s13d3", "flyway_schema_history", false, null, "filesystem:" + W.resolve("d")));
    hist("s13d3", "flyway_schema_history");

    h("E: MOVE to a jar. Module audit migrated from filesystem, then served from classpath: location in a jar (namespaced path)");
    newDb("s13e"); Path EA = W.resolve("e/fs-audit");
    String v1 = "create table app.audit_log(id int, at timestamptz);\n-- comment with ; and 'quote'\n";
    String v2 = "create index on app.audit_log(id);\ninsert into app.audit_log values (1, now());\n";
    put(EA, "V0001__create_audit_log.sql", v1); put(EA, "V0002__idx_audit_log.sql", v2);
    String CP = "db/migration/net/kodelix/core/audit/";
    mig("E fs", fw("s13e", "flyway_audit", false, null, "filesystem:" + EA)); hist("s13e", "flyway_audit");
    Map<String, String> same = new LinkedHashMap<>(); same.put(CP + "V0001__create_audit_log.sql", v1); same.put(CP + "V0002__idx_audit_log.sql", v2);
    Path jarSame = jar(W.resolve("e/audit-same.jar"), same);
    try (var l = cl(jarSame)) {
      h("E1: same bytes from the jar");
      var f = fw("s13e", "flyway_audit", false, l, "classpath:" + CP); val("E1", f); mig("E1", f); info(f);
    }
    Map<String, String> crlf = new LinkedHashMap<>(); crlf.put(CP + "V0001__create_audit_log.sql", v1.replace("\n", "\r\n")); crlf.put(CP + "V0002__idx_audit_log.sql", v2.replace("\n", "\r\n"));
    try (var l = cl(jar(W.resolve("e/audit-crlf.jar"), crlf))) { h("E2: jar with CRLF line endings"); val("E2", fw("s13e", "flyway_audit", false, l, "classpath:" + CP)); }
    Map<String, String> tr = new LinkedHashMap<>(same); tr.put(CP + "V0002__idx_audit_log.sql", v2 + "-- one trailing comment\n");
    Path jarTamper = jar(W.resolve("e/audit-trailing-comment.jar"), tr);
    try (var l = cl(jarTamper)) {
      h("E3: jar with one trailing comment added to V0002 (checksum change)");
      var f = fw("s13e", "flyway_audit", false, l, "classpath:" + CP); val("E3", f); mig("E3", f);
      h("E3r: repair, then validate"); try { var rr = f.repair(); System.out.println(" E3r repair OK repaired=" + rr.repairActions); } catch (Exception e) { System.out.println(" E3r repair ERROR " + msg(e)); }
      hist("s13e", "flyway_audit"); val("E3r", f);
    }
    // restore the original checksum state through repair with the original jar so later cases start from the same history
    try (var l = cl(jarSame)) { fw("s13e", "flyway_audit", false, l, "classpath:" + CP).repair(); }
    Map<String, String> ren = new LinkedHashMap<>(same); ren.remove(CP + "V0002__idx_audit_log.sql"); ren.put(CP + "V0002__renamed_index.sql", v2);
    try (var l = cl(jar(W.resolve("e/audit-renamed.jar"), ren))) { h("E4: jar where V0002 has another description"); val("E4", fw("s13e", "flyway_audit", false, l, "classpath:" + CP)); }
    h("E5: location dropped (no location for the applied migrations)");
    Path empty = W.resolve("e/empty"); Files.createDirectories(empty);
    val("E5", fw("s13e", "flyway_audit", false, null, "filesystem:" + empty));
    h("E6: old filesystem dir still present AND jar location configured");
    try (var l = cl(jarSame)) { var f = fw("s13e", "flyway_audit", false, l, "filesystem:" + EA, "classpath:" + CP); val("E6", f); mig("E6", f); }
    Map<String, String> plus = new LinkedHashMap<>(same); plus.put(CP + "V0003__add_note.sql", "alter table app.audit_log add column note text;\n");
    try (var l = cl(jar(W.resolve("e/audit-v0003.jar"), plus))) { h("E7: jar ships a new V0003"); var f = fw("s13e", "flyway_audit", false, l, "classpath:" + CP); mig("E7", f); hist("s13e", "flyway_audit"); }

    h("F: classpath collisions. Two jars with the SAME un-namespaced path db/migration/V1__*.sql");
    newDb("s13f1"); Map<String, String> jx = Map.of("db/migration/V1__x.sql", "create table app.x(id int);"), jy = Map.of("db/migration/V1__y.sql", "create table app.y(id int);");
    try (var l = cl(jar(W.resolve("f/x.jar"), jx), jar(W.resolve("f/y.jar"), jy))) { mig("F1", fw("s13f1", "flyway_schema_history", false, l, "classpath:db/migration")); }
    h("F2: namespaced jars, locations listed per module, ONE shared table (both V1)");
    newDb("s13f2"); String PX = "db/migration/net/kodelix/core/x/", PY = "db/migration/net/kodelix/core/y/";
    Path jx2 = jar(W.resolve("f/x2.jar"), Map.of(PX + "V1__x.sql", "create table app.x(id int);")), jy2 = jar(W.resolve("f/y2.jar"), Map.of(PY + "V1__y.sql", "create table app.y(id int);"));
    try (var l = cl(jx2, jy2)) { mig("F2 shared table", fw("s13f2", "flyway_schema_history", false, l, "classpath:" + PX, "classpath:" + PY)); }
    h("F3: same, one history table per module");
    newDb("s13f3");
    try (var l = cl(jx2, jy2)) { mig("F3 x", fw("s13f3", "flyway_x", false, l, "classpath:" + PX)); mig("F3 y", fw("s13f3", "flyway_y", false, l, "classpath:" + PY)); hist("s13f3", "flyway_x"); hist("s13f3", "flyway_y"); }
    h("F4: parent classpath location db/migration/net/kodelix/core picks up both modules (recursion), per-module tables NOT used");
    newDb("s13f4");
    try (var l = cl(jx2, jy2)) { mig("F4", fw("s13f4", "flyway_schema_history", false, l, "classpath:db/migration/net/kodelix/core")); }

    h("G: switching an EXISTING database from one shared table to a per-module table");
    newDb("s13g"); Path GA = W.resolve("g/audit"); put(GA, "V0001__audit_create.sql", "create table app.audit_log(id int);"); put(GA, "V0002__audit_idx.sql", "create index on app.audit_log(id);");
    mig("G shared", fw("s13g", "flyway_schema_history", false, null, "filesystem:" + GA)); hist("s13g", "flyway_schema_history");
    mig("G1 new table name, no baseline", fw("s13g", "flyway_audit", false, null, "filesystem:" + GA));
    var gb = Flyway.configure().dataSource(url("s13g"), "postgres", "").locations("filesystem:" + GA).defaultSchema("app").schemas("app").table("flyway_audit").baselineOnMigrate(true).baselineVersion("0002").load();
    mig("G2 baselineOnMigrate baselineVersion=0002", gb); hist("s13g", "flyway_audit");
    System.out.println("\nDONE");
  }
}
