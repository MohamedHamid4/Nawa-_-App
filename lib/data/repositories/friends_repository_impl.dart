import 'package:uuid/uuid.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/friendship.dart';
import '../datasources/remote/firestore_remote_datasource.dart';

class FriendsRepository {
  final FirestoreRemoteDatasource _firestore;
  static const _uuid = Uuid();

  FriendsRepository({required FirestoreRemoteDatasource firestore})
      : _firestore = firestore;

  /// Watches friendships for the given user. Each friendship doc contains the
  /// other user's display info already embedded for quick rendering.
  Stream<List<Friendship>> watchFriends(String uid) {
    return _firestore.watchFriends(uid).map((rows) =>
        rows.map((m) => Friendship.fromMap(Map<String, dynamic>.from(m))).toList());
  }

  Future<String?> sendRequest({
    required String selfUid,
    required String selfDisplayName,
    String? selfUsername,
    String? selfPhotoUrl,
    required String targetUsername,
  }) async {
    final targetUid = await _firestore.findUserIdByUsername(targetUsername);
    if (targetUid == null) return 'friends.user_not_found';
    if (targetUid == selfUid) return 'friends.user_not_found';

    final id = _uuid.v4();
    final now = DateTime.now();

    final targetProfile = await _firestore.getUserProfile(targetUid);
    final targetDisplayName =
        (targetProfile?['displayName'] as String?) ?? targetUsername;
    final targetPhoto = targetProfile?['photoUrl'] as String?;

    // Mirror on both sides.
    await _firestore.writeFriendship(
      uid: selfUid,
      data: {
        'id': id,
        'requesterId': selfUid,
        'addresseeId': targetUid,
        'status': FriendshipStatus.pending.name,
        'createdAt': now.millisecondsSinceEpoch,
        'otherDisplayName': targetDisplayName,
        'otherUsername': targetUsername,
        'otherPhotoUrl': targetPhoto,
      },
    );
    await _firestore.writeFriendship(
      uid: targetUid,
      data: {
        'id': id,
        'requesterId': selfUid,
        'addresseeId': targetUid,
        'status': FriendshipStatus.pending.name,
        'createdAt': now.millisecondsSinceEpoch,
        'otherDisplayName': selfDisplayName,
        'otherUsername': selfUsername,
        'otherPhotoUrl': selfPhotoUrl,
      },
    );
    return null;
  }

  Future<void> acceptRequest({
    required String selfUid,
    required Friendship friendship,
  }) async {
    final updated = {
      ...friendship.toMap(),
      'status': FriendshipStatus.accepted.name,
    };
    final otherUid = friendship.otherUserIdOf(selfUid);
    try {
      await _firestore.writeFriendship(uid: selfUid, data: updated);
      await _firestore.writeFriendship(uid: otherUid, data: updated);
    } catch (e) {
      AppLogger.w('acceptRequest failed: $e');
      rethrow;
    }
  }

  Future<void> declineOrRemove({
    required String selfUid,
    required Friendship friendship,
  }) async {
    final otherUid = friendship.otherUserIdOf(selfUid);
    try {
      await _firestore.deleteFriendship(selfUid, friendship.id);
      await _firestore.deleteFriendship(otherUid, friendship.id);
    } catch (e) {
      AppLogger.w('declineOrRemove failed: $e');
    }
  }
}
