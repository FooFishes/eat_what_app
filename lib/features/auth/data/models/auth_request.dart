class AuthRequest({
  required final String account,
  required final String password,
  final String device = 'APP',
}) {
  Map<String, dynamic> toJson() {
    return {'username': account, 'password': password, 'device': device};
  }
}
