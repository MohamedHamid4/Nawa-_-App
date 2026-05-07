import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/extensions.dart';
import '_legal_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.privacy.hero_title'.tr(),
      heroIcon: Icons.lock_outline,
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
                  '${'legal.privacy.last_updated'.tr()}: ${'legal.privacy.effective_date'.tr()}',
                  style: context.text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LegalParagraph('legal.privacy.intro'.tr()),
        LegalSection(
          title: 'legal.privacy.section_collect_title'.tr(),
          children: [
            LegalBullet('legal.privacy.section_collect_account'.tr()),
            LegalBullet('legal.privacy.section_collect_content'.tr()),
            LegalBullet('legal.privacy.section_collect_device'.tr()),
          ],
        ),
        LegalSection(
          title: 'legal.privacy.section_use_title'.tr(),
          children: [LegalParagraph('legal.privacy.section_use_body'.tr())],
        ),
        LegalSection(
          title: 'legal.privacy.section_ai_title'.tr(),
          children: [LegalParagraph('legal.privacy.section_ai_body'.tr())],
        ),
        LegalSection(
          title: 'legal.privacy.section_ads_title'.tr(),
          children: [LegalParagraph('legal.privacy.section_ads_body'.tr())],
        ),
        LegalSection(
          title: 'legal.privacy.section_security_title'.tr(),
          children: [
            LegalParagraph('legal.privacy.section_security_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.privacy.section_rights_title'.tr(),
          children: [LegalParagraph('legal.privacy.section_rights_body'.tr())],
        ),
        LegalSection(
          title: 'legal.privacy.section_children_title'.tr(),
          children: [
            LegalParagraph('legal.privacy.section_children_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.privacy.section_changes_title'.tr(),
          children: [LegalParagraph('legal.privacy.section_changes_body'.tr())],
        ),
        LegalSection(
          title: 'legal.privacy.section_contact_title'.tr(),
          children: [
            LegalParagraph('legal.privacy.section_contact_body'.tr()),
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
