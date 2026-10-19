// S31 (researcher, tier-E evidence): build a detached CAdES-BES-shaped CMS SignedData with Bouncy Castle bcpkix 1.86.
// Throwaway RSA-2048 key + self-signed cert generated IN MEMORY; the private key is never written to disk.
// Data = a made-up two-line JSON stand-in, not a real receipt. Args: <outdir>
import java.io.*; import java.math.BigInteger; import java.nio.charset.StandardCharsets; import java.nio.file.*;
import java.security.*; import java.security.cert.X509Certificate; import java.util.*;
import org.bouncycastle.asn1.*; import org.bouncycastle.asn1.cms.*; import org.bouncycastle.asn1.ess.*;
import org.bouncycastle.asn1.nist.NISTObjectIdentifiers; import org.bouncycastle.asn1.pkcs.PKCSObjectIdentifiers;
import org.bouncycastle.asn1.x500.X500Name; import org.bouncycastle.asn1.x509.AlgorithmIdentifier;
import org.bouncycastle.cert.X509CertificateHolder; import org.bouncycastle.cert.jcajce.*;
import org.bouncycastle.cms.*; import org.bouncycastle.cms.jcajce.*; import org.bouncycastle.operator.jcajce.*;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
public class S31Cades {
  public static void main(String[] a) throws Exception {
    Path out = Paths.get(a[0]);
    Security.addProvider(new BouncyCastleProvider());
    KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA"); kpg.initialize(2048); KeyPair kp = kpg.generateKeyPair();
    X500Name dn = new X500Name("CN=S31 throwaway test");
    Date nb = new Date(), na = new Date(nb.getTime() + 86400000L);
    X509CertificateHolder ch = new JcaX509v3CertificateBuilder(dn, BigInteger.ONE, nb, na, dn, kp.getPublic())
        .build(new JcaContentSignerBuilder("SHA256withRSA").build(kp.getPrivate()));
    X509Certificate cert = new JcaX509CertificateConverter().getCertificate(ch);
    byte[] data = "{\"RECEIPTS\":[{\"X\":\"S31 stand-in\"}]}".getBytes(StandardCharsets.UTF_8);
    byte[] certSha = MessageDigest.getInstance("SHA-256").digest(cert.getEncoded());
    SigningCertificateV2 scv2 = new SigningCertificateV2(new ESSCertIDv2(new AlgorithmIdentifier(NISTObjectIdentifiers.id_sha256), certSha));
    CMSAttributeTableGenerator gen = p -> {
      ASN1EncodableVector v = new ASN1EncodableVector();
      v.add(new Attribute(CMSAttributes.contentType, new DERSet((ASN1ObjectIdentifier) p.get(CMSAttributeTableGenerator.CONTENT_TYPE))));
      v.add(new Attribute(CMSAttributes.messageDigest, new DERSet(new DEROctetString((byte[]) p.get(CMSAttributeTableGenerator.DIGEST)))));
      v.add(new Attribute(PKCSObjectIdentifiers.id_aa_signingCertificateV2, new DERSet(scv2)));
      v.add(new Attribute(CMSAttributes.signingTime, new DERSet(new org.bouncycastle.asn1.x509.Time(new Date()))));
      return new AttributeTable(v);
    };
    CMSSignedDataGenerator g = new CMSSignedDataGenerator();
    g.addSignerInfoGenerator(new JcaSignerInfoGeneratorBuilder(new JcaDigestCalculatorProviderBuilder().build())
        .setSignedAttributeGenerator(gen).setUnsignedAttributeGenerator(null)
        .build(new JcaContentSignerBuilder("SHA256withRSA").build(kp.getPrivate()), ch));
    g.addCertificates(new JcaCertStore(List.of(cert)));
    CMSSignedData sd = g.generate(new CMSProcessableByteArray(data), false); // false = detached
    Files.write(out.resolve("data.bin"), data); Files.write(out.resolve("sig.der"), sd.getEncoded());
    Files.write(out.resolve("cert.der"), cert.getEncoded());
    // round trip with BC's own verifier
    CMSSignedData chk = new CMSSignedData(new CMSProcessableByteArray(data), sd.getEncoded());
    for (SignerInformation si : chk.getSignerInfos().getSigners()) {
      boolean ok = si.verify(new JcaSimpleSignerInfoVerifierBuilder().build(cert));
      System.out.println("BC round-trip verify = " + ok + "; digestAlg=" + si.getDigestAlgOID() + "; encAlg=" + si.getEncryptionAlgOID()
        + "; signedAttrs=" + si.getSignedAttributes().size() + "; unsignedAttrs=" + (si.getUnsignedAttributes()==null?0:si.getUnsignedAttributes().size()));
    }
    System.out.println("SHA-256(data)=" + HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(data)));
    System.out.println("sig.der bytes=" + sd.getEncoded().length);
  }
}
