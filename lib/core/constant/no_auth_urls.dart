import 'urls.dart';

class NoAuthUrls {
  static const List<String> urls = [
    Urls.checkUsername,
    Urls.register,
    Urls.login,
  ];

  static bool contains(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    return urls.contains(path);
  }
}
