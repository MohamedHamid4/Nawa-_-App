import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/local_datasource.dart';
import '../datasources/local/preferences_service.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/firestore_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final FirestoreRemoteDatasource _firestore;
  final LocalDatasource _local;
  final PreferencesService _prefs;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required FirestoreRemoteDatasource firestore,
    required LocalDatasource local,
    required PreferencesService prefs,
  })  : _remote = remote,
        _firestore = firestore,
        _local = local,
        _prefs = prefs;

  @override
  Stream<AppUser?> authStateChanges() => _remote.authStateChanges();

  @override
  AppUser? get currentUser => _remote.currentUser;

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      final v = await body();
      return Success(v);
    } on fb.FirebaseAuthException catch (e) {
      return FailureResult(AuthRemoteDatasource.mapException(e));
    } on AuthFailure catch (f) {
      return FailureResult(f);
    } catch (e, st) {
      AppLogger.e('auth error', e, st);
      return FailureResult(AuthFailure('auth.errors.unknown', cause: e));
    }
  }

  Future<Result<AppUser>> _afterSignIn(AppUser u) async {
    await _prefs.setLastUserId(u.uid);
    return Success(u);
  }

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final u = await _remote.signInWithEmail(email, password);
        await _prefs.setLastUserId(u.uid);
        return u;
      });

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final u = await _remote.signUpWithEmail(
          name: name,
          email: email,
          password: password,
        );
        await _prefs.setLastUserId(u.uid);
        return u;
      });

  @override
  Future<Result<AppUser>> signInWithGoogle() => _guard(() async {
        final u = await _remote.signInWithGoogle();
        return (await _afterSignIn(u)).dataOrNull ?? u;
      });

  @override
  Future<Result<AppUser>> signInWithApple() => _guard(() async {
        final u = await _remote.signInWithApple();
        return (await _afterSignIn(u)).dataOrNull ?? u;
      });

  @override
  Future<Result<AppUser>> signInAnonymously() => _guard(() async {
        final u = await _remote.signInAnonymously();
        return (await _afterSignIn(u)).dataOrNull ?? u;
      });

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _guard(() => _remote.sendPasswordReset(email));

  @override
  Future<Result<void>> signOut() => _guard(() async {
        await _remote.signOut();
        await _prefs.setLastUserId(null);
      });

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
        final u = _remote.rawCurrentUser;
        if (u == null) {
          throw const AuthFailure('auth.errors.user_not_found');
        }
        final uid = u.uid;
        // 1. delete all user notes from firestore
        await _firestore.deleteAllUserNotes(uid);
        // 2. Note: Cloudinary cleanup requires Admin API + signed deletion endpoint.
        // For now, files become orphaned after account deletion. Implement a
        // backend cleanup job in production.
        // 3. delete user doc
        await _firestore.deleteUserDoc(uid);
        // 4. wipe local hive
        await _local.wipeUser(uid);
        // 5. clear prefs.lastUserId
        await _prefs.setLastUserId(null);
        await _prefs.setSubscriptionPlan('free');
        await _prefs.setSubscriptionExpiry(null);
        // 6. delete the firebase user
        await _remote.deleteCurrentUser();
      });
}
