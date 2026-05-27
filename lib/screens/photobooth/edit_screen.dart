import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/photobooth_session.dart';
import '../../models/sticker_item.dart';
import '../../services/photobooth_compositor.dart';
import '../../utils/theme.dart';
import '../../widgets/photobooth/sticker_panel.dart';
import '../../widgets/photobooth/draggable_sticker.dart';

/// Step 4: Composite preview + sticker editor
class EditScreen extends StatefulWidget {
  final PhotoboothSession session;
  final String eventName;
  final ValueChanged<Uint8List> onComplete;

  const EditScreen({
    super.key,
    required this.session,
    required this.eventName,
    required this.onComplete,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  bool _compositing = true;
  Uint8List? _compositePreview;
  int _selectedStickerIdx = -1;
  bool _showDeleteZone = false;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    try {
      // Load frame overlay if selected
      Uint8List? frameBytes;
      final frame = widget.session.selectedFrame;
      if (frame != null) {
        final frameUrl = frame.assetUrl.startsWith('http')
            ? frame.assetUrl
            : ApiConfig.ensureImageUrl(frame.assetUrl);
        final response = await http.get(Uri.parse(frameUrl));
        frameBytes = response.bodyBytes;
      }

      final composite = await PhotoboothCompositor.compositePhotobooth(
        photos: widget.session.selectedPhotos,
        layout: widget.session.layout,
        frameOverlayBytes: frameBytes,
        stickers: [], // No stickers yet for preview
        isFrontCamera: widget.session.isFrontCamera,
      );

      if (mounted) {
        setState(() {
          _compositePreview = composite;
          _compositing = false;
        });
      }
    } catch (e) {
      debugPrint('Composite error: $e');
      if (mounted) {
        setState(() => _compositing = false);
      }
    }
  }

  Future<void> _onComplete() async {
    setState(() => _compositing = true);

    try {
      Uint8List? frameBytes;
      final frame = widget.session.selectedFrame;
      if (frame != null) {
        final frameUrl = frame.assetUrl.startsWith('http')
            ? frame.assetUrl
            : ApiConfig.ensureImageUrl(frame.assetUrl);
        final response = await http.get(Uri.parse(frameUrl));
        frameBytes = response.bodyBytes;
      }

      final finalComposite = await PhotoboothCompositor.compositePhotobooth(
        photos: widget.session.selectedPhotos,
        layout: widget.session.layout,
        frameOverlayBytes: frameBytes,
        stickers: widget.session.stickers,
        isFrontCamera: widget.session.isFrontCamera,
      );

      widget.onComplete(finalComposite);
    } catch (e) {
      debugPrint('Final composite error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo ảnh: $e')),
        );
        setState(() => _compositing = false);
      }
    }
  }

  void _addSticker(StickerItem catalogSticker) {
    final newSticker = StickerItem(
      id: '${catalogSticker.id}_${DateTime.now().millisecondsSinceEpoch}',
      content: catalogSticker.content,
      category: catalogSticker.category,
      baseFontSize: catalogSticker.baseFontSize,
      textColor: catalogSticker.textColor,
      position: const Offset(0.5, 0.4), // Center-ish
      scale: 1.0,
      rotation: 0.0,
    );

    setState(() {
      if (widget.session.addSticker(newSticker)) {
        _selectedStickerIdx = widget.session.stickers.length - 1;
      }
    });
  }

  void _removeSticker(int index) {
    setState(() {
      widget.session.removeSticker(index);
      _selectedStickerIdx = -1;
    });
  }

  void _undoLastSticker() {
    setState(() {
      widget.session.removeLast();
      _selectedStickerIdx = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_compositing && _compositePreview == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryPink),
            SizedBox(height: 16),
            Text(
              'Đang tạo ảnh composite...',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thêm sticker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (widget.session.stickers.isNotEmpty)
                    GestureDetector(
                      onTap: _undoLastSticker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.undo, color: AppTheme.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Hoàn tác',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Canvas with composite + stickers
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                key: _canvasKey,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStickerIdx = -1),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Composite preview
                          if (_compositePreview != null)
                            Image.memory(
                              _compositePreview!,
                              fit: BoxFit.cover,
                            ),

                          // Draggable stickers
                          ...widget.session.stickers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final sticker = entry.value;
                            return DraggableSticker(
                              sticker: sticker,
                              canvasSize: canvasSize,
                              isSelected: idx == _selectedStickerIdx,
                              onTap: () =>
                                  setState(() => _selectedStickerIdx = idx),
                              onPositionChanged: (pos) {
                                setState(() => sticker.position = pos);
                              },
                              onScaleChanged: (scale) {
                                setState(() => sticker.scale = scale);
                              },
                              onRotationChanged: (rotation) {
                                setState(() => sticker.rotation = rotation);
                              },
                              onDeleteZone: () => _removeSticker(idx),
                            );
                          }),

                          // Delete zone indicator
                          if (_showDeleteZone)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: canvasSize.height * 0.15,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.red.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Sticker panel
        StickerPanel(
          onStickerSelected: _addSticker,
          currentCount: widget.session.stickers.length,
          maxCount: 3,
        ),

        // Complete button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _compositing ? null : _onComplete,
              icon: _compositing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(_compositing ? 'Đang xử lý...' : 'Hoàn tất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
