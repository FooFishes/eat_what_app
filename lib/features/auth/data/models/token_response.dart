class TokenResponse({
  required final bool isLogin,
  required final String loginDeviceType,
  required final int loginId,
  required final String loginType,
  required final String tag,
  required final int tokenActiveTimeout,
  required final String tokenName,
  required final int tokenSessionTimeout,
  required final int tokenTimeout,
  required final String tokenValue,
}) {
  factory fromJson(Map<String, dynamic> json) {
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
