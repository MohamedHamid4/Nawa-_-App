import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier).signIn(
          _email.text.trim(),
          _password.text,
        );
    if (ok && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final vm = ref.read(authViewModelProvider.notifier);

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (next.failure != null && next.failure != prev?.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure!.message.tr())),
        );
        vm.clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(
              phone: 24.0,
              smallPhone: 16.0,
              tablet: 48.0,
              largeTablet: 64.0,
            ),
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text('auth.welcome_back'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('auth.sign_in_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _email,
                  hintText: 'auth.email'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    final key = Validators.email(v);
                    return key?.tr();
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _password,
                  hintText: 'auth.password'.tr(),
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => Validators.password(v)?.tr(),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgot),
                    child: Text('auth.forgot_password'.tr()),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'auth.sign_in'.tr(),
                  loading: auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('auth.or_continue_with'.tr(),
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'auth.google'.tr(),
                  variant: AppButtonVariant.outline,
                  icon: Icons.g_mobiledata,
                  loading: auth.loading,
                  onPressed: () async {
                    final ok = await vm.google();
                    if (ok && mounted) context.go(AppRoutes.home);
                  },
                ),
                if (Platform.isIOS || Platform.isMacOS) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'auth.apple'.tr(),
                    variant: AppButtonVariant.outline,
                    icon: Icons.apple,
                    loading: auth.loading,
                    onPressed: () async {
                      final ok = await vm.apple();
                      if (ok && mounted) context.go(AppRoutes.home);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: 'auth.guest'.tr(),
                  variant: AppButtonVariant.text,
                  onPressed: () async {
                    final ok = await vm.guest();
                    if (ok && mounted) context.go(AppRoutes.home);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.no_account'.tr()),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.signUp),
                      child: Text('auth.sign_up'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}
