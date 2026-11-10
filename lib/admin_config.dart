import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdminConfig {
  static const String salt = 'x7Kp9mQ2vL8nR4tY6wZ1aB3cD5eF7gH9';
  static const String dbUrl = 'https://jio-hotstar-premium-default-rtdb.firebaseio.com/';
  static const String adminUserHash = '3ebf2c1cd5172d05beeb7e78e5dd537f2ae83cbdc2abfa70e3657294e513ece3';
  static const String adminPassHash = '0fbd74e20682be11ed560b9487dc8159a08581d271451800dfa94cefcb5c349c';
}

class AdminAuthHelper {
  static String hashValue(String value, String salt) {
    final bytes = utf8.encode(value + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyAdmin(String username, String password) {
    final inputUserHash = hashValue(username, AdminConfig.salt);
    final inputPassHash = hashValue(password, AdminConfig.salt);
    return inputUserHash == AdminConfig.adminUserHash && inputPassHash == AdminConfig.adminPassHash;
  }
}
