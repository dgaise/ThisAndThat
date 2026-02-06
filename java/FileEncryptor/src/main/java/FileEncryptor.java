import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import java.io.IOException;
import java.nio.file.*;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

public class FileEncryptor {

    private static final String KEY_FILE = "secret.key";
    private static final Set<String> FILES_TO_SKIP = Set.of(
            "secret.key",
            "FileEncryptor.java",
            "FileEncryptor.class"
    );
    private static final int GCM_TAG_LENGTH = 16 * 8; // 16 bytes * 8 bits
    private static final int GCM_IV_LENGTH = 12;       // 12 bytes IV
    private static final SecureRandom RANDOM = new SecureRandom();

    public static void main(String[] args) throws Exception {
        if (args.length < 1 || (!args[0].equalsIgnoreCase("encrypt") && !args[0].equalsIgnoreCase("decrypt"))) {
            System.out.println("Usage: java FileEncryptor <encrypt|decrypt>");
            return;
        }

        boolean encryptMode = args[0].equalsIgnoreCase("encrypt");
        SecretKey key = Files.exists(Path.of(KEY_FILE)) ? loadKey() : generateKey();

        List<Path> filesToProcess = Files.list(Path.of("."))
                .filter(Files::isRegularFile)
                .filter(p -> !FILES_TO_SKIP.contains(p.getFileName().toString()))
                .collect(Collectors.toList());

        for (Path file : filesToProcess) {
            if (encryptMode) {
                encryptFile(file, key);
            } else {
                decryptFile(file, key);
            }
        }

        System.out.println("All files " + (encryptMode ? "encrypted." : "decrypted."));
    }

    private static SecretKey generateKey() throws Exception {
        KeyGenerator kg = KeyGenerator.getInstance("AES");
        kg.init(128); // Fernet uses AES-128
        SecretKey key = kg.generateKey();
        // save as Base64
        Files.write(Path.of(KEY_FILE), Base64.getEncoder().encode(key.getEncoded()));
        System.out.println("New key generated and saved to " + KEY_FILE);
        return key;
    }

    private static SecretKey loadKey() throws IOException {
        byte[] keyBytes = Base64.getDecoder().decode(Files.readAllBytes(Path.of(KEY_FILE)));
        return new javax.crypto.spec.SecretKeySpec(keyBytes, "AES");
    }

    private static void encryptFile(Path file, SecretKey key) throws Exception {
        byte[] content = Files.readAllBytes(file);

        byte[] iv = new byte[GCM_IV_LENGTH];
        RANDOM.nextBytes(iv);
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);

        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);
        byte[] encrypted = cipher.doFinal(content);

        // Prepend IV so we can decrypt later
        byte[] combined = new byte[iv.length + encrypted.length];
        System.arraycopy(iv, 0, combined, 0, iv.length);
        System.arraycopy(encrypted, 0, combined, iv.length, encrypted.length);

        Files.write(file, combined);
        System.out.println("File '" + file.getFileName() + "' encrypted.");
    }

    private static void decryptFile(Path file, SecretKey key) throws Exception {
        byte[] combined = Files.readAllBytes(file);

        byte[] iv = new byte[GCM_IV_LENGTH];
        byte[] encrypted = new byte[combined.length - GCM_IV_LENGTH];

        System.arraycopy(combined, 0, iv, 0, GCM_IV_LENGTH);
        System.arraycopy(combined, GCM_IV_LENGTH, encrypted, 0, encrypted.length);

        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);

        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, key, spec);
        byte[] decrypted = cipher.doFinal(encrypted);

        Files.write(file, decrypted);
        System.out.println("File '" + file.getFileName() + "' decrypted.");
    }
}
