import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static String _currentLanguage = 'en';

  static void setLanguage(String lang) {
    _currentLanguage = lang;
  }

  static String getLanguage() => _currentLanguage;

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? 'en';
  }

  static Future<void> saveLanguage(String lang) async {
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', lang);
  }
}

class AppStrings {
  static const Map<String, Map<String, String>> _data = {
    'en': {
      'app_name': 'Jio Hotstar Premium',
      'login': 'Continue with Google',
      'tagline': 'Stream Unlimited. Anywhere. Anytime.',
      'home': 'Home', 'search': 'Search', 'premium': 'Premium', 'settings': 'Settings',
      'trending': 'Trending', 'movies': 'Movies', 'web_series': 'Web Series',
      'my_list': 'My List', 'adult': 'Adult Content',
      'watch_later': 'Watch Later', 'share': 'Share', 'download': 'Download', 'report': 'Report',
      'watch_now': 'Watch Now', 'more_from_category': 'More from this category',
      'set_password': 'Set Adult Password', 'enter_password': 'Enter Adult Password',
      'sponsored_link': 'Sponsored Link', 'continue': 'Continue',
      'upgrade_to_premium': 'Upgrade to Premium', 'logout': 'Logout', 'language': 'Language',
      'please_wait': 'Please wait...', 'no_results': 'No results found',
      'see_all': 'See All', 'guest_login': 'Explore as Guest',
      'direct_signin': 'Quick Instant Sign-In',
    },
    'hi': {
      'app_name': 'जियो हॉटस्टार प्रीमियम',
      'login': 'Google से जारी रखें',
      'tagline': 'असीमित स्ट्रीम करें। कभी भी, कहीं भी।',
      'home': 'होम', 'search': 'खोजें', 'premium': 'प्रीमियम', 'settings': 'सेटिंग्स',
      'trending': 'ट्रेंडिंग', 'movies': 'फिल्में', 'web_series': 'वेब सीरीज़',
      'my_list': 'मेरी सूची', 'adult': 'वयस्क सामग्री',
      'watch_later': 'बाद में देखें', 'share': 'साझा करें', 'download': 'डाउनलोड', 'report': 'रिपोर्ट',
      'watch_now': 'अभी देखें', 'more_from_category': 'इस श्रेणी से और',
      'set_password': 'वयस्क पासवर्ड सेट करें', 'enter_password': 'वयस्क पासवर्ड दर्ज करें',
      'sponsored_link': 'प्रायोजित लिंक', 'continue': 'जारी रखें',
      'upgrade_to_premium': 'प्रीमियम में अपग्रेड करें', 'logout': 'लॉग आउट', 'language': 'भाषा',
      'please_wait': 'कृपया प्रतीक्षा करें...', 'no_results': 'कोई परिणाम नहीं मिला',
      'see_all': 'सभी देखें', 'guest_login': 'अतिथि के रूप में अन्वेषण करें',
      'direct_signin': 'त्वरित साइन-इन',
    },
  };

  static String t(String key) {
    final lang = SharedPreferencesHelper.getLanguage(); // 'en' or 'hi'
    return _data[lang]?[key] ?? _data['en']?[key] ?? key;
  }
}
