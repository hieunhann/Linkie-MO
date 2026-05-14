import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  /// Register a new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _api.postNoAuth('/Auth/register', body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password.trim(),
    });
    return response['data'] ?? response;
  }

  /// Login with email/password
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.postNoAuth('/Auth/login', body: {
      'email': email.trim().toLowerCase(),
      'password': password.trim(),
    });

    final data = response['data'] ?? response;

    // Save tokens
    final prefs = await SharedPreferences.getInstance();
    if (data['accessToken'] != null) {
      await prefs.setString(ApiConfig.accessTokenKey, data['accessToken']);
    }
    if (data['refreshToken'] != null) {
      await prefs.setString(ApiConfig.refreshTokenKey, data['refreshToken']);
    }

    return data;
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/Auth/changePassword', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    await _api.postNoAuth('/Auth/forgetPassword', body: {
      'email': email.trim().toLowerCase(),
    });
  }

  /// Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    await _api.postNoAuth('/Auth/resetPassword', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// Logout - clear tokens
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.accessTokenKey);
    await prefs.remove(ApiConfig.refreshTokenKey);
    await prefs.remove(ApiConfig.userKey);
  }
}
