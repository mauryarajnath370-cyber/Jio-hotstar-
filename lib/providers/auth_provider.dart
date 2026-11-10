import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/utils/secure_storage_helper.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAdmin = false;
  DateTime? _adultUnlockedAt;

  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _currentUser != null;

  bool get isAdultSessionActive {
    if (_adultUnlockedAt == null) return false;
    final diff = DateTime.now().difference(_adultUnlockedAt!);
    return diff.inMinutes < 15;
  }

  void unlockAdultSession() {
    _adultUnlockedAt = DateTime.now();
    notifyListeners();
  }

  void lockAdultSession() {
    _adultUnlockedAt = null;
    notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentUser();
      _isAdmin = await SecureStorageHelper.isAdminLoggedIn();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInDirect(String email, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.signInDirect(email, name);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  void setAdminLoggedIn(bool value) {
    _isAdmin = value;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    await SecureStorageHelper.clearAdminSession();
    _currentUser = null;
    _isAdmin = false;
    _adultUnlockedAt = null;
    _isLoading = false;
    notifyListeners();
  }
}
