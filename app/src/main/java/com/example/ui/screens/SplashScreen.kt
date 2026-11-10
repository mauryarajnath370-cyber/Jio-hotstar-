package com.example.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.example.core.AdminConfig
import com.example.core.EncryptionHelper
import com.example.core.SecureStorageHelper
import com.example.services.DatabaseService
import com.example.ui.components.JioHotstarLogo
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(
    onNavigateToLanguage: () -> Unit,
    onNavigateToLogin: () -> Unit,
    onNavigateToHome: () -> Unit
) {
    val context = LocalContext.current
    val scale = remember { Animatable(0.85f) }
    val alpha = remember { Animatable(0.0f) }

    LaunchedEffect(Unit) {
        // 500ms animation
        scale.animateTo(1.0f, animationSpec = tween(500, easing = FastOutSlowInEasing))
        alpha.animateTo(1.0f, animationSpec = tween(500))

        try {
            if (FirebaseApp.getApps(context).isEmpty()) {
                FirebaseApp.initializeApp(context)
            }
            try {
                FirebaseDatabase.getInstance(AdminConfig.DB_URL).setPersistenceEnabled(true)
            } catch (_: Exception) {}

            EncryptionHelper.init(context)
            DatabaseService().seedInitialDataIfEmpty()
        } catch (_: Exception) {}

        delay(1500)

        val selectedLanguage = SecureStorageHelper.getSelectedLanguage(context)
        if (selectedLanguage == null) {
            onNavigateToLanguage()
        } else {
            val user = FirebaseAuth.getInstance().currentUser
            if (user == null) {
                onNavigateToLogin()
            } else {
                onNavigateToHome()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF0F0F0F),
                        Color(0xFF1A0000)
                    )
                )
            )
            .padding(24.dp)
            .testTag("splash_screen_container"),
        contentAlignment = Alignment.Center
    ) {
        JioHotstarLogo(
            size = 38,
            modifier = Modifier
                .scale(scale.value)
                .alpha(alpha.value)
                .testTag("splash_logo")
        )
    }
}
