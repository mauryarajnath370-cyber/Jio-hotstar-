package com.example.core

import android.content.Context
import android.content.SharedPreferences

object SecureStorageHelper {
    private const val PREF_NAME = "jio_hotstar_secure_prefs"
    private const val KEY_ADMIN_SESSION = "admin_session_active"
    private const val KEY_AES_KEY = "aes_key"
    private const val KEY_SELECTED_LANGUAGE = "selected_language"
    private const val KEY_WATCH_LATER = "watch_later_ids"
    private const val KEY_RECENT_SEARCHES = "recent_searches"
    private const val KEY_FAILED_ATTEMPTS = "admin_failed_attempts"
    private const val KEY_LOCK_UNTIL = "admin_lock_until"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    // Admin Session
    fun saveAdminSession(context: Context) {
        getPrefs(context).edit().putBoolean(KEY_ADMIN_SESSION, true).apply()
    }

    fun isAdminLoggedIn(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_ADMIN_SESSION, false)
    }

    fun clearAdminSession(context: Context) {
        getPrefs(context).edit().remove(KEY_ADMIN_SESSION).apply()
    }

    // Lockout protection
    fun getFailedAttempts(context: Context): Int {
        return getPrefs(context).getInt(KEY_FAILED_ATTEMPTS, 0)
    }

    fun setFailedAttempts(context: Context, count: Int) {
        getPrefs(context).edit().putInt(KEY_FAILED_ATTEMPTS, count).apply()
    }

    fun getLockUntil(context: Context): Long {
        return getPrefs(context).getLong(KEY_LOCK_UNTIL, 0L)
    }

    fun setLockUntil(context: Context, timestamp: Long) {
        getPrefs(context).edit().putLong(KEY_LOCK_UNTIL, timestamp).apply()
    }

    // AES Key
    fun saveAesKey(context: Context, keyB64: String) {
        getPrefs(context).edit().putString(KEY_AES_KEY, keyB64).apply()
    }

    fun getAesKey(context: Context): String? {
        return getPrefs(context).getString(KEY_AES_KEY, null)
    }

    // Language
    fun getSelectedLanguage(context: Context): String? {
        return getPrefs(context).getString(KEY_SELECTED_LANGUAGE, null)
    }

    fun saveSelectedLanguage(context: Context, langCode: String) {
        getPrefs(context).edit().putString(KEY_SELECTED_LANGUAGE, langCode).apply()
    }

    // Watch Later
    fun getWatchLaterIds(context: Context): Set<String> {
        return getPrefs(context).getStringSet(KEY_WATCH_LATER, emptySet()) ?: emptySet()
    }

    fun toggleWatchLater(context: Context, videoId: String): Boolean {
        val current = getWatchLaterIds(context).toMutableSet()
        val isAdded: Boolean
        if (current.contains(videoId)) {
          current.remove(videoId)
          isAdded = false
        } else {
          current.add(videoId)
          isAdded = true
        }
        getPrefs(context).edit().putStringSet(KEY_WATCH_LATER, current).apply()
        return isAdded
    }

    // Recent searches
    fun getRecentSearches(context: Context): List<String> {
        val raw = getPrefs(context).getString(KEY_RECENT_SEARCHES, "") ?: ""
        return if (raw.isEmpty()) emptyList() else raw.split("|||")
    }

    fun addRecentSearch(context: Context, query: String) {
        if (query.trim().isEmpty()) return
        val current = getRecentSearches(context).toMutableList()
        current.remove(query)
        current.add(0, query)
        val trimmed = if (current.size > 5) current.subList(0, 5) else current
        getPrefs(context).edit().putString(KEY_RECENT_SEARCHES, trimmed.joinToString("|||")).apply()
    }
}
