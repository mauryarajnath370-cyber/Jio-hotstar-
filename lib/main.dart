import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'admin_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/content_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  } catch (_) {}

  runApp(const JioHotstarApp());
}

class JioHotstarApp extends StatelessWidget {
  const JioHotstarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppConstants.routeSplash,
        routes: {
          AppConstants.routeSplash: (context) => const SplashScreen(),
          AppConstants.routeLanguage: (context) => const LanguageScreen(),
          AppConstants.routeLogin: (context) => const LoginScreen(),
          AppConstants.routeHome: (context) => const HomeScreen(),
          '/admin': (context) => const AdminLoginScreen(),
        },
      ),
    );
  }
}
