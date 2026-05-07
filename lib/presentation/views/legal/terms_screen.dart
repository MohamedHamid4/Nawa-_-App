import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/extensions.dart';
import '_legal_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.terms.hero_title'.tr(),
      heroIcon: Icons.description_outlined,
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
                  '${'legal.terms.last_updated'.tr()}: ${'legal.terms.effective_date'.tr()}',
                  style: context.text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LegalParagraph('legal.terms.intro'.tr()),
        LegalSection(
          title: 'legal.terms.section_account_title'.tr(),
          children: [LegalParagraph('legal.terms.section_account_body'.tr())],
        ),
        LegalSection(
          title: 'legal.terms.section_use_title'.tr(),
          children: [LegalParagraph('legal.terms.section_use_body'.tr())],
        ),
        LegalSection(
          title: 'legal.terms.section_content_title'.tr(),
          children: [LegalParagraph('legal.terms.section_content_body'.tr())],
        ),
        LegalSection(
          title: 'legal.terms.section_subscription_title'.tr(),
          children: [
            LegalParagraph('legal.terms.section_subscription_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.terms.section_termination_title'.tr(),
          children: [
            LegalParagraph('legal.terms.section_termination_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.terms.section_disclaimer_title'.tr(),
          children: [
            LegalParagraph('legal.terms.section_disclaimer_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.terms.section_liability_title'.tr(),
          children: [LegalParagraph('legal.terms.section_liability_body'.tr())],
        ),
        LegalSection(
          title: 'legal.terms.section_law_title'.tr(),
          children: [LegalParagraph('legal.terms.section_law_body'.tr())],
        ),
        LegalSection(
          title: 'legal.terms.section_changes_title'.tr(),
          children: [LegalParagraph('legal.terms.section_changes_body'.tr())],
        ),
      ],
    );
  }
}
