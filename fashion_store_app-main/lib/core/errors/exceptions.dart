class ServerException implements Exception {
  ServerException(this.message);
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}
