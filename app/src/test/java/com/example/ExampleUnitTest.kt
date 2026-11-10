package com.example

import com.example.core.AdminAuthHelper
import com.example.core.AdminConfig
import com.example.models.CategoryModel
import com.example.models.UserModel
import com.example.models.VideoModel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExampleUnitTest {
    @Test
    fun admin_fixed_hashes_verify_correctly() {
        val userHash = AdminAuthHelper.hashValue("rohit_123", AdminConfig.SALT)
        val passHash = AdminAuthHelper.hashValue("Aa@12345", AdminConfig.SALT)

        assertEquals("3ebf2c1cd5172d05beeb7e78e5dd537f2ae83cbdc2abfa70e3657294e513ece3", userHash)
        assertEquals("0fbd74e20682be11ed560b9487dc8159a08581d271451800dfa94cefcb5c349c", passHash)
        assertEquals(AdminConfig.ADMIN_USER_HASH, userHash)
        assertEquals(AdminConfig.ADMIN_PASS_HASH, passHash)

        // Test verification function
        assertTrue(AdminAuthHelper.verifyAdmin("rohit_123", "Aa@12345"))
    }

    @Test
    fun models_serialization_and_premium_check() {
        val video = VideoModel(
            id = "vid_101",
            title = "Special Live Match",
            cdnUrl = "https://cdn.example.com/stream.m3u8",
            isPaid = true,
            isTrending = true
        )
        val map = video.toMap()
        val deserialized = VideoModel.fromMap("vid_101", map)
        assertEquals("Special Live Match", deserialized.title)
        assertTrue(deserialized.isPaid)
        assertTrue(deserialized.isTrending)

        val cat = CategoryModel(
            id = "cat_movies",
            name = "Blockbuster Movies",
            order = 1
        )
        val catMap = cat.toMap()
        val catDeserialized = CategoryModel.fromMap("cat_movies", catMap)
        assertEquals("Blockbuster Movies", catDeserialized.name)
        assertEquals(1, catDeserialized.order)

        val user = UserModel(
            uid = "user_42",
            email = "fan@jiohotstar.com",
            plan = "premium",
            planExpiry = 0L // Lifetime
        )
        assertTrue(user.isPremiumActive)
    }
}
