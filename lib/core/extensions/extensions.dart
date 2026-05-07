import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  MediaQueryData get media => MediaQuery.of(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }
}

extension StringX on String {
  bool get isBlank => trim().isEmpty;
  String get nonBlankOrFallback => trim().isEmpty ? '—' : this;
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String truncate(int max) =>
      length <= max ? this : '${substring(0, max).trim()}…';
}

extension DateTimeX on DateTime {
  String formatLocal({String pattern = 'yyyy-MM-dd HH:mm', String? locale}) {
    return intl.DateFormat(pattern, locale).format(toLocal());
  }

  String relative(String localeCode) {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds.abs() < 60) {
      return localeCode.startsWith('ar') ? 'الآن' : 'now';
    }
    if (diff.inMinutes.abs() < 60) {
      return localeCode.startsWith('ar')
          ? 'منذ ${diff.inMinutes} د'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours.abs() < 24) {
      return localeCode.startsWith('ar')
          ? 'منذ ${diff.inHours} س'
          : '${diff.inHours}h ago';
    }
    return formatLocal(pattern: 'MMM d, HH:mm', locale: localeCode);
  }
}
