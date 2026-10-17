import java.nio.file.*; import java.security.*; import java.security.spec.*; import java.util.*;
import java.util.regex.*;
public class S202Java {
  static byte[] hex(String s){ byte[] b=new byte[s.length()/2]; for(int i=0;i<b.length;i++) b[i]=(byte)Integer.parseInt(s.substring(2*i,2*i+2),16); return b; }
  public static void main(String[] a) throws Exception {
    String j = Files.readString(Path.of(a[0]));
    Matcher m = Pattern.compile("\"name\": \"([^\"]*)\",\\s*\"pub\": \"([0-9a-f]*)\",\\s*\"msg\": \"([0-9a-f]*)\",\\s*\"sig\": \"([0-9a-f]*)\"").matcher(j);
    System.out.println("java " + System.getProperty("java.runtime.version"));
    byte[] spkiPrefix = hex("302a300506032b6570032100"); // RFC 8410 SPKI prefix for 1.3.101.112
    while (m.find()) {
      byte[] pub = hex(m.group(2)), msg = hex(m.group(3)), sig = hex(m.group(4));
      String jdk, bc;
      try { byte[] spki = new byte[spkiPrefix.length + pub.length]; System.arraycopy(spkiPrefix,0,spki,0,spkiPrefix.length); System.arraycopy(pub,0,spki,spkiPrefix.length,pub.length);
        PublicKey k = KeyFactory.getInstance("Ed25519").generatePublic(new X509EncodedKeySpec(spki));
        Signature s = Signature.getInstance("Ed25519"); s.initVerify(k); s.update(msg); jdk = String.valueOf(s.verify(sig)); }
      catch (Throwable e) { jdk = "THROW(" + e.getClass().getSimpleName() + ": " + e.getMessage() + ")"; }
      try { org.bouncycastle.math.ec.rfc8032.Ed25519.class.getName();
        bc = String.valueOf(org.bouncycastle.math.ec.rfc8032.Ed25519.verify(sig, 0, pub, 0, msg, 0, msg.length)); }
      catch (Throwable e) { bc = "THROW(" + e.getClass().getSimpleName() + ")"; }
      System.out.printf("%-55s jdk=%-60s bc=%s%n", m.group(1), jdk, bc);
    }
  }
}
