import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/extensions/extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/app_notification.dart';
import '../../widgets/common/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text('notifications.title'.tr())),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: stream.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.notifications_none,
                  title: 'notifications.empty'.tr(),
                  subtitle: '',
                );
              }
              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(
                    phone: 16.0,
                    smallPhone: 12.0,
                    tablet: 24.0,
                  ),
                  vertical: 12,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _NotificationCard(notif: items[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notif;
  const _NotificationCard({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(collaborationRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final senderName = notif.senderName ?? '?';

    String body;
    switch (notif.type) {
      case NotificationType.noteCollaboration:
        body = 'notifications.invitation_to_collaborate'
            .tr(args: [senderName, notif.noteTitle ?? '']);
      case NotificationType.friendRequest:
      case NotificationType.system:
        body = senderName;
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isPending
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant,
          width: notif.isPending ? 1.4 : 0.8,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: (notif.senderAvatar != null &&
                        notif.senderAvatar!.isNotEmpty &&
                        !notif.senderAvatar!.startsWith('avatar://'))
                    ? CachedNetworkImageProvider(notif.senderAvatar!)
                    : null,
                child: (notif.senderAvatar == null ||
                        notif.senderAvatar!.isEmpty ||
                        notif.senderAvatar!.startsWith('avatar://'))
                    ? Text(
                        senderName.characters.firstOrNull?.toUpperCase() ??
                            '?',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: notif.isPending
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.createdAt
                          .relative(context.locale.languageCode),
                      style: context.text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notif.type == NotificationType.noteCollaboration &&
              notif.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: notif.noteOwnerId == null
                        ? null
                        : () async {
                            await repo.declineInvitation(
                              notif,
                              noteOwnerId: notif.noteOwnerId!,
                            );
                          },
                    icon: const Icon(Icons.close),
                    label: Text('notifications.decline'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: notif.noteOwnerId == null
                        ? null
                        : () async {
                            await repo.acceptInvitation(
                              notif,
                              noteOwnerId: notif.noteOwnerId!,
                            );
                            if (!context.mounted) return;
                            if (notif.noteId != null) {
                              context.push(
                                '${AppRoutes.noteEditor}/${notif.noteId}',
                              );
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: Text('notifications.accept'.tr()),
                  ),
                ),
              ],
            ),
          ] else if (notif.status == NotificationStatus.accepted &&
              notif.type == NotificationType.noteCollaboration) ...[
            const SizedBox(height: 8),
            Text(
              'notifications.accepted'.tr(),
              style: context.text.bodySmall?.copyWith(color: scheme.primary),
            ),
          ] else if (notif.status == NotificationStatus.declined) ...[
            const SizedBox(height: 8),
            Text(
              'notifications.declined'.tr(),
              style: context.text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
