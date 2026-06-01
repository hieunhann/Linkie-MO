import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/photobooth_session.dart';
import '../../models/ar_frame.dart';
import '../../config/api_config.dart';
import '../../providers/event_provider.dart';
import '../../services/photobooth_compositor.dart';
import '../../utils/theme.dart';

/// Step 5: Save photo, timelapse MP4, and share
class SaveScreen extends StatefulWidget {
  final PhotoboothSession session;
  final Uint8List compositeImage;
  final List<ArFrame> frames;
  final String eventName;
  final String eventId;
  final VoidCallback onRestart;

  const SaveScreen({
    super.key,
    required this.session,
    required this.compositeImage,
    required this.frames,
    required this.eventName,
    required this.eventId,
    required this.onRestart,
  });

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen>
    with SingleTickerProviderStateMixin {
  bool _saving = false;
  bool _savedPhoto = false;
  bool _savingTimelapse = false;
  bool _savedTimelapse = false;
  String? _timelapseError;

  late AnimationController _celebrationCtl;
  late Animation<double> _celebrationAnim;

  late Uint8List _currentCompositeImage;
  bool _isRecompositing = false;

  @override
  void initState() {
    super.initState();
    _currentCompositeImage = widget.compositeImage;
    _celebrationCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationAnim = CurvedAnimation(
      parent: _celebrationCtl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _celebrationCtl.dispose();
    super.dispose();
  }

  Future<void> _savePhoto() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photos.request();
      }

      final fileName =
          'linkie-photobooth-${widget.eventName.replaceAll(' ', '-').toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await ImageGallerySaverPlus.saveImage(
        _currentCompositeImage,
        name: fileName,
        quality: 95,
      );

      // Record frame usage
      if (widget.session.selectedFrame != null) {
        context.read<EventProvider>().recordFrameUsage(
              widget.eventId,
              widget.session.selectedFrame!.id,
            );
      }

      setState(() {
        _savedPhoto = true;
        _saving = false;
      });
      _celebrationCtl.forward(from: 0.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh đã được lưu vào thư viện! 📸'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu ảnh: $e')),
        );
      }
    }
  }

  Future<void> _saveTimelapse() async {
    if (_savingTimelapse) return;
    if (widget.session.timelapseFrames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu timelapse')),
      );
      return;
    }

    setState(() {
      _savingTimelapse = true;
      _timelapseError = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();

      final mp4Path = await PhotoboothCompositor.generateTimelapseMp4(
        frames: widget.session.timelapseFrames,
        outputDir: tempDir.path,
      );

      if (mp4Path != null) {
        // Save MP4 to gallery using saveFile (not saveImage — saveImage is for images only)
        await ImageGallerySaverPlus.saveFile(mp4Path,
            name: 'linkie-timelapse-${DateTime.now().millisecondsSinceEpoch}');

        setState(() {
          _savedTimelapse = true;
          _savingTimelapse = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Time-lapse đã được lưu! 🎬'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
        }
      } else {
        setState(() {
          _savingTimelapse = false;
          _timelapseError = 'Không thể tạo video. Cần cài đặt FFmpeg.';
        });
      }
    } catch (e) {
      setState(() {
        _savingTimelapse = false;
        _timelapseError = 'Lỗi: $e';
      });
    }
  }

  Future<void> _sharePhoto() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/linkie_photobooth_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_currentCompositeImage);

      // Get render box for iOS iPad compatibility (prevents PlatformException)
      final box = context.findRenderObject() as RenderBox?;
      final rect = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      // Share photo using share_plus package
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my photobooth photo from Linkie! 📸 #LinkiePhotobooth',
        sharePositionOrigin: rect,
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ: $e')),
        );
      }
    }
  }

  Future<void> _changeFrame(ArFrame? newFrame) async {
    if (_isRecompositing) return;
    setState(() {
      _isRecompositing = true;
    });

    try {
      Uint8List? frameBytes;
      if (newFrame != null) {
        final frameUrl = newFrame.assetUrl.startsWith('http')
            ? newFrame.assetUrl
            : ApiConfig.ensureImageUrl(newFrame.assetUrl);
        final response = await http.get(Uri.parse(frameUrl));
        frameBytes = response.bodyBytes;
      }

      final regenerated = await PhotoboothCompositor.compositePhotobooth(
        photos: widget.session.selectedPhotos,
        layout: widget.session.layout,
        frameOverlayBytes: frameBytes,
        stickers: widget.session.stickers,
        isFrontCamera: widget.session.isFrontCamera,
      );

      setState(() {
        widget.session.selectedFrame = newFrame;
        _currentCompositeImage = regenerated;
        _isRecompositing = false;
        _savedPhoto = false; // Reset save status since photo changed
        _savedTimelapse = false; // Reset timelapse status
      });
    } catch (e) {
      debugPrint('Recomposite error: $e');
      setState(() {
        _isRecompositing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thay đổi khung: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Celebration text
          AnimatedBuilder(
            animation: _celebrationAnim,
            builder: (ctx, child) {
              return Transform.scale(
                scale: _savedPhoto ? _celebrationAnim.value.clamp(0.0, 1.0) : 0.0,
                child: child,
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '🎉 Tuyệt vời!',
                style: TextStyle(
                  color: AppTheme.primaryPink,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Preview image
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _currentCompositeImage,
                    fit: BoxFit.cover,
                  ),
                  if (_isRecompositing)
                    Container(
                      color: Colors.black.withOpacity(0.55),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryPink),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal Frame Selector
          if (widget.frames.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Thay đổi Khung AR',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.frames.length + 1, // +1 for "No Frame" option
                itemBuilder: (context, index) {
                  final isNoFrame = index == 0;
                  final frame = isNoFrame ? null : widget.frames[index - 1];
                  final isSelected = isNoFrame 
                      ? widget.session.selectedFrame == null
                      : widget.session.selectedFrame?.id == frame?.id;

                  return GestureDetector(
                    onTap: () => _changeFrame(frame),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected 
                            ? AppTheme.primaryPink.withOpacity(0.12)
                            : Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryPink : AppTheme.borderLight,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: isNoFrame
                          ? const Center(
                              child: Icon(Icons.block, color: Colors.white54, size: 20),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                frame!.assetUrl.startsWith('http')
                                    ? frame.assetUrl
                                    : ApiConfig.ensureImageUrl(frame.assetUrl),
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.broken_image, color: Colors.grey, size: 16),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 20),
          ],

          // Action buttons grid
          Row(
            children: [
              // Save Photo
              Expanded(
                child: _ActionButton(
                  icon: _saving
                      ? Icons.hourglass_top
                      : (_savedPhoto ? Icons.check_circle : Icons.save_alt),
                  label: _saving
                      ? 'Đang lưu...'
                      : (_savedPhoto ? 'Đã lưu!' : 'Lưu Ảnh'),
                  color: _savedPhoto ? AppTheme.successColor : AppTheme.primaryPink,
                  onTap: _savedPhoto ? null : _savePhoto,
                ),
              ),
              const SizedBox(width: 10),
              // Save Timelapse
              Expanded(
                child: _ActionButton(
                  icon: _savingTimelapse
                      ? Icons.hourglass_top
                      : (_savedTimelapse ? Icons.check_circle : Icons.movie),
                  label: _savingTimelapse
                      ? 'Đang tạo...'
                      : (_savedTimelapse ? 'Đã lưu!' : 'Time-lapse'),
                  color: _savedTimelapse
                      ? AppTheme.successColor
                      : AppTheme.primaryTeal,
                  onTap: _savedTimelapse ? null : _saveTimelapse,
                  subtitle: _timelapseError,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              // Share
              Expanded(
                child: _ActionButton(
                  icon: Icons.share,
                  label: 'Chia sẻ',
                  color: AppTheme.purple,
                  onTap: _sharePhoto,
                ),
              ),
              const SizedBox(width: 10),
              // Restart
              Expanded(
                child: _ActionButton(
                  icon: Icons.refresh,
                  label: 'Chụp lại',
                  color: Colors.white.withOpacity(0.5),
                  onTap: widget.onRestart,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.textTertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ảnh được lưu với chất lượng cao (1080×1920) phù hợp up Story',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
