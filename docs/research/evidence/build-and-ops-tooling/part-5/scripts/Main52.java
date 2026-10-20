import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.MigrationInfo;
import org.flywaydb.core.api.callback.Callback;
import org.flywaydb.core.api.callback.Context;
import org.flywaydb.core.api.callback.Event;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

/** S52 probe (throwaway, not production code). args = cmd user mode arg target locationDir.
 *  mode: none | initSql | callbackdir | urlopt | jdbcprop | javacb. Env: PGPORT, PGDB. */
public class Main52 {
  public static void main(String[] a) throws Exception {
    String cmd = a[0], user = a[1], mode = a[2], arg = a[3], target = a[4], loc = a[5];
    String url = "jdbc:postgresql://127.0.0.1:" + System.getenv("PGPORT") + "/" + System.getenv("PGDB");
    var c = Flyway.configure()
      .locations("filesystem:" + loc).defaultSchema("app").schemas("app").target(target)
      .configuration(Map.of("flyway.postgresql.transactional.lock", "false"));
    switch (mode) {
      case "initSql": c.initSql(arg); break;
      case "callbackdir": c.callbackLocations("filesystem:" + arg); break;
      case "urlopt": url += "?options=" + java.net.URLEncoder.encode(arg, StandardCharsets.UTF_8).replace("+", "%20"); break;
      case "jdbcprop": c.jdbcProperties(Map.of("options", arg)); break;
      case "javacb": c.callbacks(new Cb(Event.valueOf(arg))); break;
      default: break;
    }
    c.dataSource(url, user, "");
    Flyway f = c.load();
    try {
      if (cmd.equals("migrate")) f.migrate();
      else if (cmd.equals("validate")) f.validate();
    } catch (Exception e) { System.out.println("ERROR: " + e.getClass().getName() + ": " + String.valueOf(e.getMessage()).replace("\n", " | ")); }
    try {
      for (MigrationInfo i : f.info().all())
        System.out.println("INFO v=" + i.getVersion() + " state=" + i.getState() + " by=" + i.getInstalledBy());
    } catch (Exception e) { System.out.println("INFO-ERROR: " + e.getMessage()); }
  }
}

/** Java callback: runs SET ROLE migrator on the connection Flyway hands to the event, prints who it ran as. */
class Cb implements Callback {
  final Event ev;
  Cb(Event e) { ev = e; }
  public boolean supports(Event e, Context ctx) { return e == ev; }
  public boolean canHandleInTransaction(Event e, Context ctx) { return true; }
  public void handle(Event e, Context ctx) {
    try (Statement s = ctx.getConnection().createStatement()) {
      s.execute("SET ROLE migrator");
      ResultSet r = s.executeQuery("select pg_backend_pid(), session_user, current_user");
      r.next();
      System.out.println("JAVACB event=" + e + " pid=" + r.getInt(1) + " session_user=" + r.getString(2) + " current_user=" + r.getString(3));
    } catch (SQLException x) { throw new RuntimeException(x); }
  }
  public String getCallbackName() { return "s52-set-role"; }
}
