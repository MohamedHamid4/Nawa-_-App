import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Nawa logo — a stylized "ن" (Arabic Noon letter) inside a soft rounded shape,
/// representing the seed/nucleus that grows into ideas.
///
/// The dot above the ن symbolizes a single thought, and the curve below
/// represents the container holding all your notes.
class NawaLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;

  const NawaLogo({
    super.key,
    this.size = 96,
    this.showBackground = true,
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = primaryColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final accent = accentColor ??
        (isDark ? AppColors.darkAccent : AppColors.lightAccent);
    final bg = backgroundColor ??
        (isDark ? AppColors.darkSurface : Colors.white);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NawaLogoPainter(
          primary: primary,
          accent: accent,
          background: bg,
          showBackground: showBackground,
        ),
      ),
    );
  }
}

class _NawaLogoPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color background;
  final bool showBackground;

  _NawaLogoPainter({
    required this.primary,
    required this.accent,
    required this.background,
    required this.showBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    if (showBackground) {
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.24),
      );
      final bgPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawRRect(bgRect, bgPaint);
    }

    final strokeColor = showBackground ? Colors.white : primary;
    final strokeW = w * 0.085;

    final bowlPath = Path();
    final bowlTop = h * 0.42;
    final bowlBottom = h * 0.78;
    final bowlLeft = w * 0.28;
    final bowlRight = w * 0.72;

    bowlPath.moveTo(bowlLeft, bowlTop);
    bowlPath.quadraticBezierTo(
      w * 0.20,
      bowlBottom + h * 0.05,
      center.dx,
      bowlBottom,
    );
    bowlPath.quadraticBezierTo(
      w * 0.80,
      bowlBottom + h * 0.05,
      bowlRight,
      bowlTop,
    );

    final bowlPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bowlPath, bowlPaint);

    final dotCenter = Offset(center.dx, h * 0.28);
    final dotRadius = w * 0.075;

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(dotCenter, dotRadius * 1.6, glowPaint);

    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, dotRadius, dotPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(dotCenter.dx - dotRadius * 0.3, dotCenter.dy - dotRadius * 0.3),
      dotRadius * 0.35,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NawaLogoPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent ||
      oldDelegate.background != background ||
      oldDelegate.showBackground != showBackground;
}

/// Animated version of the logo — used in the splash screen.
class AnimatedNawaLogo extends StatefulWidget {
  final double size;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedNawaLogo({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1400),
    this.onComplete,
  });

  @override
  State<AnimatedNawaLogo> createState() => _AnimatedNawaLogoState();
}

class _AnimatedNawaLogoState extends State<AnimatedNawaLogo>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value * _pulseAnimation.value,
              child: NawaLogo(size: widget.size),
            ),
          ),
        );
      },
    );
  }
}
