import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/api_config.dart';
import '../providers/event_provider.dart';
import '../models/ar_frame.dart';
import '../utils/theme.dart';
import 'package:http/http.dart' as http;
import 'photobooth/photobooth_session_page.dart';

/// Camera page with 2 modes: AR Frame (original) and Photobooth (new)
class CameraFramePage extends StatefulWidget {
  final String eventId;
  const CameraFramePage({super.key, required this.eventId});
  @override
  State<CameraFramePage> createState() => _CameraFramePageState();
}

class _CameraFramePageState extends State<CameraFramePage> {
  // ── Shared state ──
  CameraController? _cameraCtl;
  List<CameraDescription> _cameras = [];
  bool _loading = true;
  int _cameraIdx = 0;
  String _eventName = 'Sự kiện';
  String _cameraError = '';
  List<ArFrame> _frames = [];

  // ── Mode ──
  int _modeIndex = 0; // 0 = AR Frame, 1 = Photobooth

  // ── AR Frame mode state ──
  bool _flashVisible = false;
  bool _showFramePicker = false;
  int _selectedFrameIdx = 0;

  // ── Camera zoom state ──
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseScaleZoom = 1.0;
  bool _showZoomBadge = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _cameraError = 'Không thể truy cập camera. Vui lòng cấp quyền camera.';
        _loading = false;
      });
      return;
    }

    final ep = context.read<EventProvider>();
    await ep.fetchEventById(widget.eventId);
    await ep.fetchEventFrames(widget.eventId);
    _eventName = ep.currentEvent?.name ?? 'Sự kiện';
    _frames = ep.frames;

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() {
        _cameraError = 'Không tìm thấy camera.';
        _loading = false;
      });
      return;
    }
    _cameraIdx = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIdx < 0) _cameraIdx = 0;
    await _startCamera();
    setState(() => _loading = false);
  }

  Future<void> _startCamera() async {
    _cameraCtl?.dispose();
    _cameraCtl = CameraController(
      _cameras[_cameraIdx],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    try {
      await _cameraCtl!.initialize();
      _minZoom = await _cameraCtl!.getMinZoomLevel();
      _maxZoom = await _cameraCtl!.getMaxZoomLevel();
      _currentZoom = _minZoom;
      if (mounted) setState(() => _cameraError = '');
    } catch (e) {
      setState(() => _cameraError = 'Lỗi khởi tạo camera: $e');
    }
  }

  void _toggleCamera() {
    if (_cameras.length < 2) return;
    _cameraIdx = (_cameraIdx + 1) % _cameras.length;
    _startCamera();
  }

  Future<void> _handleZoom(double scale) async {
    if (_cameraCtl == null) return;
    final newZoom = (_baseScaleZoom * scale).clamp(_minZoom, _maxZoom);
    await _cameraCtl!.setZoomLevel(newZoom);
    setState(() {
      _currentZoom = newZoom;
      _showZoomBadge = true;
    });
    // Auto-hide zoom badge after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _currentZoom == newZoom) {
        setState(() => _showZoomBadge = false);
      }
    });
  }

  Future<void> _handleCapture() async {
    if (_cameraCtl == null || !_cameraCtl!.value.isInitialized || _frames.isEmpty) return;

    try {
      final XFile photo = await _cameraCtl!.takePicture();
      final photoBytes = await photo.readAsBytes();
      final frame = _frames[_selectedFrameIdx];

      setState(() => _flashVisible = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashVisible = false);
      });

      final frameUrl = frame.assetUrl.startsWith('http')
          ? frame.assetUrl
          : ApiConfig.ensureImageUrl(frame.assetUrl);
      final frameResponse = await http.get(Uri.parse(frameUrl));
      final frameBytes = frameResponse.bodyBytes;

      final composited = await _compositeImages(photoBytes, frameBytes);

      if (Platform.isAndroid) {
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photos.request();
      }
      final fileName =
          'linkie-${_eventName.replaceAll(' ', '-').toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await ImageGallerySaverPlus.saveImage(composited, name: fileName, quality: 92);

      context.read<EventProvider>().recordFrameUsage(widget.eventId, frame.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh đã được lưu vào thư viện! 📸'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  Future<Uint8List> _compositeImages(Uint8List photoBytes, Uint8List frameBytes) async {
    final codec1 = await ui.instantiateImageCodec(photoBytes);
    final frame1 = await codec1.getNextFrame();
    final photo = frame1.image;

    final codec2 = await ui.instantiateImageCodec(frameBytes);
    final frame2 = await codec2.getNextFrame();
    final overlay = frame2.image;

    final size = Size(overlay.width.toDouble(), overlay.height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final isFront = _cameras[_cameraIdx].lensDirection == CameraLensDirection.front;
    if (isFront) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = ui.FilterQuality.high,
    );

    if (isFront) canvas.restore();

    canvas.drawImage(overlay, Offset.zero, Paint()..filterQuality = ui.FilterQuality.high);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _openPhotobooth() {
    // Dispose camera before navigating (Photobooth has its own camera)
    _cameraCtl?.dispose();
    _cameraCtl = null;

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => PhotoboothSessionPage(
          eventId: widget.eventId,
          eventName: _eventName,
          frames: _frames,
        ),
      ),
    )
        .then((_) {
      // Restart camera when returning
      _startCamera();
    });
  }

  @override
  void dispose() {
    _cameraCtl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDarkAlt,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppTheme.primaryTealLight),
            SizedBox(height: 16),
            Text('Đang khởi động Camera AR...',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDarkAlt,
      body: Stack(
        children: [
          Column(
            children: [
              // Header with mode selector
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    children: [
                      // Top row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: const Icon(Icons.chevron_left,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Camera',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('•',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.2))),
                          ),
                          Expanded(
                            child: Text(_eventName,
                                style: const TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 10,
                                    letterSpacing: 1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Mode selector tabs
                      _buildModeSelector(),
                    ],
                  ),
                ),
              ),

              // Camera viewfinder (AR Frame mode)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cameraError.isNotEmpty)
                        Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.1),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.no_photography,
                                      color: Colors.red, size: 32),
                                ),
                                const SizedBox(height: 16),
                                Text(_cameraError,
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center),
                              ]),
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

                      // Frame overlay
                      if (_frames.isNotEmpty && _selectedFrameIdx < _frames.length)
                        Positioned.fill(
                          child: Image.network(
                            _frames[_selectedFrameIdx].assetUrl.startsWith('http')
                                ? _frames[_selectedFrameIdx].assetUrl
                                : ApiConfig.ensureImageUrl(
                                    _frames[_selectedFrameIdx].assetUrl),
                            fit: BoxFit.fill,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),

                      // Flash
                      if (_flashVisible)
                        Container(color: Colors.white.withOpacity(0.8)),

                      // Zoom badge
                      if (_showZoomBadge)
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _showZoomBadge ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.borderMedium),
                                ),
                                child: Text(
                                  '${_currentZoom.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Frame name tag
                      if (_frames.isNotEmpty && !_showFramePicker)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderMedium),
                              ),
                              child: Text(
                                _frames[_selectedFrameIdx].name,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Frame picker button
                    GestureDetector(
                      onTap: () => setState(() => _showFramePicker = true),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: AppTheme.borderMedium),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.primaryPink.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _frames.isNotEmpty
                                  ? Image.network(
                                      _frames[_selectedFrameIdx]
                                              .assetUrl
                                              .startsWith('http')
                                          ? _frames[_selectedFrameIdx].assetUrl
                                          : ApiConfig.ensureImageUrl(
                                              _frames[_selectedFrameIdx].assetUrl),
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.image,
                                          size: 16,
                                          color: Colors.pink),
                                    )
                                  : const Icon(Icons.image,
                                      size: 16, color: Colors.pink),
                            ),
                            Text('AR FRAME',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    // Capture button
                    GestureDetector(
                      onTap: _handleCapture,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryPink, width: 3),
                          color: AppTheme.bgDarkAlt,
                        ),
                        child: const Icon(Icons.camera,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    // Switch camera button
                    GestureDetector(
                      onTap: _toggleCamera,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: AppTheme.borderMedium),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cameraswitch,
                                color: Colors.white.withOpacity(0.6), size: 24),
                            Text('Đổi Camera',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showFramePicker) _buildFramePicker(),
        ],
      ),
    );
  }

  /// Mode selector: AR Frame | Photobooth
  Widget _buildModeSelector() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          _buildModeTab(0, '🖼️ AR Frame'),
          _buildModeTab(1, '📸 Photobooth'),
        ],
      ),
    );
  }

  Widget _buildModeTab(int index, String label) {
    final isActive = _modeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) {
            // Navigate to Photobooth
            _openPhotobooth();
          } else {
            setState(() => _modeIndex = 0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: isActive ? AppTheme.primaryPink.withOpacity(0.2) : Colors.transparent,
            border: Border.all(
              color: isActive ? AppTheme.primaryPink.withOpacity(0.4) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textTertiary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramePicker() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C23),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderMedium),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chọn AR Frame',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text('Có ${_frames.length} mẫu AR Frame',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showFramePicker = false),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.close,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _frames.length,
                        itemBuilder: (ctx, i) {
                          final frame = _frames[i];
                          final isSelected = _selectedFrameIdx == i;
                          final url = frame.assetUrl.startsWith('http')
                              ? frame.assetUrl
                              : ApiConfig.ensureImageUrl(frame.assetUrl);
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedFrameIdx = i;
                              _showFramePicker = false;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isSelected
                                    ? AppTheme.primaryPink.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryPink
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(url,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) =>
                                              const Icon(Icons.broken_image,
                                                  color: Colors.grey)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      frame.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.primaryPink
                                            : AppTheme.textSecondary,
                                        fontSize: 10,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
