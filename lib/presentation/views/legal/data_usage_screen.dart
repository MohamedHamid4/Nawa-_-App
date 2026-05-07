import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '_legal_scaffold.dart';

class DataUsageScreen extends StatelessWidget {
  const DataUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.data_usage.hero_title'.tr(),
      subtitle: 'legal.data_usage.hero_subtitle'.tr(),
      heroIcon: Icons.shield_outlined,
      children: [
        LegalSection(
          title: 'legal.data_usage.section_local_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_local_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_cloud_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_cloud_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_attachments_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_attachments_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_ai_title'.tr(),
          children: [LegalParagraph('legal.data_usage.section_ai_body'.tr())],
        ),
        LegalSection(
          title: 'legal.data_usage.section_metrics_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_metrics_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_offline_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_offline_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_export_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_export_body'.tr())
          ],
        ),
        LegalSection(
          title: 'legal.data_usage.section_delete_title'.tr(),
          children: [
            LegalParagraph('legal.data_usage.section_delete_body'.tr())
          ],
        ),
      ],
    );
  }
}
