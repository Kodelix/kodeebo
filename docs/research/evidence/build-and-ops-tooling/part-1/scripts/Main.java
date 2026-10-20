import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
/** S11 probe: args = cmd user initSql target locationDir. Throwaway, not production code. */
public class Main {
  public static void main(String[] a) {
    String cmd = a[0], user = a[1], init = a[2], target = a[3], loc = a[4];
    var c = Flyway.configure()
      .dataSource("jdbc:postgresql://127.0.0.1:" + System.getenv("PGPORT") + "/" + System.getenv().getOrDefault("PGDB", "kodeebo"), user, "")
      .locations("filesystem:" + loc)
      .defaultSchema("app").schemas("app")
      .target(target);
    if (!init.isEmpty()) c.initSql(init);
    if (a.length > 5) { var m = new java.util.HashMap<String,String>(); for (String kv : a[5].split(",")) { String[] x = kv.split("=", 2); m.put(x[0], x[1]); } c.configuration(m); }
    Flyway f = c.load();
    try {
      if (cmd.equals("migrate")) f.migrate();
      else if (cmd.equals("validate")) f.validate();
    } catch (Exception e) { System.out.println("ERROR: " + e.getClass().getName() + ": " + e.getMessage()); }
    try {
      for (MigrationInfo i : f.info().all())
        System.out.println("INFO v=" + i.getVersion() + " desc=" + i.getDescription() + " state=" + i.getState() + " by=" + i.getInstalledBy() + " checksum=" + i.getChecksum());
    } catch (Exception e) { System.out.println("INFO-ERROR: " + e.getMessage()); }
  }
}
