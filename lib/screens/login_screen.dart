import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/jio_hotstar_logo.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Rajnath Maurya');
  final TextEditingController _emailController = TextEditingController(text: 'mauryarajnath370@gmail.com');
  bool _showCustomSignIn = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in failed. Trying instant sign-in...'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
      // Fallback to instant sign in automatically
      _handleDirectSignIn(context);
    }
  }

  void _handleDirectSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInDirect(
      _emailController.text.trim(),
      _nameController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in error. Please check internet connection.'),
          backgroundColor: Color(0xFFE50914),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const JioHotstarLogo(size: 34),
                const SizedBox(height: 12),
                Text(
                  AppStrings.t('tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 54),

                if (authProvider.isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text('Signing in to Jio Hotstar...', style: TextStyle(color: AppTheme.textGrey)),
                    ],
                  )
                else ...[
                  // "Continue with Google" button (white bg, Google icon, dark text)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () => _handleGoogleSignIn(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.t('login'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instant 1-Click Working Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textWhite,
                        side: const BorderSide(color: AppTheme.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.flash_on, color: AppTheme.accent),
                      label: Text(
                        AppStrings.t('direct_signin'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _handleDirectSignIn(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guest explore button
                  TextButton(
                    onPressed: () {
                      authProvider.signInDirect('guest@jiohotstar.com', 'Guest Viewer').then((_) {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, AppConstants.routeHome);
                        }
                      });
                    },
                    child: Text(
                      AppStrings.t('guest_login'),
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Option to customize login profile if desired
                  GestureDetector(
                    onTap: () => setState(() => _showCustomSignIn = !_showCustomSignIn),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showCustomSignIn ? 'Hide Custom Profile' : 'Custom Profile Options',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        Icon(
                          _showCustomSignIn ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  if (_showCustomSignIn) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: TextStyle(color: AppTheme.textGrey),
                        filled: true,
                        fillColor: AppTheme.surface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: AppTheme.textGrey),
                        filled: true,
                        fillColor: AppTheme.surface,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
