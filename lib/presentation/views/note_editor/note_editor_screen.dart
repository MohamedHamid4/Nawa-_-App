import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/share_service.dart';
import '../../../core/theme/note_font_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/note_block.dart';
import '../../../domain/usecases/note_usecases.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/note_editor_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/guest_lock_sheet.dart';
import '../../widgets/common/reminder_picker.dart';
import '../../widgets/common/tag_input.dart';
import '../../widgets/note_blocks/audio_block_widget.dart';
import '../../widgets/note_blocks/checklist_block_widget.dart';
import '../../widgets/note_blocks/file_block_widget.dart';
import '../../widgets/note_blocks/image_block_widget.dart';
import '../../widgets/note_blocks/link_block_widget.dart';
import '../../widgets/note_blocks/text_block_widget.dart';
import '../../widgets/note_blocks/video_block_widget.dart';
import 'recorder_dialog.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _scheduleReminderNotif(Note note) async {
    if (note.reminderAt == null) return;
    final svc = ref.read(notificationServiceProvider);
    final id = note.id.hashCode & 0x7FFFFFFF;
    try {
      await svc.scheduleReminder(
        id: id,
        title: note.title.isEmpty ? 'app.name'.tr() : note.title,
        body: 'note.reminder'.tr(),
        when: note.reminderAt!,
      );
    } catch (_) {}
  }

  Future<void> _addImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final block = NoteBlockFactory.newImage(localPath: picked.path);
    ref.read(noteEditorViewModelProvider(widget.noteId).notifier).addBlock(block);
  }

  Future<void> _addImageWithOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
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
                  title: Text('editor.image_from_gallery'.tr()),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text('editor.image_from_camera'.tr()),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked == null) return;
    final block = NoteBlockFactory.newImage(localPath: picked.path);
    ref
        .read(noteEditorViewModelProvider(widget.noteId).notifier)
        .addBlock(block);
  }

  Future<void> _addVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final block = NoteBlockFactory.newVideo(localPath: picked.path);
    ref.read(noteEditorViewModelProvider(widget.noteId).notifier).addBlock(block);
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final block = NoteBlockFactory.newFile(
      fileName: f.name,
      localPath: f.path,
      size: f.size,
    );
    ref.read(noteEditorViewModelProvider(widget.noteId).notifier).addBlock(block);
  }

  Future<void> _addLink() async {
    ref
        .read(noteEditorViewModelProvider(widget.noteId).notifier)
        .addBlock(NoteBlockFactory.newLink(''));
  }

  Future<void> _addAudio() async {
    final localeId = context.locale.languageCode == 'ar' ? 'ar' : 'en_US';
    final result = await showDialog<RecorderResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecorderDialog(localeId: localeId),
    );
    if (result == null) return;
    final block = AudioBlock(
      id: NoteBlockFactory.newAudio().id,
      updatedAt: DateTime.now(),
      localPath: result.path,
      durationMs: result.durationMs,
      transcript: result.transcript,
    );
    ref.read(noteEditorViewModelProvider(widget.noteId).notifier).addBlock(block);
  }

  Future<void> _runOcr(ImageBlock block) async {
    final isPremium = ref.read(subscriptionViewModelProvider).isPremium;
    if (!isPremium) {
      _gateAi();
      return;
    }
    final path = block.localPath;
    if (path == null) return;
    final ocr = ref.read(ocrServiceProvider);
    ref
        .read(noteEditorViewModelProvider(widget.noteId).notifier)
        .setAiBusy('ocr');
    final r = await ocr.extractText(path,
        locale: context.locale.languageCode);
    ref
        .read(noteEditorViewModelProvider(widget.noteId).notifier)
        .setAiBusy(null);
    r.when(
      success: (text) {
        if (text.trim().isEmpty) return;
        ref
            .read(noteEditorViewModelProvider(widget.noteId).notifier)
            .insertBlockAfter(block.id, NoteBlockFactory.newText(text: text));
      },
      failure: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ai.error'.tr())),
          );
        }
      },
    );
  }

  Future<void> _summarize() async {
    final user = ref.read(authViewModelProvider).user;
    if (user?.isGuest ?? true) {
      await showGuestLockSheet(context, feature: 'guest.ai_locked'.tr());
      return;
    }
    final isPremium = ref.read(subscriptionViewModelProvider).isPremium;
    if (!isPremium) {
      _gateAi();
      return;
    }
    final vm = ref.read(noteEditorViewModelProvider(widget.noteId).notifier);
    final text = vm.fullPlainText().trim();
    if (text.length < AppLimits.summarizeMinChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ai.error_text_too_short'.tr())),
      );
      return;
    }
    vm.setAiBusy('summarize');
    final use = SummarizeNote(ref.read(aiServiceProvider));
    final r = await use.call(text, context.locale.languageCode);
    vm.setAiBusy(null);
    r.when(
      success: vm.setSummary,
      failure: (f) {
        if (!mounted) return;
        final code = f is AiFailure ? f.code : 'unknown';
        final msgKey = switch (code) {
          'text_too_short' => 'ai.error_text_too_short',
          'api_key_invalid' => 'ai.error_key_invalid',
          'quota_exceeded' => 'ai.error_quota',
          'no_internet' => 'ai.error_no_internet',
          'empty_response' => 'ai.error_empty',
          'blocked' => 'ai.error_blocked',
          _ => 'ai.error_unknown',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgKey.tr()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _extractTasks() async {
    final user = ref.read(authViewModelProvider).user;
    if (user?.isGuest ?? true) {
      await showGuestLockSheet(context, feature: 'guest.ai_locked'.tr());
      return;
    }
    final isPremium = ref.read(subscriptionViewModelProvider).isPremium;
    if (!isPremium) {
      _gateAi();
      return;
    }
    final vm = ref.read(noteEditorViewModelProvider(widget.noteId).notifier);
    final text = vm.fullPlainText().trim();
    if (text.isEmpty) return;
    vm.setAiBusy('tasks');
    final use = ExtractTasks(ref.read(aiServiceProvider));
    final r = await use.call(text, context.locale.languageCode);
    vm.setAiBusy(null);
    r.when(
      success: (block) => vm.addBlock(block),
      failure: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ai.error'.tr())),
          );
        }
      },
    );
  }

  Future<void> _gateAi() async {
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ai.premium_required'.tr()),
        content: Text('subscription.subtitle'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'ad'),
            child: Text('ai.watch_ad'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'upgrade'),
            child: Text('common.upgrade'.tr()),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'upgrade') {
      context.push(AppRoutes.paywall);
    } else if (action == 'ad') {
      final ok = await ref.read(adsServiceProvider).showRewarded();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ai.ad_unlocked'.tr())),
        );
      }
    }
  }

  void _showMetadata(BuildContext context, Note note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final vm =
            ref.read(noteEditorViewModelProvider(widget.noteId).notifier);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('note.metadata'.tr(),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('note.summary'.tr(),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  note.aiSummary?.trim().isNotEmpty == true
                      ? note.aiSummary!
                      : 'note.no_summary'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Divider(height: 24),
                Text('note.tags_hint'.tr(),
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TagInput(
                  tags: note.tags,
                  onChanged: vm.setTags,
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm),
                  title: Text(
                    note.reminderAt != null
                        ? 'note.reminder'.tr()
                        : 'note.set_reminder'.tr(),
                  ),
                  subtitle: note.reminderAt == null
                      ? Text('note.no_reminder'.tr())
                      : Text(note.reminderAt!.toLocal().toString()),
                  trailing: note.reminderAt == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            vm.setReminder(null);
                            Navigator.pop(sheetCtx);
                          },
                        ),
                  onTap: () async {
                    final picked = await ReminderPicker.show(context,
                        initial: note.reminderAt);
                    if (picked != null) {
                      vm.setReminder(picked);
                      final updated = ref
                          .read(noteEditorViewModelProvider(widget.noteId))
                          .note;
                      if (updated != null) {
                        await _scheduleReminderNotif(updated);
                      }
                    }
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(note.pinned ? 'note.unpin'.tr() : 'note.pin'.tr()),
                  value: note.pinned,
                  onChanged: vm.setPinned,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(note.archived
                      ? 'note.unarchive'.tr()
                      : 'note.archive'.tr()),
                  value: note.archived,
                  onChanged: vm.setArchived,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('note.encrypt'.tr()),
                  value: note.encrypted,
                  onChanged: (v) async {
                    final user = ref.read(authViewModelProvider).user;
                    if (v && (user?.isGuest ?? true)) {
                      Navigator.pop(sheetCtx);
                      await showGuestLockSheet(context,
                          feature: 'guest.encrypt_locked'.tr());
                      return;
                    }
                    final isPremium =
                        ref.read(subscriptionViewModelProvider).isPremium;
                    if (v && !isPremium) {
                      Navigator.pop(sheetCtx);
                      context.push(AppRoutes.paywall);
                      return;
                    }
                    vm.setEncrypted(v);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noteEditorViewModelProvider(widget.noteId));
    final vm = ref.read(noteEditorViewModelProvider(widget.noteId).notifier);
    final note = state.note;

    if (state.loading || note == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_titleController.text != note.title) {
      _titleController.value = TextEditingValue(
        text: note.title,
        selection: TextSelection.collapsed(offset: note.title.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await vm.saveNow();
            final n = ref.read(noteEditorViewModelProvider(widget.noteId)).note;
            if (n != null) await _scheduleReminderNotif(n);
            if (context.mounted) context.pop();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (state.lastSavedAt != null)
              Icon(Icons.cloud_done_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                state.saving
                    ? 'common.saving'.tr()
                    : state.lastSavedAt != null
                        ? 'common.saved'.tr()
                        : '',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'ai.menu'.tr(),
            onSelected: (v) {
              if (v == 'summarize') _summarize();
              if (v == 'tasks') _extractTasks();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'summarize',
                child: Row(
                  children: [
                    const Icon(Icons.summarize_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('ai.summarize'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'tasks',
                child: Row(
                  children: [
                    const Icon(Icons.checklist, size: 18),
                    const SizedBox(width: 8),
                    Text('ai.extract_tasks'.tr()),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: context.locale.languageCode == 'ar' ? 'الخط' : 'Font',
            onPressed: () => _showFontStylePicker(context, vm),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'common.share'.tr(),
            onPressed: () => _showShareSheet(context, note),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showMetadata(context, note),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: 'note.delete'.tr(),
                message: 'note.delete_confirm'.tr(),
                destructive: true,
              );
              if (ok) {
                await vm.deleteSelf();
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(
                  context.responsive(
                    phone: 16.0,
                    smallPhone: 12.0,
                    tablet: 24.0,
                  ),
                  8,
                  context.responsive(
                    phone: 16.0,
                    smallPhone: 12.0,
                    tablet: 24.0,
                  ),
                  12,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.done,
                  style: NoteFontStyles.getStyle(
                    style: note.fontStyle,
                    isArabic: context.locale.languageCode == 'ar',
                    fontSize: 22,
                  ).copyWith(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: context.locale.languageCode == 'ar'
                        ? 'عنوان المذكرة'
                        : 'Note title',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onChanged: vm.updateTitle,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.fromLTRB(
                    context.responsive(phone: 8.0, smallPhone: 4.0, tablet: 16.0),
                    8,
                    context.responsive(phone: 8.0, smallPhone: 4.0, tablet: 16.0),
                    120,
                  ),
                  onReorder: vm.reorder,
                  itemCount: note.blocks.length,
                  itemBuilder: (context, index) {
                    final block = note.blocks[index];
                    final widgetForBlock = _buildBlock(block);
                    return Padding(
                      key: ValueKey(block.id),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding:
                                  EdgeInsets.only(top: 16, left: 4, right: 4),
                              child: Icon(Icons.drag_indicator,
                                  size: 18, color: Colors.grey),
                            ),
                          ),
                          Expanded(child: widgetForBlock),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
              ),
            ),
          ),
          if (state.aiBusyAction != null)
            const _AiBusyOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBlockSheet(context, vm),
        tooltip: 'note.add_block'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddBlockSheet(
      BuildContext context, NoteEditorViewModel vm) async {
    await showModalBottomSheet<void>(
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
              'note.add_block'.tr(),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _BlockTile(
                  icon: Icons.text_fields,
                  label: 'note.blocks.text'.tr(),
                  color: const Color(0xFF4D9180),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.addBlock(NoteBlockFactory.newText());
                  },
                ),
                _BlockTile(
                  icon: Icons.checklist,
                  label: 'note.blocks.checklist'.tr(),
                  color: const Color(0xFF3E6D9C),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.addBlock(NoteBlockFactory.newChecklist());
                  },
                ),
                _BlockTile(
                  icon: Icons.image_outlined,
                  label: 'note.blocks.image'.tr(),
                  color: const Color(0xFFC9A75C),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addImage();
                  },
                  onLongPress: () {
                    Navigator.pop(ctx);
                    _addImageWithOptions();
                  },
                ),
                _BlockTile(
                  icon: Icons.videocam_outlined,
                  label: 'note.blocks.video'.tr(),
                  color: const Color(0xFFB48BE0),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addVideo();
                  },
                ),
                _BlockTile(
                  icon: Icons.mic_none_outlined,
                  label: 'note.blocks.audio'.tr(),
                  color: const Color(0xFFE07A74),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addAudio();
                  },
                ),
                _BlockTile(
                  icon: Icons.attach_file_outlined,
                  label: 'note.blocks.file'.tr(),
                  color: const Color(0xFF5BBFA8),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addFile();
                  },
                ),
                _BlockTile(
                  icon: Icons.link,
                  label: 'note.blocks.link'.tr(),
                  color: const Color(0xFF6FA3D6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addLink();
                  },
                ),
              ],
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFontStylePicker(BuildContext context, NoteEditorViewModel vm) {
    final isArabic = context.locale.languageCode == 'ar';

    showModalBottomSheet<void>(
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
              isArabic ? 'اختر نوع الخط' : 'Choose font style',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),
            ...NoteFontStyle.values.map((style) {
              final currentNote =
                  ref.read(noteEditorViewModelProvider(widget.noteId)).note;
              final isSelected = currentNote?.fontStyle == style;
              return InkWell(
                onTap: () {
                  vm.updateFontStyle(style);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(ctx).colorScheme.primaryContainer
                        : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(ctx).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          NoteFontStyles.previewText(style, isArabic),
                          style: NoteFontStyles.getStyle(
                            style: style,
                            isArabic: isArabic,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          NoteFontStyles.displayName(style, isArabic),
                          style:
                              Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: Theme.of(ctx).colorScheme.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showShareSheet(BuildContext context, Note note) async {
    final user = ref.read(authViewModelProvider).user;
    if (user?.isGuest ?? true) {
      await showGuestLockSheet(context, feature: 'guest.share_locked'.tr());
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add_outlined,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                title: Text(
                  'share.invite_friend'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('share.invite_friend_subtitle'.tr()),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInviteFriendsSheet(note);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text('share.share_pdf'.tr()),
                subtitle: Text('share.share_pdf_subtitle'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ShareService.shareAsPdf(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text('share.download_pdf'.tr()),
                subtitle: Text('share.download_pdf_subtitle'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await ShareService.downloadAsPdf(note);
                  if (!context.mounted) return;
                  if (file == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ai.error_unknown'.tr())),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'share.pdf_saved'.tr(
                          args: [file.path.split(Platform.pathSeparator).last],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: Text('share.share_text'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ShareService.shareAsText(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('share.copy_to_clipboard'.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ShareService.copyToClipboard(note);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('share.copied'.tr())),
                    );
                  }
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showInviteFriendsSheet(Note note) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final friendsRepo = ref.read(friendsRepositoryProvider);
    final collabRepo = ref.read(collaborationRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StreamBuilder(
            stream: friendsRepo.watchFriends(user.uid),
            builder: (_, snap) {
              final friends = (snap.data ?? const [])
                  .where((f) => f.isAccepted)
                  .toList();
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Text(
                      'share.invite_to_note'.tr(),
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Expanded(
                    child: friends.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 56,
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'share.no_friends_yet'.tr(),
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'share.no_friends_subtitle'.tr(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.push(AppRoutes.friends);
                                    },
                                    icon: const Icon(Icons.person_add),
                                    label: Text(
                                      'share.go_to_friends'.tr(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtl,
                            itemCount: friends.length,
                            itemBuilder: (_, i) {
                              final f = friends[i];
                              final friendId = f.otherUserIdOf(user.uid);
                              final friendName =
                                  f.otherDisplayName ?? friendId;
                              final alreadyCollab =
                                  note.collaboratorIds.contains(friendId);
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    friendName.characters.firstOrNull
                                            ?.toUpperCase() ??
                                        '?',
                                  ),
                                ),
                                title: Text(friendName),
                                trailing: alreadyCollab
                                    ? Chip(
                                        label: Text(
                                          'share.already_collaborator'.tr(),
                                        ),
                                      )
                                    : FilledButton(
                                        onPressed: () async {
                                          await collabRepo
                                              .inviteCollaborator(
                                            noteId: note.id,
                                            noteOwnerId: note.userId,
                                            noteTitle: note.title,
                                            senderId: user.uid,
                                            senderName: user.displayName ??
                                                user.email ??
                                                'Nawa user',
                                            senderAvatar: user.photoUrl,
                                            recipientId: friendId,
                                          );
                                          if (!context.mounted) return;
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'share.invitation_sent'
                                                    .tr(args: [friendName]),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text('share.invite'.tr()),
                                      ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(NoteBlock block) {
    final vm = ref.read(noteEditorViewModelProvider(widget.noteId).notifier);
    final note = ref.read(noteEditorViewModelProvider(widget.noteId)).note;
    final fontStyle = note?.fontStyle ?? NoteFontStyle.defaultStyle;
    switch (block) {
      case TextBlock t:
        return TextBlockWidget(
          key: ValueKey('text-${t.id}'),
          block: t,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(t.id),
          noteFontStyle: fontStyle,
        );
      case ChecklistBlock c:
        return ChecklistBlockWidget(
          key: ValueKey('check-${c.id}'),
          block: c,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(c.id),
        );
      case ImageBlock i:
        return ImageBlockWidget(
          key: ValueKey('img-${i.id}'),
          block: i,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(i.id),
          onOcr: () => _runOcr(i),
        );
      case VideoBlock v:
        return VideoBlockWidget(
          key: ValueKey('vid-${v.id}'),
          block: v,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(v.id),
        );
      case AudioBlock a:
        return AudioBlockWidget(
          key: ValueKey('aud-${a.id}'),
          block: a,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(a.id),
        );
      case FileBlock f:
        return FileBlockWidget(
          key: ValueKey('file-${f.id}'),
          block: f,
          onRemove: () => vm.removeBlock(f.id),
        );
      case LinkBlock l:
        return LinkBlockWidget(
          key: ValueKey('link-${l.id}'),
          block: l,
          onChanged: vm.updateBlock,
          onRemove: () => vm.removeBlock(l.id),
        );
    }
  }
}

class _BlockTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BlockTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AiBusyOverlay extends StatelessWidget {
  const _AiBusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Text('ai.working'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
