import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class ThemeViewModel extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(prefsProvider).themeMode;
    return _decode(saved);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(prefsProvider).setThemeMode(_encode(mode));
  }

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeMode>(ThemeViewModel.new);
