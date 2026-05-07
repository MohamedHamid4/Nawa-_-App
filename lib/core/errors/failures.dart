sealed class Failure {
  final String message;
  final Object? cause;
  const Failure(this.message, {this.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'auth.errors.network_error', super.cause})
      : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

class ServerFailure extends Failure {
  const ServerFailure({String message = 'auth.errors.unknown', super.cause})
      : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'auth.errors.unknown', super.cause})
      : super(message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

class UnknownFailure extends Failure {
  const UnknownFailure({String message = 'auth.errors.unknown', super.cause})
      : super(message);
}

/// Carries a structured error code from the AI provider so the UI can pick
/// a precise translation (e.g. quota_exceeded vs no_internet).
class AiFailure extends Failure {
  final String code;
  const AiFailure(this.code, {String? message, super.cause})
      : super(message ?? 'ai.error_unknown');
}
