import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../presentation/viewmodels/locale_viewmodel.dart';
import '../presentation/viewmodels/theme_viewmodel.dart';
import 'providers.dart';
import 'router.dart';

class NawaApp extends ConsumerStatefulWidget {
  const NawaApp({super.key});

  @override
  ConsumerState<NawaApp> createState() => _NawaAppState();
}

class _NawaAppState extends ConsumerState<NawaApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _wasInBackground = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildRouter(ref);
    Future.microtask(() {
      ref.read(syncServiceProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      final shouldLock = _backgroundedAt != null &&
          DateTime.now().difference(_backgroundedAt!) >
              const Duration(seconds: 30);

      if (!shouldLock) return;

      try {
        final prefs = ref.read(prefsProvider);
        final auth = ref.read(authRepositoryProvider);
        if (prefs.biometricEnabled && auth.currentUser != null) {
          Future.microtask(() {
            try {
              _router.go(AppRoutes.lock);
            } catch (_) {}
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeViewModelProvider);
    final vmLocale = ref.watch(localeViewModelProvider);
    final locale = context.locale.languageCode == vmLocale.languageCode
        ? context.locale
        : vmLocale;

    return MaterialApp.router(
      title: 'Nawa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: _router,
    );
  }
}
