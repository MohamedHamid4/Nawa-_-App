import '../../core/services/cloudinary_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/firestore_remote_datasource.dart';

class ProfileRepository {
  final AuthRemoteDatasource _auth;
  final FirestoreRemoteDatasource _firestore;
  final CloudinaryStorageService _cloudinary;

  ProfileRepository({
    required AuthRemoteDatasource auth,
    required FirestoreRemoteDatasource firestore,
    required CloudinaryStorageService cloudinary,
  })  : _auth = auth,
        _firestore = firestore,
        _cloudinary = cloudinary;

  /// Load the current user's profile, merging Firebase auth + Firestore profile doc.
  Future<AppUser?> loadCurrent() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      final doc = await _firestore.getUserProfile(fbUser.uid);
      if (doc == null) return fbUser;
      return fbUser.copyWith(
        displayName: doc['displayName'] as String? ?? fbUser.displayName,
        photoUrl: doc['photoUrl'] as String? ?? fbUser.photoUrl,
        username: doc['username'] as String?,
        bio: doc['bio'] as String?,
        createdAt: doc['createdAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(doc['createdAt'] as int)
            : null,
      );
    } catch (e) {
      AppLogger.w('loadCurrent failed: $e');
      return fbUser;
    }
  }

  Future<void> save({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _firestore.upsertUserProfile(uid, data);
    await _auth.updateProfile(displayName: displayName, photoUrl: photoUrl);
  }

  Future<String?> uploadAvatar(String localPath, String uid) async {
    return _cloudinary.uploadAvatar(localPath: localPath, userId: uid);
  }

  Future<bool> isUsernameAvailable(String username) =>
      _firestore.isUsernameAvailable(username);

  Future<void> claimUsername(String username, String uid) =>
      _firestore.claimUsername(username, uid);
}
