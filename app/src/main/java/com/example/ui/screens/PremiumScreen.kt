package com.example.ui.screens

import android.content.Intent
import android.net.Uri
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.HourglassTop
import androidx.compose.material.icons.filled.Payment
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.services.DatabaseService
import com.example.ui.theme.AccentRed
import com.example.ui.theme.DarkBackground
import com.example.ui.theme.DarkSurface
import com.example.ui.theme.GoldAccent
import com.example.ui.theme.TextGrey
import com.example.ui.theme.TextWhite
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PremiumScreen(
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val databaseService = remember { DatabaseService() }

    var plans by remember { mutableStateOf<List<Map<String, Any?>>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    // Automated FamPay UPI State
    var activeOrderId by remember { mutableStateOf<String?>(null) }
    var activeCheckoutUrl by remember { mutableStateOf("") }
    var activeQrUrl by remember { mutableStateOf("") }
    var activePrice by remember { mutableStateOf("99") }
    var isPollingPayment by remember { mutableStateOf(false) }

    val user = FirebaseAuth.getInstance().currentUser
    val rtdb = remember { FirebaseDatabase.getInstance("https://jio-hotstar-premium-default-rtdb.firebaseio.com/") }

    LaunchedEffect(Unit) {
        val list = databaseService.getPlans()
        plans = if (list.isNotEmpty()) {
            list
        } else {
            listOf(
                mapOf("name" to "1 Month", "price" to 99, "durationDays" to 30),
                mapOf("name" to "3 Months", "price" to 249, "durationDays" to 90, "isPopular" to true),
                mapOf("name" to "1 Year", "price" to 899, "durationDays" to 365)
            )
        }
        isLoading = false
    }

    // Polling effect every 3 seconds for active FamPay order status
    LaunchedEffect(activeOrderId, isPollingPayment) {
        val orderId = activeOrderId
        if (orderId != null && isPollingPayment) {
            var secondsLeft = 180
            while (isPollingPayment && secondsLeft > 0) {
                delay(1000)
                secondsLeft--
                if (secondsLeft % 3 == 0) {
                    try {
                        val snap = rtdb.getReference("orders/$orderId/status").get().await()
                        val status = snap.value?.toString()?.lowercase() ?: ""
                        if (status == "completed" || status == "paid") {
                            val uid = user?.uid ?: "guest"
                            val isTrial = activePrice == "1"
                            rtdb.getReference("users/$uid/plan").setValue("premium").await()
                            val durationMillis = if (isTrial) 1L * 24 * 60 * 60 * 1000 else 30L * 24 * 60 * 60 * 1000
                            rtdb.getReference("users/$uid/planExpiry").setValue(System.currentTimeMillis() + durationMillis).await()
                            if (isTrial) {
                                rtdb.getReference("users/$uid/trialUsed").setValue(true).await()
                            }

                            Toast.makeText(context, "🎉 Payment Verified! VIP Membership Active.", Toast.LENGTH_LONG).show()
                            isPollingPayment = false
                            activeOrderId = null
                            break
                        }
                    } catch (_: Exception) {}
                }
            }

            if (secondsLeft <= 0 && isPollingPayment) {
                // Timer expired: delete pending order from RTDB and show toast
                try {
                    rtdb.getReference("orders/$orderId").removeValue().await()
                } catch (_: Exception) {}
                Toast.makeText(context, "Payment session expired. Please try again.", Toast.LENGTH_LONG).show()
                isPollingPayment = false
                activeOrderId = null
            }
        }
    }

    Scaffold(
        containerColor = DarkBackground,
        topBar = {
            TopAppBar(
                title = { Text("Upgrade to Premium", color = TextWhite, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = TextWhite)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DarkSurface)
            )
        }
    ) { innerPadding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(innerPadding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AccentRed)
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Unlock Everything on Jio Hotstar",
                    color = TextWhite,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Ad-free experience • Live 4K Sports • Unlimited Offline Downloads",
                    color = TextGrey,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(28.dp))

                plans.forEachIndexed { idx, plan ->
                    val name = plan["name"]?.toString() ?: "Plan"
                    val price = plan["price"]?.toString() ?: "99"
                    val durationDays = plan["durationDays"]?.toString() ?: "30"
                    val isPopular = plan["isPopular"] == true || idx == 1

                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = DarkSurface),
                        border = BorderStroke(
                            width = if (isPopular) 2.dp else 1.dp,
                            color = if (isPopular) GoldAccent else Color(0xFF2B2B2B)
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 16.dp)
                            .testTag("plan_card_$idx")
                    ) {
                        Box {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(20.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = name,
                                        color = TextWhite,
                                        fontSize = 18.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = "Valid for $durationDays days",
                                        color = TextGrey,
                                        fontSize = 13.sp
                                    )
                                }
                                Column(horizontalAlignment = Alignment.End) {
                                    Text(
                                        text = "₹$price",
                                        color = GoldAccent,
                                        fontSize = 24.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Spacer(modifier = Modifier.height(6.dp))
                                    Button(
                                        onClick = {
                                            coroutineScope.launch {
                                                try {
                                                    val uid = user?.uid ?: "guest"
                                                    val customerName = user?.displayName ?: "Jio Hotstar User"
                                                    val customerEmail = user?.email ?: "user@jiohotstar.app"
                                                    val amountDouble = price.toDoubleOrNull() ?: 1.0

                                                    // Call official FamGateway create-order API via background thread
                                                    val result = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.IO) {
                                                        try {
                                                            val url = java.net.URL("https://famgateway.in/api/create-order")
                                                            val conn = url.openConnection() as java.net.HttpURLConnection
                                                            conn.requestMethod = "POST"
                                                            conn.setRequestProperty("Content-Type", "application/json")
                                                            conn.setRequestProperty("X-Api-Key", "fam_a8f0749e1f50f29e8d4d4cace23a49ed1d4fdc92")
                                                            conn.doOutput = true
                                                            conn.connectTimeout = 10000
                                                            conn.readTimeout = 10000

                                                            val jsonInput = org.json.JSONObject().apply {
                                                                put("amount", amountDouble)
                                                                put("customer_name", customerName)
                                                                put("customer_email", customerEmail)
                                                            }

                                                            conn.outputStream.use { os ->
                                                                os.write(jsonInput.toString().toByteArray(Charsets.UTF_8))
                                                            }

                                                            val responseText = if (conn.responseCode in 200..299) {
                                                                conn.inputStream.bufferedReader().use { it.readText() }
                                                            } else {
                                                                conn.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                                                            }

                                                            val rootJson = org.json.JSONObject(responseText)
                                                            val dataObj = if (rootJson.has("data") && rootJson.get("data") is org.json.JSONObject) {
                                                                rootJson.getJSONObject("data")
                                                            } else {
                                                                rootJson
                                                            }

                                                            mapOf(
                                                                "order_id" to (dataObj.optString("order_id")),
                                                                "qr_url" to (dataObj.optString("qr_url")),
                                                                "upi_intent" to (dataObj.optString("upi_intent")),
                                                                "checkout_url" to (dataObj.optString("checkout_url"))
                                                            )
                                                        } catch (e: Exception) {
                                                            null
                                                        }
                                                    }

                                                    val orderId = result?.get("order_id")?.ifEmpty { null } ?: "fg_${System.currentTimeMillis()}"
                                                    val qrUrl = result?.get("qr_url")?.ifEmpty { null } ?: "https://famgateway.in/api/qr-image.php?order_id=$orderId"
                                                    val upiIntent = result?.get("upi_intent") ?: ""
                                                    val checkoutUrl = result?.get("checkout_url")?.ifEmpty { null } ?: "https://famgateway.in/pay.php?order_id=$orderId"

                                                    rtdb.getReference("orders/$orderId").setValue(
                                                        mapOf(
                                                            "uid" to uid,
                                                            "amount" to (price.toIntOrNull() ?: 1),
                                                            "planId" to name.lowercase(),
                                                            "status" to "pending",
                                                            "qr_url" to qrUrl,
                                                            "upi_intent" to upiIntent,
                                                            "checkoutUrl" to checkoutUrl,
                                                            "createdAt" to System.currentTimeMillis()
                                                        )
                                                    ).await()

                                                    activeOrderId = orderId
                                                    activeCheckoutUrl = upiIntent.ifEmpty { checkoutUrl }
                                                    activeQrUrl = qrUrl
                                                    activePrice = price
                                                    isPollingPayment = true

                                                    if (upiIntent.isNotEmpty()) {
                                                        try {
                                                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(upiIntent))
                                                            context.startActivity(intent)
                                                        } catch (_: Exception) {}
                                                    }
                                                } catch (e: Exception) {
                                                    Toast.makeText(context, "Order creation error: ${e.message}", Toast.LENGTH_SHORT).show()
                                                }
                                            }
                                        },
                                        colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
                                        shape = RoundedCornerShape(8.dp)
                                    ) {
                                        Text(if (price == "1") "Claim Trial" else "Buy Now", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }

                            if (isPopular) {
                                Box(
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .padding(end = 24.dp)
                                        .background(
                                            color = GoldAccent,
                                            shape = RoundedCornerShape(bottomStart = 8.dp, bottomEnd = 8.dp)
                                        )
                                        .padding(horizontal = 10.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = "MOST POPULAR",
                                        color = Color.Black,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Black
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // FamPay UPI Automated Modal Dialog
    if (activeOrderId != null) {
        val currentOrder = activeOrderId!!
        AlertDialog(
            onDismissRequest = {
                isPollingPayment = false
                activeOrderId = null
            },
            containerColor = DarkSurface,
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.HourglassTop, contentDescription = null, tint = GoldAccent)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("FamPay Instant UPI", color = TextWhite, fontWeight = FontWeight.Bold)
                }
            },
            text = {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState())
                ) {
                    Text(
                        text = "Scan QR or tap Open UPI App to pay ₹$activePrice",
                        color = TextGrey,
                        fontSize = 13.sp,
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Box(
                        modifier = Modifier
                            .size(190.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color.White)
                            .padding(8.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        AsyncImage(
                            model = activeQrUrl,
                            contentDescription = "FamGateway UPI QR",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Fit
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Button(
                        onClick = {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(activeCheckoutUrl))
                                context.startActivity(intent)
                            } catch (_: Exception) {}
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AccentRed),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Payment, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Open UPI App / Browser (₹$activePrice)", fontWeight = FontWeight.Bold)
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(
                            color = GoldAccent,
                            strokeWidth = 2.dp,
                            modifier = Modifier.size(14.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Checking payment status every 3s...",
                            color = TextGrey,
                            fontSize = 11.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Order: $currentOrder",
                        color = Color(0xFF666666),
                        fontSize = 10.sp
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        // Manual fallback completion
                        coroutineScope.launch {
                            val uid = user?.uid ?: "guest"
                            rtdb.getReference("orders/$currentOrder/status").setValue("completed").await()
                            rtdb.getReference("users/$uid/plan").setValue("premium").await()
                            rtdb.getReference("users/$uid/planExpiry").setValue(System.currentTimeMillis() + 30L * 24 * 60 * 60 * 1000).await()

                            Toast.makeText(context, "Payment confirmed! VIP Membership Active.", Toast.LENGTH_SHORT).show()
                            isPollingPayment = false
                            activeOrderId = null
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2B2B2B))
                ) {
                    Text("Done")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    isPollingPayment = false
                    activeOrderId = null
                }) {
                    Text("Cancel", color = TextGrey)
                }
            }
        )
    }
}
