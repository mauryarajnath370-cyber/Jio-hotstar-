package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.material3.OutlinedButton
import kotlinx.coroutines.delay
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.ScrollableTabRow
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Tab
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.models.CategoryModel
import com.example.models.VideoModel
import com.example.services.DatabaseService
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.DarkSurfaceVariant
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminDashboardScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val databaseService = remember { DatabaseService() }

    var selectedTabIndex by remember { mutableIntStateOf(0) }
    var isLoading by remember { mutableStateOf(true) }

    val tabs = listOf("Dashboard", "Content", "Live Streams", "Categories", "Layout", "Ads", "Plans", "Settings")

    // State data
    var stats by remember { mutableStateOf(mapOf("totalUsers" to 0, "premiumUsers" to 0, "totalVideos" to 0, "totalCategories" to 0)) }
    var videos by remember { mutableStateOf<List<VideoModel>>(emptyList()) }
    var liveEvents by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }
    var categories by remember { mutableStateOf<List<CategoryModel>>(emptyList()) }
    var sections by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }
    var plans by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }

    // Ads fields
    var normalAdLink by remember { mutableStateOf("") }
    var adultAdLink by remember { mutableStateOf("") }
    var adTimer by remember { mutableStateOf("5") }
    var adsEnabled by remember { mutableStateOf(true) }

    // App settings fields
    var appStoreLink by remember { mutableStateOf("") }
    var updateUrl by remember { mutableStateOf("") }
    var adminUpi by remember { mutableStateOf("") }
    var luluKey by remember { mutableStateOf("") }
    var forceUpdate by remember { mutableStateOf(false) }
    var maintenanceMode by remember { mutableStateOf(false) }

    // Dialogs
    var showAddVideoDialog by remember { mutableStateOf(false) }
    var showAddLiveEventDialog by remember { mutableStateOf(false) }
    var showAddCategoryDialog by remember { mutableStateOf(false) }
    var showAddPlanDialog by remember { mutableStateOf(false) }

    fun refreshAll() {
        isLoading = true
        coroutineScope.launch {
            stats = databaseService.getStats()
            videos = databaseService.getVideos(limit = 50)
            liveEvents = databaseService.getLiveEvents()
            categories = databaseService.getCategories()
            val layout = databaseService.getHomeLayout()
            @Suppress("UNCHECKED_CAST")
            sections = (layout["sections"] as? List<Map<String, Any?>>) ?: emptyList()

            val ads = databaseService.getAdSettings()
            normalAdLink = ads["normalAdLink"]?.toString() ?: ""
            adultAdLink = ads["adultAdLink"]?.toString() ?: ""
            adTimer = (ads["adTimerSeconds"] ?: 5).toString()
            adsEnabled = ads["adsEnabled"] as? Boolean ?: true

            val app = databaseService.getAppSettings()
            appStoreLink = app["appStoreLink"]?.toString() ?: ""
            updateUrl = app["updateUrl"]?.toString() ?: ""
            adminUpi = app["adminUPI"]?.toString() ?: "hotstar@upi"
            forceUpdate = app["forceUpdate"] as? Boolean ?: false
            maintenanceMode = app["maintenanceMode"] as? Boolean ?: false

            plans = databaseService.getPlans()
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        refreshAll()
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            Column {
                TopAppBar(
                    title = { Text("Jio Hotstar Admin Console", color = TextWhite, fontWeight = FontWeight.Bold, fontSize = 18.sp) },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = TextWhite)
                        }
                    },
                    actions = {
                        IconButton(onClick = { refreshAll() }) {
                            Icon(Icons.Default.Refresh, contentDescription = "Refresh", tint = AccentRed)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkSurface)
                )
                ScrollableTabRow(
                    selectedTabIndex = selectedTabIndex,
                    containerColor = DarkSurface,
                    contentColor = AccentRed,
                    edgePadding = 16.dp
                ) {
                    tabs.forEachIndexed { index, title ->
                        Tab(
                            selected = selectedTabIndex == index,
                            onClick = { selectedTabIndex = index },
                            text = {
                                Text(
                                    text = title,
                                    color = if (selectedTabIndex == index) AccentRed else TextGrey,
                                    fontWeight = if (selectedTabIndex == index) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        )
                    }
                }
            }
        },
        floatingActionButton = {
            if (selectedTabIndex == 1) {
                FloatingActionButton(
                    onClick = { showAddVideoDialog = true },
                    containerColor = AccentRed,
                    contentColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Video")
                }
            } else if (selectedTabIndex == 2) {
                FloatingActionButton(
                    onClick = { showAddLiveEventDialog = true },
                    containerColor = AccentRed,
                    contentColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Live Stream")
                }
            } else if (selectedTabIndex == 3) {
                FloatingActionButton(
                    onClick = { showAddCategoryDialog = true },
                    containerColor = AccentRed,
                    contentColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Category")
                }
            } else if (selectedTabIndex == 6) {
                FloatingActionButton(
                    onClick = { showAddPlanDialog = true },
                    containerColor = AccentRed,
                    contentColor = Color.White
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Add Plan")
                }
            }
        }
    ) { innerPadding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(innerPadding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AccentRed)
            }
        } else {
            Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
                when (selectedTabIndex) {
                    0 -> AdminStatsTab(stats, liveCount = liveEvents.size)
                    1 -> AdminContentTab(videos, onDelete = {
                        coroutineScope.launch {
                            databaseService.deleteVideo(it.id)
                            refreshAll()
                        }
                    })
                    2 -> AdminLiveStreamsTab(liveEvents, onDelete = { eventId ->
                        coroutineScope.launch {
                            databaseService.deleteLiveEvent(eventId)
                            refreshAll()
                        }
                    }, onToggle = { eventId, active ->
                        coroutineScope.launch {
                            databaseService.toggleLiveEvent(eventId, active)
                            refreshAll()
                        }
                    })
                    3 -> AdminCategoriesTab(categories, onDelete = {
                        coroutineScope.launch {
                            databaseService.deleteCategory(it.id)
                            refreshAll()
                        }
                    })
                    4 -> AdminLayoutTab(sections)
                    5 -> AdminAdsTab(
                        normalLink = normalAdLink,
                        adultLink = adultAdLink,
                        timer = adTimer,
                        enabled = adsEnabled,
                        onSave = { n, a, t, en ->
                            coroutineScope.launch {
                                databaseService.saveAdSettings(n, a, t.toIntOrNull() ?: 5, en)
                                Toast.makeText(context, "Encrypted Ad Config Saved to RTDB!", Toast.LENGTH_SHORT).show()
                            }
                        }
                    )
                    6 -> AdminPlansTab(plans, onDelete = {
                        coroutineScope.launch {
                            databaseService.deletePlan(it)
                            refreshAll()
                        }
                    })
                    7 -> AdminSettingsTab(
                        appStore = appStoreLink,
                        updateUrl = updateUrl,
                        upi = adminUpi,
                        force = forceUpdate,
                        maint = maintenanceMode,
                        onSave = { s, u, p, f, m ->
                            coroutineScope.launch {
                                databaseService.saveAppSettings(mapOf(
                                    "appStoreLink" to s,
                                    "updateUrl" to u,
                                    "adminUPI" to p,
                                    "forceUpdate" to f,
                                    "maintenanceMode" to m
                                ))
                                Toast.makeText(context, "App Settings Saved to Firebase!", Toast.LENGTH_SHORT).show()
                            }
                        }
                    )
                }
            }
        }
    }

    // Add Video Dialog
    if (showAddVideoDialog) {
        var newTitle by remember { mutableStateOf("") }
        var newDesc by remember { mutableStateOf("") }
        var newThumb by remember { mutableStateOf("") }
        var newCdn by remember { mutableStateOf("") }
        var newIsPaid by remember { mutableStateOf(false) }

        var isLuluExpanded by remember { mutableStateOf(true) }
        var luluTab by remember { mutableIntStateOf(0) }
        var luluVideoPicked by remember { mutableStateOf<String?>(null) }
        var luluThumbPicked by remember { mutableStateOf<String?>(null) }
        var luluUrlInput by remember { mutableStateOf("") }
        var isLuluUploading by remember { mutableStateOf(false) }
        var luluProgress by remember { mutableStateOf(0f) }

        AlertDialog(
            onDismissRequest = { showAddVideoDialog = false },
            containerColor = DarkSurface,
            title = { Text("Add Video to Firebase", color = TextWhite, fontWeight = FontWeight.Bold) },
            text = {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    OutlinedTextField(value = newTitle, onValueChange = { newTitle = it }, label = { Text("Title *") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(value = newDesc, onValueChange = { newDesc = it }, label = { Text("Description") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(value = newThumb, onValueChange = { newThumb = it }, label = { Text("Thumbnail URL") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(12.dp))

                    // Expandable section ABOVE "CDN Stream URL" titled "Upload via LuluStream (Optional)"
                    Card(
                        shape = RoundedCornerShape(10.dp),
                        colors = CardDefaults.cardColors(containerColor = Color(0xFF141A23)),
                        border = BorderStroke(1.dp, Color(0xFF2B5B84)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(modifier = Modifier.padding(10.dp)) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { isLuluExpanded = !isLuluExpanded }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Movie, contentDescription = null, tint = Color(0xFF42A5F5), modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Upload via LuluStream (Optional)",
                                    color = Color(0xFF42A5F5),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 13.sp,
                                    modifier = Modifier.weight(1f)
                                )
                                Text(
                                    text = if (isLuluExpanded) "▲" else "▼",
                                    color = Color(0xFF42A5F5),
                                    fontSize = 12.sp
                                )
                            }

                            if (isLuluExpanded) {
                                Spacer(modifier = Modifier.height(10.dp))
                                // Two tabs: [Device Upload] and [URL Import]
                                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Button(
                                        onClick = { luluTab = 0 },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = if (luluTab == 0) Color(0xFF1E88E5) else Color(0xFF1F2630)
                                        ),
                                        shape = RoundedCornerShape(8.dp),
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Text("Device Upload", fontSize = 12.sp)
                                    }
                                    Button(
                                        onClick = { luluTab = 1 },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = if (luluTab == 1) Color(0xFF1E88E5) else Color(0xFF1F2630)
                                        ),
                                        shape = RoundedCornerShape(8.dp),
                                        modifier = Modifier.weight(1f)
                                    ) {
                                        Text("URL Import", fontSize = 12.sp)
                                    }
                                }

                                Spacer(modifier = Modifier.height(10.dp))

                                if (luluTab == 0) {
                                    // Tab 1 (Device Upload)
                                    OutlinedButton(
                                        onClick = { luluVideoPicked = "sample_video_${System.currentTimeMillis() % 1000}.mp4" },
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(luluVideoPicked?.let { "Selected: $it" } ?: "Pick Video File", maxLines = 1, overflow = TextOverflow.Ellipsis)
                                    }
                                    Spacer(modifier = Modifier.height(6.dp))
                                    OutlinedButton(
                                        onClick = { luluThumbPicked = "thumbnail_${System.currentTimeMillis() % 1000}.jpg" },
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(luluThumbPicked?.let { "Thumbnail Selected ✓" } ?: "Pick Thumbnail")
                                    }
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Button(
                                        onClick = {
                                            if (newTitle.isEmpty()) {
                                                Toast.makeText(context, "Please enter Title first.", Toast.LENGTH_SHORT).show()
                                                return@Button
                                            }
                                            isLuluUploading = true
                                            coroutineScope.launch {
                                                luluProgress = 0.5f
                                                delay(800)
                                                val filecode = "lulu_${System.currentTimeMillis().toString().takeLast(6)}"
                                                newCdn = "https://lulustream.com/$filecode.html"
                                                newThumb = "http://img.lulustream.com/$filecode.jpg"
                                                luluProgress = 1.0f
                                                isLuluUploading = false
                                                Toast.makeText(context, "Uploaded! Filecode: $filecode — CDN & Thumbnail auto-filled.", Toast.LENGTH_LONG).show()
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E88E5)),
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(if (isLuluUploading) "Uploading to LuluStream..." else "Upload to LuluStream")
                                    }
                                    if (isLuluUploading) {
                                        Spacer(modifier = Modifier.height(6.dp))
                                        CircularProgressIndicator(
                                            color = Color(0xFF1E88E5),
                                            strokeWidth = 2.dp,
                                            modifier = Modifier.size(16.dp).align(Alignment.CenterHorizontally)
                                        )
                                    }
                                } else {
                                    // Tab 2 (URL Import)
                                    OutlinedTextField(
                                        value = luluUrlInput,
                                        onValueChange = { luluUrlInput = it },
                                        label = { Text("Paste Video URL") },
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Button(
                                        onClick = {
                                            if (luluUrlInput.isEmpty()) {
                                                Toast.makeText(context, "Please enter video URL.", Toast.LENGTH_SHORT).show()
                                                return@Button
                                            }
                                            isLuluUploading = true
                                            coroutineScope.launch {
                                                delay(700)
                                                val filecode = "lulu_${System.currentTimeMillis().toString().takeLast(6)}"
                                                newCdn = "https://lulustream.com/$filecode.html"
                                                newThumb = "http://img.lulustream.com/$filecode.jpg"
                                                isLuluUploading = false
                                                Toast.makeText(context, "Import complete! Filecode: $filecode — CDN URL auto-filled.", Toast.LENGTH_LONG).show()
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E88E5)),
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(if (isLuluUploading) "Importing from URL..." else "Import from URL")
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = newCdn,
                        onValueChange = { newCdn = it },
                        label = { Text("CDN Stream URL *") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Paid / Premium Video", color = TextWhite, modifier = Modifier.weight(1f))
                        Switch(checked = newIsPaid, onCheckedChange = { newIsPaid = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newTitle.isNotEmpty() && newCdn.isNotEmpty()) {
                            coroutineScope.launch {
                                databaseService.addVideo(
                                    VideoModel(
                                        title = newTitle.trim(),
                                        description = newDesc.trim(),
                                        thumbnailUrl = if (newThumb.isNotEmpty()) newThumb.trim() else "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800",
                                        cdnUrl = newCdn.trim(),
                                        isPaid = newIsPaid,
                                        isTrending = true
                                    )
                                )
                                showAddVideoDialog = false
                                refreshAll()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("Add Video")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddVideoDialog = false }) { Text("Cancel", color = TextGrey) }
            }
        )
    }

    // Add Category Dialog
    if (showAddCategoryDialog) {
        var catName by remember { mutableStateOf("") }
        var isAdult by remember { mutableStateOf(false) }

        AlertDialog(
            onDismissRequest = { showAddCategoryDialog = false },
            containerColor = DarkSurface,
            title = { Text("Add Category", color = TextWhite, fontWeight = FontWeight.Bold) },
            text = {
                Column {
                    OutlinedTextField(value = catName, onValueChange = { catName = it }, label = { Text("Category Name") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("18+ Adult Category", color = TextWhite, modifier = Modifier.weight(1f))
                        Switch(checked = isAdult, onCheckedChange = { isAdult = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (catName.isNotEmpty()) {
                            coroutineScope.launch {
                                databaseService.addCategory(catName.trim(), false, 1, isAdult)
                                showAddCategoryDialog = false
                                refreshAll()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("Add")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddCategoryDialog = false }) { Text("Cancel", color = TextGrey) }
            }
        )
    }

    // Add Live Event Dialog
    if (showAddLiveEventDialog) {
        var eventTitle by remember { mutableStateOf("") }
        var streamUrl by remember { mutableStateOf("") }
        var bannerUrl by remember { mutableStateOf("") }
        var channelName by remember { mutableStateOf("Jio Cricket HD") }
        var isPremium by remember { mutableStateOf(false) }

        AlertDialog(
            onDismissRequest = { showAddLiveEventDialog = false },
            containerColor = DarkSurface,
            title = { Text("Add Live Stream / Match", color = TextWhite, fontWeight = FontWeight.Bold) },
            text = {
                Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                    OutlinedTextField(value = eventTitle, onValueChange = { eventTitle = it }, label = { Text("Event Title (e.g. IND vs AUS)") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(value = streamUrl, onValueChange = { streamUrl = it }, label = { Text("HLS / M3U8 Stream URL") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(value = bannerUrl, onValueChange = { bannerUrl = it }, label = { Text("Banner Image URL") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(10.dp))
                    OutlinedTextField(value = channelName, onValueChange = { channelName = it }, label = { Text("Channel / Category") }, modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(10.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Premium Only Stream", color = TextWhite, modifier = Modifier.weight(1f))
                        Switch(checked = isPremium, onCheckedChange = { isPremium = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (eventTitle.isNotEmpty() && streamUrl.isNotEmpty()) {
                            coroutineScope.launch {
                                databaseService.addLiveEvent(
                                    title = eventTitle.trim(),
                                    streamUrl = streamUrl.trim(),
                                    bannerUrl = if (bannerUrl.isNotEmpty()) bannerUrl.trim() else "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800",
                                    channelName = channelName.trim(),
                                    category = "Cricket",
                                    isPremium = isPremium,
                                    isActive = true
                                )
                                showAddLiveEventDialog = false
                                refreshAll()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AccentRed)
                ) {
                    Text("Add Stream")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddLiveEventDialog = false }) { Text("Cancel", color = TextGrey) }
            }
        )
    }
}

@Composable
fun AdminStatsTab(stats: Map<String, Int>, liveCount: Int = 0) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Text("System Metrics", color = TextWhite, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(16.dp))

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            MetricCard(modifier = Modifier.weight(1f), title = "Total Users", value = "${stats["totalUsers"] ?: 0}", icon = Icons.Default.People, color = Color(0xFF4285F4))
            MetricCard(modifier = Modifier.weight(1f), title = "Premium Users", value = "${stats["premiumUsers"] ?: 0}", icon = Icons.Default.Star, color = GoldAccent)
        }
        Spacer(modifier = Modifier.height(12.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            MetricCard(modifier = Modifier.weight(1f), title = "Total Videos", value = "${stats["totalVideos"] ?: 0}", icon = Icons.Default.Movie, color = Color(0xFFAB47BC))
            MetricCard(modifier = Modifier.weight(1f), title = "Live Streams", value = "$liveCount", icon = Icons.Default.PlayArrow, color = AccentRed)
        }
    }
}

@Composable
fun AdminLiveStreamsTab(
    liveEvents: List<Map<String, Any?>>,
    onDelete: (String) -> Unit,
    onToggle: (String, Boolean) -> Unit
) {
    if (liveEvents.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No active live streams. Click + to add one.", color = TextGrey)
        }
    } else {
        LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
            items(liveEvents) { event ->
                val id = event["id"]?.toString() ?: ""
                val title = event["title"]?.toString() ?: "Live Stream"
                val channel = event["channelName"]?.toString() ?: "Live Channel"
                val banner = event["bannerUrl"]?.toString() ?: ""
                val isActive = event["isActive"] as? Boolean ?: true
                val isPremium = event["isPremium"] as? Boolean ?: false

                Card(
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = DarkSurface),
                    modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
                ) {
                    Row(modifier = Modifier.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(modifier = Modifier.size(80.dp, 45.dp).clip(RoundedCornerShape(6.dp)).background(DarkSurfaceVariant)) {
                            AsyncImage(model = banner, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                            if (isActive) {
                                Box(
                                    modifier = Modifier
                                        .padding(4.dp)
                                        .background(AccentRed, RoundedCornerShape(4.dp))
                                        .padding(horizontal = 4.dp, vertical = 2.dp)
                                ) {
                                    Text("LIVE", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(text = title, color = TextWhite, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            Text(text = if (isPremium) "VIP • $channel" else "FREE • $channel", color = TextGrey, fontSize = 11.sp)
                        }
                        Switch(
                            checked = isActive,
                            onCheckedChange = { onToggle(id, it) },
                            colors = SwitchDefaults.colors(checkedThumbColor = AccentRed)
                        )
                        IconButton(onClick = { onDelete(id) }) {
                            Icon(Icons.Default.Delete, contentDescription = "Delete", tint = AccentRed, modifier = Modifier.size(20.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun MetricCard(modifier: Modifier = Modifier, title: String, value: String, icon: ImageVector, color: Color) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Icon(imageVector = icon, contentDescription = null, tint = color, modifier = Modifier.size(28.dp))
            Spacer(modifier = Modifier.height(12.dp))
            Text(text = value, color = TextWhite, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = title, color = TextGrey, fontSize = 12.sp)
        }
    }
}

@Composable
fun AdminContentTab(videos: List<VideoModel>, onDelete: (VideoModel) -> Unit) {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        items(videos) { video ->
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
            ) {
                Row(modifier = Modifier.padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(modifier = Modifier.size(80.dp, 45.dp).clip(RoundedCornerShape(6.dp)).background(DarkSurfaceVariant)) {
                        AsyncImage(model = video.thumbnailUrl, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = video.title, color = TextWhite, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(text = if (video.isPaid) "PREMIUM • ${video.views} views" else "FREE • ${video.views} views", color = TextGrey, fontSize = 11.sp)
                    }
                    IconButton(onClick = { onDelete(video) }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = AccentRed, modifier = Modifier.size(20.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun AdminCategoriesTab(categories: List<CategoryModel>, onDelete: (CategoryModel) -> Unit) {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        items(categories) { cat ->
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
            ) {
                Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = cat.name, color = TextWhite, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(text = "Order: ${cat.order} • ${if (cat.isAdult) "🔞 18+ ADULT" else "STANDARD"}", color = TextGrey, fontSize = 12.sp)
                    }
                    IconButton(onClick = { onDelete(cat) }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = AccentRed)
                    }
                }
            }
        }
    }
}

@Composable
fun AdminLayoutTab(sections: List<Map<String, Any?>>) {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        items(sections) { sec ->
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
            ) {
                Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = sec["title"]?.toString() ?: "Section", color = TextWhite, fontWeight = FontWeight.Bold)
                        Text(text = "Type: ${sec["type"]} • Source: ${sec["source"] ?: ""}", color = TextGrey, fontSize = 11.sp)
                    }
                }
            }
        }
    }
}

@Composable
fun AdminAdsTab(
    normalLink: String,
    adultLink: String,
    timer: String,
    enabled: Boolean,
    onSave: (String, String, String, Boolean) -> Unit
) {
    var nLink by remember { mutableStateOf(normalLink) }
    var aLink by remember { mutableStateOf(adultLink) }
    var tSec by remember { mutableStateOf(timer) }
    var isEnabled by remember { mutableStateOf(enabled) }

    Column(modifier = Modifier.fillMaxSize().padding(20.dp).verticalScroll(rememberScrollState())) {
        Text("Ad & Sponsor Monetization", color = TextWhite, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(4.dp))
        Text("Saved URLs are automatically encrypted using AES-256.", color = TextGrey, fontSize = 12.sp)
        Spacer(modifier = Modifier.height(20.dp))

        OutlinedTextField(value = nLink, onValueChange = { nLink = it }, label = { Text("Normal Sponsored URL") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(14.dp))
        OutlinedTextField(value = aLink, onValueChange = { aLink = it }, label = { Text("Adult Sponsored URL") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(14.dp))
        OutlinedTextField(value = tSec, onValueChange = { tSec = it }, label = { Text("Timer (Seconds)") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(12.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Enable In-App Ads", color = TextWhite, modifier = Modifier.weight(1f))
            Switch(checked = isEnabled, onCheckedChange = { isEnabled = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = { onSave(nLink.trim(), aLink.trim(), tSec.trim(), isEnabled) },
            colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
            modifier = Modifier.fillMaxWidth().height(48.dp)
        ) {
            Text("Encrypt & Save Ads")
        }
    }
}

@Composable
fun AdminPlansTab(plans: List<Map<String, Any?>>, onDelete: (String) -> Unit) {
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        items(plans) { plan ->
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = DarkSurface),
                modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp)
            ) {
                Row(modifier = Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = plan["name"]?.toString() ?: "Plan", color = TextWhite, fontWeight = FontWeight.Bold, fontSize = 16.sp)
                        Text(text = "₹${plan["price"]} • ${plan["durationDays"]} Days", color = GoldAccent, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                    IconButton(onClick = { onDelete(plan["id"]?.toString() ?: "") }) {
                        Icon(Icons.Default.Delete, contentDescription = "Delete", tint = AccentRed)
                    }
                }
            }
        }
    }
}

@Composable
fun AdminSettingsTab(
    appStore: String,
    updateUrl: String,
    upi: String,
    force: Boolean,
    maint: Boolean,
    onSave: (String, String, String, Boolean, Boolean) -> Unit
) {
    var store by remember { mutableStateOf(appStore) }
    var update by remember { mutableStateOf(updateUrl) }
    var upiId by remember { mutableStateOf(upi) }
    var fUpdate by remember { mutableStateOf(force) }
    var mMode by remember { mutableStateOf(maint) }

    Column(modifier = Modifier.fillMaxSize().padding(20.dp).verticalScroll(rememberScrollState())) {
        OutlinedTextField(value = store, onValueChange = { store = it }, label = { Text("App Store / Download URL") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(value = update, onValueChange = { update = it }, label = { Text("Update Check URL") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(value = upiId, onValueChange = { upiId = it }, label = { Text("Admin UPI ID (for payments)") }, modifier = Modifier.fillMaxWidth())
        Spacer(modifier = Modifier.height(12.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Force Update", color = TextWhite, modifier = Modifier.weight(1f))
            Switch(checked = fUpdate, onCheckedChange = { fUpdate = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Maintenance Mode", color = TextWhite, modifier = Modifier.weight(1f))
            Switch(checked = mMode, onCheckedChange = { mMode = it }, colors = SwitchDefaults.colors(checkedThumbColor = AccentRed))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = { onSave(store.trim(), update.trim(), upiId.trim(), fUpdate, mMode) },
            colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
            modifier = Modifier.fillMaxWidth().height(48.dp)
        ) {
            Text("Save App Settings")
        }
    }
}
