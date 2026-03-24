class FoodSystemTagVO {
  final int id;
  final String name;
  final int count;
  final bool taggedByMe;

  const FoodSystemTagVO({
    required this.id,
    required this.name,
    required this.count,
    required this.taggedByMe,
  });

  factory FoodSystemTagVO.fromJson(Map<String, dynamic> json) {
    return FoodSystemTagVO(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      taggedByMe: json['taggedByMe'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'count': count, 'taggedByMe': taggedByMe};
  }
}
