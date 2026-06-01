import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import '../models/photobooth_session.dart';
import '../models/sticker_item.dart';

/// High-quality image compositing engine for Photobooth
/// Output: 1080×1920 (9:16 Story ratio)
class PhotoboothCompositor {
  static const int canvasWidth = 1080;
  static const int canvasHeight = 1920;
  static const double _gap = 20.0;
  static const double _padding = 24.0;
  static const double _cornerRadius = 16.0;

  /// Main composite: photos + layout + frame overlay + stickers
  /// Runs heavy work — call from compute() isolate if needed
  static Future<Uint8List> compositePhotobooth({
    required List<Uint8List> photos,
    required PhotoboothLayout layout,
    Uint8List? frameOverlayBytes,
    List<StickerItem> stickers = const [],
    bool isFrontCamera = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(canvasWidth.toDouble(), canvasHeight.toDouble());

    // 1. Draw dark gradient background
    _drawBackground(canvas, size);

    // 2. Draw photos into layout cells
    final decodedPhotos = await _decodeImages(photos);
    final cells = _getCellRects(layout);

    for (int i = 0; i < cells.length && i < decodedPhotos.length; i++) {
      _drawPhotoInCell(canvas, decodedPhotos[i], cells[i], isFrontCamera);
    }

    // Dispose decoded photos
    for (final img in decodedPhotos) {
      img.dispose();
    }

    // 3. Draw AR Frame overlay (cover entire canvas)
    if (frameOverlayBytes != null) {
      final frameImage = await _decodeImage(frameOverlayBytes);
      canvas.drawImageRect(
        frameImage,
        Rect.fromLTWH(0, 0, frameImage.width.toDouble(), frameImage.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = ui.FilterQuality.high,
      );
      frameImage.dispose();
    }

    // 4. Draw stickers
    for (final sticker in stickers) {
      _drawSticker(canvas, sticker, size);
    }

    // 5. Encode to JPEG
    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth, canvasHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Draw gradient background
  static void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D1117),
          Color(0xFF161B22),
          Color(0xFF0D1117),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }

  /// Get cell rectangles for each layout type
  static List<Rect> _getCellRects(PhotoboothLayout layout) {
    switch (layout) {
      case PhotoboothLayout.strip1x4:
        return _strip1x4Cells();
      case PhotoboothLayout.grid2x2:
        return _grid2x2Cells();
      case PhotoboothLayout.grid2x4:
        return _grid2x4Cells();
    }
  }

  /// 1×4 Strip layout: 1 column, 4 rows
  static List<Rect> _strip1x4Cells() {
    final cellW = canvasWidth - _padding * 2;
    final totalGaps = _gap * 3;
    final cellH = (canvasHeight - _padding * 2 - totalGaps) / 4;
    final cells = <Rect>[];
    for (int row = 0; row < 4; row++) {
      final y = _padding + row * (cellH + _gap);
      cells.add(Rect.fromLTWH(_padding, y, cellW, cellH));
    }
    return cells;
  }

  /// 2×2 Grid layout: 2 columns, 2 rows
  static List<Rect> _grid2x2Cells() {
    final cellW = (canvasWidth - _padding * 2 - _gap) / 2;
    final cellH = (canvasHeight - _padding * 2 - _gap) / 2;
    final cells = <Rect>[];
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) {
        final x = _padding + col * (cellW + _gap);
        final y = _padding + row * (cellH + _gap);
        cells.add(Rect.fromLTWH(x, y, cellW, cellH));
      }
    }
    return cells;
  }

  /// 2×4 Grid layout: 2 columns, 4 rows
  static List<Rect> _grid2x4Cells() {
    final cellW = (canvasWidth - _padding * 2 - _gap) / 2;
    final totalGaps = _gap * 3;
    final cellH = (canvasHeight - _padding * 2 - totalGaps) / 4;
    final cells = <Rect>[];
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 2; col++) {
        final x = _padding + col * (cellW + _gap);
        final y = _padding + row * (cellH + _gap);
        cells.add(Rect.fromLTWH(x, y, cellW, cellH));
      }
    }
    return cells;
  }

  /// Draw a single photo into a cell with rounded corners and cover fit
  static void _drawPhotoInCell(
    Canvas canvas,
    ui.Image photo,
    Rect cell,
    bool flipHorizontal,
  ) {
    canvas.save();

    // Clip to rounded rect
    final rrect = RRect.fromRectAndRadius(cell, Radius.circular(_cornerRadius));
    canvas.clipRRect(rrect);

    // Calculate cover fit (crop to fill)
    final photoAspect = photo.width / photo.height;
    final cellAspect = cell.width / cell.height;

    Rect srcRect;
    if (photoAspect > cellAspect) {
      // Photo is wider — crop sides
      final srcH = photo.height.toDouble();
      final srcW = srcH * cellAspect;
      final srcX = (photo.width - srcW) / 2;
      srcRect = Rect.fromLTWH(srcX, 0, srcW, srcH);
    } else {
      // Photo is taller — crop top/bottom
      final srcW = photo.width.toDouble();
      final srcH = srcW / cellAspect;
      final srcY = (photo.height - srcH) / 2;
      srcRect = Rect.fromLTWH(0, srcY, srcW, srcH);
    }

    // Flip horizontal for front camera
    if (flipHorizontal) {
      canvas.translate(cell.left + cell.width, cell.top);
      canvas.scale(-1, 1);
      canvas.drawImageRect(
        photo,
        srcRect,
        Rect.fromLTWH(0, 0, cell.width, cell.height),
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      canvas.drawImageRect(
        photo,
        srcRect,
        cell,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    }

    canvas.restore();

    // Draw subtle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  /// Draw a sticker (emoji or text) on canvas
  static void _drawSticker(Canvas canvas, StickerItem sticker, Size canvasSize) {
    canvas.save();

    // Convert normalized position to canvas coordinates
    final dx = sticker.position.dx * canvasSize.width;
    final dy = sticker.position.dy * canvasSize.height;

    canvas.translate(dx, dy);
    canvas.rotate(sticker.rotation);
    canvas.scale(sticker.scale);

    final fontSize = sticker.baseFontSize * 2; // Scale up for 1080w canvas

    if (sticker.category == StickerCategory.text) {
      // Draw styled text sticker
      _drawTextSticker(canvas, sticker, fontSize);
    } else {
      // Draw emoji sticker
      final textPainter = TextPainter(
        text: TextSpan(
          text: sticker.content,
          style: TextStyle(fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    }

    canvas.restore();
  }

  /// Draw a styled text sticker with background pill and shadow
  static void _drawTextSticker(Canvas canvas, StickerItem sticker, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: sticker.content,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 4,
          shadows: [
            Shadow(
              color: (sticker.textColor ?? const Color(0xFFE91E8C)).withOpacity(0.6),
              blurRadius: 20,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: textPainter.width + 40,
        height: textPainter.height + 16,
      ),
      const Radius.circular(24),
    );
    final bgPaint = Paint()
      ..color = (sticker.textColor ?? const Color(0xFFE91E8C)).withOpacity(0.85);
    canvas.drawRRect(bgRect, bgPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  /// Save timelapse frames as individual JPEG files to a directory
  /// Returns the directory path containing frames
  static Future<String> saveTimelapseFrames({
    required List<Uint8List> frames,
    required String outputDir,
  }) async {
    final dir = Directory('$outputDir/timelapse_frames');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    for (int i = 0; i < frames.length; i++) {
      final file = File('${dir.path}/frame_${i.toString().padLeft(4, '0')}.jpg');
      await file.writeAsBytes(frames[i]);
    }

    return dir.path;
  }

  /// Generate MP4 timelapse using ffmpeg
  /// Returns the output MP4 file path
  static Future<String?> generateTimelapseMp4({
    required List<Uint8List> frames,
    required String outputDir,
    int inputFps = 2,
    int outputFps = 30,
  }) async {
    if (frames.isEmpty) return null;

    try {
      // Save frames to disk
      final framesDir = await saveTimelapseFrames(
        frames: frames,
        outputDir: outputDir,
      );

      final outputPath = '$outputDir/timelapse_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Try with libx264 first (requires GPL build for H.264)
      final commandX264 =
          '-y -framerate $inputFps -i $framesDir/frame_%04d.jpg '
          '-vf scale=540:960,fps=$outputFps '
          '-c:v libx264 -preset ultrafast -pix_fmt yuv420p '
          '-movflags +faststart '
          '$outputPath';

      // Fallback with mpeg4 (works on all LGPL/GPL builds, 100% guaranteed support)
      final commandMpeg4 =
          '-y -framerate $inputFps -i $framesDir/frame_%04d.jpg '
          '-vf scale=540:960,fps=$outputFps '
          '-c:v mpeg4 -q:v 3 -pix_fmt yuv420p '
          '$outputPath';

      try {
        debugPrint('Timelapse: Attempting encoding with libx264 (GPL)...');
        final successX264 = await _runFfmpeg(commandX264);
        if (successX264) {
          await Directory(framesDir).delete(recursive: true);
          return outputPath;
        }
      } catch (e) {
        debugPrint('Timelapse: libx264 encoding attempt threw exception: $e');
      }

      try {
        debugPrint('Timelapse: Falling back to mpeg4 (LGPL)...');
        final successMpeg4 = await _runFfmpeg(commandMpeg4);
        if (successMpeg4) {
          await Directory(framesDir).delete(recursive: true);
          return outputPath;
        }
      } catch (e) {
        debugPrint('Timelapse: mpeg4 encoding attempt threw exception: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Error generating timelapse: $e');
      return null;
    }
  }

  /// Try to run ffmpeg command — returns true if successful
  static Future<bool> _runFfmpeg(String command) async {
    try {
      debugPrint('FFmpeg command: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('FFmpeg execution succeeded!');
        return true;
      } else {
        final state = await session.getState();
        final failStackTrace = await session.getFailStackTrace();
        debugPrint('FFmpeg execution failed with state $state, failStackTrace: $failStackTrace');
        return false;
      }
    } catch (e) {
      debugPrint('FFmpeg execution failed: $e');
      return false;
    }
  }

  /// Resize a photo for timelapse (lower res to save RAM)
  static Future<Uint8List> resizeForTimelapse(Uint8List photoBytes) async {
    final codec = await ui.instantiateImageCodec(
      photoBytes,
      targetWidth: 540,
      targetHeight: 960,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 540, 960),
      Paint()..filterQuality = ui.FilterQuality.medium,
    );

    final picture = recorder.endRecording();
    final resized = await picture.toImage(540, 960);
    final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    resized.dispose();

    return byteData!.buffer.asUint8List();
  }

  // ── Helper methods ──

  static Future<List<ui.Image>> _decodeImages(List<Uint8List> imageBytes) async {
    final images = <ui.Image>[];
    for (final bytes in imageBytes) {
      images.add(await _decodeImage(bytes));
    }
    return images;
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
