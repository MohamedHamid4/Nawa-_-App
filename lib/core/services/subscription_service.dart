import '../../data/datasources/local/preferences_service.dart';
import '../../domain/entities/subscription.dart';

/// Lightweight, synchronous read of premium state for instant UI checks.
/// Use SubscriptionViewModel for reactive updates.
class SubscriptionService {
  final PreferencesService _prefs;
  SubscriptionService(this._prefs);

  Subscription get cached {
    final planName = _prefs.subscriptionPlan;
    final expiryMs = _prefs.subscriptionExpiry;
    final plan = SubscriptionPlan.values.firstWhere(
      (p) => p.name == planName,
      orElse: () => SubscriptionPlan.free,
    );
    return Subscription(
      plan: plan,
      expiryDate: expiryMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
          : null,
    );
  }

  bool get isPremium => cached.isPremium;

  bool canCreateNote(int currentCount) {
    if (isPremium) return true;
    return currentCount < 50;
  }

  bool canUseAi() => isPremium;
  bool canEncrypt() => isPremium;
}
