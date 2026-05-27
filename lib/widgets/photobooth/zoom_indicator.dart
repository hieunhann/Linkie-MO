import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Displays current zoom level badge (e.g., "1.0x", "2.5x")
/// Auto-fades out after 2 seconds of no change
class ZoomIndicator extends StatefulWidget {
  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double>? onZoomChanged;

  const ZoomIndicator({
    super.key,
    required this.zoomLevel,
    this.minZoom = 1.0,
    this.maxZoom = 8.0,
    this.onZoomChanged,
  });

  @override
  State<ZoomIndicator> createState() => _ZoomIndicatorState();
}

class _ZoomIndicatorState extends State<ZoomIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtl;
  late Animation<double> _fadeAnim;
  double _lastZoom = 1.0;
  bool _showSlider = false;

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
    _lastZoom = widget.zoomLevel;
  }

  @override
  void didUpdateWidget(ZoomIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoomLevel != widget.zoomLevel) {
      _fadeCtl.forward();
      _lastZoom = widget.zoomLevel;
      // Auto-hide after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.zoomLevel == _lastZoom) {
          _fadeCtl.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom badge
        GestureDetector(
          onTap: () => setState(() => _showSlider = !_showSlider),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderMedium),
              ),
              child: Text(
                '${widget.zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        // Optional zoom slider
        if (_showSlider) ...[
          const SizedBox(height: 8),
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  '${widget.minZoom.toStringAsFixed(0)}x',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryPink,
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 2,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: widget.zoomLevel,
                      min: widget.minZoom,
                      max: widget.maxZoom,
                      onChanged: widget.onZoomChanged,
                    ),
                  ),
                ),
                Text(
                  '${widget.maxZoom.toStringAsFixed(0)}x',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
