class HiveBoxes {
  static const notes = 'notes_v1';
  static const pendingOps = 'pending_ops_v1';
  static const cache = 'cache_v1';
}

class PrefKeys {
  static const themeMode = 'theme_mode';
  static const locale = 'locale';
  static const firstLaunch = 'first_launch';
  static const lastUserId = 'last_user_id';
  static const biometricEnabled = 'biometric_enabled';
  static const notificationsEnabled = 'notifications_enabled';
  static const subscriptionPlan = 'subscription_plan';
  static const subscriptionExpiry = 'subscription_expiry';
  static const onboardingDone = 'onboarding_done';
}

class FsCollections {
  static const users = 'users';
  static const notes = 'notes';
  static const subscription = 'subscription';
}

class AppLimits {
  static const freeMaxNotes = 50;
  static const freeStorageMb = 100;
  static const premiumStorageGb = 10;
  static const autoSaveDebounceMs = 600;
  static const searchDebounceMs = 250;
  static const pageSize = 25;
  static const firestoreBatchMax = 450;
  static const summarizeMinChars = 280;
  static const aiTimeoutSeconds = 60;
}
