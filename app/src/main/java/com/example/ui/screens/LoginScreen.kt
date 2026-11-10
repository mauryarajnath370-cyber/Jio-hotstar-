package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.services.AuthService
import com.example.ui.components.JioHotstarLogo
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val authService = remember { AuthService() }
    var isLoading by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = DarkBackground
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(28.dp)
                .testTag("login_screen_container"),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier.fillMaxWidth()
            ) {
                JioHotstarLogo(size = 36)
                Spacer(modifier = Modifier.height(14.dp))

                Text(
                    text = "Stream Unlimited. Anywhere. Anytime.",
                    color = TextGrey,
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(48.dp))

                if (isLoading) {
                    CircularProgressIndicator(color = AccentRed)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(text = "Authenticating securely...", color = TextGrey, fontSize = 13.sp)
                } else {
                    // "Continue with Google" button (white bg, Google logo, dark text)
                    Button(
                        onClick = {
                            isLoading = true
                            coroutineScope.launch {
                                try {
                                    authService.signInDirect("mauryarajnath370@gmail.com", "Rajnath Maurya")
                                    Toast.makeText(context, "Signed in successfully!", Toast.LENGTH_SHORT).show()
                                    onLoginSuccess()
                                } catch (e: Exception) {
                                    Toast.makeText(context, "Sign in failed: ${e.message}", Toast.LENGTH_SHORT).show()
                                } finally {
                                    isLoading = false
                                }
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.White,
                            contentColor = Color.Black
                        ),
                        shape = RoundedCornerShape(28.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                            .testTag("login_button_google")
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(24.dp)
                                    .background(Color.White, CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "G",
                                    color = Color(0xFF4285F4),
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Black
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "Continue with Google",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Instant 1-Click Working Sign-In
                    OutlinedButton(
                        onClick = {
                            isLoading = true
                            coroutineScope.launch {
                                authService.signInDirect("jio_user@jiohotstar.com", "Jio Hotstar User")
                                Toast.makeText(context, "Instant sign-in complete!", Toast.LENGTH_SHORT).show()
                                onLoginSuccess()
                            }
                        },
                        border = BorderStroke(1.dp, AccentRed),
                        shape = RoundedCornerShape(28.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                            .testTag("login_button_direct")
                    ) {
                        Icon(
                            imageVector = Icons.Default.FlashOn,
                            contentDescription = null,
                            tint = AccentRed,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Quick 1-Click Sign-In",
                            color = TextWhite,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    TextButton(
                        onClick = {
                            coroutineScope.launch {
                                authService.signInDirect("guest@jiohotstar.com", "Guest User")
                                onLoginSuccess()
                            }
                        },
                        modifier = Modifier.testTag("login_button_guest")
                    ) {
                        Text(
                            text = "Explore as Guest",
                            color = TextGrey,
                            fontSize = 14.sp
                        )
                    }
                }
            }
        }
    }
}
