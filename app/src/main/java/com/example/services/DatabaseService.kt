package com.example.services

import com.example.core.AdminConfig
import com.example.core.EncryptionHelper
import com.example.models.CategoryModel
import com.example.models.VideoModel
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.Query
import com.google.firebase.database.ServerValue
import kotlinx.coroutines.tasks.await
import java.security.MessageDigest

class DatabaseService {
    private val database: FirebaseDatabase by lazy {
        FirebaseDatabase.getInstance(AdminConfig.DB_URL)
    }

    private val rootRef get() = database.reference

    suspend fun seedInitialDataIfEmpty() {
        try {
            val snapshot = rootRef.child("categories").get().await()
            if (!snapshot.exists() || snapshot.childrenCount == 0L) {
                val seedData = mapOf(
                    "categories" to mapOf(
                        "-Ncat1" to mapOf("name" to "Trending", "isPaid" to false, "order" to 0, "isAdult" to false),
                        "-Ncat2" to mapOf("name" to "Movies", "isPaid" to false, "order" to 1, "isAdult" to false),
                        "-Ncat3" to mapOf("name" to "Web Series", "isPaid" to false, "order" to 2, "isAdult" to false),
                        "-Ncat4" to mapOf("name" to "Adult", "isPaid" to false, "order" to 99, "isAdult" to true)
                    ),
                    "home_layout" to mapOf(
                        "sections" to listOf(
                            mapOf("type" to "carousel", "title" to "Live Events", "source" to "live_events", "order" to 0),
                            mapOf("type" to "row", "title" to "Trending", "source" to "videos", "filter" to "trending", "order" to 1),
                            mapOf("type" to "row", "title" to "Movies", "source" to "videos", "category" to "-Ncat2", "order" to 2),
                            mapOf("type" to "row", "title" to "Web Series", "source" to "videos", "category" to "-Ncat3", "order" to 3),
                            mapOf("type" to "adult_card", "title" to "Adult", "order" to 99)
                        )
                    ),
                    "settings" to mapOf(
                        "ads" to mapOf(
                            "normalAdLink" to "",
                            "adultAdLink" to "",
                            "adTimerSeconds" to 5,
                            "adsEnabled" to true
                        ),
                        "app" to mapOf(
                            "appStoreLink" to "https://jiohotstar.app/download",
                            "updateUrl" to "https://jiohotstar.app/update",
                            "forceUpdate" to false,
                            "maintenanceMode" to false,
                            "minVersion" to "1.0.0",
                            "adminUPI" to "hotstar@upi"
                        )
                    ),
                    "plans" to mapOf(
                        "-plan1" to mapOf("name" to "1 Month", "price" to 99, "durationDays" to 30, "order" to 0),
                        "-plan2" to mapOf("name" to "3 Months", "price" to 249, "durationDays" to 90, "order" to 1),
                        "-plan3" to mapOf("name" to "1 Year", "price" to 899, "durationDays" to 365, "order" to 2)
                    )
                )
                rootRef.updateChildren(seedData).await()
            }
        } catch (_: Exception) {}
    }

    suspend fun getLiveEvents(): List<Map<String, Any?>> {
        return try {
            val snapshot = rootRef.child("live_events").get().await()
            if (!snapshot.exists()) return emptyList()
            val list = mutableListOf<Map<String, Any?>>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                val map = child.value as? Map<*, *> ?: continue
                val m = map.toMutableMap()
                m["id"] = key
                @Suppress("UNCHECKED_CAST")
                list.add(m as Map<String, Any?>)
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun addLiveEvent(
        title: String,
        streamUrl: String,
        bannerUrl: String = "",
        channelName: String = "Jio Live",
        category: String = "Cricket",
        isPremium: Boolean = false,
        isActive: Boolean = true
    ) {
        val ref = rootRef.child("live_events").push()
        ref.setValue(mapOf(
            "title" to title,
            "streamUrl" to streamUrl,
            "bannerUrl" to bannerUrl,
            "thumbnailUrl" to bannerUrl,
            "channelName" to channelName,
            "category" to category,
            "isPremium" to isPremium,
            "isActive" to isActive,
            "isLive" to isActive,
            "createdAt" to ServerValue.TIMESTAMP
        )).await()
    }

    suspend fun deleteLiveEvent(id: String) {
        rootRef.child("live_events").child(id).removeValue().await()
    }

    suspend fun toggleLiveEvent(id: String, isActive: Boolean) {
        val updates = mapOf<String, Any>(
            "isActive" to isActive,
            "isLive" to isActive
        )
        rootRef.child("live_events").child(id).updateChildren(updates).await()
    }

    suspend fun getVideos(limit: Int = 30, startAfterKey: String? = null): List<VideoModel> {
        return try {
            var query: Query = rootRef.child("videos").orderByKey()
            if (startAfterKey != null) {
                query = query.startAfter(startAfterKey)
            }
            query = query.limitToFirst(limit)

            val snapshot = query.get().await()
            val list = mutableListOf<VideoModel>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                val map = child.value as? Map<*, *> ?: continue
                @Suppress("UNCHECKED_CAST")
                list.add(VideoModel.fromMap(key, map as Map<String, Any?>))
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getVideoById(id: String): VideoModel? {
        return try {
            val snapshot = rootRef.child("videos").child(id).get().await()
            if (snapshot.exists() && snapshot.value is Map<*, *>) {
                @Suppress("UNCHECKED_CAST")
                VideoModel.fromMap(id, snapshot.value as Map<String, Any?>)
            } else null
        } catch (_: Exception) {
            null
        }
    }

    suspend fun getCategories(): List<CategoryModel> {
        return try {
            val snapshot = rootRef.child("categories").orderByChild("order").get().await()
            val list = mutableListOf<CategoryModel>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                val map = child.value as? Map<*, *> ?: continue
                @Suppress("UNCHECKED_CAST")
                list.add(CategoryModel.fromMap(key, map as Map<String, Any?>))
            }
            list.sortedBy { it.order }
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getHomeLayout(): Map<String, Any?> {
        return try {
            val snapshot = rootRef.child("home_layout").get().await()
            @Suppress("UNCHECKED_CAST")
            (snapshot.value as? Map<String, Any?>) ?: defaultLayout()
        } catch (_: Exception) {
            defaultLayout()
        }
    }

    private fun defaultLayout(): Map<String, Any?> {
        return mapOf(
            "sections" to listOf(
                mapOf("type" to "carousel", "title" to "Live Events", "source" to "live_events", "order" to 0),
                mapOf("type" to "row", "title" to "Trending", "source" to "videos", "filter" to "trending", "order" to 1),
                mapOf("type" to "adult_card", "title" to "Adult Content", "order" to 99)
            )
        )
    }

    suspend fun getAdSettings(): Map<String, Any?> {
        return try {
            val snapshot = rootRef.child("settings/ads").get().await()
            val raw = snapshot.value as? Map<*, *>
            val normalEnc = raw?.get("normalAdLink")?.toString() ?: ""
            val adultEnc = raw?.get("adultAdLink")?.toString() ?: ""
            val timer = (raw?.get("adTimerSeconds") as? Number)?.toInt() ?: 5
            val enabled = raw?.get("adsEnabled") as? Boolean ?: true

            mapOf(
                "normalAdLink" to if (normalEnc.isNotEmpty()) EncryptionHelper.decrypt(normalEnc) else "",
                "adultAdLink" to if (adultEnc.isNotEmpty()) EncryptionHelper.decrypt(adultEnc) else "",
                "adTimerSeconds" to timer,
                "adsEnabled" to enabled
            )
        } catch (_: Exception) {
            mapOf("normalAdLink" to "", "adultAdLink" to "", "adTimerSeconds" to 5, "adsEnabled" to true)
        }
    }

    suspend fun getAppSettings(): Map<String, Any?> {
        return try {
            val snapshot = rootRef.child("settings/app").get().await()
            @Suppress("UNCHECKED_CAST")
            (snapshot.value as? Map<String, Any?>) ?: defaultAppSettings()
        } catch (_: Exception) {
            defaultAppSettings()
        }
    }

    private fun defaultAppSettings(): Map<String, Any?> {
        return mapOf(
            "appName" to "Jio Hotstar Premium",
            "appStoreLink" to "https://jiohotstar.app/download",
            "updateUrl" to "https://jiohotstar.app/update",
            "forceUpdate" to false,
            "maintenanceMode" to false,
            "minVersion" to "1.0.0",
            "adminUPI" to "hotstar@upi"
        )
    }

    suspend fun getVideosByCategory(categoryId: String, limit: Int = 10, excludeId: String? = null): List<VideoModel> {
        return try {
            val query = rootRef.child("videos").orderByChild("categoryId").equalTo(categoryId).limitToFirst(limit + 1)
            val snapshot = query.get().await()
            val list = mutableListOf<VideoModel>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                if (key == excludeId) continue
                val map = child.value as? Map<*, *> ?: continue
                @Suppress("UNCHECKED_CAST")
                list.add(VideoModel.fromMap(key, map as Map<String, Any?>))
            }
            list.take(limit)
        } catch (_: Exception) {
            emptyList()
        }
    }

    suspend fun getTrendingVideos(limit: Int = 10): List<VideoModel> {
        return try {
            val query = rootRef.child("videos").orderByChild("isTrending").equalTo(true).limitToFirst(limit)
            val snapshot = query.get().await()
            val list = mutableListOf<VideoModel>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                val map = child.value as? Map<*, *> ?: continue
                @Suppress("UNCHECKED_CAST")
                list.add(VideoModel.fromMap(key, map as Map<String, Any?>))
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    // --- Admin Operations ---
    suspend fun addVideo(video: VideoModel): String {
        val newRef = rootRef.child("videos").push()
        val data = video.toMap().toMutableMap()
        data["createdAt"] = ServerValue.TIMESTAMP
        data["views"] = 0
        newRef.setValue(data).await()
        return newRef.key ?: ""
    }

    suspend fun updateVideo(id: String, map: Map<String, Any?>) {
        rootRef.child("videos").child(id).updateChildren(map).await()
    }

    suspend fun deleteVideo(id: String) {
        rootRef.child("videos").child(id).removeValue().await()
    }

    suspend fun addCategory(name: String, isPaid: Boolean, order: Int, isAdult: Boolean) {
        val newRef = rootRef.child("categories").push()
        newRef.setValue(mapOf(
            "name" to name,
            "isPaid" to isPaid,
            "order" to order,
            "isAdult" to isAdult
        )).await()
    }

    suspend fun deleteCategory(id: String) {
        rootRef.child("categories").child(id).removeValue().await()
    }

    suspend fun saveHomeSections(sections: List<Map<String, Any?>>) {
        rootRef.child("home_layout/sections").setValue(sections).await()
    }

    suspend fun saveAdSettings(normalAd: String, adultAd: String, timer: Int, enabled: Boolean) {
        val normalEnc = if (normalAd.isNotEmpty()) EncryptionHelper.encrypt(normalAd) else ""
        val adultEnc = if (adultAd.isNotEmpty()) EncryptionHelper.encrypt(adultAd) else ""
        rootRef.child("settings/ads").setValue(mapOf(
            "normalAdLink" to normalEnc,
            "adultAdLink" to adultEnc,
            "adTimerSeconds" to timer,
            "adsEnabled" to enabled
        )).await()
    }

    suspend fun getPlans(): List<Map<String, Any?>> {
        return try {
            val snapshot = rootRef.child("plans").get().await()
            val list = mutableListOf<Map<String, Any?>>()
            for (child in snapshot.children) {
                val key = child.key ?: continue
                val map = child.value as? Map<*, *> ?: continue
                val m = map.toMutableMap()
                m["id"] = key
                @Suppress("UNCHECKED_CAST")
                list.add(m as Map<String, Any?>)
            }
            if (list.none { it["id"] == "trial_1rs" || (it["price"] as? Number)?.toInt() == 1 }) {
                list.add(0, mapOf(
                    "id" to "trial_1rs",
                    "name" to "₹1 Premium Trial",
                    "price" to 1,
                    "durationDays" to 1,
                    "isTrial" to true,
                    "order" to 0
                ))
            }
            list.sortedBy { (it["order"] as? Number)?.toInt() ?: 10 }
        } catch (_: Exception) {
            listOf(
                mapOf("id" to "trial_1rs", "name" to "₹1 Premium Trial", "price" to 1, "durationDays" to 1, "isTrial" to true, "order" to 0),
                mapOf("name" to "1 Month", "price" to 99, "durationDays" to 30, "order" to 1),
                mapOf("name" to "3 Months", "price" to 249, "durationDays" to 90, "isPopular" to true, "order" to 2),
                mapOf("name" to "1 Year", "price" to 899, "durationDays" to 365, "order" to 3)
            )
        }
    }

    suspend fun addPlan(name: String, price: Int, durationDays: Int) {
        val ref = rootRef.child("plans").push()
        ref.setValue(mapOf(
            "name" to name,
            "price" to price,
            "durationDays" to durationDays,
            "order" to 10
        )).await()
    }

    suspend fun deletePlan(id: String) {
        rootRef.child("plans").child(id).removeValue().await()
    }

    suspend fun saveAppSettings(settings: Map<String, Any?>) {
        rootRef.child("settings/app").updateChildren(settings).await()
    }

    suspend fun getStats(): Map<String, Int> {
        var totalUsers = 0
        var premiumUsers = 0
        var totalVideos = 0
        var totalCategories = 0

        try {
            val uSnap = rootRef.child("users").get().await()
            totalUsers = uSnap.childrenCount.toInt()
            for (u in uSnap.children) {
                val m = u.value as? Map<*, *>
                if (m?.get("plan") == "premium") premiumUsers++
            }
            totalVideos = rootRef.child("videos").get().await().childrenCount.toInt()
            totalCategories = rootRef.child("categories").get().await().childrenCount.toInt()
        } catch (_: Exception) {}

        return mapOf(
            "totalUsers" to totalUsers,
            "premiumUsers" to premiumUsers,
            "totalVideos" to totalVideos,
            "totalCategories" to totalCategories
        )
    }

    // Adult Password
    suspend fun setAdultPassword(uid: String, rawPass: String) {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(rawPass.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
        rootRef.child("users").child(uid).child("adultPasswordHash").setValue(hash).await()
    }

    suspend fun verifyAdultPassword(uid: String, rawPass: String): Boolean {
        return try {
            val snap = rootRef.child("users").child(uid).child("adultPasswordHash").get().await()
            val stored = snap.value?.toString() ?: return false
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(rawPass.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
            stored == hash
        } catch (_: Exception) {
            false
        }
    }
}
