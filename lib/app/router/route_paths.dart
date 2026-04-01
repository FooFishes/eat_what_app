class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const auth = '/auth';
  static const webviewAuth = '/webview-auth';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const foodieMap = '/foodie_map';
  static const home = '/home';
  static const map = '/map';
  static const upload = '/upload';
  static const restaurant = '/restaurant';
  static const profile = '/profile';
  static const profileInfo = '/profile/info';
  static const profileHistory = '/profile/history';
  static const profileTags = '/profile/tags';

  static String restaurantDetail(int restaurantId) {
    return '$restaurant/$restaurantId';
  }

  static String uploadAddFood(int restaurantId) {
    return '$upload/restaurant/$restaurantId/add-food';
  }

  static const uploadAddRestaurant = '/upload/restaurant/add';
}
