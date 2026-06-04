import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual tokens shared by Login and Sign Up screens (matches provided mockups).
abstract final class AuthScreenDecor {
  /// Royal blue (expected login mockup ~`#0052FF`).
  static const Color primaryBlue = Color(0xFF0052FF);
  /// Icy pale blue behind the primary blob (top header).
  static const Color waveLavender = Color(0xFFE3EDFF);
  static const Color fieldFill = Color(0xFFF5F5F5);
  static const Color titleColor = Color(0xFF000000);
  static const Color subtitleColor = Color(0xFF4A4F57);
  static const Color linkGray = Color(0xFF5C5C5C);
  static const Color hintMuted = Color(0xFF8A8A8E);

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.065).clamp(22.0, 32.0);
  }

  /// Organic header blobs (top-left), ~upper third of the screen; scales with size.
  static Widget waveHeader(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final headerH = (h * 0.30).clamp(168.0, 260.0);

    return SizedBox(
      height: headerH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -headerH * 0.42,
            left: -w * 0.32,
            child: Container(
              width: w * 1.05,
              height: headerH * 1.55,
              decoration: BoxDecoration(
                color: waveLavender,
                borderRadius: BorderRadius.circular(w * 0.48),
              ),
            ),
          ),
          Positioned(
            top: -headerH * 0.38,
            left: -w * 0.34,
            child: Container(
              width: w * 0.78,
              height: headerH * 1.12,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(w * 0.40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration authField({
    required String hintText,
    Widget? prefix,
    Widget? suffixIcon,
    bool alignSuffix = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: hintMuted,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
      prefixIcon: prefix,
      prefixIconConstraints: prefix != null
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : null,
      suffixIcon: suffixIcon == null
          ? null
          : alignSuffix
              ? Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: suffixIcon,
                )
              : suffixIcon,
      filled: true,
      fillColor: fieldFill,
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: primaryBlue.withValues(alpha: 0.45), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0xFFB00020)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.2),
      ),
    );
  }

  static ButtonStyle primaryCapsuleButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      minimumSize: const Size.fromHeight(54),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  /// Login mockup: wide blue control with ~12–16px corner radius (not a full pill).
  static ButtonStyle primaryRoundedActionButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
      ),
    );
  }
}

/// Circular dashed border + camera icon (Sign Up reference layout).
///
/// When [onTap] is set, the whole control is tappable (e.g. pick a profile photo).
/// [image] shows a preview; [uploading] shows a progress overlay.
class AuthAvatarPlaceholder extends StatelessWidget {
  const AuthAvatarPlaceholder({
    super.key,
    this.size = 88,
    this.onTap,
    this.image,
    this.uploading = false,
    this.accentColor,
  });

  final double size;
  final VoidCallback? onTap;
  final ImageProvider? image;
  final bool uploading;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final inner = (size - 5).clamp(1.0, size);
    final color = accentColor ?? AuthScreenDecor.primaryBlue;

    Widget avatar = SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox(
                width: inner,
                height: inner,
                child: ColoredBox(
                  color: Colors.white,
                  child: image != null
                      ? Image(
                          image: image!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.photo_camera_outlined,
                          color: color,
                          size: size * 0.36,
                        ),
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: _DashedCirclePainter(
              color: color,
              strokeWidth: 2,
            ),
            child: const SizedBox.expand(),
          ),
          if (uploading)
            Center(
              child: ClipOval(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.65),
                  child: SizedBox(
                    width: inner,
                    height: inner,
                    child: Center(
                      child: SizedBox(
                        width: size * 0.32,
                        height: size * 0.32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: uploading ? null : onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLen = 7.0;
        const gap = 5.0;
        final end = math.min(distance + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
