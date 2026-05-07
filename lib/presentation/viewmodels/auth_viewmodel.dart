import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthState {
  final bool loading;
  final AppUser? user;
  final Failure? failure;

  const AuthState({this.loading = false, this.user, this.failure});

  AuthState copyWith({bool? loading, AppUser? user, Failure? failure, bool clearFailure = false}) =>
      AuthState(
        loading: loading ?? this.loading,
        user: user ?? this.user,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    return AuthState(user: _repo.currentUser);
  }

  Future<bool> _wrap(Future<Result<AppUser>> Function() call) async {
    state = state.copyWith(loading: true, clearFailure: true);
    final r = await call();
    return r.when(
      success: (u) {
        state = AuthState(loading: false, user: u);
        return true;
      },
      failure: (f) {
        state = state.copyWith(loading: false, failure: f);
        return false;
      },
    );
  }

  Future<bool> signIn(String email, String password) =>
      _wrap(() => _repo.signInWithEmail(email: email, password: password));

  Future<bool> signUp(String name, String email, String password) =>
      _wrap(() =>
          _repo.signUpWithEmail(name: name, email: email, password: password));

  Future<bool> google() => _wrap(_repo.signInWithGoogle);
  Future<bool> apple() => _wrap(_repo.signInWithApple);
  Future<bool> guest() => _wrap(_repo.signInAnonymously);

  Future<bool> sendReset(String email) async {
    state = state.copyWith(loading: true, clearFailure: true);
    final r = await _repo.sendPasswordReset(email);
    return r.when(
      success: (_) {
        state = state.copyWith(loading: false);
        return true;
      },
      failure: (f) {
        state = state.copyWith(loading: false, failure: f);
        return false;
      },
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(loading: true, clearFailure: true);
    final r = await _repo.deleteAccount();
    return r.when(
      success: (_) {
        state = const AuthState();
        return true;
      },
      failure: (f) {
        state = state.copyWith(loading: false, failure: f);
        return false;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearFailure: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(user: _repo.currentUser);
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
