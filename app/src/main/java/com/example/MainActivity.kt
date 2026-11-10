package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.Crossfade
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.example.models.VideoModel
import com.example.ui.screens.AdminDashboardScreen
import com.example.ui.screens.AdminLoginScreen
import com.example.ui.screens.AdultCategoryScreen
import com.example.ui.screens.HomeScreen
import com.example.ui.screens.LanguageScreen
import com.example.ui.screens.LoginScreen
import com.example.ui.screens.PremiumScreen
import com.example.ui.screens.SearchScreen
import com.example.ui.screens.SettingsScreen
import com.example.ui.screens.SplashScreen
import com.example.ui.screens.VideoPlayerScreen
import com.example.ui.theme.JioHotstarTheme

sealed class AppDestination {
    data object Splash : AppDestination()
    data object Language : AppDestination()
    data object Login : AppDestination()
    data object Home : AppDestination()
    data class Player(val video: VideoModel) : AppDestination()
    data object Search : AppDestination()
    data object Premium : AppDestination()
    data object Settings : AppDestination()
    data object Adult : AppDestination()
    data object AdminLogin : AppDestination()
    data object AdminDashboard : AppDestination()
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            JioHotstarTheme {
                MainAppNavigation()
            }
        }
    }
}

@Composable
fun MainAppNavigation() {
    var currentScreen by remember { mutableStateOf<AppDestination>(AppDestination.Splash) }

    BackHandler(enabled = currentScreen !is AppDestination.Splash && currentScreen !is AppDestination.Home) {
        currentScreen = when (currentScreen) {
            is AppDestination.Player,
            is AppDestination.Search,
            is AppDestination.Premium,
            is AppDestination.Settings,
            is AppDestination.Adult,
            is AppDestination.AdminLogin -> AppDestination.Home

            is AppDestination.AdminDashboard -> AppDestination.Home
            is AppDestination.Login -> AppDestination.Language
            is AppDestination.Language -> AppDestination.Language
            else -> AppDestination.Home
        }
    }

    Crossfade(targetState = currentScreen, label = "screen_transition") { screen ->
        when (screen) {
            is AppDestination.Splash -> {
                SplashScreen(
                    onNavigateToLanguage = { currentScreen = AppDestination.Language },
                    onNavigateToLogin = { currentScreen = AppDestination.Login },
                    onNavigateToHome = { currentScreen = AppDestination.Home }
                )
            }
            is AppDestination.Language -> {
                LanguageScreen(
                    onLanguageSelected = { currentScreen = AppDestination.Login }
                )
            }
            is AppDestination.Login -> {
                LoginScreen(
                    onLoginSuccess = { currentScreen = AppDestination.Home }
                )
            }
            is AppDestination.Home -> {
                HomeScreen(
                    onNavigateToVideo = { currentScreen = AppDestination.Player(it) },
                    onNavigateToSearch = { currentScreen = AppDestination.Search },
                    onNavigateToPremium = { currentScreen = AppDestination.Premium },
                    onNavigateToSettings = { currentScreen = AppDestination.Settings },
                    onNavigateToAdult = { currentScreen = AppDestination.Adult },
                    onNavigateToAdmin = { currentScreen = AppDestination.AdminLogin }
                )
            }
            is AppDestination.Player -> {
                VideoPlayerScreen(
                    video = screen.video,
                    onBack = { currentScreen = AppDestination.Home },
                    onVideoSelected = { currentScreen = AppDestination.Player(it) }
                )
            }
            is AppDestination.Search -> {
                SearchScreen(
                    onBack = { currentScreen = AppDestination.Home },
                    onVideoSelected = { currentScreen = AppDestination.Player(it) }
                )
            }
            is AppDestination.Premium -> {
                PremiumScreen(
                    onBack = { currentScreen = AppDestination.Home }
                )
            }
            is AppDestination.Settings -> {
                SettingsScreen(
                    onBack = { currentScreen = AppDestination.Home },
                    onChangeLanguage = { currentScreen = AppDestination.Language },
                    onLogout = { currentScreen = AppDestination.Login }
                )
            }
            is AppDestination.Adult -> {
                AdultCategoryScreen(
                    onBack = { currentScreen = AppDestination.Home },
                    onVideoSelected = { currentScreen = AppDestination.Player(it) }
                )
            }
            is AppDestination.AdminLogin -> {
                AdminLoginScreen(
                    onBack = { currentScreen = AppDestination.Home },
                    onAdminLoginSuccess = { currentScreen = AppDestination.AdminDashboard }
                )
            }
            is AppDestination.AdminDashboard -> {
                AdminDashboardScreen(
                    onBack = { currentScreen = AppDestination.Home }
                )
            }
        }
    }
}
