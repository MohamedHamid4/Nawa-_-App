import '../../core/errors/result.dart';
import '../../domain/entities/subscription.dart';
import '../datasources/local/preferences_service.dart';

abstract class PurchaseRepository {
  Future<Result<Subscription>> purchase(SubscriptionPlan plan);
  Future<Result<Subscription?>> restore();
  Future<void> cancel();
}

class LocalPurchaseRepository implements PurchaseRepository {
  final PreferencesService _prefs;
  LocalPurchaseRepository(this._prefs);

  @override
  Future<Result<Subscription>> purchase(SubscriptionPlan plan) async {
    final now = DateTime.now();
    final expiry = plan == SubscriptionPlan.yearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    final sub = Subscription(
      plan: plan,
      startDate: now,
      expiryDate: expiry,
    );
    await _prefs.setSubscriptionPlan(plan.name);
    await _prefs.setSubscriptionExpiry(expiry.millisecondsSinceEpoch);
    return Success(sub);
  }

  @override
  Future<Result<Subscription?>> restore() async {
    final planName = _prefs.subscriptionPlan;
    final expiryMs = _prefs.subscriptionExpiry;
    final plan = SubscriptionPlan.values.firstWhere(
      (p) => p.name == planName,
      orElse: () => SubscriptionPlan.free,
    );
    if (plan == SubscriptionPlan.free) return const Success(null);
    return Success(Subscription(
      plan: plan,
      expiryDate: expiryMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
          : null,
    ));
  }

  @override
  Future<void> cancel() async {
    await _prefs.setSubscriptionPlan('free');
    await _prefs.setSubscriptionExpiry(null);
  }
}
