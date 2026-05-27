import 'package:flutter/material.dart';
import '../../models/ar_frame.dart';
import '../../models/photobooth_session.dart';
import '../../config/api_config.dart';
import '../../utils/theme.dart';

/// Step 1: Choose layout (2x2, 1x4, 2x4) and AR Frame
class LayoutSelectionScreen extends StatefulWidget {
  final List<ArFrame> frames;
  final ArFrame? selectedFrame;
  final PhotoboothLayout selectedLayout;
  final void Function(PhotoboothLayout layout, ArFrame? frame) onConfirm;

  const LayoutSelectionScreen({
    super.key,
    required this.frames,
    this.selectedFrame,
    required this.selectedLayout,
    required this.onConfirm,
  });

  @override
  State<LayoutSelectionScreen> createState() => _LayoutSelectionScreenState();
}

class _LayoutSelectionScreenState extends State<LayoutSelectionScreen> {
  late PhotoboothLayout _layout;
  ArFrame? _frame;

  @override
  void initState() {
    super.initState();
    _layout = widget.selectedLayout;
    _frame = widget.selectedFrame;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Layout
          const Text(
            'Chọn bố cục',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn cách sắp xếp ảnh phù hợp cho Story',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Layout cards
          Row(
            children: PhotoboothLayout.values.map((layout) {
              final isSelected = _layout == layout;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _layout = layout),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? AppTheme.primaryPink.withOpacity(0.12)
                          : Colors.white.withOpacity(0.03),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryPink
                            : AppTheme.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Layout preview icon
                        SizedBox(
                          height: 100,
                          child: _buildLayoutPreview(layout, isSelected),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          layout.label,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryPink : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${layout.photoCount} ảnh',
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryPink.withOpacity(0.7)
                                : AppTheme.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Section: AR Frame
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn khung AR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_frame != null)
                GestureDetector(
                  onTap: () => setState(() => _frame = null),
                  child: Text(
                    'Bỏ chọn',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tùy chọn — Khung AR sẽ phủ lên toàn bộ ảnh',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Frame grid
          if (widget.frames.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Center(
                child: Text(
                  'Không có khung AR nào',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: widget.frames.length,
              itemBuilder: (ctx, i) {
                final frame = widget.frames[i];
                final isSelected = _frame?.id == frame.id;
                final url = frame.assetUrl.startsWith('http')
                    ? frame.assetUrl
                    : ApiConfig.ensureImageUrl(frame.assetUrl);

                return GestureDetector(
                  onTap: () => setState(() => _frame = frame),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? AppTheme.primaryPink.withOpacity(0.1)
                          : Colors.white.withOpacity(0.03),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryPink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            frame.name,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryPink : AppTheme.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_layout, _frame),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Bắt đầu chụp ${_layout.photoCount} ảnh',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build mini preview of the layout structure
  Widget _buildLayoutPreview(PhotoboothLayout layout, bool isSelected) {
    final color = isSelected ? AppTheme.primaryPink : Colors.white.withOpacity(0.15);

    switch (layout) {
      case PhotoboothLayout.strip1x4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: color.withOpacity(isSelected ? 0.3 : 0.15),
                border: Border.all(color: color.withOpacity(0.5), width: 1),
              ),
            ),
          )),
        );
      case PhotoboothLayout.grid2x2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (row) => Expanded(
            child: Row(
              children: List.generate(2, (col) => Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: color.withOpacity(isSelected ? 0.3 : 0.15),
                    border: Border.all(color: color.withOpacity(0.5), width: 1),
                  ),
                ),
              )),
            ),
          )),
        );
      case PhotoboothLayout.grid2x4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (row) => Expanded(
            child: Row(
              children: List.generate(2, (col) => Expanded(
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: color.withOpacity(isSelected ? 0.3 : 0.15),
                    border: Border.all(color: color.withOpacity(0.5), width: 1),
                  ),
                ),
              )),
            ),
          )),
        );
    }
  }
}
