import 'dart:convert';

/// Placeholders for a future REST backend (swap in instead of Firestore-only writes).
///
/// Wire these into a new [ProfileRemoteDataSource] implementation when the API exists.
abstract final class UserProfileRemoteApiPlaceholders {
  static const String baseUrl = String.fromEnvironment(
    'USER_API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  /// Example: `POST /v1/auth/register` — implement with your HTTP client + auth headers.
  static Future<void> registerUserPlaceholder({
    required Map<String, dynamic> body,
  }) async {
    // Example: await http.post(Uri.parse('$baseUrl/v1/auth/register'), body: jsonEncode(body));
    throw UnimplementedError('REST register — implement when API is ready.');
  }

  /// Example: `PATCH /v1/users/me` — **omit** `email` from [body] if the account email is immutable.
  static Future<void> updateUserProfilePlaceholder({
    required Map<String, dynamic> body,
  }) async {
    // Example: await http.patch(Uri.parse('$baseUrl/v1/users/me'), body: jsonEncode(body));
    throw UnimplementedError('REST update profile — implement when API is ready.');
  }

  /// Sample JSON shape for documentation (email omitted on purpose for updates).
  static Map<String, dynamic> sampleUpdateBody({
    required String displayName,
    String? phoneNumberE164,
    String? photoUrl,
    String? address,
  }) {
    return {
      'displayName': displayName,
      'phoneNumber': ?phoneNumberE164,
      'photoUrl': ?photoUrl,
      'address': ?address,
    };
  }

  static String encodeJson(Map<String, dynamic> body) => jsonEncode(body);
}
