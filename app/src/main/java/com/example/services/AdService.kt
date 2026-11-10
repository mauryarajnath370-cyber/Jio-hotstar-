package com.example.services

class AdService(private val databaseService: DatabaseService = DatabaseService()) {

    suspend fun getNormalAdLink(): String {
        return try {
            val settings = databaseService.getAdSettings()
            settings["normalAdLink"]?.toString() ?: ""
        } catch (_: Exception) {
            ""
        }
    }

    suspend fun getAdultAdLink(): String {
        return try {
            val settings = databaseService.getAdSettings()
            settings["adultAdLink"]?.toString() ?: ""
        } catch (_: Exception) {
            ""
        }
    }

    suspend fun getAdTimerSeconds(): Int {
        return try {
            val settings = databaseService.getAdSettings()
            (settings["adTimerSeconds"] as? Number)?.toInt() ?: 5
        } catch (_: Exception) {
            5
        }
    }
}
