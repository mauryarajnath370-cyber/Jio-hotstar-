import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/fampay_service.dart';
import '../l10n/app_strings.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final FamPayService _famPayService = FamPayService();
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  void _fetchPlans() async {
    final list = await DatabaseService().getPlans();
    if (mounted) {
      setState(() {
        _plans = list.isNotEmpty
            ? list
            : [
                {
                  "id": "trial_1rs",
                  "name": "₹1 Premium Trial",
                  "price": 1,
                  "durationDays": 1,
                  "isTrial": true,
                },
                {"name": "1 Month", "price": 99, "durationDays": 30},
                {"name": "3 Months", "price": 249, "durationDays": 90, "isPopular": true},
                {"name": "1 Year", "price": 899, "durationDays": 365},
              ];
        _isLoading = false;
      });
    }
  }

  void startTrial(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    String name = user?.displayName ?? "User";
    String email = user?.email ?? "test@test.com";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var orderData = await FamPayService.createOrder(1.00, name, email);

    if (context.mounted) Navigator.pop(context);

    if (orderData != null && orderData['qr_url'] != null) {
      if (context.mounted) {
        showPaymentDialog(context, orderData, user?.uid ?? "guest_user");
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment API Failed.")));
      }
    }
  }

  void showPaymentDialog(BuildContext context, Map<String, dynamic> orderData, String uid) {
    String orderId = orderData['order_id'].toString();
    String qrUrl = orderData['qr_url'].toString();
    String upiIntent = orderData['upi_intent']?.toString() ?? "";

    int secondsRemaining = 180; // 3 Minutes
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
              if (secondsRemaining > 0) {
                setState(() => secondsRemaining--);
              } else {
                t.cancel();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Timeout! Order Deleted.")));

                // DELETE ORDER FROM FIREBASE
                FirebaseDatabase.instance.ref('orders/$orderId').remove();
              }

              if (secondsRemaining % 3 == 0) {
                String status = await FamPayService.checkStatus(orderId);
                if (status == "success") {
                  t.cancel();
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Success! Trial Activated.")));

                  // UPDATE USER PLAN IN FIREBASE
                  int expiry = DateTime.now().millisecondsSinceEpoch + (1 * 24 * 60 * 60 * 1000); // 1 Day
                  FirebaseDatabase.instance.ref('users/$uid').update({
                    'plan': 'premium',
                    'planExpiry': expiry,
                    'trialUsed': true,
                  });

                  if (context.mounted) {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.loadCurrentUser();
                  }
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text("Scan to Pay ₹1", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: qrUrl,
                    height: 200,
                    width: 200,
                    placeholder: (c, u) => const CircularProgressIndicator(),
                    errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Time Remaining: ${secondsRemaining ~/ 60}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            timer?.cancel();
                            Navigator.pop(dialogContext);
                          },
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                          onPressed: () async {
                            final target = upiIntent.isNotEmpty
                                ? upiIntent
                                : (orderData['checkout_url'] ?? "").toString();
                            if (target.isNotEmpty) {
                              try {
                                await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            }
                          },
                          child: const Text("Pay via UPI App"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
    });
  }

  void _handleBuyNow(Map<String, dynamic> plan) async {
    final planId = (plan['id'] ?? plan['name'] ?? '').toString().toLowerCase();
    if (planId == 'trial_1rs' || plan['price'] == 1) {
      startTrial(context);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before upgrading.')),
      );
      return;
    }

    final double price = (plan['price'] as num?)?.toDouble() ?? 99.0;
    final int durationDays = (plan['durationDays'] as num?)?.toInt() ?? 30;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );

    final String customerName = user.name.isNotEmpty ? user.name : 'Jio Hotstar User';
    final String customerEmail = user.email.isNotEmpty ? user.email : 'user@jiohotstar.app';

    Map<String, dynamic>? orderData = await FamPayService.createOrder(price, customerName, customerEmail);
    if (mounted) Navigator.pop(context);

    if (orderData != null && orderData['qr_url'] != null) {
      if (mounted) {
        showPaymentDialog(context, orderData, user.uid);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment API Failed.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isPremium = user != null && user.isPremiumActive;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          AppStrings.t('upgrade_to_premium'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Premium Banner if already active
                  if (isPremium)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium, color: Colors.black, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'Jio Hotstar VIP Active',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.planExpiry == 0
                                ? 'Lifetime Subscription Active'
                                : 'You are Premium until ${DateTime.fromMillisecondsSinceEpoch(user.planExpiry).toLocal().toString().split(' ')[0]}',
                            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Unlock Everything with Jio Hotstar Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ad-free entertainment • Live 4K Sports • Unlimited Offline Downloads',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 28),

                  // Plans cards
                  ..._plans.map((plan) {
                    final isTrial = plan['id'] == 'trial_1rs' || plan['isTrial'] == true || (plan['price'] == 1 && plan['durationDays'] == 1);
                    final isTrialUsed = user?.trialUsed == true;

                    // If user already used trial, we can disable or mark it
                    if (isTrial && isTrialUsed) {
                      // Skip rendering or show disabled
                      return const SizedBox.shrink();
                    }

                    final isPopular = plan['isPopular'] == true;

                    Color borderColor = const Color(0xFF2B2B2B);
                    if (isTrial) {
                      borderColor = const Color(0xFF00E676); // Green highlight for 1-Day Trial
                    } else if (isPopular) {
                      borderColor = const Color(0xFFFFD700);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: (isTrial || isPopular) ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan['name']?.toString() ?? 'Plan',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isTrial
                                            ? '24 Hours Full Access • Special Offer'
                                            : 'Valid for ${plan['durationDays'] ?? 30} days',
                                        style: TextStyle(
                                          color: isTrial ? const Color(0xFF00E676) : AppTheme.textGrey,
                                          fontSize: 12,
                                          fontWeight: isTrial ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${plan['price'] ?? 99}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isTrial ? const Color(0xFF00E676) : const Color(0xFFFFD700),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isTrial ? const Color(0xFF00C853) : AppTheme.accent,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      ),
                                      onPressed: () => _handleBuyNow(plan),
                                      child: Text(
                                        isTrial ? 'Claim Trial' : 'Buy Plan',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isTrial)
                            Positioned(
                              top: 0,
                              right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E676),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '1-DAY TRIAL',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                          else if (isPopular)
                            Positioned(
                              top: 0,
                              right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD700),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'MOST POPULAR',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
