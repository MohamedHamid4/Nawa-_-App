import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/friendship.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/empty_state.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text('friends.title'.tr())),
        body: Center(child: Text('guest.friends_locked'.tr())),
      );
    }
    final repo = ref.watch(friendsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('friends.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'friends.show_qr'.tr(),
            onPressed: () => context.push(AppRoutes.qrCode),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'friends.scan_qr'.tr(),
            onPressed: () => context.push(AppRoutes.qrScan),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'friends.tab_friends'.tr()),
            Tab(text: 'friends.tab_requests'.tr()),
            Tab(text: 'friends.tab_search'.tr()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendSheet(context, _tabs),
        icon: const Icon(Icons.person_add),
        label: Text('friends.add_friend'.tr()),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.responsive(phone: double.infinity, tablet: 720.0),
          ),
          child: StreamBuilder<List<Friendship>>(
        stream: repo.watchFriends(user.uid),
        builder: (context, snap) {
          final all = snap.data ?? const <Friendship>[];
          final accepted = all.where((f) => f.isAccepted).toList();
          final pendingIncoming = all
              .where((f) => f.isPending && f.addresseeId == user.uid)
              .toList();
          return TabBarView(
            controller: _tabs,
            children: [
              _FriendsList(items: accepted, isRequest: false),
              _FriendsList(items: pendingIncoming, isRequest: true),
              _SearchTab(controller: _searchCtl),
            ],
          );
        },
          ),
        ),
      ),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  final List<Friendship> items;
  final bool isRequest;

  const _FriendsList({required this.items, required this.isRequest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      if (isRequest) {
        return EmptyState(
          icon: Icons.notifications_none,
          title: 'friends.no_requests_title'.tr(),
          subtitle: 'friends.no_requests_subtitle'.tr(),
        );
      }
      return _FriendsEmptyState(parentContext: context);
    }
    final user = ref.watch(authViewModelProvider).user;
    if (user == null) return const SizedBox.shrink();
    final repo = ref.read(friendsRepositoryProvider);
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final f = items[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.primaryContainer,
            backgroundImage:
                f.otherPhotoUrl != null && f.otherPhotoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(f.otherPhotoUrl!)
                    : null,
            child: (f.otherPhotoUrl == null || f.otherPhotoUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(f.otherDisplayName ?? f.otherUsername ?? 'User'),
          subtitle: f.otherUsername != null ? Text('@${f.otherUsername}') : null,
          trailing: isRequest
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check_circle,
                          color: context.colors.primary),
                      onPressed: () async {
                        await repo.acceptRequest(
                          selfUid: user.uid,
                          friendship: f,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('friends.request_accepted'.tr())),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel,
                          color: context.colors.error),
                      onPressed: () async {
                        await repo.declineOrRemove(
                          selfUid: user.uid,
                          friendship: f,
                        );
                      },
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: ListTile(
                          leading: Icon(Icons.person_remove,
                              color: Theme.of(ctx).colorScheme.error),
                          title: Text('friends.remove'.tr()),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await repo.declineOrRemove(
                              selfUid: user.uid,
                              friendship: f,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SearchTab extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _SearchTab({required this.controller});

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  bool _sending = false;

  Future<void> _send() async {
    final username = widget.controller.text.trim().toLowerCase();
    if (username.isEmpty) return;
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    setState(() => _sending = true);
    final repo = ref.read(friendsRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);
    final me = await profileRepo.loadCurrent();
    final err = await repo.sendRequest(
      selfUid: user.uid,
      selfDisplayName: me?.displayName ?? user.email ?? 'User',
      selfUsername: me?.username,
      selfPhotoUrl: me?.photoUrl,
      targetUsername: username,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err != null ? err.tr() : 'friends.request_sent'.tr()),
      ),
    );
    if (err == null) widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'friends.search_hint'.tr(),
            ),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text('friends.send_request'.tr()),
          ),
        ],
      ),
    );
  }
}

void _showAddFriendSheet(BuildContext context, TabController? tabs) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text('friends.show_my_qr'.tr()),
            subtitle: Text('friends.my_qr_subtitle'.tr()),
            onTap: () {
              Navigator.of(sheet).pop();
              context.push(AppRoutes.qrCode);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: Text('friends.scan_qr'.tr()),
            onTap: () {
              Navigator.of(sheet).pop();
              context.push(AppRoutes.qrScan);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('friends.search_username'.tr()),
            onTap: () {
              Navigator.of(sheet).pop();
              tabs?.animateTo(2);
            },
          ),
          const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

class _FriendsEmptyState extends StatelessWidget {
  final BuildContext parentContext;
  const _FriendsEmptyState({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 64,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'friends.empty_title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'friends.empty_subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => parentContext.push(AppRoutes.qrCode),
              icon: const Icon(Icons.qr_code_2),
              label: Text('friends.show_my_qr'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => parentContext.push(AppRoutes.qrScan),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text('friends.scan_qr'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                final state = parentContext
                    .findAncestorStateOfType<_FriendsScreenState>();
                state?._tabs.animateTo(2);
              },
              icon: const Icon(Icons.search),
              label: Text('friends.search_username'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
