class ApiResponse<T> {
  final int code;
  final String message;
  final T data;
  final int timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic> json)? fromJsonT,
  }) {
    return ApiResponse(
      code: json['code'],
      message: json['message'],
      data: fromJsonT?.call(json['data']) ?? json['data'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson({
    Map<String, dynamic>? Function(T value)? toJsonT,
  }) {
    return {
      'code': code,
      'message': message,
      'data': toJsonT?.call(data) ?? data,
      'timestamp': timestamp,
    };
  }
}
