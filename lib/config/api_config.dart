/// API configuration constants for Linkie Mobile App
class ApiConfig {
  // For Android Emulator, use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://10.0.2.2:5002/api';
  static const String apiOrigin = 'http://10.0.2.2:5002';
  static const String signalRHubUrl = 'http://10.0.2.2:5002/hubs/wishwall';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'linkie_user';

  /// Ensures a URL is absolute for images/assets
  static String ensureImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http') || url.startsWith('blob:')) return url;
    return url.startsWith('/') ? '$apiOrigin$url' : '$apiOrigin/$url';
  }
}
