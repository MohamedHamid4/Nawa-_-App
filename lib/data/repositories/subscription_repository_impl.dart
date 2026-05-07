import 'dart:async';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/local/preferences_service.dart';
import '../datasources/remote/firestore_remote_datasource.dart';
import 'purchase_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirestoreRemoteDatasource _remote;
  final PreferencesService _prefs;
  final PurchaseRepository _purchase;

  SubscriptionRepositoryImpl({
    required FirestoreRemoteDatasource remote,
    required PreferencesService prefs,
    required PurchaseRepository purchase,
  })  : _remote = remote,
        _prefs = prefs,
        _purchase = purchase;

  Subscription _localFallback() {
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

  Future<void> _persistLocal(Subscription s) async {
    await _prefs.setSubscriptionPlan(s.plan.name);
    await _prefs.setSubscriptionExpiry(s.expiryDate?.millisecondsSinceEpoch);
  }

  @override
  Future<Result<Subscription>> current(String uid) async {
    try {
      final doc = await _remote.subscriptionDoc(uid).get();
      if (!doc.exists) {
        return Success(_localFallback());
      }
      final s = Subscription.fromMap(Map<String, dynamic>.from(doc.data()!));
      await _persistLocal(s);
      return Success(s);
    } catch (e) {
      AppLogger.w('subscription current() falling back to local: $e');
      return Success(_localFallback());
    }
  }

  @override
  Stream<Subscription> watch(String uid) {
    return _remote.subscriptionDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return _localFallback();
      final s = Subscription.fromMap(Map<String, dynamic>.from(snap.data()!));
      // mirror to prefs (non-blocking)
      unawaited(_persistLocal(s));
      return s;
    });
  }

  @override
  Future<Result<void>> setPlan({
    required String uid,
    required SubscriptionPlan plan,
    required DateTime expiryDate,
  }) async {
    try {
      final purchaseResult = await _purchase.purchase(plan);
      if (purchaseResult is FailureResult<Subscription>) {
        return FailureResult(purchaseResult.failure);
      }
      final sub = Subscription(
        plan: plan,
        startDate: DateTime.now(),
        expiryDate: expiryDate,
        autoRenew: true,
      );
      await _remote.subscriptionDoc(uid).set(sub.toMap());
      await _persistLocal(sub);
      return const Success(null);
    } catch (e) {
      AppLogger.e('setPlan', e);
      return FailureResult(ServerFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> cancel(String uid) async {
    try {
      await _purchase.cancel();
      final free = Subscription.free();
      await _remote.subscriptionDoc(uid).set(free.toMap());
      await _persistLocal(free);
      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure(cause: e));
    }
  }

  @override
  Future<Result<Subscription>> restore(String uid) async {
    try {
      final restored = await _purchase.restore();
      if (restored is FailureResult<Subscription?>) {
        return FailureResult(restored.failure);
      }
      final value = restored.dataOrNull;
      if (value == null) {
        return Success(Subscription.free());
      }
      await _remote.subscriptionDoc(uid).set(value.toMap());
      await _persistLocal(value);
      return Success(value);
    } catch (e) {
      return FailureResult(ServerFailure(cause: e));
    }
  }
}
