import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/utils/responsive.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/app_text_field.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _uploading = false;
  String? _localPhotoUrl;
  String? _localDisplayName;

  String _initials(String name, String email) {
    final src = name.trim().isNotEmpty ? name : email;
    final parts =
        src.split(RegExp(r'[\s@.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  Future<void> _saveAvatar(String? value) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _localPhotoUrl = value ?? '');
    await ref.read(profileRepositoryProvider).save(
          uid: user.uid,
          photoUrl: value ?? '',
        );
    await ref.read(authViewModelProvider.notifier).refresh();
    if (mounted) setState(() {});
  }

  Future<void> _pickFromGallery() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(file.path, user.uid);
      if (url != null) {
        await _saveAvatar(url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.upload_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final colors = [
      0xFF4D9180, 0xFF6FB8A4, 0xFFC9A75C, 0xFF8B6F47,
      0xFF5C7AA8, 0xFFA85C7A, 0xFF7AA85C, 0xFFA87A5C,
      0xFF5CA8A8, 0xFFA85C5C, 0xFF8A5CA8, 0xFF5CA87A,
    ];

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'profile.choose_avatar'.tr(),
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: colors
                  .map((c) => GestureDetector(
                        onTap: () => Navigator.pop(ctx, c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initials(
                                user.displayName ?? '',
                                user.email ?? '',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
            ),
          ),
        ),
      ),
    );

    if (selected != null) {
      await _saveAvatar('avatar://${selected.toRadixString(16)}');
    }
  }

  void _showAvatarOptions() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final hasPhoto =
        (_localPhotoUrl ?? user.photoUrl)?.isNotEmpty == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('profile.choose_gallery'.tr()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.face_outlined),
                  title: Text('profile.choose_avatar_option'.tr()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _chooseAvatar();
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: Icon(Icons.delete_outline,
                        color: Theme.of(ctx).colorScheme.error),
                    title: Text(
                      'profile.remove_photo'.tr(),
                      style:
                          TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _saveAvatar('');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editDisplayName() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final ctrl = TextEditingController(
      text: _localDisplayName ?? user.displayName ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.edit_name'.tr()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'profile.name_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _localDisplayName = newName);
      await ref.read(profileRepositoryProvider).save(
            uid: user.uid,
            displayName: newName,
          );
      await ref.read(authViewModelProvider.notifier).refresh();
      if (mounted) setState(() {});
    }
  }

  Future<void> _confirmDelete() async {
    final ok1 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('settings.delete_account'.tr()),
        content: Text('settings.delete_account_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.continue'.tr()),
          ),
        ],
      ),
    );
    if (ok1 != true || !mounted) return;

    final controller = TextEditingController();
    final ok2 = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final canConfirm = controller.text.trim().toUpperCase() == 'DELETE';
        return AlertDialog(
          title: Text('settings.delete_account'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('settings.delete_account_confirm2'.tr()),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller,
                  hintText: 'DELETE',
                  onChanged: (_) => setS(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed:
                  canConfirm ? () => Navigator.pop(ctx, true) : null,
              child: Text('settings.delete_account'.tr()),
            ),
          ],
        );
      }),
    );

    if (ok2 != true || !mounted) return;

    final success =
        await ref.read(authViewModelProvider.notifier).deleteAccount();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.delete_account_done'.tr())),
      );
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final scheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('settings.profile'.tr())),
        body: Center(child: Text('common.error'.tr())),
      );
    }

    final displayName = (_localDisplayName ?? user.displayName)?.trim();
    final hasName = displayName != null && displayName.isNotEmpty;
    final shownName = hasName ? displayName : 'profile.set_your_name'.tr();
    final email = user.email ?? '';
    final photoSource = _localPhotoUrl ?? user.photoUrl ?? '';
    final hasPhoto = photoSource.isNotEmpty;
    final isAvatarColor = photoSource.startsWith('avatar://');
    final avatarColor = isAvatarColor
        ? Color(int.parse(photoSource.substring(9), radix: 16))
        : scheme.primaryContainer;

    final avatarSize = context.responsive<double>(
      phone: 120,
      smallPhone: 100,
      tablet: 144,
      largeTablet: 160,
    );
    final avatarFontSize = avatarSize * 0.35;

    return Scaffold(
      appBar: AppBar(title: Text('settings.profile'.tr())),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(
                phone: 24.0,
                smallPhone: 16.0,
                tablet: 32.0,
              ),
              vertical: context.responsive(phone: 32.0, smallPhone: 20.0),
            ),
            children: [
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _uploading ? null : _showAvatarOptions,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: (hasPhoto && !isAvatarColor)
                              ? CachedNetworkImage(
                                  imageUrl: photoSource,
                                  width: avatarSize,
                                  height: avatarSize,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Center(
                                    child: Text(
                                      _initials(shownName, email),
                                      style: TextStyle(
                                        color: scheme.onPrimaryContainer,
                                        fontSize: avatarFontSize,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _initials(shownName, email),
                                    style: TextStyle(
                                      color: isAvatarColor
                                          ? Colors.white
                                          : scheme.onPrimaryContainer,
                                      fontSize: avatarFontSize,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                if (_uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploading ? null : _showAvatarOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: scheme.surface, width: 3),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _editDisplayName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      shownName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: hasName
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.signIn);
            },
            icon: const Icon(Icons.logout),
            label: Text('common.logout'.tr()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: Icon(Icons.delete_outline, color: scheme.error),
            label: Text(
              'settings.delete_account'.tr(),
              style: TextStyle(color: scheme.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
