import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../domain/entities/subscription.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/premium_badge.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  String _planLabel(SubscriptionPlan p) {
    switch (p) {
      case SubscriptionPlan.free:
        return 'common.free'.tr();
      case SubscriptionPlan.monthly:
        return 'subscription.monthly'.tr();
      case SubscriptionPlan.yearly:
        return 'subscription.yearly'.tr();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionViewModelProvider);
    final vm = ref.read(subscriptionViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('subscription.manage_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        sub.isPremium
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline,
                        color: sub.isPremium
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'subscription.current_plan'.tr(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      if (sub.isPremium) const PremiumBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _planLabel(sub.plan),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (sub.expiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'subscription.expires'.tr(
                        namedArgs: {
                          'date': DateFormat.yMMMd(context.locale.toLanguageTag())
                              .format(sub.expiryDate!),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!sub.isPremium)
            AppButton(
              label: 'common.upgrade'.tr(),
              icon: Icons.arrow_forward,
              onPressed: () => context.push(AppRoutes.paywall),
            )
          else
            AppButton(
              label: 'subscription.cancel'.tr(),
              variant: AppButtonVariant.outline,
              color: Theme.of(context).colorScheme.error,
              onPressed: () async {
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'subscription.cancel'.tr(),
                  message: 'subscription.cancel_confirm'.tr(),
                  destructive: true,
                );
                if (ok) {
                  await vm.cancel();
                }
              },
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'subscription.restore'.tr(),
            variant: AppButtonVariant.text,
            onPressed: () async {
              final ok = await vm.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'subscription.restored'.tr()
                          : 'subscription.no_purchases'.tr(),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
