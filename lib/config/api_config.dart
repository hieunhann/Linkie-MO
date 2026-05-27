/// API configuration constants for Linkie Mobile App
class ApiConfig {
  // For Android Emulator, use 10.0.2.2 instead of localhost
  // --- CONFIGURATION FOR PRODUCTION ---
  static const String baseUrl = 'https://linkie-be.onrender.com/api';
  static const String apiOrigin = 'https://linkie-be.onrender.com';
  static const String signalRHubUrl = 'https://linkie-be.onrender.com/hubs/wishwall';

  // --- CONFIGURATION FOR LOCAL TESTING (Uncomment to use & comment the Production blocks above) ---
  // Hướng dẫn: Đổi '192.168.x.x' thành IP máy tính chạy Backend của bạn khi test trên thiết bị thực,
  // hoặc sử dụng '10.0.2.2' cho Android Emulator, 'localhost' cho iOS Simulator.
  // static const String baseUrl = 'http://192.168.x.x:5002/api';
  // static const String apiOrigin = 'http://192.168.x.x:5002';
  // static const String signalRHubUrl = 'http://192.168.x.x:5002/hubs/wishwall';

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
