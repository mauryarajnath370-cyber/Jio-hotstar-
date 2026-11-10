package com.example.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.models.VideoModel
import com.example.services.DatabaseService
import com.example.ui.components.JioHotstarLogo
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.DarkSurfaceVariant
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToVideo: (VideoModel) -> Unit,
    onNavigateToSearch: () -> Unit,
    onNavigateToPremium: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToAdult: () -> Unit,
    onNavigateToAdmin: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val databaseService = remember { DatabaseService() }

    var selectedNavIndex by remember { mutableIntStateOf(0) }
    var isLoading by remember { mutableStateOf(true) }
    var trendingVideos by remember { mutableStateOf<List<VideoModel>>(emptyList()) }
    var allVideos by remember { mutableStateOf<List<VideoModel>>(emptyList()) }
    var liveEvents by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }
    var sections by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }

    // 5-tap tracker on logo for Admin Panel
    var tapCount by remember { mutableIntStateOf(0) }
    var firstTapTime by remember { mutableStateOf(0L) }

    // Adult Dialog State
    var showSetAdultPasswordDialog by remember { mutableStateOf(false) }
    var showEnterAdultPasswordDialog by remember { mutableStateOf(false) }
    var adultPin1 by remember { mutableStateOf("") }
    var adultPin2 by remember { mutableStateOf("") }
    var adultPinVerify by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        databaseService.seedInitialDataIfEmpty()
        val trending = databaseService.getTrendingVideos(10)
        val videos = databaseService.getVideos(20)
        val live = databaseService.getLiveEvents().filter { event -> event["isActive"] == true || event["isLive"] == true }
        val layout = databaseService.getHomeLayout()

        @Suppress("UNCHECKED_CAST")
        val layoutSections = (layout["sections"] as? List<Map<String, Any?>>) ?: emptyList()

        trendingVideos = if (trending.isNotEmpty()) trending else defaultVideos()
        allVideos = if (videos.isNotEmpty()) videos else defaultVideos()
        liveEvents = live
        sections = layoutSections
        isLoading = false
    }

    fun handleLogoTap() {
        val now = System.currentTimeMillis()
        if (firstTapTime == 0L || now - firstTapTime > 2000L) {
            firstTapTime = now
            tapCount = 1
        } else {
            tapCount++
            if (tapCount >= 5) {
                tapCount = 0
                firstTapTime = 0L
                Toast.makeText(context, "Opening Admin Master Portal...", Toast.LENGTH_SHORT).show()
                onNavigateToAdmin()
            }
        }
    }

    fun handleAdultCardClick() {
        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: "default_user"
        coroutineScope.launch {
            // Check if password exists
            val snap = databaseService.verifyAdultPassword(uid, "")
            // If user has not set password yet
            val hasPass = FirebaseAuth.getInstance().currentUser?.uid?.let {
                // Check if user set pin
                true
            } ?: false

            showEnterAdultPasswordDialog = true
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = {
                    Box(
                        modifier = Modifier
                            .clickable { handleLogoTap() }
                            .padding(vertical = 4.dp)
                            .testTag("home_logo_clickable")
                    ) {
                        JioHotstarLogo(size = 20)
                    }
                },
                actions = {
                    IconButton(onClick = onNavigateToSearch) {
                        Icon(Icons.Default.Search, contentDescription = "Search", tint = TextWhite)
                    }
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings", tint = TextWhite)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkSurface)
            )
        },
        bottomBar = {
            NavigationBar(
                containerColor = DarkSurface,
                modifier = Modifier.testTag("home_bottom_bar")
            ) {
                NavigationBarItem(
                    selected = selectedNavIndex == 0,
                    onClick = { selectedNavIndex = 0 },
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Home", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = AccentRed,
                        selectedTextColor = AccentRed,
                        indicatorColor = DarkSurfaceVariant
                    )
                )
                NavigationBarItem(
                    selected = selectedNavIndex == 1,
                    onClick = {
                        selectedNavIndex = 1
                        onNavigateToSearch()
                    },
                    icon = { Icon(Icons.Default.Search, contentDescription = "Search") },
                    label = { Text("Search", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = AccentRed,
                        selectedTextColor = AccentRed,
                        indicatorColor = DarkSurfaceVariant
                    )
                )
                NavigationBarItem(
                    selected = selectedNavIndex == 2,
                    onClick = {
                        selectedNavIndex = 2
                        onNavigateToPremium()
                    },
                    icon = { Icon(Icons.Default.Star, contentDescription = "Premium") },
                    label = { Text("Premium", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = AccentRed,
                        selectedTextColor = AccentRed,
                        indicatorColor = DarkSurfaceVariant
                    )
                )
                NavigationBarItem(
                    selected = selectedNavIndex == 3,
                    onClick = {
                        selectedNavIndex = 3
                        onNavigateToSettings()
                    },
                    icon = { Icon(Icons.Default.Settings, contentDescription = "Settings") },
                    label = { Text("Settings", fontSize = 11.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = AccentRed,
                        selectedTextColor = AccentRed,
                        indicatorColor = DarkSurfaceVariant
                    )
                )
            }
        }
    ) { innerPadding ->
        if (isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = AccentRed)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
                    .padding(bottom = 24.dp)
            ) {
                // Live Stream Banner if active
                if (liveEvents.isNotEmpty()) {
                    val live = liveEvents.first()
                    val liveVideo = VideoModel(
                        id = live["id"]?.toString() ?: "live_1",
                        title = live["title"]?.toString() ?: "Live Cricket Match",
                        cdnUrl = live["streamUrl"]?.toString() ?: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                        thumbnailUrl = live["bannerUrl"]?.toString() ?: "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800",
                        description = "Watch live stream on Jio Hotstar Premium",
                        categoryId = "live",
                        isPaid = live["isPremium"] as? Boolean ?: false,
                        isLive = true,
                        views = 125000L
                    )
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                            .clickable { onNavigateToVideo(liveVideo) },
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(70.dp, 44.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(DarkSurfaceVariant)
                            ) {
                                AsyncImage(
                                    model = liveVideo.thumbnailUrl,
                                    contentDescription = null,
                                    modifier = Modifier.fillMaxSize(),
                                    contentScale = ContentScale.Crop
                                )
                                Box(
                                    modifier = Modifier
                                        .padding(3.dp)
                                        .background(AccentRed, RoundedCornerShape(3.dp))
                                        .padding(horizontal = 4.dp, vertical = 1.dp)
                                ) {
                                    Text("LIVE", color = Color.White, fontSize = 8.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = liveVideo.title,
                                    color = TextWhite,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = "${live["channelName"] ?: "Live"} • High Definition",
                                    color = TextGrey,
                                    fontSize = 11.sp
                                )
                            }
                            Button(
                                onClick = { onNavigateToVideo(liveVideo) },
                                colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
                                shape = RoundedCornerShape(16.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Text("Watch", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                }

                // Carousel Hero Banner (Auto-scrolling every 4s)
                val heroVideo = trendingVideos.firstOrNull() ?: defaultVideos().first()
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(220.dp)
                        .clickable { onNavigateToVideo(heroVideo) }
                        .testTag("hero_carousel_slide")
                ) {
                    AsyncImage(
                        model = heroVideo.thumbnailUrl,
                        contentDescription = heroVideo.title,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        Color(0x800F0F0F),
                                        DarkBackground
                                    )
                                )
                            )
                    )
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .padding(16.dp)
                            .fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            if (heroVideo.isPaid) {
                                Box(
                                    modifier = Modifier
                                        .background(GoldAccent, RoundedCornerShape(4.dp))
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = "PREMIUM",
                                        color = Color.Black,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Black
                                    )
                                }
                                Spacer(modifier = Modifier.height(4.dp))
                            }
                            Text(
                                text = heroVideo.title,
                                color = TextWhite,
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Button(
                            onClick = { onNavigateToVideo(heroVideo) },
                            colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
                            shape = RoundedCornerShape(20.dp)
                        ) {
                            Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(text = "Play Now", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Trending Row
                VideoHorizontalSection(
                    title = "Trending Now",
                    videos = trendingVideos,
                    onSeeAll = onNavigateToSearch,
                    onVideoClick = onNavigateToVideo
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Movies Row
                VideoHorizontalSection(
                    title = "Blockbuster Movies",
                    videos = allVideos,
                    onSeeAll = onNavigateToSearch,
                    onVideoClick = onNavigateToVideo
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Adult 18+ Content Card
                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                        .height(100.dp)
                        .clickable { handleAdultCardClick() }
                        .testTag("adult_content_card")
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.horizontalGradient(
                                    colors = listOf(
                                        Color(0xFF8B0000),
                                        Color(0xFF1A0000),
                                        DarkBackground
                                    )
                                )
                            )
                            .padding(horizontal = 20.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column {
                                Text(
                                    text = "🔞 Adult Content",
                                    color = TextWhite,
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "PIN Protected • 18+ Only",
                                    color = Color.White.copy(alpha = 0.7f),
                                    fontSize = 12.sp
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .background(Color.Black.copy(alpha = 0.4f), CircleShape),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Lock,
                                    contentDescription = "Protected",
                                    tint = AccentRed,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Enter Adult Password Dialog
    if (showEnterAdultPasswordDialog) {
        AlertDialog(
            onDismissRequest = { showEnterAdultPasswordDialog = false },
            containerColor = DarkSurface,
            title = {
                Text(text = "Enter Adult PIN / Password", color = TextWhite, fontWeight = FontWeight.Bold)
            },
            text = {
                Column {
                    Text(text = "Enter your secret access code or default PIN (1234)", color = TextGrey, fontSize = 13.sp)
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = adultPinVerify,
                        onValueChange = { adultPinVerify = it },
                        label = { Text("Access Code") },
                        visualTransformation = PasswordVisualTransformation(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = TextWhite,
                            unfocusedTextColor = TextWhite,
                            focusedBorderColor = AccentRed,
                            unfocusedBorderColor = TextGrey
                        ),
                        modifier = Modifier.fillMaxWidth().testTag("adult_pin_field")
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: "default_user"
                        coroutineScope.launch {
                            val ok = databaseService.verifyAdultPassword(uid, adultPinVerify) || adultPinVerify == "1234"
                            if (ok) {
                                showEnterAdultPasswordDialog = false
                                onNavigateToAdult()
                            } else {
                                Toast.makeText(context, "Wrong PIN/Password. Default is 1234", Toast.LENGTH_SHORT).show()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("Unlock")
                }
            },
            dismissButton = {
                TextButton(onClick = { showEnterAdultPasswordDialog = false }) {
                    Text("Cancel", color = TextGrey)
                }
            }
        )
    }
}

@Composable
fun VideoHorizontalSection(
    title: String,
    videos: List<VideoModel>,
    onSeeAll: () -> Unit,
    onVideoClick: (VideoModel) -> Unit
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = title,
                color = TextWhite,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "See All >",
                color = AccentRed,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { onSeeAll() }
            )
        }

        LazyRow(
            modifier = Modifier.padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(videos) { video ->
                VideoCardItem(video = video, onClick = { onVideoClick(video) })
            }
        }
    }
}

@Composable
fun VideoCardItem(
    video: VideoModel,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(130.dp)
            .clickable { onClick() }
            .testTag("video_card_${video.id}")
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .clip(RoundedCornerShape(8.dp))
                .background(DarkSurfaceVariant)
        ) {
            AsyncImage(
                model = video.thumbnailUrl,
                contentDescription = video.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
            if (video.isPaid) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(6.dp)
                        .background(GoldAccent, RoundedCornerShape(4.dp))
                        .padding(horizontal = 5.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "PREMIUM",
                        color = Color.Black,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.ExtraBold
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = video.title,
            color = TextWhite,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

private fun defaultVideos(): List<VideoModel> {
    return listOf(
        VideoModel(
            id = "vid_1",
            title = "ICC Cricket World Cup 2026: Live Final",
            thumbnailUrl = "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=600",
            cdnUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            isPaid = true,
            isTrending = true,
            views = 142000
        ),
        VideoModel(
            id = "vid_2",
            title = "Action Thriller: The Special Ops Season 3",
            thumbnailUrl = "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600",
            cdnUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            isPaid = false,
            isTrending = true,
            views = 89000
        ),
        VideoModel(
            id = "vid_3",
            title = "Jio Cinema Superhit: Romantic Comedy",
            thumbnailUrl = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600",
            cdnUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            isPaid = true,
            views = 56000
        )
    )
}
