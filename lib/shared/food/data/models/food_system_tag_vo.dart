class const FoodSystemTagVO({
  required final int id,
  required final String name,
  required final int count,
  required final bool taggedByMe,
}) {
  factory fromJson(Map<String, dynamic> json) {
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
