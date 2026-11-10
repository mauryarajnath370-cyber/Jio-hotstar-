import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../l10n/app_strings.dart';
import 'language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          AppStrings.t('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2B2B2B)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.accent,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'J',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : 'Jio Hotstar Viewer',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email.isNotEmpty == true ? user!.email : 'user@jiohotstar.com',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user?.isPremiumActive == true ? const Color(0xFFFFD700) : Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user?.isPremiumActive == true ? 'VIP PREMIUM' : 'FREE TIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user?.isPremiumActive == true ? Colors.black : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings items
            _buildSettingTile(
              icon: Icons.language,
              title: AppStrings.t('language'),
              subtitle: SharedPreferencesHelper.getLanguage() == 'hi' ? 'हिंदी (Hindi)' : 'English',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.ondemand_video,
              title: 'Watch Ad to Unlock',
              subtitle: 'Coming in Step 3',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Step 3 Feature: Watch Ad to Unlock')),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.share,
              title: 'Share App',
              subtitle: 'Invite friends & family',
              onTap: () async {
                final settings = await DatabaseService().getAppSettings();
                final link = settings['appStoreLink'] ?? 'https://jiohotstar.app';
                Share.share('Stream movies & cricket on Jio Hotstar Premium! Download: $link');
              },
            ),
            _buildSettingTile(
              icon: Icons.system_update,
              title: 'Check for Updates',
              subtitle: 'Version 1.0.0 (Latest)',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Software Update', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'You are using the latest version of Jio Hotstar Premium (1.0.0).',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Logout
            _buildSettingTile(
              icon: Icons.logout,
              iconColor: AppTheme.accent,
              title: AppStrings.t('logout'),
              titleColor: AppTheme.accent,
              onTap: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
                }
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Jio Hotstar Premium v1.0.0 (Build 2026)\nSecure Encrypted Core',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    Color iconColor = Colors.white70,
    required String title,
    Color titleColor = Colors.white,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
        onTap: onTap,
      ),
    );
  }
}
