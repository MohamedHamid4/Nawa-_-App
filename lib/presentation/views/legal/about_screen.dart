import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/extensions.dart';
import '_legal_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openWebsite() async {
    final uri = Uri.parse('https://mohamedhamid4.github.io/MohamedHamid.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.about.hero_title'.tr(),
      subtitle: 'legal.about.hero_subtitle'.tr(),
      heroImage: 'assets/icons/app_icon.png',
      children: [
        LegalParagraph('legal.about.intro'.tr()),
        LegalSection(
          title: 'legal.about.mission_title'.tr(),
          children: [LegalParagraph('legal.about.mission_body'.tr())],
        ),
        LegalSection(
          title: 'legal.about.values_title'.tr(),
          children: [
            LegalBullet('legal.about.value_privacy'.tr()),
            LegalBullet('legal.about.value_offline'.tr()),
            LegalBullet('legal.about.value_arabic'.tr()),
            LegalBullet('legal.about.value_quality'.tr()),
          ],
        ),
        LegalSection(
          title: 'legal.about.credits_title'.tr(),
          children: [
            LegalParagraph('legal.about.credits_body'.tr()),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'legal.about.developer_name'.tr(),
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'legal.about.developer_role'.tr(),
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openWebsite,
                      icon: const Icon(Icons.public, size: 18),
                      label: Text('legal.about.visit_developer'.tr()),
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${'legal.about.version'.tr()} 1.0.0  •  ${'legal.about.build'.tr()} 1',
            style: context.text.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
