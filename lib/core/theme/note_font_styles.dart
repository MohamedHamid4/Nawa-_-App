import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/note.dart';

class NoteFontStyles {
  NoteFontStyles._();

  static TextStyle getStyle({
    required NoteFontStyle style,
    required bool isArabic,
    double fontSize = 16,
    Color? color,
  }) {
    TextStyle base;

    switch (style) {
      case NoteFontStyle.defaultStyle:
        base = isArabic
            ? GoogleFonts.ibmPlexSansArabic(fontSize: fontSize)
            : GoogleFonts.inter(fontSize: fontSize);
        break;
      case NoteFontStyle.bold:
        base = isArabic
            ? GoogleFonts.ibmPlexSansArabic(
                fontSize: fontSize, fontWeight: FontWeight.w800)
            : GoogleFonts.inter(
                fontSize: fontSize, fontWeight: FontWeight.w800);
        break;
      case NoteFontStyle.italic:
        base = isArabic
            ? GoogleFonts.ibmPlexSansArabic(
                fontSize: fontSize, fontStyle: FontStyle.italic)
            : GoogleFonts.inter(
                fontSize: fontSize, fontStyle: FontStyle.italic);
        break;
      case NoteFontStyle.cursive:
        base = isArabic
            ? GoogleFonts.amiri(fontSize: fontSize)
            : GoogleFonts.caveat(fontSize: fontSize + 2);
        break;
      case NoteFontStyle.heavy:
        base = isArabic
            ? GoogleFonts.ibmPlexSansArabic(
                fontSize: fontSize, fontWeight: FontWeight.w900)
            : GoogleFonts.inter(
                fontSize: fontSize, fontWeight: FontWeight.w900);
        break;
      case NoteFontStyle.mono:
        base = isArabic
            ? GoogleFonts.notoNaskhArabic(fontSize: fontSize)
            : GoogleFonts.jetBrainsMono(fontSize: fontSize);
        break;
    }

    return base.copyWith(color: color, height: 1.6);
  }

  static String displayName(NoteFontStyle style, bool isArabic) {
    switch (style) {
      case NoteFontStyle.defaultStyle:
        return isArabic ? 'افتراضي' : 'Default';
      case NoteFontStyle.bold:
        return isArabic ? 'عريض' : 'Bold';
      case NoteFontStyle.italic:
        return isArabic ? 'مائل' : 'Italic';
      case NoteFontStyle.cursive:
        return isArabic ? 'منحني' : 'Cursive';
      case NoteFontStyle.heavy:
        return isArabic ? 'ثقيل' : 'Heavy';
      case NoteFontStyle.mono:
        return isArabic ? 'مونوسبيس' : 'Mono';
    }
  }

  static String previewText(NoteFontStyle style, bool isArabic) {
    return isArabic ? 'الخط العربي' : 'Aa';
  }
}
