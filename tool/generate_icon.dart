// Generates the Nawa app icon programmatically.
// Run with: dart run tool/generate_icon.dart
//
// Produces:
//   assets/icons/app_icon.png            — 1024×1024 with rounded green bg
//   assets/icons/app_icon_foreground.png — 1024×1024 transparent (Android adaptive)

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const _bgRgb = [0x2F, 0x6B, 0x5F]; // emerald primary
const _accentRgb = [0xC9, 0xA7, 0x5C]; // gold accent

void main() {
  _generateIcon('assets/icons/app_icon.png', 1024, withBackground: true);
  _generateIcon(
    'assets/icons/app_icon_foreground.png',
    1024,
    withBackground: false,
    paddingFraction: 0.18,
  );
  // ignore: avoid_print
  print('Icons generated.');
}

void _generateIcon(
  String path,
  int size, {
  required bool withBackground,
  double paddingFraction = 0.0,
}) {
  final img = Image(width: size, height: size, numChannels: 4);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  if (withBackground) {
    final bgColor = ColorRgb8(_bgRgb[0], _bgRgb[1], _bgRgb[2]);
    final cornerRadius = (size * 0.24).round();
    _fillRoundedRect(img, 0, 0, size, size, cornerRadius, bgColor);
  }

  final pad = (size * paddingFraction).round();
  final inner = size - pad * 2;
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  final strokeColor = withBackground
      ? ColorRgb8(255, 255, 255)
      : ColorRgb8(_bgRgb[0], _bgRgb[1], _bgRgb[2]);
  final accentColor = ColorRgb8(_accentRgb[0], _accentRgb[1], _accentRgb[2]);

  final strokeWidth = (inner * 0.085).round();
  final bowlTop = cy - (inner * 0.04).round();
  final bowlBottom = cy + (inner * 0.18).round();
  final bowlLeft = cx - (inner * 0.22).round();
  final bowlRight = cx + (inner * 0.22).round();

  // Quadratic bezier from (bowlLeft, bowlTop) → (cx, bowlBottom)
  // and from (cx, bowlBottom) → (bowlRight, bowlTop), drawn as filled circles.
  for (var t = 0.0; t <= 1.0; t += 0.002) {
    final invT = 1 - t;
    final controlX1 = (cx - inner * 0.30).round();
    final controlY = bowlBottom + (inner * 0.05).round();
    final lx = (invT * invT * bowlLeft +
            2 * invT * t * controlX1 +
            t * t * cx)
        .round();
    final ly = (invT * invT * bowlTop +
            2 * invT * t * controlY +
            t * t * bowlBottom)
        .round();
    fillCircle(
      img,
      x: lx,
      y: ly,
      radius: strokeWidth ~/ 2,
      color: strokeColor,
      antialias: true,
    );

    final controlX2 = (cx + inner * 0.30).round();
    final rx = (invT * invT * cx +
            2 * invT * t * controlX2 +
            t * t * bowlRight)
        .round();
    final ry = (invT * invT * bowlBottom +
            2 * invT * t * controlY +
            t * t * bowlTop)
        .round();
    fillCircle(
      img,
      x: rx,
      y: ry,
      radius: strokeWidth ~/ 2,
      color: strokeColor,
      antialias: true,
    );
  }

  final dotY = cy - (inner * 0.22).round();
  final dotRadius = (inner * 0.075).round();

  for (var r = dotRadius * 2; r > dotRadius; r--) {
    final alpha = (255 *
            (dotRadius * 2 - r) /
            dotRadius *
            0.3)
        .clamp(0.0, 80.0)
        .round();
    fillCircle(
      img,
      x: cx,
      y: dotY,
      radius: r,
      color: ColorRgba8(_accentRgb[0], _accentRgb[1], _accentRgb[2], alpha),
      antialias: true,
    );
  }

  fillCircle(
    img,
    x: cx,
    y: dotY,
    radius: dotRadius,
    color: accentColor,
    antialias: true,
  );

  // Tiny white sparkle highlight on the dot
  fillCircle(
    img,
    x: cx - (dotRadius * 0.3).round(),
    y: dotY - (dotRadius * 0.3).round(),
    radius: (dotRadius * 0.35).round(),
    color: ColorRgba8(255, 255, 255, 110),
    antialias: true,
  );

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(img));
}

void _fillRoundedRect(
  Image img,
  int x,
  int y,
  int w,
  int h,
  int radius,
  Color color,
) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      final dx = math.max(
        (x + radius - px).toDouble(),
        math.max(0.0, (px - (x + w - radius - 1)).toDouble()),
      );
      final dy = math.max(
        (y + radius - py).toDouble(),
        math.max(0.0, (py - (y + h - radius - 1)).toDouble()),
      );
      if (dx * dx + dy * dy <= (radius * radius).toDouble()) {
        img.setPixel(px, py, color);
      }
    }
  }
}
