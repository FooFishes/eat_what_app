/// 饭点. 各饭点的时间段见 `MealRules`.
///
/// 店铺适合的饭点和推荐所用的饭点都取这四个值.
enum MealTime {
  breakfast('breakfast', '早饭'),
  lunch('lunch', '午饭'),
  dinner('dinner', '晚饭'),
  night('night', '夜宵');

  const new(this.api, this.label);

  final String api;
  final String label;

  static MealTime? fromApi(String? value) {
    for (final meal in values) {
      if (meal.api == value) return meal;
    }
    return null;
  }
}
