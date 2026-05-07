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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authViewModelProvider.notifier).signUp(
          _name.text.trim(),
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
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(
              phone: 24.0,
              smallPhone: 16.0,
              tablet: 48.0,
              largeTablet: 64.0,
            ),
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('auth.welcome'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('auth.create_account_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _name,
                  hintText: 'auth.name'.tr(),
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.name(v)?.tr(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _email,
                  hintText: 'auth.email'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => Validators.email(v)?.tr(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _password,
                  hintText: 'auth.password'.tr(),
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => Validators.password(v)?.tr(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _confirm,
                  hintText: 'auth.confirm_password'.tr(),
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      Validators.confirm(v, _password.text)?.tr(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'auth.sign_up'.tr(),
                  loading: auth.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.have_account'.tr()),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('auth.sign_in'.tr()),
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
