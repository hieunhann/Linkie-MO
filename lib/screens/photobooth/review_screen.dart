import 'package:flutter/material.dart';
import '../../models/photobooth_session.dart';
import '../../utils/theme.dart';

/// Step 3: Review captured photos, select which ones to include, reorder
class ReviewScreen extends StatefulWidget {
  final PhotoboothSession session;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const ReviewScreen({
    super.key,
    required this.session,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final selectedCount = session.selectedIndices.length;
    final required = session.requiredPhotoCount;

    return Column(
      children: [
        // Counter
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn ảnh cho khung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nhấn vào ảnh để chọn/bỏ chọn',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selectedCount >= required
                      ? AppTheme.primaryPink.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedCount >= required
                        ? AppTheme.primaryPink.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$selectedCount/$required',
                  style: TextStyle(
                    color: selectedCount >= required
                        ? AppTheme.primaryPink
                        : Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: session.capturedPhotos.length,
            itemBuilder: (ctx, i) {
              final isSelected = session.selectedIndices.contains(i);
              final selectionOrder = session.selectedIndices.indexOf(i);

              return GestureDetector(
                onTap: () {
                  setState(() => session.togglePhotoSelection(i));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryPink : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryPink.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Photo
                        Image.memory(
                          session.capturedPhotos[i],
                          fit: BoxFit.cover,
                        ),

                        // Dark overlay for unselected
                        if (!isSelected)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                          ),

                        // Selection badge
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryPink,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPink.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${selectionOrder + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Layout preview (mini)
        if (selectedCount > 0) _buildMiniPreview(session),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              // Retake button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRetake,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Chụp thêm'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderMedium),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Continue button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: selectedCount >= required ? widget.onConfirm : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Tiếp theo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                    disabledForegroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPreview(PhotoboothSession session) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Preview: ',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
          ),
          const SizedBox(width: 8),
          ...session.selectedIndices.map((idx) {
            if (idx >= session.capturedPhotos.length) return const SizedBox();
            return Container(
              width: 48,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderMedium),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.memory(
                  session.capturedPhotos[idx],
                  fit: BoxFit.cover,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
