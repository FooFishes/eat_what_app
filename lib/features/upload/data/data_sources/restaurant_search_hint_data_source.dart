import 'package:shared_preferences/shared_preferences.dart';

class RestaurantSearchHintDataSource {
  static const String _howHintSeenKey = 'restaurant_search_how_hint_seen';

  const new();

  Future<bool> shouldShowIntroHint() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_howHintSeenKey) ?? false;
    if (seen) {
      return false;
    }
    await prefs.setBool(_howHintSeenKey, true);
    return true;
  }

  Future<void> markIntroHintShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_howHintSeenKey, true);
  }
}
