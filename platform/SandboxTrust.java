import java.io.ByteArrayInputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;

import org.apache.camel.BindToRegistry;
import org.apache.camel.support.jsse.KeyStoreParameters;
import org.apache.camel.support.jsse.SSLContextParameters;
import org.apache.camel.support.jsse.TrustManagersParameters;

/**
 * Truststore for the OpenShift service CA mounted in every pod at
 * /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt.
 * The shared OpenShift AI predictors present a certificate signed by that CA.
 */
@BindToRegistry("sandboxSsl")
public class SandboxTrust extends SSLContextParameters {

    public SandboxTrust() {
        try {
            String pem = Files.readString(Path.of("/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt"));
            CertificateFactory factory = CertificateFactory.getInstance("X.509");
            char[] password = "changeit".toCharArray();
            KeyStore store = KeyStore.getInstance("PKCS12");
            store.load(null, password);
            int index = 0;
            for (Certificate certificate : factory.generateCertificates(
                    new ByteArrayInputStream(pem.getBytes(StandardCharsets.UTF_8)))) {
                store.setCertificateEntry("service-ca-" + index++, certificate);
            }
            Path truststore = Path.of("/tmp/service-ca.p12");
            try (OutputStream output = Files.newOutputStream(truststore)) {
                store.store(output, password);
            }
            KeyStoreParameters parameters = new KeyStoreParameters();
            parameters.setResource(truststore.toUri().toString());
            parameters.setType("PKCS12");
            parameters.setPassword("changeit");
            TrustManagersParameters trust = new TrustManagersParameters();
            trust.setKeyStore(parameters);
            setTrustManagers(trust);
        } catch (Exception exception) {
            throw new IllegalStateException("No se pudo cargar service-ca.crt", exception);
        }
    }
}
