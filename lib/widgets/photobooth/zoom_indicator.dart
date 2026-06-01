import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// A professional zoom control panel that stays visible,
/// providing quick zoom buttons (0.5x, 1x, 2x) and a smooth linear slider.
class ZoomIndicator extends StatelessWidget {
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onZoomChanged;

  const ZoomIndicator({
    super.key,
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Generate quick zoom presets
    final presets = <double>[];
    
    // Add 0.5x/ultrawide if supported
    if (minZoom < 1.0) {
      presets.add(minZoom);
    }
    
    // Always include 1.0x and 2.0x (clamped appropriately)
    if (minZoom <= 1.0 && maxZoom >= 1.0 && !presets.contains(1.0)) {
      presets.add(1.0);
    }
    
    const double target2x = 2.0;
    if (maxZoom >= target2x && !presets.contains(target2x)) {
      presets.add(target2x);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Zoom Buttons Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: presets.map((preset) {
              final isSelected = (zoomLevel - preset).abs() < 0.05;
              String label = '${preset.toStringAsFixed(1)}x';
              if (preset == minZoom && minZoom < 1.0) label = '0.5x';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onZoomChanged(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppTheme.primaryPink
                          : Colors.black.withOpacity(0.4),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),

          // Slider for fine-grained zoom adjustment
          SizedBox(
            width: 140,
            height: 20,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryPink,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 2,
                overlayColor: AppTheme.primaryPink.withOpacity(0.2),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: zoomLevel.clamp(minZoom, maxZoom),
                min: minZoom,
                max: maxZoom > minZoom ? maxZoom : minZoom + 1.0,
                onChanged: onZoomChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
