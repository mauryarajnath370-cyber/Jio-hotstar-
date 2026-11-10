import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../admin_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/encryption_helper.dart';
import '../core/widgets/jio_hotstar_logo.dart';
import '../services/database_service.dart';
import '../l10n/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isMaintenance = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyD7YumwKVQi9UiAoRd8ypBZys6JFHD20Eo',
            appId: '1:147522734754:android:447b5f94dfd73e66a0e5fb',
            messagingSenderId: '147522734754',
            projectId: 'jio-hotstar-premium',
            databaseURL: AdminConfig.dbUrl,
            storageBucket: 'jio-hotstar-premium.firebasestorage.app',
          ),
        );
      }
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      } catch (_) {}

      await EncryptionHelper.init();
      await SharedPreferencesHelper.loadLanguage();

      // Check Maintenance Mode & Force Update
      final appSettings = await DatabaseService().getAppSettings();
      if (appSettings['maintenanceMode'] == true) {
        setState(() => _isMaintenance = true);
        return;
      }

      if (appSettings['forceUpdate'] == true && mounted) {
        final updateUrl = appSettings['updateUrl'] ?? 'https://jiohotstar.app/update';
        _showForceUpdateDialog(updateUrl);
        return;
      }
    } catch (_) {}

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final selectedLanguage = prefs.getString('selected_language');

    if (selectedLanguage == null) {
      Navigator.pushReplacementNamed(context, AppConstants.routeLanguage);
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
      } else {
        Navigator.pushReplacementNamed(context, AppConstants.routeHome);
      }
    }
  }

  void _showForceUpdateDialog(String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Update Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'A new version of Jio Hotstar Premium is available with important security and streaming upgrades. Please update to continue watching.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
            onPressed: () async {
              try {
                await launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMaintenance) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_circle, size: 72, color: Color(0xFFE50914)),
                const SizedBox(height: 16),
                const Text(
                  'Under Scheduled Maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We are currently upgrading the Jio Hotstar servers for smoother 4K streaming. We will be back online shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                  onPressed: () => _initializeAppAndNavigate(),
                  child: const Text('Check Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A0000),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const JioHotstarLogo(size: 38),
            ),
          ),
        ),
      ),
    );
  }
}
