class TokenResponse {
  final bool isLogin;
  final String loginDeviceType;
  final int loginId;
  final String loginType;
  final String tag;
  final int tokenActiveTimeout;
  final String tokenName;
  final int tokenSessionTimeout;
  final int tokenTimeout;
  final String tokenValue;

  TokenResponse({
    required this.isLogin,
    required this.loginDeviceType,
    required this.loginId,
    required this.loginType,
    required this.tag,
    required this.tokenActiveTimeout,
    required this.tokenName,
    required this.tokenSessionTimeout,
    required this.tokenTimeout,
    required this.tokenValue,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final rawLoginId = json['loginId'];
    return TokenResponse(
      isLogin: json['isLogin'] as bool,
      loginDeviceType: json['loginDeviceType'] as String,
      loginId: switch (rawLoginId) {
        int value => value,
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      loginType: json['loginType'] as String,
      tag: '', // NEVER USE IT
      tokenActiveTimeout: json['tokenActiveTimeout'] as int,
      tokenName: json['tokenName'] as String,
      tokenSessionTimeout: json['tokenSessionTimeout'] as int,
      tokenTimeout: json['tokenTimeout'] as int,
      tokenValue: json['tokenValue'] as String,
    );
  }
}
