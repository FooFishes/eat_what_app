class NoAuthUrls {
  // Auth Endpoints
  static const String checkUsername = '/auth/checkUsername';
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  static const List<String> urls = [checkUsername, register, login];

  static bool contains(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return urls.contains(path);
  }
}
