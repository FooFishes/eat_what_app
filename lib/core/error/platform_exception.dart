//平台错误基类
sealed class PlatformException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const new({required this.message, this.originalError, this.stackTrace});
}

class LocationException extends PlatformException {
  final LocationExceptionType type;
  const new({
    required this.type,
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

enum LocationExceptionType { timeout, permissionDenied, unknown }
