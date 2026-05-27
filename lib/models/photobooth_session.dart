import 'dart:typed_data';
import 'sticker_item.dart';
import 'ar_frame.dart';

/// Layout types for photobooth — optimized for Story (9:16)
enum PhotoboothLayout {
  strip1x4, // 1 cột × 4 hàng (classic photobooth strip)
  grid2x2,  // 2 cột × 2 hàng
  grid2x4,  // 2 cột × 4 hàng
}

extension PhotoboothLayoutExt on PhotoboothLayout {
  int get photoCount {
    switch (this) {
      case PhotoboothLayout.strip1x4:
      case PhotoboothLayout.grid2x2:
        return 4;
      case PhotoboothLayout.grid2x4:
        return 8;
    }
  }

  String get label {
    switch (this) {
      case PhotoboothLayout.strip1x4:
        return '1×4 Strip';
      case PhotoboothLayout.grid2x2:
        return '2×2 Grid';
      case PhotoboothLayout.grid2x4:
        return '2×4 Grid';
    }
  }

  String get icon {
    switch (this) {
      case PhotoboothLayout.strip1x4:
        return '📋';
      case PhotoboothLayout.grid2x2:
        return '⊞';
      case PhotoboothLayout.grid2x4:
        return '▦';
    }
  }
}

/// Represents a single photobooth session
class PhotoboothSession {
  PhotoboothLayout layout;
  List<Uint8List> capturedPhotos;
  List<int> selectedIndices;
  List<StickerItem> stickers;
  ArFrame? selectedFrame;
  List<Uint8List> timelapseFrames;
  double zoomLevel;
  bool isFrontCamera;

  PhotoboothSession({
    this.layout = PhotoboothLayout.grid2x2,
    List<Uint8List>? capturedPhotos,
    List<int>? selectedIndices,
    List<StickerItem>? stickers,
    this.selectedFrame,
    List<Uint8List>? timelapseFrames,
    this.zoomLevel = 1.0,
    this.isFrontCamera = true,
  })  : capturedPhotos = capturedPhotos ?? [],
        selectedIndices = selectedIndices ?? [],
        stickers = stickers ?? [],
        timelapseFrames = timelapseFrames ?? [];

  int get requiredPhotoCount => layout.photoCount;
  bool get hasEnoughPhotos => selectedIndices.length >= requiredPhotoCount;
  int get currentPhotoNumber => capturedPhotos.length + 1;

  /// Get the photos selected for the layout in order
  List<Uint8List> get selectedPhotos {
    return selectedIndices
        .where((i) => i < capturedPhotos.length)
        .map((i) => capturedPhotos[i])
        .toList();
  }

  void addPhoto(Uint8List photo) {
    capturedPhotos.add(photo);
    // Auto-select if we haven't filled the layout yet
    if (selectedIndices.length < requiredPhotoCount) {
      selectedIndices.add(capturedPhotos.length - 1);
    }
  }

  void togglePhotoSelection(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else if (selectedIndices.length < requiredPhotoCount) {
      selectedIndices.add(index);
    }
  }

  bool addSticker(StickerItem sticker) {
    if (stickers.length >= 3) return false; // Max 3 stickers
    stickers.add(sticker);
    return true;
  }

  void removeSticker(int index) {
    if (index >= 0 && index < stickers.length) {
      stickers.removeAt(index);
    }
  }

  void removeLast() {
    if (stickers.isNotEmpty) {
      stickers.removeLast();
    }
  }

  void reset() {
    capturedPhotos.clear();
    selectedIndices.clear();
    stickers.clear();
    timelapseFrames.clear();
    zoomLevel = 1.0;
  }
}
