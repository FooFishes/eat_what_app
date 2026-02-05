/// 业务异常 (HTTP 200 但业务码非0)
///
/// 该异常独立于 DioException，可以直接被 catch，方便业务层精确处理
class BusinessException implements Exception {
  final int code;
  final String message;
  final String uri;
  final int timestamp;

  BusinessException({
    required this.code,
    required this.message,
    required this.uri,
    required this.timestamp,
  });

  @override
  String toString() =>
      'BusinessException: [$code] $message (at $uri) at $timestamp ';
}
