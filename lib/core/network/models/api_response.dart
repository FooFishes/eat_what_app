class const ApiResponse<T>({
  required final int code,
  required final String msg,
  required final T? data,
  required final int timestamp,
}) {
  factory fromJson(Map<String, dynamic> json, T Function(Object?) parseData) {
    return ApiResponse(
      code: json['code'] as int,
      msg: (json['msg'] as String?)?.trim() ?? '',
      data: parseData(json['data']),
      timestamp: json['timestamp'] as int,
    );
  }
}

class const PaginatedData<T>({
  required final int currentPage,
  required final List<T> items,
  required final int totalPages,
  required final int totalItems,
  required final bool hasNext,
});
