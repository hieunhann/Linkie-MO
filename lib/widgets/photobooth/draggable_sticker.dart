import 'package:flutter/material.dart';
import '../../models/sticker_item.dart';
import '../../utils/theme.dart';

/// A sticker widget that can be dragged, scaled, and rotated on the canvas.
/// Includes support for a precise delete zone at the bottom-center.
class DraggableSticker extends StatefulWidget {
  final StickerItem sticker;
  final Size canvasSize;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPositionChanged;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onRotationChanged;
  final VoidCallback? onDeleteZone;
  final Function(bool isDragging, bool inDeleteZone)? onDragStateChanged;

  const DraggableSticker({
    super.key,
    required this.sticker,
    required this.canvasSize,
    required this.isSelected,
    required this.onTap,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onDeleteZone,
    this.onDragStateChanged,
  });

  @override
  State<DraggableSticker> createState() => _DraggableStickerState();
}

class _DraggableStickerState extends State<DraggableSticker> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  bool _inDeleteZone = false;

  @override
  Widget build(BuildContext context) {
    final dx = widget.sticker.position.dx * widget.canvasSize.width;
    final dy = widget.sticker.position.dy * widget.canvasSize.height;

    return Positioned(
      left: dx - 40 * widget.sticker.scale,
      top: dy - 40 * widget.sticker.scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onScaleStart: (details) {
          _baseScale = widget.sticker.scale;
          _baseRotation = widget.sticker.rotation;
          
          // Notify parent drag starts
          widget.onDragStateChanged?.call(true, _inDeleteZone);
        },
        onScaleUpdate: (details) {
          // Pan (move)
          if (details.pointerCount == 1) {
            final newDx = (dx + details.focalPointDelta.dx) / widget.canvasSize.width;
            final newDy = (dy + details.focalPointDelta.dy) / widget.canvasSize.height;
            
            final clampedDx = newDx.clamp(0.02, 0.98);
            final clampedDy = newDy.clamp(0.02, 0.98);

            widget.onPositionChanged(Offset(clampedDx, clampedDy));

            // Precise delete zone: Bottom center only (Y > 0.82, X between 0.35 and 0.65)
            final inZone = clampedDy > 0.82 && clampedDx > 0.35 && clampedDx < 0.65;
            if (inZone != _inDeleteZone) {
              setState(() => _inDeleteZone = inZone);
              widget.onDragStateChanged?.call(true, inZone);
            }
          }

          // Pinch to scale + rotate
          if (details.pointerCount == 2) {
            widget.onScaleChanged(
              (_baseScale * details.scale).clamp(0.3, 3.0),
            );
            widget.onRotationChanged(
              _baseRotation + details.rotation,
            );
          }
        },
        onScaleEnd: (details) {
          // Notify parent drag ends
          widget.onDragStateChanged?.call(false, false);
          
          if (_inDeleteZone && widget.onDeleteZone != null) {
            widget.onDeleteZone!();
          }
          setState(() {
            _inDeleteZone = false;
          });
        },
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(widget.sticker.rotation)
            ..scale(widget.sticker.scale),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: widget.isSelected && !_inDeleteZone
                  ? Border.all(color: AppTheme.primaryPink.withOpacity(0.6), width: 1.5)
                  : (_inDeleteZone
                      ? Border.all(color: Colors.red.withOpacity(0.8), width: 1.5)
                      : null),
              color: _inDeleteZone
                  ? Colors.red.withOpacity(0.35)
                  : (widget.isSelected
                      ? Colors.white.withOpacity(0.05)
                      : Colors.transparent),
            ),
            child: widget.sticker.category == StickerCategory.text
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _inDeleteZone 
                          ? Colors.red.withOpacity(0.8)
                          : (widget.sticker.textColor ?? AppTheme.primaryPink).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.sticker.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : Text(
                    widget.sticker.content,
                    style: TextStyle(
                      fontSize: 40,
                      color: _inDeleteZone ? Colors.red.withOpacity(0.5) : null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
