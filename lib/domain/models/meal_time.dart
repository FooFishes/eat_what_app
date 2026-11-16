/// 饭点枚举, 各时段划分见 `MealRules`.
///
/// 店铺适用的营业时段与推荐场景均使用这四个取值.
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
