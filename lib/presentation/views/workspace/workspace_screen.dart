import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../domain/entities/user.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  static const _uuid = Uuid();

  static const _palette = [
    0xFF4D9180,
    0xFF3E6D9C,
    0xFFC9A75C,
    0xFFC0413B,
    0xFF7A5BBE,
    0xFF4F6E3D,
    0xFFCB6E2D,
    0xFF2A8084,
  ];

  static const _emojis = [
    '🗂️', '📒', '✨', '🌙', '🌿', '☕', '🎯', '💡',
    '📚', '🧩', '🎨', '🛒', '🏠', '💼', '🍃', '🪴',
  ];

  List<Workspace> _load() {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return [];
    return ref.read(localDatasourceProvider).getWorkspaces(auth.uid);
  }

  Future<void> _save(List<Workspace> ws) async {
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    await ref.read(localDatasourceProvider).setWorkspaces(auth.uid, ws);
    setState(() {});
  }

  Future<void> _editor({Workspace? existing}) async {
    final controller =
        TextEditingController(text: existing?.name ?? '');
    String emoji = existing?.emoji ?? _emojis.first;
    int color = existing?.colorValue ?? _palette.first;

    final saved = await showModalBottomSheet<Workspace?>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) {
        return StatefulBuilder(builder: (sheet, setS) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheet).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null
                      ? 'workspace.new'.tr()
                      : 'workspace.edit'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: controller,
                  hintText: 'workspace.name_hint'.tr(),
                ),
                const SizedBox(height: 16),
                Text('workspace.emoji'.tr(),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _emojis)
                      InkWell(
                        onTap: () => setS(() => emoji = e),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: emoji == e
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('workspace.color'.tr(),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in _palette)
                      InkWell(
                        onTap: () => setS(() => color = c),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == c
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'common.save'.tr(),
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(sheet).pop(
                      Workspace(
                        id: existing?.id ?? _uuid.v4(),
                        name: name,
                        emoji: emoji,
                        colorValue: color,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
      },
    );

    if (saved != null) {
      final list = _load();
      final idx = list.indexWhere((w) => w.id == saved.id);
      if (idx >= 0) {
        list[idx] = saved;
      } else {
        list.add(saved);
      }
      await _save(list);
    }
  }

  Future<void> _delete(Workspace w) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'workspace.delete'.tr(),
      message: 'workspace.delete_confirm'.tr(),
      destructive: true,
    );
    if (!ok) return;
    final list = _load().where((x) => x.id != w.id).toList();
    await _save(list);
  }

  @override
  Widget build(BuildContext context) {
    final list = _load();
    return Scaffold(
      appBar: AppBar(title: Text('workspace.title'.tr())),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.workspaces_outline,
              title: 'workspace.empty_title'.tr(),
              subtitle: 'workspace.empty_subtitle'.tr(),
              action: AppButton(
                label: 'workspace.new'.tr(),
                fullWidth: false,
                onPressed: _editor,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final w = list[i];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(w.colorValue).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(w.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    title: Text(w.name),
                    onTap: () => _editor(existing: w),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: () => _delete(w),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _editor,
              icon: const Icon(Icons.add),
              label: Text('workspace.new'.tr()),
            ),
    );
  }
}
