class WishwallMessage {
  final String id;
  final String userName;
  final String message;
  final String sentiment;
  final String createdAt;

  WishwallMessage({
    required this.id,
    required this.userName,
    required this.message,
    required this.sentiment,
    required this.createdAt,
  });

  factory WishwallMessage.fromJson(Map<String, dynamic> json) {
    return WishwallMessage(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      sentiment: json['sentiment']?.toString() ?? 'Neutral',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userName': userName,
    'message': message,
    'sentiment': sentiment,
    'createdAt': createdAt,
  };

  WishwallMessage copyWith({
    String? id,
    String? userName,
    String? message,
    String? sentiment,
    String? createdAt,
  }) {
    return WishwallMessage(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      sentiment: sentiment ?? this.sentiment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
