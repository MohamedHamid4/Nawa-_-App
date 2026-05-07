import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/extensions.dart';
import '_legal_scaffold.dart';

class SubscriptionTermsScreen extends StatelessWidget {
  const SubscriptionTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.subscription_terms.hero_title'.tr(),
      heroIcon: Icons.workspace_premium_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.event,
                  size: 20, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${'legal.subscription_terms.last_updated'.tr()}: ${'legal.subscription_terms.effective_date'.tr()}',
                  style: context.text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LegalParagraph('legal.subscription_terms.intro'.tr()),
        LegalSection(
          title: 'legal.subscription_terms.section_plans_title'.tr(),
          children: [
            LegalParagraph('legal.subscription_terms.section_plans_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_premium_title'.tr(),
          children: [
            LegalParagraph(
                'legal.subscription_terms.section_premium_includes'.tr()),
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_billing_title'.tr(),
          children: [
            LegalParagraph(
                'legal.subscription_terms.section_billing_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_cancel_title'.tr(),
          children: [
            LegalParagraph('legal.subscription_terms.section_cancel_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_refund_title'.tr(),
          children: [
            LegalParagraph('legal.subscription_terms.section_refund_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_trial_title'.tr(),
          children: [
            LegalParagraph('legal.subscription_terms.section_trial_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_changes_title'.tr(),
          children: [
            LegalParagraph(
                'legal.subscription_terms.section_changes_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_family_title'.tr(),
          children: [
            LegalParagraph('legal.subscription_terms.section_family_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.subscription_terms.section_contact_title'.tr(),
          children: [
            LegalParagraph(
                'legal.subscription_terms.section_contact_body'.tr()),
            const SizedBox(height: 4),
            Text(
              'support@nawa.app',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
