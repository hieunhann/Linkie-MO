import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Progress bar showing "Ảnh 2/4" with dot indicators
class PhotoProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const PhotoProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera icon
          const Icon(Icons.camera_alt, color: AppTheme.primaryPink, size: 16),
          const SizedBox(width: 8),
          // Text counter
          Text(
            'Ảnh $current/$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          // Dot indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) {
              final isFilled = i < current;
              final isCurrent = i == current - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: isCurrent ? 16 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isFilled
                      ? AppTheme.primaryPink
                      : Colors.white.withOpacity(0.15),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPink.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
