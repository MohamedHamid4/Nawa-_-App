import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

class PreferencesService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme
  String? get themeMode => _prefs.getString(PrefKeys.themeMode);
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(PrefKeys.themeMode, mode);

  // Locale
  String? get locale => _prefs.getString(PrefKeys.locale);
  Future<void> setLocale(String code) =>
      _prefs.setString(PrefKeys.locale, code);

  // First launch / Onboarding
  bool get isOnboardingDone => _prefs.getBool(PrefKeys.onboardingDone) ?? false;
  Future<void> setOnboardingDone() =>
      _prefs.setBool(PrefKeys.onboardingDone, true);

  // Last user
  String? get lastUserId => _prefs.getString(PrefKeys.lastUserId);
  Future<void> setLastUserId(String? id) async {
    if (id == null) {
      await _prefs.remove(PrefKeys.lastUserId);
    } else {
      await _prefs.setString(PrefKeys.lastUserId, id);
    }
  }

  // Biometric
  bool get biometricEnabled =>
      _prefs.getBool(PrefKeys.biometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool enabled) =>
      _prefs.setBool(PrefKeys.biometricEnabled, enabled);

  // Notifications
  bool get notificationsEnabled =>
      _prefs.getBool(PrefKeys.notificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(PrefKeys.notificationsEnabled, enabled);

  // Subscription
  String get subscriptionPlan =>
      _prefs.getString(PrefKeys.subscriptionPlan) ?? 'free';
  Future<void> setSubscriptionPlan(String plan) =>
      _prefs.setString(PrefKeys.subscriptionPlan, plan);

  int? get subscriptionExpiry => _prefs.getInt(PrefKeys.subscriptionExpiry);
  Future<void> setSubscriptionExpiry(int? millis) async {
    if (millis == null) {
      await _prefs.remove(PrefKeys.subscriptionExpiry);
    } else {
      await _prefs.setInt(PrefKeys.subscriptionExpiry, millis);
    }
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
