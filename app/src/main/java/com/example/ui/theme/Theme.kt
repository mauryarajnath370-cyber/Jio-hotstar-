package com.example.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp

private val HotstarDarkColorScheme = darkColorScheme(
    primary = AccentRed,
    onPrimary = TextWhite,
    primaryContainer = AccentRedDark,
    onPrimaryContainer = TextWhite,
    secondary = GoldAccent,
    onSecondary = DarkBackground,
    background = DarkBackground,
    onBackground = TextWhite,
    surface = DarkSurface,
    onSurface = TextWhite,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = TextGrey,
    outline = CardBorder
)

val HotstarShapes = Shapes(
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp)
)

@Composable
fun JioHotstarTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = HotstarDarkColorScheme,
        typography = Typography,
        shapes = HotstarShapes,
        content = content
    )
}
