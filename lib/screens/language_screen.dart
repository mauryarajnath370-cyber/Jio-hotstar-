import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/jio_hotstar_logo.dart';
import '../l10n/app_strings.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    await SharedPreferencesHelper.saveLanguage(langCode);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const JioHotstarLogo(size: 32),
              const SizedBox(height: 36),
              const Text(
                'Choose Language / भाषा चुनें',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your preferred streaming language',
                style: TextStyle(fontSize: 14, color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Two large cards side by side
              Row(
                children: [
                  // Hindi Card
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectLanguage(context, 'hi'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'अ',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'हिन्दी',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'फ़िल्में और शो',
                              style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // English Card
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectLanguage(context, 'en'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'En',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'English',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Movies & Series',
                              style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
