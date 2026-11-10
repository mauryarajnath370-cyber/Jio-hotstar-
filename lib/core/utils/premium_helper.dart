import '../../models/user_model.dart';
import '../../models/video_model.dart';

class PremiumHelper {
  /// Strictly checks that user has 'premium' plan and their planExpiry has NOT expired.
  /// If planExpiry is in the past (e.g. 24 hours trial finished), returns false.
  static bool isPremium(UserModel? user) {
    if (user == null) return false;
    return user.plan == 'premium' && user.planExpiry > DateTime.now().millisecondsSinceEpoch;
  }

  /// Paid videos are strictly locked for non-premium or expired users
  static bool canPlay(VideoModel video, UserModel? user) {
    if (!video.isPaid) return true;
    return isPremium(user);
  }

  /// Offline downloads are restricted to active premium subscribers
  static bool canDownload(VideoModel video, UserModel? user) {
    if (!video.isDownloadable) return false;
    return isPremium(user);
  }
}
