import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

class CollaborationRepository {
  final FirebaseFirestore _firestore;
  CollaborationRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _noteDoc(
    String ownerId,
    String noteId,
  ) =>
      _firestore
          .collection('users')
          .doc(ownerId)
          .collection('notes')
          .doc(noteId);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Future<void> inviteCollaborator({
    required String noteId,
    required String noteOwnerId,
    required String noteTitle,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String recipientId,
  }) async {
    await _noteDoc(noteOwnerId, noteId).set({
      'pendingInviteIds': FieldValue.arrayUnion([recipientId]),
    }, SetOptions(merge: true));

    await _notifications.add({
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': NotificationType.noteCollaboration.name,
      'status': NotificationStatus.pending.name,
      'noteId': noteId,
      'noteOwnerId': noteOwnerId,
      'noteTitle': noteTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptInvitation(AppNotification notif,
      {required String noteOwnerId}) async {
    if (notif.noteId == null) return;
    final batch = _firestore.batch();
    batch.set(
      _noteDoc(noteOwnerId, notif.noteId!),
      {
        'collaboratorIds': FieldValue.arrayUnion([notif.recipientId]),
        'pendingInviteIds': FieldValue.arrayRemove([notif.recipientId]),
      },
      SetOptions(merge: true),
    );
    batch.update(_notifications.doc(notif.id), {
      'status': NotificationStatus.accepted.name,
    });
    await batch.commit();
  }

  Future<void> declineInvitation(AppNotification notif,
      {required String noteOwnerId}) async {
    final batch = _firestore.batch();
    if (notif.noteId != null) {
      batch.set(
        _noteDoc(noteOwnerId, notif.noteId!),
        {
          'pendingInviteIds':
              FieldValue.arrayRemove([notif.recipientId]),
        },
        SetOptions(merge: true),
      );
    }
    batch.update(_notifications.doc(notif.id), {
      'status': NotificationStatus.declined.name,
    });
    await batch.commit();
  }

  Future<void> markAsRead(String notifId) async {
    await _notifications.doc(notifId).update({
      'status': NotificationStatus.read.name,
    });
  }

  Future<void> removeCollaborator({
    required String noteId,
    required String noteOwnerId,
    required String userId,
  }) async {
    await _noteDoc(noteOwnerId, noteId).update({
      'collaboratorIds': FieldValue.arrayRemove([userId]),
    });
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
