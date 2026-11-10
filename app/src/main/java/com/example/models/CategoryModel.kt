package com.example.models

data class CategoryModel(
    val id: String = "",
    val name: String = "",
    val isPaid: Boolean = false,
    val order: Int = 0,
    val isAdult: Boolean = false
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "name" to name,
            "isPaid" to isPaid,
            "order" to order,
            "isAdult" to isAdult
        )
    }

    companion object {
        fun fromMap(id: String, map: Map<String, Any?>): CategoryModel {
            return CategoryModel(
                id = id,
                name = map["name"] as? String ?: "",
                isPaid = map["isPaid"] as? Boolean ?: false,
                order = (map["order"] as? Number)?.toInt() ?: 0,
                isAdult = map["isAdult"] as? Boolean ?: false
            )
        }
    }
}
