class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;
  final int timestamp;

  const ApiResponse({
    required this.code,
    required this.msg,
    required this.data,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) parseData,
  ) {
    return ApiResponse(
      code: json['code'] as int,
      msg: (json['msg'] as String?)?.trim() ?? '',
      data: parseData(json['data']),
      timestamp: json['timestamp'] as int,
    );
  }
}

class PaginatedData<T> {
  final int currentPage;
  final List<T> items;
  final int totalPages;
  final int totalItems;
  final bool hasNext;

  const PaginatedData({
    required this.currentPage,
    required this.items,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
  });
}
