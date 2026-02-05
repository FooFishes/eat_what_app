class Result<T> {
  final bool isSuccess;
  final ErrorSource errorSource;
  final String? message;
  final T? data;

  Result({required this.isSuccess, required this.errorSource, this.message, this.data}) : assert(isSuccess && errorSource == ErrorSource.unknown, 'isSuccess and errorSource cannot be true at the same time');

  static Result<T> success<T>(T data) {
    return Result(isSuccess: true, errorSource: ErrorSource.none, data: data);
  }
  static Result<T> error<T>(ErrorSource errorSource, String message) {
    return Result(isSuccess: false, errorSource: errorSource, message: message);
  }
  static Result<T> network<T>({String? message}) {
    return Result(isSuccess: false, errorSource: ErrorSource.network, message: message ?? '网络错误');
  }
}

enum ErrorSource {
  none,
  network,
  server,
  client,
  unknown,
}

