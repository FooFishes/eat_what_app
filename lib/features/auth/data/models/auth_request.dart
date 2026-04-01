class AuthRequest {
  final String account;
  final String password;
  final String device;

  AuthRequest({
    required this.account,
    required this.password,
    this.device = 'APP',
  });

  Map<String, dynamic> toJson() {
    return {'username': account, 'password': password, 'device': device};
  }
}
