enum UpdateErrorKind {
  /// Could not reach the server (DNS, TLS, timeout, connection reset).
  network,

  /// The server answered with an unexpected HTTP status.
  server,

  /// The server answered, but not with the documented JSON.
  badResponse,

  /// 404 `unknown app`: the app id is not served by this server.
  unknownApp,

  /// The server (or a download URL) is not https / not an allowed host.
  insecureUrl,

  /// The downloaded file's size differs from what the server announced.
  sizeMismatch,

  /// The downloaded file's SHA-256 differs from what the server announced.
  checksumMismatch,

  /// The download was cancelled by the caller.
  cancelled,

  /// The OS-specific installer failed to start.
  installFailed,

  /// No installer exists for this platform.
  unsupportedPlatform,
}

class UpdateException implements Exception {
  UpdateException(this.kind, this.message, {this.cause});

  final UpdateErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'UpdateException(${kind.name}): $message';
}
