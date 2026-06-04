/// Form validation helpers for email/password registration and phone (E.164-style).
abstract final class RegistrationValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? emailError(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? passwordError(String? raw) {
    final v = raw ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? displayNameError(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Enter your display name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 80) return 'Name is too long';
    return null;
  }

  static String? confirmPasswordError(String? raw, String password) {
    final v = raw ?? '';
    if (v.isEmpty) return 'Confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  /// National number digits only (no country code). Typical E.164 subscriber length bounds.
  static String? addressError(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 500) return 'Address is too long';
    return null;
  }

  static String? nationalPhoneDigitsError(String? raw) {
    final digits = digitsOnly(raw);
    if (digits.isEmpty) return 'Enter your phone number';
    if (digits.length < 7) return 'Phone number is too short';
    if (digits.length > 15) return 'Phone number is too long';
    return null;
  }

  static String digitsOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\D'), '');
  }

  /// Builds `+[countryCode][nationalDigits]` for Firestore (not SMS-verified).
  static String buildE164({required String phoneCode, required String nationalDigits}) {
    final code = phoneCode.replaceAll(RegExp(r'\D'), '');
    final national = digitsOnly(nationalDigits);
    return '+$code$national';
  }
}
