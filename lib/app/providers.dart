import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/connectivity_service.dart';
import '../core/services/ads_service.dart';
import '../core/services/ai_service_impl.dart';
import '../core/services/biometric_service.dart';
import '../core/services/cloudinary_storage_service.dart';
import '../core/services/encryption_service.dart';
import '../core/services/link_preview_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/ocr_service.dart';
import '../core/services/subscription_service.dart';
import '../core/services/sync_service.dart';
import '../core/services/voice_service.dart';
import '../data/datasources/local/local_datasource.dart';
import '../data/datasources/local/preferences_service.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/firestore_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/collaboration_repository.dart';
import '../data/repositories/friends_repository_impl.dart';
import '../data/repositories/note_repository_impl.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/repositories/subscription_repository_impl.dart';
import '../domain/entities/app_notification.dart';
import '../domain/entities/user.dart';
import '../domain/repositories/ai_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../domain/repositories/subscription_repository.dart';

// ── Bootstrap (overridden in main.dart) ─────────────────────
final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  throw UnimplementedError('localDatasourceProvider must be overridden');
});

final prefsProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('prefsProvider must be overridden');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

// ── Core services ───────────────────────────────────────────
final connectivityProvider = Provider<ConnectivityService>((ref) {
  final s = ConnectivityService();
  s.init();
  ref.onDispose(s.dispose);
  return s;
});

final adsServiceProvider = Provider<AdsService>((ref) {
  final s = AdsService();
  s.init();
  return s;
});

final aiServiceProvider = Provider<AiService>((ref) => HttpAiService());

final ocrServiceProvider = Provider<OcrService>((ref) {
  final s = OcrService();
  ref.onDispose(s.dispose);
  return s;
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final s = VoiceService();
  ref.onDispose(s.dispose);
  return s;
});

final linkPreviewServiceProvider =
    Provider<LinkPreviewService>((ref) => LinkPreviewService());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

final encryptionServiceProvider =
    Provider<EncryptionService>((ref) => EncryptionService());

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(ref.watch(prefsProvider)),
);

// ── Datasources ─────────────────────────────────────────────
final authRemoteProvider =
    Provider<AuthRemoteDatasource>((ref) => AuthRemoteDatasource());

final firestoreRemoteProvider =
    Provider<FirestoreRemoteDatasource>((ref) => FirestoreRemoteDatasource());

final cloudinaryStorageProvider = Provider<CloudinaryStorageService>(
  (ref) => CloudinaryStorageService(),
);

// ── Repositories ────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteProvider),
    firestore: ref.watch(firestoreRemoteProvider),
    local: ref.watch(localDatasourceProvider),
    prefs: ref.watch(prefsProvider),
  );
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final repo = NoteRepositoryImpl(
    local: ref.watch(localDatasourceProvider),
    remote: ref.watch(firestoreRemoteProvider),
    connectivity: ref.watch(connectivityProvider),
    cloudinary: ref.watch(cloudinaryStorageProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => LocalPurchaseRepository(ref.watch(prefsProvider)),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    remote: ref.watch(firestoreRemoteProvider),
    prefs: ref.watch(prefsProvider),
    purchase: ref.watch(purchaseRepositoryProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    auth: ref.watch(authRemoteProvider),
    firestore: ref.watch(firestoreRemoteProvider),
    cloudinary: ref.watch(cloudinaryStorageProvider),
  );
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(
    firestore: ref.watch(firestoreRemoteProvider),
  );
});

final collaborationRepositoryProvider =
    Provider<CollaborationRepository>((ref) {
  return CollaborationRepository(FirebaseFirestore.instance);
});

final notificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(collaborationRepositoryProvider).watchNotifications(user.uid);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(collaborationRepositoryProvider).watchUnreadCount(user.uid);
});

// ── App-level state ─────────────────────────────────────────
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final connectivityOnlineProvider = StreamProvider<bool>((ref) {
  final s = ref.watch(connectivityProvider);
  return s.onChange;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final s = SyncService(
    notes: ref.watch(noteRepositoryProvider),
    connectivity: ref.watch(connectivityProvider),
  );
  s.start();
  ref.onDispose(s.stop);
  return s;
});
