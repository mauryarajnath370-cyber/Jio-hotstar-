package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.AccentRed
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.TextWhite

@Composable
fun JioHotstarLogo(
    modifier: Modifier = Modifier,
    size: Int = 24,
    showBadge: Boolean = true
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Jio",
                fontSize = size.sp,
                fontWeight = FontWeight.Bold,
                color = TextWhite,
                letterSpacing = 0.5.sp
            )
            Text(
                text = "Hotstar",
                fontSize = size.sp,
                fontWeight = FontWeight.Bold,
                color = AccentRed,
                letterSpacing = 0.5.sp
            )
        }
        if (showBadge) {
            Spacer(modifier = Modifier.height(2.dp))
            Box(
                modifier = Modifier
                    .background(
                        brush = Brush.horizontalGradient(
                            colors = listOf(GoldAccent, Color(0xFFFFA500))
                        ),
                        shape = RoundedCornerShape(10.dp)
                    )
                    .padding(horizontal = 6.dp, vertical = 1.dp)
            ) {
                Text(
                    text = "PREMIUM",
                    fontSize = (size * 0.32).sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = Color.Black,
                    letterSpacing = 1.2.sp
                )
            }
        }
    }
}
