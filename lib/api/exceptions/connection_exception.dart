class ConnectionException implements Exception {
  final String message;

  const ConnectionException([this.message = 'Connection failed']);

  @override
  String toString() => message;
}
