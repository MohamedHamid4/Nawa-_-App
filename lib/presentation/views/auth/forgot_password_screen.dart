import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok =
        await ref.read(authViewModelProvider.notifier).sendReset(_email.text);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.reset_link_sent'.tr())),
      );
    }
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
      appBar: AppBar(title: Text('auth.reset_password'.tr())),
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
                Text('auth.email'.tr(),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _email,
                  hintText: 'auth.email'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => Validators.email(v)?.tr(),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'auth.reset_password'.tr(),
                  loading: auth.loading,
                  onPressed: _submit,
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
