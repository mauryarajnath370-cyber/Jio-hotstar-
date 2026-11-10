package com.example.core

import android.content.Context
import android.util.Base64
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

object EncryptionHelper {
    private const val ALGORITHM = "AES/CBC/PKCS5Padding"
    private var secretKey: SecretKeySpec? = null

    val isInitialized: Boolean
        get() = secretKey != null

    fun init(context: Context) {
        if (secretKey != null) return
        var keyB64 = SecureStorageHelper.getAesKey(context)
        if (keyB64 == null) {
            val random = SecureRandom()
            val keyBytes = ByteArray(32) // 256 bits
            random.nextBytes(keyBytes)
            keyB64 = Base64.encodeToString(keyBytes, Base64.NO_WRAP)
            SecureStorageHelper.saveAesKey(context, keyB64)
        }
        val decoded = Base64.decode(keyB64, Base64.NO_WRAP)
        secretKey = SecretKeySpec(decoded, "AES")
    }

    fun encrypt(plainText: String): String {
        val key = secretKey ?: throw IllegalStateException("EncryptionHelper not initialized")
        val ivBytes = ByteArray(16)
        SecureRandom().nextBytes(ivBytes)
        val ivSpec = IvParameterSpec(ivBytes)

        val cipher = Cipher.getInstance(ALGORITHM)
        cipher.init(Cipher.ENCRYPT_MODE, key, ivSpec)
        val encryptedBytes = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))

        val ivB64 = Base64.encodeToString(ivBytes, Base64.NO_WRAP)
        val cipherB64 = Base64.encodeToString(encryptedBytes, Base64.NO_WRAP)
        return "$ivB64:$cipherB64"
    }

    fun decrypt(encryptedPayload: String): String {
        val key = secretKey ?: return encryptedPayload
        if (!encryptedPayload.contains(":")) return encryptedPayload

        return try {
            val parts = encryptedPayload.split(":")
            if (parts.size != 2) return encryptedPayload

            val ivBytes = Base64.decode(parts[0], Base64.NO_WRAP)
            val cipherBytes = Base64.decode(parts[1], Base64.NO_WRAP)
            val ivSpec = IvParameterSpec(ivBytes)

            val cipher = Cipher.getInstance(ALGORITHM)
            cipher.init(Cipher.DECRYPT_MODE, key, ivSpec)
            val decryptedBytes = cipher.doFinal(cipherBytes)
            String(decryptedBytes, Charsets.UTF_8)
        } catch (_: Exception) {
            encryptedPayload
        }
    }
}
