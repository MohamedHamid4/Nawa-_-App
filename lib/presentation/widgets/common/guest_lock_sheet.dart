import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/extensions.dart';

/// Returns true if the user is allowed to proceed (not a guest).
/// Returns false and shows the lock sheet if the user is a guest.
Future<bool> requireSignIn(BuildContext context, WidgetRef ref,
    {String? feature}) async {
  final user = ref.read(authRepositoryProvider).currentUser;
  if (user == null || user.isGuest) {
    if (context.mounted) {
      await showGuestLockSheet(context, feature: feature);
    }
    return false;
  }
  return true;
}

/// Shown when a guest user tries to use a feature that requires sign-in.
/// Returns true if the user chose to sign up.
Future<bool> showGuestLockSheet(BuildContext context, {String? feature}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ctx.colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: ctx.colors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ctx.colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 36,
                    color: ctx.colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'guest.locked_title'.tr(),
                  style: ctx.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  feature ?? 'guest.locked_subtitle'.tr(),
                  style: ctx.text.bodyMedium?.copyWith(
                    color: ctx.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.person_add_outlined),
                    onPressed: () {
                      Navigator.pop(ctx, true);
                      GoRouter.of(ctx).go(AppRoutes.signUp);
                    },
                    label: Text('guest.sign_up_now'.tr()),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx, false);
                      GoRouter.of(ctx).go(AppRoutes.signIn);
                    },
                    child: Text('guest.sign_in_existing'.tr()),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('common.cancel'.tr()),
                ),
              ],
              ),
            ),
          ),
        ),
      ) ??
      false;
}
