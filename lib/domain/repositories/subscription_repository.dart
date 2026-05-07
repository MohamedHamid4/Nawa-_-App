import '../../core/errors/result.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Result<Subscription>> current(String uid);
  Stream<Subscription> watch(String uid);
  Future<Result<void>> setPlan({
    required String uid,
    required SubscriptionPlan plan,
    required DateTime expiryDate,
  });
  Future<Result<void>> cancel(String uid);
  Future<Result<Subscription>> restore(String uid);
}
