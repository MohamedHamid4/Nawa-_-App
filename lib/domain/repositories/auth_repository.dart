import '../../core/errors/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signInWithGoogle();
  Future<Result<AppUser>> signInWithApple();
  Future<Result<AppUser>> signInAnonymously();
  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
}
