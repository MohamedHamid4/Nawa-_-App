import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/user.dart';

class AuthRemoteDatasource {
  final fb.FirebaseAuth _auth;
  AuthRemoteDatasource({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  fb.User? get rawCurrentUser => _auth.currentUser;

  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _map(u);
  }

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map((u) => u == null ? null : _map(u));
  }

  AppUser _map(fb.User u) => AppUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
        isAnonymous: u.isAnonymous,
      );

  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _map(cred.user!);
  }

  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (name.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(name.trim());
    }
    return _map(cred.user!);
  }

  Future<AppUser> signInWithGoogle() async {
    final google = GoogleSignIn();
    final account = await google.signIn();
    if (account == null) {
      throw const AuthFailure('auth.errors.operation_not_allowed');
    }
    final googleAuth = await account.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _map(cred.user!);
  }

  Future<AppUser> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      throw const AuthFailure('auth.errors.operation_not_allowed');
    }
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauth = fb.OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    final cred = await _auth.signInWithCredential(oauth);
    return _map(cred.user!);
  }

  Future<AppUser> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return _map(cred.user!);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.delete();
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final u = _auth.currentUser;
    if (u == null) return;
    if (displayName != null) await u.updateDisplayName(displayName);
    if (photoUrl != null) await u.updatePhotoURL(photoUrl);
  }

  static AuthFailure mapException(fb.FirebaseAuthException e) {
    final code = e.code;
    final mapping = {
      'user-not-found': 'auth.errors.user_not_found',
      'wrong-password': 'auth.errors.wrong_password',
      'invalid-credential': 'auth.errors.wrong_password',
      'invalid-login-credentials': 'auth.errors.wrong_password',
      'email-already-in-use': 'auth.errors.email_in_use',
      'weak-password': 'auth.errors.weak_password',
      'invalid-email': 'auth.errors.invalid_email',
      'user-disabled': 'auth.errors.user_disabled',
      'too-many-requests': 'auth.errors.too_many_requests',
      'network-request-failed': 'auth.errors.network_error',
      'operation-not-allowed': 'auth.errors.operation_not_allowed',
      'requires-recent-login': 'auth.errors.requires_recent_login',
    };
    return AuthFailure(mapping[code] ?? 'auth.errors.unknown', cause: e);
  }
}
