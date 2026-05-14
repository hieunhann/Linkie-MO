import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/wishwall_message.dart';
import 'api_client.dart';

class WishwallService {
  final ApiClient _api = ApiClient();

  /// GET — Lấy danh sách tin nhắn đã duyệt
  Future<List<WishwallMessage>> getMessages(String eventId) async {
    final response = await _api.get('/events/$eventId/wishwall');
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((m) => WishwallMessage.fromJson(m)).toList();
    }
    return [];
  }

  /// POST — Gửi tin nhắn mới
  Future<WishwallMessage?> sendMessage(String eventId, String message) async {
    final response = await _api.post('/events/$eventId/wishwall', body: {
      'message': message,
    });
    final data = response['data'] ?? response;
    if (data is Map<String, dynamic>) {
      return WishwallMessage.fromJson(data);
    }
    return null;
  }

  /// Creates a SignalR HubConnection to the Wishwall hub
  Future<HubConnection> createConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.accessTokenKey) ?? '';

    final connection = HubConnectionBuilder()
        .withUrl(
          ApiConfig.signalRHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    return connection;
  }
}
