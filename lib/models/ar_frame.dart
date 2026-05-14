class ArFrame {
  final String id;
  final String name;
  final String assetUrl;
  final bool isActive;

  ArFrame({
    required this.id,
    required this.name,
    required this.assetUrl,
    required this.isActive,
  });

  factory ArFrame.fromJson(Map<String, dynamic> json) {
    return ArFrame(
      id: json['id']?.toString() ?? '',
      name: json['frameName']?.toString() ?? json['name']?.toString() ?? '',
      assetUrl: json['frameUrl']?.toString() ?? json['assetUrl']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
