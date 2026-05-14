import '../config/api_config.dart';

class PublicEvent {
  final String id;
  final String name;
  final String description;
  final String startTime;
  final String endTime;
  final String location;
  final int maxParticipants;
  final bool isWishwallEnabled;
  final String? thumbnailUrl;
  final String status;

  PublicEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxParticipants,
    required this.isWishwallEnabled,
    this.thumbnailUrl,
    required this.status,
  });

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    return PublicEvent(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      maxParticipants: json['maxParticipants'] ?? 0,
      isWishwallEnabled: json['isWishwallEnabled'] ?? false,
      thumbnailUrl: ApiConfig.ensureImageUrl(json['thumbnailUrl']?.toString()),
      status: json['status']?.toString() ?? '',
    );
  }

  /// Tính trạng thái sự kiện dựa trên thời gian hiện tại
  String get eventStatus {
    final now = DateTime.now();
    final start = DateTime.parse(startTime);
    final end = DateTime.parse(endTime);
    if (now.isAfter(start) && now.isBefore(end)) return 'live';
    if (now.isBefore(start)) return 'upcoming';
    return 'past';
  }
}
