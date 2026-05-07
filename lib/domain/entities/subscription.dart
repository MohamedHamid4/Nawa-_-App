enum SubscriptionPlan { free, monthly, yearly }

class Subscription {
  final SubscriptionPlan plan;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool autoRenew;

  const Subscription({
    required this.plan,
    this.startDate,
    this.expiryDate,
    this.autoRenew = true,
  });

  factory Subscription.free() => const Subscription(plan: SubscriptionPlan.free);

  bool get isPremium {
    if (plan == SubscriptionPlan.free) return false;
    if (expiryDate == null) return true;
    return expiryDate!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toMap() => {
        'plan': plan.name,
        'startDate': startDate?.millisecondsSinceEpoch,
        'expiryDate': expiryDate?.millisecondsSinceEpoch,
        'autoRenew': autoRenew,
      };

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
        plan: SubscriptionPlan.values.firstWhere(
          (p) => p.name == (m['plan'] as String? ?? 'free'),
          orElse: () => SubscriptionPlan.free,
        ),
        startDate: m['startDate'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['startDate'] as int),
        expiryDate: m['expiryDate'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['expiryDate'] as int),
        autoRenew: (m['autoRenew'] as bool?) ?? true,
      );
}
