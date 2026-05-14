import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _loading = false;
  final AuthService _authService = AuthService();

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  AuthProvider() {
    _loadUserFromStorage();
  }

  /// Load user from SharedPreferences on startup
  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(ApiConfig.userKey);
    if (stored != null) {
      try {
        _user = AuthUser.fromJson(jsonDecode(stored));
        notifyListeners();
      } catch (_) {
        // corrupted data
      }
    }
  }

  /// Save user to SharedPreferences
  Future<void> _saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
  }

  /// Extract user from JWT token
  AuthUser _extractUserFromToken(String token, {String? fallbackEmail}) {
    try {
      final payload = JwtDecoder.decode(token);

      // Extract claims from .NET JWT
      final dotNetRole = payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
          ?? payload['role'];
      final name = payload['FullName']
          ?? payload['name']
          ?? fallbackEmail?.split('@')[0]
          ?? 'User';
      final userId = payload['sub'] ?? payload['id'] ?? '';
      final email = payload['email'] ?? fallbackEmail ?? '';

      // Map backend role
      String role = 'user';
      if (dotNetRole != null) {
        final r = dotNetRole.toString().toLowerCase();
        if (r == 'admin') role = 'admin';
        else if (r == 'staff') role = 'staff';
        else if (r == 'led') role = 'led';
        else if (r == 'organizer') role = 'organizer';
      }

      return AuthUser(
        id: userId.toString(),
        name: name.toString(),
        email: email.toString(),
        role: role,
      );
    } catch (e) {
      // Fallback
      return AuthUser(
        id: '0',
        name: fallbackEmail?.split('@')[0] ?? 'User',
        email: fallbackEmail ?? '',
        role: 'user',
      );
    }
  }

  /// Login with email/password
  Future<AuthUser> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);

      if (data['accessToken'] != null) {
        final user = _extractUserFromToken(data['accessToken'], fallbackEmail: email);
        _user = user;
        await _saveUser(user);
        notifyListeners();
        return user;
      }

      throw Exception('No access token received');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Register and auto-login
  Future<AuthUser> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();

    try {
      await _authService.register(name, email, password);
      return await login(email, password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _authService.changePassword(currentPassword, newPassword);
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
