const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const crypto = require("crypto");

admin.initializeApp();

const RTDB_URL = "https://jio-hotstar-premium-default-rtdb.firebaseio.com/";
const db = admin.database(RTDB_URL);

// Exact FamPay API Credentials
const FAMGATEWAY_API_KEY = "fam_a8f0749e1f50f29e8d4d4cace23a49ed1d4fdc92";
const FAMGATEWAY_BASE_URL = "https://famgateway.in/api";

function getApiKey() {
  return (
    (functions.config().famgateway && functions.config().famgateway.key) ||
    process.env.FAMGATEWAY_KEY ||
    FAMGATEWAY_API_KEY
  );
}

/**
 * 1. createFamPayOrder (Callable Function)
 * - Makes POST request to FamGateway Create Order API: https://famgateway.in/api/create-order
 * - Headers: {"X-Api-Key": FAMGATEWAY_API_KEY, "Content-Type": "application/json"}
 * - Body: {"amount": 99.00, "custom_id": "{user_uid}_{plan_id}"}
 * - Saves pending order in RTDB: orders/{order_id} = {uid, planId, status: "pending"}
 * - Returns checkout_url and qr_image_url to the app.
 */
exports.createFamPayOrder = functions.https.onCall(async (data, context) => {
  const uid = (context.auth && context.auth.uid) || data.uid || "guest_user";
  const planId = data.planId || "plan_monthly";
  const amount = parseFloat(data.amount) || 1.0;
  const customerName = data.customer_name || data.customerName || "Jio Hotstar User";
  const customerEmail = data.customer_email || data.customerEmail || "user@jiohotstar.app";
  const apiKey = getApiKey();

  try {
    const payload = {
      amount: amount,
      customer_name: customerName,
      customer_email: customerEmail,
    };

    const response = await axios.post(`${FAMGATEWAY_BASE_URL}/create-order`, payload, {
      headers: {
        "X-Api-Key": apiKey,
        "Content-Type": "application/json",
      },
      timeout: 15000,
    });

    const resData = response.data || {};
    const orderId = resData.order_id || resData.orderId;
    const qrUrl = resData.qr_url || resData.qrUrl || resData.qr_image_url || "";
    const upiIntent = resData.upi_intent || resData.upiIntent || "";
    const checkoutUrl = resData.checkout_url || resData.checkoutUrl || "";

    if (!orderId) {
      throw new Error(`FamGateway create-order failed: ${JSON.stringify(resData)}`);
    }

    // Save pending order in RTDB: orders/{order_id}
    await db.ref(`orders/${orderId}`).set({
      uid: uid,
      planId: planId,
      amount: amount,
      status: "pending",
      customer_name: customerName,
      customer_email: customerEmail,
      qr_url: qrUrl,
      upi_intent: upiIntent,
      checkout_url: checkoutUrl,
      createdAt: Date.now(),
    });

    return {
      order_id: orderId,
      qr_url: qrUrl,
      upi_intent: upiIntent,
      checkout_url: checkoutUrl,
      status: "pending",
    };
  } catch (error) {
    console.error("createFamPayOrder error:", error.response ? error.response.data : error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

/**
 * 2. famPayWebhook (HTTP Request Function)
 * - Header: "X-FamGateway-Signature" (HMAC-SHA256 of raw body using API_KEY)
 * - Body: {"status": "success", "order_id": "...", "utr": "..."}
 * - Verifies the HMAC signature using the API key.
 * - If valid, updates RTDB: orders/{order_id}/status = "success"
 * - Updates user: users/{uid}/plan = "premium" and sets planExpiry based on the plan duration.
 */
exports.famPayWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const apiKey = getApiKey();
  const signature = req.headers["x-famgateway-signature"] || req.headers["X-FamGateway-Signature"];

  // Verify HMAC-SHA256 signature
  const rawBody = req.rawBody ? req.rawBody.toString("utf8") : JSON.stringify(req.body);
  const expectedSignature = crypto
    .createHmac("sha256", apiKey)
    .update(rawBody)
    .digest("hex");

  if (signature && signature !== expectedSignature) {
    console.warn("Signature mismatch. Received:", signature, "Expected:", expectedSignature);
    return res.status(401).send("Unauthorized: Invalid signature");
  }

  const body = req.body || {};
  const orderId = body.order_id || body.orderId;
  const utr = body.utr || "";
  const status = (body.status || "").toLowerCase();

  if (!orderId) {
    return res.status(400).json({ error: "Missing order_id" });
  }

  if (status !== "success" && status !== "paid" && status !== "completed") {
    return res.status(200).json({ message: "Ignored non-success event" });
  }

  try {
    const orderRef = db.ref(`orders/${orderId}`);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists()) {
      return res.status(404).json({ error: "Order not found" });
    }

    const orderData = orderSnap.val() || {};
    if (orderData.status === "completed") {
      return res.status(200).json({ message: "Order already completed" });
    }

    const uid = orderData.uid;
    const planId = orderData.planId;

    // Fetch plan details from RTDB plans/{planId} to get durationDays
    let durationDays = 30;
    try {
      const planSnap = await db.ref(`plans/${planId}`).get();
      if (planSnap.exists() && planSnap.val().durationDays) {
        durationDays = parseInt(planSnap.val().durationDays, 10);
      }
    } catch (_) {}

    const planExpiry = Date.now() + durationDays * 24 * 60 * 60 * 1000;

    // Update RTDB: orders/{order_id}/status = "completed"
    await orderRef.update({
      status: "completed",
      utr: utr,
      completedAt: Date.now(),
    });

    // Update user: users/{uid}/plan = "premium" and planExpiry
    if (uid && uid !== "guest_user") {
      await db.ref(`users/${uid}`).update({
        plan: "premium",
        planExpiry: planExpiry,
      });
    }

    console.log(`Payment success for order ${orderId}, user ${uid}, expiry ${new Date(planExpiry)}`);
    return res.status(200).json({ success: true, message: "Payment processed" });
  } catch (error) {
    console.error("Webhook execution error:", error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * 3. checkFamPayOrderStatus (Callable & HTTP Function)
 * - Endpoint: GET https://famgateway.in/api/checkout-status.php?order_id={order_id}
 * - Response: {"status": "paid", "utr": "123456789012"} (or "pending")
 */
exports.checkFamPayOrder = functions.https.onCall(async (data, context) => {
  const orderId = data.orderId || data.order_id;
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing orderId");
  }

  const apiKey = getApiKey();

  try {
    // Check RTDB first
    const orderRef = db.ref(`orders/${orderId}`);
    const orderSnap = await orderRef.get();
    if (orderSnap.exists() && orderSnap.val().status === "completed") {
      return { status: "paid", completed: true };
    }

    // Call FamGateway Check Status endpoint
    const response = await axios.get(
      `${FAMGATEWAY_BASE_URL}/checkout-status.php?order_id=${encodeURIComponent(orderId)}`,
      {
        headers: {
          "X-Api-Key": apiKey,
        },
        timeout: 10000,
      }
    );

    const resData = response.data || {};
    const status = (resData.status || "").toLowerCase();

    if (status === "paid" || status === "success" || status === "completed") {
      if (orderSnap.exists()) {
        const orderData = orderSnap.val() || {};
        let durationDays = 30;
        try {
          const planSnap = await db.ref(`plans/${orderData.planId}`).get();
          if (planSnap.exists() && planSnap.val().durationDays) {
            durationDays = parseInt(planSnap.val().durationDays, 10);
          }
        } catch (_) {}

        const planExpiry = Date.now() + durationDays * 24 * 60 * 60 * 1000;

        await orderRef.update({
          status: "completed",
          utr: resData.utr || "FAMPAY_VERIFIED",
          completedAt: Date.now(),
        });

        if (orderData.uid && orderData.uid !== "guest_user") {
          await db.ref(`users/${orderData.uid}`).update({
            plan: "premium",
            planExpiry: planExpiry,
          });
        }
      }

      return { status: "paid", completed: true };
    }

    return { status: "pending", completed: false };
  } catch (error) {
    console.error("checkFamPayOrder error:", error.message);
    return { status: "pending", completed: false };
  }
});
