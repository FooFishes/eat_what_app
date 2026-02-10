import '../../error/api_exception.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
    Success<T> s => s.data,
    Failure<T> _ => null,
  };

  ApiException? get error => switch (this) {
    Success<T> _ => null,
    Failure<T> f => f.exception,
  };

  /// 模式匹配
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) => switch (this) {
    Success<T> s => success(s.data),
    Failure<T> f => failure(f.exception),
  };

  /// 成功时转换
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T> s => Success(transform(s.data)),
    Failure<T> f => Failure(f.exception),
  };

  /// 成功时执行异步操作
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    return switch (this) {
      Success<T> s => await transform(s.data),
      Failure<T> f => Failure(f.exception),
    };
  }
}

final class Success<T> extends Result<T> {
  @override
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

final class Failure<T> extends Result<T> {
  final ApiException exception;
  const Failure(this.exception);

  @override
  String toString() => 'Failure($exception)';
}
