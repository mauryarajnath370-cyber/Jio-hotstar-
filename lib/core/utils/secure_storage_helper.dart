import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Admin Session
  static Future<void> saveAdminSession() async {
    await _storage.write(key: AppConstants.keyAdminSession, value: 'true');
  }

  static Future<bool> isAdminLoggedIn() async {
    final value = await _storage.read(key: AppConstants.keyAdminSession);
    return value == 'true';
  }

  static Future<void> clearAdminSession() async {
    await _storage.delete(key: AppConstants.keyAdminSession);
  }

  // AES Key
  static Future<void> saveAesKey(String keyB64) async {
    await _storage.write(key: AppConstants.keyAesKey, value: keyB64);
  }

  static Future<String?> getAesKey() async {
    return await _storage.read(key: AppConstants.keyAesKey);
  }

  // Admin Hashes
  static Future<void> saveAdminHashes(String userHash, String passHash) async {
    await _storage.write(key: AppConstants.keyAdminUserHash, value: userHash);
    await _storage.write(key: AppConstants.keyAdminPassHash, value: passHash);
  }

  static Future<Map<String, String?>> getAdminHashes() async {
    final userHash = await _storage.read(key: AppConstants.keyAdminUserHash);
    final passHash = await _storage.read(key: AppConstants.keyAdminPassHash);
    return {
      'userHash': userHash,
      'passHash': passHash,
    };
  }
}
