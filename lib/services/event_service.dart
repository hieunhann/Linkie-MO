import '../models/public_event.dart';
import '../models/ar_frame.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _api = ApiClient();

  /// GET — Lấy danh sách sự kiện (public, không cần auth)
  Future<List<PublicEvent>> getAllEvents({String? status}) async {
    final queryParams = status != null ? {'status': status} : null;
    final response = await _api.get('/events', queryParams: queryParams?.cast<String, String>());
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((e) => PublicEvent.fromJson(e)).toList();
    }
    return [];
  }

  /// GET — Lấy chi tiết một sự kiện theo ID
  Future<PublicEvent> getEventById(String id) async {
    try {
      final response = await _api.get('/events/$id');
      final data = response['data'] ?? response;
      return PublicEvent.fromJson(data);
    } catch (e) {
      // Fallback: try from all events
      final allEvents = await getAllEvents();
      final found = allEvents.where((ev) => ev.id == id).firstOrNull;
      if (found != null) return found;
      rethrow;
    }
  }

  /// GET — Lấy danh sách Frame của một sự kiện
  Future<List<ArFrame>> getEventFrames(String eventId) async {
    final response = await _api.get('/events/$eventId/frames');
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((f) => ArFrame.fromJson(f)).toList();
    }
    return [];
  }

  /// POST — Ghi nhận lượt sử dụng Frame (silent)
  Future<void> recordFrameUsage(String eventId, String frameId) async {
    await _api.postSilent('/events/$eventId/frames/$frameId/usage', body: {});
  }
}
