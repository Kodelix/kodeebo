// Fmt.java - JVM locale formatting of EGP amounts and a date, ar-EG and en-EG. Run: java Fmt.java
import java.text.NumberFormat; import java.util.*; import java.time.*; import java.time.format.*;
public class Fmt { public static void main(String[] a) {
  System.out.println("java " + System.getProperty("java.version") + " locale.providers=" + System.getProperty("java.locale.providers"));
  for (String tag : new String[]{"ar-EG", "ar-EG-u-nu-latn", "en-EG", "en-US"}) {
    Locale l = Locale.forLanguageTag(tag);
    NumberFormat c = NumberFormat.getCurrencyInstance(l); c.setCurrency(Currency.getInstance("EGP"));
    System.out.println(tag + " currency(1234567.5)=" + c.format(1234567.5) + "  currency(0.5)=" + c.format(0.5) + "  number(1234567.5)=" + NumberFormat.getInstance(l).format(1234567.5));
    System.out.println(tag + " date=" + DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM).withLocale(l).format(ZonedDateTime.of(2026,10,18,23,5,0,0,ZoneId.of("Africa/Cairo"))));
  }
  System.out.println("tz Africa/Cairo offset 2026-10-18 = " + ZoneId.of("Africa/Cairo").getRules().getOffset(Instant.parse("2026-10-18T12:00:00Z")));
}}
