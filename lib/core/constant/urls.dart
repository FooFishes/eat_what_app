class Urls {
  static const String baseUrl = 'https://v50to.you/api/v1';
  static const String userAgreement = 'https://www.example.com/';
  static const String checkUsername = '/auth/checkUsername';
  static const String login = '/auth/login';
  static const String userInfo = '/user/info';
  static const String userProfileStats = '/user/userInfo';
  static const String updateUserInfo = '/user/updateInfo';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/changePassword';
  static const String verify = '/auth/verify';
  static const String sendEmail = '/auth/sendEmail';
  static const String provinces = '/api/location/provinces';
  static const String activityFoods = '/activity/foods';
  static const String uploadPresign = '/upload/presign';
  static const String uploadPresignBatch = '/upload/presign/batch';
  static const String provinceActivityFoods = '/activity/{provinceId}/foods';
  static const String likes = '/activity/likes';
  static const String restaurantSearch = '/restaurant/search';
  static const String restaurantAdd = '/restaurant/add';
  static const String restaurantDetail = '/restaurant/detail';
  static const String foodsBase = '/foods';
  static const String foodsUpload = '/foods/upload';
  static const String foodsList = '/foods/list';
  static const String foodsDetail = '/foods/detail';
  static const String foodsSystemTags = '/foods/tags/system';
  static const String foodsMy = '/foods/my';
  static const String foodsFavorites = '/foods/favorites';
  static const String browseHistory = '/history/browse';
  static const String sduAuth = '/auth/sdu';

  // No auth URLs
  static const List<String> noAuthUrls = [checkUsername, register, login];

  static bool isNoAuth(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return noAuthUrls.contains(path);
  }

  static String? resolvePublicAssetUrl(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    final baseUri = Uri.parse(baseUrl);
    final origin = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
    );
    final relativePath = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    return origin.resolve(relativePath).toString();
  }

  static String cities(int provinceId) {
    return '$provinces/$provinceId/cities';
  }
}
