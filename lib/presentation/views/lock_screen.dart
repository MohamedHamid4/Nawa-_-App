import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/utils/responsive.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  Future<void> _attemptUnlock() async {
    final bio = ref.read(biometricServiceProvider);
    if (!await bio.isAvailable()) {
      _proceed();
      return;
    }
    final reason = context.locale.languageCode == 'ar'
        ? 'استخدم البصمة لفتح نواة'
        : 'Use your fingerprint to unlock Nawa';
    try {
      final ok = await bio.authenticate(reason);
      if (!mounted) return;
      if (ok) {
        _proceed();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('biometric.error'.tr())),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('biometric.error'.tr())),
      );
    }
  }

  void _proceed() {
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(AppRoutes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBox = context.responsive<double>(
      phone: 120,
      smallPhone: 96,
      tablet: 144,
      largeTablet: 160,
    );
    final iconSize = iconBox * 0.55;
    final buttonMaxWidth = context.responsive<double>(
      phone: 320,
      tablet: 400,
    );
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(
                phone: 32.0,
                smallPhone: 20.0,
                tablet: 64.0,
              ),
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: buttonMaxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: context.responsive(phone: 32.0, smallPhone: 20.0),
                  ),
                  Text(
                    'auth.app_locked'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.biometric_unlock'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(
                    height: context.responsive(phone: 48.0, smallPhone: 28.0),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.fingerprint),
                      onPressed: _attemptUnlock,
                      label: Text(
                        'auth.unlock'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'auth.sign_out'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
