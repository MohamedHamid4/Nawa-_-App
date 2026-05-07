import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'app/app.dart';
import 'app/providers.dart';
import 'core/services/ads_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/local/local_datasource.dart';
import 'data/datasources/local/preferences_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final local = LocalDatasource();
    await local.init();

    final prefs = PreferencesService();
    await prefs.init();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      AppLogger.w('Firebase init failed: $e\n$st');
    }

    FlutterError.onError = (details) {
      AppLogger.e('FlutterError', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.e('PlatformError', error, stack);
      return true;
    };

    String startLocaleCode;
    final savedLocale = prefs.locale;
    if (savedLocale != null && savedLocale.isNotEmpty) {
      startLocaleCode = savedLocale;
    } else {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      startLocaleCode = systemLocale.languageCode == 'ar' ? 'ar' : 'en';
    }

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: Locale(startLocaleCode),
        child: ProviderScope(
          overrides: [
            localDatasourceProvider.overrideWithValue(local),
            prefsProvider.overrideWithValue(prefs),
            notificationServiceProvider
                .overrideWithValue(NotificationService.instance),
          ],
          child: const NawaApp(),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeferredServices();
      _preloadLottieAssets();
    });
  }, (error, stack) {
    AppLogger.e('Uncaught zone error', error, stack);
  });
}

Future<void> _initDeferredServices() async {
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    AppLogger.w('NotificationService init failed: $e\n$st');
  }
  try {
    await AdsService().init();
  } catch (e, st) {
    AppLogger.w('AdsService init failed: $e\n$st');
  }
}

Future<void> _preloadLottieAssets() async {
  try {
    await Future.wait([
      rootBundle.load('assets/animations/onboarding_writing.json'),
      rootBundle.load('assets/animations/onboarding_ai.json'),
      rootBundle.load('assets/animations/onboarding_sync.json'),
    ]);
  } catch (_) {
    // Animations will load on demand if preload fails.
  }
}
