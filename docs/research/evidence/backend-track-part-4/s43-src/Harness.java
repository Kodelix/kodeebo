// Harness.java - calls the Go c-shared library from the JVM through the Foreign Function & Memory API (preview in JDK 21).
// Args: libbill.so, vectors.jsonl (one case per line). Run: java --enable-preview --source 21 --enable-native-access=ALL-UNNAMED Harness.java ...
import java.lang.foreign.*;
import java.lang.invoke.MethodHandle;
import java.nio.file.*;
import java.util.regex.*;

public class Harness {
  public static void main(String[] a) throws Throwable {
    Linker linker = Linker.nativeLinker();
    SymbolLookup lib = SymbolLookup.libraryLookup(Path.of(a[0]), Arena.global());
    MethodHandle h = linker.downcallHandle(lib.find("KodeeboAmount").orElseThrow(),
        FunctionDescriptor.of(ValueLayout.JAVA_LONG, ValueLayout.ADDRESS));
    Pattern p = Pattern.compile("\"id\":(\\d+)");
    StringBuilder sb = new StringBuilder();
    long t0 = System.nanoTime();
    int n = 0;
    try (Arena arena = Arena.ofConfined()) {
      for (String line : Files.readAllLines(Path.of(a[1]))) {
        Matcher m = p.matcher(line);
        m.find();
        MemorySegment s = arena.allocateUtf8String(line);
        long v = (long) h.invokeExact(s);
        sb.append(m.group(1)).append(',').append(v).append('\n');
        n++;
      }
    }
    System.out.print(sb);
    System.err.println("java " + System.getProperty("java.version") + " calls_ms=" + (System.nanoTime() - t0) / 1e6 + " n=" + n);
  }
}
