enum NotificationType { noteCollaboration, friendRequest, system }

enum NotificationStatus { pending, accepted, declined, read }

class AppNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final NotificationType type;
  final NotificationStatus status;
  final String? noteId;
  final String? noteOwnerId;
  final String? noteTitle;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.type,
    required this.status,
    this.noteId,
    this.noteOwnerId,
    this.noteTitle,
    required this.createdAt,
  });

  bool get isPending => status == NotificationStatus.pending;

  factory AppNotification.fromMap(Map<String, dynamic> m, String id) {
    DateTime resolveDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      try {
        if (raw is DateTime) return raw;
        // Firestore Timestamp has a toDate() method.
        final dyn = raw as dynamic;
        return dyn.toDate() as DateTime;
      } catch (_) {
        if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
        return DateTime.now();
      }
    }

    return AppNotification(
      id: id,
      recipientId: (m['recipientId'] as String?) ?? '',
      senderId: (m['senderId'] as String?) ?? '',
      senderName: m['senderName'] as String?,
      senderAvatar: m['senderAvatar'] as String?,
      type: NotificationType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => NotificationType.system,
      ),
      status: NotificationStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => NotificationStatus.pending,
      ),
      noteId: m['noteId'] as String?,
      noteOwnerId: m['noteOwnerId'] as String?,
      noteTitle: m['noteTitle'] as String?,
      createdAt: resolveDate(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'type': type.name,
        'status': status.name,
        'noteId': noteId,
        'noteOwnerId': noteOwnerId,
        'noteTitle': noteTitle,
        'createdAt': createdAt,
      };
}
