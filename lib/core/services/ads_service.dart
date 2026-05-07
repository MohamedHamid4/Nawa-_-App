import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../config/env.dart';
import '../utils/app_logger.dart';

/// Smart ads service: interstitial every N actions, app open on cold start,
/// rewarded for premium feature unlocks. Banner removed (low value, high friction).
class AdsService {
  bool _initialized = false;

  // Interstitial state
  InterstitialAd? _interstitialAd;
  int _navigationCount = 0;
  static const int _showInterstitialEvery = 5;

  // App Open state
  AppOpenAd? _appOpenAd;
  DateTime? _lastAppOpenShown;
  static const Duration _appOpenCooldown = Duration(hours: 4);

  Future<void> init() async {
    if (_initialized || !Env.adsEnabled) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _preloadInterstitial();
      _preloadAppOpen();
    } catch (e) {
      AppLogger.w('AdsService init failed: $e');
    }
  }

  bool get adsEnabled => Env.adsEnabled;

  // ─── Interstitial ───────────────────────────────────────────────

  void _preloadInterstitial() {
    if (!Env.adsEnabled) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitialAd = null;
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          AppLogger.w('Interstitial failed to load: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Call this on every navigation; shows interstitial every N navigations.
  Future<void> trackNavigationAndMaybeShow() async {
    if (!Env.adsEnabled) return;
    _navigationCount++;
    if (_navigationCount >= _showInterstitialEvery) {
      _navigationCount = 0;
      await _showInterstitial();
    }
  }

  Future<void> _showInterstitial() async {
    if (_interstitialAd == null) {
      _preloadInterstitial();
      return;
    }
    try {
      await _interstitialAd!.show();
    } catch (e) {
      AppLogger.w('Interstitial show failed: $e');
    }
  }

  // ─── App Open ───────────────────────────────────────────────────

  void _preloadAppOpen() {
    if (!Env.adsEnabled) return;
    AppOpenAd.load(
      adUnitId: AdConfig.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (err) {
          AppLogger.w('App Open failed to load: $err');
        },
      ),
    );
  }

  Future<void> showAppOpenIfReady() async {
    if (!Env.adsEnabled || _appOpenAd == null) return;
    if (_lastAppOpenShown != null &&
        DateTime.now().difference(_lastAppOpenShown!) < _appOpenCooldown) {
      return;
    }
    _lastAppOpenShown = DateTime.now();
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _preloadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _appOpenAd = null;
        _preloadAppOpen();
      },
    );
    try {
      await _appOpenAd!.show();
    } catch (e) {
      AppLogger.w('AppOpen show failed: $e');
    }
  }

  // ─── Rewarded ───────────────────────────────────────────────────

  /// Show rewarded ad. Returns true if user earned the reward.
  Future<bool> showRewarded({bool isAiUnlock = false}) async {
    if (!Env.adsEnabled) return false;
    final completer = Completer<bool>();
    var earned = false;

    await RewardedAd.load(
      adUnitId: isAiUnlock ? AdConfig.rewardedAiId : AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, __) => earned = true);
        },
        onAdFailedToLoad: (err) {
          AppLogger.w('Rewarded failed: $err');
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  // ─── Native Ad widget builder ───────────────────────────────────

  /// Build a native ad. Caller must dispose the returned NativeAd.
  NativeAd buildNativeAd({
    required void Function(NativeAd) onLoaded,
    void Function(LoadAdError)? onFailed,
  }) {
    return NativeAd(
      adUnitId: AdConfig.nativeId,
      request: const AdRequest(),
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, err) {
          AppLogger.w('Native failed: $err');
          ad.dispose();
          onFailed?.call(err);
        },
      ),
    );
  }
}
