class FoodTagSummaryVO {
  final int id;
  final String name;

  const FoodTagSummaryVO({required this.id, required this.name});

  factory FoodTagSummaryVO.fromJson(Map<String, dynamic> json) {
    return FoodTagSummaryVO(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
