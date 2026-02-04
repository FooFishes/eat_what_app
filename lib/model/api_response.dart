class ApiResponse<T> {
  final int code;
  final String message;
  final T data;
  final int timestamp;

  ApiResponse({required this.code, required this.message, required this.data, required this.timestamp});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(code: json['code'], message: json['message'], data: json['data'], timestamp: json['timestamp']);
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, 'data': data, 'timestamp': timestamp};
  }
}