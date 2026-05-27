import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/photobooth_session.dart';
import '../../providers/event_provider.dart';
import '../../services/photobooth_compositor.dart';
import '../../utils/theme.dart';

/// Step 5: Save photo, timelapse MP4, and share
class SaveScreen extends StatefulWidget {
  final PhotoboothSession session;
  final Uint8List compositeImage;
  final String eventName;
  final String eventId;
  final VoidCallback onRestart;

  const SaveScreen({
    super.key,
    required this.session,
    required this.compositeImage,
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

  @override
  void initState() {
    super.initState();
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
        widget.compositeImage,
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
        // Save MP4 to gallery
        final mp4Bytes = await File(mp4Path).readAsBytes();
        await ImageGallerySaverPlus.saveImage(
          mp4Bytes,
          name: 'linkie-timelapse-${DateTime.now().millisecondsSinceEpoch}.mp4',
        );

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
      await file.writeAsBytes(widget.compositeImage);

      // Try share_plus if available, otherwise show snackbar
      try {
        // Dynamic import to avoid crash if share_plus not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ảnh đã lưu tại: ${file.path}'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
        }
      } catch (e) {
        debugPrint('Share error: $e');
      }
    } catch (e) {
      debugPrint('Share error: $e');
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
              child: Image.memory(
                widget.compositeImage,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 20),

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
