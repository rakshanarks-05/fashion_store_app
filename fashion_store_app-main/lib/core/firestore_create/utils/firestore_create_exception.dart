/// Thrown when a Firestore create or batch commit operation fails.
///
/// Wraps the original error for debugging while exposing a stable message.
class FirestoreCreateException implements Exception {
  FirestoreCreateException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'FirestoreCreateException: $message${cause != null ? ' ($cause)' : ''}';
}
