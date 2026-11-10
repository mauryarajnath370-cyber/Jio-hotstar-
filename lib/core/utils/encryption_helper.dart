import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static late final Encrypter _encrypter;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  // Call once at app start
  static Future<void> init() async {
    const storage = FlutterSecureStorage();
    String? keyB64 = await storage.read(key: 'aes_key');
    if (keyB64 == null) {
      final key = Key.fromSecureRandom(32);
      keyB64 = base64Encode(key.bytes);
      await storage.write(key: 'aes_key', value: keyB64);
    }
    _encrypter = Encrypter(AES(Key(base64Decode(keyB64)), mode: AESMode.cbc));
    _initialized = true;
  }

  static String encrypt(String plain) {
    if (!_initialized) {
      throw StateError('EncryptionHelper is not initialized. Call init() first.');
    }
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plain, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  static String decrypt(String encrypted) {
    if (!_initialized) {
      throw StateError('EncryptionHelper is not initialized. Call init() first.');
    }
    if (!encrypted.contains(':')) {
      return encrypted; // Plaintext fallback if not encrypted
    }
    try {
      final parts = encrypted.split(':');
      if (parts.length != 2) return encrypted;
      final iv = IV.fromBase64(parts[0]);
      return _encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return encrypted;
    }
  }
}
