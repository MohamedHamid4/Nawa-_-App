import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class LocaleViewModel extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.read(prefsProvider).locale;
    if (saved != null && saved.isNotEmpty) {
      return Locale(saved);
    }
    final sys =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(sys == 'ar' ? 'ar' : 'en');
  }

  Future<void> setLocale(BuildContext context, Locale locale) async {
    // Always apply via EasyLocalization first so context.locale becomes the
    // source of truth, then mirror into Riverpod state to trigger rebuilds.
    // Skipping based purely on `state` causes desyncs when the initial state
    // disagreed with EasyLocalization's startLocale.
    if (context.locale.languageCode != locale.languageCode) {
      await context.setLocale(locale);
    }
    await ref.read(prefsProvider).setLocale(locale.languageCode);
    state = locale;
  }
}

final localeViewModelProvider =
    NotifierProvider<LocaleViewModel, Locale>(LocaleViewModel.new);
