import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../core/extensions/extensions.dart';
import '../../../domain/entities/user.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  AppUser? _user;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _bioCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(profileRepositoryProvider);
    final user = await repo.loadCurrent();
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameCtl.text = user?.displayName ?? '';
      _bioCtl.text = user?.bio ?? '';
      _photoUrl = user?.photoUrl;
      _loading = false;
    });
  }

  Future<void> _changePhoto() async {
    final user = _user;
    if (user == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final url = await ref
        .read(profileRepositoryProvider)
        .uploadAvatar(picked.path, user.uid);
    if (!mounted) return;
    setState(() {
      _photoUrl = url ?? _photoUrl;
      _uploading = false;
    });
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).save(
            uid: user.uid,
            displayName: _nameCtl.text.trim(),
            bio: _bioCtl.text.trim(),
            photoUrl: _photoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.saved'.tr())),
        );
      }
      // refresh auth state to reflect updated displayName
      await ref.read(authViewModelProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('profile.title'.tr())),
        body: Center(child: Text('common.error'.tr())),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: context.colors.primaryContainer,
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(_photoUrl!)
                      : null,
                  child: (_photoUrl == null || _photoUrl!.isEmpty)
                      ? Icon(Icons.person,
                          size: 48, color: context.colors.primary)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: context.colors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploading ? null : _changePhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _uploading ? null : _changePhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text('profile.edit_photo'.tr()),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtl,
            decoration: InputDecoration(
              labelText: 'profile.name'.tr(),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioCtl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'profile.bio'.tr(),
              hintText: 'profile.bio_hint'.tr(),
              prefixIcon: const Icon(Icons.short_text),
            ),
          ),
          const SizedBox(height: 12),
          _ReadOnlyRow(
            icon: Icons.email_outlined,
            label: 'profile.email'.tr(),
            value: user.email ?? '—',
          ),
          if (user.username != null && user.username!.isNotEmpty)
            _ReadOnlyRow(
              icon: Icons.alternate_email,
              label: 'friends.username_hint'.tr(),
              value: '@${user.username!}',
            ),
          _ReadOnlyRow(
            icon: Icons.fingerprint,
            label: 'profile.user_id'.tr(),
            value: user.uid,
          ),
          if (user.createdAt != null)
            _ReadOnlyRow(
              icon: Icons.event_outlined,
              label: 'profile.joined'.tr(),
              value: user.createdAt!.toLocal().toString().split('.').first,
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
                : Text('profile.save'.tr()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: context.text.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.lock_outline,
              size: 16, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
