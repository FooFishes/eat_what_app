class Urls {
  static const String baseUrl = 'https://v50to.you/api/v1';
  static const String userAgreement = 'https://www.example.com/';
  static const String checkUsername = '/auth/checkUsername';
  static const String login = '/auth/login';
  static const String userInfo = '/user/info';
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
  static const String sduAuth = '/auth/sdu';

  // No auth URLs
  static const List<String> noAuthUrls = [checkUsername, register, login];

  static bool isNoAuth(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return noAuthUrls.contains(path);
  }

  static String cities(int provinceId) {
    return '$provinces/$provinceId/cities';
  }
}
