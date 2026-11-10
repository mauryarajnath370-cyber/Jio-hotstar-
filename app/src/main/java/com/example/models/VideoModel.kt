package com.example.models

data class VideoModel(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    val thumbnailUrl: String = "",
    val cdnUrl: String = "",
    val categoryId: String = "",
    val isPaid: Boolean = false,
    val isTrending: Boolean = false,
    val isLive: Boolean = false,
    val isDownloadable: Boolean = true,
    val views: Long = 0L,
    val createdAt: Long = System.currentTimeMillis()
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "title" to title,
            "description" to description,
            "thumbnailUrl" to thumbnailUrl,
            "cdnUrl" to cdnUrl,
            "categoryId" to categoryId,
            "isPaid" to isPaid,
            "isTrending" to isTrending,
            "isLive" to isLive,
            "isDownloadable" to isDownloadable,
            "views" to views,
            "createdAt" to createdAt
        )
    }

    companion object {
        fun fromMap(id: String, map: Map<String, Any?>): VideoModel {
            return VideoModel(
                id = id,
                title = map["title"] as? String ?: "",
                description = map["description"] as? String ?: "",
                thumbnailUrl = map["thumbnailUrl"] as? String ?: "",
                cdnUrl = map["cdnUrl"] as? String ?: "",
                categoryId = map["categoryId"] as? String ?: "",
                isPaid = map["isPaid"] as? Boolean ?: false,
                isTrending = map["isTrending"] as? Boolean ?: false,
                isLive = map["isLive"] as? Boolean ?: false,
                isDownloadable = map["isDownloadable"] as? Boolean ?: true,
                views = (map["views"] as? Number)?.toLong() ?: 0L,
                createdAt = (map["createdAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
            )
        }
    }
}
