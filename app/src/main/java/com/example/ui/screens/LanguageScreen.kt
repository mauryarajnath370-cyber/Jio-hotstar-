package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.core.SecureStorageHelper
import com.example.ui.components.JioHotstarLogo
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite

@Composable
fun LanguageScreen(
    onLanguageSelected: () -> Unit
) {
    val context = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(24.dp)
            .testTag("language_screen_container"),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        JioHotstarLogo(size = 32)
        Spacer(modifier = Modifier.height(36.dp))

        Text(
            text = "Choose Language / भाषा चुनें",
            color = TextWhite,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Select your preferred streaming language",
            color = TextGrey,
            fontSize = 14.sp,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(40.dp))

        // Two large cards side by side
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Hindi
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.5.dp, AccentRed.copy(alpha = 0.5f)),
                modifier = Modifier
                    .weight(1f)
                    .clickable {
                        SecureStorageHelper.saveSelectedLanguage(context, "hi")
                        onLanguageSelected()
                    }
                    .testTag("lang_card_hi")
            ) {
                Column(
                    modifier = Modifier.padding(vertical = 28.dp, horizontal = 16.dp).fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "अ",
                        color = AccentRed,
                        fontSize = 44.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "हिन्दी",
                        color = TextWhite,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "फ़िल्में और शो",
                        color = TextGrey,
                        fontSize = 12.sp
                    )
                }
            }

            // English
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                border = BorderStroke(1.5.dp, Color.White.copy(alpha = 0.2f)),
                modifier = Modifier
                    .weight(1f)
                    .clickable {
                        SecureStorageHelper.saveSelectedLanguage(context, "en")
                        onLanguageSelected()
                    }
                    .testTag("lang_card_en")
            ) {
                Column(
                    modifier = Modifier.padding(vertical = 28.dp, horizontal = 16.dp).fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "En",
                        color = TextWhite,
                        fontSize = 44.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = "English",
                        color = TextWhite,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Movies & Series",
                        color = TextGrey,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}
