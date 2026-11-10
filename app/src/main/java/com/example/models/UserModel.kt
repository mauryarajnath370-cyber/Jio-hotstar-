package com.example.models

data class UserModel(
    val uid: String = "",
    val email: String = "",
    val name: String = "",
    val photoUrl: String = "",
    val plan: String = "free",
    val planExpiry: Long = 0L,
    val isAdmin: Boolean = false,
    val adultPasswordHash: String = "",
    val createdAt: Long = System.currentTimeMillis()
) {
    val isPremiumActive: Boolean
        get() {
            if (plan != "premium") return false
            if (planExpiry == 0L) return true
            return System.currentTimeMillis() < planExpiry
        }

    fun toMap(): Map<String, Any> {
        return mapOf(
            "email" to email,
            "name" to name,
            "photoUrl" to photoUrl,
            "plan" to plan,
            "planExpiry" to planExpiry,
            "isAdmin" to isAdmin,
            "adultPasswordHash" to adultPasswordHash,
            "createdAt" to createdAt
        )
    }

    companion object {
        fun fromMap(uid: String, map: Map<String, Any?>): UserModel {
            return UserModel(
                uid = uid,
                email = map["email"] as? String ?: "",
                name = map["name"] as? String ?: "",
                photoUrl = map["photoUrl"] as? String ?: "",
                plan = map["plan"] as? String ?: "free",
                planExpiry = (map["planExpiry"] as? Number)?.toLong() ?: 0L,
                isAdmin = map["isAdmin"] as? Boolean ?: false,
                adultPasswordHash = map["adultPasswordHash"] as? String ?: "",
                createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
            )
        }
    }
}
