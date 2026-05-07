import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/subscription.dart';

class SubscriptionViewModel extends Notifier<Subscription> {
  @override
  Subscription build() {
    final svc = ref.read(subscriptionServiceProvider);
    final auth = ref.watch(authStateProvider);
    final initial = svc.cached;
    final uid = auth.value?.uid;
    if (uid != null) {
      final repo = ref.watch(subscriptionRepositoryProvider);
      final sub = repo.watch(uid).listen((s) {
        state = s;
      });
      ref.onDispose(sub.cancel);
    }
    return initial;
  }

  bool get isPremium => state.isPremium;
  SubscriptionPlan get currentPlan => state.plan;
  DateTime? get expiryDate => state.expiryDate;

  Future<bool> subscribe(SubscriptionPlan plan) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return false;
    final repo = ref.read(subscriptionRepositoryProvider);
    final now = DateTime.now();
    final expiry = plan == SubscriptionPlan.yearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    final r = await repo.setPlan(uid: uid, plan: plan, expiryDate: expiry);
    return r.isSuccess;
  }

  Future<bool> restore() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return false;
    final repo = ref.read(subscriptionRepositoryProvider);
    final r = await repo.restore(uid);
    return r.when(
      success: (s) {
        state = s;
        return s.isPremium;
      },
      failure: (_) => false,
    );
  }

  Future<bool> cancel() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return false;
    final repo = ref.read(subscriptionRepositoryProvider);
    final r = await repo.cancel(uid);
    if (r is Success<void>) {
      state = Subscription.free();
      return true;
    }
    return false;
  }
}

final subscriptionViewModelProvider =
    NotifierProvider<SubscriptionViewModel, Subscription>(
        SubscriptionViewModel.new);
