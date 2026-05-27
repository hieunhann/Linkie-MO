import 'dart:ui';

/// Categories of stickers available in the photobooth
enum StickerCategory { emoji, decorative, text }

/// A sticker placed on the photobooth composite image
class StickerItem {
  /// Unique identifier
  final String id;

  /// Content to render (emoji char, text, or icon name)
  final String content;

  /// Category for UI grouping
  final StickerCategory category;

  /// Position on canvas (normalized 0.0 to 1.0)
  Offset position;

  /// Scale factor (1.0 = default ~80px at 1080w canvas)
  double scale;

  /// Rotation in radians
  double rotation;

  /// Font size for rendering (base size before scale)
  final double baseFontSize;

  /// Optional text color (for text stickers)
  final Color? textColor;

  StickerItem({
    required this.id,
    required this.content,
    required this.category,
    this.position = const Offset(0.5, 0.5),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.baseFontSize = 64.0,
    this.textColor,
  });

  StickerItem copyWith({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return StickerItem(
      id: id,
      content: content,
      category: category,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      baseFontSize: baseFontSize,
      textColor: textColor,
    );
  }
}

/// Catalog of all available stickers (bundled in app)
class StickerCatalog {
  static List<StickerItem> get emojiStickers => [
        _emoji('emoji_heart', '❤️'),
        _emoji('emoji_fire', '🔥'),
        _emoji('emoji_sparkles', '✨'),
        _emoji('emoji_star', '⭐'),
        _emoji('emoji_party', '🎉'),
        _emoji('emoji_love_eyes', '😍'),
        _emoji('emoji_cool', '😎'),
        _emoji('emoji_kiss', '💋'),
        _emoji('emoji_rainbow', '🌈'),
        _emoji('emoji_camera', '📸'),
      ];

  static List<StickerItem> get decorativeStickers => [
        _emoji('deco_flower', '🌸'),
        _emoji('deco_cherry', '🌸'),
        _emoji('deco_ribbon', '🎀'),
        _emoji('deco_crown', '👑'),
        _emoji('deco_butterfly', '🦋'),
        _emoji('deco_diamond', '💎'),
        _emoji('deco_music', '🎵'),
        _emoji('deco_confetti', '🎊'),
      ];

  static List<StickerItem> get textStickers => [
        _text('text_love', 'LOVE', const Color(0xFFE91E8C)),
        _text('text_bestday', 'BEST DAY', const Color(0xFF00BCD4)),
        _text('text_xoxo', 'XOXO', const Color(0xFFE91E8C)),
        _text('text_wow', 'WOW!', const Color(0xFFFF9800)),
        _text('text_mood', '#MOOD', const Color(0xFF9C27B0)),
      ];

  static StickerItem _emoji(String id, String emoji) => StickerItem(
        id: id,
        content: emoji,
        category: StickerCategory.emoji,
        baseFontSize: 64.0,
      );

  static StickerItem _text(String id, String text, Color color) => StickerItem(
        id: id,
        content: text,
        category: StickerCategory.text,
        baseFontSize: 40.0,
        textColor: color,
      );

  static List<StickerItem> getByCategory(StickerCategory category) {
    switch (category) {
      case StickerCategory.emoji:
        return emojiStickers;
      case StickerCategory.decorative:
        return decorativeStickers;
      case StickerCategory.text:
        return textStickers;
    }
  }
}
