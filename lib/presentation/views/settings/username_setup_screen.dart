import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/extensions.dart';
import '../../viewmodels/auth_viewmodel.dart';

class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() =>
      _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _ctl = TextEditingController();
  String? _error;
  bool _saving = false;

  static final _validRe = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _ctl.text.trim().toLowerCase();
    if (!_validRe.hasMatch(username)) {
      setState(() => _error = 'friends.username_invalid'.tr());
      return;
    }
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(profileRepositoryProvider);
    final available = await repo.isUsernameAvailable(username);
    if (!available) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'friends.username_taken'.tr();
      });
      return;
    }
    await repo.claimUsername(username, user.uid);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('friends.username_set'.tr())),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('friends.set_username_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'friends.set_username_subtitle'.tr(),
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctl,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.alternate_email),
                hintText: 'friends.username_hint'.tr(),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('common.save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
