package com.example.ui.screens

import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.OndemandVideo
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.core.SecureStorageHelper
import com.example.services.AuthService
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.DarkSurfaceVariant
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import com.google.firebase.auth.FirebaseAuth

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onChangeLanguage: () -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val authService = remember { AuthService() }
    val user = FirebaseAuth.getInstance().currentUser
    var showUpdateDialog by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = { Text("Settings", color = TextWhite, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = TextWhite)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkSurface)
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // User Profile Card
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().testTag("user_profile_card")
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(54.dp)
                            .background(AccentRed, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = if (user?.displayName?.isNotEmpty() == true) user.displayName!!.take(1).uppercase() else "J",
                            color = Color.White,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.width(16.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = user?.displayName ?: "Jio Hotstar Viewer",
                            color = TextWhite,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = user?.email ?: "viewer@jiohotstar.com",
                            color = TextGrey,
                            fontSize = 13.sp
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Box(
                            modifier = Modifier
                                .background(GoldAccent, RoundedCornerShape(4.dp))
                                .padding(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "VIP PREMIUM ACTIVE",
                                color = Color.Black,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Black
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Settings items
            SettingsItemRow(
                icon = Icons.Default.Language,
                title = "Language",
                subtitle = if (SecureStorageHelper.getSelectedLanguage(context) == "hi") "हिंदी (Hindi)" else "English",
                onClick = onChangeLanguage
            )
            SettingsItemRow(
                icon = Icons.Default.OndemandVideo,
                title = "Watch Ad to Unlock",
                subtitle = "Coming in Step 3",
                onClick = {
                    Toast.makeText(context, "Step 3 Feature: Watch Ad to Unlock", Toast.LENGTH_SHORT).show()
                }
            )
            SettingsItemRow(
                icon = Icons.Default.Share,
                title = "Share App",
                subtitle = "Invite friends & family",
                onClick = {
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, "Stream movies & cricket on Jio Hotstar Premium! Download: https://jiohotstar.app/download")
                    }
                    context.startActivity(Intent.createChooser(shareIntent, "Share App"))
                }
            )
            SettingsItemRow(
                icon = Icons.Default.SystemUpdate,
                title = "Check for Updates",
                subtitle = "Version 1.0.0 (Latest)",
                onClick = { showUpdateDialog = true }
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Logout row
            SettingsItemRow(
                icon = Icons.Default.Logout,
                iconColor = AccentRed,
                title = "Logout",
                titleColor = AccentRed,
                onClick = {
                    authService.signOut()
                    SecureStorageHelper.clearAdminSession(context)
                    onLogout()
                }
            )

            Spacer(modifier = Modifier.height(36.dp))

            Text(
                text = "Jio Hotstar Premium v1.0.0\nSecure Encrypted Android Core",
                color = TextGrey.copy(alpha = 0.5f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }

    if (showUpdateDialog) {
        AlertDialog(
            onDismissRequest = { showUpdateDialog = false },
            containerColor = DarkSurface,
            title = { Text("Software Update", color = TextWhite, fontWeight = FontWeight.Bold) },
            text = { Text("You are using the latest version of Jio Hotstar Premium (1.0.0).", color = TextGrey) },
            confirmButton = {
                Button(
                    onClick = { showUpdateDialog = false },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun SettingsItemRow(
    icon: ImageVector,
    iconColor: Color = Color.White,
    title: String,
    titleColor: Color = TextWhite,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 10.dp)
            .clickable { onClick() }
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(24.dp))
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(text = title, color = titleColor, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                if (subtitle != null) {
                    Text(text = subtitle, color = TextGrey, fontSize = 12.sp)
                }
            }
            Icon(Icons.AutoMirrored.Filled.ArrowForwardIos, contentDescription = null, tint = TextGrey, modifier = Modifier.size(14.dp))
        }
    }
}
