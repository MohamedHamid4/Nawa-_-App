import 'dart:io' show Platform;

class AdConfig {
  AdConfig._();

  // ═══ TEST IDs (used by default during development) ═══
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const _testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const _testAppOpenIos = 'ca-app-pub-3940256099942544/5575463023';

  // ═══ PRODUCTION IDs (Android — your real ad units) ═══
  static const _prodInterstitialAndroid = 'ca-app-pub-3962967753864866/5814713854';
  static const _prodRewardedAiAndroid = 'ca-app-pub-3962967753864866/5671243624';
  static const _prodRewardedAndroid = 'ca-app-pub-3962967753864866/2721646651';
  static const _prodNativeAndroid = 'ca-app-pub-3962967753864866/7668135432';
  static const _prodAppOpenAndroid = 'ca-app-pub-3962967753864866/4595405067';

  static const bool useProdAds = bool.fromEnvironment(
    'USE_PROD_ADS',
    defaultValue: false,
  );

  static String _pick(String prod, String test) =>
      useProdAds && prod.isNotEmpty ? prod : test;

  static String get interstitialId => Platform.isAndroid
      ? _pick(_prodInterstitialAndroid, _testInterstitialAndroid)
      : _testInterstitialIos;

  static String get rewardedAiId => Platform.isAndroid
      ? _pick(_prodRewardedAiAndroid, _testRewardedAndroid)
      : _testRewardedIos;

  static String get rewardedId => Platform.isAndroid
      ? _pick(_prodRewardedAndroid, _testRewardedAndroid)
      : _testRewardedIos;

  static String get nativeId => Platform.isAndroid
      ? _pick(_prodNativeAndroid, _testNativeAndroid)
      : _testNativeIos;

  static String get appOpenId => Platform.isAndroid
      ? _pick(_prodAppOpenAndroid, _testAppOpenAndroid)
      : _testAppOpenIos;

  // Banner is unused — kept for backwards compatibility
  static String get bannerId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';
}
