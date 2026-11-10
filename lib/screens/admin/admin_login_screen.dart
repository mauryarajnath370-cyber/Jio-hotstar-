import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../admin_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/secure_storage_helper.dart';
import '../../core/widgets/jio_hotstar_logo.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleAdminLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt('admin_lock_until') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < lockUntil) {
      final remainingMins = ((lockUntil - now) / 60000).ceil();
      setState(() {
        _errorMessage = 'Too many failed attempts. Locked for $remainingMins minutes.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _userController.text.trim();
    final password = _passController.text.trim();

    final isValid = AdminAuthHelper.verifyAdmin(username, password);

    if (isValid) {
      // Success
      await prefs.setInt('admin_failed_attempts', 0);
      await SecureStorageHelper.saveAdminSession();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      // Failed
      final attempts = (prefs.getInt('admin_failed_attempts') ?? 0) + 1;
      await prefs.setInt('admin_failed_attempts', attempts);

      if (attempts >= 5) {
        final lockTime = now + (60 * 60 * 1000); // 1 hour lock
        await prefs.setInt('admin_lock_until', lockTime);
        setState(() {
          _errorMessage = 'Too many failed attempts. Locked for 1 hour.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid admin credentials ($attempts/5 attempts)';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid credentials. Remaining attempts: ${5 - attempts}'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Admin Portal Login', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const JioHotstarLogo(size: 30),
                const SizedBox(height: 12),
                const Text(
                  'Encrypted Master Control Panel',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 36),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Admin Username',
                          labelStyle: TextStyle(color: AppTheme.textGrey),
                          prefixIcon: Icon(Icons.person, color: AppTheme.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Admin Password',
                          labelStyle: TextStyle(color: AppTheme.textGrey),
                          prefixIcon: Icon(Icons.lock, color: AppTheme.accent),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                          onPressed: _isLoading ? null : _handleAdminLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Authenticate & Enter', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
