import 'database_service.dart';

class AdService {
  final DatabaseService _databaseService;

  AdService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  Future<String> getNormalAdLink() async {
    try {
      final adSettings = await _databaseService.getAdSettings();
      return adSettings['normalAdLink']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String> getAdultAdLink() async {
    try {
      final adSettings = await _databaseService.getAdSettings();
      return adSettings['adultAdLink']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<int> getAdTimerSeconds() async {
    try {
      final adSettings = await _databaseService.getAdSettings();
      final timer = adSettings['adTimerSeconds'];
      if (timer is int) return timer;
      return int.tryParse(timer?.toString() ?? '5') ?? 5;
    } catch (_) {
      return 5;
    }
  }
}
