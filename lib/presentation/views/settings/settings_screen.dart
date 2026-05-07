import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../viewmodels/locale_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../widgets/common/premium_badge.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometric = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    final p = ref.read(prefsProvider);
    _biometric = p.biometricEnabled;
    _notifications = p.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeViewModelProvider);
    final locale = ref.watch(localeViewModelProvider);
    final sub = ref.watch(subscriptionViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(label: 'settings.appearance'.tr()),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text('settings.theme'.tr()),
            subtitle: Text(_themeLabel(theme)),
            onTap: () => _showThemePicker(theme),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text('settings.language'.tr()),
            subtitle: Text(
              locale.languageCode == 'ar'
                  ? 'settings.language_ar'.tr()
                  : 'settings.language_en'.tr(),
            ),
            onTap: _showLanguagePicker,
          ),
          _SectionHeader(label: 'settings.account'.tr()),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('settings.profile'.tr()),
            onTap: () => context.push(AppRoutes.account),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: Text('settings.subscription'.tr()),
            trailing: sub.isPremium ? const PremiumBadge() : null,
            onTap: () => context.push(
              sub.isPremium ? AppRoutes.subscription : AppRoutes.paywall,
            ),
          ),
          _SectionHeader(label: 'settings.security'.tr()),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text('settings.biometric'.tr()),
            value: _biometric,
            onChanged: (v) async {
              setState(() => _biometric = v);
              await ref.read(prefsProvider).setBiometricEnabled(v);
            },
          ),
          _SectionHeader(label: 'settings.notifications'.tr()),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text('settings.enable_notifications'.tr()),
            value: _notifications,
            onChanged: (v) async {
              setState(() => _notifications = v);
              await ref.read(prefsProvider).setNotificationsEnabled(v);
              if (!v) {
                await ref.read(notificationServiceProvider).cancelAll();
              }
            },
          ),
          _SectionHeader(label: 'settings.data'.tr()),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text('settings.clear_cache'.tr()),
            onTap: () async {
              await ref.read(localDatasourceProvider).clearCacheBox();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('settings.cache_cleared'.tr())),
                );
              }
            },
          ),
          _SectionHeader(label: 'settings.legal'.tr()),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('settings.about'.tr()),
            onTap: () => context.push(AppRoutes.about),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('settings.privacy'.tr()),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text('settings.terms'.tr()),
            onTap: () => context.push(AppRoutes.terms),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text('settings.contact'.tr()),
            onTap: () => context.push(AppRoutes.contact),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text('settings.data_usage'.tr()),
            onTap: () => context.push(AppRoutes.dataUsage),
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions_outlined),
            title: Text('settings.subscription_terms'.tr()),
            onTap: () => context.push(AppRoutes.subscriptionTerms),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${'settings.version'.tr()} 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'settings.theme_light'.tr();
      case ThemeMode.dark:
        return 'settings.theme_dark'.tr();
      case ThemeMode.system:
        return 'settings.theme_system'.tr();
    }
  }

  void _showThemePicker(ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in ThemeMode.values)
              ListTile(
                leading: Icon(
                  m == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: m == current
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(_themeLabel(m)),
                onTap: () async {
                  await ref
                      .read(themeViewModelProvider.notifier)
                      .setMode(m);
                  if (sheet.mounted) Navigator.of(sheet).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final outerContext = context;
    final currentCode = outerContext.locale.languageCode;
    showModalBottomSheet<void>(
      context: outerContext,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: Text('settings.language_ar'.tr()),
              trailing: currentCode == 'ar'
                  ? Icon(Icons.check_circle,
                      color: Theme.of(sheet).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.of(sheet).pop();
                ref
                    .read(localeViewModelProvider.notifier)
                    .setLocale(outerContext, const Locale('ar'));
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text('settings.language_en'.tr()),
              trailing: currentCode == 'en'
                  ? Icon(Icons.check_circle,
                      color: Theme.of(sheet).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.of(sheet).pop();
                ref
                    .read(localeViewModelProvider.notifier)
                    .setLocale(outerContext, const Locale('en'));
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
