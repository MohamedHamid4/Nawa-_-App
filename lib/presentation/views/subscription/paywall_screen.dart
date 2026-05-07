import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/subscription.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/common/app_button.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPlan _selected = SubscriptionPlan.yearly;
  bool _loading = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(subscriptionViewModelProvider.notifier)
        .subscribe(_selected);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.success'.tr())),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.error'.tr())),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final ok =
        await ref.read(subscriptionViewModelProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'subscription.restored'.tr() : 'subscription.no_purchases'.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 360,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lightTertiary, AppColors.lightPrimary],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'subscription.title'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'subscription.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('subscription.features_title'.tr(),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _Feature(text: 'subscription.feature_unlimited'.tr()),
                          _Feature(text: 'subscription.feature_ai'.tr()),
                          _Feature(text: 'subscription.feature_no_ads'.tr()),
                          _Feature(text: 'subscription.feature_storage'.tr()),
                          _Feature(text: 'subscription.feature_themes'.tr()),
                          _Feature(
                              text: 'subscription.feature_encryption'.tr()),
                          _Feature(
                              text: 'subscription.feature_priority_sync'.tr()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Text(
                              'subscription.comparison_title'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          _ComparisonRow(
                            label: 'subscription.row_notes'.tr(),
                            free: 'subscription.row_notes_free'.tr(),
                            premium: 'subscription.row_notes_premium'.tr(),
                          ),
                          _ComparisonRow(
                            label: 'subscription.row_ai'.tr(),
                            free: 'subscription.row_ai_free'.tr(),
                            premium: 'subscription.row_ai_premium'.tr(),
                          ),
                          _ComparisonRow(
                            label: 'subscription.row_ads'.tr(),
                            free: 'subscription.row_ads_free'.tr(),
                            premium: 'subscription.row_ads_premium'.tr(),
                          ),
                          _ComparisonRow(
                            label: 'subscription.row_storage'.tr(),
                            free: 'subscription.row_storage_free'.tr(),
                            premium: 'subscription.row_storage_premium'.tr(),
                          ),
                          _ComparisonRow(
                            label: 'subscription.row_encryption'.tr(),
                            free: 'subscription.row_encryption_free'.tr(),
                            premium:
                                'subscription.row_encryption_premium'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PriceCard(
                    selected: _selected == SubscriptionPlan.yearly,
                    title: 'subscription.yearly'.tr(),
                    price: 'subscription.yearly_price'.tr(),
                    period: 'subscription.per_year'.tr(),
                    badge: 'subscription.save_badge'.tr(),
                    onTap: () =>
                        setState(() => _selected = SubscriptionPlan.yearly),
                  ),
                  const SizedBox(height: 12),
                  _PriceCard(
                    selected: _selected == SubscriptionPlan.monthly,
                    title: 'subscription.monthly'.tr(),
                    price: 'subscription.monthly_price'.tr(),
                    period: 'subscription.per_month'.tr(),
                    onTap: () =>
                        setState(() => _selected = SubscriptionPlan.monthly),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'subscription.cta_subscribe'.tr(),
                    loading: _loading,
                    onPressed: _subscribe,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'subscription.auto_renew_disclosure'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _restore,
                        child: Text('subscription.restore'.tr()),
                      ),
                      Text('•',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4))),
                      TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.subscriptionTerms),
                        child: Text('subscription.terms_link'.tr()),
                      ),
                      Text('•',
                          style: TextStyle(
                              color: scheme.onSurface.withValues(alpha: 0.4))),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.privacy),
                        child: Text('subscription.privacy_link'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String text;
  const _Feature({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: scheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String free;
  final String premium;
  const _ComparisonRow({
    required this.label,
    required this.free,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String price;
  final String period;
  final String? badge;
  final VoidCallback onTap;

  const _PriceCard({
    required this.selected,
    required this.title,
    required this.price,
    required this.period,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: 2,
                ),
                color: selected ? scheme.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.tertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: price,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: ' $period',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
