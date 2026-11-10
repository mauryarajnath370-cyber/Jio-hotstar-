package com.example.ui.screens

import android.content.Intent
import android.net.Uri
import android.widget.MediaController
import android.widget.Toast
import android.widget.VideoView
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material.icons.filled.Fullscreen
import androidx.compose.material.icons.filled.PauseCircle
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import coil.compose.AsyncImage
import com.example.core.SecureStorageHelper
import com.example.models.VideoModel
import com.example.services.AdService
import com.example.services.DatabaseService
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.DarkSurfaceVariant
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun VideoPlayerScreen(
    video: VideoModel,
    onBack: () -> Unit,
    onVideoSelected: (VideoModel) -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val adService = remember { AdService() }
    val databaseService = remember { DatabaseService() }

    var isPlaying by remember { mutableStateOf(true) }
    var showDescription by remember { mutableStateOf(false) }
    var playbackProgress by remember { mutableFloatStateOf(0.35f) }
    var playbackSpeed by remember { mutableFloatStateOf(1.0f) }
    var showSpeedMenu by remember { mutableStateOf(false) }
    var isSavedToWatchLater by remember { mutableStateOf(SecureStorageHelper.getWatchLaterIds(context).contains(video.id)) }
    var moreVideos by remember { mutableStateOf<List<VideoModel>>(emptyList()) }

    // Ad Flow State
    var showAdDialog by remember { mutableStateOf(false) }
    var adLink by remember { mutableStateOf("") }
    var adTimerRemaining by remember { mutableIntStateOf(5) }
    var adCountdownActive by remember { mutableStateOf(false) }
    var showChatSheet by remember { mutableStateOf(false) }

    LaunchedEffect(video.id) {
        val list = databaseService.getVideosByCategory(video.categoryId, limit = 10, excludeId = video.id)
        moreVideos = list

        val adSettings = databaseService.getAdSettings()
        val adsEnabled = adSettings["adsEnabled"] as? Boolean ?: true
        val normalAd = adService.getNormalAdLink()
        val timerSeconds = adService.getAdTimerSeconds()

        if (adsEnabled && normalAd.isNotEmpty()) {
            adLink = normalAd
            adTimerRemaining = timerSeconds
            showAdDialog = true
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showChatSheet = true },
                containerColor = DarkSurface,
                contentColor = AccentRed,
                modifier = Modifier.testTag("player_live_chat_fab")
            ) {
                Icon(Icons.Default.ChatBubbleOutline, contentDescription = "Live Chat")
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Video Player 16:9 Viewport
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .background(Color.Black)
            ) {
                AsyncImage(
                    model = video.thumbnailUrl,
                    contentDescription = video.title,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )

                // Native Android VideoView integration
                AndroidView(
                    factory = { ctx ->
                        VideoView(ctx).apply {
                            setVideoURI(Uri.parse(video.cdnUrl))
                            setOnPreparedListener { mp ->
                                mp.isLooping = true
                                start()
                            }
                        }
                    },
                    modifier = Modifier.fillMaxSize()
                )

                // Interactive Controls Overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.35f))
                ) {
                    // Top row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = Color.White)
                        }
                        Row {
                            Box {
                                IconButton(onClick = { showSpeedMenu = true }) {
                                    Icon(Icons.Default.Speed, contentDescription = "Speed", tint = Color.White)
                                }
                                DropdownMenu(
                                    expanded = showSpeedMenu,
                                    onDismissRequest = { showSpeedMenu = false },
                                    modifier = Modifier.background(DarkSurface)
                                ) {
                                    listOf(0.5f, 1.0f, 1.5f, 2.0f).forEach { speed ->
                                        DropdownMenuItem(
                                            text = { Text("${speed}x", color = TextWhite) },
                                            onClick = {
                                                playbackSpeed = speed
                                                showSpeedMenu = false
                                                Toast.makeText(context, "Speed: ${speed}x", Toast.LENGTH_SHORT).show()
                                            }
                                        )
                                    }
                                }
                            }
                            IconButton(onClick = {
                                Toast.makeText(context, "Fullscreen activated", Toast.LENGTH_SHORT).show()
                            }) {
                                Icon(Icons.Default.Fullscreen, contentDescription = "Fullscreen", tint = Color.White)
                            }
                        }
                    }

                    // Center play/rewind controls
                    Row(
                        modifier = Modifier.align(Alignment.Center),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(28.dp)
                    ) {
                        IconButton(onClick = {
                            playbackProgress = (playbackProgress - 0.05f).coerceAtLeast(0.0f)
                        }) {
                            Icon(Icons.Default.Replay10, contentDescription = "10s Back", tint = Color.White, modifier = Modifier.size(36.dp))
                        }
                        IconButton(
                            onClick = { isPlaying = !isPlaying },
                            modifier = Modifier.size(54.dp)
                        ) {
                            Icon(
                                imageVector = if (isPlaying) Icons.Default.PauseCircle else Icons.Default.PlayCircle,
                                contentDescription = if (isPlaying) "Pause" else "Play",
                                tint = AccentRed,
                                modifier = Modifier.size(54.dp)
                            )
                        }
                        IconButton(onClick = {
                            playbackProgress = (playbackProgress + 0.05f).coerceAtMost(1.0f)
                        }) {
                            Icon(Icons.Default.Forward10, contentDescription = "10s Forward", tint = Color.White, modifier = Modifier.size(36.dp))
                        }
                    }

                    // Bottom progress slider
                    Slider(
                        value = playbackProgress,
                        onValueChange = { playbackProgress = it },
                        colors = SliderDefaults.colors(
                            thumbColor = AccentRed,
                            activeTrackColor = AccentRed,
                            inactiveTrackColor = Color.White.copy(alpha = 0.3f)
                        ),
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 4.dp)
                    )
                }
            }

            // Scrollable Details
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                item {
                    Text(
                        text = video.title,
                        color = TextWhite,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "${video.views} views • Today • HD",
                        color = TextGrey,
                        fontSize = 13.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    // Action Row
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        PlayerActionButton(
                            icon = if (isSavedToWatchLater) Icons.Default.Bookmark else Icons.Default.BookmarkBorder,
                            color = if (isSavedToWatchLater) AccentRed else Color.White,
                            label = "Watch Later",
                            onClick = {
                                val added = SecureStorageHelper.toggleWatchLater(context, video.id)
                                isSavedToWatchLater = added
                                Toast.makeText(context, if (added) "Saved to Watch Later" else "Removed", Toast.LENGTH_SHORT).show()
                            }
                        )
                        PlayerActionButton(
                            icon = Icons.Default.Share,
                            color = Color.White,
                            label = "Share",
                            onClick = {
                                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, "Watch \"${video.title}\" on Jio Hotstar Premium! Download: https://jiohotstar.app/download")
                                }
                                context.startActivity(Intent.createChooser(shareIntent, "Share Video"))
                            }
                        )
                        PlayerActionButton(
                            icon = Icons.Default.Download,
                            color = Color.White,
                            label = "Download",
                            onClick = {
                                Toast.makeText(context, "Encrypted offline download active (7-day validity)", Toast.LENGTH_LONG).show()
                            }
                        )
                        PlayerActionButton(
                            icon = Icons.Default.Flag,
                            color = Color.White,
                            label = "Report",
                            onClick = {
                                Toast.makeText(context, "Issue flagged for Jio Hotstar moderators", Toast.LENGTH_SHORT).show()
                            }
                        )
                    }

                    HorizontalDivider(color = Color(0xFF2B2B2B), modifier = Modifier.padding(vertical = 16.dp))

                    if (video.description.isNotEmpty()) {
                        Text(
                            text = video.description,
                            color = TextGrey,
                            fontSize = 13.sp,
                            maxLines = if (showDescription) Int.MAX_VALUE else 2,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = if (showDescription) "Show less" else "Show more",
                            color = AccentRed,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .clickable { showDescription = !showDescription }
                                .padding(vertical = 4.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    Text(
                        text = "More from this category",
                        color = TextWhite,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                }

                items(moreVideos) { item ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp)
                            .clickable { onVideoSelected(item) },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .width(120.dp)
                                .height(68.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(DarkSurfaceVariant)
                        ) {
                            AsyncImage(
                                model = item.thumbnailUrl,
                                contentDescription = item.title,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = item.title,
                                color = TextWhite,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "${item.views} views",
                                color = TextGrey,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }

    // Sponsored Link Dialog
    if (showAdDialog) {
        AlertDialog(
            onDismissRequest = {},
            containerColor = DarkSurface,
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Campaign, contentDescription = null, tint = AccentRed)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(text = "Sponsored Link", color = TextWhite, fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column {
                    Text(
                        text = "Click Continue to open the sponsored sponsor link, then come back to watch in HD.",
                        color = TextGrey,
                        fontSize = 14.sp
                    )
                    if (adCountdownActive) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(color = AccentRed, modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = if (adTimerRemaining > 0) "Please wait ${adTimerRemaining}s..." else "Ready to stream!",
                                color = TextWhite,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            },
            confirmButton = {
                if (!adCountdownActive) {
                    Button(
                        onClick = {
                            adCountdownActive = true
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(adLink))
                                context.startActivity(intent)
                            } catch (_: Exception) {}

                            coroutineScope.launch {
                                while (adTimerRemaining > 0) {
                                    delay(1000)
                                    adTimerRemaining--
                                }
                                showAdDialog = false
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                    ) {
                        Text("Continue")
                    }
                }
            }
        )
    }

    // Live Chat Sheet Placeholder
    if (showChatSheet) {
        AlertDialog(
            onDismissRequest = { showChatSheet = false },
            containerColor = DarkSurface,
            title = {
                Text(text = "Live Interactive Chat", color = TextWhite, fontWeight = FontWeight.Bold)
            },
            text = {
                Text(text = "P2P Interactive Live Chat will be fully activated in Step 3.", color = TextGrey)
            },
            confirmButton = {
                Button(
                    onClick = { showChatSheet = false },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("OK")
                }
            }
        )
    }
}

@Composable
fun PlayerActionButton(
    icon: ImageVector,
    color: Color,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable { onClick() }
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Icon(imageVector = icon, contentDescription = label, tint = color, modifier = Modifier.size(22.dp))
        Spacer(modifier = Modifier.height(4.dp))
        Text(text = label, color = TextGrey, fontSize = 11.sp)
    }
}
