import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/ar_frame.dart';
import '../../models/photobooth_session.dart';
import '../../utils/theme.dart';
import 'layout_selection_screen.dart';
import 'capture_screen.dart';
import 'review_screen.dart';
import 'edit_screen.dart';
import 'save_screen.dart';

/// Main controller for the Photobooth flow (5 steps)
class PhotoboothSessionPage extends StatefulWidget {
  final String eventId;
  final String eventName;
  final List<ArFrame> frames;

  const PhotoboothSessionPage({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.frames,
  });

  @override
  State<PhotoboothSessionPage> createState() => _PhotoboothSessionPageState();
}

class _PhotoboothSessionPageState extends State<PhotoboothSessionPage> {
  late PhotoboothSession _session;
  int _currentStep = 0; // 0=Layout, 1=Capture, 2=Review, 3=Edit, 4=Save
  Uint8List? _compositeResult;

  static const _stepLabels = [
    'Layout',
    'Chụp ảnh',
    'Xem lại',
    'Sticker',
    'Lưu',
  ];

  @override
  void initState() {
    super.initState();
    _session = PhotoboothSession();
    if (widget.frames.isNotEmpty) {
      _session.selectedFrame = widget.frames.first;
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
  }

  void _onLayoutSelected(PhotoboothLayout layout, ArFrame? frame) {
    setState(() {
      _session.layout = layout;
      _session.selectedFrame = frame;
      _currentStep = 1;
    });
  }

  void _onCaptureComplete() {
    setState(() => _currentStep = 2);
  }

  void _onReviewComplete() {
    setState(() => _currentStep = 3);
  }

  void _onEditComplete(Uint8List composite) {
    setState(() {
      _compositeResult = composite;
      _currentStep = 4;
    });
  }

  void _onRestart() {
    setState(() {
      _session.reset();
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarkAlt,
      body: Column(
        children: [
          // Header with step indicator
          _buildHeader(context),
          // Current step screen
          Expanded(child: _buildCurrentStep()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            // Top row: back + title
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentStep > 0) {
                      _goToStep(_currentStep - 1);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 14),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Photobooth',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text('•', style: TextStyle(color: Colors.white.withOpacity(0.2))),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.eventName,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Step indicator
            _buildStepIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDone
                        ? AppTheme.primaryPink
                        : (isActive
                            ? AppTheme.primaryPink.withOpacity(0.6)
                            : Colors.white.withOpacity(0.08)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepLabels[i],
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDone ? AppTheme.primaryPink : AppTheme.textTertiary),
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return LayoutSelectionScreen(
          frames: widget.frames,
          selectedFrame: _session.selectedFrame,
          selectedLayout: _session.layout,
          onConfirm: _onLayoutSelected,
        );
      case 1:
        return CaptureScreen(
          session: _session,
          onComplete: _onCaptureComplete,
        );
      case 2:
        return ReviewScreen(
          session: _session,
          onConfirm: _onReviewComplete,
          onRetake: () => _goToStep(1),
        );
      case 3:
        return EditScreen(
          session: _session,
          eventName: widget.eventName,
          onComplete: _onEditComplete,
        );
      case 4:
        return SaveScreen(
          session: _session,
          compositeImage: _compositeResult!,
          eventName: widget.eventName,
          eventId: widget.eventId,
          onRestart: _onRestart,
        );
      default:
        return const SizedBox();
    }
  }
}
