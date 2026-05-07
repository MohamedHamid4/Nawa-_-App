class Validators {
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  /// Returns a translation key on error, or null when valid.
  static String? email(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'auth.errors.email_required';
    if (!_emailRegex.hasMatch(v)) return 'auth.errors.email_invalid';
    return null;
  }

  static String? password(String? raw) {
    final v = raw ?? '';
    if (v.isEmpty) return 'auth.errors.password_required';
    if (v.length < 8) return 'auth.errors.password_short';
    return null;
  }

  static String? name(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'auth.errors.name_required';
    return null;
  }

  static String? confirm(String? value, String reference) {
    if ((value ?? '') != reference) return 'auth.passwords_dont_match';
    return null;
  }
}
