import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/services/share_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/note.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notes_list_viewmodel.dart';
import '../../viewmodels/subscription_viewmodel.dart';
import '../../widgets/common/ad_banner_widget.dart';
import '../../widgets/common/guest_lock_sheet.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/premium_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _uuid = Uuid();

  Future<void> _newNote() async {
    if (!await requireSignIn(context, ref,
        feature: 'guest.create_note_locked'.tr())) {
      return;
    }
    final auth = ref.read(authStateProvider).value;
    if (auth == null) return;
    final list = ref.read(notesListViewModelProvider).all;
    final isPremium = ref.read(subscriptionViewModelProvider).isPremium;
    if (!isPremium && list.length >= AppLimits.freeMaxNotes) {
      if (!mounted) return;
      context.push(AppRoutes.paywall);
      return;
    }
    final id = _uuid.v4();
    if (!mounted) return;
    context.push('${AppRoutes.noteEditor}/$id');
  }

  Future<void> _openNote(Note note) async {
    if (!await requireSignIn(context, ref,
        feature: 'guest.edit_locked'.tr())) {
      return;
    }
    await ref.read(adsServiceProvider).trackNavigationAndMaybeShow();
    if (!mounted) return;
    context.push('${AppRoutes.noteEditor}/${note.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesListViewModelProvider);
    final vm = ref.read(notesListViewModelProvider.notifier);
    final online = ref.watch(connectivityOnlineProvider).value ?? true;
    final sub = ref.watch(subscriptionViewModelProvider);
    final user = ref.watch(authStateProvider).value;
    final isGuest = user?.isGuest ?? false;

    final visible = state.visible;

    return Scaffold(
      drawer: _Drawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'home.title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub.isPremium) ...[
              const SizedBox(width: 8),
              const PremiumBadge(),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'common.search'.tr(),
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () => context.push(AppRoutes.calendar),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'notifications.title'.tr(),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              Consumer(builder: (context, ref, _) {
                final count = ref
                        .watch(unreadNotificationsCountProvider)
                        .valueOrNull ??
                    0;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!online)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'common.offline'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isGuest) const _GuestBanner(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsive(phone: 16.0, smallPhone: 12.0, tablet: 24.0),
              12,
              context.responsive(phone: 16.0, smallPhone: 12.0, tablet: 24.0),
              4,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'home.filter_all'.tr(),
                    selected: state.filter == NotesFilter.all,
                    onTap: () => vm.setFilter(NotesFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'home.filter_pinned'.tr(),
                    selected: state.filter == NotesFilter.pinned,
                    onTap: () => vm.setFilter(NotesFilter.pinned),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'home.filter_archived'.tr(),
                    selected: state.filter == NotesFilter.archived,
                    onTap: () => vm.setFilter(NotesFilter.archived),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.lightbulb_outline,
                    title: 'home.empty_title'.tr(),
                    subtitle: 'home.empty_subtitle'.tr(),
                  )
                : Builder(builder: (_) {
                    final adInterval = sub.isPremium ? 0 : 8;
                    final totalSlots = adInterval == 0
                        ? visible.length
                        : visible.length + (visible.length ~/ adInterval);
                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        context.responsive(
                          phone: 12.0,
                          smallPhone: 8.0,
                          tablet: 24.0,
                        ),
                        12,
                        context.responsive(
                          phone: 12.0,
                          smallPhone: 8.0,
                          tablet: 24.0,
                        ),
                        88,
                      ),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: context.responsive(
                          phone: 240.0,
                          smallPhone: 200.0,
                          tablet: 260.0,
                        ),
                        mainAxisExtent:
                            context.responsive(phone: 200.0, smallPhone: 180.0),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: totalSlots,
                      itemBuilder: (_, i) {
                        if (adInterval > 0 && (i + 1) % (adInterval + 1) == 0) {
                          return const NativeAdCard();
                        }
                        final noteIndex = adInterval == 0
                            ? i
                            : i - (i ~/ (adInterval + 1));
                        if (noteIndex >= visible.length) {
                          return const SizedBox.shrink();
                        }
                        final note = visible[noteIndex];
                        return _NoteCard(
                          note: note,
                          onTap: () => _openNote(note),
                          onLongPress: () => _showActions(context, note),
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newNote,
        icon: const Icon(Icons.add),
        label: Text('home.new_note'.tr()),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Note note) async {
    final vm = ref.read(notesListViewModelProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('common.edit'.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('${AppRoutes.noteEditor}/${note.id}');
              },
            ),
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.pinned ? 'note.unpin'.tr() : 'note.pin'.tr()),
              onTap: () {
                vm.togglePin(note);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text('note.change_color'.tr()),
              onTap: () {
                Navigator.pop(sheetContext);
                _showColorPicker(context, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text('common.share'.tr()),
              onTap: () async {
                Navigator.pop(sheetContext);
                final user = ref.read(authViewModelProvider).user;
                if (user?.isGuest ?? true) {
                  await showGuestLockSheet(context,
                      feature: 'guest.share_locked'.tr());
                  return;
                }
                await ShareService.shareAsText(note);
              },
            ),
            ListTile(
              leading: Icon(note.archived ? Icons.unarchive : Icons.archive_outlined),
              title: Text(note.archived ? 'note.unarchive'.tr() : 'note.archive'.tr()),
              onTap: () {
                vm.toggleArchive(note);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('note.delete'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  )),
              onTap: () async {
                Navigator.pop(sheetContext);
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'note.delete'.tr(),
                  message: 'note.delete_confirm'.tr(),
                  destructive: true,
                );
                if (ok) {
                  vm.delete(note);
                }
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context, Note note) async {
    const palette = <int?>[
      null,
      0xFFFFE0B2,
      0xFFFFCDD2,
      0xFFE1BEE7,
      0xFFC5CAE9,
      0xFFB2DFDB,
      0xFFC8E6C9,
      0xFFFFF9C4,
    ];
    final vm = ref.read(notesListViewModelProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'note.change_color'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: palette.map((c) {
                  final selected = note.colorValue == c;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await vm.setColor(note, c);
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c == null
                            ? Theme.of(ctx).colorScheme.surface
                            : Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(ctx).colorScheme.primary
                              : Theme.of(ctx).colorScheme.outline,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: c == null
                          ? Icon(Icons.format_color_reset_outlined,
                              size: 20,
                              color: Theme.of(ctx).colorScheme.onSurface)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? scheme.primary : scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = note.tags.take(2).toList();
    final cardColor =
        note.colorValue != null ? Color(note.colorValue!) : scheme.surface;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.pinned) ...[
                    Icon(Icons.push_pin, size: 14, color: scheme.tertiary),
                    const SizedBox(width: 4),
                  ],
                  if (note.encrypted) ...[
                    Icon(Icons.lock, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty
                          ? 'home.new_note'.tr()
                          : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.previewText(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 6),
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final t in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              if (note.reminderAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.alarm,
                          size: 12, color: scheme.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.reminderAt!.formatLocal(
                            pattern: 'MMM d, HH:mm',
                            locale: context.locale.languageCode,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Drawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final sub = ref.watch(subscriptionViewModelProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.person,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? user?.email ?? 'auth.guest'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isPremium)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: PremiumBadge(),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _DrawerItem(
                    icon: Icons.note_outlined,
                    label: 'home.title'.tr(),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerItem(
                    icon: Icons.search,
                    label: 'home.drawer_search'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.search);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'home.drawer_calendar'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.calendar);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspaces_outline,
                    label: 'home.drawer_workspaces'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.workspaces);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'home.drawer_subscription'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(
                        sub.isPremium
                            ? AppRoutes.subscription
                            : AppRoutes.paywall,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'home.drawer_settings'.tr(),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text('common.logout'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  )),
              onTap: () async {
                final ok = await ConfirmDialog.show(
                  context,
                  title: 'common.logout'.tr(),
                  message: 'common.logout_confirm'.tr(),
                  destructive: true,
                );
                if (ok) {
                  await ref.read(authViewModelProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.signIn);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallPhone;
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.responsive(phone: 16.0, smallPhone: 12.0, tablet: 24.0),
        12,
        context.responsive(phone: 16.0, smallPhone: 12.0, tablet: 24.0),
        0,
      ),
      padding: EdgeInsets.all(
        context.responsive(phone: 16.0, smallPhone: 12.0),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (!isSmall) ...[
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'guest.banner_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'guest.banner_subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.colors.primary,
              padding: EdgeInsets.symmetric(
                horizontal:
                    context.responsive(phone: 16.0, smallPhone: 10.0),
                vertical: 10,
              ),
            ),
            onPressed: () => context.go(AppRoutes.signUp),
            child: Text('guest.sign_up_now'.tr()),
          ),
        ],
      ),
    );
  }
}
