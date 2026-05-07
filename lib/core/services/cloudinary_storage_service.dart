import 'package:cloudinary_public/cloudinary_public.dart';

import '../../config/env.dart';
import '../utils/app_logger.dart';

/// Cloudinary-backed media storage. Replaces Firebase Storage.
/// Free tier: 25 credits/month (~25GB storage + 25GB bandwidth).
class CloudinaryStorageService {
  late final CloudinaryPublic _cloudinary;

  CloudinaryStorageService() {
    _cloudinary = CloudinaryPublic(
      Env.cloudinaryCloudName,
      Env.cloudinaryUploadPreset,
      cache: false,
    );
  }

  bool get isConfigured => Env.cloudinaryCloudName.isNotEmpty;

  CloudinaryResourceType _resourceTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) {
      return CloudinaryResourceType.Image;
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'].contains(ext)) {
      return CloudinaryResourceType.Video;
    }
    return CloudinaryResourceType.Auto;
  }

  /// Upload a local file. Returns the secure URL on success, null on failure.
  Future<String?> upload({
    required String localPath,
    required String userId,
    required String noteId,
    required String blockId,
  }) async {
    if (!isConfigured) {
      AppLogger.w('Cloudinary not configured — skipping upload');
      return null;
    }

    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          localPath,
          resourceType: _resourceTypeFor(localPath),
          folder: 'nawa/$userId/$noteId',
          publicId: blockId,
        ),
      );
      AppLogger.i('Cloudinary uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      AppLogger.e('Cloudinary upload failed: ${e.message}', e);
      return null;
    } catch (e, st) {
      AppLogger.e('Cloudinary upload error', e, st);
      return null;
    }
  }

  /// Upload a profile avatar; returns the secure URL on success.
  Future<String?> uploadAvatar({
    required String localPath,
    required String userId,
  }) async {
    if (!isConfigured) return null;
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          localPath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'nawa/avatars',
          publicId: userId,
        ),
      );
      return response.secureUrl;
    } catch (e, st) {
      AppLogger.e('avatar upload error', e, st);
      return null;
    }
  }
}
