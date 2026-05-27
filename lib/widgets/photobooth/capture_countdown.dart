import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';

/// Fullscreen countdown overlay: 3 → 2 → 1 with bounce + glow animation
class CaptureCountdown extends StatefulWidget {
  final VoidCallback onComplete;
  final int seconds;

  const CaptureCountdown({
    super.key,
    required this.onComplete,
    this.seconds = 3,
  });

  @override
  State<CaptureCountdown> createState() => _CaptureCountdownState();
}

class _CaptureCountdownState extends State<CaptureCountdown>
    with TickerProviderStateMixin {
  late int _currentNumber;
  late AnimationController _scaleCtl;
  late AnimationController _opacityCtl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _currentNumber = widget.seconds;

    _scaleCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacityCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(begin: 2.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtl, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _opacityCtl, curve: Curves.easeInExpo),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _animateNumber();
  }

  void _animateNumber() {
    _scaleCtl.reset();
    _opacityCtl.reset();
    _scaleCtl.forward();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Wait, then fade out and go to next number
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _opacityCtl.forward().then((_) {
        if (!mounted) return;
        if (_currentNumber > 1) {
          setState(() => _currentNumber--);
          _animateNumber();
        } else {
          // Countdown complete
          HapticFeedback.heavyImpact();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _scaleCtl.dispose();
    _opacityCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleCtl, _opacityCtl]),
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryPink.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      radius: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.4 * _opacityAnim.value),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_currentNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryPink.withOpacity(0.8),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
