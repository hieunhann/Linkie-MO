import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/photobooth_session.dart';
import '../../services/photobooth_compositor.dart';
import '../../utils/theme.dart';
import '../../widgets/photobooth/zoom_indicator.dart';
import '../../widgets/photobooth/capture_countdown.dart';
import '../../widgets/photobooth/photo_progress_bar.dart';

/// Step 2: Camera capture with zoom, countdown, progress, and timelapse recording
class CaptureScreen extends StatefulWidget {
  final PhotoboothSession session;
  final VoidCallback onComplete;

  const CaptureScreen({
    super.key,
    required this.session,
    required this.onComplete,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _cameraCtl;
  List<CameraDescription> _cameras = [];
  int _cameraIdx = 0;
  bool _loading = true;
  String _error = '';
  bool _flashVisible = false;
  bool _showCountdown = false;
  bool _autoCapture = false;
  Timer? _autoCaptureTimer;
  Timer? _timelapseTimer;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseScaleZoom = 1.0;

  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() {
        _error = 'Không tìm thấy camera.';
        _loading = false;
      });
      return;
    }

    // Start with front camera
    _cameraIdx = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIdx < 0) _cameraIdx = 0;

    await _startCamera();
    if (mounted) setState(() => _loading = false);

    // Start timelapse recording
    _startTimelapseRecording();
  }

  Future<void> _startCamera() async {
    _cameraCtl?.dispose();
    _cameraCtl = CameraController(
      _cameras[_cameraIdx],
      ResolutionPreset.high, // High 1080p is fast, crisp, and RAM efficient
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraCtl!.initialize();
      _minZoom = await _cameraCtl!.getMinZoomLevel();
      _maxZoom = await _cameraCtl!.getMaxZoomLevel();
      _currentZoom = _minZoom;
      widget.session.isFrontCamera =
          _cameras[_cameraIdx].lensDirection == CameraLensDirection.front;

      // Apply initial FlashMode for back camera
      if (!widget.session.isFrontCamera) {
        await _cameraCtl!.setFlashMode(_flashMode);
      } else {
        await _cameraCtl!.setFlashMode(FlashMode.off);
      }

      if (mounted) setState(() => _error = '');
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi camera: $e');
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _cameraIdx = (_cameraIdx + 1) % _cameras.length;
    _startCamera();
  }

  void _startTimelapseRecording() {
    _timelapseTimer?.cancel();
    // Record every 1.5 seconds instead of 500ms to prevent camera buffer overload
    _timelapseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (_cameraCtl == null || 
          !_cameraCtl!.value.isInitialized || 
          _isCapturing || 
          _showCountdown) return;
      try {
        final photo = await _cameraCtl!.takePicture();
        final bytes = await photo.readAsBytes();
        final resized = await PhotoboothCompositor.resizeForTimelapse(bytes);
        
        // Final sanity check before adding frame
        if (mounted && !_isCapturing && !_showCountdown) {
          widget.session.timelapseFrames.add(resized);
        }
      } catch (_) {
        // Skip frame if camera is busy or disposed
      }
    });
  }

  Future<void> _toggleFlash() async {
    if (_cameraCtl == null || !_cameraCtl!.value.isInitialized) return;
    if (_cameras[_cameraIdx].lensDirection == CameraLensDirection.front) return;

    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.always;
    } else if (_flashMode == FlashMode.always) {
      newMode = FlashMode.auto;
    } else {
      newMode = FlashMode.off;
    }

    try {
      await _cameraCtl!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  Future<void> _handleZoom(double scale) async {
    if (_cameraCtl == null) return;
    final newZoom = (_baseScaleZoom * scale).clamp(_minZoom, _maxZoom);
    await _cameraCtl!.setZoomLevel(newZoom);
    setState(() {
      _currentZoom = newZoom;
      widget.session.zoomLevel = newZoom;
    });
  }

  void _startCapture() {
    // Immediately stop timelapse timer to free camera resources during countdown
    _timelapseTimer?.cancel();
    setState(() => _showCountdown = true);
  }

  Future<void> _doCapture() async {
    if (_cameraCtl == null || !_cameraCtl!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _flashVisible = true; // Trigger white flash screen IMMEDIATELY for instant feedback
    });

    // Animate white flash overlay fade out quickly
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _flashVisible = false);
    });

    try {
      // Ensure timelapse is definitely stopped during takePicture
      _timelapseTimer?.cancel();

      final photo = await _cameraCtl!.takePicture();
      final bytes = await photo.readAsBytes();

      widget.session.addPhoto(bytes);

      // Check if we have enough photos
      if (widget.session.capturedPhotos.length >= widget.session.requiredPhotoCount) {
        // Stop timelapse and auto-capture completely
        _autoCaptureTimer?.cancel();
        _timelapseTimer?.cancel();
        await Future.delayed(const Duration(milliseconds: 300));
        // Reset _isCapturing before navigating away to prevent stuck state
        if (mounted) {
          setState(() => _isCapturing = false);
          widget.onComplete();
        }
        return;
      }

      setState(() {
        _isCapturing = false;
      });

      // Resume timelapse recording for subsequent photo capture
      _startTimelapseRecording();

      // Auto-capture next photo
      if (_autoCapture) {
        _autoCaptureTimer = Timer(const Duration(seconds: 3), _startCapture);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      setState(() {
        _isCapturing = false;
        _flashVisible = false;
      });
      // Safety resume
      _startTimelapseRecording();
      if (_autoCapture) {
        _autoCaptureTimer = Timer(const Duration(seconds: 3), _startCapture);
      }
    }
  }

  void _toggleAutoCapture() {
    setState(() {
      _autoCapture = !_autoCapture;
      if (_autoCapture) {
        _autoCaptureTimer = Timer(const Duration(seconds: 3), _startCapture);
      } else {
        _autoCaptureTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    _timelapseTimer?.cancel();
    _cameraCtl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryTealLight),
            SizedBox(height: 16),
            Text('Đang khởi động Camera...', style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: PhotoProgressBar(
            current: widget.session.capturedPhotos.length,
            total: widget.session.requiredPhotoCount,
          ),
        ),

        // Camera viewfinder
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                if (_error.isNotEmpty)
                  Center(
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  )
                else if (_cameraCtl != null && _cameraCtl!.value.isInitialized)
                  GestureDetector(
                    onScaleStart: (_) => _baseScaleZoom = _currentZoom,
                    onScaleUpdate: (details) => _handleZoom(details.scale),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: _cameras[_cameraIdx].lensDirection ==
                              CameraLensDirection.front
                          ? (Matrix4.identity()..scale(-1.0, 1.0))
                          : Matrix4.identity(),
                      child: CameraPreview(_cameraCtl!),
                    ),
                  ),

                // Flash effect
                if (_flashVisible)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _flashVisible ? 1.0 : 0.0,
                    curve: Curves.easeOutExpo,
                    child: Container(color: Colors.white.withOpacity(0.85)),
                  ),

                // Countdown overlay
                if (_showCountdown)
                  CaptureCountdown(
                    onComplete: () {
                      setState(() => _showCountdown = false);
                      _doCapture();
                    },
                  ),

                // Zoom indicator (bottom center)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ZoomIndicator(
                      zoomLevel: _currentZoom,
                      minZoom: _minZoom,
                      maxZoom: _maxZoom,
                      onZoomChanged: (zoom) async {
                        await _cameraCtl?.setZoomLevel(zoom);
                        setState(() {
                          _currentZoom = zoom;
                          widget.session.zoomLevel = zoom;
                        });
                      },
                    ),
                  ),
                ),

                // Layout label (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.session.layout.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Flash toggle (top right, left of timelapse REC)
                if (_cameras.isNotEmpty &&
                    _cameras[_cameraIdx].lensDirection != CameraLensDirection.front)
                  Positioned(
                    top: 12,
                    right: 80,
                    child: GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _flashMode != FlashMode.off
                                ? AppTheme.primaryPink
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _flashMode == FlashMode.always
                                  ? Icons.flash_on
                                  : _flashMode == FlashMode.auto
                                      ? Icons.flash_auto
                                      : Icons.flash_off,
                              color: _flashMode != FlashMode.off
                                  ? AppTheme.primaryPink
                                  : Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _flashMode == FlashMode.always
                                  ? 'FLASH: BẬT'
                                  : _flashMode == FlashMode.auto
                                      ? 'FLASH: AUTO'
                                      : 'FLASH: TẮT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Timelapse indicator (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Auto-capture toggle
              GestureDetector(
                onTap: _toggleAutoCapture,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _autoCapture
                        ? AppTheme.primaryPink.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: _autoCapture
                          ? AppTheme.primaryPink
                          : AppTheme.borderMedium,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: _autoCapture ? AppTheme.primaryPink : Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      Text(
                        _autoCapture ? 'TỰ ĐỘNG' : 'TỰ ĐỘNG',
                        style: TextStyle(
                          color: _autoCapture
                              ? AppTheme.primaryPink
                              : Colors.white.withOpacity(0.4),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Capture button
              GestureDetector(
                onTap: (_showCountdown || _isCapturing) ? null : _startCapture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryPink, width: 4),
                    color: AppTheme.bgDarkAlt,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_showCountdown || _isCapturing)
                            ? Colors.grey
                            : AppTheme.primaryPink.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.camera, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

              // Switch camera
              GestureDetector(
                onTap: _toggleCamera,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: AppTheme.borderMedium),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cameraswitch, color: Colors.white.withOpacity(0.6), size: 20),
                      Text(
                        'ĐỔI CAM',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
