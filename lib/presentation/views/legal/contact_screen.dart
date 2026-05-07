import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/extensions.dart';
import '_legal_scaffold.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openMail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openDeveloperSite() async {
    final uri = Uri.parse('https://mohamedhamid4.github.io/MohamedHamid.com/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'legal.contact.hero_title'.tr(),
      subtitle: 'legal.contact.hero_subtitle'.tr(),
      heroIcon: Icons.mail_outline,
      children: [
        LegalSection(
          title: 'legal.contact.section_support_title'.tr(),
          children: [
            LegalParagraph('legal.contact.section_support_body'.tr()),
            _ContactCard(
              icon: Icons.support_agent,
              label: 'legal.contact.email_label'.tr(),
              value: 'support@nawa.app',
              onTap: () => _openMail('support@nawa.app'),
            ),
          ],
        ),
        LegalSection(
          title: 'legal.contact.section_business_title'.tr(),
          children: [
            LegalParagraph('legal.contact.section_business_body'.tr()),
            _ContactCard(
              icon: Icons.business,
              label: 'legal.contact.email_label'.tr(),
              value: 'business@nawa.app',
              onTap: () => _openMail('business@nawa.app'),
            ),
          ],
        ),
        LegalSection(
          title: 'legal.contact.section_developer_title'.tr(),
          children: [
            LegalParagraph('legal.contact.section_developer_body'.tr()),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openDeveloperSite,
                      icon: const Icon(Icons.public),
                      label: Text('legal.contact.developer_website'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, size: 16, color: context.colors.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'legal.contact.response_time'.tr(),
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
