package com.example.core

import java.security.MessageDigest

object AdminConfig {
    const val SALT = "x7Kp9mQ2vL8nR4tY6wZ1aB3cD5eF7gH9"
    const val DB_URL = "https://jio-hotstar-premium-default-rtdb.firebaseio.com/"
    const val ADMIN_USERNAME = "rohit_123"

    // Hardcoded verified SHA-256 hashes: sha256(username + salt) and sha256(password + salt)
    const val ADMIN_USER_HASH = "3ebf2c1cd5172d05beeb7e78e5dd537f2ae83cbdc2abfa70e3657294e513ece3"
    const val ADMIN_PASS_HASH = "0fbd74e20682be11ed560b9487dc8159a08581d271451800dfa94cefcb5c349c"
}

object AdminAuthHelper {
    fun hashValue(value: String, salt: String): String {
        val input = value + salt
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    fun verifyAdmin(user: String, pass: String): Boolean {
        val inputUserHash = hashValue(user, AdminConfig.SALT)
        val inputPassHash = hashValue(pass, AdminConfig.SALT)
        return inputUserHash.equals(AdminConfig.ADMIN_USER_HASH, ignoreCase = true) &&
                inputPassHash.equals(AdminConfig.ADMIN_PASS_HASH, ignoreCase = true)
    }
}
