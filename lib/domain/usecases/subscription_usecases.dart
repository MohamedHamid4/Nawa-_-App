import '../../core/errors/result.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class CheckPremium {
  final SubscriptionRepository repo;
  CheckPremium(this.repo);
  Future<bool> call(String uid) async {
    final r = await repo.current(uid);
    return r.when(success: (s) => s.isPremium, failure: (_) => false);
  }
}

class SubscribePlan {
  final SubscriptionRepository repo;
  SubscribePlan(this.repo);
  Future<Result<void>> call({
    required String uid,
    required SubscriptionPlan plan,
  }) {
    final now = DateTime.now();
    final expiry = plan == SubscriptionPlan.yearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    return repo.setPlan(uid: uid, plan: plan, expiryDate: expiry);
  }
}

class RestorePurchases {
  final SubscriptionRepository repo;
  RestorePurchases(this.repo);
  Future<Result<Subscription>> call(String uid) => repo.restore(uid);
}
