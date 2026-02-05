class NoAuthUrls {
  // Auth Endpoints
  static const String checkUsername = '/auth/checkUsername';
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  static const List<String> urls = [checkUsername, register, login];

  static bool contains(String url) {
    return urls.any((element) => url.contains(element));
  }
}
