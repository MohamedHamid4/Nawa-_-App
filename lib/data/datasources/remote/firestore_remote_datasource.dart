import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/note.dart';
import '../../models/pending_op.dart';

class FirestoreRemoteDatasource {
  final FirebaseFirestore _db;

  FirestoreRemoteDatasource({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCol(String uid) => _db
      .collection(FsCollections.users)
      .doc(uid)
      .collection(FsCollections.notes);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(FsCollections.users).doc(uid);

  DocumentReference<Map<String, dynamic>> _subscriptionDoc(String uid) =>
      _db
          .collection(FsCollections.users)
          .doc(uid)
          .collection(FsCollections.subscription)
          .doc('current');

  Stream<List<Note>> watchNotes(String uid) {
    return _notesCol(uid)
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Note.fromMap(Map<String, dynamic>.from(d.data())))
            .toList());
  }

  Future<Note?> getNote(String uid, String id) async {
    final snap = await _notesCol(uid).doc(id).get();
    if (!snap.exists) return null;
    return Note.fromMap(Map<String, dynamic>.from(snap.data()!));
  }

  Future<void> upsertNote(Note note) async {
    await _notesCol(note.userId).doc(note.id).set(note.toMap());
  }

  Future<void> markNoteDeleted(String uid, String id) async {
    await _notesCol(uid).doc(id).set({
      'id': id,
      'userId': uid,
      'deleted': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> commitOpsBatch(List<PendingOp> ops) async {
    final chunks = <List<PendingOp>>[];
    for (var i = 0; i < ops.length; i += AppLimits.firestoreBatchMax) {
      chunks.add(ops.sublist(
        i,
        i + AppLimits.firestoreBatchMax > ops.length
            ? ops.length
            : i + AppLimits.firestoreBatchMax,
      ));
    }
    for (final chunk in chunks) {
      final batch = _db.batch();
      for (final op in chunk) {
        switch (op.kind) {
          case PendingOpKind.upsert:
            if (op.snapshot != null) {
              batch.set(
                _notesCol(op.userId).doc(op.noteId),
                op.snapshot!,
              );
            }
          case PendingOpKind.delete:
            batch.set(
              _notesCol(op.userId).doc(op.noteId),
              {
                'id': op.noteId,
                'userId': op.userId,
                'deleted': true,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              SetOptions(merge: true),
            );
        }
      }
      await batch.commit();
    }
  }

  Future<void> deleteAllUserNotes(String uid) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await _notesCol(uid).limit(AppLimits.firestoreBatchMax).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.isNotEmpty);
  }

  Future<void> deleteUserDoc(String uid) async {
    try {
      await _userDoc(uid).delete();
    } catch (_) {}
    try {
      await _subscriptionDoc(uid).delete();
    } catch (_) {}
  }

  // Subscription
  DocumentReference<Map<String, dynamic>> subscriptionDoc(String uid) =>
      _subscriptionDoc(uid);

  // ─── User profile ───────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<void> upsertUserProfile(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots().map((s) => s.data());
  }

  // ─── Usernames ──────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _usernamesCol() =>
      _db.collection('usernames');

  Future<bool> isUsernameAvailable(String username) async {
    final snap = await _usernamesCol().doc(username).get();
    return !snap.exists;
  }

  Future<void> claimUsername(String username, String uid) async {
    final batch = _db.batch();
    batch.set(_usernamesCol().doc(username), {
      'userId': uid,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.set(_userDoc(uid), {'username': username}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<String?> findUserIdByUsername(String username) async {
    final snap = await _usernamesCol().doc(username).get();
    if (!snap.exists) return null;
    return snap.data()?['userId'] as String?;
  }

  // ─── Friends ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _friendsCol(String uid) =>
      _userDoc(uid).collection('friends');

  Future<void> writeFriendship({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final id = data['id'] as String;
    await _friendsCol(uid).doc(id).set(data, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchFriends(String uid) {
    return _friendsCol(uid).snapshots().map(
          (s) => s.docs.map((d) => d.data()).toList(),
        );
  }

  Future<void> deleteFriendship(String uid, String friendshipId) async {
    await _friendsCol(uid).doc(friendshipId).delete();
  }
}
