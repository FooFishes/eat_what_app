class AuthRespuest {
  final String account;
  final String password;
  final String device;

  AuthRespuest({
    required this.account,
    required this.password,
    this.device = 'APP',
  });

  Map<String, dynamic> toJson() {
    return {'username': account, 'password': password, 'device': device};
  }
}
