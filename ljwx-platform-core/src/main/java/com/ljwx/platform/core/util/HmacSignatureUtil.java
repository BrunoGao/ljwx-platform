package com.ljwx.platform.core.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * HMAC Signature Utility
 * <p>
 * Implements HMAC-SHA256 signature generation and verification
 * for Open API authentication.
 * </p>
 *
 * @author LJWX Platform
 * @since Phase 48
 */
public class HmacSignatureUtil {

    private static final String HMAC_SHA256_ALGORITHM = "HmacSHA256";

    /**
     * Generate HMAC-SHA256 signature
     *
     * @param secretKey Secret key
     * @param appKey    Application key
     * @param timestamp Timestamp (milliseconds)
     * @param nonce     Random nonce
     * @param bodyHash  Request body SHA-256 hash (Base64 encoded)
     * @return Base64 encoded signature
     */
    public static String generateSignature(String secretKey, String appKey,
                                            String timestamp, String nonce, String bodyHash) {
        try {
            // 1. Construct data to sign (separated by newline)
            String data = appKey + "\n" + timestamp + "\n" + nonce + "\n" + bodyHash;

            // 2. Use HMAC-SHA256 algorithm
            Mac hmac = Mac.getInstance(HMAC_SHA256_ALGORITHM);
            SecretKeySpec secretKeySpec = new SecretKeySpec(
                secretKey.getBytes(StandardCharsets.UTF_8),
                HMAC_SHA256_ALGORITHM
            );
            hmac.init(secretKeySpec);

            // 3. Calculate signature
            byte[] signatureBytes = hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));

            // 4. Base64 encode
            return Base64.getEncoder().encodeToString(signatureBytes);
        } catch (Exception e) {
            throw new RuntimeException("HMAC signature generation failed", e);
        }
    }

    /**
     * Verify HMAC-SHA256 signature
     *
     * @param signature Signature to verify
     * @param secretKey Secret key
     * @param appKey    Application key
     * @param timestamp Timestamp (milliseconds)
     * @param nonce     Random nonce
     * @param bodyHash  Request body SHA-256 hash (Base64 encoded)
     * @return true if signature is valid, false otherwise
     */
    public static boolean verifySignature(String signature, String secretKey,
                                           String appKey, String timestamp,
                                           String nonce, String bodyHash) {
        String expectedSignature = generateSignature(secretKey, appKey, timestamp, nonce, bodyHash);
        return MessageDigest.isEqual(
            signature.getBytes(StandardCharsets.UTF_8),
            expectedSignature.getBytes(StandardCharsets.UTF_8)
        );
    }

    /**
     * Calculate SHA-256 hash of request body
     *
     * @param body Request body
     * @return Base64 encoded hash
     */
    public static String calculateBodyHash(String body) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(body.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException("Body hash calculation failed", e);
        }
    }
}
