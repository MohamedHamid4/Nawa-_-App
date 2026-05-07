// Generates splash & adaptive-icon assets procedurally so we can fine-tune
// proportions without round-tripping through a designer.
// Run with: dart run tool/generate_splash_logos.dart

import 'dart:io';

import 'package:image/image.dart';

const _brandGreen = 0xFF4D9180;
const _darkBg = 0xFF0F1218;

void main() {
  _writeSplashLogo(
    path: 'assets/icons/splash_logo.png',
    size: 512,
    bg: ColorRgba8(0, 0, 0, 0),
    square: ColorRgb8(
      (_brandGreen >> 16) & 0xFF,
      (_brandGreen >> 8) & 0xFF,
      _brandGreen & 0xFF,
    ),
    lines: ColorRgb8(255, 255, 255),
  );
  stdout.writeln('Generated splash_logo.png (512x512)');

  _writeSplashLogo(
    path: 'assets/icons/splash_logo_dark.png',
    size: 512,
    bg: ColorRgba8(0, 0, 0, 0),
    square: ColorRgb8(
      (_brandGreen >> 16) & 0xFF,
      (_brandGreen >> 8) & 0xFF,
      _brandGreen & 0xFF,
    ),
    lines: ColorRgb8(255, 255, 255),
  );
  stdout.writeln('Generated splash_logo_dark.png (512x512)');

  // Master app icon — same proportions as splash but full bleed (no padding).
  _writeAppIcon(
    path: 'assets/icons/app_icon.png',
    size: 1024,
    bg: ColorRgb8(
      (_brandGreen >> 16) & 0xFF,
      (_brandGreen >> 8) & 0xFF,
      _brandGreen & 0xFF,
    ),
    lines: ColorRgb8(255, 255, 255),
  );
  stdout.writeln('Generated app_icon.png (1024x1024)');

  // Adaptive icon foreground — 3 white lines on transparent canvas.
  _writeAdaptiveForeground(
    path: 'assets/icons/app_icon_foreground.png',
    size: 1024,
    lines: ColorRgb8(255, 255, 255),
  );
  stdout.writeln('Generated app_icon_foreground.png (1024x1024)');

  stdout.writeln('All splash & adaptive assets generated.');
  // Suppress unused-warning for dark constant (kept for future tinting).
  _darkBg.toString();
}

void _writeSplashLogo({
  required String path,
  required int size,
  required Color bg,
  required Color square,
  required Color lines,
}) {
  final img = Image(width: size, height: size, numChannels: 4);
  fill(img, color: bg);

  // Rounded square ~78% of canvas, centered.
  final sq = (size * 0.78).round();
  final sqX = (size - sq) ~/ 2;
  final sqY = (size - sq) ~/ 2;
  final sqRadius = (sq * 0.22).round();
  _fillRoundedRect(img, sqX, sqY, sq, sq, sqRadius, square);

  // Compact line widths so the longest line clears the rounded square nicely.
  final lineWidths = [
    (size * 0.26).round(),
    (size * 0.48).round(),
    (size * 0.36).round(),
  ];
  _drawThreeLines(img, size, lineWidths, lines);

  File(path).writeAsBytesSync(encodePng(img));
}

void _writeAppIcon({
  required String path,
  required int size,
  required Color bg,
  required Color lines,
}) {
  final img = Image(width: size, height: size, numChannels: 4);
  fill(img, color: bg);

  final lineWidths = [
    (size * 0.26).round(),
    (size * 0.48).round(),
    (size * 0.36).round(),
  ];
  _drawThreeLines(img, size, lineWidths, lines);

  File(path).writeAsBytesSync(encodePng(img));
}

void _writeAdaptiveForeground({
  required String path,
  required int size,
  required Color lines,
}) {
  final img = Image(width: size, height: size, numChannels: 4);
  fill(img, color: ColorRgba8(0, 0, 0, 0));

  // Bigger lines for adaptive icon foreground — fills more of the safe zone
  // because adaptive masking already crops aggressively.
  final lineWidths = [
    (size * 0.30).round(),
    (size * 0.55).round(),
    (size * 0.42).round(),
  ];
  _drawThreeLines(img, size, lineWidths, lines);

  File(path).writeAsBytesSync(encodePng(img));
}

void _drawThreeLines(
  Image img,
  int canvas,
  List<int> widths,
  Color color,
) {
  final cx = canvas ~/ 2;
  final cy = canvas ~/ 2;
  final lineThickness = (canvas * 0.045).round();
  final lineSpacing = (canvas * 0.085).round();
  final totalGroupHeight = lineThickness * 3 + lineSpacing * 2;
  final firstLineY = cy - totalGroupHeight ~/ 2;

  for (var i = 0; i < 3; i++) {
    final w = widths[i];
    final y = firstLineY + i * (lineThickness + lineSpacing);
    final x = cx - w ~/ 2;
    _fillRoundedRect(img, x, y, w, lineThickness, lineThickness ~/ 2, color);
  }
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
      if (px < 0 || py < 0 || px >= img.width || py >= img.height) continue;
      final dx = (px < x + radius)
          ? (x + radius) - px
          : (px > x + w - radius - 1)
              ? px - (x + w - radius - 1)
              : 0;
      final dy = (py < y + radius)
          ? (y + radius) - py
          : (py > y + h - radius - 1)
              ? py - (y + h - radius - 1)
              : 0;
      if (dx * dx + dy * dy <= radius * radius) {
        img.setPixel(px, py, color);
      }
    }
  }
}
