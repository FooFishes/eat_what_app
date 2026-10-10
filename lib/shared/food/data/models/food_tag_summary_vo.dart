class const FoodTagSummaryVO({
  required final int id,
  required final String name,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return FoodTagSummaryVO(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
